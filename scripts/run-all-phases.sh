#!/usr/bin/env bash
# รันครบ 3 เฟส: เก็บลิงก์ → กรอง → ดึงรายละเอียดขึ้น Cloud
#
#   ./scripts/run-all-phases.sh
#
# ถ้าเฟส 1 กำลังรันอยู่ จะรอให้จบก่อน แล้วค่อยเฟส 2–3
# Log: data/ph-pipeline/ph-full-pipeline.log
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ph-pipeline-env.sh
source "$ROOT/scripts/ph-pipeline-env.sh"
LOG="$PH_PIPELINE_DIR/ph-full-pipeline.log"
PROGRESS="$PH_PIPELINE_DIR/ph-metro-discover-progress.json"
RAW="$PH_PIPELINE_DIR/ph-all-links-raw.json"
METRO_FILTERED="$PH_PIPELINE_DIR/ph-slugs-metro.json"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

cd "$ROOT"
export PH_PIPELINE_DIR

log "=== PROPPITER — รันครบทุกเฟส ==="
log "โฟลเดอร์ข้อมูล: $PH_PIPELINE_DIR"

# รอเฟส 1 ที่รันอยู่ (ถ้ามี)
if pgrep -f "discover-metro-projects-v2.py" >/dev/null 2>&1; then
  log "เฟส 1 กำลังรัน — รอให้จบ..."
  while pgrep -f "discover-metro-projects-v2.py" >/dev/null 2>&1; do
    COUNT=$(PH_PIPELINE_DIR="$PH_PIPELINE_DIR" python3 -c "
import json, os
p = os.path.join(os.environ['PH_PIPELINE_DIR'], 'ph-all-links-raw.json')
if os.path.exists(p):
    print(json.load(open(p)).get('count', 0))
else:
    print('?')
" 2>/dev/null || echo "?")
    log "  เก็บลิงก์แล้ว: $COUNT รายการ..."
    sleep 60
  done
  log "เฟส 1 (ที่รันอยู่) เสร็จแล้ว"
else
  if [[ -f "$PROGRESS" ]]; then
    log "เฟส 1 — ต่อจาก progress เดิม (RESUME=1)"
    FRESH=0 RESUME=1 COLLECT_ALL=1 bash "$ROOT/scripts/collect-all-project-links.sh" 2>&1 | tee -a "$LOG"
  else
    log "เฟส 1 — เริ่มเก็บลิงก์ใหม่ (progress หาย — เก็บถาวรใน data/ph-pipeline)"
    FRESH=1 RESUME=0 COLLECT_ALL=1 bash "$ROOT/scripts/collect-all-project-links.sh" 2>&1 | tee -a "$LOG"
  fi
fi

COUNT=$(PH_PIPELINE_DIR="$PH_PIPELINE_DIR" python3 -c "
import json, os
print(json.load(open(os.path.join(os.environ['PH_PIPELINE_DIR'], 'ph-all-links-raw.json'))).get('count', 0))
" 2>/dev/null || echo 0)
log "เฟส 1 เสร็จ — รวม $COUNT ลิงก์"

log "=== เฟส 2: คัดกรอง ==="
PH_PIPELINE_DIR="$PH_PIPELINE_DIR" python3 "$ROOT/scripts/filter-collected-slugs.py" 2>&1 | tee -a "$LOG"

METRO=$(PH_PIPELINE_DIR="$PH_PIPELINE_DIR" python3 -c "
import json, os
print(json.load(open(os.path.join(os.environ['PH_PIPELINE_DIR'], 'ph-slugs-metro.json'))).get('count', 0))
" 2>/dev/null || echo 0)
log "เฟส 2 เสร็จ — metro $METRO รายการ"

log "=== เฟส 3: ดึงรายละเอียดขึ้น Cloud ==="
PH_PIPELINE_DIR="$PH_PIPELINE_DIR" IMPORT_SCOPE="${IMPORT_SCOPE:-metro}" \
  bash "$ROOT/scripts/import-collected-projects.sh" 2>&1 | tee -a "$LOG"

log "✅ ครบทุกเฟสแล้ว — เปิดแอปแอดมิน → โครงการ"
