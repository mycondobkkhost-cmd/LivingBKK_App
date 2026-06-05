#!/usr/bin/env bash
# ตรวจว่าพร้อม deploy / รันแอป (ไม่แทนทดสอบ E2E)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ok=0
warn=0

check() {
  if eval "$2" >/dev/null 2>&1; then
    echo "✅ $1"
    ok=$((ok + 1))
  else
    echo "⚠️  $1"
    warn=$((warn + 1))
  fi
}

echo "=== PROPPITER / LivingBKK_App verify-ready ==="
echo ""

check ".env.local" "test -f .env.local"
check "mobile/assets/env" "test -f mobile/assets/env"
check "supabase CLI" "command -v supabase"
check "flutter" "command -v flutter"
MIG_COUNT="$(ls -1 supabase/migrations/*.sql 2>/dev/null | wc -l | tr -d ' ')"
echo "ℹ️  migrations: ${MIG_COUNT} ไฟล์ (เป้า 45+)"
check "migrations (40+)" "test \"${MIG_COUNT:-0}\" -ge 40"

if [[ -f .env.local ]]; then
  # shellcheck disable=SC1090
  source .env.local
  [[ -n "${SUPABASE_URL:-}" ]] && echo "✅ SUPABASE_URL ตั้งแล้ว" || echo "⚠️  SUPABASE_URL ว่าง"
  [[ -n "${SUPABASE_ANON_KEY:-}" ]] && echo "✅ SUPABASE_ANON_KEY ตั้งแล้ว" || echo "⚠️  SUPABASE_ANON_KEY ว่าง"
  [[ -n "${OPENAI_API_KEY:-}" ]] && echo "✅ OPENAI_API_KEY (Phase 12 AI)" || echo "ℹ️  OPENAI_API_KEY ว่าง — ใช้ rule-based search"
  if [[ -n "${FIREBASE_PROJECT_ID:-}" ]]; then
    echo "✅ FIREBASE_* (Phase 15 push)"
  else
    echo "ℹ️  FIREBASE_* ว่าง — push ใช้ Realtime ในแอป"
  fi
  if [[ -f mobile/android/app/google-services.json ]]; then
    echo "✅ google-services.json"
  else
    echo "ℹ️  ไม่มี google-services.json — รัน flutterfire configure ก่อน Store"
  fi
fi

echo ""
echo "Edge functions ในโปรเจกต์:"
ls -1 supabase/functions/*/index.ts 2>/dev/null | sed 's|supabase/functions/||;s|/index.ts||' | sed 's/^/  · /'

echo ""
echo "สรุป: ✅ $ok ผ่าน · ⚠️ $warn ควรแก้"
echo "Deploy: ./scripts/deploy-all.sh"
echo "รายการเหลือ: docs/ROADMAP-REMAINING.md"
echo "ก่อน push: docs/PRE-PUSH-STATUS.md"
