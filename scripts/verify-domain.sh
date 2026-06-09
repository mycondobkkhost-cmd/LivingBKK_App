#!/usr/bin/env bash
# ตรวจว่าโดเมน custom พร้อมใช้งาน (HTTPS + หน้ากฎหมาย + redirect Netlify)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DOMAIN="${DOMAIN:-${1:-realxtateth.com}}"
DOMAIN="${DOMAIN#https://}"
DOMAIN="${DOMAIN#http://}"
DOMAIN="${DOMAIN%%/*}"
BASE="https://${DOMAIN}"

NETLIFY_SITE="${NETLIFY_SITE:-quiet-kangaroo-ab6073}"
NETLIFY_URL="https://${NETLIFY_SITE}.netlify.app"

ok=0
fail=0

pass() { echo "✅ $1"; ok=$((ok + 1)); }
must() { echo "❌ $1"; fail=$((fail + 1)); }
note() { echo "ℹ️  $1"; }

http_code() {
  local url="$1"
  curl -s -o /dev/null -w '%{http_code}' -L --max-time 20 "$url" 2>/dev/null || echo "000"
}

final_url() {
  local url="$1"
  curl -s -o /dev/null -w '%{url_effective}' -L --max-time 20 "$url" 2>/dev/null || echo ""
}

echo "=== ตรวจโดเมน RealXtate ==="
echo "โดเมน: $BASE"
echo "Netlify subdomain: $NETLIFY_URL"
echo ""

if ! command -v curl >/dev/null 2>&1; then
  must "ไม่พบ curl — ติดตั้งก่อน (macOS มีมาให้แล้ว)"
  exit 1
fi

# --- HTTPS หน้าหลัก ---
for path in / /legal/privacy.html /legal/terms.html; do
  url="${BASE}${path}"
  code="$(http_code "$url")"
  if [[ "$code" == "200" ]]; then
    pass "${path:-/} → HTTP 200"
  else
    must "${path:-/} → HTTP $code (คาดหวัง 200) — $url"
  fi
done

# --- เนื้อหามีแบรนด์ RealXtate ---
for path in /legal/privacy.html /legal/terms.html; do
  url="${BASE}${path}"
  if curl -sf -L --max-time 20 "$url" 2>/dev/null | grep -qi 'RealXtate'; then
    pass "${path} มีข้อความ RealXtate"
  else
    must "${path} ไม่พบข้อความ RealXtate — ตรวจ deploy"
  fi
done

# --- Redirect จาก Netlify subdomain (ถ้าตั้ง primary domain แล้ว) ---
netlify_code="$(http_code "$NETLIFY_URL/")"
netlify_final="$(final_url "$NETLIFY_URL/")"

if [[ "$netlify_code" == "200" || "$netlify_code" == "301" || "$netlify_code" == "302" || "$netlify_code" == "308" ]]; then
  if [[ "$netlify_final" == "${BASE}/" || "$netlify_final" == "$BASE" ]]; then
    pass "Netlify subdomain redirect → $BASE"
  elif [[ "$netlify_final" == "${NETLIFY_URL}/" || "$netlify_final" == "$NETLIFY_URL" ]]; then
    note "Netlify subdomain ยังไม่ redirect ไป $BASE — ตั้ง Primary domain ใน Netlify (ไม่บังคับแต่แนะนำ)"
  else
    note "Netlify subdomain ตอบ $netlify_code → $netlify_final (ตรวจ Primary domain ใน Netlify)"
  fi
else
  note "Netlify subdomain ได้ HTTP $netlify_code — อาจยังไม่ deploy หรือ site เปลี่ยนชื่อ"
fi

# --- WEB_BASE_URL ใน repo (ถ้ามี .env.local) ---
if [[ -f "$ROOT/.env.local" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "$ROOT/.env.local" 2>/dev/null || true
  set +a
  web_base="${WEB_BASE_URL:-}"
  web_base="${web_base%/}"
  if [[ "$web_base" == "$BASE" ]]; then
    pass ".env.local WEB_BASE_URL=$BASE"
  elif [[ -n "$web_base" ]]; then
    must ".env.local WEB_BASE_URL=$web_base (คาดหวัง $BASE) — รัน ./scripts/setup-custom-domain.sh"
  else
    must ".env.local ยังไม่ตั้ง WEB_BASE_URL — รัน ./scripts/setup-custom-domain.sh"
  fi
else
  note "ไม่พบ .env.local — ข้ามตรวจ WEB_BASE_URL"
fi

echo ""
echo "=== สรุป ==="
echo "ผ่าน: $ok · ไม่ผ่าน: $fail"
if [[ "$fail" -eq 0 ]]; then
  echo "✅ โดเมนพร้อมใช้งาน (ตรวจออนไลน์ครบ)"
  exit 0
else
  echo "❌ ยังมีรายการที่ต้องแก้ — ดู docs/CUSTOM-DOMAIN.md"
  exit 1
fi
