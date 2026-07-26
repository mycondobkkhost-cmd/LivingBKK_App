#!/usr/bin/env bash
# Deploy Edge Functions ที่จำเป็นสำหรับ E2E (แชท / ลีด / นัดดู)
# ไม่ต้องเปิด Docker — ใช้ Supabase Management API
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
cd "$ROOT"

if ! command -v supabase >/dev/null 2>&1; then
  echo "❌ ไม่พบ supabase CLI — source scripts/dev-path.sh"
  exit 1
fi

FUNCTIONS=(
  owner-lead-action
  chat-record-viewing
  route-lead-notification
  chat-admin-coach-reply
  chat-turn
  owner-inquiry-submit
)

echo "=== RealXtate — deploy E2E Edge Functions (${#FUNCTIONS[@]} ตัว) ==="
for fn in "${FUNCTIONS[@]}"; do
  echo "→ $fn"
  supabase functions deploy "$fn" --use-api
done

echo ""
echo "✅ Deploy E2E functions เสร็จ"
echo "ทดสอบ: ./scripts/open-three-role-test.sh --real"
