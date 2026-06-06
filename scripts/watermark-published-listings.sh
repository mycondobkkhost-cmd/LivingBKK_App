#!/usr/bin/env bash
# ใส่ลายน้ำย้อนหลังให้ประกาศที่ publish แล้ว (ต้อง login admin + deploy function ก่อน)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"

LISTING_ID="${1:-}"

if [[ -z "$LISTING_ID" ]]; then
  echo "ใช้: $0 <listing_id>"
  echo "หรือดึงรายการ publish จาก Supabase แล้วเรียกทีละ id"
  exit 1
fi

echo "→ ใส่ลายน้ำ listing_id=$LISTING_ID"
supabase functions invoke listing-watermark-images \
  --body "{\"listing_id\":\"$LISTING_ID\"}"

echo ""
echo "✅ เสร็จ"
