#!/usr/bin/env bash
# อัปเดตเว็บ PROPPITER บน Netlify อัตโนมัติ (ไม่ต้องลากไฟล์)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB="$ROOT/mobile/build/web"
ZIP="$ROOT/mobile/build/livingbkk-web.zip"
SITE="${NETLIFY_SITE:-quiet-kangaroo-ab6073}"

# โหลด token (ไม่ commit) — ลำดับ: env ที่ส่งมา → .netlify-token → .env.local → ใส่รหัส-database
_load_token() {
  local f
  for f in "$ROOT/.netlify-token" "$ROOT/.env.local" "$ROOT/ใส่รหัส-database-ตรงนี้.env"; do
    [[ -f "$f" ]] || continue
    # shellcheck disable=SC1090
    set -a
    source <(grep -E '^NETLIFY_AUTH_TOKEN=' "$f" 2>/dev/null || true)
    set +a
    [[ -n "${NETLIFY_AUTH_TOKEN:-}" ]] && return 0
    if [[ "$f" == "$ROOT/.netlify-token" ]]; then
      NETLIFY_AUTH_TOKEN="$(tr -d '[:space:]' < "$f")"
      [[ -n "$NETLIFY_AUTH_TOKEN" ]] && return 0
    fi
  done
}
_load_token

if [[ ! -f "$WEB/index.html" ]]; then
  echo "▶ ยังไม่มี build — กำลัง build..."
  "$ROOT/scripts/build-web.sh"
fi

echo "▶ zip สำหรับ deploy..."
rm -f "$ZIP"
(cd "$WEB" && zip -r -q "$ZIP" .)
echo "   $ZIP ($(du -h "$ZIP" | cut -f1))"

if [[ -z "${NETLIFY_AUTH_TOKEN:-}" ]]; then
  echo ""
  echo "❌ ยังไม่มี NETLIFY_AUTH_TOKEN"
  echo "   1) Netlify → User settings → Applications → Personal access tokens → New token"
  echo "   2) ใส่ใน .env.local:  NETLIFY_AUTH_TOKEN=nfp_..."
  echo "      หรือสร้างไฟล์ .netlify-token (บรรทัดเดียว ไม่ commit)"
  echo "   3) รัน ./scripts/deploy-netlify.sh อีกครั้ง"
  echo ""
  echo "   หรือลาก zip เอง: ./scripts/open-netlify-upload.sh"
  "$ROOT/scripts/open-netlify-upload.sh" || true
  exit 1
fi

echo "▶ deploy → https://${SITE}.netlify.app"
RESP="$(curl -sS -w "\n%{http_code}" \
  -H "Authorization: Bearer ${NETLIFY_AUTH_TOKEN}" \
  -H "Content-Type: application/zip" \
  --data-binary "@${ZIP}" \
  "https://api.netlify.com/api/v1/sites/${SITE}/deploys")"

HTTP_CODE="$(echo "$RESP" | tail -1)"
BODY="$(echo "$RESP" | sed '$d')"

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "❌ Netlify API ล้มเหลว (HTTP $HTTP_CODE)"
  echo "$BODY" | head -c 500
  echo ""
  exit 1
fi

DEPLOY_URL="$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('deploy_ssl_url') or d.get('ssl_url') or '')" 2>/dev/null || true)"
echo ""
echo "✅ Deploy สำเร็จ"
echo "   ลิงก์: https://${SITE}.netlify.app"
[[ -n "$DEPLOY_URL" ]] && echo "   Deploy: $DEPLOY_URL"
echo "   รอ 30–60 วินาที แล้ว hard refresh บนมือถือ"
