#!/usr/bin/env bash
# เปิด Email Routing + privacy@realxtateth.com (ต้องมี CLOUDFLARE_API_TOKEN)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOMAIN="${DOMAIN:-realxtateth.com}"
ZONE_ID="${CLOUDFLARE_ZONE_ID:-b69b377517eb002f4bea569cfee97570}"
DEST_EMAIL="${PRIVACY_FORWARD_EMAIL:-mycondobkk.host@gmail.com}"
CUSTOM_LOCAL="privacy"

ENV_LOCAL="$ROOT/.env.local"
[[ -f "$ENV_LOCAL" ]] && { set -a; source "$ENV_LOCAL" 2>/dev/null || true; set +a; }

TOKEN="${CLOUDFLARE_API_TOKEN:-}"
if [[ -z "$TOKEN" ]]; then
  echo "❌ ไม่มี CLOUDFLARE_API_TOKEN ใน .env.local"
  echo "   สร้าง Token ใหม่: Edit zone DNS + Email Routing Rules (ถ้ามี)"
  echo "   https://dash.cloudflare.com/profile/api-tokens"
  exit 1
fi

api() {
  curl -sS -X "$1" "https://api.cloudflare.com/client/v4$2" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    ${3:+ -d "$3"}
}

ok() { echo "$1" | python3 -c "import sys,json; sys.exit(0 if json.load(sys.stdin).get('success') else 1)" 2>/dev/null; }

echo "=== Email Routing: ${CUSTOM_LOCAL}@${DOMAIN} → ${DEST_EMAIL} ==="

# 1) Enable routing
echo "▶ เปิด Email Routing..."
res="$(api POST "/zones/${ZONE_ID}/email/routing/enable" '{}')"
if ok "$res"; then
  echo "✅ Enable สำเร็จ"
else
  echo "ℹ️  Enable API: $(echo "$res" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('errors',[{}])[0].get('message','fail'))" 2>/dev/null)"
  echo "▶ ลองสร้าง DNS records ผ่าน API..."
  res2="$(api POST "/zones/${ZONE_ID}/email/routing/dns" '{}')"
  if ok "$res2"; then
    echo "✅ สร้าง Email DNS สำเร็จ"
  else
    echo "▶ ใส่ MX records มือผ่าน DNS API..."
    for pair in "route1.mx.cloudflare.net:58" "route2.mx.cloudflare.net:12" "route3.mx.cloudflare.net:86"; do
      host="${pair%%:*}"; pri="${pair##*:}"
      body=$(python3 -c "import json; print(json.dumps({'type':'MX','name':'${DOMAIN}','content':'${host}','priority':${pri},'proxied':False,'ttl':1}))")
      r="$(api POST "/zones/${ZONE_ID}/dns_records" "$body")"
      if ok "$r"; then echo "✅ MX → $host"; else echo "ℹ️  MX $host อาจมีอยู่แล้ว"; fi
    done
  fi
fi

# 2) Destination address
echo "▶ เพิ่มปลายทาง ${DEST_EMAIL} (ต้องยืนยันใน Gmail)..."
body=$(python3 -c "import json; print(json.dumps({'email':'${DEST_EMAIL}'}))")
res="$(api POST "/zones/${ZONE_ID}/email/routing/addresses" "$body")"
DEST_TAG=""
if ok "$res"; then
  DEST_TAG="$(echo "$res" | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['tag'])" 2>/dev/null || true)"
  echo "✅ ส่งเมลยืนยันไป ${DEST_EMAIL} แล้ว — เปิด Gmail กดลิงก์ Confirm"
else
  msg="$(echo "$res" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('errors',[{}])[0].get('message',''))" 2>/dev/null)"
  echo "ℹ️  Destination: $msg"
  # ดึง tag ถ้ามีอยู่แล้ว
  list="$(api GET "/zones/${ZONE_ID}/email/routing/addresses")"
  DEST_TAG="$(echo "$list" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for a in d.get('result',[]):
  if a.get('email','').lower()=='${DEST_EMAIL}'.lower():
    print(a.get('tag','')); break
" 2>/dev/null || true)"
  [[ -n "$DEST_TAG" ]] && echo "✅ ใช้ destination ที่มีอยู่: $DEST_TAG"
fi

# 3) Routing rule privacy@
if [[ -n "$DEST_TAG" ]]; then
  echo "▶ สร้าง rule ${CUSTOM_LOCAL}@${DOMAIN}..."
  body=$(python3 -c "
import json
print(json.dumps({
  'name': 'privacy forward',
  'enabled': True,
  'matchers': [{'type': 'literal', 'field': 'to', 'value': '${CUSTOM_LOCAL}@${DOMAIN}'}],
  'actions': [{'type': 'forward', 'value': ['${DEST_TAG}']}],
}))
")
  res="$(api POST "/zones/${ZONE_ID}/email/routing/rules" "$body")"
  if ok "$res"; then
    echo "✅ Rule privacy@ สร้างแล้ว"
  else
    echo "ℹ️  Rule: $(echo "$res" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('errors',[{}])[0].get('message',''))" 2>/dev/null)"
    echo "   (อาจต้องยืนยัน Gmail ก่อน — ยืนยันแล้วรันสคริปต์นี้อีกครั้ง)"
  fi
else
  echo "⚠️  ยังไม่มี destination tag — ยืนยัน Gmail แล้วรัน:"
  echo "   ./scripts/setup-cloudflare-email-routing.sh"
fi

echo ""
echo "ตรวจใน Cloudflare → Email Routing → Overview (ควร Enabled)"
echo "ทดสอบ: ส่งเมลไป privacy@${DOMAIN}"
