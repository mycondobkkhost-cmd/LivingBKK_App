#!/usr/bin/env python3
"""
ค้นหาโครงการ กทม.+ปริมณฑล จาก Property Hub — แบบครอบคลุม (v2)

อ่าน __NEXT_DATA__ จากหน้าประกาศ → ดึง project.slug + address ตรงจาก JSON
ไม่พึ่ง regex อย่างเดียว และไล่ pagination จนครบ (หรือตาม MAX_PAGES_PER_SEED)

ชั้นการค้นหา:
  A — เขตกรุงเทพ 50 เขต × 6 ประเภทประกาศ
  B — โซน BTS + MRT
  C — 6 จังหวัดปริมณฑลเต็มจังหวัด
  D — seed โครงการดัง + ลิงก์จากหน้าโครงการ + หน้า project-{slug}
  E — ค้นหาตามตัวอักษร/พยางค์ (?text=) ทุกจังหวัดปริมณฑล

ผลลัพธ์: data/ph-pipeline/ph-metro-slugs.json (หรือ PH_PIPELINE_DIR)
"""
from __future__ import annotations

import json
import os
import re
import signal
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable

UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
)
ROOT = Path(__file__).resolve().parents[1]
PIPELINE_DIR = Path(os.environ.get("PH_PIPELINE_DIR", "/tmp"))
OUT = PIPELINE_DIR / "ph-metro-slugs.json"
LEGACY_OUT = PIPELINE_DIR / "ph-all-slugs.json"
PROGRESS_OUT = PIPELINE_DIR / "ph-metro-discover-progress.json"
LINKS_SNAPSHOT = PIPELINE_DIR / "ph-links-snapshot.json"
BACKUP_DIR = PIPELINE_DIR / "backups"
SAVE_EVERY_PAGES = int(os.environ.get("SAVE_EVERY_PAGES", "10"))
BACKUP_EVERY_N_PROJECTS = int(os.environ.get("BACKUP_EVERY_N_PROJECTS", "250"))

# สำหรับบันทึกฉุกเฉินเมื่อคอมดับ / SIGTERM
_runtime: dict[str, Any] = {}
_last_backup_count = 0

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

# เขตกรุงเทพ → slug บน Property Hub (ต่อท้าย -bangkok)
BKK_DISTRICT_SLUGS = [
    "phra-nakhon", "dusit", "nong-chok", "bang-rak", "bang-khen", "bang-kapi",
    "pathum-wan", "pom-prap-sattru-phai", "phra-khanong", "min-buri", "lat-krabang",
    "yan-nawa", "samphanthawong", "phaya-thai", "thon-buri", "bangkok-yai",
    "bangkok-noi", "bang-khun-thian", "phasi-charoen", "nong-khaem", "rat-burana",
    "bang-phlat", "din-daeng", "bueng-kum", "sathorn", "bang-sue", "chatuchak",
    "bang-kho-laem", "prawet", "khlong-toei", "suan-luang", "chom-thong",
    "don-mueang", "ratchathewi", "lat-phrao", "watthana", "bang-khae", "lak-si",
    "sai-mai", "khan-na-yao", "saphan-sung", "wang-thonglang", "khlong-sam-wa",
    "bang-na", "thawi-watthana", "thung-khru", "bang-bon",
]

BTS_ZONES = [
    "asok", "phrom-phong", "thonglor", "ekkamai", "on-nut", "bang-chak", "bearing",
    "udom-suk", "bang-na", "samrong", "ari", "sanam-pao", "phaya-thai",
    "victory-monument", "siam", "chit-lom", "ploenchit", "nana", "rama-9",
    "huai-khwang", "sutthisan", "lat-phrao", "phra-khanong", "wutthakat",
    "talat-phlu", "bang-wa", "saphan-taksin", "surasak", "saphan-khwai",
    "mo-chit", "makkasan", "phetchaburi", "silom", "lumphini", "sam-yan",
    "wat-mangkon", "sam-yot", "sanam-chai", "ratchathewi", "national-stadium",
    "ratchadamri", "khlong-toei", "chong-nonsi", "saladaeng", "krung-thon-buri",
    "wongwian-yai", "pho-nang", "punnawithi", "eakamai", "bang-chak",
]

MRT_ZONES = [
    "sukhumvit", "phetchaburi", "phra-ram-9", "thailand-cultural-centre",
    "huai-khwang", "sutthisan", "ratchadaphisek", "lat-phrao", "phahon-yothin",
    "chatuchak-park", "kamphaeng-phet", "bang-sue", "tao-poon", "bang-phlat",
    "itsaraphap", "sanam-chai", "sam-yot", "hualamphong", "lumphini", "si-lom",
    "sukhumvit", "queen-sirikit", "khlong-toei", "samyan", "wat-mangkon",
]

EXCLUDED_ADDRESS_KEYWORDS = [
    "chiang mai", "เชียงใหม่", "phuket", "ภูเก็ต", "pattaya", "พัทยา",
    "chonburi", "ชลบุรี", "rayong", "ระยอง", "khon kaen", "ขอนแก่น",
    "hat yai", "หาดใหญ่", "songkhla", "สงขลา", "udon", "อุดร",
    "nakhon ratchasima", "โคราช", "surat thani", "สุราษฎร์",
]

METRO_ADDRESS_KEYWORDS = [
    "bangkok", "กรุงเทพ", "นนทบุรี", "nonthaburi", "ปทุมธานี", "pathum",
    "pathumthani", "สมุทรปราการ", "samut prakan", "samutprakan",
    "สมุทรสาคร", "samut sakhon", "นครปฐม", "nakhon pathom",
    "บางใหญ่", "บางบัวทอง", "บางกรวย", "รังสิต", "คลองหลวง",
    "บางพลี", "พระประแดง", "เมืองนนทบุรี", "เมืองปทุมธานี",
]

# โครงการ seed ที่ต้องมี + โครงการดังในกทม.
BOOTSTRAP_SEED_SLUGS = [
    "hyde-heritage-thonglor", "hyde-heritage", "true-thonglor", "ashton-asoke",
    "life-asoke-hype", "noble-remix-thonglor", "the-line-sukhumvit-101",
    "ideo-ratchada-huaykwang", "lumpini-place-rama9", "rhythm-sukhumvit-36",
    "the-lofts-ekkamai", "beatniq-sukhumvit-32", "hyde-sukhumvit-11",
    "ashton-chula-silom", "regent-home-sukhumvit-81", "life-one-wireless",
]

MAX_PAGES_PER_SEED = int(os.environ.get("MAX_PAGES_PER_SEED", "0"))  # 0 = unlimited
# ชั้น E — COLLECT_ALL=1 ค่าเริ่มต้นไม่จำกัดหน้า (เก็บลิงก์ให้ครบก่อน)
COLLECT_ALL = os.environ.get("COLLECT_ALL", "0") == "1"
MAX_PAGES_PER_QUERY = int(
    os.environ.get(
        "MAX_PAGES_PER_QUERY",
        "0" if COLLECT_ALL else "8",
    )
)
DELAY_SEC = float(os.environ.get("DISCOVER_DELAY", "0.12"))
SMOKE_TEST = os.environ.get("SMOKE_TEST", "0") == "1"
RESUME = os.environ.get("RESUME", "1") == "1"
LAYERS = os.environ.get("LAYERS", "A,B,C,D,E").upper().split(",")
RAW_OUT = Path(os.environ.get("RAW_OUT", str(PIPELINE_DIR / "ph-all-links-raw.json")))
TEXT_LISTING_TYPES = ("condo-for-rent", "condo-for-sale")


@dataclass
class ProjectHit:
    slug: str
    name: str = ""
    name_en: str = ""
    address: str = ""
    sources: set[str] = field(default_factory=set)

    def to_dict(self) -> dict[str, Any]:
        return {
            "slug": self.slug,
            "name": self.name,
            "name_en": self.name_en,
            "address": self.address,
            "sources": sorted(self.sources),
        }


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
    bad = {"undefined", "new", "edit", "search", "page", "projects"}
    return slug not in bad


def is_metro_address(address: str) -> bool:
    if not address or not address.strip():
        return True  # ไม่มีที่อยู่ — เก็บไว้ก่อน กรองตอน import
    hay = address.lower()
    for bad in EXCLUDED_ADDRESS_KEYWORDS:
        if bad in hay:
            return False
    return any(k in hay for k in METRO_ADDRESS_KEYWORDS)


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


def projects_from_listings_payload(data: dict[str, Any]) -> list[dict[str, str]]:
    pp = (data.get("props") or {}).get("pageProps") or {}
    block = pp.get("listings") or {}
    items = block.get("listings") or []
    out: list[dict[str, str]] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        proj = item.get("project") or {}
        if not isinstance(proj, dict):
            continue
        slug = (proj.get("slug") or "").strip()
        if not slug or not is_valid_slug(slug):
            continue
        out.append(
            {
                "slug": slug,
                "name": (proj.get("name") or "").strip(),
                "name_en": (proj.get("nameEnglish") or "").strip(),
                "address": (proj.get("address") or "").strip(),
            }
        )
    return out


def slugs_from_project_html(html: str) -> set[str]:
    found = set(re.findall(r"/projects/([a-z0-9-]+)", html))
    return {s for s in found if is_valid_slug(s)}


def build_page_url(path: str, page: int, text_query: str | None = None) -> str:
    base = f"https://propertyhub.in.th{path}"
    params: list[str] = []
    if text_query:
        params.append(f"text={urllib.parse.quote(text_query)}")
    if page > 1:
        params.append(f"page={page}")
    if not params:
        return base
    return f"{base}?{'&'.join(params)}"


def get_pagination(data: dict[str, Any]) -> tuple[int, int]:
    pp = (data.get("props") or {}).get("pageProps") or {}
    block = pp.get("listings") or {}
    pag = block.get("pagination") or {}
    total_pages = int(pag.get("totalPages") or 1)
    total_count = int(pag.get("totalCount") or 0)
    return max(1, total_pages), total_count


def build_search_queries() -> list[str]:
    """คำค้นสำหรับชั้น E — ไล่ตัวอักษร + พยางค์ไทย + คำนำหน้าโครงการดัง."""
    queries: list[str] = []
    seen: set[str] = set()

    def add(q: str) -> None:
        q = q.strip().lower()
        if len(q) < 1 or q in seen:
            return
        seen.add(q)
        queries.append(q)

    for c in "abcdefghijklmnopqrstuvwxyz":
        add(c)

    for d in "0123456789":
        add(d)

    for bg in (
        "th", "hy", "he", "hi", "li", "lf", "no", "as", "vi", "ra", "su", "ka",
        "ba", "on", "ut", "la", "si", "kn", "ch", "pl", "ru", "pa", "id", "sk",
        "ide", "lif", "nob", "hyd", "asp", "the", "one", "lin", "bea", "hyp",
        "lum", "reg", "bea", "rh", "tem", "soc", "xt", "kn", "base", "life",
        "hyde", "heritage", "ashton", "noble", "supal", "ideo", "lumpini",
    ):
        add(bg)

    for th in (
        "ก", "ข", "ค", "ง", "จ", "ช", "ด", "ต", "ท", "น", "บ", "ป", "พ", "ฟ",
        "ม", "ย", "ร", "ล", "ว", "ส", "ห", "อ", "ฮ",
        "ไล", "ทร", "นอ", "ไฮ", "หร", "เดอ", "วิ", "แอ", "เอ", "ไอ", "เดอะ",
        "ไลฟ์", "นอเบิล", "ไฮด์", "แอส", "เดอะไลน์", "ลัม", "รีเจ้นท์", "ไอดีโอ",
        "ทรู", "อโศก", "ทองหล่อ", "สุขุมวิท", "พระราม", "ลาดพร้าว", "บางนา",
    ):
        add(th)

    return queries


def build_text_search_seeds() -> list[tuple[str, str, str]]:
    """(layer, province_path, query) for layer E."""
    seeds: list[tuple[str, str, str]] = []
    queries = build_search_queries()
    if SMOKE_TEST:
        queries = ["hyde", "life", "noble", "h", "ทรู", "ไลฟ์"]

    provinces = ["bangkok"] if SMOKE_TEST else METRO_PROVINCES
    for province in provinces:
        for kind in TEXT_LISTING_TYPES:
            base = f"/en/{kind}/{province}"
            for q in queries:
                seeds.append(("E", base, q))
    return seeds


def build_seeds() -> list[tuple[str, str]]:
    """Return list of (layer, path_without_domain)."""
    seeds: list[tuple[str, str]] = []

    if "A" in LAYERS:
        for district in BKK_DISTRICT_SLUGS:
            area = f"{district}-bangkok"
            for kind in LISTING_TYPES:
                seeds.append(("A", f"/en/{kind}/{area}"))

    if "B" in LAYERS:
        for zone in dict.fromkeys(BTS_ZONES):  # dedupe order-preserving
            for kind in ("condo-for-rent", "condo-for-sale"):
                seeds.append(("B", f"/en/{kind}/bts-{zone}"))
        for zone in dict.fromkeys(MRT_ZONES):
            for kind in ("condo-for-rent", "condo-for-sale"):
                seeds.append(("B", f"/en/{kind}/mrt-{zone}"))

    if "C" in LAYERS:
        for province in METRO_PROVINCES:
            for kind in LISTING_TYPES:
                seeds.append(("C", f"/en/{kind}/{province}"))

    if SMOKE_TEST:
        smoke = [
            ("A", "/en/condo-for-rent/watthana-bangkok"),
            ("A", "/en/condo-for-rent/huai-khwang-bangkok"),
            ("B", "/en/condo-for-rent/bts-thonglor"),
            ("B", "/en/condo-for-rent/mrt-sukhumvit"),
            ("C", "/en/condo-for-rent/nonthaburi"),
        ]
        allowed = set(LAYERS)
        seeds = [(layer, path) for layer, path in smoke if layer in allowed]

    return seeds


def load_state() -> tuple[dict[str, ProjectHit], set[str]]:
    projects: dict[str, ProjectHit] = {}
    done_seeds: set[str] = set()

    if RESUME and OUT.exists():
        try:
            raw = json.loads(OUT.read_text(encoding="utf-8"))
            for p in raw.get("projects") or []:
                slug = p.get("slug")
                if not slug:
                    continue
                projects[slug] = ProjectHit(
                    slug=slug,
                    name=p.get("name", ""),
                    name_en=p.get("name_en", ""),
                    address=p.get("address", ""),
                    sources=set(p.get("sources") or []),
                )
        except Exception:
            pass

    if RESUME and PROGRESS_OUT.exists():
        try:
            prog = json.loads(PROGRESS_OUT.read_text(encoding="utf-8"))
            done_seeds = set(prog.get("done_seeds") or [])
        except Exception:
            pass

    return projects, done_seeds


def metro_slugs_from(projects: dict[str, ProjectHit]) -> list[str]:
    out: list[str] = []
    for p in sorted(projects.values(), key=lambda x: x.slug):
        if is_metro_address(p.address):
            out.append(p.slug)
    return out


def _atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(text, encoding="utf-8")
    tmp.replace(path)


def _maybe_backup(payload: dict[str, Any]) -> None:
    global _last_backup_count
    count = int(payload.get("count") or 0)
    if count < 1:
        return
    if count - _last_backup_count < BACKUP_EVERY_N_PROJECTS:
        return
    _last_backup_count = count
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    stamp = time.strftime("%Y%m%d-%H%M%S")
    body = json.dumps(payload, ensure_ascii=False, indent=2)
    _atomic_write(BACKUP_DIR / "latest.json", body)
    _atomic_write(BACKUP_DIR / f"checkpoint-{stamp}-{count}.json", body)


def save_state(
    projects: dict[str, ProjectHit],
    done_seeds: set[str],
    *,
    current_seed: str | None = None,
    current_page: int | None = None,
) -> None:
    ordered = sorted(projects.values(), key=lambda p: p.slug)
    metro_slugs = metro_slugs_from(projects)
    saved_at = time.strftime("%Y-%m-%dT%H:%M:%S")
    payload = {
        "count": len(ordered),
        "metro_count": len(metro_slugs),
        "scope": "collect_all" if COLLECT_ALL else "bangkok_metro_only",
        "method": "next_data_v2",
        "collect_all": COLLECT_ALL,
        "phase": "collect",
        "saved_at": saved_at,
        "slugs": [p.slug for p in ordered],
        "metro_slugs": metro_slugs,
        "projects": [p.to_dict() for p in ordered],
    }
    body = json.dumps(payload, ensure_ascii=False, indent=2)
    _atomic_write(OUT, body)
    if COLLECT_ALL:
        _atomic_write(RAW_OUT, body)
    _atomic_write(
        LEGACY_OUT,
        json.dumps(
            {
                "count": payload["count"],
                "slugs": payload["slugs"],
                "metro_count": payload["metro_count"],
                "metro_slugs": metro_slugs,
                "saved_at": saved_at,
            },
            ensure_ascii=False,
        ),
    )
    _atomic_write(
        LINKS_SNAPSHOT,
        json.dumps(
            {
                "count": payload["count"],
                "slugs": payload["slugs"],
                "saved_at": saved_at,
                "current_seed": current_seed,
                "current_page": current_page,
            },
            ensure_ascii=False,
            indent=2,
        ),
    )
    _atomic_write(
        PROGRESS_OUT,
        json.dumps(
            {
                "done_seeds": sorted(done_seeds),
                "project_count": len(ordered),
                "current_seed": current_seed,
                "current_page": current_page,
                "saved_at": saved_at,
            },
            ensure_ascii=False,
            indent=2,
        ),
    )
    _maybe_backup(payload)


def _emergency_save(*_args: Any) -> None:
    rt = _runtime
    if not rt:
        sys.exit(0)
    try:
        save_state(
            rt["projects"],
            rt["done_seeds"],
            current_seed=rt.get("current_seed"),
            current_page=rt.get("current_page"),
        )
        print(f"\n💾 บันทึกฉุกเฉิน {len(rt['projects'])} ลิงก์ → {OUT}", flush=True)
    except Exception as e:
        print(f"\n⚠️ บันทึกฉุกเฉินล้มเหลว: {e}", file=sys.stderr, flush=True)
    sys.exit(0)


def merge_hit(projects: dict[str, ProjectHit], hit: dict[str, str], source: str) -> None:
    slug = hit["slug"]
    if not COLLECT_ALL and not is_metro_address(hit.get("address", "")):
        return
    existing = projects.get(slug)
    if existing is None:
        projects[slug] = ProjectHit(
            slug=slug,
            name=hit.get("name", ""),
            name_en=hit.get("name_en", ""),
            address=hit.get("address", ""),
            sources={source},
        )
        return
    if hit.get("name") and not existing.name:
        existing.name = hit["name"]
    if hit.get("name_en") and not existing.name_en:
        existing.name_en = hit["name_en"]
    if hit.get("address") and not existing.address:
        existing.address = hit["address"]
    existing.sources.add(source)


def crawl_seed(
    layer: str,
    path: str,
    projects: dict[str, ProjectHit],
    *,
    text_query: str | None = None,
    max_pages: int | None = None,
    on_checkpoint: Callable[[int], None] | None = None,
) -> int:
    q_suffix = f"?text={urllib.parse.quote(text_query)}" if text_query else ""
    source = f"{layer}:{path}{q_suffix}"
    added = 0
    before = len(projects)

    page1_url = build_page_url(path, 1, text_query)
    try:
        html = fetch_html(page1_url)
    except urllib.error.HTTPError as e:
        print(f"  skip {path}: HTTP {e.code}", file=sys.stderr)
        return 0
    except Exception as e:
        print(f"  skip {path}: {e}", file=sys.stderr)
        return 0

    data = parse_next_data(html)
    if not data:
        # fallback regex จาก HTML
        for slug in slugs_from_project_html(html):
            merge_hit(projects, {"slug": slug, "address": ""}, source)
        return len(projects) - before

    total_pages, total_count = get_pagination(data)
    if max_pages is not None:
        page_cap = max_pages
    elif text_query:
        page_cap = MAX_PAGES_PER_QUERY if MAX_PAGES_PER_QUERY > 0 else total_pages
    else:
        page_cap = total_pages if MAX_PAGES_PER_SEED <= 0 else min(total_pages, MAX_PAGES_PER_SEED)
    cap = min(total_pages, page_cap) if page_cap > 0 else total_pages

    for page in range(1, cap + 1):
        if page == 1:
            page_html = html
            page_data = data
        else:
            page_url = build_page_url(path, page, text_query)
            try:
                page_html = fetch_html(page_url)
                page_data = parse_next_data(page_html) or {}
            except Exception as e:
                print(f"  page {page} {path}: {e}", file=sys.stderr)
                break
            time.sleep(DELAY_SEC)

        hits = projects_from_listings_payload(page_data)
        if not hits:
            hits = [{"slug": s, "name": "", "name_en": "", "address": ""} for s in slugs_from_project_html(page_html)]

        for h in hits:
            merge_hit(projects, h, source)

        if page % 25 == 0 or page == cap:
            print(
                f"    {path} page {page}/{cap} (+{len(projects) - before} รวม {len(projects)})",
                flush=True,
            )
        if on_checkpoint and (page % SAVE_EVERY_PAGES == 0 or page == cap):
            on_checkpoint(page)

    added = len(projects) - before
    print(
        f"  [{layer}] {path}: +{added} โครงการ (pages {cap}/{total_pages}, listings≈{total_count})",
        flush=True,
    )
    return added


def crawl_layer_d(projects: dict[str, ProjectHit]) -> None:
    seeds = list(BOOTSTRAP_SEED_SLUGS)
    if not SMOKE_TEST:
        for slug in list(projects.keys())[:300]:
            if slug not in seeds:
                seeds.append(slug)

    def paths_for_slug(slug: str) -> tuple[str, ...]:
        if SMOKE_TEST:
            return (f"/en/condo-for-rent/project-{slug}",)
        return (
            f"/projects/{slug}",
            f"/en/condo-for-rent/project-{slug}",
            f"/en/condo-for-sale/project-{slug}",
        )

    for slug in seeds:
        if not is_valid_slug(slug):
            continue
        for path in paths_for_slug(slug):
            source = f"D:{path}"
            try:
                html = fetch_html(f"https://propertyhub.in.th{path}")
            except Exception:
                continue
            merge_hit(
                projects,
                {"slug": slug, "name": "", "name_en": "", "address": ""},
                source,
            )
            data = parse_next_data(html)
            if data:
                for h in projects_from_listings_payload(data):
                    merge_hit(projects, h, source)
            for related in slugs_from_project_html(html):
                merge_hit(
                    projects,
                    {"slug": related, "name": "", "name_en": "", "address": ""},
                    source,
                )
            time.sleep(DELAY_SEC)
    print(f"  [D] seed + project-* pages: รวม {len(projects)} โครงการ", flush=True)


def main() -> int:
    global _last_backup_count
    PIPELINE_DIR.mkdir(parents=True, exist_ok=True)
    signal.signal(signal.SIGTERM, _emergency_save)
    signal.signal(signal.SIGINT, _emergency_save)

    projects, done_seeds = load_state()
    _last_backup_count = len(projects)
    seeds = build_seeds()

    text_seeds = build_text_search_seeds() if "E" in LAYERS else []

    print("=== Property Hub — ค้นหาโครงการ (v2) ===", flush=True)
    print(f"บันทึกถาวร: {PIPELINE_DIR} (ทุก {SAVE_EVERY_PAGES} หน้า)", flush=True)
    if COLLECT_ALL:
        print("โหมด COLLECT_ALL — เก็บทุกลิงก์ก่อน คัดกรองทีหลัง", flush=True)
    print(
        f"ชั้น: {','.join(LAYERS)} | A-C seeds: {len(seeds)} | E คำค้น: {len(text_seeds)} | มีอยู่แล้ว: {len(projects)}",
        flush=True,
    )
    if MAX_PAGES_PER_SEED > 0:
        print(f"จำกัด {MAX_PAGES_PER_SEED} หน้า/seed (A-C)", flush=True)
    if MAX_PAGES_PER_QUERY > 0:
        print(f"จำกัด {MAX_PAGES_PER_QUERY} หน้า/คำค้น (E)", flush=True)
    if SMOKE_TEST:
        print("โหมด SMOKE_TEST — ทดสอบสั้นๆ", flush=True)

    _runtime["projects"] = projects
    _runtime["done_seeds"] = done_seeds

    def make_checkpoint(key: str) -> Callable[[int], None]:
        def checkpoint(page: int) -> None:
            _runtime["current_seed"] = key
            _runtime["current_page"] = page
            save_state(projects, done_seeds, current_seed=key, current_page=page)

        return checkpoint

    for layer, path in seeds:
        key = f"{layer}:{path}"
        if RESUME and key in done_seeds:
            continue
        crawl_seed(layer, path, projects, on_checkpoint=make_checkpoint(key))
        done_seeds.add(key)
        _runtime.pop("current_seed", None)
        _runtime.pop("current_page", None)
        save_state(projects, done_seeds)
        time.sleep(DELAY_SEC)

    for layer, path, query in text_seeds:
        key = f"{layer}:{path}?text={query}"
        if RESUME and key in done_seeds:
            continue
        crawl_seed(
            layer,
            path,
            projects,
            text_query=query,
            on_checkpoint=make_checkpoint(key),
        )
        done_seeds.add(key)
        _runtime.pop("current_seed", None)
        _runtime.pop("current_page", None)
        save_state(projects, done_seeds)
        time.sleep(DELAY_SEC)

    if "D" in LAYERS:
        crawl_layer_d(projects)
        save_state(projects, done_seeds)

    save_state(projects, done_seeds)
    _runtime.clear()

    # สรุปโครงการดัง
    famous = ["hyde-heritage-thonglor", "hyde-heritage", "ashton-asoke", "life-asoke-hype"]
    found_famous = [s for s in famous if s in projects]
    metro_n = len(metro_slugs_from(projects))
    print(f"\n✅ พบ {len(projects)} ลิงก์โครงการ (กรองกทม.+ปริมณฑลได้ {metro_n}) → {OUT}", flush=True)
    if COLLECT_ALL:
        print(f"   ไฟล์ดิบทั้งหมด → {RAW_OUT}", flush=True)
    if found_famous:
        print(f"   โครงการดังที่เจอ: {', '.join(found_famous)}", flush=True)
    else:
        print("   ⚠️ ยังไม่เจอ Hyde Heritage ในรอบนี้ — รันเต็มชั้น A/B หรือเพิ่ม seed", flush=True)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
