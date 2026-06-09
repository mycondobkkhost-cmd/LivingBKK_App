#!/usr/bin/env bash
# ตรวจความพร้อมขึ้น Store แบบฟรี — ไม่นับ Firebase / keystore เป็นข้อบังคับ
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ok=0
warn=0
fail=0

pass() { echo "✅ $1"; ok=$((ok + 1)); }
note() { echo "ℹ️  $1"; warn=$((warn + 1)); }
must() {
  echo "❌ $1"
  fail=$((fail + 1))
}

check_contains() {
  local label="$1" file="$2" pattern="$3"
  if [[ -f "$file" ]] && grep -q "$pattern" "$file"; then
    pass "$label"
  else
    must "$label"
  fi
}

echo "=== PROPPITER store-free prep ==="
echo ""

# --- บังคับ (ฟรี) ---
check_contains "privacy.html" "mobile/web/legal/privacy.html" "PROPPITER"
check_contains "terms.html" "mobile/web/legal/terms.html" "PROPPITER"
check_contains "delete-account function" "supabase/functions/delete-account/index.ts" "deleteUser"
check_contains "ลบบัญชีในโปรไฟล์" "mobile/lib/features/profile/profile_page.dart" "deleteAccount"
check_contains "iOS location permission text" "mobile/ios/Runner/Info.plist" "NSLocationWhenInUseUsageDescription"
check_contains "iOS photo permission text" "mobile/ios/Runner/Info.plist" "NSPhotoLibraryUsageDescription"
check_contains "iOS export compliance" "mobile/ios/Runner/Info.plist" "ITSAppUsesNonExemptEncryption"
check_contains "Android INTERNET" "mobile/android/app/src/main/AndroidManifest.xml" "INTERNET"
check_contains "Android location" "mobile/android/app/src/main/AndroidManifest.xml" "ACCESS_FINE_LOCATION"
check_contains "store listing copy" "store-listing/descriptions-th.md" "PROPPITER"
check_contains "privacy answers doc" "store-listing/app-privacy-answers.md" "ข้อมูลที่เก็บ"

if [[ -f mobile/assets/env ]]; then
  if grep -qE '^TRIAL_MODE=(false|0|off|no)' mobile/assets/env; then
    pass "TRIAL_MODE=false"
  else
    must "TRIAL_MODE ยังไม่ปิด — ตั้ง false ก่อนส่งร้าน"
  fi
  web_base="$(grep -E '^WEB_BASE_URL=' mobile/assets/env | cut -d= -f2- | tr -d ' ' || true)"
  if [[ -n "$web_base" && "$web_base" != "https://" ]]; then
    pass "WEB_BASE_URL=$web_base"
    if command -v curl >/dev/null 2>&1; then
      for path in /legal/privacy.html /legal/terms.html; do
        code="$(curl -s -o /dev/null -w '%{http_code}' "${web_base}${path}" || echo 000)"
        if [[ "$code" == "200" ]]; then
          pass "URL live ${path} (HTTP 200)"
        else
          must "URL ${web_base}${path} ได้ HTTP $code — deploy เว็บใหม่"
        fi
      done
    else
      note "ไม่มี curl — เปิด ${web_base}/legal/privacy.html ด้วยมือ"
    fi
  else
    must "WEB_BASE_URL ว่าง — sync-env หลัง deploy"
  fi
else
  must "ไม่พบ mobile/assets/env — รัน ./scripts/sync-env.sh"
fi

ver="$(grep '^version:' mobile/pubspec.yaml | awk '{print $2}')"
if [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
  pass "version $ver"
else
  must "pubspec version ไม่ถูกรูปแบบ ($ver)"
fi

# --- ทางเลือก (ฟรี แต่ยังไม่บังคับ) ---
if [[ -f mobile/android/key.properties ]]; then
  pass "android/key.properties (release signing พร้อม)"
else
  note "ยังไม่มี key.properties — รัน ./scripts/generate-android-keystore.sh (ฟรี)"
fi

if [[ -f mobile/ios/Runner/GoogleService-Info.plist ]]; then
  pass "Firebase iOS plist"
else
  note "ไม่มี Firebase iOS — push นอกแอปปิดได้ ไม่กระทบส่งร้าน"
fi

if [[ -f scripts/generate-android-keystore.sh ]]; then
  pass "สคริปต์สร้าง keystore"
fi

echo ""
if [[ "$fail" -eq 0 ]]; then
  echo "สรุป: ✅ $ok ผ่าน · ℹ️ $warn ทางเลือก · พร้อมขั้นตอนฟรีแล้ว"
  echo "คู่มือ: docs/STORE-FREE-PREP.md"
  exit 0
fi

echo "สรุป: ✅ $ok ผ่าน · ❌ $fail ต้องแก้ · ℹ️ $warn ทางเลือก"
echo "คู่มือ: docs/STORE-FREE-PREP.md"
exit 1
