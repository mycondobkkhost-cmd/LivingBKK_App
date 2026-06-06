#!/usr/bin/env bash
# กู้คืนลิงก์จาก backup (เมื่อคอมดับกลางทาง)
#
#   ./scripts/restore-ph-pipeline.sh                  # ใช้ backups/latest.json
#   ./scripts/restore-ph-pipeline.sh path/to.json   # ระบุไฟล์เอง
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ph-pipeline-env.sh
source "$ROOT/scripts/ph-pipeline-env.sh"

SRC="${1:-$PH_PIPELINE_DIR/backups/latest.json}"
if [[ ! -f "$SRC" ]]; then
  echo "❌ ไม่พบ $SRC"
  echo "   ลอง: ls $PH_PIPELINE_DIR/backups/"
  exit 1
fi

python3 << PY
import json, shutil
from pathlib import Path

src = Path("$SRC")
dest = Path("$PH_PIPELINE_DIR")
data = json.loads(src.read_text(encoding="utf-8"))
count = data.get("count", len(data.get("slugs", [])))
for name in ("ph-metro-slugs.json", "ph-all-links-raw.json", "ph-all-slugs.json"):
    shutil.copy2(src, dest / name)
slugs = data.get("slugs") or []
prog_path = dest / "ph-metro-discover-progress.json"
if prog_path.exists():
    done = json.loads(prog_path.read_text(encoding="utf-8")).get("done_seeds") or []
else:
    done = []
(dest / "ph-metro-discover-progress.json").write_text(
    json.dumps({
        "done_seeds": done,
        "project_count": count,
        "restored_from": str(src),
        "saved_at": data.get("saved_at"),
    }, ensure_ascii=False, indent=2),
    encoding="utf-8",
)
print(f"✅ กู้คืน {count} ลิงก์จาก {src}")
print("   ต่อด้วย: ./scripts/resume-ph-pipeline.sh")
PY
