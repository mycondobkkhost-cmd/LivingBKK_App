#!/bin/bash
export PATH="/Users/angkarn1996/development/flutter/bin:$PATH"
lsof -tiTCP:7357 -sTCP:LISTEN 2>/dev/null | xargs kill -9 2>/dev/null || true
sleep 1
cd /Users/angkarn1996/Desktop/LivingBKK_App/mobile || exit 1
exec flutter run -d web-server --web-hostname=127.0.0.1 --web-port=7357 --no-dds
