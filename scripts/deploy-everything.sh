#!/usr/bin/env bash
# ช่วย deploy ครบ: build zip → เปิด Netlify + Finder → Supabase (Terminal)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
ZIP="$ROOT/mobile/build/livingbkk-web.zip"
SITE="quiet-kangaroo-ab6073"
NETLIFY_DEPLOYS="https://app.netlify.com/sites/${SITE}/deploys"

echo ""
echo "=============================================="
echo "  LivingBKK — deploy ครบชุด (ทำบน Mac)"
echo "=============================================="
echo ""

# --- 1) Build zip ล่าสุด ---
echo "▶ ขั้น 1/3: สร้างไฟล์ zip ล่าสุด..."
"$ROOT/scripts/sync-env.sh" >/dev/null
cd "$ROOT/mobile"
flutter build web --release
(cd build/web && zip -r -q "$ZIP" .)
echo "   ✅ zip พร้อม: $ZIP"
echo ""

# --- 2) Netlify ---
echo "▶ ขั้น 2/3: อัป Netlify"
echo "   จะเปิด Finder (ไฟล์ zip) + หน้า Deploys ของ site $SITE"
echo "   → ลาก livingbkk-web.zip ลงกล่อง 「Drag and drop」"
echo ""
read -r -p "   กด Enter เมื่อเปิดหน้า Netlify แล้ว (จะเปิดให้)... " _

open -R "$ZIP"
open "$NETLIFY_DEPLOYS"

echo ""
read -r -p "   ลาก zip อัป Netlify เสร็จแล้วหรือยัง? (y/N): " netlify_done
if [[ ! "$netlify_done" =~ ^[Yy]$ ]]; then
  echo "   ⏸  ทำขั้น 2 ให้เสร็จก่อน แล้วรันสคริปต์นี้อีกครั้ง"
  exit 0
fi
echo ""

# --- 3) Supabase ---
echo "▶ ขั้น 3/3: Deploy Supabase"
if supabase projects list >/dev/null 2>&1; then
  echo "   ✅ login Supabase แล้ว — กำลัง deploy..."
  "$ROOT/scripts/deploy-projects-cloud.sh"
else
  echo "   ยังไม่ login — จะเปิด browser ให้ login"
  echo "   (ถ้าถามรหัส DB: ไป Supabase → Project Settings → Database)"
  echo ""
  supabase login
  "$ROOT/scripts/deploy-projects-cloud.sh"
fi

echo ""
echo "=============================================="
echo "  ✅ เสร็จครบ!"
echo "  เปิดแอp: https://${SITE}.netlify.app/admin/console"
echo "  → แท็บ「โครงการ」→ 1) ค้นหารายชื่อ → 2) ดึงชุดใหญ่"
echo "=============================================="
