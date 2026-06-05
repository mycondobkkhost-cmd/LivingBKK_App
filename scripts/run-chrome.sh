#!/bin/bash
# Run LivingBKK in Chrome (works without Xcode on macOS 12)
set -e
source "$(dirname "$0")/dev-path.sh"
cd "$(dirname "$0")/../mobile"
flutter pub get
flutter run -d chrome
