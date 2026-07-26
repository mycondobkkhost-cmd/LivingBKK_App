#!/usr/bin/env bash
# อ่าน OPENAI_API_KEY จาก .env.local → ตั้ง Supabase Edge secrets
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
ENV_LOCAL="$ROOT/.env.local"

if [[ ! -f "$ENV_LOCAL" ]]; then
  echo "❌ ไม่พบ .env.local — คัดลอกจาก .env.local.example แล้วใส่ OPENAI_API_KEY"
  exit 1
fi

# shellcheck disable=SC1090
set -a
source "$ENV_LOCAL"
set +a

if [[ -z "${OPENAI_API_KEY:-}" ]] || [[ "$OPENAI_API_KEY" == *"YOUR_"* ]]; then
  echo "❌ ใส่ OPENAI_API_KEY=sk-... ใน .env.local ก่อน"
  exit 1
fi

supabase secrets set \
  OPENAI_API_KEY="$OPENAI_API_KEY" \
  OPENAI_MODEL="${OPENAI_MODEL:-gpt-4o-mini}"

echo "✅ ตั้ง OPENAI secrets บน Supabase แล้ว (model: ${OPENAI_MODEL:-gpt-4o-mini})"
