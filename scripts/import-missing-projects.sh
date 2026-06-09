#!/usr/bin/env bash
# ดึงโครงการที่ยังไม่มีใน Cloud (เทียบ slug+alias กับ metro)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ph-pipeline-env.sh
source "$ROOT/scripts/ph-pipeline-env.sh"
source "$ROOT/scripts/dev-path.sh"
cd "$ROOT"
export PH_PIPELINE_DIR

LOG="$PH_PIPELINE_DIR/import-missing.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] refresh missing" | tee -a "$LOG"
PH_PIPELINE_DIR="$PH_PIPELINE_DIR" python3 "$ROOT/scripts/refresh-ph-missing.py" | tee -a "$LOG"

MISSING=$(python3 -c "import json; print(json.load(open('$PH_PIPELINE_DIR/ph-slugs-missing.json'))['count'])")
if [[ "$MISSING" == "0" ]]; then
  echo "✅ ไม่มีโครงการค้าง — สมุดครบแล้ว" | tee -a "$LOG"
  exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] import $MISSING slugs" | tee -a "$LOG"
cp "$PH_PIPELINE_DIR/ph-slugs-missing.json" /tmp/ph-discover.json
SKIP_DISCOVER=1 IMPORT_SCOPE=metro BATCH_SIZE="${BATCH_SIZE:-20}" MAX_BATCHES=0 \
  bash "$ROOT/scripts/sync-propertyhub-cloud.sh" 2>&1 | tee -a "$LOG"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] refresh หลัง import" | tee -a "$LOG"
PH_PIPELINE_DIR="$PH_PIPELINE_DIR" python3 "$ROOT/scripts/refresh-ph-missing.py" | tee -a "$LOG"
