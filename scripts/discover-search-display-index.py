#!/usr/bin/env python3
"""
เก็บ「การแสดงผลตามตัวอักษร」จาก Property Hub สำหรับดรอปดาวน์ในแอป

1) Bootstrap — เขตกทม./ปริมณฑล, ทำเลฮิต, BTS/MRT (จับคู่ ห → ห้วยขวาง ฯลฯ)
2) Crawl — หน้าประกาศ ?text={คำค้น} ดึง zone + โครงการจาก __NEXT_DATA__

ผลลัพธ์:
  /tmp/ph-search-display-index.json
  mobile/assets/data/search_display_index.json  (ให้แอปโหลด)

รัน:
  python3 scripts/discover-search-display-index.py
  SMOKE_TEST=1 python3 scripts/discover-search-display-index.py
"""
from __future__ import annotations

import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
OUT_TMP = Path("/tmp/ph-search-display-index.json")
OUT_APP = ROOT / "mobile/assets/data/search_display_index.json"
PROGRESS = Path("/tmp/ph-search-display-progress.json")

UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
)

METRO_PROVINCES = [
    "bangkok", "nonthaburi", "pathum-thani",
    "samut-prakan", "samut-sakhon", "nakhon-pathom",
]

SMOKE_TEST = os.environ.get("SMOKE_TEST", "0") == "1"
RESUME = os.environ.get("RESUME", "1") == "1"
DELAY = float(os.environ.get("DISCOVER_DELAY", "0.1"))
CRAWL_WEB = os.environ.get("CRAWL_WEB", "1") == "1"

# เขตกรุงเทพ + ปริมณฑลหลัก (ชื่อไทย, อังกฤษ, geo slug ในแอป)
LOCATION_SEEDS: list[tuple[str, str, str]] = [
    ("ห้วยขวาง", "Huai Khwang", "huai-khwang"),
    ("วัฒนา", "Watthana", "thonglor"),
    ("จตุจักร", "Chatuchak", "chatuchak"),
    ("บางนา", "Bang Na", "bangna"),
    ("ลาดพร้าว", "Lat Phrao", "ladprao"),
    ("สาทร", "Sathorn", "silom"),
    ("คลองเตย", "Khlong Toei", "asok"),
    ("ราชเทวี", "Ratchathewi", "asok"),
    ("ปทุมวัน", "Pathum Wan", "asok"),
    ("พญาไท", "Phaya Thai", "ari"),
    ("ดินแดง", "Din Daeng", "rama-9"),
    ("บางรัก", "Bang Rak", "silom"),
    ("ยานนาวา", "Yan Nawa", "silom"),
    ("ธนบุรี", "Thon Buri", "silom"),
    ("บางกะปิ", "Bang Kapi", "bangna"),
    ("สวนหลวง", "Suan Luang", "bangna"),
    ("ประเวศ", "Prawet", "bangna"),
    ("ดอนเมือง", "Don Mueang", "ari"),
    ("บางซื่อ", "Bang Sue", "ari"),
    ("พระนคร", "Phra Nakhon", "silom"),
    ("ทองหล่อ", "Thong Lo", "thonglor"),
    ("อโศก", "Asok", "asok"),
    ("สุขุมวิท", "Sukhumvit", "sukhumvit"),
    ("อารีย์", "Ari", "ari"),
    ("สีลม", "Silom", "silom"),
    ("สาทร", "Sathorn", "silom"),
    ("พระราม 9", "Rama 9", "rama-9"),
    ("พระราม 3", "Rama 3", "silom"),
    ("รัชดา", "Ratchada", "rama-9"),
    ("ลาดพร้าว", "Lat Phrao", "ladprao"),
    ("บางใหญ่", "Bang Yai", "nonthaburi"),
    ("เมืองนนทบุรี", "Nonthaburi", "nonthaburi"),
    ("เมืองปทุมธานี", "Pathum Thani", "pathum-thani"),
    ("รังสิต", "Rangsit", "pathum-thani"),
    ("บางพลี", "Bang Phli", "samut-prakan"),
    ("เมืองสมุทรปราการ", "Samut Prakan", "samut-prakan"),
]

BTS_MRT_SEEDS: list[tuple[str, str, str]] = [
    ("BTS อโศก", "BTS Asok", "asok"),
    ("BTS ทองหล่อ", "BTS Thong Lo", "thonglor"),
    ("BTS เอกมัย", "BTS Ekkamai", "thonglor"),
    ("BTS อารีย์", "BTS Ari", "ari"),
    ("BTS บางนา", "BTS Bang Na", "bangna"),
    ("BTS สยาม", "BTS Siam", "asok"),
    ("MRT สุขุมวิท", "MRT Sukhumvit", "asok"),
    ("MRT พระราม 9", "MRT Rama 9", "rama-9"),
    ("MRT ห้วยขวาง", "MRT Huai Khwang", "huai-khwang"),
    ("MRT ลาดพร้าว", "MRT Lat Phrao", "ladprao"),
]


def build_alphabet_queries() -> list[str]:
    queries: list[str] = []
    seen: set[str] = set()

    def add(q: str) -> None:
        q = q.strip()
        if not q or q in seen:
            return
        seen.add(q)
        queries.append(q)

    for c in "abcdefghijklmnopqrstuvwxyz":
        add(c)
    for c in "กขคงจชดตทนบปพฟมยรลวสหอฮ":
        add(c)
    for th in (
        "ไล", "ทร", "นอ", "ไฮ", "หร", "ห้", "ห้ว", "ห้วย", "เดอ", "วิ", "แอ", "เอ",
        "ไลฟ์", "นอเบิล", "ไฮด์", "ทรู", "ทอง", "อโศ", "สุข", "พระ", "ลาด", "บาง",
        "hyde", "life", "noble", "asok", "thong", "huai", "rama", "sukhumvit",
    ):
        add(th)
    return queries


def entry_key(e: dict[str, Any]) -> str:
    return "|".join(
        [
            str(e.get("kind") or ""),
            str(e.get("title_th") or ""),
            str(e.get("title_en") or ""),
            str(e.get("project_slug") or ""),
            ",".join(e.get("geo_zone_slugs") or []),
        ]
    )


def make_entry(
    *,
    kind: str,
    title_th: str,
    title_en: str,
    subtitle_th: str = "",
    subtitle_en: str = "",
    project_slug: str | None = None,
    geo_zone_slugs: list[str] | None = None,
    source: str = "bootstrap",
) -> dict[str, Any]:
    return {
        "kind": kind,
        "title_th": title_th,
        "title_en": title_en,
        "subtitle_th": subtitle_th,
        "subtitle_en": subtitle_en,
        "project_slug": project_slug,
        "geo_zone_slugs": geo_zone_slugs or [],
        "source": source,
    }


def index_entry(by_query: dict[str, list[dict]], entry: dict[str, Any], query: str) -> None:
    q = query.strip()
    if not q:
        return
    bucket = by_query.setdefault(q, [])
    ek = entry_key(entry)
    if any(entry_key(x) == ek for x in bucket):
        return
    bucket.append(entry)


def prefix_queries_for_text(text_th: str, text_en: str) -> list[str]:
    """สร้างคีย์ค้นหาทุก prefix สำหรับดรอปดาวน์ (ห → ห้วยขวาง)."""
    keys: set[str] = set()
    for raw in (text_th, text_en.lower()):
        t = raw.strip()
        if not t:
            continue
        for i in range(1, min(len(t) + 1, 12)):
            keys.add(t[:i])
        for word in re.split(r"[\s\-]+", t):
            if len(word) >= 1:
                for i in range(1, min(len(word) + 1, 8)):
                    keys.add(word[:i])
    return sorted(keys, key=lambda x: (len(x), x))


def bootstrap_index() -> tuple[dict[str, list[dict]], list[dict]]:
    by_query: dict[str, list[dict]] = {}
    all_entries: list[dict] = []
    seen: set[str] = set()

    def push(entry: dict[str, Any]) -> None:
        ek = entry_key(entry)
        if ek in seen:
            return
        seen.add(ek)
        all_entries.append(entry)
        for q in prefix_queries_for_text(entry["title_th"], entry["title_en"]):
            index_entry(by_query, entry, q)

    for th, en, slug in LOCATION_SEEDS:
        push(
            make_entry(
                kind="location",
                title_th=th,
                title_en=en,
                subtitle_th="ทำเล · กทม.+ปริมณฑล",
                subtitle_en="Area · Bangkok metro",
                geo_zone_slugs=[slug],
                source="bootstrap_district",
            )
        )

    for th, en, slug in BTS_MRT_SEEDS:
        push(
            make_entry(
                kind="transit",
                title_th=th,
                title_en=en,
                subtitle_th="การเดินทาง",
                subtitle_en="Transit",
                geo_zone_slugs=[slug],
                source="bootstrap_transit",
            )
        )

    return by_query, all_entries


def fetch_html(url: str) -> str:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": UA, "Accept-Language": "th-TH,th;q=0.9,en;q=0.9"},
    )
    with urllib.request.urlopen(req, timeout=45) as res:
        return res.read().decode("utf-8", errors="ignore")


def parse_next_data(html: str) -> dict[str, Any] | None:
    m = re.search(
        r'<script id="__NEXT_DATA__"[^>]*type="application/json"[^>]*>(.*?)</script>',
        html,
        re.S,
    )
    if not m:
        return None
    try:
        return json.loads(m.group(1))
    except json.JSONDecodeError:
        return None


def district_from_address(address: str) -> str | None:
    if not address:
        return None
    part = address.split("Bangkok")[0].strip(" ,")
    if not part:
        return None
    return part.split(",")[0].strip()


def crawl_query(
    query: str,
    by_query: dict[str, list[dict]],
    all_entries: list[dict],
    seen: set[str],
) -> None:
    path = f"/en/condo-for-rent/bangkok?text={urllib.parse.quote(query)}"
    try:
        html = fetch_html(f"https://propertyhub.in.th{path}")
    except urllib.error.HTTPError:
        return
    except Exception as e:
        print(f"  skip {query}: {e}", file=sys.stderr)
        return

    data = parse_next_data(html)
    if not data:
        return

    pp = (data.get("props") or {}).get("pageProps") or {}
    zone = pp.get("zone") or {}
    if isinstance(zone, dict) and zone.get("name"):
        zname = str(zone["name"])
        zslug = str(zone.get("slug") or "").strip()
        entry = make_entry(
            kind="location",
            title_th=zname,
            title_en=zname,
            subtitle_th="โซนจาก Property Hub",
            subtitle_en="Zone from Property Hub",
            geo_zone_slugs=[zslug] if zslug else [],
            source=f"web_zone:{query}",
        )
        ek = entry_key(entry)
        if ek not in seen:
            seen.add(ek)
            all_entries.append(entry)
        index_entry(by_query, entry, query)

    listings = (pp.get("listings") or {}).get("listings") or []
    for item in listings[:80]:
        if not isinstance(item, dict):
            continue
        proj = item.get("project") or {}
        if not isinstance(proj, dict):
            continue
        slug = (proj.get("slug") or "").strip()
        name = (proj.get("name") or "").strip()
        name_en = (proj.get("nameEnglish") or name).strip()
        addr = (proj.get("address") or "").strip()
        if not slug or not name:
            continue
        entry = make_entry(
            kind="project",
            title_th=name,
            title_en=name_en,
            subtitle_th=addr or "โครงการ",
            subtitle_en=addr or "Project",
            project_slug=slug,
            source=f"web_project:{query}",
        )
        ek = entry_key(entry)
        if ek not in seen:
            seen.add(ek)
            all_entries.append(entry)
        index_entry(by_query, entry, query)

        dist = district_from_address(addr)
        if dist:
            loc = make_entry(
                kind="location",
                title_th=dist,
                title_en=dist,
                subtitle_th="จากที่อยู่โครงการ",
                subtitle_en="From project address",
                source=f"web_district:{query}",
            )
            lek = entry_key(loc)
            if lek not in seen:
                seen.add(lek)
                all_entries.append(loc)
            index_entry(by_query, loc, query)


def save_payload(by_query: dict, all_entries: list, done: list[str]) -> None:
    payload = {
        "version": 1,
        "scope": "bangkok_metro",
        "method": "alphabet_display_index",
        "query_count": len(by_query),
        "entry_count": len(all_entries),
        "by_query": by_query,
        "entries": all_entries,
    }
    OUT_TMP.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    OUT_APP.parent.mkdir(parents=True, exist_ok=True)
    OUT_APP.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    PROGRESS.write_text(json.dumps({"done_queries": done}, ensure_ascii=False), encoding="utf-8")


def main() -> int:
    by_query, all_entries = bootstrap_index()
    seen = {entry_key(e) for e in all_entries}
    done: list[str] = []

    if RESUME and OUT_TMP.exists():
        try:
            prev = json.loads(OUT_TMP.read_text(encoding="utf-8"))
            for q, items in (prev.get("by_query") or {}).items():
                for e in items:
                    if entry_key(e) not in seen:
                        seen.add(entry_key(e))
                        all_entries.append(e)
                    index_entry(by_query, e, q)
            if PROGRESS.exists():
                done = json.loads(PROGRESS.read_text(encoding="utf-8")).get("done_queries") or []
        except Exception:
            pass

    queries = build_alphabet_queries()
    if SMOKE_TEST:
        queries = ["ห", "ห้", "hyde", "h", "ทรู", "อโศก"]

    print(f"=== สมุดแสดงผลค้นหา (ดรอปดาวน์) ===", flush=True)
    print(f"bootstrap: {len(all_entries)} รายการ | คำค้นเว็บ: {len(queries)}", flush=True)

    if CRAWL_WEB:
        for i, q in enumerate(queries):
            if RESUME and q in done:
                continue
            crawl_query(q, by_query, all_entries, seen)
            done.append(q)
            if (i + 1) % 20 == 0 or SMOKE_TEST:
                save_payload(by_query, all_entries, done)
                print(f"  [{i + 1}/{len(queries)}] รวม {len(all_entries)} รายการ", flush=True)
            time.sleep(DELAY)

    save_payload(by_query, all_entries, done)

    sample = by_query.get("ห", [])
    print(f"\n✅ เก็บแล้ว {len(all_entries)} รายการ, {len(by_query)} คำค้น", flush=True)
    print(f"   แอป: {OUT_APP}", flush=True)
    if sample:
        titles = [x.get("title_th") for x in sample[:5]]
        print(f"   ตัวอย่าง ค้น「ห」: {', '.join(titles)}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
