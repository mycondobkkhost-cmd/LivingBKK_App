#!/usr/bin/env python3
"""
Bonus: faster scrape via embedded __NEXT_DATA__ (no browser).

PropertyHub search pages embed full listing JSON in <script id="__NEXT_DATA__">.
This is the same payload the React app uses — often cleaner than DOM scraping.

To find a true XHR API (optional upgrade):
  1. Open Chrome DevTools → Network → filter "Fetch/XHR"
  2. Reload a search page (e.g. condo-for-rent/bangkok)
  3. Look for hosts like api.propertyhub.in.th or /graphql
  4. Copy URL, method, query/body, and required headers (cookies, x-*)
  5. Replay with requests; paginate with the same page= query param

This script does NOT guess private API paths — it fetches HTML once per page
and parses __NEXT_DATA__ (reliable, no API key).
"""

from __future__ import annotations

import json
import random
import re
import sys
import time
from typing import Any

import pandas as pd
import requests
from bs4 import BeautifulSoup

# Reuse parsers from main script
from scrape_propertyhub_listings import (
    BASE_URL,
    DELAY_MAX_SEC,
    DELAY_MIN_SEC,
    MAX_PAGES,
    OUTPUT_CSV,
    USER_AGENT,
    build_page_url,
    parse_listing_item,
)

SESSION = requests.Session()
SESSION.headers.update(
    {
        "User-Agent": USER_AGENT,
        "Accept": "text/html,application/xhtml+xml",
        "Accept-Language": "en-US,en;q=0.9,th;q=0.8",
    }
)


def fetch_page_html(url: str) -> str:
    r = SESSION.get(url, timeout=45)
    r.raise_for_status()
    return r.text


def extract_rows(html: str, page_number: int) -> tuple[list[dict], bool]:
    soup = BeautifulSoup(html, "lxml")
    script = soup.find("script", id="__NEXT_DATA__", type="application/json")
    if not script or not script.string:
        return [], False
    data = json.loads(script.string)
    page_props = (data.get("props") or {}).get("pageProps") or {}
    zone_name = (page_props.get("zone") or {}).get("name")
    block = page_props.get("listings") or {}
    items = block.get("listings") or []
    pagination = block.get("pagination") or {}

    rows = []
    for item in items:
        if isinstance(item, dict):
            rows.append(
                parse_listing_item(item, zone_name, page_number).__dict__
            )

    total_pages = pagination.get("totalPages")
    has_next = not total_pages or page_number < int(total_pages)
    return rows, has_next


def main() -> int:
    all_rows: list[dict] = []
    for page_num in range(1, MAX_PAGES + 1):
        url = build_page_url(BASE_URL, page_num)
        print(f"GET {url}")
        try:
            html = fetch_page_html(url)
            rows, has_next = extract_rows(html, page_num)
            all_rows.extend(rows)
            print(f"  +{len(rows)} (total {len(all_rows)})")
        except Exception as exc:
            print(f"  failed: {exc}", file=sys.stderr)
            break
        if not rows or not has_next or page_num >= MAX_PAGES:
            break
        time.sleep(random.uniform(DELAY_MIN_SEC, DELAY_MAX_SEC))

    if not all_rows:
        return 1
    df = pd.DataFrame(all_rows).drop_duplicates(subset=["listing_url"])
    out = OUTPUT_CSV.replace(".csv", "_api.csv")
    df.to_csv(out, index=False, encoding="utf-8-sig")
    print(f"✅ {len(df)} rows → {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
