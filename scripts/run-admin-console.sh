#!/usr/bin/env bash
# เปิด Admin Console บน Chrome (ตอบแชทบนคอม)
set -e
source "$(dirname "$0")/dev-path.sh"
cd "$(dirname "$0")/../mobile"
flutter pub get
flutter run -d chrome --web-launch-url=http://localhost:8080/admin/console
