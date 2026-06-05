#!/usr/bin/env bash
# Phase 15 — สร้าง iOS release (ต้องมี Xcode + macOS รุ่นรองรับ)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/scripts/dev-path.sh"

cd "$ROOT/mobile"

BUILD_NAME="${BUILD_NAME:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

echo "=== LivingBKK iOS build ==="
echo "version: $BUILD_NAME+$BUILD_NUMBER"
echo ""

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "❌ ไม่พบ Xcode — iOS build ต้องใช้ Mac + Xcode"
  echo "   ทางเลือก: ใช้ PWA จาก ./scripts/build-web.sh (Phase 13)"
  exit 1
fi

if [[ -f "$ROOT/.env.local" ]]; then
  echo "→ sync env"
  "$ROOT/scripts/sync-env.sh"
fi

flutter pub get
flutter build ios --release \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER" \
  --no-codesign

echo ""
echo "✅ iOS build สำเร็จ (no-codesign)"
echo "   เปิด Xcode: open ios/Runner.xcworkspace"
echo "   Archive → Distribute App → App Store Connect"

if [[ ! -f ios/Runner/GoogleService-Info.plist ]]; then
  echo ""
  echo "ℹ️  ไม่พบ ios/Runner/GoogleService-Info.plist"
  echo "   รัน: cd mobile && flutterfire configure"
fi
