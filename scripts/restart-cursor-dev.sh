#!/usr/bin/env bash
# รีสตาร์ท Flutter web สำหรับ Cursor Simple Browser (ไม่เปิด Chrome ภายนอก)
# ใช้หลังแก้ mobile/ ทุกครั้ง — ค่าเริ่มต้นพอร์ต 7357
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
"$ROOT/scripts/sync-env.sh" 2>/dev/null || true

PORT="${1:-7357}"
BASE="http://127.0.0.1:${PORT}"

cd "$ROOT/mobile"
flutter pub get >/dev/null 2>&1 || flutter pub get

if lsof -ti ":$PORT" >/dev/null 2>&1; then
  lsof -ti ":$PORT" | xargs kill -9 2>/dev/null || true
  sleep 1
fi

echo ""
echo "============================================"
echo "  PROPPITER — dev server (Cursor)"
echo "============================================"
echo "  แอปลูกค้า:  ${BASE}/"
echo "  Admin:       ${BASE}/admin"
echo ""
echo "  Cursor: Cmd+Shift+P → Simple Browser: Show"
echo "  Hot restart หลังแก้โค้ด: กด R ในเทอร์มินัลนี้"
echo "============================================"
echo ""

exec flutter run -d web-server \
  --web-hostname=127.0.0.1 \
  --web-port="$PORT"
