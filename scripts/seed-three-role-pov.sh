#!/usr/bin/env bash
# จัด POV เทส 3 บทบาท — เจ้าของมีทรัพย์ · ลูกค้า+แอดมินแชททรัพย์เดียวกัน
# ใช้: ./scripts/seed-three-role-pov.sh [--open]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env.local"
OPEN_CHROME=false
if [[ "${1:-}" == "--open" ]]; then
  OPEN_CHROME=true
fi

PORT="${PORT:-7357}"
BASE="http://127.0.0.1:${PORT}"
LISTING_CODE="${LISTING_CODE:-RENT-CD-POV-2026-000001}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ ไม่พบ .env.local"
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

URL="${SUPABASE_URL%/}"
KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"
if [[ -z "$URL" || -z "$KEY" ]]; then
  echo "❌ ต้องมี SUPABASE_URL และ SUPABASE_SERVICE_ROLE_KEY ใน .env.local"
  exit 1
fi

api() {
  local method="$1"
  local path="$2"
  local body="${3:-}"
  if [[ -n "$body" ]]; then
    curl -sS -X "$method" "$URL/rest/v1/$path" \
      -H "apikey: $KEY" \
      -H "Authorization: Bearer $KEY" \
      -H "Content-Type: application/json" \
      -H "Prefer: return=representation" \
      -d "$body"
  else
    curl -sS -X "$method" "$URL/rest/v1/$path" \
      -H "apikey: $KEY" \
      -H "Authorization: Bearer $KEY" \
      -H "Content-Type: application/json"
  fi
}

user_id_by_email() {
  curl -sS "$URL/auth/v1/admin/users?per_page=200" \
    -H "apikey: $KEY" \
    -H "Authorization: Bearer $KEY" | python3 -c "
import json,sys
target=sys.argv[1].lower()
for u in json.load(sys.stdin).get('users') or []:
  if (u.get('email') or '').lower() == target:
    print(u['id'])
    break
" "$1"
}

echo "=== RealXtate — จัด POV 3 บทบาท ===" >&2

OWNER_ID="$(user_id_by_email 'demo-owner@livingbkk.local')"
SEEKER_ID="$(user_id_by_email 'demo-seeker@livingbkk.local')"
if [[ -z "$OWNER_ID" || -z "$SEEKER_ID" ]]; then
  echo "❌ ไม่พบ demo-owner หรือ demo-seeker — รัน ./scripts/seed-demo-users-api.sh ก่อน"
  exit 1
fi

RESULT="$(python3 - "$URL" "$KEY" "$OWNER_ID" "$SEEKER_ID" "$LISTING_CODE" <<'PY'
import json, sys, urllib.request
from datetime import datetime, timezone

url, key, owner_id, seeker_id, listing_code = sys.argv[1:6]
headers = {
    "apikey": key,
    "Authorization": f"Bearer {key}",
    "Content-Type": "application/json",
    "Prefer": "return=representation",
}

def req(method, path, body=None, prefer=None):
    h = dict(headers)
    if prefer:
        h["Prefer"] = prefer
    data = None if body is None else json.dumps(body).encode()
    r = urllib.request.Request(f"{url}/rest/v1/{path}", data=data, headers=h, method=method)
    with urllib.request.urlopen(r) as res:
        raw = res.read().decode()
        return json.loads(raw) if raw else None

# ทรัพย์ของเจ้าของ — ใช้ที่มีอยู่ก่อน ไม่งั้นสร้าง POV
rows = req("GET", f"listings?owner_id=eq.{owner_id}&status=eq.published&select=id,listing_code,title,project_name&order=created_at.desc&limit=1")
listing = rows[0] if rows else None
if not listing:
    try:
        created = req("POST", "listings", {
            "listing_code": listing_code,
            "owner_id": owner_id,
            "created_by_id": owner_id,
            "listing_type": "rent",
            "status": "published",
            "property_type": "condo",
            "title": "2 นอน · The Line Sukhumvit 101 (POV เทส)",
            "price_net": 22000,
            "bedrooms": 2,
            "bathrooms": 1,
            "area_sqm": 58,
            "district": "วัฒนา",
            "project_name": "The Line Sukhumvit 101",
            "pet_allowed": False,
            "listed_by_role": "owner",
            "owner_verified": True,
            "platform_has_owner_contact": True,
            "co_agent_listing_type": "co_agent_50_50",
            "published_at": datetime.now(timezone.utc).isoformat(),
        })
        listing = created[0]
        print(f"created listing {listing['listing_code']}", file=sys.stderr)
    except Exception as e:
        # อาจมีรหัสซ้ำ — ลองดึงตาม code
        rows = req("GET", f"listings?listing_code=eq.{listing_code}&select=id,listing_code,title,project_name&limit=1")
        listing = rows[0] if rows else None
        if not listing:
            raise SystemExit(f"create listing failed: {e}")

listing_id = listing["id"]
code = listing["listing_code"]
title = listing.get("title") or code
project = listing.get("project_name")

# แชทลูกค้า ↔ ทรัพย์
threads = req("GET", f"chat_threads?user_id=eq.{seeker_id}&listing_id=eq.{listing_id}&select=id&limit=1")
if threads:
    thread_id = threads[0]["id"]
else:
    created = req("POST", "chat_threads", {
        "user_id": seeker_id,
        "room_kind": "property",
        "listing_id": listing_id,
        "listing_code": code,
        "listing_title": title,
        "project_name": project,
        "category": "property_faq",
        "status": "open",
        "allow_viewing_request": True,
        "admin_reply_done": True,
    })
    thread_id = created[0]["id"]
    print(f"created thread {thread_id}", file=sys.stderr)

# ข้อความเริ่มต้น (ถ้ายังว่าง)
msgs = req("GET", f"chat_messages?thread_id=eq.{thread_id}&select=id&limit=1")
if not msgs:
    seed = [
        ("ai", "สวัสดีค่ะ RealXtate ยินดีให้บริการค่ะ สนใจสอบถามรายละเอียดทรัพย์นี้ได้เลยนะคะ"),
        ("user", "สวัสดีค่ะ สนใจทรัพย์นี้ ขอรายละเอียดเพิ่มค่ะ"),
        ("ai", "ได้เลยค่ะ ห้องนี้เป็น 2 นอน งบประมาณตามประกาศ สะดวกนัดดูช่วงไหนดีคะ"),
        ("user", "อยากนัดดูค่ะ"),
    ]
    for role, text in seed:
        req("POST", "chat_messages", {
            "thread_id": thread_id,
            "role": role,
            "text": text,
            "requires_admin": False,
        }, prefer="return=minimal")
    req("PATCH", f"chat_threads?id=eq.{thread_id}", {
        "last_message_at": "now()",
        "admin_reply_done": False,
        "category": "viewing_request",
    }, prefer="return=minimal")
    print("seeded chat messages", file=sys.stderr)

print(json.dumps({
    "listing_id": listing_id,
    "listing_code": code,
    "listing_title": title,
    "thread_id": thread_id,
    "owner_id": owner_id,
    "seeker_id": seeker_id,
}))
PY
)"

LISTING_ID="$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin)['listing_id'])")"
CODE="$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin)['listing_code'])")"
THREAD_ID="$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin)['thread_id'])")"
TITLE="$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin)['listing_title'])")"

SEEKER_URL="${BASE}/?preview=1&tab=contact&devRole=seeker&devAuth=real&devListing=${CODE}&devOpenChat=1"
OWNER_URL="${BASE}/?preview=1&tab=mine&devRole=offerer&devAuth=real"
ADMIN_URL="${BASE}/admin/console?devRole=admin&devAuth=real&room=${THREAD_ID}"

echo "" >&2
echo "✅ POV พร้อมแล้ว" >&2
echo "   ทรัพย์: $CODE" >&2
echo "   ชื่อ:    $TITLE" >&2
echo "   แชท:    $THREAD_ID" >&2
echo "" >&2
echo "  เจ้าของ → แท็บจัดการประกาศ (มีทรัพย์ในระบบ)" >&2
echo "  $OWNER_URL" >&2
echo "" >&2
echo "  ลูกค้า → เปิดแชททรัพย์นี้อัตโนมัติ" >&2
echo "  $SEEKER_URL" >&2
echo "" >&2
echo "  แอดมิน → แชทห้องเดียวกัน" >&2
echo "  $ADMIN_URL" >&2
echo "" >&2

if [[ "$OPEN_CHROME" == true ]]; then
  PROFILE_ROOT="$ROOT/.dev-chrome-profiles"
  CHROME_APP="Google Chrome"
  [[ -d "/Applications/Google Chrome.app" ]] || CHROME_APP="Chromium"
  open_window() {
    local name="$1" url="$2" label="$3"
    mkdir -p "$PROFILE_ROOT/$name"
    echo "→ $label"
    open -na "$CHROME_APP" --args \
      "--user-data-dir=$PROFILE_ROOT/$name" \
      "--no-first-run" \
      "--no-default-browser-check" \
      "--new-window" \
      "$url"
    sleep 1
  }
  open_window "realxtate-seeker" "$SEEKER_URL" "ลูกค้า"
  open_window "realxtate-offerer" "$OWNER_URL" "เจ้าของ"
  open_window "realxtate-admin" "$ADMIN_URL" "แอดมิน"
  osascript -e "tell application \"$CHROME_APP\" to activate" 2>/dev/null || true
  echo "✅ เปิด Chrome 3 หน้าต่างแล้ว" >&2
fi

# stdout เฉพาะ JSON สำหรับสคริปต์อื่น
echo "$RESULT"
