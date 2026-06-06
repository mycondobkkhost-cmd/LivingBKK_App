#!/usr/bin/env bash
# เฟส 1 — เก็บลิงก์โครงการให้ครบที่สุด (ยังไม่ดึงรายละเอียด ยังไม่กรอง)
#
#   ./scripts/collect-all-project-links.sh
#
# ผลลัพธ์:
#   /tmp/ph-all-links-raw.json   — ทุก slug ที่พบ
#   /tmp/ph-metro-slugs.json     — progress + รายการล่าสุด
#   /tmp/ph-discover-run.log     — log
#
# ตัวเลือก:
#   FRESH=1        ลบ progress เดิม เริ่มใหม่
#   RESUME=0       ไม่ต่อจาก progress
#   LAYERS=...     ชั้นค้นหา (ค่าเริ่มต้น A,B,C,D,E)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ph-pipeline-env.sh
source "$ROOT/scripts/ph-pipeline-env.sh"
cd "$ROOT"

export COLLECT_ALL=1
export PYTHONUNBUFFERED=1
export LAYERS="${LAYERS:-A,B,C,D,E}"
export RESUME="${RESUME:-1}"
export MAX_PAGES_PER_SEED="${MAX_PAGES_PER_SEED:-0}"
export MAX_PAGES_PER_QUERY="${MAX_PAGES_PER_QUERY:-0}"
export DISCOVER_DELAY="${DISCOVER_DELAY:-0.12}"

if [[ "${FRESH:-0}" == "1" ]]; then
  rm -f "$PH_PIPELINE_DIR/ph-metro-slugs.json" "$PH_PIPELINE_DIR/ph-all-slugs.json"
  rm -f "$PH_PIPELINE_DIR/ph-all-links-raw.json" "$PH_PIPELINE_DIR/ph-metro-discover-progress.json"
fi

DISCOVER_LOG="$PH_PIPELINE_DIR/ph-discover-run.log"

echo "=== เฟส 1: เก็บลิงก์โครงการ (COLLECT_ALL) ==="
echo "ชั้น: $LAYERS | บันทึก: $PH_PIPELINE_DIR/ph-all-links-raw.json"
echo "ดูความคืบหน้า: tail -f $DISCOVER_LOG"
echo ""

PH_PIPELINE_DIR="$PH_PIPELINE_DIR" python3 -u "$ROOT/scripts/discover-metro-projects-v2.py" 2>&1 | tee -a "$DISCOVER_LOG"

echo ""
echo "✅ เฟส 1 เสร็จ — ถัดไป: ./scripts/filter-collected-slugs.py แล้ว import"
