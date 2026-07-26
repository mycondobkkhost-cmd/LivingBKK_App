#!/usr/bin/env python3
"""Rebuild property_projects nearby_transit / bts_station / aliases from coordinates.

Removes polluted station names from aliases (e.g. Hive Taksin + อ่อนนุช)
and re-links only stations that are actually near the project pin.
"""
from __future__ import annotations

import json
import math
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENV_FILE = ROOT / ".env.local"

# Mirror supabase/functions/_shared/transit_proximity.ts
STATIONS = [
    ("BTS", "หมอชิต", "Mo Chit", 13.8027, 100.5540),
    ("BTS", "อารีย์", "Ari", 13.7797, 100.5448),
    ("BTS", "สนามเป้า", "Sanam Pao", 13.7728, 100.5448),
    ("BTS", "อนุสาวรีย์ชัยฯ", "Victory Monument", 13.7651, 100.5370),
    ("BTS", "พญาไท", "Phaya Thai", 13.7569, 100.5347),
    ("BTS", "ราชเทวี", "Ratchathewi", 13.7519, 100.5316),
    ("BTS", "สยาม", "Siam", 13.7456, 100.5341),
    ("BTS", "ชิดลม", "Chit Lom", 13.7445, 100.5430),
    ("BTS", "เพลินจิต", "Phloen Chit", 13.7431, 100.5488),
    ("BTS", "นานา", "Nana", 13.7405, 100.5553),
    ("BTS", "อโศก", "Asok", 13.7373, 100.5606),
    ("BTS", "พร้อมพงษ์", "Phrom Phong", 13.7305, 100.5693),
    ("BTS", "ทองหล่อ", "Thong Lo", 13.7242, 100.5784),
    ("BTS", "เอกมัย", "Ekkamai", 13.7195, 100.5851),
    ("BTS", "อ่อนนุช", "On Nut", 13.7056, 100.6011),
    ("BTS", "บางจาก", "Bang Chak", 13.6967, 100.6055),
    ("BTS", "แบริ่ง", "Bearing", 13.6687, 100.6018),
    ("BTS", "สำโรง", "Samrong", 13.6462, 100.5956),
    ("BTS", "สนามกีฬาแห่งชาติ", "National Stadium", 13.7468, 100.5292),
    ("BTS", "ราชดำริ", "Ratchadamri", 13.7396, 100.5345),
    ("BTS", "ศาลาแดง", "Sala Daeng", 13.7284, 100.5342),
    ("BTS", "ช่องนนทรี", "Chong Nonsi", 13.7236, 100.5294),
    ("BTS", "สุรศักดิ์", "Surasak", 13.7199, 100.5234),
    ("BTS", "สะพานตากสิน", "Saphan Taksin", 13.7188, 100.5141),
    ("MRT", "สุขุมวิท", "Sukhumvit", 13.7386, 100.5613),
    ("MRT", "สีลม", "Silom", 13.7297, 100.5368),
    ("MRT", "ลุมพินี", "Lumphini", 13.7278, 100.5458),
    ("MRT", "คลองเตย", "Khlong Toei", 13.7224, 100.5539),
    ("MRT", "ศูนย์สิริกิติ์", "Queen Sirikit", 13.7220, 100.5600),
    ("MRT", "พระราม 9", "Phra Ram 9", 13.7587, 100.5650),
    ("MRT", "ห้วยขวาง", "Huai Khwang", 13.7785, 100.5736),
    ("MRT", "ลาดพร้าว", "Lat Phrao", 13.8060, 100.5734),
    ("MRT", "บางซื่อ", "Bang Sue", 13.8038, 100.5392),
    ("MRT", "หัวลำโพง", "Hua Lamphong", 13.7378, 100.5174),
    ("ARL", "มักกะสัน", "Makkasan", 13.7510, 100.5608),
]

GEO_ZONES = [
    ("thonglor", 13.722, 100.582, 1.2),
    ("sukhumvit-mid", 13.728, 100.576, 1.2),
    ("asok", 13.738, 100.561, 1.2),
    ("sukhumvit-early", 13.742, 100.552, 1.2),
    ("bangna", 13.668, 100.602, 1.5),
    ("ari", 13.780, 100.545, 1.2),
    ("silom", 13.726, 100.532, 1.2),
    ("rama-9", 13.760, 100.568, 1.2),
    ("ladprao", 13.800, 100.573, 1.2),
    ("onnut", 13.700, 100.603, 1.2),
    ("huai-khwang", 13.7785, 100.5736, 1.2),
]

NEARBY_KM = 1.5
FALLBACK_KM = 2.5
NEARBY_LIMIT = 3

# พิกัดผิดชัดเจน — แก้ก่อนคำนวณสถานีใกล้เคียง
COORD_FIXES = {
    # Hive Taksin อยู่โซนสะพานตากสิน ไม่ใช่คลองสานฝั่งไกล
    "hive-taksin": (13.71905, 100.51385),
}

TRANSIT_TOKENS: set[str] = set()
for system, name_th, name_en, *_ in STATIONS:
    TRANSIT_TOKENS.add(name_th)
    TRANSIT_TOKENS.add(name_en)
    TRANSIT_TOKENS.add(f"{system} {name_th}")
    TRANSIT_TOKENS.add(f"{system} {name_en}")
    TRANSIT_TOKENS.add(name_th.lower())
    TRANSIT_TOKENS.add(name_en.lower())


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip().strip('"').strip("'")
    # also allow process env
    for k in ("SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY", "SUPABASE_ANON_KEY"):
        if k in os.environ:
            env[k] = os.environ[k]
    return env


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371.0
    p = math.pi / 180
    a = (
        math.sin((lat2 - lat1) * p / 2) ** 2
        + math.cos(lat1 * p)
        * math.cos(lat2 * p)
        * math.sin((lng2 - lng1) * p / 2) ** 2
    )
    return 2 * r * math.asin(math.sqrt(a))


def transit_slug(system: str, name_en: str) -> str:
    sys = re.sub(r"[^a-z0-9]", "", system.lower())
    name = re.sub(r"[^a-z0-9]+", "-", name_en.lower()).strip("-")
    return f"{sys}-{name}"


def nearby_stations(lat: float, lng: float) -> list[tuple[str, str, float]]:
    """Return (label_th, tag_slug, km) sorted by distance."""
    hits = []
    for system, name_th, name_en, slat, slng in STATIONS:
        km = haversine_km(lat, lng, slat, slng)
        hits.append((f"{system} {name_th}", transit_slug(system, name_en), km))
    hits.sort(key=lambda x: x[2])
    near = [h for h in hits if h[2] <= NEARBY_KM][:NEARBY_LIMIT]
    if near:
        return near
    # fallback: closest station if within FALLBACK_KM
    if hits and hits[0][2] <= FALLBACK_KM:
        return [hits[0]]
    return []


def primary_zone(lat: float, lng: float) -> str | None:
    best = None
    best_km = 1e9
    for slug, zlat, zlng, max_km in GEO_ZONES:
        km = haversine_km(lat, lng, zlat, zlng)
        if km <= max_km and km < best_km:
            best_km = km
            best = slug
    return best


def is_transit_token(value: str) -> bool:
    t = value.strip()
    if not t:
        return True
    if t in TRANSIT_TOKENS:
        return True
    if t.lower() in TRANSIT_TOKENS:
        return True
    if re.match(r"^(BTS|MRT|ARL|Gold)\s+", t, re.I):
        return True
    return False


def name_aliases(name_th: str | None, name_en: str | None, slug: str | None) -> list[str]:
    out: list[str] = []

    def add(v: str | None) -> None:
        if not v:
            return
        s = v.strip()
        if not s or is_transit_token(s):
            return
        if s not in out:
            out.append(s)

    add(name_th)
    add(name_en)
    if slug:
        add(slug.replace("-", " "))
        add(slug)
    # tokenized name parts (keep meaningful chunks)
    for raw in (name_th or "", name_en or ""):
        for part in re.split(r"[\s\-/·|,]+", raw):
            p = part.strip()
            if len(p) < 2:
                continue
            if is_transit_token(p):
                continue
            # drop ultra-generic English crumbs
            if p.lower() in {"the", "condo", "condominium", "residence", "residences", "station"}:
                continue
            add(p)
    return out


def clean_existing_aliases(aliases: list[str] | None) -> list[str]:
    out: list[str] = []
    for a in aliases or []:
        if is_transit_token(a):
            continue
        s = a.strip()
        if not s:
            continue
        if s not in out:
            out.append(s)
    return out


def rebuild_row(row: dict) -> dict | None:
    slug = row.get("slug") or ""
    lat = row.get("lat")
    lng = row.get("lng")
    if slug in COORD_FIXES:
        lat, lng = COORD_FIXES[slug]
    if lat is None or lng is None:
        return None
    try:
        lat_f = float(lat)
        lng_f = float(lng)
    except (TypeError, ValueError):
        return None
    if not (5 < lat_f < 21 and 97 < lng_f < 106):
        return None

    near = nearby_stations(lat_f, lng_f)
    nearby_labels = [h[0] for h in near]
    tag_slugs = [h[1] for h in near]
    zone = primary_zone(lat_f, lng_f)
    if zone:
        tag_slugs.append(zone)
    if slug:
        tag_slugs.append(slug)

    aliases = []
    for a in name_aliases(row.get("name_th"), row.get("name_en"), slug):
        if a not in aliases:
            aliases.append(a)
    for a in clean_existing_aliases(row.get("aliases")):
        if a not in aliases:
            aliases.append(a)

    # Deduplicate tag slugs preserving order
    seen = set()
    search_tag_slugs = []
    for s in tag_slugs:
        if s in seen:
            continue
        seen.add(s)
        search_tag_slugs.append(s)

    payload = {
        "nearby_transit": nearby_labels,
        "bts_station": " · ".join(nearby_labels) if nearby_labels else None,
        "aliases": aliases,
        "search_tag_slugs": search_tag_slugs,
        "tag_enrich_status": "auto_ok" if nearby_labels or zone else "needs_review",
        "tag_enrich_meta": {
            "tier": "coords_rebuild_v2",
            "nearby_km": NEARBY_KM,
            "fallback_km": FALLBACK_KM,
            "stations": [
                {"label": h[0], "slug": h[1], "km": round(h[2], 3)} for h in near
            ],
            "primary_zone": zone,
            "enriched_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        },
        "_zone_slug": zone,
    }
    if slug in COORD_FIXES:
        payload["lat"] = lat_f
        payload["lng"] = lng_f
        payload["tag_enrich_meta"]["coord_fix"] = True
    return payload


def rest_get_all(url: str, key: str) -> list[dict]:
    headers = {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Accept": "application/json",
        "Prefer": "count=exact",
    }
    out: list[dict] = []
    page = 1000
    offset = 0
    while True:
        qs = urllib.parse.urlencode(
            {
                "select": "id,slug,name_th,name_en,lat,lng,aliases,nearby_transit,bts_station,geo_zone_id",
                "is_active": "eq.true",
                "order": "slug",
                "limit": str(page),
                "offset": str(offset),
            }
        )
        req = urllib.request.Request(
            f"{url}/rest/v1/property_projects?{qs}", headers=headers
        )
        with urllib.request.urlopen(req, timeout=60) as resp:
            batch = json.loads(resp.read().decode())
        if not batch:
            break
        out.extend(batch)
        if len(batch) < page:
            break
        offset += page
        print(f"  fetched {len(out)}…", flush=True)
    return out


def rest_patch(url: str, key: str, project_id: str, payload: dict) -> None:
    headers = {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    }
    body = json.dumps(payload).encode()
    req = urllib.request.Request(
        f"{url}/rest/v1/property_projects?id=eq.{project_id}",
        data=body,
        headers=headers,
        method="PATCH",
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        resp.read()


def load_zone_ids(url: str, key: str) -> dict[str, str]:
    headers = {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Accept": "application/json",
    }
    qs = urllib.parse.urlencode({"select": "id,slug"})
    req = urllib.request.Request(f"{url}/rest/v1/geo_zones?{qs}", headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            rows = json.loads(resp.read().decode())
        return {r["slug"]: r["id"] for r in rows if r.get("slug") and r.get("id")}
    except Exception:
        return {}


def main() -> int:
    dry = "--dry-run" in sys.argv
    env = load_env()
    url = env.get("SUPABASE_URL")
    key = env.get("SUPABASE_SERVICE_ROLE_KEY") or env.get("SUPABASE_ANON_KEY")
    if not url or not key:
        print("❌ Need SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY in .env.local")
        return 1

    print("=== Rebuild project transit links from coordinates ===")
    print(f"nearby ≤ {NEARBY_KM} km (fallback ≤ {FALLBACK_KM} km), dry_run={dry}")
    rows = rest_get_all(url, key)
    print(f"projects: {len(rows)}")
    zones = load_zone_ids(url, key)

    updated = 0
    stripped_onnut = 0
    examples = []
    for i, row in enumerate(rows, 1):
        rebuilt = rebuild_row(row)
        if not rebuilt:
            continue
        zone_slug = rebuilt.pop("_zone_slug", None)
        old_aliases = row.get("aliases") or []
        if "อ่อนนุช" in old_aliases or "BTS อ่อนนุช" in old_aliases:
            near_labels = set(rebuilt["nearby_transit"])
            if "BTS อ่อนนุช" not in near_labels:
                stripped_onnut += 1

        payload = {
            "nearby_transit": rebuilt["nearby_transit"],
            "bts_station": rebuilt["bts_station"],
            "aliases": rebuilt["aliases"],
            "search_tag_slugs": rebuilt["search_tag_slugs"],
            "tag_enrich_status": rebuilt["tag_enrich_status"],
            "tag_enrich_meta": rebuilt["tag_enrich_meta"],
        }
        if zone_slug and zone_slug in zones:
            payload["geo_zone_id"] = zones[zone_slug]

        if row.get("slug") == "hive-taksin":
            examples.append(("hive-taksin", old_aliases, payload))

        if not dry:
            try:
                rest_patch(url, key, row["id"], payload)
            except urllib.error.HTTPError as e:
                print(f"  ! fail {row.get('slug')}: {e.read()[:200]}")
                continue
        updated += 1
        if i % 200 == 0:
            print(f"  processed {i}/{len(rows)} updated={updated}", flush=True)
            if not dry:
                time.sleep(0.05)

    print(f"\n✅ updated={updated}  stripped_false_onnut_alias≈{stripped_onnut}")
    for slug, old_a, payload in examples:
        print(f"\n--- {slug} ---")
        print("  old aliases:", old_a)
        print("  new nearby:", payload["nearby_transit"])
        print("  new bts:", payload["bts_station"])
        print("  new aliases:", payload["aliases"][:12], "…")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
