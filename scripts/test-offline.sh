#!/bin/bash
# ทดสอบออฟไลน์ — ไม่ต้อง Supabase / เน็ต (unit tests เท่านั้น)
set -e
source "$(dirname "$0")/dev-path.sh"
cd "$(dirname "$0")/../mobile"
flutter pub get
flutter test test/trial_listing_store_test.dart \
  test/listing_create_rules_test.dart \
  test/listing_transaction_types_test.dart \
  test/listing_browse_sorter_test.dart
echo ""
echo "✓ ทดสอบออฟไลน์ผ่าน — flow ลงประกาศ/อนุมัติ (TrialListingStore) + กฎลิงก์แผนที่"
