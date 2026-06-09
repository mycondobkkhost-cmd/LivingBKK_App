#!/usr/bin/env bash
# เตรียมขึ้น Store แบบฟรี (ไม่รวมสมัคร Developer / Firebase)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== PROPPITER — prepare store (free) ==="
echo ""

if [[ ! -f .env.local ]]; then
  echo "⚠️  ไม่พบ .env.local — ใช้ .env.local.example เป็นต้นแบบ"
else
  echo "→ sync env"
  "$ROOT/scripts/sync-env.sh"
fi

echo ""
echo "→ verify free store prep"
chmod +x "$ROOT/scripts/verify-store-free.sh" 2>/dev/null || true
"$ROOT/scripts/verify-store-free.sh" || true

echo ""
echo "ขั้นถัดไป (ฟรี):"
echo "  1. ./scripts/deploy-all.sh          # deploy delete-account"
echo "  2. ./scripts/generate-android-keystore.sh   # ถ้ายังไม่มี signing"
echo "  3. ./scripts/build-android.sh apk   # ทดสอบบนมือถือ"
echo "  4. อ่าน docs/STORE-FREE-PREP.md + store-listing/"
echo ""
echo "เมื่อพร้อมสมัครร้าน: docs/STORE-SUBMISSION-CHECKLIST.md"
