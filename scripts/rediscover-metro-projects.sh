#!/usr/bin/env bash
# แผนเต็ม: ค้นหาโครงการ กทม.+ปริมณฑล → ปิดของนอกพื้นที่ → ดึงรายละเอียดขึ้น Cloud
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=============================================="
echo "  โครงการ กทม.+ปริมณฑล เท่านั้น"
echo "  1) ค้นหาชื่อ v2 (ชั้น A-E: JSON + ค้นหาตัวอักษร)"
echo "  2) ปิดโครงการนอกพื้นที่ในคลาวด์"
echo "  3) ดึงรายละเอียดทีละชุด"
echo "=============================================="
echo ""

echo "=== ขั้น 1: ค้นหาโครงการ v2 (กทม.+ปริมณฑล) ==="
echo "   ใช้เวลา 2–8 ชม. ถ้าไล่ครบทุกเขต — ดู docs/คู่มือ-Property-Hub-เว็บเดียว.md"
python3 "$ROOT/scripts/discover-metro-projects-v2.py"
echo ""

echo "=== ขั้น 2: ปิดโครงการนอกพื้นที่ (ต้อง deploy function ล่าสุด) ==="
"$ROOT/scripts/purge-non-metro-projects.sh" || echo "⚠️ ข้าม purge ถ้า function ยังไม่ deploy"
echo ""

echo "=== ขั้น 3: สมุดแสดงผลดรอปดาวน์ (ค้นตามตัวอักษร) ==="
echo "   เก็บครบก่อน — แอปโหลดจาก mobile/assets/data/search_display_index.json"
python3 "$ROOT/scripts/discover-search-display-index.py"
echo ""

echo "=== ขั้น 4: sync รายละเอียดขึ้น Cloud ==="
SKIP_DISCOVER=1 "$ROOT/scripts/sync-propertyhub-cloud.sh"
