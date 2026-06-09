#!/usr/bin/env bash
# หลังล็อกอิน Cloudflare แล้ว — เปิด Chrome ทุกแท็บที่ต้องใช้ + อัปเดต repo
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOMAIN="${DOMAIN:-realxtateth.com}"
NETLIFY_SITE="${NETLIFY_SITE:-quiet-kangaroo-ab6073}"
NETLIFY_HOST="${NETLIFY_SITE}.netlify.app"
NETLIFY_APEX_IP="${NETLIFY_APEX_IP:-75.2.60.5}"
WEB_BASE="https://${DOMAIN}"

open_chrome() {
  local url="$1"
  if [[ -d "/Applications/Google Chrome.app" ]]; then
    open -a "Google Chrome" "$url"
  else
    open "$url"
  fi
}

echo "=== RealXtate — ต่อหลังล็อกอิน Cloudflare ==="
echo ""

# อัปเดต .env.local
if [[ ! -f "$ROOT/.env.local" && -f "$ROOT/.env.local.example" ]]; then
  cp "$ROOT/.env.local.example" "$ROOT/.env.local"
fi
if [[ -f "$ROOT/.env.local" ]]; then
  for kv in "WEB_BASE_URL=${WEB_BASE}" "DNS_PROVIDER=cloudflare" "CUSTOM_DOMAIN=${DOMAIN}"; do
    key="${kv%%=*}"
    if grep -qE "^${key}=" "$ROOT/.env.local"; then
      if sed --version 2>/dev/null | grep -q GNU; then
        sed -i "s|^${key}=.*|${kv}|" "$ROOT/.env.local"
      else
        sed -i '' "s|^${key}=.*|${kv}|" "$ROOT/.env.local"
      fi
    else
      printf '%s\n' "$kv" >> "$ROOT/.env.local"
    fi
  done
  echo "✅ อัปเดต .env.local → WEB_BASE_URL=${WEB_BASE}"
  if grep -qE '^SUPABASE_URL=https://[^/]+' "$ROOT/.env.local" \
    && grep -qE '^SUPABASE_ANON_KEY=(eyJ|sb_publishable_)' "$ROOT/.env.local"; then
    "$ROOT/scripts/sync-env.sh" 2>/dev/null || true
  fi
fi

echo ""
echo "เปิด Chrome 4 แท็บ (ทำตามลำดับ):"
echo ""

echo "【แท็บ 1】 จดโดเมน (ถ้ายังไม่จด)"
echo "  → ค้นหา: ${DOMAIN} → Add to cart → ชำระบัตร"
open_chrome "https://dash.cloudflare.com/?to=/:account/domains/register"
sleep 1

echo ""
echo "【แท็บ 2】 Netlify — เพิ่มโดเมน"
echo "  → Add domain → ${DOMAIN} → External DNS"
open_chrome "https://app.netlify.com/sites/${NETLIFY_SITE}/domain-management"
sleep 1

echo ""
echo "【แท็บ 3】 Cloudflare DNS (หลังจดโดเมนแล้ว)"
echo "  → เลือกโซน ${DOMAIN} → DNS → Records:"
echo "     A    @    ${NETLIFY_APEX_IP}     (เมฆเทา / DNS only)"
echo "     CNAME www ${NETLIFY_HOST} (เมฆเทา / DNS only)"
open_chrome "https://dash.cloudflare.com/"
sleep 1

echo ""
echo "【แท็บ 4】 Email Routing (หลัง DNS)"
echo "  → privacy@${DOMAIN} → forward Gmail"
open_chrome "https://dash.cloudflare.com/?to=/:account/${DOMAIN}/email/routing"
sleep 1

echo ""
echo "【แท็บ 5】 Supabase Auth URL"
open_chrome "https://supabase.com/dashboard/project/_/auth/url-configuration"

echo ""
echo "── หลังตั้ง DNS แล้ว รันในเทอร์มินัล ──"
echo "  ./scripts/verify-cloudflare-dns.sh"
echo "  ./scripts/build-web.sh && ./scripts/deploy-netlify.sh"
echo "  ./scripts/verify-domain.sh"
echo ""
echo "Supabase ตั้ง:"
echo "  Site URL:      ${WEB_BASE}"
echo "  Redirect URLs: ${WEB_BASE}/**"
