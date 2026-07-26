#!/usr/bin/env bash
# ตรวจว่า GOOGLE_MAPS_API_KEY ใช้ได้ (local + Supabase Edge geocode)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/.env.local"

echo "=== RealXtate — verify Google Maps key ==="

if [[ -z "${GOOGLE_MAPS_API_KEY:-}" ]] || [[ "${GOOGLE_MAPS_API_KEY}" == *YOUR_* ]]; then
  echo "❌ .env.local ยังไม่มี GOOGLE_MAPS_API_KEY"
  echo "   สร้าง key ที่ https://console.cloud.google.com/google/maps-apis/credentials"
  echo "   แล้วรัน: ./scripts/setup-google-maps.sh AIzaSy..."
  exit 1
fi

echo "→ ทดสอบ Places API (New)"
PLACES_NEW=$(curl -sS -X POST "https://places.googleapis.com/v1/places:searchText" \
  -H "Content-Type: application/json" \
  -H "X-Goog-Api-Key: ${GOOGLE_MAPS_API_KEY}" \
  -H "X-Goog-FieldMask: places.displayName,places.formattedAddress,places.location" \
  -d '{"textQuery":"Indy 5 Bangna condo bangkok thailand","languageCode":"th","regionCode":"TH"}')

if echo "$PLACES_NEW" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('places') else 1)" 2>/dev/null; then
  echo "✅ Places API (New) — OK"
else
  echo "❌ Places API (New) — ยังไม่พร้อม"
  echo "$PLACES_NEW" | python3 -m json.tool 2>/dev/null || echo "$PLACES_NEW"
  echo ""
  echo "   เปิด API นี้แล้วรอ 1–2 นาที:"
  echo "   https://console.cloud.google.com/marketplace/product/google/places.googleapis.com?project=livingbkk"
  exit 1
fi

if [[ -z "${SUPABASE_URL:-}" ]] || [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "⚠️  ข้าม Supabase Edge — ไม่มี SUPABASE_URL/ANON_KEY"
  exit 0
fi

echo ""
echo "→ ทดสอบ maps-share-resolve geocode fallback (Supabase Edge secret)"
TOKEN=$(curl -sS -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Content-Type: application/json" \
  -d "{\"email\":\"${ADMIN_EMAIL:-demo-admin@livingbkk.local}\",\"password\":\"${ADMIN_PASSWORD:-demo12345}\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))")
[[ -n "$TOKEN" ]] || { echo "❌ admin login failed"; exit 1; }

EDGE=$(curl -sS -X POST "$SUPABASE_URL/functions/v1/maps-share-resolve" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://maps.app.goo.gl/test","project_name":"Indy 5","hint_district":"บางนา"}')

if echo "$EDGE" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('result') else 1)" 2>/dev/null; then
  echo "✅ Supabase Edge geocode — OK"
  echo "$EDGE" | python3 -m json.tool
elif echo "$EDGE" | grep -q google_maps_key_missing; then
  echo "❌ Supabase Edge ยังไม่มี GOOGLE_MAPS_API_KEY secret"
  echo "   รัน: ./scripts/setup-google-maps.sh"
  exit 1
else
  echo "⚠️  Edge response (อาจต้อง deploy maps-share-resolve ล่าสุด):"
  echo "$EDGE" | python3 -m json.tool 2>/dev/null || echo "$EDGE"
fi

echo ""
echo "✅ ตรวจเสร็จ"
