#!/usr/bin/env bash
# ไล่ slug ที่ดึง PH ไม่สำเร็จ → validate แล้ว retry batch import
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ph-pipeline-env.sh
source "$ROOT/scripts/ph-pipeline-env.sh"
source "$ROOT/scripts/dev-path.sh"
cd "$ROOT"

SLUG_FILE="${1:-$PH_PIPELINE_DIR/ph-slugs-metro.json}"
FAILED_LIST="$PH_PIPELINE_DIR/ph-slugs-failed.json"
RETRY_LOG="$PH_PIPELINE_DIR/retry-failed.log"
BATCH_SIZE="${BATCH_SIZE:-20}"
VALIDATE_CHUNK="${VALIDATE_CHUNK:-40}"

if [[ ! -f "$SLUG_FILE" ]]; then
  echo "❌ ไม่พบ $SLUG_FILE"
  exit 1
fi

cp "$SLUG_FILE" /tmp/ph-discover.json
SLUG_COUNT=$(python3 -c "import json; print(len(json.load(open('/tmp/ph-discover.json')).get('slugs',[])))")

echo "[$(date '+%Y-%m-%d %H:%M:%S')] validate $SLUG_COUNT slugs" | tee -a "$RETRY_LOG"

# shellcheck source=/dev/null
source "$ROOT/.env.local" 2>/dev/null || true
SUPABASE_URL="${SUPABASE_URL:-https://auflqgqrmpbioflnhsrj.supabase.co}"
ANON_KEY="${SUPABASE_ANON_KEY:-}"
ADMIN_EMAIL="${ADMIN_EMAIL:-demo-admin@livingbkk.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-demo12345}"

AUTH_JSON=$(curl -sS -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")
ACCESS_TOKEN=$(echo "$AUTH_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))")
if [[ -z "$ACCESS_TOKEN" ]]; then
  echo "❌ ล็อกอินแอดมินไม่สำเร็จ" | tee -a "$RETRY_LOG"
  exit 1
fi

invoke_fn() {
  curl -sS -X POST "$SUPABASE_URL/functions/v1/project-import-propertyhub" \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$1"
}

python3 <<'PY' > /tmp/ph-all-slugs-list.json
import json
with open("/tmp/ph-discover.json") as f:
    print(json.dumps(json.load(f).get("slugs", [])))
PY

FAILED=()
OFFSET=0
while true; do
  CHUNK_JSON=$(python3 <<PY
import json
slugs = json.load(open("/tmp/ph-all-slugs-list.json"))
offset = $OFFSET
size = $VALIDATE_CHUNK
batch = slugs[offset:offset+size]
print(json.dumps({"mode":"validate_slugs","slugs":batch,"limit":size}))
PY
)
  if [[ "$(python3 -c "import json; b=json.loads('''$CHUNK_JSON'''); print(len(b.get('slugs',[])))")" == "0" ]]; then
    break
  fi

  RESP=$(invoke_fn "$CHUNK_JSON")
  python3 <<PY >>"$RETRY_LOG"
import json
resp = json.loads('''$(echo "$RESP" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')''')
for item in resp.get("invalid", []):
    print(f"invalid\t{item.get('slug')}\t{item.get('error')}")
PY

  NEW_FAILED=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print('\n'.join(i['slug'] for i in d.get('invalid',[])))")
  if [[ -n "$NEW_FAILED" ]]; then
    while IFS= read -r slug; do
      [[ -n "$slug" ]] && FAILED+=("$slug")
    done <<< "$NEW_FAILED"
  fi

  OFFSET=$((OFFSET + VALIDATE_CHUNK))
  if [[ "$OFFSET" -ge "$SLUG_COUNT" ]]; then
    break
  fi
  echo "validate $OFFSET/$SLUG_COUNT · failed so far ${#FAILED[@]}" | tee -a "$RETRY_LOG"
done

python3 <<PY
import json
slugs = sorted(set('''${FAILED[*]}'''.split()))
out = {"count": len(slugs), "slugs": slugs}
json.dump(out, open("$FAILED_LIST", "w"), ensure_ascii=False, indent=2)
print(len(slugs))
PY

UNIQUE_FAIL=$(python3 -c "import json; print(json.load(open('$FAILED_LIST'))['count'])")
echo "[$(date '+%Y-%m-%d %H:%M:%S')] พบล้มเหลว $UNIQUE_FAIL slug → $FAILED_LIST" | tee -a "$RETRY_LOG"

if [[ "$UNIQUE_FAIL" == "0" ]]; then
  echo "✅ ไม่มี slug ที่ validate ไม่ผ่าน" | tee -a "$RETRY_LOG"
  exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] retry import $UNIQUE_FAIL slugs" | tee -a "$RETRY_LOG"
cp "$FAILED_LIST" /tmp/ph-discover.json

SKIP_DISCOVER=1 IMPORT_SCOPE=metro BATCH_SIZE="$BATCH_SIZE" MAX_BATCHES=0 START_OFFSET=0 \
  bash "$ROOT/scripts/sync-propertyhub-cloud.sh" >>"$RETRY_LOG" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] retry จบ" | tee -a "$RETRY_LOG"
