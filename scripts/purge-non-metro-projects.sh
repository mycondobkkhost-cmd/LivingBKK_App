#!/usr/bin/env bash
# ปิดโครงการนอก กทม.+ปริมณฑล ในคลาวด์ (รันครั้งเดียวหลังแก้นโยบายพื้นที่)
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

set -a
_load_env
set +a

SUPABASE_URL="${SUPABASE_URL:-https://auflqgqrmpbioflnhsrj.supabase.co}"
ANON_KEY="${SUPABASE_ANON_KEY:-}"
ADMIN_EMAIL="${ADMIN_EMAIL:-demo-admin@livingbkk.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-demo12345}"

if [[ -z "$ANON_KEY" ]]; then
  ANON_KEY="$(grep -E '^SUPABASE_ANON_KEY=' "$ROOT/mobile/assets/env" | cut -d= -f2- | tr -d '\r' || true)"
fi

echo "=== ล็อกอินแอดมิน ==="
AUTH_JSON=$(curl -sS -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")

ACCESS_TOKEN=$(echo "$AUTH_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('access_token',''))" 2>/dev/null || true)
if [[ -z "$ACCESS_TOKEN" ]]; then
  echo "❌ ล็อกอินไม่สำเร็จ"
  exit 1
fi

echo "=== ปิดโครงการนอก กทม.+ปริมณฑล ==="
curl -sS -X POST "$SUPABASE_URL/functions/v1/project-import-propertyhub" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"mode":"deactivate_non_metro"}' | python3 -m json.tool

echo ""
echo "✅ เสร็จ — โครงการที่เหลือในแอปจะเป็น กทม.+ปริมณฑล เท่านั้น"
