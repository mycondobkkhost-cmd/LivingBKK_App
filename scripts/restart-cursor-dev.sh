#!/usr/bin/env bash
# เริ่ม Flutter web สำหรับ Cursor Simple Browser (live preview)
# รันครั้งเดียวต่อเซสชัน — แก้ UI แล้ว Save → hot reload อัตโนมัติ (.vscode/settings.json)
# รีสตาร์ทใหม่เฉพาะเมื่อ hot reload ไม่พอ หรือเปลี่ยน pubspec/env/route ใหม่
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
echo "  RealXtate — dev server (Cursor)"
echo "============================================"
echo "  แอปลูกค้า:  ${BASE}/"
echo "  Admin:       ${BASE}/admin"
echo ""
echo "  Cursor: Cmd+Shift+P → Simple Browser: Show → เปิดลิงก์แล้วค้างไว้"
echo "  แก้ UI: Save ไฟล์ → hot reload อัตโนมัติ (ดูในแท็บเดิม)"
echo "  ถ้าไม่ขึ้น: refresh แท็บ หรือกด R (hot restart) ในเทอร์มินัลนี้"
echo "============================================"
echo ""

exec flutter run -d web-server \
  --web-hostname=127.0.0.1 \
  --web-port="$PORT"
