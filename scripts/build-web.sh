#!/usr/bin/env bash
# สร้างเว็บแอป LivingBKK สำหรับเอาไปวางบน Netlify / โฮสต์
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== LivingBKK — สร้างเว็บแอป ==="
echo ""

if [[ -f "$ROOT/.env.local" ]]; then
  "$ROOT/scripts/sync-env.sh"
else
  echo "⚠️  ยังไม่มี .env.local — ใช้ค่าใน mobile/assets/env อย่างเดียว"
fi

cd "$ROOT/mobile"
flutter pub get
echo ""
echo "กำลัง build (ใช้เวลา 1–3 นาที)..."
flutter build web --release

OUT="$ROOT/mobile/build/web"
echo ""
echo "✅ เสร็จแล้ว"
echo ""
echo "โฟลเดอร์ที่อัปโหลด:"
echo "  $OUT"
echo ""
echo "ขั้นถัดไป:"
echo "  1) เปิด https://app.netlify.com/drop"
echo "  2) ลากโฟลเดอร์ build/web ไปวาง"
echo "  3) ได้ลิงก์ เช่น https://your-app.netlify.app"
echo "  4) ใส่ลิงก์นั้นใน .env.local → WEB_BASE_URL=https://your-app.netlify.app"
echo "  5) รัน ./scripts/sync-env.sh && ./scripts/build-web.sh อีกครั้ง (ลิงก์แชร์จะถูกต้อง)"
echo ""
echo "ทดสอบลิงก์ห้อง: https://your-app.netlify.app/listing/<id>"
echo "แอดมินบนคอม: /admin"
echo ""
echo "คู่มือ: docs/คู่มือ-ใช้แอปบนมือถือ.md"
