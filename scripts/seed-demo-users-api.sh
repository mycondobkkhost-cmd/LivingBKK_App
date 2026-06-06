#!/usr/bin/env bash
# สร้างบัญชี demo 3 คนบน Supabase Cloud (Admin API)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env.local"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ ไม่พบ .env.local"
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

URL="${SUPABASE_URL%/}"
KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"

if [[ -z "$URL" || -z "$KEY" ]]; then
  echo "❌ ต้องมี SUPABASE_URL และ SUPABASE_SERVICE_ROLE_KEY ใน .env.local"
  exit 1
fi

PASS="${DEMO_USER_PASSWORD:-demo12345}"

create_or_update() {
  local email="$1"
  local role="$2"
  local name="$3"

  local existing
  existing="$(curl -sS "$URL/auth/v1/admin/users?per_page=200" \
    -H "apikey: $KEY" \
    -H "Authorization: Bearer $KEY" | python3 -c "
import json,sys
target=sys.argv[1].lower()
d=json.load(sys.stdin)
for u in d.get('users') or []:
  if (u.get('email') or '').lower() == target:
    print(u['id'])
    break
" "$email" 2>/dev/null || true)"

  local user_id
  if [[ -n "$existing" ]]; then
    curl -sS -X PUT "$URL/auth/v1/admin/users/$existing" \
      -H "apikey: $KEY" \
      -H "Authorization: Bearer $KEY" \
      -H "Content-Type: application/json" \
      -d "{\"password\":\"$PASS\",\"email_confirm\":true,\"user_metadata\":{\"role\":\"$role\",\"display_name\":\"$name\"}}" \
      >/dev/null
    user_id="$existing"
    echo "↻ อัปเดต $email"
  else
    local res
    res="$(curl -sS -X POST "$URL/auth/v1/admin/users" \
      -H "apikey: $KEY" \
      -H "Authorization: Bearer $KEY" \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"$email\",\"password\":\"$PASS\",\"email_confirm\":true,\"user_metadata\":{\"role\":\"$role\",\"display_name\":\"$name\"}}")"
    user_id="$(echo "$res" | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || true)"
    if [[ -z "$user_id" ]]; then
      echo "❌ สร้าง $email ไม่สำเร็จ: $res"
      return 1
    fi
    echo "✅ สร้าง $email"
  fi

  curl -sS -X POST "$URL/rest/v1/profiles?on_conflict=id" \
    -H "apikey: $KEY" \
    -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: resolution=merge-duplicates,return=representation" \
    -d "{\"id\":\"$user_id\",\"role\":\"$role\",\"display_name\":\"$name\"}" \
    | python3 -c "
import json,sys
rows=json.load(sys.stdin)
if not rows:
  sys.exit(1)
r=rows[0]
if r.get('role') != sys.argv[1]:
  print(f\"⚠️  profile role ยังเป็น {r.get('role')} (ต้องการ {sys.argv[1]})\", file=sys.stderr)
" "$role" 2>/dev/null || true
}

echo "=== สร้างบัญชี demo (รหัส: $PASS) ==="
create_or_update "demo-owner@livingbkk.local" "owner" "Demo Owner"
create_or_update "demo-admin@livingbkk.local" "admin" "Demo Admin"
create_or_update "demo-seeker@livingbkk.local" "seeker" "Demo Seeker"
echo ""
echo "พร้อมล็อกอิน:"
echo "  ลูกค้า/เจ้าของ: demo-owner@livingbkk.local"
echo "  แอดมิน:        demo-admin@livingbkk.local"
echo "  ลูกค้าคนที่ 3:  demo-seeker@livingbkk.local"
echo "  รหัสทุกคน:      $PASS"
