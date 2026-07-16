# Phase 1-5 Verification and Manual Test Cases

> Scope: Firebase foundation, Authentication/Analytics/Remote Config core, MVVM/navigation, Home/Journals/Keywords/detail flows, Profile/PDF/Firebase Storage.
> Platform for manual verification: Android emulator/device with Google Play Services.
> FCM Notification Center, Crashlytics demo buttons, Patrol E2E and iOS/IPA are later phases and are not failures of Phase 1-5.

## 1. Test type definitions

| Type | Meaning | Expected behavior |
| --- | --- | --- |
| `SUCCESS` | Valid user flow with available network/services | Action completes and required data/UI appears |
| `FAILURE` | Invalid input, cancelled action, API/Firebase rejection | Friendly error/empty state appears; app does not crash |
| `INTERRUPTED` | Network loss, duplicate tap, tab switch, logout or app lifecycle interruption | Duplicate work is blocked or flow recovers safely |
| `BOUNDARY` | Limit, empty data, missing optional fields or independent state | App enforces defined boundary and remains usable |
| `SECURITY` | Authentication, UID ownership, secret/config protection | Unauthorized access is denied |
| `EVIDENCE` | Verification in Firebase Console/DebugView | Required Firebase record is visible |

## 2. Preconditions

- Install the latest debug APK on an Android emulator/device with Google Play Services.
- Firebase Android package is `com.example.journal_trend_analysis`.
- Google provider is enabled in Firebase Authentication and SHA-1/SHA-256 are registered.
- Firebase Storage is available on the Blaze plan and `storage.rules` is published.
- Remote Config contains:
  - `max_journals_displayed = 10`
  - `max_keywords_displayed = 10`
- Prepare one Google account `User A`. A second account `User B` is optional for Storage security verification.
- Use a stable connection for success cases and emulator airplane mode/network disable for interrupted cases.
- Record `Actual result`, `PASS/FAIL`, screenshot and notes for every case.

## 3. Automated verification performed by Codex

| ID | Verification | Expected | Result |
| --- | --- | --- | --- |
| AUTO-01 | `flutter analyze` | No analyzer issue | PASS - no issues |
| AUTO-02 | Full Flutter test suite | All unit/widget tests pass | PASS - 44/44 tests |
| AUTO-03 | Android debug build | APK compiles with Firebase plugins | PASS |
| AUTO-04 | Android emulator smoke test | App opens Login Screen without app exception | PASS |
| AUTO-05 | PDF binary/text validation | Valid `%PDF`, all required sections extractable | PASS |
| AUTO-06 | PDF visual render | No clipped/overlapping text; stable page split | PASS - 2 pages inspected |
| AUTO-07 | Credential scan | No Admin/service-account private key in source | PASS |
| AUTO-08 | Storage rule/code path review | `reports/{uid}/{fileName}.pdf` and UID ownership match | PASS |

## 4. Phase 1 - Firebase foundation

| ID | Type | Test steps | Expected result | Requirement |
| --- | --- | --- | --- | --- |
| P1-01 | `SUCCESS` | Launch the freshly installed app with network enabled | App starts and displays `Journal Trend Analyzer`; no Firebase initialization crash | Phase 1 bootstrap DoD |
| P1-02 | `SUCCESS` | Inspect the Login Screen after startup | Google login button is visible and enabled | 3.1 Login Screen |
| P1-03 | `INTERRUPTED` | Disable network, force close, then reopen app | App still opens a stable Login Screen; Firebase auxiliary services do not block startup | Phase 1 resilience |
| P1-04 | `SECURITY` | Review repository files before push | No Firebase Admin SDK key, service-account JSON, FCM server key or private key exists | 4.2 secret protection |
| P1-05 | `EVIDENCE` | Check Firebase project Android app settings | Package is `.example`; SHA-1 and SHA-256 match the debug signing report | Phase 1 Firebase setup |

## 5. Phase 2 - Authentication, Analytics and Remote Config core

| ID | Type | Test steps | Expected result | Requirement |
| --- | --- | --- | --- | --- |
| P2-01 | `SUCCESS` | Tap `Continue with Google`, choose User A and approve | Login completes and Home is shown | 3.1 Google Sign-In |
| P2-02 | `FAILURE` | Start Google login and cancel the chooser | Login Screen remains; message `Could not sign in with Google. Please try again.` appears | Auth failure handling |
| P2-03 | `INTERRUPTED` | Tap Google login repeatedly while it is starting | Only one authentication flow starts; button shows `Signing in...` and duplicate taps are ignored | Duplicate tap protection |
| P2-04 | `FAILURE` | Disable network and attempt Google login | Friendly login error appears; app does not hang or enter Home | Auth network failure |
| P2-05 | `SUCCESS` | Login successfully, force close, then reopen app | Existing Firebase session returns to Home without requesting login again | Auth state gate |
| P2-06 | `SUCCESS` | Open Profile after login | Photo or fallback avatar, display name and email are visible | 3.1/3.9 user information |
| P2-07 | `SUCCESS` | Inspect Remote Config section in Profile | Two values are shown for journals and keywords | 3.9 Remote Config demo |
| P2-08 | `FAILURE` | Temporarily make Remote Config unavailable and restart | App remains usable and displays fallback value `10` | Phase 2 fallback |
| P2-09 | `SUCCESS` | Tap `Sign Out` | App returns to Login Screen and protected tabs are no longer accessible | 3.1 logout |
| P2-10 | `EVIDENCE` | Perform login, search and logout; inspect Analytics DebugView/Events | `login`, `search_topic`, `logout` appear; automatic `screen_view`/`user_engagement` may also appear | 4.1 Analytics |

## 6. Phase 3 - MVVM and required navigation

| ID | Type | Test steps | Expected result | Requirement |
| --- | --- | --- | --- | --- |
| P3-01 | `SUCCESS` | Login and inspect bottom navigation | Exactly four destinations appear: Home, Journals, Keywords, Profile | 3.2 navigation |
| P3-02 | `SUCCESS` | Open each of the four destinations | Correct screen appears and app does not recreate the auth flow | 3.2 screens |
| P3-03 | `BOUNDARY` | Search Home=`Artificial Intelligence`, Journals=`Cybersecurity`, Keywords=`Healthcare`; revisit every tab | Each tab preserves its own topic and results; no cross-tab linking occurs | Project decision: independent state |
| P3-04 | `INTERRUPTED` | Switch tabs while a tab is loading | Navigation remains responsive; other tabs keep their own state; no stale response overwrites another tab | Async/MVVM state safety |
| P3-05 | `SUCCESS` | Open a detail screen and press Android Back | Returns to the originating tab with prior search state intact | Typed detail navigation |
| P3-06 | `BOUNDARY` | Rotate emulator or resize window if supported | Four-tab navigation and core cards remain readable without overflow | 5 responsive UI |

## 7. Phase 4 - Home and publication flow

| ID | Type | Test steps | Expected result | Requirement |
| --- | --- | --- | --- | --- |
| P4-H01 | `SUCCESS` | On Home search `Artificial Intelligence` | Loading indicator appears, then OpenAlex results and analytics are displayed | 3.3 search |
| P4-H02 | `SUCCESS` | Inspect Home after a successful search | Total publications, average citations, most active year, top journal, top author, trend chart and influential publication appear | 3.3 metrics |
| P4-H03 | `BOUNDARY` | Search a broad topic | First page loads at most 100 works and shows `Loaded X of Y matching works` | OpenAlex page-size contract |
| P4-H04 | `BOUNDARY` | Clear topic and press Search | No invalid API request or crash occurs; current state remains usable | Input boundary |
| P4-H05 | `FAILURE` | Disable network and search a new topic | A visible OpenAlex error state appears; app remains navigable | 5 loading/error states |
| P4-H06 | `BOUNDARY` | Search a deliberately nonsensical rare topic that returns no works | Empty-state notice appears instead of broken charts | 5 empty state |
| P4-H07 | `SUCCESS` | Tap the most influential publication | Publication Detail opens | 3.3 navigation |
| P4-H08 | `SUCCESS` | Inspect Publication Detail | Title, authors, year, journal, citations, DOI and abstract are shown when available | 3.4 detail fields |
| P4-H09 | `BOUNDARY` | Open a work missing DOI or abstract | Missing optional data has a safe fallback; layout does not crash | 3.4 optional fields |
| P4-H10 | `SUCCESS` | Tap original publication link | DOI/OpenAlex page opens in external browser | 3.4 original link |
| P4-H11 | `FAILURE` | Attempt original link with no browser/network | App stays open and reports that the link cannot be opened | Link failure handling |
| P4-H12 | `EVIDENCE` | Search and open a publication; inspect Analytics | `search_topic` has `keyword`; `view_publication` has title/year | 4.1 events |
| P4-H13 | `SUCCESS` | Tap `Load next 100` after a broad-topic search | Existing metrics stay visible, then loaded count and analytics increase without duplicates | Controlled cursor pagination |
| P4-H14 | `SUCCESS` | Tap `Load all N` or `Load up to 1,000` | Pages load sequentially from the cursor; live progress increases after each committed page | One-tap bulk UX |
| P4-H15 | `INTERRUPTED` | Tap `Cancel` while bulk loading | UI reports it will stop after the current request; the in-flight page is discarded and existing data remains usable | Cooperative cancellation |
| P4-H16 | `FAILURE` | Disable network before loading another page | Existing data stays visible, an error and `Retry` appear; restoring network and Retry continues from the same cursor | Recoverable pagination failure |
| P4-H17 | `BOUNDARY` | Bulk-load a very broad topic until the app cap | Loading stops at 1,000 works and a safety-limit notice replaces load actions | Mobile memory boundary |

## 8. Phase 4 - Journals flow

| ID | Type | Test steps | Expected result | Requirement |
| --- | --- | --- | --- | --- |
| P4-J01 | `SUCCESS` | Open Journals and search `Cybersecurity` | Loading state is followed by journal summary/list | 3.5 independent search |
| P4-J02 | `SUCCESS` | Inspect Journals results | Works/journals/citations summary, contribution bars, publication count and citation statistics appear | 3.5 journal analytics |
| P4-J03 | `SUCCESS` | Tap a journal | Journal Detail opens with journal name | 3.5 navigation |
| P4-J04 | `SUCCESS` | Inspect Journal Detail | Total publications, total citations, average citations and related publications appear | 3.6 detail |
| P4-J05 | `SUCCESS` | Tap a related publication | Publication Detail opens and Android Back returns to Journal Detail | 3.6 related publications |
| P4-J06 | `FAILURE` | Disable network and search another journal topic | Error card appears; bottom navigation remains usable | 5 error state |
| P4-J07 | `BOUNDARY` | Search a topic whose works have no recognized journal | `No journals were found for this topic.` appears | 3.5 empty state |
| P4-J08 | `EVIDENCE` | Open a journal and inspect Analytics | `view_journal` appears with `journal_name` | 4.1 event |
| P4-J09 | `SUCCESS` | Load another page in Journals | Loaded count increases and journal rankings update without changing Home/Keywords state | Independent cursor pagination |

## 9. Phase 4 - Keywords flow

| ID | Type | Test steps | Expected result | Requirement |
| --- | --- | --- | --- | --- |
| P4-K01 | `SUCCESS` | Open Keywords and search `Healthcare` | Loading state is followed by keyword analytics | 3.7 independent search |
| P4-K02 | `SUCCESS` | Inspect Keywords results | Works/unique keywords/top keyword, frequency bars, trending list and trend chart appear | 3.7 analytics |
| P4-K03 | `SUCCESS` | Tap a frequent or trending keyword | Keyword Detail opens | 3.7 navigation |
| P4-K04 | `SUCCESS` | Inspect Keyword Detail | Publication trend, related journals, related publications and top authors appear | 3.8 detail |
| P4-K05 | `BOUNDARY` | Compare author ranking counts | Authors are sorted descending by related publication count | 3.8 ranking |
| P4-K06 | `FAILURE` | Disable network and search another keyword topic | Error card appears; app does not crash | 5 error state |
| P4-K07 | `BOUNDARY` | Search data without usable keywords/topics | `No keywords were found for this topic.` appears | 3.7 empty state |
| P4-K08 | `EVIDENCE` | Open a keyword and related publication; inspect Analytics | `view_keyword` and `view_publication` appear with required parameters | 4.1 events |
| P4-K09 | `SUCCESS` | Load another page in Keywords | Loaded count increases and keyword frequency/trends update without changing Home/Journals state | Independent cursor pagination |

## 10. Phase 5 - Profile, PDF and Firebase Storage

| ID | Type | Test steps | Expected result | Requirement |
| --- | --- | --- | --- | --- |
| P5-01 | `SUCCESS` | Complete a Home search, then open Profile | Report card shows the Home topic and publication count | 3.9 report source |
| P5-02 | `SUCCESS` | Tap `Generate & Upload PDF` | UI transitions through `Generating PDF document...` and Storage upload progress | Phase 5 progress |
| P5-03 | `SUCCESS` | Wait for upload completion | Green success state, selectable download URL, `Open PDF` and `Copy URL` appear | 3.9 export URL |
| P5-04 | `SUCCESS` | Open the generated PDF | Valid readable PDF opens with topic, timestamp/source, KPI, trend, top journals/authors/publications and page numbers | Phase 5 PDF DoD |
| P5-05 | `SUCCESS` | Tap `Copy URL` and paste it into a text field/browser | Correct download URL is copied | 3.9 URL usability |
| P5-06 | `EVIDENCE` | Inspect Firebase Storage Console after success | File exists at `reports/{UserA_UID}/journal_trend_<topic>_<timestamp>.pdf` with PDF content type | 4.2 path convention |
| P5-07 | `EVIDENCE` | Inspect Analytics after successful upload | `export_pdf` appears with the Home `topic`; it is not emitted on failed upload | 4.1 event |
| P5-08 | `FAILURE` | With no successful Home data, open Profile and export | Message asks user to search a topic on Home; app does not upload an empty report | Phase 5 validation |
| P5-09 | `FAILURE` | Disable network before upload | Upload times out within 60 seconds, cancels the task, and shows `Retry` without logging `export_pdf` | Phase 5 upload failure |
| P5-10 | `INTERRUPTED` | After P5-09, restore network and tap `Retry` | Same report request is regenerated/uploaded and success URL appears | Phase 5 retry |
| P5-11 | `INTERRUPTED` | Rapidly tap export while generating/uploading | Button is disabled; only one export flow/upload starts | Duplicate protection |
| P5-12 | `INTERRUPTED` | Start export, then Sign Out before generation completes | Login Screen appears; no Flutter exception or disposed-state crash occurs | Lifecycle safety |
| P5-12A | `INTERRUPTED` | Tap `Cancel export` during the actual Storage upload | UploadTask is cancelled, the state is retryable, and no `export_pdf` event is logged | Real upload cancellation |
| P5-13 | `INTERRUPTED` | Force close app during upload, reopen and login | App starts normally. In-process progress is reset; user can export again. Process-death resume is not required by Phase 5 | App interruption |
| P5-14 | `FAILURE` | Use invalid/unpublished Storage Rules or unavailable billing | Generic Storage error and retry appear; app remains usable | Firebase rejection |
| P5-15 | `SECURITY` | In Storage Rules Playground or authenticated SDK, access User A path as User B | Read/write is denied because `request.auth.uid != userId` | 4.2 UID ownership |
| P5-16 | `SECURITY` | Attempt Storage access without authentication | Read/write is denied | 4.2 authenticated access |
| P5-17 | `BOUNDARY` | Export a topic containing spaces/symbols | Upload succeeds with a safe filename and `.pdf` extension | Filename boundary |
| P5-18 | `BOUNDARY` | Export a Vietnamese topic such as `Trí tuệ nhân tạo` | PDF keeps the text readable by normalizing it to `Tri tue nhan tao`; no black squares or broken glyphs | PDF text boundary |

## 11. Requirement coverage summary

| Requirement area | Covered by | Expected Phase 1-5 status |
| --- | --- | --- |
| Firebase bootstrap/config | P1-01 to P1-05 | Complete |
| Google Authentication/Profile/Logout | P2-01 to P2-09 | Complete |
| Analytics events implemented through Phase 5 | P2-10, P4-H12, P4-J08, P4-K08, P5-07 | Implemented; Console evidence remains manual |
| Remote Config core and two values | P2-07, P2-08 | Complete |
| Four-tab MVVM navigation and independent state | P3-01 to P3-06 | Complete |
| Home and Publication Detail | P4-H01 to P4-H12 | Complete |
| Journals and Journal Detail | P4-J01 to P4-J08 | Complete |
| Keywords and Keyword Detail | P4-K01 to P4-K08 | Complete |
| PDF generation and Storage upload | P5-01 to P5-17 | Implemented; Console/security evidence remains manual |

## 12. Manual execution record

Use this table while testing:

| Test ID | Actual result | PASS/FAIL/BLOCKED | Screenshot/evidence | Notes |
| --- | --- | --- | --- | --- |
| Example: P2-01 | Home opened after Google login | PASS | `evidence/P2-01.png` | User A |

Do not mark a test `FAIL` when an external prerequisite is missing. Use `BLOCKED` for cases such as Firebase billing disabled, unpublished rules, missing SHA certificate, Analytics processing delay or OpenAlex outage, and record the exact blocker.
