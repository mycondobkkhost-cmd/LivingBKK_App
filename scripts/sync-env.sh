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
GOOGLE_MAPS_WEB_USE_OSM=${GOOGLE_MAPS_WEB_USE_OSM:-false}
WEB_BASE_URL=${WEB_BASE_URL:-}
TRIAL_MODE=${TRIAL_MODE:-false}
ADMIN_DEMO_CASES=${ADMIN_DEMO_CASES:-false}
FIREBASE_API_KEY=${FIREBASE_API_KEY:-}
FIREBASE_APP_ID=${FIREBASE_APP_ID:-}
FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID:-}
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID:-}
EOF

# อัปเดต Google Maps script บน Web (เฉพาะเมื่อมี key จริง)
if [[ -f "$INDEX_HTML" ]]; then
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i '/maps.googleapis.com\/maps\/api\/js/d' "$INDEX_HTML"
  else
    sed -i '' '/maps.googleapis.com\/maps\/api\/js/d' "$INDEX_HTML"
  fi

  # คืน marker ถ้าหาย (เคยถูก sed ลบในรุ่นเก่า)
  if ! grep -q 'LIVINGBKK_GOOGLE_MAPS_SCRIPT' "$INDEX_HTML"; then
    python3 - "$INDEX_HTML" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
needle = "  <!-- Google Maps: sync-env.sh ใส่ script เมื่อมี GOOGLE_MAPS_API_KEY ใน .env.local -->"
insert = needle + "\n  <!-- LIVINGBKK_GOOGLE_MAPS_SCRIPT -->"
if needle in text and "LIVINGBKK_GOOGLE_MAPS_SCRIPT" not in text:
    text = text.replace(needle, insert, 1)
    open(path, "w", encoding="utf-8").write(text)
PY
  fi

  if [[ -n "${GOOGLE_MAPS_API_KEY:-}" ]] && ! _missing GOOGLE_MAPS_API_KEY; then
    MAPS_ESC="${GOOGLE_MAPS_API_KEY//\\/\\\\}"
    MAPS_ESC="${MAPS_ESC//\"/\\\"}"
    python3 - "$INDEX_HTML" "$MAPS_ESC" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
key = sys.argv[2]
text = path.read_text(encoding="utf-8")

# ลบ script maps + auth failure เก่า
text = re.sub(
    r"\s*<script[^>]*maps\.googleapis\.com/maps/api/js[^>]*>\s*</script>\s*",
    "\n",
    text,
)
text = re.sub(
    r"\s*<script>\s*// LIVINGBKK_GMAPS_AUTH_FAILURE[\s\S]*?</script>\s*",
    "\n",
    text,
)

maps_block = f'''  <script src="https://maps.googleapis.com/maps/api/js?key={key}"></script>
  <script>
    // LIVINGBKK_GMAPS_AUTH_FAILURE
    window.gm_authFailure = function () {{
      window.__LIVINGBKK_GMAPS_FAILED = true;
      try {{ localStorage.setItem('livingbkk_gmaps_failed', '1'); }} catch (e) {{}}
      window.dispatchEvent(new Event('livingbkk-gmaps-failed'));
    }};
  </script>
  <!-- LIVINGBKK_GOOGLE_MAPS_SCRIPT -->'''

needle = "<!-- LIVINGBKK_GOOGLE_MAPS_SCRIPT -->"
if needle in text:
    text = text.replace(needle, maps_block, 1)
else:
    # คืน marker + block ใต้คอมเมนต์ Google Maps
    marker_comment = "  <!-- Google Maps: sync-env.sh ใส่ script เมื่อมี GOOGLE_MAPS_API_KEY ใน .env.local -->"
    if marker_comment in text:
        text = text.replace(
            marker_comment,
            marker_comment + "\n" + maps_block,
            1,
        )

path.write_text(text, encoding="utf-8")
PY
  else
    python3 - "$INDEX_HTML" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
text = re.sub(
    r"\s*<script[^>]*maps\.googleapis\.com/maps/api/js[^>]*>\s*</script>\s*",
    "\n",
    text,
)
text = re.sub(
    r"\s*<script>\s*// LIVINGBKK_GMAPS_AUTH_FAILURE[\s\S]*?</script>\s*",
    "\n",
    text,
)
if "LIVINGBKK_GOOGLE_MAPS_SCRIPT" not in text:
    marker_comment = "  <!-- Google Maps: sync-env.sh ใส่ script เมื่อมี GOOGLE_MAPS_API_KEY ใน .env.local -->"
    if marker_comment in text:
        text = text.replace(
            marker_comment,
            marker_comment + "\n  <!-- LIVINGBKK_GOOGLE_MAPS_SCRIPT (no key - OSM map) -->",
            1,
        )
elif "<!-- LIVINGBKK_GOOGLE_MAPS_SCRIPT -->" in text:
    text = text.replace(
        "<!-- LIVINGBKK_GOOGLE_MAPS_SCRIPT -->",
        "<!-- LIVINGBKK_GOOGLE_MAPS_SCRIPT (no key - OSM map) -->",
        1,
    )
path.write_text(text, encoding="utf-8")
PY
  fi
fi

if _missing FIREBASE_PROJECT_ID; then
  echo "ℹ️  Firebase ว่าง — ใช้ Realtime ในแอป; ใส่ FIREBASE_* เพื่อ FCM push"
fi
if [[ -z "${WEB_BASE_URL:-}" ]]; then
  echo "ℹ️  WEB_BASE_URL ว่าง — ลิงก์แชร์ใช้ URL ปัจจุบันบนเว็บ หรือ realxtateth.com"
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

# iOS — GMSServices ใน AppDelegate (idempotent — ไม่ซ้อนบรรทัดซ้ำ)
APP_DELEGATE="$ROOT/mobile/ios/Runner/AppDelegate.swift"
if [[ -f "$APP_DELEGATE" ]]; then
  if [[ -n "${GOOGLE_MAPS_API_KEY:-}" ]] && ! _missing GOOGLE_MAPS_API_KEY; then
    KEY_ESC="${GOOGLE_MAPS_API_KEY//\\/\\\\}"
    KEY_ESC="${KEY_ESC//\"/\\\"}"
    python3 - "$APP_DELEGATE" "$KEY_ESC" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
key = sys.argv[2]
text = path.read_text()
lines = text.splitlines()

# ลบ GMSServices ซ้ำทั้งหมดก่อน
lines = [ln for ln in lines if "GMSServices.provideAPIKey" not in ln]

# ใส่ import GoogleMaps หลัง import Flutter ถ้ายังไม่มี
if not any("import GoogleMaps" in ln for ln in lines):
    out = []
    for ln in lines:
        out.append(ln)
        if ln.strip() == "import Flutter":
            out.append("import GoogleMaps")
    lines = out

init_line = f'    GMSServices.provideAPIKey("{key}") // LIVINGBKK_GOOGLE_MAPS_INIT'
out = []
inserted = False
for ln in lines:
    out.append(ln)
    if (not inserted) and "GeneratedPluginRegistrant.register" in ln:
        out.append(init_line)
        inserted = True

if not inserted:
    # fallback — ใส่ก่อน return super.application
    out2 = []
    for ln in out:
        if (not inserted) and "return super.application" in ln:
            out2.append(init_line)
            inserted = True
        out2.append(ln)
    out = out2

path.write_text("\n".join(out) + "\n")
PY
    echo "   - $APP_DELEGATE"
  fi
fi
