# OpenAlex Fetch-All and Pagination Decision

> Review date: 2026-07-15
> Status: implemented and verified
> Scope: topic searches in Home, Journals, and Keywords

## 1. Question being evaluated

Before this upgrade, the app requested a bounded sample of up to 200 OpenAlex
works for each topic. The proposed alternative was to fetch every matching work
and then split the result into pages in the Flutter UI.

There are two different techniques hidden behind the word "pagination":

1. **Client-side pagination:** fetch every result first, keep everything in
   memory, and only divide the already-downloaded list into UI pages.
2. **Server-side cursor pagination:** request one page from OpenAlex, render it,
   and request the next page only when the user asks for more.

Only the second technique materially improves the app's initial performance.

## 2. Pre-implementation repository audit

- `OpenAlexService.searchTopic()` returned only `List<Publication>` and discarded
  response metadata such as the full result count and next cursor.
- Requests used `per-page` and clamped the value to 200. The current
  OpenAlex documentation describes `per_page`, with a maximum of 100 results
  per request. That code did not follow the current documented paging contract.
- `OpenAlexSearchState` had no `totalCount`, `nextCursor`, `hasMore`, or
  `isLoadingMore` fields.
- Home, Journals, and Keywords calculate analytics from the loaded
  publications. Their three search states are independent and must stay
  independent after any pagination change.
- The topic flow currently uses full-text `search=...`. That produces a
  relevance-ranked search result, not a canonical set of every work assigned
  to an OpenAlex Topic. A true topic corpus should first resolve an OpenAlex
  Topic ID and then filter works by that ID.

## 3. Option comparison

| Option | Initial speed | Network/RAM use | Statistical coverage | Complexity | Decision |
| --- | --- | --- | --- | --- | --- |
| Keep a fixed 200-work sample | Fast enough | Bounded | Sample only | Low | Acceptable short-term |
| Fetch all, then paginate in Flutter | Slow for large topics | Potentially unbounded | Full loaded corpus | High | Reject |
| OpenAlex cursor pagination, 100/page | Fast first page | Grows only on demand | Loaded pages only | Medium | Recommended |
| Cursor pages plus OpenAlex aggregate queries | Fast first page | Bounded | Full-corpus summary where supported | Medium-high | Best analytics design |

Why "fetch all, then paginate" is rejected:

- The user still waits for every sequential API request before seeing a
  complete result.
- Every publication and nested author/topic/abstract object remains in Dart
  memory even if the UI shows only 20 rows.
- A failure near the end can interrupt the entire operation.
- Rebuilding analytics over a very large in-memory list increases CPU work.
- The result count can change between searches, so "all" is not a stable or
  predictable mobile workload.

## 4. Scale estimate

With the currently documented maximum of 100 works per response:

| Matching works | Sequential requests required |
| ---: | ---: |
| 200 | 2 |
| 1,000 | 10 |
| 10,000 | 100 |
| 100,000 | 1,000 |

The cursor for the next page comes from the previous response, so paging a
single result set is inherently sequential. As a conservative engineering
estimate, if one selected work averages about 10 KB of JSON, 10,000 works are
already around 100 MB before Dart object overhead. This size estimate is an
inference for planning, not a guarantee from OpenAlex.

OpenAlex's current pricing makes an unbounded full-text search another poor fit
for a mobile client. Full-text Search costs $1 per 1,000 calls. At 100 works per
call, retrieving 100,000 search results requires about 1,000 calls and consumes
about $1 before retries. The anonymous daily budget is $0.10, while a free API
key provides $1 per day. OpenAlex also explicitly advises against cursor-paging
an entire dataset; its free snapshot is the supported option for bulk data.

An OpenAlex API key must not be embedded in an APK or IPA because a client-side
secret can be extracted. If authenticated high-volume access becomes necessary,
the app should call a controlled backend/proxy that owns the key and enforces
budgets, caching, and request limits.

The optional `OPENALEX_API_KEY` Dart define in this repository exists only for
local development and live Patrol verification. It must be omitted from public
release builds; a Dart define is configuration, not secure secret storage.

## 5. Recommended design

The implemented server-side cursor pagination uses this design:

1. Introduce `OpenAlexPage<Publication>` containing `items`, `totalCount`, and
   `nextCursor`.
2. Use the documented `per_page=100` parameter and `cursor=*` for the first
   page, then the returned cursor for later pages.
3. Extend search state with `totalCount`, `nextCursor`, `hasMore`, and
   `isLoadingMore`.
4. Render the first page immediately and offer both **Load next 100** and a
   one-tap bulk action: **Load all N** when the result fits inside the cap, or
   **Load up to 1,000** for larger result sets. Show status such as
   `Loaded 300 of up to 1,000` while the bulk action is running.
5. Apply a product safety cap of 500-1,000 loaded works per tab unless an
   explicit export/background-data requirement justifies more.
6. Preserve separate cursor and loaded-list state for Home, Journals, and
   Keywords.
7. Cancel or ignore stale cursor responses when a new search starts.
8. Retry transient rate-limit/server errors with bounded exponential backoff.
9. For full-corpus trend/count summaries, use `meta.count` and OpenAlex
   `group_by` queries where supported instead of downloading every work.

The UI can still paginate or virtualize the publications already loaded, but
that is a rendering choice on top of server-side pagination, not a replacement
for it.

## 6. Recommendation for this Lab

Do **not** fetch the complete result set on the Android/iOS client. The app now
uses:

- 100 works per OpenAlex request;
- a visible **Load next 100** action for controlled data use;
- a one-tap **Load all N** or **Load up to 1,000** action with live progress,
  cancellation, and retry;
- a 1,000-work per-tab safety cap;
- full result count from response metadata;
- explicit labels that charts and rankings use only the loaded works.

OpenAlex aggregate queries remain a possible future enhancement for
full-corpus summaries; this upgrade does not present loaded-sample analytics as
full-corpus analytics.

This makes the first result faster, lowers memory and data usage, gives the user
progressive access to more publications, and avoids an unpredictable
"download the whole topic" operation. Pagination therefore improves the app
only when it controls network fetching, not when it merely divides an already
fully downloaded list.

The metrics, charts, journal ranking, keyword ranking, and exported PDF continue
to use the works loaded in the Home tab. The UI labels this explicitly; the
OpenAlex total count is broader than the loaded analytics sample.

## 7. Implementation and verification

- `OpenAlexPage<T>` preserves items, `meta.count`, `meta.next_cursor`, and the
  optional request cost.
- Topic requests use `per_page=100` and start with `cursor=*`.
- Home, Journals, and Keywords keep separate repository/cursor state.
- `Load next 100` appends one cursor page in API order. `Load all N` / `Load up
  to 1,000` follows cursors sequentially and updates the UI after each page.
- Both modes deduplicate non-empty publication IDs and never load more than
  1,000 works per tab.
- Cancelling bulk loading keeps all previously committed pages, discards the
  page that was in flight, and preserves its cursor so the user can continue.
- A failed next page leaves existing data visible and exposes a retry action.
- A new search or disposal invalidates an older first-page/load-more response.
- Repeated cursors stop pagination without a Retry loop; a new search safely
  restarts the cursor chain.
- HTTP 429 and 5xx responses use bounded exponential retry; other 4xx responses
  fail immediately.
- Journals use a lazy list builder, and keyword aggregation/trending results are
  cached for each loaded publication list.
- Automated verification after the UX and robustness upgrade: analyzer clean,
  114 Flutter tests pass, and the Android debug APK builds successfully.
- Live OpenAlex smoke check returned one result with `meta.count`, `per_page=1`,
  and a non-empty `next_cursor`.

## 8. Official references

- [OpenAlex API introduction](https://developers.openalex.org/api-reference/introduction)
- [Authentication and pricing](https://developers.openalex.org/api-reference/authentication)
- [List works](https://developers.openalex.org/api-reference/works/list-works)
- [Page through results](https://developers.openalex.org/guides/page-through-results)
- [Searching](https://developers.openalex.org/guides/searching)
- [Errors and retry guidance](https://developers.openalex.org/api-reference/errors)
