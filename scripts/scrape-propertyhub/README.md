# PropertyHub listing scraper

Scrapes **individual listings** (condo/house for rent or sale) from [propertyhub.in.th](https://propertyhub.in.th) search pages.

## What you get per row

| Column | Example |
|--------|---------|
| `project_name` | Life Phahon - Ladprao |
| `listing_title` | Full ad title (often includes BTS/MRT) |
| `price` | `19,000 THB/month` |
| `location_zone` | Bangkok, Chatuchak Bangkok |
| `bts_mrt` | Parsed from title when present |
| `size_sqm` | 35 |
| `bedrooms` / `bathrooms` | 1 / 1 |
| `listing_url` | Direct link to the ad |

## Install

```bash
cd scripts/scrape-propertyhub
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
playwright install chromium
```

## Configure & run (Playwright + BeautifulSoup)

Edit the top of `scrape_propertyhub_listings.py`:

```python
BASE_URL = "https://propertyhub.in.th/en/condo-for-rent/bangkok"
MAX_PAGES = 10          # start small for testing
DELAY_MIN_SEC = 3.0
DELAY_MAX_SEC = 7.0
OUTPUT_CSV = "propertyhub_listings.csv"
```

Other listing types (change `BASE_URL` only):

| Type | Example URL |
|------|-------------|
| Condo rent | `https://propertyhub.in.th/en/condo-for-rent/bangkok` |
| Condo sale | `https://propertyhub.in.th/en/condo-for-sale/bangkok` |
| National condo rent | `https://propertyhub.in.th/en/condo-for-rent` (may redirect) |

```bash
python scrape_propertyhub_listings.py
```

Output: `propertyhub_listings.csv` (UTF-8 with BOM for Excel).

## Faster bonus: `__NEXT_DATA__` only (requests)

Same fields, no browser — uses JSON embedded in the HTML:

```bash
python scrape_propertyhub_api.py
```

Writes `propertyhub_listings_api.csv`.

## How extraction works

1. **Playwright** opens each `?page=N` URL with a real Chrome user-agent.
2. Waits for listing links to appear.
3. **BeautifulSoup** reads `<script id="__NEXT_DATA__">` → `pageProps.listings.listings[]` (60 items/page).
4. If that JSON is missing, falls back to parsing listing cards in the DOM.
5. **pandas** dedupes by `listing_url` and exports CSV.

## Finding the internal API (Network tab)

1. Open **Chrome DevTools** (F12) → **Network**.
2. Enable **Preserve log**, filter **Fetch/XHR**.
3. Visit e.g. `https://propertyhub.in.th/en/condo-for-rent/bangkok`.
4. Look for requests to `api.propertyhub.in.th` or paths containing `listing`, `search`, `zone`.
5. Click a request → **Headers** (URL, cookies) + **Payload** (query/body).
6. **Response** should be JSON with the same fields as `__NEXT_DATA__` (`title`, `price`, `roomInformation`, …).
7. Replay with `requests` and paginate with the same `page` parameter the site uses.

PropertyHub also dns-prefetches `https://api.propertyhub.in.th`; endpoints may require session cookies from a first browser visit.

## Legal & etiquette

- Respect [PropertyHub terms](https://propertyhub.in.th) and robots.txt.
- Use delays (`DELAY_*`) and modest `MAX_PAGES` while testing.
- Do not hammer the site; this script is for personal/research use.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `playwright install` missing | Run `playwright install chromium` |
| 0 rows | Try `/en/condo-for-rent/bangkok` instead of root path |
| Timeout | Increase `PAGE_LOAD_TIMEOUT_MS` or set `HEADLESS = False` |
| Blocked / CAPTCHA | Increase delays; run headed browser |
