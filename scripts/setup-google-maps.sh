#!/usr/bin/env bash
# ใส่ Google Maps API key แล้ว sync ไปแอป (Web + Android + iOS)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_LOCAL="$ROOT/.env.local"

if [[ ! -f "$ENV_LOCAL" ]]; then
  cp "$ROOT/.env.local.example" "$ENV_LOCAL"
  echo "สร้าง $ENV_LOCAL แล้ว — ใส่คีย์ด้านล่าง"
fi

if [[ -n "${1:-}" ]]; then
  KEY="$1"
else
  echo "Google Maps API key (จาก console.cloud.google.com):"
  echo "  เปิด API: Maps JavaScript API, Places API, Maps SDK for Android/iOS"
  read -r -p "GOOGLE_MAPS_API_KEY= " KEY
fi

if [[ -z "$KEY" ]] || [[ "$KEY" == *your_* ]] || [[ "$KEY" == *YOUR_* ]]; then
  echo "❌ ไม่ได้ใส่คีย์ — ยกเลิก"
  exit 1
fi

if grep -q '^GOOGLE_MAPS_API_KEY=' "$ENV_LOCAL"; then
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i "s|^GOOGLE_MAPS_API_KEY=.*|GOOGLE_MAPS_API_KEY=${KEY}|" "$ENV_LOCAL"
  else
    sed -i '' "s|^GOOGLE_MAPS_API_KEY=.*|GOOGLE_MAPS_API_KEY=${KEY}|" "$ENV_LOCAL"
  fi
else
  echo "GOOGLE_MAPS_API_KEY=${KEY}" >> "$ENV_LOCAL"
fi

"$ROOT/scripts/sync-env.sh"
echo ""
echo "✅ พร้อมแล้ว — รันแอปใหม่:"
echo "   ./scripts/run-app.sh"
