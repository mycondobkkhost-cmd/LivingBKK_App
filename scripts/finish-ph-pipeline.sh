#!/usr/bin/env bash
# เฟส 2–3 หลัง collect เสร็จ (กรอง + ขึ้น Cloud)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ph-pipeline-env.sh
source "$ROOT/scripts/ph-pipeline-env.sh"
LOG="$PH_PIPELINE_DIR/ph-full-pipeline.log"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

cd "$ROOT"
export PH_PIPELINE_DIR

if pgrep -f "discover-metro-projects-v2.py" >/dev/null 2>&1; then
  echo "❌ เฟส 1 ยังรันอยู่ — รอให้จบก่อน"
  exit 1
fi

RAW="$PH_PIPELINE_DIR/ph-all-links-raw.json"
if [[ ! -f "$RAW" ]]; then
  echo "❌ ไม่พบ $RAW — รัน ./scripts/resume-ph-pipeline.sh ก่อน"
  exit 1
fi

COUNT=$(PH_PIPELINE_DIR="$PH_PIPELINE_DIR" python3 -c "
import json, os
print(json.load(open(os.path.join(os.environ['PH_PIPELINE_DIR'], 'ph-all-links-raw.json'))).get('count', 0))
")
log "=== เฟส 2–3 (จาก $COUNT ลิงก์) ==="

log "เฟส 2: คัดกรอง"
PH_PIPELINE_DIR="$PH_PIPELINE_DIR" python3 "$ROOT/scripts/filter-collected-slugs.py" 2>&1 | tee -a "$LOG"

METRO=$(PH_PIPELINE_DIR="$PH_PIPELINE_DIR" python3 -c "
import json, os
print(json.load(open(os.path.join(os.environ['PH_PIPELINE_DIR'], 'ph-slugs-metro.json'))).get('count', 0))
")
log "เฟส 2 เสร็จ — metro $METRO รายการ (ตัดซ้ำแล้ว)"

log "เฟส 3: ดึงรายละเอียดขึ้น Cloud"
PH_PIPELINE_DIR="$PH_PIPELINE_DIR" IMPORT_SCOPE="${IMPORT_SCOPE:-metro}" \
  bash "$ROOT/scripts/import-collected-projects.sh" 2>&1 | tee -a "$LOG"

log "✅ ครบเฟส 2–3 — เปิดแอปแอดมิน → โครงการ"
