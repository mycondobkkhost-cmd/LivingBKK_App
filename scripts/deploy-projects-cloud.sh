#!/usr/bin/env bash
# Deploy เฉพาะสมุดโครงการ: migration + project-import-* functions
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
cd "$ROOT"

VISIBLE="$ROOT/ใส่รหัส-database-ตรงนี้.env"
ENV_FILE="$ROOT/.env.local"

_load_env() {
  if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1091
    source "$ENV_FILE"
  fi
  if [[ -f "$VISIBLE" ]]; then
    # shellcheck disable=SC1091
    source "$VISIBLE"
  fi
}

if [[ ! -f "$ENV_FILE" ]] && [[ ! -f "$VISIBLE" ]]; then
  echo "❌ ไม่พบไฟล์ตั้งค่า"
  exit 1
fi

set -a
_load_env
set +a

if [[ -n "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  export SUPABASE_ACCESS_TOKEN
elif ! supabase projects list >/dev/null 2>&1; then
  echo "❌ ยังไม่ได้ login Supabase CLI"
  echo "   วิธีที่ 1: รัน supabase login ใน Terminal"
  echo "   วิธีที่ 2: ใส่ SUPABASE_ACCESS_TOKEN ใน .env.local"
  echo "           สร้างที่ https://supabase.com/dashboard/account/tokens"
  exit 1
fi

if [[ -z "${SUPABASE_DB_PASSWORD:-}" ]]; then
  echo "❌ ยังไม่ได้ใส่ SUPABASE_DB_PASSWORD"
  echo ""
  echo "   เปิดไฟล์: LivingBKK_App/ใส่รหัส-database-ตรงนี้.env"
  echo "   ใส่รหัสหลัง = แล้ว Save"
  echo ""
  "$ROOT/scripts/open-env-local.sh"
  exit 1
fi

PROJECT_REF="${SUPABASE_PROJECT_REF:-auflqgqrmpbioflnhsrj}"

echo "=== link project $PROJECT_REF ==="
if [[ -n "${SUPABASE_DB_PASSWORD:-}" ]]; then
  supabase link --project-ref "$PROJECT_REF" --password "$SUPABASE_DB_PASSWORD"
else
  supabase link --project-ref "$PROJECT_REF"
fi

echo ""
echo "=== db push ==="
echo y | supabase db push

echo ""
echo "=== Edge Functions (projects) ==="
for fn in project-import-fetch project-import-propertyhub project-tag-enrich; do
  echo "→ $fn"
  supabase functions deploy "$fn" --use-api
done

echo ""
echo "✅ Deploy สมุดโครงการเสร็จ"
echo "   ถัดไป: แอดมิน → โครงการ → 「ดึงทั้งหมดจาก Property Hub」"
echo "   หรือ: ./scripts/sync-propertyhub-cloud.sh"
