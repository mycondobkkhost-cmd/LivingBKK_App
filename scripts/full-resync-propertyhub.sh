#!/usr/bin/env bash
# รีเซ็ตสมุดโครงการทั้งหมด → ค้นหาชื่อแบบเต็ม (ไล่ตัวอักษร/ตัวเลข) → ดึงรายละเอียดขึ้น Cloud
#
# ใช้เมื่อต้องการเคลียร์ข้อมูลเก่าแล้วเติมใหม่ครบจาก Property Hub
#
#   CONFIRM=1 ./scripts/full-resync-propertyhub.sh
#
# ตัวเลือก:
#   FRESH_DISCOVER=1  — ลบ progress ค้นหาเดิม เริ่มค้นหาใหม่
#   LAYERS=A,B,C,D,E  — ชั้นค้นหา (ค่าเริ่มต้น = ครบทุกชั้น รวมไล่ a-z 0-9)
#   MAX_BATCHES=0     — 0 = ดึงจนจบทุก slug
#   SKIP_PURGE=1      — ข้ามลบโครงการ (ดึงทับอย่างเดียว)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
cd "$ROOT"

if [[ "${CONFIRM:-0}" != "1" ]]; then
  echo "⚠️  คำสั่งนี้จะ:"
  echo "   1) ลบโครงการทั้งหมดใน property_projects (ถอด project_id จากประกาศ)"
  echo "   2) ค้นหาชื่อโครงการจาก Property Hub แบบเต็ม (เขต + BTS/MRT + ไล่ตัวอักษร/ตัวเลข)"
  echo "   3) ดึงรายละเอียดทีละชุดขึ้น Supabase"
  echo ""
  echo "รัน: CONFIRM=1 ./scripts/full-resync-propertyhub.sh"
  exit 1
fi

VISIBLE="$ROOT/ใส่รหัส-database-ตรงนี้.env"
ENV_FILE="$ROOT/.env.local"
_load_env() {
  [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
  [[ -f "$VISIBLE" ]] && source "$VISIBLE"
}
set -a
_load_env
set +a

SUPABASE_URL="${SUPABASE_URL:-https://auflqgqrmpbioflnhsrj.supabase.co}"
ANON_KEY="${SUPABASE_ANON_KEY:-}"
ADMIN_EMAIL="${ADMIN_EMAIL:-demo-admin@livingbkk.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-demo12345}"

if [[ -z "$ANON_KEY" ]]; then
  ANON_KEY="$(grep -E '^SUPABASE_ANON_KEY=' "$ROOT/mobile/assets/env" | cut -d= -f2- | tr -d '\r' || true)"
fi
[[ -n "$ANON_KEY" ]] || { echo "❌ ไม่พบ SUPABASE_ANON_KEY"; exit 1; }

echo "=== เข้าสู่ระบบแอดมิน ==="
AUTH_JSON=$(curl -sS -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")
ACCESS_TOKEN=$(echo "$AUTH_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null || true)
[[ -n "$ACCESS_TOKEN" ]] || { echo "❌ ล็อกอินไม่สำเร็จ"; exit 1; }

if [[ "${SKIP_PURGE:-0}" != "1" ]]; then
  echo ""
  echo "=== ลบโครงการเก่าทั้งหมด ==="
  PURGE_RESP=$(curl -sS -X POST "$SUPABASE_URL/functions/v1/project-import-propertyhub" \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"mode":"purge_all","confirm":true}')
  echo "$PURGE_RESP" | python3 -c "
import sys, json
d=json.load(sys.stdin)
if d.get('error'):
    print('❌', d['error'])
    raise SystemExit(1)
print(f\"✅ ลบโครงการ {d.get('projects_deleted',0)} รายการ · ถอดลิงก์ประกาศ {d.get('listings_unlinked',0)} รายการ\")
" || exit 1
fi

if [[ "${FRESH_DISCOVER:-1}" == "1" ]]; then
  echo ""
  echo "=== ล้าง progress ค้นหาเดิม ==="
  rm -f /tmp/ph-metro-slugs.json /tmp/ph-all-slugs.json /tmp/ph-metro-discover-progress.json
fi

echo ""
echo "=== เฟส 1: เก็บลิงก์ทั้งหมด (COLLECT_ALL) ==="
COLLECT_ALL=1 LAYERS="${LAYERS:-A,B,C,D,E}" FRESH="${FRESH_DISCOVER:-1}" \
  bash "$ROOT/scripts/collect-all-project-links.sh"

echo ""
echo "=== เฟส 2: คัดกรอง ==="
python3 "$ROOT/scripts/filter-collected-slugs.py"

echo ""
echo "=== เฟส 3: ดึงรายละเอียด (metro) ==="
IMPORT_SCOPE="${IMPORT_SCOPE:-metro}" bash "$ROOT/scripts/import-collected-projects.sh"

echo ""
echo "✅ รีเซ็ต + ซิงค์เต็มเสร็จ — เปิดแอปแอดมิน → โครงการ เพื่อตรวจรายการ"
