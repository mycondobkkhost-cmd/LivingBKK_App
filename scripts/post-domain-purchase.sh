#!/usr/bin/env bash
# หลังซื้อโดเมน realxtateth.com แล้ว — ตั้ง DNS + Netlify (ไม่เปิดหน้าจดโดเมน)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOMAIN="${DOMAIN:-realxtateth.com}"
NETLIFY_SITE="${NETLIFY_SITE:-quiet-kangaroo-ab6073}"
NETLIFY_HOST="${NETLIFY_SITE}.netlify.app"
NETLIFY_APEX_IP="${NETLIFY_APEX_IP:-75.2.60.5}"

open_chrome() {
  if [[ -d "/Applications/Google Chrome.app" ]]; then
    open -a "Google Chrome" "$1"
  else
    open "$1"
  fi
}

echo "=== RealXtate — หลังซื้อโดเมนแล้ว ==="
echo "โดเมน: $DOMAIN (NS ควรเป็น cloudflare.com แล้ว)"
echo ""

"$ROOT/scripts/continue-cloudflare-login.sh" 2>/dev/null | grep -E '^(✅|ℹ️)' || true

echo ""
echo "══════════════════════════════════════════════════════"
echo "  ขั้น A — Netlify (แท็บที่เปิดให้)"
echo "══════════════════════════════════════════════════════"
echo "1. Add a domain → ${DOMAIN}"
echo "2. เลือก Set up using external DNS"
echo "3. คัดลอกค่า A / CNAME ที่ Netlify แสดง (ถ้าต่างจากด้านล่าง)"
echo ""

open_chrome "https://app.netlify.com/sites/${NETLIFY_SITE}/domain-management"
sleep 2

echo "══════════════════════════════════════════════════════"
echo "  ขั้น B — Cloudflare DNS"
echo "══════════════════════════════════════════════════════"
echo "เลือกโซน ${DOMAIN} → DNS → Records → Add record:"
echo ""
printf "  %-6s %-6s %-45s %s\n" "Type" "Name" "Content" "Proxy"
printf "  %-6s %-6s %-45s %s\n" "A" "@" "$NETLIFY_APEX_IP" "DNS only (เมฆเทา)"
printf "  %-6s %-6s %-45s %s\n" "CNAME" "www" "$NETLIFY_HOST" "DNS only (เมฆเทา)"
echo ""
echo "ลบ record A/CNAME ชนกัน (เช่น parking page) ถ้ามี"
echo ""

open_chrome "https://dash.cloudflare.com/?to=/:account/${DOMAIN}/dns/records"
sleep 1

echo "══════════════════════════════════════════════════════"
echo "  ขั้น C — รอ HTTPS แล้วตรวจ"
echo "══════════════════════════════════════════════════════"
echo "  ./scripts/verify-cloudflare-dns.sh"
echo "  ./scripts/build-web.sh && ./scripts/deploy-netlify.sh"
echo "  ./scripts/verify-domain.sh"
echo ""

read -r -p "ตั้ง DNS ใน Cloudflare แล้ว? กด Enter เพื่อตรวจ DNS..." _
"$ROOT/scripts/verify-cloudflare-dns.sh" "$DOMAIN" || true
