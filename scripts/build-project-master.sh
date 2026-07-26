#!/usr/bin/env bash
# สร้างสมุดโครงการมาสเตอร์: ชื่อจาก Property Hub + จัดทำเล/BTS จากพิกัด
# LivingInsider ใช้เติมพิกัดทีหลังผ่านแอดมิน (ไม่ทับชื่อ PH)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=dev-path.sh
source "$ROOT/scripts/dev-path.sh"

echo "==> RealXtate project master (Property Hub names + transit from pins)"
echo "    Docs: docs/PROJECT-MASTER.md"
echo

if [[ "${SKIP_DEPLOY:-0}" != "1" ]]; then
  echo "==> Deploy project edge functions / migrations (if needed)"
  "$ROOT/scripts/deploy-projects-cloud.sh" || {
    echo "⚠️  deploy-projects-cloud ล้มเหลว — ถ้าเคย deploy แล้ว ตั้ง SKIP_DEPLOY=1 แล้วรันใหม่"
    exit 1
  }
fi

SLUGS="$ROOT/data/ph-pipeline/ph-metro-slugs.json"
if [[ ! -f "$SLUGS" ]]; then
  echo "ไม่พบ $SLUGS — รันค้นหา slug ก่อน:"
  echo "  ./scripts/rediscover-metro-projects.sh"
  exit 1
fi

COUNT="$(python3 -c "import json; d=json.load(open('$SLUGS')); print(d.get('count') or len(d.get('slugs') or d.get('items') or []))")"
echo "==> Property Hub metro slugs: $COUNT"
echo "==> Sync เข้า property_projects (source_platform=propertyhub)"
SKIP_DISCOVER=1 bash "$ROOT/scripts/sync-propertyhub-cloud.sh"

echo "==> Rebuild nearby_transit / bts_station จากพิกัดจริง"
python3 "$ROOT/scripts/rebuild-project-transit-links.py"

echo
echo "✅ สมุดมาสเตอร์พร้อมใช้งานในแอป (ProjectCatalog / ช่องเลือกโครงการ)"
echo "   เติมพิกัดจาก LivingInsider ได้ทีหลังในแอดมิน → โครงการ → วางลิงก์ LI"
echo "   (ระบบจะไม่ทับชื่อที่มาจาก Property Hub)"
