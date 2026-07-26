#!/usr/bin/env bash
# ทดสอบ flow เพิ่มโครงการจากลิงก์แผนที่ (API ระดับเดียวกับ UI)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/.env.local"

BASE="${SUPABASE_URL}"
ANON="${SUPABASE_ANON_KEY}"
EMAIL="${ADMIN_EMAIL:-demo-admin@livingbkk.local}"
PASS="${ADMIN_PASSWORD:-demo12345}"
IMPORT_ID="${1:-2d84675e-d87f-40db-85f2-707db696335b}"
MAP_LINK="${MAP_TEST_LINK:-https://www.google.com/maps/place/Indy+5+Bangna+Km.7/@13.70,100.50,17z/data=!3m1!4b1!4m6!3m5!1s0x0!8m2!3d13.668000!4d100.645000}"

echo "=== 1) Login admin ==="
TOKEN=$(curl -sS -X POST "$BASE/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON" -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))")
[[ -n "$TOKEN" ]] || { echo "❌ login failed"; exit 1; }
AUTH_H=(-H "apikey: $ANON" -H "Authorization: Bearer $TOKEN")
echo "✅ login ok"

echo ""
echo "=== 2) maps-share-resolve ==="
RESOLVE=$(curl -sS -X POST "$BASE/functions/v1/maps-share-resolve" \
  "${AUTH_H[@]}" -H "Content-Type: application/json" \
  -d "{\"url\":\"$MAP_LINK\"}")
echo "$RESOLVE" | python3 -m json.tool
LAT=$(echo "$RESOLVE" | python3 -c "import sys,json; r=json.load(sys.stdin).get('result') or {}; print(r.get('lat',''))")
LNG=$(echo "$RESOLVE" | python3 -c "import sys,json; r=json.load(sys.stdin).get('result') or {}; print(r.get('lng',''))")
PLACE=$(echo "$RESOLVE" | python3 -c "import sys,json; r=json.load(sys.stdin).get('result') or {}; print(r.get('place_name',''))")
[[ -n "$LAT" && -n "$LNG" ]] || { echo "❌ resolve failed"; exit 1; }
echo "✅ coords: $LAT, $LNG · place: $PLACE"

echo ""
echo "=== 3) Load import $IMPORT_ID ==="
curl -sS "$BASE/rest/v1/listing_imports?id=eq.$IMPORT_ID&select=id,listing_id,project_preview,parsed" \
  "${AUTH_H[@]}" -o /tmp/add-project-import.json
LISTING_ID=$(python3 -c "import json; r=json.load(open('/tmp/add-project-import.json'))[0]; print(r['listing_id'])")
PROJECT_NAME=$(python3 -c "import json; r=json.load(open('/tmp/add-project-import.json'))[0]; print(r.get('project_preview') or 'Indy 5')")
echo "listing_id=$LISTING_ID project=$PROJECT_NAME"

echo ""
echo "=== 4) Create project (maps_share_link) ==="
NAME_EN="${PLACE:-Indy 5 Bangna Km.7}"
CREATE_BODY=$(python3 -c "import json; print(json.dumps({
  'name_th': '''$PROJECT_NAME''',
  'name_en': '''$NAME_EN''',
  'district': 'บางนา',
  'property_type': 'condo',
  'lat': float('$LAT'),
  'lng': float('$LNG'),
  'is_active': True,
  'source_platform': 'maps_share_link',
  'source_url': '''$MAP_LINK''',
  'aliases': ['''$PROJECT_NAME''', '''$NAME_EN'''],
}))")
curl -sS -X POST "$BASE/rest/v1/property_projects" \
  "${AUTH_H[@]}" -H "Content-Type: application/json" -H "Prefer: return=representation" \
  -d "$CREATE_BODY" -o /tmp/add-project-created.json
PROJECT_ID=$(python3 -c "import json; r=json.load(open('/tmp/add-project-created.json')); print(r[0]['id'] if isinstance(r,list) else r.get('id',''))")
if [[ -z "$PROJECT_ID" ]]; then
  echo "❌ create failed:"; cat /tmp/add-project-created.json; exit 1
fi
echo "✅ project_id=$PROJECT_ID"

echo ""
echo "=== 5) Link listing ==="
PATCH=$(python3 -c "import json; print(json.dumps({
  'project_id': '$PROJECT_ID',
  'project_name': '''$PROJECT_NAME''',
  'district': 'บางนา',
  'location': f'SRID=4326;POINT($LNG $LAT)',
}))")
curl -sS -X PATCH "$BASE/rest/v1/listings?id=eq.$LISTING_ID" \
  "${AUTH_H[@]}" -H "Content-Type: application/json" -H "Prefer: return=minimal" \
  -d "$PATCH"
echo "✅ listing linked"

echo ""
echo "=== 6) Cleanup test project (unlink + delete) ==="
curl -sS -X PATCH "$BASE/rest/v1/listings?id=eq.$LISTING_ID" \
  "${AUTH_H[@]}" -H "Content-Type: application/json" -H "Prefer: return=minimal" \
  -d '{"project_id": null}' >/dev/null
curl -sS -X DELETE "$BASE/rest/v1/property_projects?id=eq.$PROJECT_ID" \
  "${AUTH_H[@]}" -H "Prefer: return=minimal" >/dev/null
echo "✅ cleanup done"

echo ""
echo "=== PASS: add-project-from-map flow OK ==="
