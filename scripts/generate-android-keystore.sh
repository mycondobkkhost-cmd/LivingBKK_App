#!/usr/bin/env bash
# สร้าง keystore Android สำหรับ Play Store (ฟรี — ไม่ต้องสมัคร Play Console)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT/mobile/android"
KEYSTORE="$ANDROID_DIR/upload-keystore.jks"
PROPS="$ANDROID_DIR/key.properties"
ALIAS="${KEY_ALIAS:-upload}"
VALIDITY="${KEY_VALIDITY_DAYS:-10000}"

if [[ -f "$KEYSTORE" ]]; then
  echo "มี keystore อยู่แล้ว: $KEYSTORE"
  echo "ถ้าต้องการสร้างใหม่ ลบไฟล์นี้ก่อน"
  exit 0
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "ไม่พบ keytool — ติดตั้ง JDK ก่อน (มากับ Android Studio)"
  exit 1
fi

echo "=== สร้าง Android upload keystore ==="
echo "ไฟล์: $KEYSTORE"
echo "alias: $ALIAS"
echo ""
echo "keytool จะถามรหัสผ่านและข้อมูลองค์กร — จำรหัสให้ดี (ใช้ตลอดชีวิตแอป)"
echo ""

keytool -genkey -v \
  -keystore "$KEYSTORE" \
  -keyalg RSA \
  -keysize 2048 \
  -validity "$VALIDITY" \
  -alias "$ALIAS"

read -r -s -p "ใส่ storePassword อีกครั้งสำหรับ key.properties: " STORE_PW
echo ""
read -r -s -p "ใส่ keyPassword (กด Enter ถ้าเท่ากับ store): " KEY_PW
echo ""
KEY_PW="${KEY_PW:-$STORE_PW}"

cat > "$PROPS" <<EOF
storePassword=$STORE_PW
keyPassword=$KEY_PW
keyAlias=$ALIAS
storeFile=$KEYSTORE
EOF

chmod 600 "$PROPS" 2>/dev/null || true

echo ""
echo "✅ สร้างแล้ว:"
echo "   $KEYSTORE"
echo "   $PROPS"
echo ""
echo "อย่า commit ไฟล์เหล่านี้ (อยู่ใน .gitignore แล้ว)"
echo "ทดสอบ build: ./scripts/build-android.sh aab"
