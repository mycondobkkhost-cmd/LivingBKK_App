# โฟลเดอร์เก็บ progress pipeline (ไม่หายเมื่อ /tmp ถูกล้าง)
#   source scripts/ph-pipeline-env.sh
if [[ -n "${BASH_VERSION:-}" ]]; then
  _PH_ENV_SELF="${BASH_SOURCE[0]}"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  _PH_ENV_SELF="${(%):-%x}"
else
  _PH_ENV_SELF="$0"
fi
ROOT="$(cd "$(dirname "$_PH_ENV_SELF")/.." && pwd)"
unset _PH_ENV_SELF
export PH_PIPELINE_DIR="${PH_PIPELINE_DIR:-$ROOT/data/ph-pipeline}"
mkdir -p "$PH_PIPELINE_DIR"
export PH_PIPELINE_DIR
