#!/usr/bin/env python3
"""เทียบ slug metro กับ Cloud → บันทึก ph-slugs-missing.json"""
from __future__ import annotations

import json
import os
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PIPELINE = Path(os.environ.get("PH_PIPELINE_DIR", ROOT / "data/ph-pipeline"))


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    for path in (ROOT / ".env.local", ROOT / "mobile/assets/env"):
        if not path.exists():
            continue
        for line in path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env.setdefault(k.strip(), v.strip())
    return env


def fetch_cloud_slugs(base: str, anon: str) -> set[str]:
    """เฉพาะคอลัมน์ slug — aliases เป็นชื่อแสดง ไม่ใช่ PH slug"""
    headers = {"apikey": anon, "Authorization": f"Bearer {anon}"}
    slugs: set[str] = set()
    offset = 0
    while True:
        url = (
            f"{base}/rest/v1/property_projects"
            f"?select=slug,is_active&is_active=eq.true&order=slug&offset={offset}&limit=1000"
        )
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=120) as resp:
            rows = json.loads(resp.read())
        if not rows:
            break
        for row in rows:
            slug = (row.get("slug") or "").strip()
            if slug:
                slugs.add(slug)
        if len(rows) < 1000:
            break
        offset += 1000
    return slugs


def main() -> int:
    env = load_env()
    base = env.get("SUPABASE_URL", "https://auflqgqrmpbioflnhsrj.supabase.co")
    anon = env.get("SUPABASE_ANON_KEY", "")
    if not anon:
        print("❌ ไม่พบ SUPABASE_ANON_KEY")
        return 1

    metro_path = PIPELINE / "ph-slugs-metro.json"
    if not metro_path.exists():
        print(f"❌ ไม่พบ {metro_path}")
        return 1

    metro = json.loads(metro_path.read_text()).get("slugs", [])
    metro_set = set(metro)
    cloud = fetch_cloud_slugs(base, anon)

    still_failed_path = PIPELINE / "ph-slugs-still-failed.json"
    still_failed: set[str] = set()
    if still_failed_path.exists():
        still_failed = set(json.loads(still_failed_path.read_text()).get("slugs", []))

    missing = sorted(metro_set - cloud - still_failed)
    out = {"count": len(missing), "slugs": missing}
    out_path = PIPELINE / "ph-slugs-missing.json"
    out_path.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"metro slugs: {len(metro_set)}")
    print(f"cloud projects (unique slug): {len(cloud)}")
    print(f"still_failed (skip): {len(still_failed)}")
    print(f"missing to import: {len(missing)}")
    print(f"→ {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
