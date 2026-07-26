#!/usr/bin/env python3
"""Import Pantip Property curated project catalog into RealXtate seed artifacts.

Reads pantip-property-hub / pantip-property-automation:
  - data/projects.json
  - data/project_aliases.json

Writes (under data/pantip_import/):
  - property_projects_seed.json
  - coverage_report.json
  - property_projects_seed.sql  (optional upsert statements)

Does NOT import listings inventory, LivingInsider HTML, or scrape anew.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "data" / "pantip_import"

# Bootstrap projects from mobile/lib/data/bangkok_projects.dart (coords + slugs).
BOOTSTRAP: list[dict[str, Any]] = [
    {
        "slug": "true-thonglor",
        "name_th": "ทรู ทองหล่อ",
        "name_en": "THRU Thonglor",
        "district": "วัฒนา",
        "lat": 13.744168,
        "lng": 100.585446,
        "bts": "BTS ทองหล่อ",
        "aliases": ["ทรู", "ทองหล่อ", "thonglor", "trendy", "thru thonglor"],
    },
    {
        "slug": "the-line-sukhumvit-101",
        "name_th": "เดอะไลน์ สุขุมวิท 101",
        "name_en": "The Line Sukhumvit 101",
        "district": "วัฒนา",
        "lat": 13.691995,
        "lng": 100.608228,
        "bts": "BTS บางจาก",
        "aliases": ["line 101", "เดอะไลน์"],
    },
    {
        "slug": "noble-remix-thonglor",
        "name_th": "โนเบิล รีมิกซ์ ทองหล่อ",
        "name_en": "Noble Remix Thonglor",
        "district": "วัฒนา",
        "lat": 13.724567,
        "lng": 100.577260,
        "bts": "BTS ทองหล่อ",
        "aliases": ["noble remix", "โนเบิล"],
    },
    {
        "slug": "rhythm-sukhumvit-36",
        "name_th": "ริธึม สุขุมวิท 36",
        "name_en": "Rhythm Sukhumvit 36",
        "district": "คลองเตย",
        "lat": 13.721870,
        "lng": 100.576904,
        "bts": "BTS ทองหล่อ",
        "aliases": ["rhythm 36", "ริธึม"],
    },
    {
        "slug": "ashton-asoke",
        "name_th": "แอสตัน อโศก",
        "name_en": "Ashton Asoke",
        "district": "วัฒนา",
        "lat": 13.738783,
        "lng": 100.561071,
        "bts": "BTS อโศก / MRT สุขุมวิท",
        "aliases": ["ashton", "อโศก", "asok"],
    },
    {
        "slug": "life-asoke-hype",
        "name_th": "ไลฟ์ อโศก ไฮป์",
        "name_en": "Life Asoke Hype",
        "district": "วัฒนา",
        "lat": 13.754291,
        "lng": 100.562893,
        "bts": "BTS อโศก",
        "aliases": ["life asoke", "ไลฟ์ อโศก"],
    },
    {
        "slug": "the-lofts-ekkamai",
        "name_th": "เดอะ ลอฟท์ เอกมัย",
        "name_en": "The Lofts Ekkamai",
        "district": "วัฒนา",
        "lat": 13.718407,
        "lng": 100.587647,
        "bts": "BTS เอกมัย",
        "aliases": ["lofts ekkamai", "เอกมัย", "ekkamai"],
    },
    {
        "slug": "hq-sukhumvit-101",
        "name_th": "HQ สุขุมวิท 101",
        "name_en": "HQ Sukhumvit 101",
        "district": "วัฒนา",
        "lat": 13.729764,
        "lng": 100.581401,
        "bts": "BTS บางจาก",
        "aliases": ["hq 101"],
    },
    {
        "slug": "tela-thonglor",
        "name_th": "เทล่า ทองหล่อ",
        "name_en": "Tela Thonglor",
        "district": "วัฒนา",
        "lat": 13.733041,
        "lng": 100.582043,
        "bts": "BTS ทองหล่อ",
        "aliases": ["tela"],
    },
    {
        "slug": "beatniq-sukhumvit-32",
        "name_th": "บีทนิค สุขุมวิท 32",
        "name_en": "Beatniq Sukhumvit 32",
        "district": "คลองเตย",
        "lat": 13.726175,
        "lng": 100.575635,
        "bts": "BTS ทองหล่อ",
        "aliases": ["beatniq"],
    },
    {
        "slug": "ideo-q-sukhumvit-36",
        "name_th": "ไอดีโอ คิว สุขุมวิท 36",
        "name_en": "Ideo Q Sukhumvit 36",
        "district": "คลองเตย",
        "lat": 13.720876,
        "lng": 100.576305,
        "bts": "BTS ทองหล่อ",
        "aliases": ["ideo q", "ไอดีโอ"],
    },
    {
        "slug": "hyde-sukhumvit-11",
        "name_th": "ไฮด์ สุขุมวิท 11",
        "name_en": "Hyde Sukhumvit 11",
        "district": "วัฒนา",
        "lat": 13.743641,
        "lng": 100.556536,
        "bts": "BTS นานา",
        "aliases": ["hyde 11", "นานา", "nana"],
    },
    {
        "slug": "the-room-sukhumvit-38",
        "name_th": "เดอะ รูม สุขุมวิท 38",
        "name_en": "The Room Sukhumvit 38",
        "district": "คลองเตย",
        "lat": 13.716981,
        "lng": 100.579988,
        "bts": "BTS ทองหล่อ",
        "aliases": ["the room 38"],
    },
    {
        "slug": "aspire-sukhumvit-48",
        "name_th": "แอสไพร์ สุขุมวิท 48",
        "name_en": "Aspire Sukhumvit 48",
        "district": "คลองเตย",
        "lat": 13.711081,
        "lng": 100.593920,
        "bts": "BTS พร้อมพงษ์",
        "aliases": ["aspire 48", "พร้อมพงษ์"],
    },
    {
        "slug": "lumpini-place-rama9",
        "name_th": "ลุมพินี เพลส พระราม 9",
        "name_en": "Lumpini Place Rama 9",
        "district": "ห้วยขวาง",
        "lat": 13.756149,
        "lng": 100.571142,
        "bts": "MRT พระราม 9",
        "aliases": ["ลุมพินี พระราม 9", "rama 9"],
    },
    {
        "slug": "siamese-exclusive-queens",
        "name_th": "ไซมิส เอ็กซ์คลูซีฟ ควีนส์",
        "name_en": "Siamese Exclusive Queens",
        "district": "คลองเตย",
        "lat": 13.723233,
        "lng": 100.561119,
        "bts": "BTS ทองหล่อ",
        "aliases": ["siamese queens"],
    },
    {
        "slug": "the-tree-sukhumvit-71",
        "name_th": "เดอะ ทรี สุขุมวิท 71",
        "name_en": "The Tree Sukhumvit 71",
        "district": "วัฒนา",
        "lat": 13.740614,
        "lng": 100.599997,
        "bts": "BTS บางจาก",
        "aliases": ["the tree 71"],
    },
    {
        "slug": "u-delight-bangna",
        "name_th": "ยู ดีไลท์ บางนา",
        "name_en": "U Delight Bangna",
        "district": "บางนา",
        "lat": 13.668200,
        "lng": 100.604500,
        "bts": "BTS บางนา",
        "aliases": ["u delight", "บางนา", "bangna"],
    },
    {
        "slug": "the-key-wutthakat",
        "name_th": "เดอะ คีย์ BTS วุฒากาศ",
        "name_en": "The Key BTS Wutthakat",
        "district": "บางบอน",
        "lat": 13.714112,
        "lng": 100.468207,
        "bts": "BTS วุฒากาศ",
        "aliases": ["the key wutthakat"],
    },
    {
        "slug": "ideo-mobi-sukhumvit-81",
        "name_th": "ไอดีโอ โมบิ สุขุมวิท 81",
        "name_en": "Ideo Mobi Sukhumvit 81",
        "district": "บางนา",
        "lat": 13.704654,
        "lng": 100.602019,
        "bts": "BTS บางจาก",
        "aliases": ["ideo mobi 81"],
    },
    {
        "slug": "the-address-asoke",
        "name_th": "ดิ แอดเดรส อโศก",
        "name_en": "The Address Asoke",
        "district": "วัฒนา",
        "lat": 13.749328,
        "lng": 100.561926,
        "bts": "BTS อโศก",
        "aliases": ["address asoke", "แอดเดรส"],
    },
    {
        "slug": "m-neighborhood-ari",
        "name_th": "เอ็ม นีโบฮู้ด อารีย์",
        "name_en": "M Neighborhood Ari",
        "district": "พญาไท",
        "lat": 13.779689,
        "lng": 100.544646,
        "bts": "BTS อารีย์",
        "aliases": ["ari", "อารีย์", "m neighborhood"],
    },
    {
        "slug": "villa-bangna-townhome",
        "name_th": "วิลล่า บางนา",
        "name_en": "Villa Bangna Townhome",
        "district": "บางนา",
        "lat": 13.674863,
        "lng": 100.599097,
        "bts": "BTS บางนา",
        "aliases": ["วิลล่า บางนา"],
        "property_type": "townhouse",
    },
    {
        "slug": "sansiri-house-onnut",
        "name_th": "บ้านเดี่ยว อ่อนนุช",
        "name_en": "Detached House On Nut",
        "district": "สวนหลวง",
        "lat": 13.712898,
        "lng": 100.600884,
        "bts": "BTS อ่อนนุช",
        "aliases": ["บ้าน", "onnut", "อ่อนนุช"],
        "property_type": "house",
    },
]

# RealXtate station catalog (labels that have coords). slug used for geo_zone hints.
RX_STATIONS: dict[str, dict[str, Any]] = {
    "BTS หมอชิต": {"slug": "bts-mo-chit", "lat": 13.8027, "lng": 100.5540, "geo_zone": "ari"},
    "BTS อารีย์": {"slug": "bts-ari", "lat": 13.7797, "lng": 100.5448, "geo_zone": "ari"},
    "BTS สนามเป้า": {"slug": "bts-sanam-pao", "lat": 13.7728, "lng": 100.5448, "geo_zone": "ari"},
    "BTS อนุสาวรีย์ชัยฯ": {
        "slug": "bts-victory-monument",
        "lat": 13.7651,
        "lng": 100.5370,
        "geo_zone": None,
    },
    "BTS พญาไท": {"slug": "bts-phaya-thai", "lat": 13.7569, "lng": 100.5347, "geo_zone": None},
    "BTS ราชเทวี": {"slug": "bts-ratchathewi", "lat": 13.7519, "lng": 100.5316, "geo_zone": None},
    "BTS สยาม": {"slug": "bts-siam", "lat": 13.7456, "lng": 100.5341, "geo_zone": "asok"},
    "BTS ชิดลม": {"slug": "bts-chit-lom", "lat": 13.7445, "lng": 100.5430, "geo_zone": None},
    "BTS เพลินจิต": {"slug": "bts-phloen-chit", "lat": 13.7431, "lng": 100.5488, "geo_zone": None},
    "BTS นานา": {"slug": "bts-nana", "lat": 13.7405, "lng": 100.5553, "geo_zone": "asok"},
    "BTS อโศก": {"slug": "bts-asok", "lat": 13.7373, "lng": 100.5606, "geo_zone": "asok"},
    "BTS พร้อมพงษ์": {
        "slug": "bts-phrom-phong",
        "lat": 13.7305,
        "lng": 100.5693,
        "geo_zone": "sukhumvit",
    },
    "BTS ทองหล่อ": {"slug": "bts-thong-lo", "lat": 13.7242, "lng": 100.5784, "geo_zone": "thonglor"},
    "BTS เอกมัย": {"slug": "bts-ekkamai", "lat": 13.7195, "lng": 100.5851, "geo_zone": "thonglor"},
    "BTS อ่อนนุช": {"slug": "bts-on-nut", "lat": 13.7056, "lng": 100.6011, "geo_zone": "onnut"},
    "BTS บางจาก": {"slug": "bts-bang-chak", "lat": 13.6967, "lng": 100.6055, "geo_zone": None},
    "BTS แบริ่ง": {"slug": "bts-bearing", "lat": 13.6687, "lng": 100.6018, "geo_zone": "bangna"},
    "BTS สำโรง": {"slug": "bts-samrong", "lat": 13.6462, "lng": 100.5956, "geo_zone": "bangna"},
    "BTS บางนา": {"slug": "bts-bang-na", "lat": 13.6687, "lng": 100.6018, "geo_zone": "bangna"},
    "BTS สนามกีฬาแห่งชาติ": {
        "slug": "bts-national-stadium",
        "lat": 13.7468,
        "lng": 100.5292,
        "geo_zone": None,
    },
    "BTS ราชดำริ": {"slug": "bts-ratchadamri", "lat": 13.7396, "lng": 100.5345, "geo_zone": None},
    "BTS ศาลาแดง": {"slug": "bts-sala-daeng", "lat": 13.7284, "lng": 100.5342, "geo_zone": "silom"},
    "BTS ช่องนนทรี": {"slug": "bts-chong-nonsi", "lat": 13.7236, "lng": 100.5294, "geo_zone": "silom"},
    "BTS สุรศักดิ์": {"slug": "bts-surasak", "lat": 13.7199, "lng": 100.5234, "geo_zone": "silom"},
    "BTS สะพานตากสิน": {
        "slug": "bts-saphan-taksin",
        "lat": 13.7188,
        "lng": 100.5141,
        "geo_zone": None,
    },
    "BTS กรุงธนบุรี": {
        "slug": "bts-krung-thon-buri",
        "lat": 13.7210,
        "lng": 100.5057,
        "geo_zone": None,
    },
    "BTS วงเวียนใหญ่": {
        "slug": "bts-wongwian-yai",
        "lat": 13.7209,
        "lng": 100.4953,
        "geo_zone": None,
    },
    "MRT สุขุมวิท": {"slug": "mrt-sukhumvit", "lat": 13.7386, "lng": 100.5613, "geo_zone": "asok"},
    "MRT สีลม": {"slug": "mrt-silom", "lat": 13.7297, "lng": 100.5368, "geo_zone": "silom"},
    "MRT ลุมพินี": {"slug": "mrt-lumphini", "lat": 13.7278, "lng": 100.5458, "geo_zone": None},
    "MRT คลองเตย": {"slug": "mrt-khlong-toei", "lat": 13.7224, "lng": 100.5539, "geo_zone": None},
    "MRT ศูนย์สิริกิติ์": {
        "slug": "mrt-queen-sirikit",
        "lat": 13.7220,
        "lng": 100.5600,
        "geo_zone": None,
    },
    "MRT พระราม 9": {"slug": "mrt-phra-ram-9", "lat": 13.7587, "lng": 100.5650, "geo_zone": "rama-9"},
    "MRT ศูนย์วัฒนธรรม": {
        "slug": "mrt-thailand-cultural-centre",
        "lat": 13.7655,
        "lng": 100.5704,
        "geo_zone": "huai-khwang",
    },
    "MRT ห้วยขวาง": {
        "slug": "mrt-huai-khwang",
        "lat": 13.7785,
        "lng": 100.5736,
        "geo_zone": "huai-khwang",
    },
    "MRT สุทธิสาร": {"slug": "mrt-sutthisan", "lat": 13.7895, "lng": 100.5741, "geo_zone": None},
    "MRT ลาดพร้าว": {"slug": "mrt-lat-phrao", "lat": 13.8060, "lng": 100.5734, "geo_zone": "ladprao"},
    "MRT พหลโยธิน": {"slug": "mrt-phahon-yothin", "lat": 13.8140, "lng": 100.5700, "geo_zone": None},
    "MRT สวนจตุจักร": {"slug": "mrt-chatuchak-park", "lat": 13.8029, "lng": 100.5532, "geo_zone": None},
    "MRT กำแพงเพชร": {"slug": "mrt-kamphaeng-phet", "lat": 13.7982, "lng": 100.5489, "geo_zone": None},
    "MRT บางซื่อ": {"slug": "mrt-bang-sue", "lat": 13.8038, "lng": 100.5392, "geo_zone": None},
    "MRT หัวลำโพง": {"slug": "mrt-hua-lamphong", "lat": 13.7378, "lng": 100.5174, "geo_zone": None},
    "MRT เตาปูน": {"slug": "mrt-tao-poon", "lat": 13.8061, "lng": 100.5304, "geo_zone": None},
    "MRT บางหว้า": {"slug": "mrt-bang-wa", "lat": 13.7202, "lng": 100.4572, "geo_zone": None},
    "ARL มักกะสัน": {"slug": "arl-makkasan", "lat": 13.7510, "lng": 100.5608, "geo_zone": "asok"},
    "ARL รามคำแหง": {"slug": "arl-ramkhamhaeng", "lat": 13.7488, "lng": 100.5997, "geo_zone": None},
}

# Pantip label → RealXtate canonical label (only when coords exist or alias of existing).
STATION_LABEL_NORMALIZE: dict[str, str] = {
    "BTS อนุสาวรีย์": "BTS อนุสาวรีย์ชัยฯ",
    "BTS อนุสาวรีย์ชัย": "BTS อนุสาวรีย์ชัยฯ",
    "MRT ศูนย์วัฒนธรรมแห่งประเทศไทย": "MRT ศูนย์วัฒนธรรม",
    "MRT ศูนย์ประชุมแห่งชาติสิริกิติ์": "MRT ศูนย์สิริกิติ์",
    "MRT เพชรบุรี": "MRT เพชรบุรี",  # not in RX coords — keep label only
    "BTS พระโขนง": "BTS พระโขนง",
    "BTS ปุณณวิถี": "BTS ปุณณวิถี",
    "BTS อุดมสุข": "BTS อุดมสุข",
    "BTS วุฒากาศ": "BTS วุฒากาศ",
    "MRT รัชดาภิเษก": "MRT รัชดาภิเษก",
}

ZONE_TO_DISTRICT: dict[str, str] = {
    "ทองหล่อ": "วัฒนา",
    "เอกมัย": "วัฒนา",
    "อโศก": "วัฒนา",
    "นานา": "วัฒนา",
    "พร้อมพงษ์": "คลองเตย",
    "สุขุมวิท": "วัฒนา",
    "เพชรบุรีตัดใหม่": "ราชเทวี",
    "RCA": "ห้วยขวาง",
    "พระราม 9": "ห้วยขวาง",
    "รัชดา": "ห้วยขวาง",
    "ห้วยขวาง": "ห้วยขวาง",
    "ลาดพร้าว": "ลาดพร้าว",
    "บางนา": "บางนา",
    "อ่อนนุช": "สวนหลวง",
    "อุดมสุข": "บางนา",
    "สาทร": "สาทร",
    "สีลม": "บางรัก",
    "อารีย์": "พญาไท",
    "วิทยุ": "ปทุมวัน",
    "ชิดลม": "ปทุมวัน",
    "สามย่าน": "ปทุมวัน",
    "รามคำแหง": "บางกะปิ",
    "มักกะสัน": "ราชเทวี",
    "เจริญนคร": "คลองสาน",
    "วงเวียนใหญ่": "ธนบุรี",
}

ZONE_TO_GEO_ZONE: dict[str, str] = {
    "ทองหล่อ": "thonglor",
    "เอกมัย": "thonglor",
    "อโศก": "asok",
    "นานา": "asok",
    "พร้อมพงษ์": "sukhumvit",
    "สุขุมวิท": "sukhumvit",
    "พระราม 9": "rama-9",
    "รัชดา": "huai-khwang",
    "ห้วยขวาง": "huai-khwang",
    "ลาดพร้าว": "ladprao",
    "บางนา": "bangna",
    "อ่อนนุช": "onnut",
    "อุดมสุข": "onnut",
    "สาทร": "silom",
    "สีลม": "silom",
    "อารีย์": "ari",
}

NAME_RE = re.compile(r"^(?P<en>.+?)\s*\((?P<th>[^)]+)\)\s*$")
NON_ALNUM = re.compile(r"[^a-z0-9]+")


def discover_pantip_root(explicit: str | None) -> Path:
    candidates: list[Path] = []
    if explicit:
        candidates.append(Path(explicit).expanduser())
    env = __import__("os").environ.get("PANTIP_ROOT")
    if env:
        candidates.append(Path(env).expanduser())
    candidates.extend(
        [
            Path("/tmp/pantip-property-hub"),
            Path("/tmp/pantip-property-automation"),
            ROOT.parent / "pantip-property-hub",
            ROOT.parent / "pantip-property-automation",
            Path.home() / "Projects" / "pantip-property-automation",
            Path("/Users/angkarn1996/Projects/pantip-property-automation"),
        ]
    )
    for c in candidates:
        if (c / "data" / "projects.json").is_file():
            return c
    raise SystemExit(
        "Pantip source not found. Pass --pantip-root or set PANTIP_ROOT "
        "(needs data/projects.json)."
    )


def norm_key(s: str) -> str:
    s = unicodedata.normalize("NFKC", s or "").strip().lower()
    s = s.replace("–", "-").replace("—", "-").replace("‐", "-")
    s = re.sub(r"\s+", " ", s)
    return s


def compact_key(s: str) -> str:
    return re.sub(r"[^a-z0-9ก-๙]+", "", norm_key(s))


def slugify(bucket_key: str, fallback: str) -> str:
    raw = (bucket_key or fallback or "").strip().lower().replace("_", "-")
    raw = NON_ALNUM.sub("-", raw)
    raw = re.sub(r"-+", "-", raw).strip("-")
    if len(raw) < 2:
        raw = NON_ALNUM.sub("-", norm_key(fallback)).strip("-")
    return raw[:80] or "project"


def parse_canonical_name(canonical: str) -> tuple[str, str]:
    m = NAME_RE.match((canonical or "").strip())
    if m:
        return m.group("th").strip(), m.group("en").strip()
    # Thai-only or EN-only
    text = (canonical or "").strip()
    if re.search(r"[ก-๙]", text) and not re.search(r"[A-Za-z]", text):
        return text, text
    return text, text


def normalize_station_label(label: str) -> str:
    t = re.sub(r"\s+", " ", (label or "").strip())
    t = STATION_LABEL_NORMALIZE.get(t, t)
    # Fix common Pantip variants
    t = t.replace("BTS Ekkamai", "BTS เอกมัย").replace("BTS Thonglor", "BTS ทองหล่อ")
    if t in RX_STATIONS:
        return t
    # Match by station name ignoring system prefix mismatches when unique
    name = t.split(" ", 1)[-1] if " " in t else t
    hits = [k for k in RX_STATIONS if k.split(" ", 1)[-1] == name]
    if len(hits) == 1:
        return hits[0]
    return t


def map_stations(labels: list[str]) -> tuple[list[str], list[str], str | None]:
    """Return (nearby labels kept, mapped RX labels, primary bts)."""
    nearby: list[str] = []
    mapped: list[str] = []
    seen: set[str] = set()
    for raw in labels:
        label = normalize_station_label(raw)
        if not label or label in seen:
            continue
        seen.add(label)
        nearby.append(label)
        if label in RX_STATIONS:
            mapped.append(label)
    primary = mapped[0] if mapped else (nearby[0] if nearby else None)
    return nearby, mapped, primary


# Zone / station tokens that must never alone match a bootstrap project.
_GENERIC_BOOTSTRAP_KEYS = {
    "thonglor",
    "ทองหล่อ",
    "asok",
    "asoke",
    "อโศก",
    "ekkamai",
    "เอกมัย",
    "nana",
    "นานา",
    "bangna",
    "บางนา",
    "ari",
    "อารีย์",
    "onnut",
    "อ่อนนุช",
    "rama9",
    "rama 9",
    "พร้อมพงษ์",
    "trendy",
    "บ้าน",
}


def _is_strong_key(key: str) -> bool:
    k = (key or "").strip()
    if len(k) < 5:
        return False
    if k in _GENERIC_BOOTSTRAP_KEYS:
        return False
    if compact_key(k) in {compact_key(x) for x in _GENERIC_BOOTSTRAP_KEYS}:
        return False
    return True


def build_bootstrap_index() -> dict[str, dict[str, Any]]:
    """Index only strong identifiers (slug + full names + distinctive aliases)."""
    idx: dict[str, dict[str, Any]] = {}
    for b in BOOTSTRAP:
        keys = {
            norm_key(b["slug"]),
            compact_key(b["slug"]),
            norm_key(b["name_th"]),
            norm_key(b["name_en"]),
            compact_key(b["name_th"]),
            compact_key(b["name_en"]),
        }
        # thru ↔ true spelling used in Pantip bucket keys
        if b["slug"] == "true-thonglor":
            keys.update(
                {
                    "thru-thonglor",
                    "thruthonglor",
                    "truethonglor",
                    compact_key("thru thonglor"),
                    compact_key("thru thonglor ทรู ทองหล่อ"),
                }
            )
        for a in b.get("aliases") or []:
            if _is_strong_key(norm_key(a)):
                keys.add(norm_key(a))
                keys.add(compact_key(a))
        for k in keys:
            if k and _is_strong_key(k):
                idx[k] = b
    return idx


def find_bootstrap(
    idx: dict[str, dict[str, Any]],
    *,
    slug: str,
    name_th: str,
    name_en: str,
    aliases: list[str],
    bucket_key: str,
) -> dict[str, Any] | None:
    candidates = [
        norm_key(slug),
        compact_key(slug),
        norm_key(bucket_key.replace("_", "-")),
        compact_key(bucket_key),
        norm_key(name_th),
        norm_key(name_en),
        compact_key(name_th),
        compact_key(name_en),
    ]
    # Only strong project-name aliases — never zone tokens
    for a in aliases:
        na, ca = norm_key(a), compact_key(a)
        if _is_strong_key(na):
            candidates.append(na)
        if _is_strong_key(ca):
            candidates.append(ca)

    for c in candidates:
        if c in idx:
            return idx[c]

    # Fuzzy: bootstrap EN name contained in Pantip EN (or reverse), min length 8
    en = norm_key(name_en)
    th = norm_key(name_th)
    for b in BOOTSTRAP:
        ben, bth = norm_key(b["name_en"]), norm_key(b["name_th"])
        if len(ben) >= 8 and (ben in en or en in ben):
            return b
        if len(bth) >= 6 and (bth in th or th in bth):
            return b
    return None


def reverse_alias_map(alias_doc: dict[str, Any]) -> dict[str, list[str]]:
    """bucket-ish compact key → extra display aliases."""
    out: dict[str, list[str]] = {}
    variant = alias_doc.get("variant_to_canonical") or {}
    # Invert: canonical compact → variants that look like human names
    canon_to_variants: dict[str, list[str]] = {}
    for variant_key, canon in variant.items():
        canon_to_variants.setdefault(str(canon), []).append(str(variant_key))
    for canon, variants in canon_to_variants.items():
        extras: list[str] = []
        for v in variants:
            if re.search(r"[A-Za-zก-๙].*[ (]", v) or " " in v or "(" in v:
                extras.append(v.strip())
            elif re.search(r"[ก-๙]", v) and len(v) >= 4:
                extras.append(v.strip())
        if extras:
            out[compact_key(canon)] = extras
            out[norm_key(canon)] = extras
    return out


def sql_escape(s: str) -> str:
    return s.replace("'", "''")


def sql_text_array(items: list[str]) -> str:
    if not items:
        return "ARRAY[]::text[]"
    return "ARRAY[" + ", ".join(f"'{sql_escape(x)}'" for x in items) + "]::text[]"


def transform_project(
    raw: dict[str, Any],
    *,
    bootstrap_idx: dict[str, dict[str, Any]],
    alias_extras: dict[str, list[str]],
) -> dict[str, Any]:
    canonical = raw.get("canonical_name") or ""
    name_th, name_en = parse_canonical_name(canonical)
    bucket = raw.get("bucket_key") or ""
    slug = slugify(bucket, name_en or name_th)

    aliases = [a for a in (raw.get("aliases") or []) if isinstance(a, str) and a.strip()]
    # Include compact / human variants from project_aliases.json
    for key in (compact_key(bucket), norm_key(bucket), compact_key(name_en), compact_key(name_th)):
        for extra in alias_extras.get(key, []):
            if extra not in aliases and extra != canonical:
                aliases.append(extra)

    # Always keep short EN/TH stems useful for search
    for stem in (name_en, name_th, canonical):
        if stem and stem not in aliases:
            aliases.append(stem)

    # Dedupe aliases (case-insensitive) keep order, cap size
    seen_a: set[str] = set()
    clean_aliases: list[str] = []
    for a in aliases:
        k = norm_key(a)
        if not k or k in seen_a:
            continue
        # Drop pure transit/zone noise from project aliases
        if re.match(r"^(bts|mrt|arl)\b", k):
            continue
        seen_a.add(k)
        clean_aliases.append(a.strip())
        if len(clean_aliases) >= 24:
            break

    transit_src = list(raw.get("transit_verified") or []) or list(
        raw.get("transit_unverified") or []
    )
    nearby, mapped, primary = map_stations(transit_src)

    zones = list(raw.get("zone_verified") or []) or list(raw.get("zone_unverified") or [])
    zone0 = zones[0] if zones else None
    district = ZONE_TO_DISTRICT.get(zone0 or "", "") or (zone0 or "กรุงเทพฯ")
    geo_zone = ZONE_TO_GEO_ZONE.get(zone0 or "")
    if not geo_zone and primary and primary in RX_STATIONS:
        geo_zone = RX_STATIONS[primary].get("geo_zone")

    boot = find_bootstrap(
        bootstrap_idx,
        slug=slug,
        name_th=name_th,
        name_en=name_en,
        aliases=clean_aliases,
        bucket_key=bucket,
    )

    lat: float | None = None
    lng: float | None = None
    coords_source = "none"
    if boot:
        slug = boot["slug"]  # preserve RealXtate bootstrap slug
        lat = float(boot["lat"])
        lng = float(boot["lng"])
        coords_source = "bootstrap"
        district = boot.get("district") or district
        if boot.get("bts") and not primary:
            primary = str(boot["bts"]).split("/")[0].strip()
        # Merge bootstrap aliases
        for a in boot.get("aliases") or []:
            if norm_key(a) not in seen_a:
                clean_aliases.append(a)
                seen_a.add(norm_key(a))
    elif mapped:
        st = RX_STATIONS[mapped[0]]
        lat = float(st["lat"])
        lng = float(st["lng"])
        coords_source = "transit_approx"

    bts_station = primary
    if boot and boot.get("bts") and coords_source == "bootstrap":
        # Prefer curated bootstrap label when present
        bts_station = str(boot["bts"])

    return {
        "slug": slug,
        "name_th": name_th,
        "name_en": name_en,
        "district": district,
        "bts_station": bts_station,
        "nearby_transit": nearby,
        "aliases": clean_aliases,
        "property_type": boot.get("property_type", "condo") if boot else "condo",
        "lat": lat,
        "lng": lng,
        "coords_source": coords_source,
        "geo_zone_slug": geo_zone,
        "zone_tags": zones[:8],
        "source_platform": "pantip_curated",
        "source_external_id": raw.get("id") or bucket or slug,
        "location_status": raw.get("location_status"),
        "bucket_key": bucket,
        "is_active": True,
    }


def write_sql(rows: list[dict[str, Any]], path: Path) -> None:
    lines = [
        "-- Generated by scripts/import-pantip-projects.py",
        "-- Curated Pantip hub derivative → property_projects upsert by slug",
        "-- Does not redistribute LivingInsider HTML/cache.",
        "",
    ]
    conflict = """ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = COALESCE(NULLIF(EXCLUDED.district, ''), public.property_projects.district),
  bts_station = COALESCE(EXCLUDED.bts_station, public.property_projects.bts_station),
  nearby_transit = CASE
    WHEN cardinality(EXCLUDED.nearby_transit) > 0 THEN EXCLUDED.nearby_transit
    ELSE public.property_projects.nearby_transit
  END,
  aliases = CASE
    WHEN cardinality(EXCLUDED.aliases) >= cardinality(public.property_projects.aliases)
      THEN EXCLUDED.aliases
    ELSE public.property_projects.aliases
  END,
  lat = COALESCE(public.property_projects.lat, EXCLUDED.lat),
  lng = COALESCE(public.property_projects.lng, EXCLUDED.lng),
  location = COALESCE(public.property_projects.location, EXCLUDED.location),
  geo_zone_id = COALESCE(public.property_projects.geo_zone_id, EXCLUDED.geo_zone_id),
  source_platform = CASE
    WHEN public.property_projects.source_platform IN ('manual', 'pantip_curated', '')
      THEN 'pantip_curated'
    ELSE public.property_projects.source_platform
  END,
  source_external_id = COALESCE(
    public.property_projects.source_external_id, EXCLUDED.source_external_id
  ),
  admin_notes = COALESCE(public.property_projects.admin_notes, EXCLUDED.admin_notes),
  updated_at = now();"""
    for r in rows:
        lat_sql = "NULL" if r["lat"] is None else str(r["lat"])
        lng_sql = "NULL" if r["lng"] is None else str(r["lng"])
        if r["lat"] is not None and r["lng"] is not None:
            loc_sql = (
                f"ST_SetSRID(ST_MakePoint({r['lng']}, {r['lat']}), 4326)::geography"
            )
        else:
            loc_sql = "NULL"
        bts = "NULL" if not r["bts_station"] else f"'{sql_escape(r['bts_station'])}'"
        gz = r.get("geo_zone_slug")
        gz_sql = (
            f"(SELECT id FROM public.geo_zones WHERE slug = '{sql_escape(gz)}' LIMIT 1)"
            if gz
            else "NULL"
        )
        notes = sql_escape(
            f"pantip_curated; coords={r['coords_source']}; bucket={r.get('bucket_key') or ''}"
        )
        lines.append(
            f"""
INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, nearby_transit, property_type,
  lat, lng, location, aliases, source_platform, source_external_id, admin_notes,
  geo_zone_id, is_active
) VALUES (
  '{sql_escape(r['slug'])}',
  '{sql_escape(r['name_th'])}',
  '{sql_escape(r['name_en'])}',
  '{sql_escape(r['district'])}',
  {bts},
  {sql_text_array(r['nearby_transit'])},
  '{sql_escape(r['property_type'])}',
  {lat_sql},
  {lng_sql},
  {loc_sql},
  {sql_text_array(r['aliases'])},
  'pantip_curated',
  '{sql_escape(str(r['source_external_id']))}',
  '{notes}',
  {gz_sql},
  true
)
{conflict}
""".strip()
        )
        lines.append("")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--pantip-root", default=None, help="Path to pantip-property-* repo")
    ap.add_argument("--out-dir", default=str(OUT_DIR))
    ap.add_argument("--limit", type=int, default=0, help="Optional cap for debug")
    ap.add_argument("--skip-sql", action="store_true")
    args = ap.parse_args()

    pantip = discover_pantip_root(args.pantip_root)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    projects_path = pantip / "data" / "projects.json"
    aliases_path = pantip / "data" / "project_aliases.json"
    projects = json.loads(projects_path.read_text(encoding="utf-8"))
    alias_doc = (
        json.loads(aliases_path.read_text(encoding="utf-8"))
        if aliases_path.is_file()
        else {}
    )
    if not isinstance(projects, list):
        raise SystemExit("projects.json must be a list")

    if args.limit and args.limit > 0:
        projects = projects[: args.limit]

    bootstrap_idx = build_bootstrap_index()
    alias_extras = reverse_alias_map(alias_doc)

    rows = [
        transform_project(p, bootstrap_idx=bootstrap_idx, alias_extras=alias_extras)
        for p in projects
        if isinstance(p, dict)
    ]

    # Deduplicate by slug (keep richer aliases / coords)
    by_slug: dict[str, dict[str, Any]] = {}
    for r in rows:
        prev = by_slug.get(r["slug"])
        if not prev:
            by_slug[r["slug"]] = r
            continue
        # merge
        aliases = list(dict.fromkeys([*(prev["aliases"] or []), *(r["aliases"] or [])]))[:24]
        nearby = list(
            dict.fromkeys([*(prev["nearby_transit"] or []), *(r["nearby_transit"] or [])])
        )
        prefer = r if (prev["lat"] is None and r["lat"] is not None) else prev
        prefer = {
            **prefer,
            "aliases": aliases,
            "nearby_transit": nearby,
            "bts_station": prefer.get("bts_station") or r.get("bts_station"),
        }
        if prefer["lat"] is None and r["lat"] is not None:
            prefer["lat"] = r["lat"]
            prefer["lng"] = r["lng"]
            prefer["coords_source"] = r["coords_source"]
        by_slug[r["slug"]] = prefer

    final_rows = sorted(by_slug.values(), key=lambda x: x["name_th"] or x["slug"])

    seed_path = out_dir / "property_projects_seed.json"
    seed_path.write_text(
        json.dumps(final_rows, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    coords = Counter(r["coords_source"] for r in final_rows)
    with_transit = sum(1 for r in final_rows if r["nearby_transit"])
    with_mapped = sum(
        1 for r in final_rows if any(t in RX_STATIONS for t in r["nearby_transit"])
    )
    with_coords = sum(1 for r in final_rows if r["lat"] is not None)
    report = {
        "source_root": str(pantip),
        "source_projects": len(projects),
        "seed_projects": len(final_rows),
        "with_nearby_transit": with_transit,
        "with_nearby_transit_pct": round(100.0 * with_transit / max(len(final_rows), 1), 2),
        "with_rx_transit_map": with_mapped,
        "with_rx_transit_map_pct": round(100.0 * with_mapped / max(len(final_rows), 1), 2),
        "with_coords": with_coords,
        "with_coords_pct": round(100.0 * with_coords / max(len(final_rows), 1), 2),
        "coords_source_counts": dict(coords),
        "bootstrap_matched": coords.get("bootstrap", 0),
        "notes": [
            "source_platform=pantip_curated",
            "coords null/transit_approx until Places geocode pass",
            "does not include properties.json / Living cache",
        ],
    }
    (out_dir / "coverage_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    if not args.skip_sql:
        write_sql(final_rows, out_dir / "property_projects_seed.sql")

    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(f"Wrote {seed_path}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
