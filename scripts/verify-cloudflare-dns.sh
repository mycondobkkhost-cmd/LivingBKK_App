#!/usr/bin/env bash
# ตรวจ DNS โดเมนชี้ไป Netlify (ก่อน/หลังตั้ง Cloudflare)
set -euo pipefail

DOMAIN="${DOMAIN:-${1:-realxtateth.com}}"
NETLIFY_SITE="${NETLIFY_SITE:-quiet-kangaroo-ab6073}"
NETLIFY_HOST="${NETLIFY_SITE}.netlify.app"
NETLIFY_APEX_IP="${NETLIFY_APEX_IP:-75.2.60.5}"

DOMAIN="${DOMAIN#https://}"
DOMAIN="${DOMAIN#http://}"
DOMAIN="${DOMAIN%%/*}"

ok=0
fail=0
pass() { echo "✅ $1"; ok=$((ok + 1)); }
must() { echo "❌ $1"; fail=$((fail + 1)); }
note() { echo "ℹ️  $1"; }

echo "=== ตรวจ DNS Cloudflare → Netlify ==="
echo "โดเมน: $DOMAIN"
echo "คาดหวัง: A @ → $NETLIFY_APEX_IP หรือ CNAME @ → $NETLIFY_HOST"
echo "         CNAME www → $NETLIFY_HOST"
echo ""

if ! command -v dig >/dev/null 2>&1; then
  must "ไม่พบ dig — ติดตั้ง bind หรือใช้เว็บ dnschecker.org"
  exit 1
fi

# Apex A
apex_a="$(dig +short A "$DOMAIN" 2>/dev/null | head -1 || true)"
if [[ "$apex_a" == "$NETLIFY_APEX_IP" ]]; then
  pass "A record @ → $apex_a"
elif [[ -n "$apex_a" ]]; then
  note "A record @ → $apex_a (ไม่ตรง $NETLIFY_APEX_IP — ตรวจใน Netlify External DNS)"
else
  # CNAME flattening at apex
  apex_cname="$(dig +short CNAME "$DOMAIN" 2>/dev/null | head -1 || true)"
  if [[ "$apex_cname" == *"$NETLIFY_HOST"* ]]; then
    pass "CNAME (apex) → $apex_cname"
  else
    must "ยังไม่พบ A หรือ CNAME ที่ apex ชี้ Netlify"
  fi
fi

# www
www_target="$(dig +short CNAME "www.${DOMAIN}" 2>/dev/null | head -1 || true)"
www_target="${www_target%.}"
if [[ "$www_target" == "$NETLIFY_HOST" || "$www_target" == "${NETLIFY_HOST}." ]]; then
  pass "CNAME www → $NETLIFY_HOST"
elif [[ -n "$www_target" ]]; then
  must "CNAME www → $www_target (คาดหวัง $NETLIFY_HOST)"
else
  note "ยังไม่มี CNAME www — แนะนำเพิ่ม (ไม่บังคับถ้าใช้แค่ apex)"
fi

# Nameservers (Cloudflare)
ns="$(dig +short NS "$DOMAIN" 2>/dev/null | head -3 | tr '\n' ' ' || true)"
if [[ "$ns" == *"cloudflare"* ]]; then
  pass "Nameserver เป็น Cloudflare"
elif [[ -n "$ns" ]]; then
  note "Nameserver: $ns (ถ้าจดที่ Cloudflare ควรเห็น cloudflare.com)"
else
  note "ยังไม่ resolve NS — รอ DNS propagate"
fi

echo ""
echo "ผ่าน: $ok · ไม่ผ่าน: $fail"
[[ "$fail" -eq 0 ]] && exit 0 || exit 1
