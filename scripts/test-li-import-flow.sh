#!/usr/bin/env bash
# ทดสอบ E2E: LI ไม่พบโครงการ → สร้างจากลิงก์แชร์ → ผูกประกาศ
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/.env.local"

BASE="${SUPABASE_URL}"
ANON="${SUPABASE_ANON_KEY}"
EMAIL="${ADMIN_EMAIL:-demo-admin@livingbkk.local}"
PASS="${ADMIN_PASSWORD:-demo12345}"
LI_URL="${LI_TEST_URL:-https://www.livinginsider.com/istockdetail/DIoooI_DojybCI.html}"
MAP_LINK="${MAP_TEST_LINK:-https://www.google.com/maps/place/Onnut/@13.705462,100.601321,17z/data=!3m1!4b1!4m6!3m5!1s0x0:0x0!8m2!3d13.705462!4d100.601321}"
IMPORT_ID="${LI_IMPORT_ID:-d9ecbfce-ec7b-4b39-acd2-54359e03ac50}"

echo "=== 1) Login admin ==="
TOKEN=$(curl -sS -X POST "$BASE/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON" -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))")
[[ -n "$TOKEN" ]] || { echo "❌ login failed"; exit 1; }
echo "✅ login ok"

AUTH_H=(-H "apikey: $ANON" -H "Authorization: Bearer $TOKEN")

echo ""
echo "=== 2) โหลด import ทดสอบ ==="
curl -sS "$BASE/rest/v1/listing_imports?id=eq.$IMPORT_ID&select=id,listing_id,project_preview,parsed,status" \
  "${AUTH_H[@]}" -o /tmp/li-test-import.json

python3 <<'PY'
import json, sys
rows=json.load(open('/tmp/li-test-import.json'))
if not rows:
    sys.exit('❌ ไม่พบ import')
row=rows[0]
flags=(row.get('parsed') or {}).get('flags') or []
print('import_id:', row['id'])
print('listing_id:', row.get('listing_id'))
print('project:', row.get('project_preview'))
print('status:', row.get('status'))
print('flags:', flags)
print('project_not_in_registry:', 'project_not_in_registry' in flags)
if not row.get('listing_id'):
    sys.exit('❌ ไม่มี listing_id')
PY

LISTING_ID=$(python3 -c "import json; print(json.load(open('/tmp/li-test-import.json'))[0]['listing_id'])")
PROJECT_NAME=$(python3 -c "import json; print(json.load(open('/tmp/li-test-import.json'))[0].get('project_preview') or 'โครงการทดสอบ')")

echo ""
echo "=== 3) Parse map share link ==="
read -r LAT LNG < <(python3 <<PY
import re
link = """$MAP_LINK"""
m = re.search(r'!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)', link)
if not m:
    m = re.search(r'@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)', link)
if not m:
    raise SystemExit('no coords')
print(m.group(1), m.group(2))
PY
)
echo "coords: $LAT, $LNG"
WKT="SRID=4326;POINT($LNG $LAT)"
DISTRICT="พระโขนง"

echo ""
echo "=== 4) Create project (maps_share_link) ==="
CREATE_BODY=$(python3 -c "import json; print(json.dumps({
  'name_th': '''$PROJECT_NAME''',
  'name_en': 'LI Test Project',
  'district': '''$DISTRICT''',
  'property_type': 'condo',
  'lat': float('$LAT'),
  'lng': float('$LNG'),
  'is_active': True,
  'source_platform': 'maps_share_link',
  'source_url': '''$MAP_LINK''',
  'aliases': ['''$PROJECT_NAME'''],
}))")
curl -sS -X POST "$BASE/rest/v1/property_projects" \
  "${AUTH_H[@]}" -H "Content-Type: application/json" -H "Prefer: return=representation" \
  -d "$CREATE_BODY" -o /tmp/li-test-project.json

PROJECT_ID=$(python3 -c "import json; r=json.load(open('/tmp/li-test-project.json')); print(r[0]['id'] if isinstance(r,list) else r.get('id',''))")
if [[ -z "$PROJECT_ID" ]]; then
  echo "❌ create project failed:"
  cat /tmp/li-test-project.json
  exit 1
fi
echo "✅ project_id: $PROJECT_ID"

echo ""
echo "=== 5) Link listing ==="
PATCH_LISTING=$(python3 -c "import json; print(json.dumps({
  'project_id': '$PROJECT_ID',
  'project_name': '''$PROJECT_NAME''',
  'district': '''$DISTRICT''',
  'location_exact': '$WKT',
  'location_public': '$WKT',
}))")
curl -sS -X PATCH "$BASE/rest/v1/listings?id=eq.$LISTING_ID" \
  "${AUTH_H[@]}" -H "Content-Type: application/json" \
  -d "$PATCH_LISTING" -o /tmp/li-link-listing.json

if grep -qi error /tmp/li-link-listing.json 2>/dev/null; then
  echo "❌ link listing failed:"; cat /tmp/li-link-listing.json; exit 1
fi
echo "✅ listing linked"

echo ""
echo "=== 6) Update import flags ==="
python3 <<PY
import json
row=json.load(open('/tmp/li-test-import.json'))[0]
parsed=row.get('parsed') or {}
flags=[f for f in (parsed.get('flags') or []) if f not in (
  'project_not_in_registry','missing_project','missing_coords','geocode_preview_ready')]
if 'project_linked' not in flags:
    flags.append('project_linked')
parsed['flags']=flags
parsed['matched_project_id']='$PROJECT_ID'
parsed.pop('geocode_preview', None)
json.dump({
  'parsed': parsed,
  'project_preview': '''$PROJECT_NAME''',
  'status': 'draft_ready',
  'error_message': None,
}, open('/tmp/li-patch-import.json','w'), ensure_ascii=False)
PY

curl -sS -X PATCH "$BASE/rest/v1/listing_imports?id=eq.$IMPORT_ID" \
  "${AUTH_H[@]}" -H "Content-Type: application/json" \
  -d @/tmp/li-patch-import.json -o /tmp/li-patch-res.json

echo ""
echo "=== 7) Verify ==="
curl -sS "$BASE/rest/v1/listings?id=eq.$LISTING_ID&select=project_id,project_name,district" \
  "${AUTH_H[@]}" | python3 -m json.tool
curl -sS "$BASE/rest/v1/listing_imports?id=eq.$IMPORT_ID&select=status,parsed" \
  "${AUTH_H[@]}" \
  | python3 -c "import sys,json; r=json.load(sys.stdin)[0]; print('import status:', r['status']); print('flags:', (r.get('parsed') or {}).get('flags'))"

echo ""
echo "✅ E2E LI import flow ผ่าน"
echo "   UI local: http://127.0.0.1:8765/admin/console (หลังรัน build-web + serve)"
