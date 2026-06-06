#!/usr/bin/env bash
# ทำงานต่อ pipeline อัปโครงการ (เก็บ progress ใน data/ph-pipeline)
#
#   ./scripts/resume-ph-pipeline.sh           # เฟส 1 เบื้องหลัง
#   ./scripts/resume-ph-pipeline.sh --all     # ครบ 3 เฟส (หน้าจอ — ช้ามาก)
#   ./scripts/resume-ph-pipeline.sh --finish  # เฟส 2–3 หลังเฟส 1 จบ
#
# ดูความคืบหน้า:
#   tail -f data/ph-pipeline/ph-discover-run.log
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ph-pipeline-env.sh
source "$ROOT/scripts/ph-pipeline-env.sh"

export COLLECT_ALL=1
export RESUME=1
export PYTHONUNBUFFERED=1
export MAX_PAGES_PER_QUERY="${MAX_PAGES_PER_QUERY:-120}"
export DISCOVER_DELAY="${DISCOVER_DELAY:-0.12}"
export SAVE_EVERY_PAGES="${SAVE_EVERY_PAGES:-10}"
export BACKUP_EVERY_N_PROJECTS="${BACKUP_EVERY_N_PROJECTS:-250}"

cd "$ROOT"

if [[ "${1:-}" == "--finish" ]]; then
  exec bash "$ROOT/scripts/finish-ph-pipeline.sh"
fi

if [[ "${1:-}" == "--all" ]]; then
  exec bash "$ROOT/scripts/run-all-phases.sh"
fi

if pgrep -f "discover-metro-projects-v2.py" >/dev/null 2>&1; then
  echo "⚠️  เฟส 1 รันอยู่แล้ว"
  echo "   tail -f $PH_PIPELINE_DIR/ph-discover-run.log"
  exit 0
fi

DISCOVER_LOG="$PH_PIPELINE_DIR/ph-discover-run.log"
echo "=== เฟส 1: ต่อเก็บลิงก์ ===" | tee -a "$DISCOVER_LOG"
echo "โฟลเดอร์: $PH_PIPELINE_DIR" | tee -a "$DISCOVER_LOG"

nohup env \
  PH_PIPELINE_DIR="$PH_PIPELINE_DIR" \
  COLLECT_ALL=1 RESUME=1 PYTHONUNBUFFERED=1 \
  MAX_PAGES_PER_QUERY="$MAX_PAGES_PER_QUERY" \
  DISCOVER_DELAY="$DISCOVER_DELAY" \
  SAVE_EVERY_PAGES="$SAVE_EVERY_PAGES" \
  BACKUP_EVERY_N_PROJECTS="$BACKUP_EVERY_N_PROJECTS" \
  python3 -u "$ROOT/scripts/discover-metro-projects-v2.py" \
  >>"$DISCOVER_LOG" 2>&1 &

echo "✅ เริ่มเฟส 1 แล้ว (PID $!)"
echo "   บันทึกถาวร: $PH_PIPELINE_DIR (ทุก ${SAVE_EVERY_PAGES} หน้า + backup ทุก ${BACKUP_EVERY_N_PROJECTS} ลิงก์)"
echo "   tail -f $DISCOVER_LOG"
echo "   กู้คืน: ./scripts/restore-ph-pipeline.sh"
echo "   เมื่อเฟส 1 จบ: ./scripts/resume-ph-pipeline.sh --finish"
