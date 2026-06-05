#!/usr/bin/env bash
# รัน Supabase login + link + db push (ไม่ต้องพิมพ์ supabase เอง)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
cd "$ROOT"

echo "=== supabase login (เปิดเบราว์เซอร์ให้ล็อกอิน) ==="
supabase login

echo "=== supabase link ==="
supabase link --project-ref auflqgqrmpbioflnhsrj

echo "=== supabase db push (อัปโหลดตาราง) ==="
supabase db push

echo "✅ เสร็จ — ต่อไปรันแอป: source scripts/dev-path.sh && cd mobile && flutter run -d chrome --web-port=8082"
