#!/usr/bin/env bash
# ดึงรายละเอียดโครงการขึ้น Cloud เบื้องหลัง (ต่อจาก START_OFFSET)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/ph-pipeline-env.sh"
source "$ROOT/scripts/dev-path.sh"
cd "$ROOT"

OFFSET="${START_OFFSET:-0}"
LOG="$PH_PIPELINE_DIR/import-cloud.log"
cp "$PH_PIPELINE_DIR/ph-slugs-metro.json" /tmp/ph-discover.json

echo "[$(date '+%Y-%m-%d %H:%M:%S')] import เริ่ม offset=$OFFSET" >>"$LOG"

SKIP_DISCOVER=1 IMPORT_SCOPE=metro BATCH_SIZE="${BATCH_SIZE:-20}" \
  START_OFFSET="$OFFSET" MAX_BATCHES="${MAX_BATCHES:-0}" \
  bash "$ROOT/scripts/import-collected-projects.sh" >>"$LOG" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] import จบ offset=$OFFSET" >>"$LOG"
