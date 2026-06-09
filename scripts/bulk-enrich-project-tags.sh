#!/usr/bin/env bash
# อัปเดตแท็กค้นหามาตรฐานให้โครงการทุกรายการ (project-tag-enrich)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
cd "$ROOT"

ENV_FILE="$ROOT/.env.local"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ ไม่พบ .env.local"
  exit 1
fi
set -a
# shellcheck disable=SC1091
source "$ENV_FILE"
set +a

: "${SUPABASE_URL:?SUPABASE_URL required}"
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY required}"

ADMIN_EMAIL="${ADMIN_EMAIL:-demo-admin@livingbkk.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-demo12345}"

echo "=== Sign in $ADMIN_EMAIL ==="
TOKEN=$(curl -s -X POST "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD}\"}" \
  | python3 -c "import json,sys; print(json.load(sys.stdin).get('access_token',''))")

if [[ -z "$TOKEN" ]]; then
  echo "❌ Login failed — ตรวจบัญชีแอดมินใน docs/บัญชี-admin.md"
  exit 1
fi

offset=0
total_updated=0
total_review=0
batch=1

echo "=== project-tag-enrich bulk ==="
while true; do
  RESP=$(curl -s -X POST "${SUPABASE_URL}/functions/v1/project-tag-enrich" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"mode\":\"bulk\",\"limit\":200,\"offset\":${offset}}")

  err=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error','') or '')")
  if [[ -n "$err" ]]; then
    echo "❌ $err"
    echo "$RESP" | python3 -m json.tool 2>/dev/null || echo "$RESP"
    exit 1
  fi

  updated=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('updated',0))")
  review=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('needs_review',0))")
  done_flag=$(echo "$RESP" | python3 -c "import json,sys; print('1' if json.load(sys.stdin).get('done') else '0')")

  total_updated=$((total_updated + updated))
  total_review=$((total_review + review))
  echo "  batch $batch: updated=$updated needs_review=$review offset=$offset"

  if [[ "$done_flag" == "1" ]]; then
    break
  fi
  offset=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('next_offset',0))")
  batch=$((batch + 1))
done

echo ""
echo "✅ เสร็จ — อัปเดต $total_updated โครงการ · ต้องตรวจ $total_review (needs_review)"
