#!/usr/bin/env bash
# เฟส 3 — ดึงรายละเอียดโครงการขึ้น Cloud จากไฟล์ที่กรองแล้ว
#
#   IMPORT_SCOPE=metro ./scripts/import-collected-projects.sh
#
# IMPORT_SCOPE:
#   metro    — กทม.+ปริมณฑล หลังตัดซ้ำ (ค่าเริ่มต้น)
#   all      — ไฟล์ดิบทั้งหมด (ไม่แนะนำ)
#   unknown  — ไม่มีที่อยู่
#   metro+unknown — metro + unknown
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ph-pipeline-env.sh
source "$ROOT/scripts/ph-pipeline-env.sh"
source "$ROOT/scripts/dev-path.sh"
cd "$ROOT"
export PH_PIPELINE_DIR

SCOPE="${IMPORT_SCOPE:-metro}"
export IMPORT_SCOPE="$SCOPE"
case "$SCOPE" in
  metro)        SRC="$PH_PIPELINE_DIR/ph-slugs-metro.json" ;;
  all|deduped)  SRC="$PH_PIPELINE_DIR/ph-all-links-raw.json" ;;
  raw)          SRC="$PH_PIPELINE_DIR/ph-all-links-raw.json" ;;
  unknown)      SRC="$PH_PIPELINE_DIR/ph-slugs-unknown.json" ;;
  metro+unknown)
    PH_PIPELINE_DIR="$PH_PIPELINE_DIR" python3 << PY
import json, os
from pathlib import Path
d = Path(os.environ["PH_PIPELINE_DIR"])
metro = json.loads((d / "ph-slugs-metro.json").read_text()) if (d / "ph-slugs-metro.json").exists() else {"slugs":[]}
unk = json.loads((d / "ph-slugs-unknown.json").read_text()) if (d / "ph-slugs-unknown.json").exists() else {"slugs":[]}
slugs = sorted(set(metro.get("slugs",[]) + unk.get("slugs",[])))
(d / "ph-slugs-import.json").write_text(json.dumps({"count":len(slugs),"slugs":slugs}, ensure_ascii=False))
print(len(slugs))
PY
    SRC="$PH_PIPELINE_DIR/ph-slugs-import.json"
    ;;
  *)
    echo "❌ IMPORT_SCOPE ไม่รู้จัก: $SCOPE"
    exit 1
    ;;
esac

if [[ ! -f "$SRC" ]]; then
  echo "❌ ไม่พบ $SRC — รัน filter-collected-slugs.py ก่อน (หรือ collect-all)"
  exit 1
fi

cp "$SRC" /tmp/ph-discover.json
COUNT=$(python3 -c "import json; print(len(json.load(open('/tmp/ph-discover.json')).get('slugs',[])))")
echo "=== เฟส 3: ดึงรายละเอียด ($SCOPE) — $COUNT โครงการ ==="

SKIP_DISCOVER=1 IMPORT_SCOPE="$SCOPE" BATCH_SIZE="${BATCH_SIZE:-20}" MAX_BATCHES="${MAX_BATCHES:-0}" \
  bash "$ROOT/scripts/sync-propertyhub-cloud.sh"

echo "✅ import เสร็จ — เฉพาะกทม.+ปริมณฑล (IMPORT_SCOPE=metro)"
