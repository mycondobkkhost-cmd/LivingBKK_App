#!/usr/bin/env bash
# เปิดหน้า Google Cloud ที่ต้องตั้ง + sync key ในแอป (macOS)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="${GCP_PROJECT:-livingbkk}"

echo "=== RealXtate — ตั้ง Google Maps Web ==="
echo ""

"$ROOT/scripts/sync-env.sh"

echo ""
echo "→ เปิด Chrome/Safari ไปหน้าที่ต้องตั้ง (โปรเจกต: $PROJECT)"
echo ""

if command -v open >/dev/null 2>&1; then
  # 1) เปิด Maps JavaScript API
  open "https://console.cloud.google.com/marketplace/product/google/maps-backend.googleapis.com?project=${PROJECT}"
  sleep 1
  # 2) หน้า API key
  open "https://console.cloud.google.com/google/maps-apis/credentials?project=${PROJECT}"
else
  echo "เปิดลิงก์เอง:"
  echo "  https://console.cloud.google.com/marketplace/product/google/maps-backend.googleapis.com?project=${PROJECT}"
  echo "  https://console.cloud.google.com/google/maps-apis/credentials?project=${PROJECT}"
fi

cat <<'EOF'

────────────────────────────────────────
  ทำ 2 คลิกใน Chrome (ทำตามลำดับ)
────────────────────────────────────────

【แท็บ 1】Maps JavaScript API
  → กดปุ่ม ENABLE (เปิดใช้งาน)

【แท็บ 2】Keys & Credentials
  → คลิกชื่อ "Maps Platform API Key" (แถวในตาราง API Keys)
  → หน้า Edit API key:
     · Application restrictions → เลือก "None" (ไม่จำกัด — ใช้ dev)
       หรือถ้าอยากจำกัด: เลือก HTTP referrers แล้ว Add:
         http://127.0.0.1:7357/*
         http://localhost:7357/*
     · กด SAVE ด้านล่าง

────────────────────────────────────────
  กลับมาแอป RealXtate
────────────────────────────────────────
  Refresh แท็บ http://127.0.0.1:7357/ (Cmd+Shift+R)

  ตรวจ key:
    ./scripts/verify-google-maps-key.sh

EOF
