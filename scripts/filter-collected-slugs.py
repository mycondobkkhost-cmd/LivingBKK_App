#!/usr/bin/env python3
"""
เฟส 2 — คัดกรอง slug หลัง collect-all

1. ตัด slug ซ้ำ
2. เก็บเฉพาะ กทม.+ปริมณฑล (metro) สำหรับ import

อ่าน ph-all-links-raw.json (หรือ ph-metro-slugs.json)
เขียน:
  - ph-slugs-metro.json      — กทม.+ปริมณฑล ไม่ซ้ำ (import หลัก)
  - ph-slugs-import.json     — สำเนา metro สำหรับ sync
  - ph-slugs-unknown.json    — ไม่มีที่อยู่ (เก็บไว้ ไม่ import อัตโนมัติ)
  - ph-slugs-excluded.json   — นอกปริมณฑล (ไม่ import)
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PIPELINE_DIR = Path(os.environ.get("PH_PIPELINE_DIR", "/tmp"))
RAW = PIPELINE_DIR / "ph-all-links-raw.json"
FALLBACK = PIPELINE_DIR / "ph-metro-slugs.json"
OUT_DIR = PIPELINE_DIR

EXCLUDED = [
    "chiang mai", "เชียงใหม่", "phuket", "ภูเก็ต", "pattaya", "พัทยา",
    "chonburi", "ชลบุรี", "rayong", "ระยอง", "khon kaen", "ขอนแก่น",
    "hat yai", "หาดใหญ่", "songkhla", "สงขลา", "udon", "อุดร",
    "nakhon ratchasima", "โคราช", "surat thani", "สุราษฎร์",
]

METRO = [
    "bangkok", "กรุงเทพ", "นนทบุรี", "nonthaburi", "ปทุมธานี", "pathum",
    "pathumthani", "สมุทรปราการ", "samut prakan", "samutprakan",
    "สมุทรสาคร", "samut sakhon", "นครปฐม", "nakhon pathom",
    "บางใหญ่", "บางบัวทอง", "บางกรวย", "รังสิต", "คลองหลวง",
    "บางพลี", "พระประแดง", "เมืองนนทบุรี", "เมืองปทุมธานี",
]


def classify(address: str) -> str:
    if not address or not address.strip():
        return "unknown"
    hay = address.lower()
    for bad in EXCLUDED:
        if bad in hay:
            return "excluded"
    if any(k in hay for k in METRO):
        return "metro"
    return "excluded"


def merge_row(existing: dict, incoming: dict) -> dict:
    out = dict(existing)
    for key in ("name", "name_en", "address"):
        if not out.get(key) and incoming.get(key):
            out[key] = incoming[key]
    src = set(out.get("sources") or [])
    src.update(incoming.get("sources") or [])
    out["sources"] = sorted(src)
    return out


def main() -> int:
    src = RAW if RAW.exists() else FALLBACK
    if not src.exists():
        print(f"❌ ไม่พบ {RAW} หรือ {FALLBACK} — รัน collect-all-project-links.sh ก่อน", file=sys.stderr)
        return 1

    data = json.loads(src.read_text(encoding="utf-8"))
    projects = data.get("projects") or []
    if not projects and data.get("slugs"):
        projects = [{"slug": s, "address": ""} for s in data["slugs"]]

    unique: dict[str, dict] = {}
    dup_count = 0

    for p in projects:
        slug = (p.get("slug") or "").strip()
        if not slug:
            continue
        row = {
            "slug": slug,
            "name": p.get("name", ""),
            "name_en": p.get("name_en", ""),
            "address": p.get("address", ""),
            "sources": p.get("sources") or [],
        }
        if slug in unique:
            dup_count += 1
            unique[slug] = merge_row(unique[slug], row)
        else:
            unique[slug] = row

    metro: list[dict] = []
    excluded: list[dict] = []
    unknown: list[dict] = []

    for row in sorted(unique.values(), key=lambda r: r["slug"]):
        bucket = classify(row.get("address") or "")
        row = {**row, "bucket": bucket}
        if bucket == "metro":
            metro.append(row)
        elif bucket == "unknown":
            unknown.append(row)
        else:
            excluded.append(row)

    def write(name: str, rows: list[dict]) -> None:
        slugs = [r["slug"] for r in rows]
        out = OUT_DIR / name
        out.write_text(
            json.dumps(
                {"count": len(slugs), "slugs": slugs, "projects": rows, "filter": "dedupe_metro"},
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )
        print(f"  {out.name}: {len(slugs)}")

    print(
        f"=== เฟส 2: ตัดซ้ำ + กรองปริมณฑลจาก {src.name} "
        f"({len(projects)} แถวดิบ → {len(unique)} slug ไม่ซ้ำ, ซ้ำรวม {dup_count}) ==="
    )
    write("ph-slugs-metro.json", metro)
    write("ph-slugs-import.json", metro)
    write("ph-slugs-unknown.json", unknown)
    write("ph-slugs-excluded.json", excluded)

    legacy = OUT_DIR / "ph-all-slugs.json"
    legacy.write_text(
        json.dumps({"count": len(metro), "slugs": [r["slug"] for r in metro]}, ensure_ascii=False),
        encoding="utf-8",
    )
    print(f"  ph-all-slugs.json: {len(metro)}")

    print(
        f"\n✅ กรองแล้ว — metro {len(metro)} · unknown {len(unknown)} · excluded {len(excluded)}"
    )
    print("   ถัดไป: IMPORT_SCOPE=metro ./scripts/import-collected-projects.sh")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
