#!/usr/bin/env bash
# Deploy migrations + Edge Functions สำหรับ AI / Admin Feed / Owner Inquiry
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
cd "$ROOT"

if ! command -v supabase >/dev/null 2>&1; then
  echo "❌ ไม่พบ supabase CLI"
  exit 1
fi

echo "=== RealXtate — deploy AI stack ==="

echo ""
echo "→ sync-env (Flutter client)"
"$ROOT/scripts/sync-env.sh"

echo ""
echo "→ supabase db push"
yes | supabase db push || {
  echo ""
  echo "⚠️  db push ไม่สำเร็จ — ดู scripts/apply-ai-migrations-manual.md"
  echo "   หรือแก้ migration ที่ติด (เช่น inventory_members) แล้วรันสคริปต์นี้อีกครั้ง"
}

FUNCTIONS=(
  smart-search-parse
  smart-search
  smart-search-autocomplete
  chat-turn
  chat-admin-coach-reply
  owner-inquiry-submit
  owner-inquiry-reply
  admin-ai-feed
  admin-orchestrator
  admin-unified-search
  image-dedup-check
  moderate-listing-text
  route-lead-notification
  chat-record-viewing
  owner-lead-action
  notify-appointment
  submit-project-request
  listing-import-fetch
  listing-import-capture
  listing-import-ai-draft
  listing-import-evidence
  maps-share-resolve
  project-geocode-preview
)

echo ""
echo "→ Edge Functions (${#FUNCTIONS[@]} ตัว)"
for fn in "${FUNCTIONS[@]}"; do
  echo "  · $fn"
  supabase functions deploy "$fn" --use-api
done

if [[ -f "$ROOT/.env.local" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "$ROOT/.env.local"
  set +a
fi

if [[ -n "${OPENAI_API_KEY:-}" ]] && [[ "${OPENAI_API_KEY}" != *"YOUR_"* ]]; then
  echo ""
  echo "→ ตั้ง Supabase secrets (OpenAI)"
  supabase secrets set \
    OPENAI_API_KEY="$OPENAI_API_KEY" \
    OPENAI_MODEL="${OPENAI_MODEL:-gpt-4o-mini}"
  echo "✅ OPENAI_API_KEY + OPENAI_MODEL ตั้งแล้ว"
else
  echo ""
  echo "ℹ️  ยังไม่มี OPENAI_API_KEY ใน .env.local"
  echo "   1) ใส่ OPENAI_API_KEY=sk-... ใน .env.local"
  echo "   2) รัน: ./scripts/setup-openai-secret.sh"
  echo "   (แอปยังเทสได้ด้วย FAQ/rules จนกว่าจะใส่ key)"
fi

if [[ -n "${GOOGLE_MAPS_API_KEY:-}" ]] && [[ "${GOOGLE_MAPS_API_KEY}" != *"YOUR_"* ]]; then
  echo ""
  echo "→ ตั้ง Supabase secrets (Google Maps — geocode fallback)"
  supabase secrets set "GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY"
  echo "✅ GOOGLE_MAPS_API_KEY ตั้งแล้ว"
else
  echo ""
  echo "ℹ️  ยังไม่มี GOOGLE_MAPS_API_KEY ใน .env.local"
  echo "   fallback geocode จากชื่อโครงการ LI จะใช้ไม่ได้จนกว่าจะใส่ key"
  echo "   รัน: ./scripts/setup-google-maps.sh"
fi

echo ""
echo "✅ Deploy AI stack เสร็จ"
echo ""
echo "ทดสอบ:"
echo "  ./scripts/restart-cursor-dev.sh"
echo "  ล็อกอินจริง → แผนที่/แชท/Admin ✨"
echo "  http://127.0.0.1:7357/admin/console"
echo "  http://127.0.0.1:7357/admin?devRole=admin&devAuth=real&nav=import"
echo ""
echo "Checklist นำเข้าแคปเจอร์ + AI:"
echo "  1) แคปเจอร์: paste ข้อความ FB + ลิงก์ + evidence + รูปทรัพย์ → AI ร่าง → แก้ After → อนุมัติ"
echo "  2) ลิงก์ FB ดึงไม่ครบ → retry → มี Before/After + กรอก owner URL"
echo "  3) description ที่ publish ไม่มีเบอร์/Line"
echo "  4) รูป evidence ไม่โผล่ใน gallery ประกาศสาธารณะ"
