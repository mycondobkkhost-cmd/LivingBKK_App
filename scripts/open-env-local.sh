#!/usr/bin/env bash
# เปิดไฟล์ใส่รหัส (เห็นใน Finder ได้ ไม่ซ่อน)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VISIBLE="$ROOT/ใส่รหัส-database-ตรงนี้.env"

if [[ ! -f "$VISIBLE" ]]; then
  echo "❌ ไม่พบ $VISIBLE"
  exit 1
fi

echo ""
echo "เปิดไฟล์นี้ (ในโฟลเดอร์ LivingBKK_App):"
echo "  ใส่รหัส-database-ตรงนี้.env"
echo ""
echo "ใส่รหัสหลัง SUPABASE_DB_PASSWORD= แล้ว Save (Cmd+S)"
echo ""

open -R "$VISIBLE"
open -e "$VISIBLE"
open "https://supabase.com/dashboard/project/auflqgqrmpbioflnhsrj/settings/database"
