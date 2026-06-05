#!/usr/bin/env bash
# ตั้งค่า LivingBKK ครั้งเดียว: .env.local → แอป + (ถ้า link แล้ว) Supabase db push
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=/dev/null
[[ -f "$ROOT/scripts/dev-path.sh" ]] && source "$ROOT/scripts/dev-path.sh"

ENV_LOCAL="$ROOT/.env.local"
EXAMPLE="$ROOT/.env.local.example"

echo "=== LivingBKK — ตั้งค่าครบชุด ==="

if [[ ! -f "$ENV_LOCAL" ]]; then
  echo ""
  echo "ยังไม่มี .env.local"
  if [[ -f "$EXAMPLE" ]]; then
    cp "$EXAMPLE" "$ENV_LOCAL"
    echo "สร้าง $ENV_LOCAL จากตัวอย่างแล้ว"
  fi
  echo ""
  echo "ใส่ค่า 3 อย่างนี้ใน .env.local:"
  echo "  1) SUPABASE_URL + SUPABASE_ANON_KEY"
  echo "     → https://supabase.com/dashboard → โปรเจกต์ → Settings → API"
  echo "  2) GOOGLE_MAPS_API_KEY"
  echo "     → https://console.cloud.google.com → APIs: Maps JavaScript + Places"
  echo "     → HTTP referrer: http://localhost:* และ http://127.0.0.1:*"
  echo ""
  read -r -p "กด Enter หลังแก้ .env.local เสร็จ..." _
fi

"$ROOT/scripts/sync-env.sh"

# Supabase backend (ต้อง login + link ก่อน — ไม่ใช้ Docker local บนเครื่องนี้ได้)
if command -v supabase >/dev/null 2>&1; then
  if [[ -d "$ROOT/.supabase" ]] || [[ -f "$ROOT/supabase/.temp/project-ref" ]]; then
    echo ""
    echo "=== Supabase: db push (migrations) ==="
    if supabase db push 2>/dev/null; then
      echo "✅ migrations สำเร็จ"
      echo "ℹ️  Seed ทรัพย์: Dashboard → SQL Editor → รัน supabase/seed_listings.sql"
      echo "   (หรือ supabase db reset บนเครื่องที่มี Docker)"
    else
      echo "⚠️  db push ไม่สำเร็จ — รันเอง: supabase login && supabase link --project-ref YOUR_REF && supabase db push"
    fi
  else
    echo ""
    echo "ℹ️  ยังไม่ link Supabase CLI — ข้าม db push"
    echo "   supabase login"
    echo "   supabase link --project-ref YOUR_PROJECT_REF"
    echo "   supabase db push"
    echo "   Dashboard → Authentication → Email → ปิด Confirm email (ทดสอบ)"
    echo "   ตั้ง profiles.role = admin สำหรับบัญชีของคุณ (ถ้าต้องการ Admin)"
  fi
else
  echo "⚠️  ไม่พบ supabase CLI — ข้าม db push"
fi

echo ""
echo "=== Flutter ==="
cd "$ROOT/mobile"
flutter pub get

PORT="${FLUTTER_WEB_PORT:-8082}"
echo ""
echo "✅ พร้อมรัน: flutter run -d chrome --web-port=$PORT"
echo "   Demo login (หลัง seed): demo-owner@livingbkk.local / demo12345"
echo ""
read -r -p "รันแอป Chrome ตอนนี้? [y/N] " run_now
if [[ "${run_now,,}" == "y" || "${run_now,,}" == "yes" ]]; then
  flutter run -d chrome --web-port="$PORT"
fi
