#!/usr/bin/env bash
# ติดตั้ง/ตั้งค่า iOS Simulator สำหรับ RealXtate (Flutter)
# ต้องมี Xcode จาก App Store ก่อน — สคริปต์นี้ทำขั้นตอนหลังติดตั้ง Xcode
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"

XCODE_APP="/Applications/Xcode.app"
DEVICE="${1:-iPhone 17 Pro Max}"

echo ""
echo "============================================"
echo "  RealXtate — ติดตั้ง iOS Simulator"
echo "============================================"
echo ""

# 1) ตรวจ Xcode เต็มรูปแบบ
if [[ ! -d "$XCODE_APP" ]]; then
  echo "❌ ยังไม่มี Xcode.app ใน /Applications"
  echo ""
  echo "ขั้นตอนที่ 1 (ทำด้วยมือ — ครั้งเดียว):"
  echo "  • เปิด App Store → ค้นหา \"Xcode\" → ติดตั้ง (~12 GB)"
  echo "  • หรือรันคำสั่งนี้เพื่อเปิดหน้า Xcode ใน App Store:"
  echo "      open \"macappstore://apps.apple.com/app/id497799835\""
  echo ""
  echo "ติดตั้ง Xcode เสร็จแล้ว รันสคริปต์นี้อีกครั้ง:"
  echo "  ./scripts/setup-ios-simulator.sh"
  echo ""
  open "macappstore://apps.apple.com/app/id497799835" 2>/dev/null || \
    open "https://apps.apple.com/app/xcode/id497799835" 2>/dev/null || true
  exit 1
fi

echo "✅ พบ Xcode.app"

# 2) ชี้ developer directory ไป Xcode
CURRENT="$(xcode-select -p 2>/dev/null || true)"
if [[ "$CURRENT" != "$XCODE_APP/Contents/Developer" ]]; then
  echo "→ ตั้งค่า xcode-select (ต้องใส่รหัส Mac)..."
  sudo xcode-select --switch "$XCODE_APP/Contents/Developer"
fi
echo "✅ xcode-select → Xcode"

# 3) ยอมรับ license + first launch
echo "→ xcodebuild -runFirstLaunch (ครั้งแรกอาจนาน)..."
sudo xcodebuild -runFirstLaunch 2>/dev/null || true
sudo xcodebuild -license accept 2>/dev/null || true

# 4) ดาวน์โหลด iOS Simulator runtime (ถ้ายังไม่มี)
echo "→ ตรวจ iOS Simulator runtime..."
if ! xcrun simctl list runtimes 2>/dev/null | grep -qi "iOS"; then
  echo "  กำลังดาวน์โหลด iOS platform (อาจใช้เวลา 10–30 นาที)..."
  xcodebuild -downloadPlatform iOS 2>/dev/null || \
    xcodebuild -downloadAllPlatforms 2>/dev/null || true
fi

# 5) CocoaPods (ต้องการ Ruby ใหม่ — Xcode ติดตั้งแล้วมักใช้ได้)
if ! command -v pod >/dev/null 2>&1; then
  echo "→ ติดตั้ง CocoaPods..."
  if command -v brew >/dev/null 2>&1; then
    brew install cocoapods
  elif sudo gem install cocoapods 2>/dev/null; then
    true
  else
    echo "  ลอง: sudo gem install cocoapods"
    echo "  หรือติดตั้ง Homebrew แล้ว: brew install cocoapods"
  fi
fi
if command -v pod >/dev/null 2>&1; then
  echo "✅ CocoaPods $(pod --version)"
else
  echo "⚠️  CocoaPods ยังไม่พบใน PATH — ลองเปิด Terminal ใหม่"
fi

# 6) Flutter iOS deps
cd "$ROOT/mobile"
flutter pub get
echo "→ pod install (iOS plugins)..."
cd ios && pod install && cd ..

# 7) เปิด Simulator + boot อุปกรณ์
echo "→ เปิด Simulator..."
open -a Simulator 2>/dev/null || true
sleep 2

if xcrun simctl list devices available 2>/dev/null | grep -q "$DEVICE"; then
  xcrun simctl boot "$DEVICE" 2>/dev/null || true
  echo "✅ Simulator: $DEVICE"
else
  echo "⚠️  ไม่พบ \"$DEVICE\" — รายการที่มี:"
  xcrun simctl list devices available 2>/dev/null | grep -i iphone | head -15 || true
  echo ""
  echo "  ใช้รุ่นที่มี: ./scripts/run-ios-simulator.sh \"iPhone 16 Pro Max\""
fi

# 8) ตรวจ Flutter
export PATH="/Users/angkarn1996/development/flutter/bin:$PATH"
echo ""
flutter doctor

echo ""
echo "============================================"
echo "  เสร็จ — รันแอปบน Simulator:"
echo "  ./scripts/run-ios-simulator.sh"
echo "============================================"
echo ""
