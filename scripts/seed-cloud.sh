#!/usr/bin/env bash
# ใส่ทรัพย์ตัวอย่าง + demo owner บน Supabase Cloud (หลัง db push)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
cd "$ROOT"

echo "=== LivingBKK — Seed Cloud ==="

if ! command -v supabase >/dev/null 2>&1; then
  echo "❌ ไม่พบ supabase CLI"
  exit 1
fi

if [[ ! -f "$ROOT/supabase/seed_listings.sql" ]]; then
  echo "สร้าง seed SQL ก่อน:"
  echo "  dart run tool/generate_seed_listings.dart"
  exit 1
fi

echo ""
echo "รัน seed ผ่าน Supabase (ต้อง link โปรเจกต์แล้ว)..."
echo ""

if supabase db execute --file "$ROOT/supabase/seed.sql" 2>/dev/null; then
  echo "✅ seed.sql"
else
  echo "⚠️  seed.sql — รันใน Dashboard → SQL Editor ถ้า CLI ไม่รองรับ db execute"
fi

if supabase db execute --file "$ROOT/supabase/seed_listings.sql" 2>/dev/null; then
  echo "✅ seed_listings.sql"
else
  echo ""
  echo "วิธีสำรอง:"
  echo "  1) เปิด https://supabase.com/dashboard → โปรเจกต์ → SQL Editor"
  echo "  2) วางเนื้อหา supabase/seed.sql แล้ว Run"
  echo "  3) วางเนื้อหา supabase/seed_listings.sql แล้ว Run"
  echo ""
  echo "Demo login:"
  echo "  demo-owner@livingbkk.local / demo12345"
fi

echo ""
echo "ตั้ง admin (แทนที่อีเมลของคุณ):"
echo "  UPDATE profiles SET role = 'admin' WHERE id = (SELECT id FROM auth.users WHERE email = 'YOUR@EMAIL');"
