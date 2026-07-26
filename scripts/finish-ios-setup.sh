#!/usr/bin/env bash
# ขั้นตอนหลังยอมรับ Xcode license แล้ว (รันต่อจาก setup-ios-simulator.sh)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
export PATH="/Users/angkarn1996/development/flutter/bin:$PATH"

DEVICE="${1:-iPhone 17 Pro Max}"

echo ""
echo "============================================"
echo "  RealXtate — ตั้งค่า iOS (ต่อ)"
echo "============================================"

# ตรวจ license
if ! xcrun simctl list devices >/dev/null 2>&1; then
  echo "❌ ยังไม่ได้ยอมรับ Xcode license"
  echo ""
  echo "ทำอย่างใดอย่างหนึ่ง:"
  echo "  1) เปิด Xcode → กด Agree ในหน้าต่าง license"
  echo "  2) หรือรันใน Terminal:"
  echo "       sudo xcodebuild -license accept"
  echo "       sudo xcodebuild -runFirstLaunch"
  echo ""
  open -a Xcode 2>/dev/null || true
  exit 1
fi

echo "✅ Xcode license OK"

# iOS runtime
if ! xcrun simctl list runtimes 2>/dev/null | grep -qi "iOS"; then
  echo "→ ดาวน์โหลด iOS Simulator runtime..."
  xcodebuild -downloadPlatform iOS 2>&1 | tail -5 || true
fi

# CocoaPods
if ! command -v pod >/dev/null 2>&1; then
  echo "→ ติดตั้ง CocoaPods (ต้องใส่รหัส Mac)..."
  sudo gem install cocoapods
fi
echo "✅ CocoaPods $(pod --version)"

# Flutter deps
cd "$ROOT/mobile"
flutter pub get
cd ios && pod install && cd ..

# Simulator
open -a Simulator 2>/dev/null || true
sleep 2

if xcrun simctl list devices available 2>/dev/null | grep -q "$DEVICE"; then
  xcrun simctl boot "$DEVICE" 2>/dev/null || true
  echo "✅ Boot: $DEVICE"
else
  echo "⚠️  ไม่พบ \"$DEVICE\" — รายการ iPhone:"
  xcrun simctl list devices available 2>/dev/null | grep -i iphone | head -12
fi

flutter doctor

echo ""
echo "รันแอป: ./scripts/run-ios-simulator.sh"
echo "============================================"
echo ""
