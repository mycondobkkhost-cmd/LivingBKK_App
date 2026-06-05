#!/usr/bin/env bash
# รันแอปให้มือถือเปิดได้ (ฮอตสปอต / Wi‑Fi เดียวกัน)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/dev-path.sh"
"$ROOT/scripts/sync-env.sh" 2>/dev/null || true
cd "$ROOT/mobile"

pick_port() {
  for p in "$@"; do
    if ! lsof -ti ":$p" >/dev/null 2>&1; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

PORT="${1:-$(pick_port 8084 8085 8086 8090 || echo 8084)}"

# หา IP ของ Mac บนเครือข่ายปัจจุบัน
MAC_IP=""
for iface in en0 bridge100 en1; do
  ip="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"
  if [[ -n "$ip" ]]; then
    MAC_IP="$ip"
    break
  fi
done

echo ""
echo "============================================"
echo "  LivingBKK — เปิดให้มือถือทดลอง"
echo "============================================"
echo ""
echo "  บน Mac (เบราว์เซอร์):  http://localhost:$PORT"
if [[ -n "$MAC_IP" ]]; then
  echo "  บนมือถือ Safari/Chrome:  http://$MAC_IP:$PORT"
else
  echo "  บนมือถือ: ดู IP ใน System Settings → Network"
  echo "            แล้วเปิด http://เลข-IP:$PORT"
fi
echo ""
echo "  หยุดแอป: กด q ใน Terminal นี้"
echo "============================================"
echo ""

# web-server = เปิดเซิร์ฟเวอร์ให้เครื่องอื่นเข้าได้ (ไม่เปิด Chrome อย่างเดียว)
flutter run -d web-server --web-hostname=0.0.0.0 --web-port="$PORT"
