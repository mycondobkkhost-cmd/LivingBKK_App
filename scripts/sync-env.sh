#!/usr/bin/env bash
# คัดลอกค่าจาก .env.local → mobile/assets/env + mobile/web/index.html
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_LOCAL="$ROOT/.env.local"
ENV_MOBILE="$ROOT/mobile/assets/env"
INDEX_HTML="$ROOT/mobile/web/index.html"

if [[ ! -f "$ENV_LOCAL" ]]; then
  echo "❌ ไม่พบ $ENV_LOCAL"
  echo "   รัน: cp .env.local.example .env.local"
  echo "   แล้วใส่ SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_MAPS_API_KEY"
  exit 1
fi

# shellcheck disable=SC1090
set -a
source "$ENV_LOCAL"
set +a

_missing() {
  local v="$1"
  [[ -z "${!v:-}" ]] || [[ "${!v}" == *YOUR_* ]] || [[ "${!v}" == *your_* ]] || [[ "${!v}" == *xxxxxxxx* ]]
}

if [[ "${SUPABASE_ANON_KEY:-}" == *"..."* ]]; then
  echo "❌ SUPABASE_ANON_KEY ยังไม่ครบ — Copy ทั้งคีย์จาก Connect"
  exit 1
fi
for var in SUPABASE_URL SUPABASE_ANON_KEY; do
  if _missing "$var"; then
    echo "❌ ยังไม่ได้ตั้งค่า $var ใน .env.local"
    exit 1
  fi
done
if _missing GOOGLE_MAPS_API_KEY; then
  echo "ℹ️  GOOGLE_MAPS_API_KEY ว่าง — แผนที่จะเป็นโหมด placeholder จนกว่าจะใส่ key"
  GOOGLE_MAPS_API_KEY=
fi

cat > "$ENV_MOBILE" <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY:-}
WEB_BASE_URL=${WEB_BASE_URL:-}
TRIAL_MODE=${TRIAL_MODE:-false}
FIREBASE_API_KEY=${FIREBASE_API_KEY:-}
FIREBASE_APP_ID=${FIREBASE_APP_ID:-}
FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID:-}
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID:-}
EOF

# อัปเดต Google Maps script บน Web (เฉพาะเมื่อมี key จริง)
if [[ -f "$INDEX_HTML" ]]; then
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i '/LIVINGBKK_GOOGLE_MAPS_SCRIPT/d' "$INDEX_HTML"
    sed -i '/maps.googleapis.com\/maps\/api\/js/d' "$INDEX_HTML"
  else
    sed -i '' '/LIVINGBKK_GOOGLE_MAPS_SCRIPT/d' "$INDEX_HTML"
    sed -i '' '/maps.googleapis.com\/maps\/api\/js/d' "$INDEX_HTML"
  fi

  if [[ -n "${GOOGLE_MAPS_API_KEY:-}" ]] && ! _missing GOOGLE_MAPS_API_KEY; then
    MAPS_ESC="${GOOGLE_MAPS_API_KEY//\\/\\\\}"
    MAPS_LINE="  <script src=\"https://maps.googleapis.com/maps/api/js?key=${MAPS_ESC}\"></script>"
    python3 - "$INDEX_HTML" "$MAPS_LINE" <<'PY'
import sys
path, line = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
needle = "<!-- LIVINGBKK_GOOGLE_MAPS_SCRIPT -->"
if needle in text:
    text = text.replace(needle, line + "\n  " + needle, 1)
    open(path, "w", encoding="utf-8").write(text)
PY
  else
    if sed --version 2>/dev/null | grep -q GNU; then
      sed -i 's|<!-- LIVINGBKK_GOOGLE_MAPS_SCRIPT -->|  <!-- LIVINGBKK_GOOGLE_MAPS_SCRIPT (no key - OSM map) -->|' "$INDEX_HTML"
    else
      sed -i '' 's|<!-- LIVINGBKK_GOOGLE_MAPS_SCRIPT -->|  <!-- LIVINGBKK_GOOGLE_MAPS_SCRIPT (no key - OSM map) -->|' "$INDEX_HTML"
    fi
  fi
fi

if _missing FIREBASE_PROJECT_ID; then
  echo "ℹ️  Firebase ว่าง — ใช้ Realtime ในแอป; ใส่ FIREBASE_* เพื่อ FCM push"
fi
if [[ -z "${WEB_BASE_URL:-}" ]]; then
  echo "ℹ️  WEB_BASE_URL ว่าง — ลิงก์แชร์ใช้ URL ปัจจุบันบนเว็บ หรือ livingbkk.app"
else
  echo "ℹ️  WEB_BASE_URL = ${WEB_BASE_URL}"
fi

echo "✅ อัปเดตแล้ว:"
echo "   - $ENV_MOBILE"
echo "   - $INDEX_HTML"

# Android — ใส่ key ใน local.properties สำหรับ native Maps
LOCAL_PROPS="$ROOT/mobile/android/local.properties"
if [[ -f "$LOCAL_PROPS" ]]; then
  if grep -q '^GOOGLE_MAPS_API_KEY=' "$LOCAL_PROPS" 2>/dev/null; then
    if sed --version 2>/dev/null | grep -q GNU; then
      sed -i "s|^GOOGLE_MAPS_API_KEY=.*|GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY:-}|" "$LOCAL_PROPS"
    else
      sed -i '' "s|^GOOGLE_MAPS_API_KEY=.*|GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY:-}|" "$LOCAL_PROPS"
    fi
  else
    printf '\nGOOGLE_MAPS_API_KEY=%s\n' "${GOOGLE_MAPS_API_KEY:-}" >> "$LOCAL_PROPS"
  fi
else
  echo "ℹ️  ไม่พบ $LOCAL_PROPS — รัน flutter pub get ใน mobile/ ก่อน"
fi
if [[ -n "${GOOGLE_MAPS_API_KEY:-}" ]] && ! _missing GOOGLE_MAPS_API_KEY; then
  echo "   - $LOCAL_PROPS (GOOGLE_MAPS_API_KEY)"
fi

# iOS — GMSServices ใน AppDelegate
APP_DELEGATE="$ROOT/mobile/ios/Runner/AppDelegate.swift"
if [[ -f "$APP_DELEGATE" ]]; then
  if [[ -n "${GOOGLE_MAPS_API_KEY:-}" ]] && ! _missing GOOGLE_MAPS_API_KEY; then
    if ! grep -q 'import GoogleMaps' "$APP_DELEGATE"; then
      if sed --version 2>/dev/null | grep -q GNU; then
        sed -i '/import Flutter/a import GoogleMaps' "$APP_DELEGATE"
      else
        sed -i '' '/import Flutter/a\
import GoogleMaps
' "$APP_DELEGATE"
      fi
    fi
    KEY_ESC="${GOOGLE_MAPS_API_KEY//\\/\\\\}"
    KEY_ESC="${KEY_ESC//\"/\\\"}"
    if grep -q 'LIVINGBKK_GOOGLE_MAPS_INIT' "$APP_DELEGATE"; then
      if sed --version 2>/dev/null | grep -q GNU; then
        sed -i "s|// LIVINGBKK_GOOGLE_MAPS_INIT.*|GMSServices.provideAPIKey(\"${KEY_ESC}\")|" "$APP_DELEGATE"
      else
        sed -i '' "s|// LIVINGBKK_GOOGLE_MAPS_INIT.*|GMSServices.provideAPIKey(\"${KEY_ESC}\")|" "$APP_DELEGATE"
      fi
    else
      if sed --version 2>/dev/null | grep -q GNU; then
        sed -i "/GeneratedPluginRegistrant.register/a \\    GMSServices.provideAPIKey(\"${KEY_ESC}\")" "$APP_DELEGATE"
      else
        sed -i '' "/GeneratedPluginRegistrant.register/a\\
    GMSServices.provideAPIKey(\"${KEY_ESC}\")
" "$APP_DELEGATE"
      fi
    fi
    echo "   - $APP_DELEGATE"
  fi
fi
