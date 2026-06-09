#!/usr/bin/env bash
# ตั้ง DNS Cloudflare → Netlify อัตโนมัติ (ต้องมี CLOUDFLARE_API_TOKEN)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOMAIN="${DOMAIN:-realxtateth.com}"
NETLIFY_HOST="${NETLIFY_SITE:-quiet-kangaroo-ab6073}.netlify.app"
NETLIFY_APEX_IP="${NETLIFY_APEX_IP:-75.2.60.5}"

ENV_LOCAL="$ROOT/.env.local"
if [[ -f "$ENV_LOCAL" ]]; then
  # shellcheck disable=SC1090
  set -a; source "$ENV_LOCAL" 2>/dev/null || true; set +a
fi

TOKEN="${CLOUDFLARE_API_TOKEN:-}"
if [[ -z "$TOKEN" ]]; then
  echo "❌ ยังไม่มี CLOUDFLARE_API_TOKEN"
  echo ""
  echo "ทำครั้งเดียว (2 นาที):"
  echo "1. เปิด Chrome → สร้าง API Token (ลิงก์ด้านล่าง)"
  echo "2. ใส่ใน .env.local:"
  echo "   CLOUDFLARE_API_TOKEN=xxxxxxxx"
  echo "3. รันสคริปต์นี้อีกครั้ง"
  echo ""
  echo "ลิงก์สร้าง Token:"
  echo "  https://dash.cloudflare.com/profile/api-tokens"
  echo "  → Create Token → Edit zone DNS → Zone: realxtateth.com → Continue → Create"
  if [[ -d "/Applications/Google Chrome.app" ]]; then
    open -a "Google Chrome" "https://dash.cloudflare.com/profile/api-tokens"
  fi
  exit 1
fi

api() {
  curl -sS -X "$1" "https://api.cloudflare.com/client/v4$2" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    ${3:+ -d "$3"}
}

echo "=== ตั้ง DNS ${DOMAIN} → Netlify ==="

ZONE_JSON="$(api GET "/zones?name=${DOMAIN}")"
ZONE_ID="$(echo "$ZONE_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['id'] if d.get('success') and d['result'] else '')" 2>/dev/null || true)"

if [[ -z "$ZONE_ID" ]]; then
  echo "❌ หา Zone ID ไม่เจอ — ตรวจ Token ว่ามีสิทธิ์ Zone DNS สำหรับ ${DOMAIN}"
  echo "$ZONE_JSON" | python3 -m json.tool 2>/dev/null | head -20 || echo "$ZONE_JSON"
  exit 1
fi
echo "✅ Zone ID: $ZONE_ID"

# ลบ A/CNAME ที่ @ และ www ถ้ามี (กันชน)
LIST="$(api GET "/zones/${ZONE_ID}/dns_records?per_page=100")"
echo "$LIST" | python3 -c "
import sys, json, subprocess, os
d = json.load(sys.stdin)
token = os.environ.get('TOKEN', '')
zone = os.environ.get('ZONE_ID', '')
domain = os.environ.get('DOMAIN', '')
apex_names = {domain, '@'}
for r in d.get('result', []):
    n = r.get('name', '')
    t = r.get('type', '')
    short = n.replace('.' + domain, '').replace(domain, '@') if domain in n else n
    if t in ('A', 'CNAME', 'AAAA') and (short in ('@', 'www') or n == domain or n == 'www.' + domain):
        rid = r['id']
        print(f\"ลบ record เก่า: {t} {n} → {r.get('content','')}\")
        subprocess.run([
            'curl', '-sS', '-X', 'DELETE',
            f'https://api.cloudflare.com/client/v4/zones/{zone}/dns_records/{rid}',
            '-H', f'Authorization: Bearer {token}',
        ], check=False)
" TOKEN="$TOKEN" ZONE_ID="$ZONE_ID" DOMAIN="$DOMAIN" 2>/dev/null || true

upsert() {
  local type="$1" name="$2" content="$3"
  local body
  body=$(python3 -c "import json; print(json.dumps({'type':'$type','name':'$name','content':'$content','proxied':False,'ttl':1}))")
  local res
  res="$(api POST "/zones/${ZONE_ID}/dns_records" "$body")"
  if echo "$res" | python3 -c "import sys,json; sys.exit(0 if json.load(sys.stdin).get('success') else 1)" 2>/dev/null; then
    echo "✅ สร้าง ${type} ${name} → ${content} (DNS only)"
  else
    echo "❌ สร้าง ${type} ${name} ล้มเหลว:"
    echo "$res" | python3 -m json.tool 2>/dev/null | head -15 || echo "$res"
    return 1
  fi
}

upsert A "$DOMAIN" "$NETLIFY_APEX_IP"
upsert CNAME "www.$DOMAIN" "$NETLIFY_HOST"

echo ""
echo "✅ ตั้ง DNS เสร็จ — รอ 15–60 นาที แล้ว Netlify จะผ่าน Pending DNS"
echo ""
if [[ -x "$ROOT/scripts/verify-cloudflare-dns.sh" ]]; then
  sleep 3
  "$ROOT/scripts/verify-cloudflare-dns.sh" "$DOMAIN" || true
fi
echo ""
echo "ขั้นถัดไป: กลับ Netlify ดู HTTPS → แล้วรัน ./scripts/verify-domain.sh"
