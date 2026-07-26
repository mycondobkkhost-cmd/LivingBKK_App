#!/usr/bin/env bash
# เปิด 3 หน้าต่าง Chrome แยก profile — ลูกค้า / ผู้เสนอ / แอดมิน
# ใช้คู่กับ dev server ที่พอร์ต 7357 (restart-cursor-dev.sh)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-7357}"
BASE="http://127.0.0.1:${PORT}"
MODE="${1:---real}"
PROFILE_ROOT="$ROOT/.dev-chrome-profiles"

if ! command -v open >/dev/null 2>&1 && [[ "$(uname -s)" == "Darwin" ]]; then
  echo "❌ ไม่พบคำสั่ง open บน macOS"
  exit 1
fi

CHROME_APP=""
if [[ -d "/Applications/Google Chrome.app" ]]; then
  CHROME_APP="Google Chrome"
elif [[ -d "/Applications/Chromium.app" ]]; then
  CHROME_APP="Chromium"
fi

if [[ -z "$CHROME_APP" ]]; then
  echo "❌ ไม่พบ Google Chrome — ติดตั้งจาก https://www.google.com/chrome/"
  exit 1
fi

if ! lsof -ti ":$PORT" >/dev/null 2>&1; then
  echo "⚠️  dev server ยังไม่รันที่พอร์ต $PORT — กำลังเริ่ม..."
  "$ROOT/scripts/restart-cursor-dev.sh" "$PORT" &
  for _ in $(seq 1 90); do
    if curl -sf "$BASE/" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
  if ! curl -sf "$BASE/" >/dev/null 2>&1; then
    echo "❌ รอ dev server ไม่สำเร็จ — รัน ./scripts/restart-cursor-dev.sh ก่อน"
    exit 1
  fi
fi

AUTH_Q=""
if [[ "$MODE" == "--real" ]]; then
  AUTH_Q="&devAuth=real"
  echo "โหมด: Supabase จริง (3 บัญชีแยก — sync แชทได้)"
else
  echo "โหมด: ทดลอง (UI แยกหน้าต่าง)"
fi

open_window() {
  local label="$1"
  local name="$2"
  local url="$3"
  local profile="$PROFILE_ROOT/$name"
  mkdir -p "$profile"
  echo "→ $label: $url"

  if [[ "$(uname -s)" == "Darwin" ]]; then
    # open -na = เปิด Chrome instance ใหม่ + โผล่หน้าจอ (ดีกว่าเรียก binary ตรงๆ)
    open -na "$CHROME_APP" --args \
      "--user-data-dir=$profile" \
      "--no-first-run" \
      "--no-default-browser-check" \
      "--new-window" \
      "$url"
  else
    local chrome_bin=""
    for candidate in \
      "/usr/bin/google-chrome" \
      "/usr/bin/chromium" \
      "/usr/bin/chromium-browser"; do
      if [[ -x "$candidate" ]]; then
        chrome_bin="$candidate"
        break
      fi
    done
    if [[ -z "$chrome_bin" ]]; then
      echo "❌ ไม่พบ Chrome/Chromium บน Linux"
      exit 1
    fi
    "$chrome_bin" \
      --user-data-dir="$profile" \
      --no-first-run \
      --new-window \
      "$url" &
  fi
  sleep 1
}

# จัด POV ทรัพย์เดียวกัน (เจ้าของมีประกาศ · ลูกค้า+แอดมินแชททรัพย์นั้น)
POV_JSON=""
if [[ "$MODE" == "--real" && -f "$ROOT/.env.local" ]]; then
  POV_JSON="$("$ROOT/scripts/seed-three-role-pov.sh" 2>/dev/null)" || true
fi

if [[ -n "$POV_JSON" ]] && echo "$POV_JSON" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
  LISTING_CODE="$(echo "$POV_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['listing_code'])")"
  THREAD_ID="$(echo "$POV_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['thread_id'])")"
  SEEKER_URL="${BASE}/?preview=1&tab=contact&devRole=seeker${AUTH_Q}&devListing=${LISTING_CODE}&devOpenChat=1"
  OFFERER_URL="${BASE}/?preview=1&tab=mine&devRole=offerer${AUTH_Q}"
  ADMIN_URL="${BASE}/admin/console?devRole=admin${AUTH_Q}&room=${THREAD_ID}"
  echo "POV ทรัพย์: $LISTING_CODE · แชท: $THREAD_ID"
else
  SEEKER_URL="${BASE}/?preview=1&tab=contact&devRole=seeker${AUTH_Q}"
  OFFERER_URL="${BASE}/?preview=1&tab=mine&devRole=offerer${AUTH_Q}"
  ADMIN_URL="${BASE}/admin/console?devRole=admin${AUTH_Q}"
fi

echo ""
echo "============================================"
echo "  RealXtate — 3 บทบาท (Chrome แยก profile)"
echo "============================================"
echo "  พอร์ต: $PORT"
echo ""

open_window "ลูกค้า" "realxtate-seeker" "$SEEKER_URL"
open_window "ผู้เสนอ" "realxtate-offerer" "$OFFERER_URL"
open_window "แอดมิน" "realxtate-admin" "$ADMIN_URL"

if [[ "$(uname -s)" == "Darwin" ]]; then
  osascript -e "tell application \"$CHROME_APP\" to activate" 2>/dev/null || true
fi

echo ""
echo "✅ สั่งเปิด Chrome 3 หน้าต่างแล้ว"
echo "   ถ้ายังไม่เห็น → กด Cmd+Tab เลือก Google Chrome"
echo ""
echo "  1) ลูกค้า  — แท็บติดต่อ (แชททรัพย์ POV)"
echo "  2) เจ้าของ — จัดการประกาศ (มีทรัพย์ในระบบ)"
echo "  3) แอดมิน — คอนโซลแชทห้องเดียวกัน"
echo "============================================"
