#!/usr/bin/env bash
# Phase 15 — สร้าง APK/AAB สำหรับ Android (Play Store หรือ sideload)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/scripts/dev-path.sh"

cd "$ROOT/mobile"

MODE="${1:-apk}"
BUILD_NAME="${BUILD_NAME:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

echo "=== LivingBKK Android build ($MODE) ==="
echo "version: $BUILD_NAME+$BUILD_NUMBER"
echo ""

if [[ -f "$ROOT/.env.local" ]]; then
  echo "→ sync env"
  "$ROOT/scripts/sync-env.sh"
fi

flutter pub get

case "$MODE" in
  apk)
    flutter build apk --release \
      --build-name="$BUILD_NAME" \
      --build-number="$BUILD_NUMBER"
    echo ""
    echo "✅ APK: mobile/build/app/outputs/flutter-apk/app-release.apk"
    ;;
  aab|appbundle)
    flutter build appbundle --release \
      --build-name="$BUILD_NAME" \
      --build-number="$BUILD_NUMBER"
    echo ""
    echo "✅ AAB: mobile/build/app/outputs/bundle/release/app-release.aab"
    ;;
  *)
    echo "Usage: $0 [apk|aab]"
    exit 1
    ;;
esac

if [[ ! -f android/app/google-services.json ]]; then
  echo ""
  echo "ℹ️  ไม่พบ android/app/google-services.json"
  echo "   FCM บน Android ใช้ Env.firebaseOptions จาก assets/env ได้"
  echo "   สำหรับ Play Store แนะนำ: cd mobile && flutterfire configure"
fi
