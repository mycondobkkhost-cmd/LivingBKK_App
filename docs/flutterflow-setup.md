# FlutterFlow Setup Guide (LivingBKK)

Use this if you build UI in **FlutterFlow** instead of the `mobile/` Flutter codebase.

## 1. Project settings

- **Theme primary:** `#6B46C1`
- **Font:** Noto Sans Thai
- **Backend:** Supabase (paste Project URL + Anon Key)

## 2. Supabase tables (read)

| Page | Table / View |
|------|----------------|
| Map cards | `listings_public` |
| Listing detail | `listings_public` by id |
| Demand board | `demand_posts` filter `status=open` |
| My offers | `demand_offers` (RLS returns own rows only) |

## 3. Custom Actions (API calls)

### Smart Search

- **Name:** `parseSmartSearch`
- **Method:** POST  
- **URL:** `{SUPABASE_URL}/functions/v1/smart-search-parse`
- **Headers:** `Authorization: Bearer {anon}`, `Content-Type: application/json`
- **Body:** `{ "query": searchText }`
- **Output:** `preview` list → bind to dropdown UI

### Submit Demand Offer

- **Name:** `submitDemandOffer`
- **URL:** `{SUPABASE_URL}/functions/v1/submit-demand-offer`
- **Body:**
  ```json
  {
    "demand_post_id": "...",
    "offerer_capacity": "owner_direct_100 | co_agent_50_50 | listing_agent",
    "offer_type": "in_app | external_link",
    "title": "...",
    "price_net": 15000,
    "external_url": "..."
  }
  ```

### Moderate listing text

- **URL:** `{SUPABASE_URL}/functions/v1/moderate-listing-text`
- **Body:** `{ "text": descriptionField }`
- Block publish if `allowed == false`

## 4. Page map (from wireframes)

| FlutterFlow Page | Wireframe section |
|------------------|-------------------|
| MapHome | phase-2 §2 |
| DemandBoard | phase-2 §7.1 |
| DemandDetail | phase-2 §7.2 |
| SubmitOffer | phase-2 §7.3 (dropdown บังคับ) |
| ListingDetail | phase-2 §4 |
| LeadBot | phase-2 §5 |
| WorkInbox | phase-2 §6 |
| Profile | phase-2 §1 |

## 5. Conditional visibility

| Widget | Visible when |
|--------|----------------|
| Agent segment control | `currentUserRole == agent` |
| Co-agent strip on card | `co_agent_eligible == true` && agent |
| Offer count on board | **Never** (blind board) |

## 6. Export

You can export Flutter code from FlutterFlow into `mobile/` or a separate repo; align folder names with `mobile/lib/features/` for easier merges.
