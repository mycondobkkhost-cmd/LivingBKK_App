#!/usr/bin/env bash
# รีเฟรชเว็บแอปหลังแก้โค้ด — สำหรับเปิดใน Cursor Simple Browser
# ใช้เมื่อมีการแก้ mobile/ แล้วต้องการดูผลทันที (build + serve)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
"$ROOT/scripts/sync-env.sh" 2>/dev/null || true

PORT="${1:-8766}"
BASE="http://127.0.0.1:${PORT}"

cd "$ROOT/mobile"
flutter pub get
echo ""
echo "=== PROPPITER — build web (รอสักครู่) ==="
flutter build web --release

# หยุดเซิร์ฟเวอร์เดิมบนพอร์ตเดียวกัน (ถ้ามี)
if lsof -ti ":$PORT" >/dev/null 2>&1; then
  lsof -ti ":$PORT" | xargs kill -9 2>/dev/null || true
  sleep 1
fi

echo ""
echo "============================================"
echo "  PROPPITER — พร้อมเปิดใน Cursor"
echo "============================================"
echo ""
echo "  หลังบ้าน (Admin):     ${BASE}/admin"
echo "  ปฏิทินนัดดู:         ${BASE}/admin?nav=viewingCalendar"
echo "  แชทคอนโซล:           ${BASE}/admin/console"
echo "  แอปลูกค้า:           ${BASE}/"
echo ""
echo "  Cursor: Cmd+Shift+P → Simple Browser: Show"
echo "============================================"
echo ""

exec "$ROOT/scripts/serve-web.sh" "$PORT"
