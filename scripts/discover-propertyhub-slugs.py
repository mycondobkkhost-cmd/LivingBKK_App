#!/usr/bin/env python3
"""
[เลิกใช้ — ใช้ discover-metro-projects-v2.py แทน]

สคริปต์เก่า: regex HTML, สูงสุด 60 หน้า — ไม่ครอบคลุม
v2 อ่าน __NEXT_DATA__ + ไล่ทุกเขตกรุงเทพ + BTS/MRT + ปริมณฑล
"""
from __future__ import annotations

import json
import re
import sys
import time
import urllib.request
from pathlib import Path

UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"
ROOT = Path(__file__).resolve().parents[1]
OUT = Path("/tmp/ph-all-slugs.json")

# กทม.+ปริมณฑล เท่านั้น (ห้ามเพิ่มจังหวัดอื่น)
METRO_PROVINCES = [
    "bangkok",
    "nonthaburi",
    "pathum-thani",
    "samut-prakan",
    "samut-sakhon",
    "nakhon-pathom",
]

LISTING_TYPES = [
    "condo-for-rent",
    "condo-for-sale",
    "house-for-rent",
    "house-for-sale",
    "townhouse-for-rent",
    "townhouse-for-sale",
]

BTS_ZONES = [
    "asok", "phrom-phong", "thonglor", "ekkamai", "on-nut", "bang-chak", "bearing",
    "udom-suk", "bang-na", "samrong", "ari", "sanam-pao", "phaya-thai",
    "victory-monument", "siam", "chit-lom", "ploenchit", "nana", "rama-9",
    "huai-khwang", "sutthisan", "lat-phrao", "phra-khanong",
    "wutthakat", "talat-phlu", "bang-wa", "saphan-taksin", "surasak",
    "saphan-khwai", "mo-chit", "makkasan", "phetchaburi", "silom", "lumphini",
    "sam-yan", "wat-mangkon", "sam-yot", "sanam-chai", "ratchathewi",
    "national-stadium", "ratchadamri", "khlong-toei",
]

LISTING_SUFFIXES = [
    (suffix, METRO_PROVINCES)
    for suffix in LISTING_TYPES
] + [
    ("condo-for-rent", [f"bts-{z}" for z in BTS_ZONES]),
    ("condo-for-sale", [f"bts-{z}" for z in BTS_ZONES]),
]

EXTRA_PAGES = [
    "/en/new-projects",
    "/en/condo-for-rent/bangkok",
    "/en/condo-for-sale/bangkok",
    "/en/condo-for-rent/nonthaburi",
    "/en/condo-for-rent/pathum-thani",
    "/en/condo-for-rent/samut-prakan",
]


def is_valid_slug(slug: str) -> bool:
    if len(slug) < 3 or len(slug) > 72:
        return False
    if slug.startswith("-") or slug.endswith("-"):
        return False
    if "---" in slug or "for-sale" in slug or "for-rent" in slug:
        return False
    if not re.match(r"^[a-z0-9][a-z0-9-]*[a-z0-9]$", slug):
        return False
    if re.match(r"^--?\d{5,}", slug):
        return False
    return True


def fetch(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "th-TH,th;q=0.9"})
    with urllib.request.urlopen(req, timeout=45) as res:
        return res.read().decode("utf-8", errors="ignore")


def slugs_from_html(html: str) -> set[str]:
    found = set(re.findall(r"/projects/([a-z0-9-]+)", html))
    found |= set(re.findall(r"project-([a-z0-9-]+)", html))
    return {s for s in found if is_valid_slug(s)}


def crawl_paginated(base_path: str, max_pages: int = 60) -> set[str]:
    all_slugs: set[str] = set()
    stale = 0
    for page in range(1, max_pages + 1):
        path = base_path if page == 1 else f"{base_path}?page={page}"
        url = f"https://propertyhub.in.th{path}"
        try:
            html = fetch(url)
        except Exception as e:
            print(f"  skip {path}: {e}", file=sys.stderr)
            break
        batch = slugs_from_html(html)
        new = len(batch - all_slugs)
        all_slugs |= batch
        if new == 0:
            stale += 1
            if stale >= 3:
                break
        else:
            stale = 0
        time.sleep(0.15)
    return all_slugs


def main() -> int:
    grand: set[str] = set()

    for suffix, areas in LISTING_SUFFIXES:
        for area in areas:
            path = f"/en/{suffix}/{area}"
            found = crawl_paginated(path)
            grand |= found
            print(f"{path}: +{len(found)} (รวม {len(grand)})", flush=True)

    for path in EXTRA_PAGES:
        try:
            html = fetch(f"https://propertyhub.in.th{path}")
            batch = slugs_from_html(html)
            grand |= batch
            print(f"{path}: +{len(batch)} (รวม {len(grand)})", flush=True)
        except Exception as e:
            print(f"skip {path}: {e}", file=sys.stderr)
        time.sleep(0.15)

    slugs = sorted(grand)
    OUT.write_text(json.dumps({"count": len(slugs), "slugs": slugs}, ensure_ascii=False), encoding="utf-8")
    print(f"\n✅ พบ {len(slugs)} โครงการ → {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
