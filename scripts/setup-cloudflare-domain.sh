#!/usr/bin/env bash
# RealXtate — ตั้งโดเมน Cloudflare Registrar + DNS → Netlify (แนะนำหลัก)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOMAIN="${DOMAIN:-realxtateth.com}"
NETLIFY_SITE="${NETLIFY_SITE:-quiet-kangaroo-ab6073}"
NETLIFY_HOST="${NETLIFY_SITE}.netlify.app"
# Netlify load balancer — ยืนยันค่าล่าสุดใน Netlify → Domain → External DNS
NETLIFY_APEX_IP="${NETLIFY_APEX_IP:-75.2.60.5}"

DOMAIN="${DOMAIN#https://}"
DOMAIN="${DOMAIN#http://}"
DOMAIN="${DOMAIN%%/*}"

# เปิดลิงก์ — ใช้ Chrome ถ้ามี (macOS) ไม่งั้นเบราว์เซอร์ default
open_browser() {
  local url="$1"
  if [[ "$(uname -s)" == "Darwin" ]] && [[ -d "/Applications/Google Chrome.app" ]]; then
    open -a "Google Chrome" "$url" 2>/dev/null && return
  fi
  if [[ "$(uname -s)" == "Darwin" ]]; then
    open "$url" 2>/dev/null && return
  fi
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" 2>/dev/null && return
  fi
  echo "เปิดลิงก์เอง: $url"
}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  RealXtate — Cloudflare + Netlify                        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "โดเมน:     $DOMAIN"
echo "Netlify:   https://${NETLIFY_HOST}"
echo "เป้าหมาย:  https://${DOMAIN}"
echo ""

step() { echo ""; echo "── $1 ──"; }

# ── 0) เปิดหน้าจดโดเมน Cloudflare ──
step "ขั้น 1 — จดโดเมนที่ Cloudflare (ชำระเงินเอง)"
echo "1. ล็อกอิน / สมัคร Cloudflare"
echo "2. Domain Registration → Register Domains"
echo "3. ค้นหา: $DOMAIN → Add to cart → ชำระบัตร"
echo "4. รอสถานะ Active"
echo ""
REGISTER_URL="https://dash.cloudflare.com/?to=/:account/domains/register"
echo "ลิงก์: $REGISTER_URL"
if [[ "$(uname -s)" == "Darwin" ]]; then
  read -r -p "เปิด Chrome ไปหน้าจดโดเมน? [Y/n] " open_cf
  open_cf="${open_cf:-Y}"
  if [[ "$open_cf" =~ ^[Yy]$ ]]; then
    open_browser "$REGISTER_URL"
  fi
fi
read -r -p "จดโดเมน $DOMAIN ใน Cloudflare แล้วหรือยัง? [y/N] " bought
if [[ ! "$bought" =~ ^[Yy]$ ]]; then
  echo ""
  echo "จดโดเมนเสร็จแล้วรันสคริปต์นี้อีกครั้ง:"
  echo "  ./scripts/setup-cloudflare-domain.sh"
  exit 0
fi

# ── 1) Netlify add domain ──
step "ขั้น 2 — เพิ่มโดเมนใน Netlify"
NETLIFY_DOMAIN_URL="https://app.netlify.com/sites/${NETLIFY_SITE}/domain-management"
echo "1. เปิด Netlify → Domain management"
echo "2. Add domain → $DOMAIN"
echo "3. เลือก External DNS (โดเมนอยู่ Cloudflare)"
echo ""
echo "ลิงก์: $NETLIFY_DOMAIN_URL"
if [[ "$(uname -s)" == "Darwin" ]]; then
  read -r -p "เปิด Chrome ไป Netlify Domain management? [Y/n] " open_nf
  open_nf="${open_nf:-Y}"
  if [[ "$open_nf" =~ ^[Yy]$ ]]; then
    open_browser "$NETLIFY_DOMAIN_URL"
  fi
fi
read -r -p "เพิ่มโดเมนใน Netlify แล้ว? [y/N] " netlify_done
if [[ ! "$netlify_done" =~ ^[Yy]$ ]]; then
  echo "เพิ่มใน Netlify แล้วรันสคริปต์ต่อ"
  exit 0
fi

# ── 2) Cloudflare DNS records ──
step "ขั้น 3 — ตั้ง DNS ใน Cloudflare"
CF_DNS_URL="https://dash.cloudflare.com/"
echo "Cloudflare → เลือกโซน $DOMAIN → DNS → Records"
echo ""
echo "เพิ่ม record (Proxy = DNS only / เมฆเทา — สำคัญสำหรับ SSL Netlify):"
echo ""
printf "  %-6s %-8s %-40s %s\n" "Type" "Name" "Content" "Proxy"
printf "  %-6s %-8s %-40s %s\n" "A" "@" "$NETLIFY_APEX_IP" "DNS only"
printf "  %-6s %-8s %-40s %s\n" "CNAME" "www" "$NETLIFY_HOST" "DNS only"
echo ""
echo "ลบ record A/CNAME เก่าที่ขัดแย้ง (ถ้ามี)"
echo "SSL/TLS → Full (strict) หลัง Netlify HTTPS Ready"
echo ""
echo "Dashboard: $CF_DNS_URL"
read -r -p "ตั้ง DNS ใน Cloudflare แล้ว? [y/N] " dns_done
if [[ "$dns_done" =~ ^[Yy]$ ]]; then
  if [[ -x "$ROOT/scripts/verify-cloudflare-dns.sh" ]]; then
    echo ""
    "$ROOT/scripts/verify-cloudflare-dns.sh" "$DOMAIN" || true
  fi
fi

# ── 3) Email routing ──
step "ขั้น 4 — อีเมล privacy@${DOMAIN} (ฟรี)"
echo "Cloudflare → Email → Email Routing → Enable"
echo "  privacy@${DOMAIN} → forward ไป Gmail ของคุณ"
read -r -p "ตั้ง Email Routing แล้ว (หรือข้ามไปก่อน)? [y/N] " _email

# ── 4) Repo env ──
step "ขั้น 5 — ตั้ง WEB_BASE_URL ใน repo"
WEB_BASE="https://${DOMAIN}"
if [[ ! -f "$ROOT/.env.local" && -f "$ROOT/.env.local.example" ]]; then
  cp "$ROOT/.env.local.example" "$ROOT/.env.local"
  echo "✅ สร้าง .env.local จาก example"
fi
if [[ -f "$ROOT/.env.local" ]]; then
  if grep -qE '^WEB_BASE_URL=' "$ROOT/.env.local"; then
    if sed --version 2>/dev/null | grep -q GNU; then
      sed -i "s|^WEB_BASE_URL=.*|WEB_BASE_URL=${WEB_BASE}|" "$ROOT/.env.local"
    else
      sed -i '' "s|^WEB_BASE_URL=.*|WEB_BASE_URL=${WEB_BASE}|" "$ROOT/.env.local"
    fi
  else
    printf '\nWEB_BASE_URL=%s\n' "$WEB_BASE" >> "$ROOT/.env.local"
  fi
  if grep -qE '^DNS_PROVIDER=' "$ROOT/.env.local"; then
    if sed --version 2>/dev/null | grep -q GNU; then
      sed -i "s|^DNS_PROVIDER=.*|DNS_PROVIDER=cloudflare|" "$ROOT/.env.local"
    else
      sed -i '' "s|^DNS_PROVIDER=.*|DNS_PROVIDER=cloudflare|" "$ROOT/.env.local"
    fi
  else
    printf 'DNS_PROVIDER=cloudflare\n' >> "$ROOT/.env.local"
  fi
  echo "✅ WEB_BASE_URL=$WEB_BASE · DNS_PROVIDER=cloudflare"
  if grep -qE '^SUPABASE_URL=https://[^/]+' "$ROOT/.env.local" \
    && grep -qE '^SUPABASE_ANON_KEY=(eyJ|sb_publishable_)' "$ROOT/.env.local"; then
    "$ROOT/scripts/sync-env.sh" 2>/dev/null || true
  fi
fi

# ── 5) Supabase ──
step "ขั้น 6 — Supabase Auth URLs"
echo "Site URL:       https://${DOMAIN}"
echo "Redirect URLs:  https://${DOMAIN}/**"
echo "เก็บ:           https://${NETLIFY_HOST}/**"
SUPA_URL="https://supabase.com/dashboard/project/_/auth/url-configuration"
echo "ลิงก์: $SUPA_URL (เลือกโปรเจกตจริงใน dashboard)"

# ── 6) Deploy ──
step "ขั้น 7 — Deploy เว็บ"
read -r -p "รัน build + deploy Netlify ตอนนี้? [y/N] " deploy_now
if [[ "$deploy_now" =~ ^[Yy]$ ]]; then
  "$ROOT/scripts/build-web.sh"
  "$ROOT/scripts/deploy-netlify.sh" || echo "⚠️  deploy ล้มเหลว — ลอง deploy มือหรือตรวจ .netlify-token"
fi

# ── 7) Verify ──
step "ขั้น 8 — ตรวจครบ"
echo "รอ Netlify HTTPS Ready (15 นาที – 24 ชม.) แล้วรัน:"
echo "  ./scripts/verify-domain.sh $DOMAIN"
echo ""
read -r -p "ตรวจโดเมนตอนนี้? [y/N] " verify_now
if [[ "$verify_now" =~ ^[Yy]$ ]]; then
  DOMAIN="$DOMAIN" "$ROOT/scripts/verify-domain.sh" "$DOMAIN" || true
fi

echo ""
echo "✅ Wizard เสร็จ — คู่มือ: docs/CLOUDFLARE-SETUP.md"
