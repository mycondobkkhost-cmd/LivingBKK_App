#!/usr/bin/env bash
# อัปเดตเว็b LivingBKK บน Netlify — ไม่ต้องลาก (คลิกเลือกไฟล์ได้)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ZIP="$ROOT/mobile/build/livingbkk-web.zip"
WEB="$ROOT/mobile/build/web"

if [[ ! -f "$ZIP" ]]; then
  echo "ยังไม่มี zip — กำลัง build..."
  "$ROOT/scripts/build-web.sh"
  (cd "$WEB" && zip -r -q "$ZIP" .)
fi

echo ""
echo "============================================"
echo "  อัปเดต Netlify — ทำบน Mac (Chrome/Safari)"
echo "============================================"
echo ""
echo "ไฟล์ที่ต้องอัปโหลด:"
echo "  $ZIP"
echo ""
echo "วิธีที่ 1 — ง่ายสุด (ไม่ต้องลาก)"
echo "  1) เปิดหน้า Deploys ของ site เดิม (quiet-kangaroo)"
echo "  2) ลาก livingbkk-web.zip ลงกล่อง Drag and drop"
echo ""
echo "วิธีที่ 2 — อัปเดต site เดิม quiet-kangaroo"
echo "  1) เข้า https://app.netlify.com และ Log in"
echo "  2) กด Sites → quiet-kangaroo-ab6073"
echo "  3) แท็บ Deploys → ลาก zip ลงกล่องด้านล่าง"
echo "     หรือ Deploys → Deploy manually → Browse"
echo ""
echo "เปิด Finder (ไฟล์ zip) + หน้า Netlify Deploys..."
echo ""

open -R "$ZIP"
SITE="${NETLIFY_SITE:-quiet-kangaroo-ab6073}"
NETLIFY_URL="https://app.netlify.com/sites/${SITE}/deploys"
open "$NETLIFY_URL"
