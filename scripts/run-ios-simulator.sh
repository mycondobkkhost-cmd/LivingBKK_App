#!/usr/bin/env bash
# รัน RealXtate บน iOS Simulator — iPhone 17 Pro Max (440×956 pt, Dynamic Island)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
"$ROOT/scripts/sync-env.sh" 2>/dev/null || true

DEVICE="${1:-iPhone 17 Pro Max}"

cd "$ROOT/mobile"
flutter pub get >/dev/null 2>&1 || flutter pub get

echo ""
echo "============================================"
echo "  RealXtate — iOS Simulator"
echo "============================================"
echo "  อุปกรณ์:     ${DEVICE}"
echo "  Viewport:    440×956 pt (iPhone 17 Pro Max)"
echo "  Supabase:    จาก mobile/assets/env"
echo ""
echo "  เปิด Simulator แล้วรอ build ครั้งแรก (~1–3 นาที)"
echo "  Hot reload: กด r ในเทอร์มินัลนี้"
echo "  รุ่นอื่น:    ./scripts/run-ios-simulator.sh \"iPhone 15 Pro\""
echo "============================================"
echo ""

if command -v xcrun >/dev/null 2>&1; then
  if ! xcrun simctl list devices available 2>/dev/null | grep -q "${DEVICE}"; then
    echo "⚠️  ไม่พบ Simulator \"${DEVICE}\" — ลอง: xcrun simctl list devices available | grep iPhone"
    echo ""
  fi
  xcrun simctl boot "${DEVICE}" 2>/dev/null || true
  open -a Simulator 2>/dev/null || true
fi

exec flutter run -d "${DEVICE}"
