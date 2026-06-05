#!/usr/bin/env bash
# ดึงสมุดโครงการจาก Property Hub ขึ้น Supabase Cloud — เฉพาะ กทม.+ปริมณฑล
# ต้อง deploy project-import-propertyhub ก่อน
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
cd "$ROOT"

VISIBLE="$ROOT/ใส่รหัส-database-ตรงนี้.env"
ENV_FILE="$ROOT/.env.local"

_load_env() {
  [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
  [[ -f "$VISIBLE" ]] && source "$VISIBLE"
}

if [[ ! -f "$ENV_FILE" ]] && [[ ! -f "$VISIBLE" ]]; then
  echo "❌ ไม่พบ .env.local"
  exit 1
fi

set -a
_load_env
set +a

SUPABASE_URL="${SUPABASE_URL:-https://auflqgqrmpbioflnhsrj.supabase.co}"
ANON_KEY="${SUPABASE_ANON_KEY:-}"
ADMIN_EMAIL="${ADMIN_EMAIL:-demo-admin@livingbkk.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-demo12345}"
BATCH_SIZE="${BATCH_SIZE:-20}"
MAX_BATCHES="${MAX_BATCHES:-0}"
START_OFFSET="${START_OFFSET:-0}"

if [[ -z "$ANON_KEY" ]]; then
  ANON_KEY="$(grep -E '^SUPABASE_ANON_KEY=' "$ROOT/mobile/assets/env" | cut -d= -f2- | tr -d '\r' || true)"
fi

if [[ -z "$ANON_KEY" ]]; then
  echo "❌ ไม่พบ SUPABASE_ANON_KEY"
  exit 1
fi

echo "=== เข้าสู่ระบบแอดมิน ($ADMIN_EMAIL) ==="
AUTH_JSON=$(curl -sS -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")

ACCESS_TOKEN=$(echo "$AUTH_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('access_token',''))" 2>/dev/null || true)

if [[ -z "$ACCESS_TOKEN" ]]; then
  echo "❌ ล็อกอินไม่สำเร็จ — ตรวจอีเมล/รหัส หรือรัน seed-cloud.sh"
  echo "$AUTH_JSON" | head -c 400
  exit 1
fi

invoke_fn() {
  local body="$1"
  curl -sS -X POST "$SUPABASE_URL/functions/v1/project-import-propertyhub" \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$body"
}

echo ""
echo "=== ค้นหารายชื่อโครงการ (Property Hub — แบบเต็ม) ==="
if [[ "${SKIP_DISCOVER:-0}" == "1" && -f /tmp/ph-all-slugs.json ]]; then
  cp /tmp/ph-all-slugs.json /tmp/ph-discover.json
  echo "ใช้รายชื่อที่ค้นหาไว้แล้ว (/tmp/ph-all-slugs.json)"
elif [[ "${USE_CLOUD_DISCOVER:-0}" == "1" ]]; then
  DISCOVER=$(invoke_fn '{"mode":"discover"}')
  echo "$DISCOVER" > /tmp/ph-discover.json
else
  if [[ -f "$ROOT/scripts/discover-metro-projects-v2.py" ]]; then
    python3 "$ROOT/scripts/discover-metro-projects-v2.py"
  else
    python3 "$ROOT/scripts/discover-propertyhub-slugs.py"
  fi
  if [[ ! -f /tmp/ph-all-slugs.json ]]; then
    echo "❌ ค้นหาชื่อไม่สำเร็จ"
    exit 1
  fi
  cp /tmp/ph-all-slugs.json /tmp/ph-discover.json
fi

SLUG_COUNT=$(python3 -c "import json; print(len(json.load(open('/tmp/ph-discover.json')).get('slugs',[])))")
echo "พบ $SLUG_COUNT โครงการ"
if [[ "$SLUG_COUNT" == "0" ]]; then
  exit 0
fi

echo ""
echo "=== ดึงรายละเอียดทีละ $BATCH_SIZE รายการ ==="
OFFSET=$START_OFFSET
if [[ "$START_OFFSET" -gt 0 ]]; then
  echo "ต่อจากรายการที่ $START_OFFSET"
fi
TOTAL_OK=0
TOTAL_FAIL=0
BATCH_NUM=0

while true; do
  if [[ "$MAX_BATCHES" -gt 0 && "$BATCH_NUM" -ge "$MAX_BATCHES" ]]; then
    echo "หยุดตาม MAX_BATCHES=$MAX_BATCHES"
    break
  fi

  RESULT=$(python3 << PY
import json
with open("/tmp/ph-discover.json") as f:
    data = json.load(f)
slugs = data.get("slugs") or []
offset = $OFFSET
size = $BATCH_SIZE
batch = slugs[offset:offset+size]
if not batch:
    print(json.dumps({"stop": True}))
else:
    print(json.dumps({"mode": "batch", "slugs": batch, "limit": size}))
PY
)

  if echo "$RESULT" | grep -q '"stop"'; then
    break
  fi

  RESP=$(invoke_fn "$RESULT")
  BATCH_NUM=$((BATCH_NUM + 1))
  PARSED=$(echo "$RESP" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if d.get('error'):
    print('ERR', d['error'])
else:
    ok=d.get('ok',0)
    fail=d.get('fail',0)
    print('OK', ok, fail)
" 2>/dev/null || echo "ERR parse")

  if [[ "$PARSED" == ERR* ]]; then
    echo "❌ batch $BATCH_NUM: ${PARSED#ERR }"
    exit 1
  fi

  OK=$(echo "$PARSED" | awk '{print $2}')
  FAIL=$(echo "$PARSED" | awk '{print $3}')
  TOTAL_OK=$((TOTAL_OK + OK))
  TOTAL_FAIL=$((TOTAL_FAIL + FAIL))
  OFFSET=$((OFFSET + BATCH_SIZE))

  echo "ชุด $BATCH_NUM · ดึงแล้ว $OFFSET/$SLUG_COUNT · สำเร็จสะสม $TOTAL_OK · ล้มเหลวสะสม $TOTAL_FAIL"

  if [[ "$OFFSET" -ge "$SLUG_COUNT" ]]; then
    break
  fi
done

echo ""
echo "✅ เสร็จ — สำเร็จ $TOTAL_OK · ล้มเหลว $TOTAL_FAIL จาก $SLUG_COUNT โครงการ"
echo "   ถัดไป: เปิดแอปแอดมิน → โครงการ → ตรวจรายการ / ลองค้นหาชื่อ"
