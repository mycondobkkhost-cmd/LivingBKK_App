#!/usr/bin/env bash
# Deploy ครบ: migrations + Edge Functions ทั้งหมด
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
cd "$ROOT"

echo "=== LivingBKK — deploy ครบชุด ==="

if ! command -v supabase >/dev/null 2>&1; then
  echo "❌ ไม่พบ supabase CLI — source scripts/dev-path.sh"
  exit 1
fi

echo ""
echo "=== db push ==="
supabase db push

FUNCTIONS=(
  submit-demand-offer
  smart-search-parse
  moderate-listing-text
  lead-bot-turn
  route-lead-notification
  notify-appointment
  notify-chat-escalation
  chat-open-thread
  chat-turn
  chat-admin-reply
  chat-claim
  chat-assign
  chat-record-viewing
  chat-record-demand-offer
  chat-sla-cron
  listing-lifecycle-cron
  image-dedup-check
  listing-watermark-images
  listing-import-fetch
  listing-import-approve
  listing-import-archive
  project-import-fetch
  project-import-propertyhub
  analytics-track
  analytics-rollup-cron
)

echo ""
echo "=== Edge Functions ==="
for fn in "${FUNCTIONS[@]}"; do
  echo "→ $fn"
  supabase functions deploy "$fn"
done

echo ""
echo "✅ Deploy เสร็จ"
echo ""
echo "ถัดไป (ครั้งเดียว):"
echo "  1) ./scripts/sync-env.sh"
echo "  2) ./scripts/seed-cloud.sh   # ทรัพย์ตัวอย่างใน cloud"
echo "  3) Dashboard → Edge → Secrets: FCM_SERVER_KEY, MAKECOM_WEBHOOK_URL (ทางเลือก)"
echo "  4) Cron: listing-lifecycle-cron รายวัน · chat-sla-cron ทุก 30 นาที"
echo "  5) Cron: analytics-rollup-cron ทุก 1 ชม. (ดู docs/phase-21-analytics-platform.md)"
echo "  6) Cron (แนะนำ): SELECT public.process_exclusive_auto_bumps(); รายชั่วโมง"
echo "  7) ดู docs/PRE-PUSH-STATUS.md"
echo "  8) ./scripts/run-app.sh"
