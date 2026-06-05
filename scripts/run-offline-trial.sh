#!/bin/bash
# เปิดแอปโหมดทดลอง — ไม่ต้องล็อกอิน Supabase (TRIAL_MODE ชั่วคราว)
set -e
ROOT="$(dirname "$0")/.."
ENV_FILE="$ROOT/mobile/assets/env"
BACKUP="$ENV_FILE.bak.offline-run"
source "$(dirname "$0")/dev-path.sh"

restore_env() {
  if [[ -f "$BACKUP" ]]; then
    mv "$BACKUP" "$ENV_FILE"
  fi
}
trap restore_env EXIT INT TERM

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ไม่พบ $ENV_FILE"
  exit 1
fi

cp "$ENV_FILE" "$BACKUP"
if grep -q '^TRIAL_MODE=' "$ENV_FILE"; then
  sed -i '' 's/^TRIAL_MODE=.*/TRIAL_MODE=true/' "$ENV_FILE"
else
  echo 'TRIAL_MODE=true' >> "$ENV_FILE"
fi

echo "→ TRIAL_MODE=true (ชั่วคราว) — ปิดแอปแล้วคืนค่า env เดิม"
echo "→ เข้าทดลอง: ฉัน → เข้าสู่ระบบ → เข้าทดลอง (ไม่ต้องรหัส)"
echo ""

cd "$ROOT/mobile"
flutter pub get
flutter run -d chrome
