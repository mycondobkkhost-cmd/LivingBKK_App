#!/usr/bin/env bash
# ช่วยตั้ง WEB_BASE_URL หลังซื้อโดเมน — DNS/Netlify/Supabase ยังต้องทำใน dashboard
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_LOCAL="$ROOT/.env.local"
ENV_EXAMPLE="$ROOT/.env.local.example"
DEFAULT_DOMAIN="realxtateth.com"

echo "=== RealXtate — ตั้งค่าโดเมน custom ==="
echo ""

read -r -p "โดเมน (default: $DEFAULT_DOMAIN): " input_domain
DOMAIN="${input_domain:-$DEFAULT_DOMAIN}"
DOMAIN="${DOMAIN#https://}"
DOMAIN="${DOMAIN#http://}"
DOMAIN="${DOMAIN%%/*}"
DOMAIN="${DOMAIN%/}"
WEB_BASE_URL="https://${DOMAIN}"

echo ""
echo "จะตั้ง WEB_BASE_URL=$WEB_BASE_URL"
echo ""

if [[ ! -f "$ENV_LOCAL" ]]; then
  if [[ -f "$ENV_EXAMPLE" ]]; then
    cp "$ENV_EXAMPLE" "$ENV_LOCAL"
    echo "✅ สร้าง $ENV_LOCAL จาก .env.local.example"
    echo "   ⚠️  ใส่ SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_MAPS_API_KEY ให้ครบก่อน sync-env"
  else
    echo "❌ ไม่พบ $ENV_EXAMPLE"
    exit 1
  fi
fi

# อัปเดตหรือเพิ่ม WEB_BASE_URL
if grep -qE '^WEB_BASE_URL=' "$ENV_LOCAL"; then
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i "s|^WEB_BASE_URL=.*|WEB_BASE_URL=${WEB_BASE_URL}|" "$ENV_LOCAL"
  else
    sed -i '' "s|^WEB_BASE_URL=.*|WEB_BASE_URL=${WEB_BASE_URL}|" "$ENV_LOCAL"
  fi
else
  printf '\nWEB_BASE_URL=%s\n' "$WEB_BASE_URL" >> "$ENV_LOCAL"
fi

# อัปเดตหรือเพิ่ม CUSTOM_DOMAIN (comment ได้ — ใช้เป็น reference)
if grep -qE '^#?CUSTOM_DOMAIN=' "$ENV_LOCAL"; then
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i "s|^#\\?CUSTOM_DOMAIN=.*|CUSTOM_DOMAIN=${DOMAIN}|" "$ENV_LOCAL"
  else
    sed -i '' "s|^#\\?CUSTOM_DOMAIN=.*|CUSTOM_DOMAIN=${DOMAIN}|" "$ENV_LOCAL"
  fi
else
  printf 'CUSTOM_DOMAIN=%s\n' "$DOMAIN" >> "$ENV_LOCAL"
fi

echo "✅ อัปเดต $ENV_LOCAL"
echo ""

# sync-env ถ้ามี key พร้อม
if grep -qE '^SUPABASE_URL=https://[^/]+' "$ENV_LOCAL" \
  && grep -qE '^SUPABASE_ANON_KEY=(eyJ|sb_publishable_)' "$ENV_LOCAL"; then
  echo "▶ รัน sync-env.sh..."
  "$ROOT/scripts/sync-env.sh"
else
  echo "ℹ️  ข้าม sync-env — ใส่ Supabase key ใน .env.local แล้วรัน:"
  echo "   ./scripts/sync-env.sh"
fi

echo ""
echo "=== ขั้นตอนถัดไป (ทำในเว็บ) ==="
echo ""
echo "1. Cloudflare + Netlify (แนะนำ):"
echo "   ./scripts/setup-cloudflare-domain.sh"
echo "   หรือ docs/CLOUDFLARE-SETUP.md"
echo ""
echo "   Netlify → Add domain: $DOMAIN → External DNS"
echo "   Cloudflare DNS: A @ → 75.2.60.5, CNAME www → quiet-kangaroo-ab6073.netlify.app (DNS only)"
echo ""
echo "2. Supabase → Authentication → URL Configuration"
echo "   Site URL:        $WEB_BASE_URL"
echo "   Redirect URLs:   ${WEB_BASE_URL}/**"
echo "   (เก็บ https://quiet-kangaroo-ab6073.netlify.app/** ช่วงเปลี่ยนโดเมน)"
echo ""
echo "3. อีเมล privacy@${DOMAIN} — Cloudflare Email Routing (ฟรี) หรือ Google Workspace"
echo ""
echo "4. Deploy เว็บใหม่:"
echo "   ./scripts/build-web.sh && ./scripts/deploy-netlify.sh"
echo ""
echo "5. ตรวจครบ:"
echo "   ./scripts/verify-domain.sh $DOMAIN"
echo ""
echo "คู่มือเต็ม: docs/CUSTOM-DOMAIN.md"
