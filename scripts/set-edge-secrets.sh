#!/usr/bin/env bash
# ตั้งรหัสลับให้ Edge Functions (จำเป็นสำหรับดึงโครงการ / นำเข้า / แชท)
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
  echo "❌ ไม่พบ .env.local"
  exit 1
fi

set -a
_load_env
set +a

PROJECT_REF="${SUPABASE_PROJECT_REF:-auflqgqrmpbioflnhsrj}"

if [[ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  echo "❌ ยังไม่ได้ใส่ SUPABASE_SERVICE_ROLE_KEY"
  echo ""
  echo "   1) เปิด Supabase Dashboard → Settings → API"
  echo "   2) คัดลอก service_role (secret) — อย่าใส่ในแอปมือถือ"
  echo "   3) วางใน .env.local บรรทัด SUPABASE_SERVICE_ROLE_KEY=..."
  echo ""
  exit 1
fi

if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "❌ ยังไม่ได้ใส่ SUPABASE_ANON_KEY (หรือ publishable key)"
  exit 1
fi

if [[ -n "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  export SUPABASE_ACCESS_TOKEN
elif ! supabase projects list >/dev/null 2>&1; then
  echo "❌ ยังไม่ได้ login Supabase CLI — รัน supabase login"
  exit 1
fi

echo "=== Edge Secrets โปรเจกต์ $PROJECT_REF ==="
echo "ℹ️  คีย์ SUPABASE_* ถูกจัดการโดยแพลตฟอร์มอัตโนมัติแล้ว"
echo "   (ดูได้ที่ Dashboard → Edge Functions → Secrets)"
echo ""
echo "=== อัปโหลดฟังก์ชันดึงโครงการ ==="
for fn in project-import-fetch project-import-propertyhub; do
  echo "→ $fn"
  supabase functions deploy "$fn" --project-ref "$PROJECT_REF" --use-api
done

echo ""
echo "✅ เสร็จแล้ว — ลองใหม่: หลังบ้าน → โครงการ → ดึงมาเติมฟอร์ม"
