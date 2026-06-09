#!/usr/bin/env bash
# ตรวจความพร้อมส่ง App Store / Play Store (ไม่แทนการทดสอบบนเครื่องจริง)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ok=0
warn=0

pass() {
  echo "✅ $1"
  ok=$((ok + 1))
}

fail() {
  echo "⚠️  $1"
  warn=$((warn + 1))
}

check_file_contains() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [[ -f "$file" ]] && grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

echo "=== PROPPITER store-ready checks ==="
echo ""

# --- ร่วม (Shared) ---
check_file_contains "legal/privacy.html" "mobile/web/legal/privacy.html" "PROPPITER"
check_file_contains "legal/terms.html" "mobile/web/legal/terms.html" "PROPPITER"
check_file_contains "delete-account Edge Function" "supabase/functions/delete-account/index.ts" "deleteUser"
check_file_contains "account deletion in profile" "mobile/lib/features/profile/profile_page.dart" "deleteAccount"

if [[ -f mobile/assets/env ]]; then
  if grep -qE '^TRIAL_MODE=(false|0|off|no)' mobile/assets/env; then
    pass "TRIAL_MODE=false ใน assets/env"
  else
    fail "TRIAL_MODE ยังไม่ปิดใน assets/env — ตั้ง TRIAL_MODE=false ก่อนส่งร้าน"
  fi
  web_base="$(grep -E '^WEB_BASE_URL=' mobile/assets/env | cut -d= -f2- | tr -d ' ' || true)"
  if [[ -n "$web_base" && "$web_base" != "https://" ]]; then
    pass "WEB_BASE_URL ตั้งแล้ว ($web_base)"
    echo "   → ทดสอบ: ${web_base}/legal/privacy.html"
    echo "   → ทดสอบ: ${web_base}/legal/terms.html"
  else
    fail "WEB_BASE_URL ว่าง — ใส่ URL หลัง deploy Netlify แล้ว sync-env"
  fi
else
  fail "ไม่พบ mobile/assets/env — รัน ./scripts/sync-env.sh"
fi

pubspec_ver="$(grep '^version:' mobile/pubspec.yaml | awk '{print $2}')"
if [[ "$pubspec_ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
  pass "pubspec version: $pubspec_ver"
else
  fail "pubspec version ไม่เป็นรูปแบบ x.y.z+n ($pubspec_ver)"
fi

# --- Android ---
check_file_contains "Android INTERNET permission" "mobile/android/app/src/main/AndroidManifest.xml" "INTERNET"
check_file_contains "Android location permissions" "mobile/android/app/src/main/AndroidManifest.xml" "ACCESS_FINE_LOCATION"
check_file_contains "Android POST_NOTIFICATIONS" "mobile/android/app/src/main/AndroidManifest.xml" "POST_NOTIFICATIONS"
check_file_contains "key.properties.example" "mobile/android/key.properties.example" "storePassword"

if [[ -f mobile/android/key.properties ]]; then
  pass "android/key.properties มีแล้ว (release signing)"
else
  fail "ยังไม่มี android/key.properties — cp key.properties.example แล้วสร้าง keystore (ดู docs/STORE-SUBMISSION-CHECKLIST.md)"
fi

if grep -q "keystorePropertiesFile.exists()" mobile/android/app/build.gradle; then
  pass "build.gradle อ่าน key.properties เมื่อมี"
else
  fail "build.gradle ยังไม่รองรับ release signing จาก key.properties"
fi

# --- iOS ---
check_file_contains "iOS NSLocationWhenInUseUsageDescription" "mobile/ios/Runner/Info.plist" "NSLocationWhenInUseUsageDescription"
check_file_contains "iOS NSPhotoLibraryUsageDescription" "mobile/ios/Runner/Info.plist" "NSPhotoLibraryUsageDescription"

if [[ -f mobile/ios/Runner/GoogleService-Info.plist ]]; then
  pass "GoogleService-Info.plist (FCM iOS)"
else
  fail "ไม่มี GoogleService-Info.plist — รัน flutterfire configure ถ้าใช้ push"
fi

echo ""
echo "สรุป store-ready: ✅ $ok ผ่าน · ⚠️ $warn ควรแก้"
echo "คู่มือขั้นตอนด้วยมือ: docs/STORE-SUBMISSION-CHECKLIST.md"

exit 0
