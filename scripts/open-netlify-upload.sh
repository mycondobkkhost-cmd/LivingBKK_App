#!/usr/bin/env bash
# เตรียมไฟล์เว็b + เปิด Netlify Drop ให้ลากอัปโหลด (ครั้งเดียว ~1 นาที)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB_DIR="$ROOT/mobile/build/web"
ZIP="$ROOT/mobile/build/livingbkk-web.zip"

echo "=== LivingBKK — เตรียมอัปโหลด Netlify ==="
echo ""

if [[ ! -d "$WEB_DIR/index.html" ]] && [[ ! -f "$WEB_DIR/index.html" ]]; then
  echo "ยังไม่มี build/web — กำลัง build..."
  "$ROOT/scripts/build-web.sh"
fi

echo "กำลัง zip ไฟล์เว็b..."
rm -f "$ZIP"
(
  cd "$WEB_DIR"
  zip -r -q "$ZIP" .
)

echo ""
echo "✅ พร้อมอัปโหลด"
echo "   โฟลเดอร์: $WEB_DIR"
echo "   ไฟล์ zip:  $ZIP"
echo ""
echo "เปิด Finder + Netlify Drop ให้แล้ว..."
echo ""
echo "👉 ลากโฟลเดอร์ 'web' หรือไฟล์ 'livingbkk-web.zip' ไปวางในหน้าเบราว์เซอร์"
echo "👉 ได้ลิงก์แล้ว copy มาใส่ .env.local → WEB_BASE_URL=https://....netlify.app"
echo "👉 รัน ./scripts/sync-env.sh && ./scripts/build-web.sh อีกครั้ง"
echo ""

open "$WEB_DIR"
open "https://app.netlify.com/drop"
