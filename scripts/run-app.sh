#!/usr/bin/env bash
# รันแอป LivingBKK บน Chrome (หา port ว่างให้อัตโนมัติ)
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

if [[ -n "${1:-}" ]]; then
  PORT="$1"
else
  PORT="$(pick_port 8084 8085 8086 8083 8090)" || {
    echo "❌ พอร์ต 8083–8090 ถูกใช้หมดแล้ว"
    echo "   ปิด Terminal เก่าที่รัน flutter อยู่ หรือรัน: ./scripts/run-app.sh 8091"
    exit 1
  }
fi

echo ""
echo "============================================"
echo "  เปิด Chrome: http://localhost:$PORT"
echo "  หยุดแอป: กด q ใน Terminal นี้"
echo "  โหลดใหม่: กด R (ตัวใหญ่)"
echo "============================================"
echo ""

flutter run -d chrome --web-port="$PORT"
