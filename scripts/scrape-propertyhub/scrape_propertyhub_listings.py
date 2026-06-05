#!/usr/bin/env python3
"""
Scrape PropertyHub.in.th listing search pages (condo/house, rent/sale).

Uses Playwright (sync) to load JS-rendered pages, then BeautifulSoup to read
embedded __NEXT_DATA__ JSON (primary) with DOM fallback for resilience.
"""

from __future__ import annotations

import json
import random
import re
import sys
import time
from dataclasses import dataclass, asdict
from typing import Any, Optional
from urllib.parse import urljoin, urlparse

import pandas as pd
from bs4 import BeautifulSoup
from playwright.sync_api import TimeoutError as PlaywrightTimeout
from playwright.sync_api import sync_playwright

# --- Configuration (edit these) ---
BASE_URL = "https://propertyhub.in.th/en/condo-for-rent/bangkok"
MAX_PAGES = 10
DELAY_MIN_SEC = 3.0
DELAY_MAX_SEC = 7.0
OUTPUT_CSV = "propertyhub_listings.csv"
HEADLESS = True
PAGE_LOAD_TIMEOUT_MS = 60_000
LISTING_LINK_SELECTOR = 'a[href*="/listings/"]'

USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/122.0.0.0 Safari/537.36"
)

SITE_ORIGIN = "https://propertyhub.in.th"


@dataclass
class ListingRow:
    project_name: Optional[str] = None
    listing_title: Optional[str] = None
    price: Optional[str] = None
    location_zone: Optional[str] = None
    bts_mrt: Optional[str] = None
    size_sqm: Optional[float] = None
    bedrooms: Optional[float] = None
    bathrooms: Optional[float] = None
    listing_url: Optional[str] = None
    post_type: Optional[str] = None
    property_type: Optional[str] = None
    page_number: Optional[int] = None


def build_page_url(base_url: str, page: int) -> str:
    base = base_url.strip().rstrip("/")
    if page <= 1:
        return base
    sep = "&" if "?" in base else "?"
    return f"{base}{sep}page={page}"


def random_delay() -> None:
    time.sleep(random.uniform(DELAY_MIN_SEC, DELAY_MAX_SEC))


def extract_bts_from_text(text: str) -> Optional[str]:
    if not text:
        return None
    m = re.search(
        r"((?:BTS|MRT|ARL|Airport Rail Link)[^\n,|]{2,60})",
        text,
        re.IGNORECASE,
    )
    return m.group(1).strip() if m else None


def format_price(item: dict[str, Any]) -> Optional[str]:
    try:
        price = item.get("price") or {}
        post = (item.get("postType") or "").upper()
        if post == "FOR_RENT" or "RENT" in post:
            rent = price.get("forRent") or {}
            monthly = (rent.get("monthly") or {}).get("price")
            if monthly is not None:
                return f"{monthly:,.0f} THB/month"
            daily = (rent.get("daily") or {}).get("price")
            if daily is not None:
                return f"{daily:,.0f} THB/day"
        sale = (price.get("forSale") or {}).get("price")
        if sale is not None:
            return f"{sale:,.0f} THB"
        sale_dp = (price.get("forSaleDownPayment") or {}).get("paid")
        if sale_dp is not None:
            return f"down {sale_dp:,.0f} THB"
    except (TypeError, ValueError, AttributeError):
        pass
    return None


def listing_url_from_slug(slug: str) -> str:
    slug = slug.strip().lstrip("/")
    if slug.startswith("http"):
        return slug
    if not slug.startswith("en/"):
        slug = f"en/listings/{slug}"
    return urljoin(SITE_ORIGIN + "/", slug)


def parse_listing_item(
    item: dict[str, Any],
    zone_name: Optional[str],
    page_number: int,
) -> ListingRow:
    row = ListingRow(page_number=page_number)
    try:
        row.listing_title = (item.get("title") or "").strip() or None
    except Exception:
        pass
    try:
        row.post_type = item.get("postType")
        row.property_type = item.get("propertyType")
    except Exception:
        pass
    try:
        project = item.get("project") or {}
        row.project_name = (
            project.get("name")
            or project.get("nameEnglish")
            or None
        )
        addr = (project.get("address") or "").strip()
        row.location_zone = ", ".join(
            p for p in [zone_name, addr] if p
        ) or zone_name
    except Exception:
        row.location_zone = zone_name
    try:
        row.bts_mrt = extract_bts_from_text(row.listing_title or "")
    except Exception:
        pass
    try:
        row.price = format_price(item)
    except Exception:
        pass
    try:
        room = item.get("roomInformation") or {}
        area = room.get("roomArea")
        row.size_sqm = float(area) if area is not None else None
        beds = room.get("numberOfBed")
        row.bedrooms = float(beds) if beds is not None else None
        baths = room.get("numberOfBath")
        row.bathrooms = float(baths) if baths is not None else None
    except Exception:
        pass
    try:
        slug = item.get("slug")
        if slug:
            row.listing_url = listing_url_from_slug(str(slug))
    except Exception:
        pass
    return row


def parse_next_data(html: str, page_number: int) -> tuple[list[ListingRow], Optional[dict]]:
    soup = BeautifulSoup(html, "lxml")
    script = soup.find("script", id="__NEXT_DATA__", type="application/json")
    if not script or not script.string:
        return [], None
    try:
        data = json.loads(script.string)
    except json.JSONDecodeError:
        return [], None

    page_props = (data.get("props") or {}).get("pageProps") or {}
    zone_name = None
    try:
        zone_name = (page_props.get("zone") or {}).get("name")
    except Exception:
        pass

    listings_block = page_props.get("listings") or {}
    items = listings_block.get("listings") or []
    pagination = listings_block.get("pagination")

    rows: list[ListingRow] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        try:
            rows.append(parse_listing_item(item, zone_name, page_number))
        except Exception as exc:
            print(f"  [warn] skip listing json: {exc}", file=sys.stderr)
    return rows, pagination if isinstance(pagination, dict) else None


def parse_dom_fallback(html: str, page_number: int) -> list[ListingRow]:
    """Fallback when __NEXT_DATA__ is missing — best-effort card parsing."""
    soup = BeautifulSoup(html, "lxml")
    rows: list[ListingRow] = []
    seen: set[str] = set()

    for a in soup.select(LISTING_LINK_SELECTOR):
        try:
            href = a.get("href") or ""
            if "/listings/" not in href:
                continue
            url = urljoin(SITE_ORIGIN, href)
            if url in seen:
                continue
            seen.add(url)

            title = a.get_text(" ", strip=True) or None
            card = a.find_parent("div", class_=re.compile(r"sc-"))
            card_text = card.get_text(" ", strip=True) if card else ""

            price = None
            m = re.search(
                r"(?:Rental|Sale|Price)\s*([\d,]+)\s*THB",
                card_text,
                re.I,
            )
            if m:
                price = m.group(0)

            size = None
            m = re.search(r"Room size\s*([\d.]+)\s*m", card_text, re.I)
            if m:
                size = float(m.group(1))

            beds = baths = None
            m = re.search(r"(\d+)\s*Bed", card_text, re.I)
            if m:
                beds = float(m.group(1))
            m = re.search(r"(\d+)\s*Bath", card_text, re.I)
            if m:
                baths = float(m.group(1))

            project_name = None
            m = re.search(r"\(([^)]+)\)\s*Exclusive", card_text)
            if m:
                project_name = m.group(1).strip()

            rows.append(
                ListingRow(
                    project_name=project_name,
                    listing_title=title,
                    price=price,
                    location_zone=None,
                    bts_mrt=extract_bts_from_text(title or ""),
                    size_sqm=size,
                    bedrooms=beds,
                    bathrooms=baths,
                    listing_url=url,
                    page_number=page_number,
                )
            )
        except Exception as exc:
            print(f"  [warn] dom card: {exc}", file=sys.stderr)
    return rows


def scrape_page(page, url: str, page_number: int) -> tuple[list[ListingRow], bool]:
    print(f"→ Page {page_number}: {url}")
    page.goto(url, wait_until="domcontentloaded", timeout=PAGE_LOAD_TIMEOUT_MS)
    try:
        page.wait_for_selector(LISTING_LINK_SELECTOR, timeout=20_000)
    except PlaywrightTimeout:
        print("  [warn] listing links slow/missing — continuing with HTML", file=sys.stderr)
    page.wait_for_timeout(1500)
    html = page.content()

    rows, pagination = parse_next_data(html, page_number)
    if not rows:
        print("  [info] __NEXT_DATA__ empty — DOM fallback", file=sys.stderr)
        rows = parse_dom_fallback(html, page_number)

    has_next = True
    if pagination:
        total_pages = pagination.get("totalPages")
        current = pagination.get("page", page_number)
        print(
            f"  parsed {len(rows)} listings "
            f"(page {current}/{total_pages}, total ~{pagination.get('totalCount')})"
        )
        if total_pages and page_number >= int(total_pages):
            has_next = False
    else:
        print(f"  parsed {len(rows)} listings")

    return rows, has_next


def run() -> int:
    all_rows: list[ListingRow] = []
    parsed_base = urlparse(BASE_URL)
    if not parsed_base.scheme:
        print("BASE_URL must include https://", file=sys.stderr)
        return 1

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=HEADLESS)
        context = browser.new_context(
            user_agent=USER_AGENT,
            locale="en-US",
            viewport={"width": 1440, "height": 900},
        )
        page = context.new_page()
        page.set_extra_http_headers(
            {"Accept-Language": "en-US,en;q=0.9,th;q=0.8"}
        )

        try:
            for page_num in range(1, MAX_PAGES + 1):
                url = build_page_url(BASE_URL, page_num)
                try:
                    rows, has_next = scrape_page(page, url, page_num)
                    all_rows.extend(rows)
                except Exception as exc:
                    print(f"  [error] page {page_num} failed: {exc}", file=sys.stderr)
                    break

                if page_num >= MAX_PAGES:
                    break
                if not rows:
                    print("  no rows — stopping pagination")
                    break
                if not has_next:
                    break
                if page_num < MAX_PAGES:
                    random_delay()
        finally:
            browser.close()

    if not all_rows:
        print("No listings extracted.", file=sys.stderr)
        return 1

    df = pd.DataFrame([asdict(r) for r in all_rows])
    df = df.drop_duplicates(subset=["listing_url"], keep="first")
    df = df.sort_values(by=["page_number", "listing_title"], na_position="last")
    df.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"\n✅ Saved {len(df)} rows → {OUTPUT_CSV}")
    return 0


if __name__ == "__main__":
    raise SystemExit(run())
