#!/usr/bin/env bash
# รัน Flutter web สำหรับเปิดใน Cursor Simple Browser (ไม่เปิด Chrome ภายนอก)
# คลิกลิงก์ด้านล่างในแชท หรือ Cmd+Shift+P → "Simple Browser: Show"
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
"$ROOT/scripts/sync-env.sh" 2>/dev/null || true
cd "$ROOT/mobile"
flutter pub get

pick_port() {
  for p in "$@"; do
    if ! lsof -ti ":$p" >/dev/null 2>&1; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

PORT="${1:-$(pick_port 8765 8766 8767 8084 || echo 8765)}"
BASE="http://127.0.0.1:${PORT}"

echo ""
echo "============================================"
echo "  PROPPITER — เปิดใน Cursor Simple Browser"
echo "============================================"
echo ""
echo "  หลังบ้าน (Admin):     ${BASE}/admin"
echo "  แชทคอนโซล:           ${BASE}/admin/console"
echo "  นำเข้าลิงก์:         ${BASE}/admin/import"
echo "  แอปลูกค้า (มือถือ):  ${BASE}/"
echo ""
echo "  Cursor: Cmd+Shift+P → Simple Browser: Show"
echo "          วาง URL ด้านบน"
echo ""
echo "  หยุด: กด q ใน Terminal นี้"
echo "============================================"
echo ""

exec flutter run -d web-server \
  --web-hostname=127.0.0.1 \
  --web-port="$PORT"
