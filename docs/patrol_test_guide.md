# Patrol E2E Test Guide

## Purpose and scope

This runbook covers the 11 Patrol scenarios required by Lab 03. The suite uses
real Firebase services and real OpenAlex responses on an Android emulator.

## Last successful full-run baseline

The complete suite reached the following baseline on 2026-07-16 with Flutter
3.44.2, Patrol package 4.7.1, Patrol CLI 4.5.1, and Android
`emulator-5554`:

```text
Total: 11
Successful: 11
Failed: 0
Skipped: 0
Duration: 8m 16s
Report: build/app/reports/androidTests/connected/debug/index.html
```

This baseline predates the final API-key injection, request de-amplification,
and stronger detail assertions. A later diagnostic run without an OpenAlex key
exhausted the anonymous daily budget and overwrote the local HTML report with a
429-related failure. The HTML report and generated test bundle are ephemeral
build artifacts and are not committed. Run the current source with a free
OpenAlex key and confirm a fresh 11/11 before collecting final screenshots.

| Test case | Scenario | Source file |
| --- | --- | --- |
| TC01 | Google Sign-In | `patrol_test/01_authentication_test.dart` |
| TC02 | Topic Search | `patrol_test/02_publication_test.dart` |
| TC03 | Publication Details | `patrol_test/02_publication_test.dart` |
| TC04 | Journals Navigation | `patrol_test/04_journal_test.dart` |
| TC05 | Journal Details | `patrol_test/04_journal_test.dart` |
| TC06 | Keywords Navigation | `patrol_test/06_keyword_test.dart` |
| TC07 | Keyword Details | `patrol_test/06_keyword_test.dart` |
| TC08 | Profile Navigation | `patrol_test/08_profile_test.dart` |
| TC09 | PDF Export and Firebase Storage upload | `patrol_test/09_export_test.dart` |
| TC10 | Firebase Remote Config | `patrol_test/10_remote_config_test.dart` |
| TC11 | Logout | `patrol_test/11_logout_test.dart` |

The numeric prefixes are intentional. Patrol CLI sorts discovered test paths
lexically, and tests declared in the same file retain declaration order. TC11
therefore has its own final target instead of running beside TC01.

Firebase Cloud Messaging, Analytics console verification, and Crashlytics
delivery are intentionally outside these 11 scenarios. Verify them with the
existing manual Firebase guides. A test crash must never be part of the Patrol
suite because it deliberately terminates the app under test.

## One-time workstation setup

1. Use the Flutter version supported by the pinned `patrol` dependency.
2. Install Patrol CLI 4.5.1 and ensure the Pub cache `bin` directory is in
   `PATH`. The Flutter package is independently pinned to 4.7.1 in
   `pubspec.yaml`.
3. Start an Android emulator image that includes Google Play services.
4. Add a dedicated Google test account to the emulator before running Patrol.
   Complete any first-time Google consent screens manually.
5. Create a free OpenAlex API key at
   [OpenAlex API settings](https://openalex.org/settings/api). Repeated live E2E
   searches can exhaust the much smaller anonymous daily budget.
6. Keep the emulator language in English and make sure it has internet access.
7. Confirm `android/app/google-services.json` belongs to the intended Firebase
   project and that the debug SHA-1/SHA-256 fingerprints are registered.
8. Confirm Firebase Authentication enables Google Sign-In.
9. Confirm Firebase Storage rules allow an authenticated user to upload only
   under that user's UID.
10. Publish the `max_journals_displayed` and `max_keywords_displayed` Remote
   Config parameters. Their values must be positive integers.

Do not put a password, access token, Firebase service-account key, OpenAlex key,
or OpenAI key in the repository. Pass `OPENALEX_API_KEY` only as a local
`--dart-define` for development and Patrol. A Dart define is embedded in the
APK/IPA and is not secret storage; do not use this client-side approach for a
production release that needs a protected key. `PATROL_GOOGLE_ACCOUNT` is
optional: when omitted, Patrol
selects the first visible account whose text contains `@`. Set it when the
emulator contains more than one Google account so the choice is deterministic.

## Confirm the device

From the project root in PowerShell:

```powershell
flutter devices
```

The examples below use `emulator-5554`. Replace it if `flutter devices` shows a
different identifier.

## Run one test file during development

If the emulator contains more than one account, set the dedicated account email
only for the current PowerShell session:

```powershell
$env:OPENALEX_API_KEY = 'your-free-openalex-key'
$env:PATROL_GOOGLE_ACCOUNT = 'your-test-account@example.com'
patrol develop --target patrol_test/01_authentication_test.dart --device emulator-5554 --dart-define=OPENALEX_API_KEY=$env:OPENALEX_API_KEY --dart-define=PATROL_GOOGLE_ACCOUNT=$env:PATROL_GOOGLE_ACCOUNT
```

Use `r` inside the Patrol development session to rerun after a source change.
Run another scenario by changing the target file, for example:

```powershell
patrol develop --target patrol_test/09_export_test.dart --device emulator-5554 --dart-define=OPENALEX_API_KEY=$env:OPENALEX_API_KEY --dart-define=PATROL_GOOGLE_ACCOUNT=$env:PATROL_GOOGLE_ACCOUNT
```

## Run the complete suite

Because `patrol_test/` is the Patrol 4 default directory, no target is required
for the full suite:

```powershell
$env:OPENALEX_API_KEY = 'your-free-openalex-key'
$env:PATROL_GOOGLE_ACCOUNT = 'your-test-account@example.com'
patrol test --device emulator-5554 --dart-define=OPENALEX_API_KEY=$env:OPENALEX_API_KEY --dart-define=PATROL_GOOGLE_ACCOUNT=$env:PATROL_GOOGLE_ACCOUNT
```

Each scenario initializes Firebase and independently calls `ensureSignedIn`.
The tests therefore do not rely on TC01 running first. TC01 signs out first so
that it always exercises Google Sign-In, while TC11 finishes on the Login
screen.

## Expected results

| Test | Success evidence | Common failure meaning |
| --- | --- | --- |
| TC01 | Home screen appears after selecting the configured account | Account is absent from emulator, SHA fingerprint is wrong, or Google Auth is disabled |
| TC02 | OpenAlex loaded status and an influential publication card appear | Network/OpenAlex request failed or returned no usable works |
| TC03 | Detail exposes title, year, journal, authors, and a non-negative citation count | Publication navigation or result mapping failed |
| TC04 | Positive Works/Journals metrics, a non-negative citation metric, and the first journal appear | OpenAlex failed or loaded works contain no journal metadata |
| TC05 | Journal name, positive publication count, and the first related publication appear | Journal item did not navigate or aggregation failed |
| TC06 | Positive Works/Unique Keywords metrics, a top keyword, and the first keyword appear | OpenAlex failed or loaded works contain no keyword/topic metadata |
| TC07 | Keyword summary, trend, first related journal/author/publication, and analysis sections appear | Keyword navigation or detail aggregation failed |
| TC08 | Profile shows a non-empty name and authenticated email; when configured, the email matches `PATROL_GOOGLE_ACCOUNT` | Firebase Auth state or profile binding is incorrect |
| TC09 | Success banner and a valid HTTPS download URL appear | Storage rule, authentication, network, PDF generation, or upload failed |
| TC10 | Success message and positive integer config values appear | Remote Config parameters are unavailable or fetch failed |
| TC11 | Google Sign-In button reappears | Firebase/Google sign-out did not complete |

Remote Config is successful even when Firebase reports that the fetched values
are unchanged. TC10 validates the resulting values instead of requiring an
activation change.

OpenAlex data changes over time. The tests deliberately avoid hard-coded paper,
journal, keyword, count, or citation values. They validate non-empty results and
required UI fields instead. Each topic search waits for the tab's initial
request to finish. The OpenAlex service performs one bounded three-attempt HTTP
retry policy with 1/2-second backoff; Patrol does not stack another request
loop. A final failure is reported honestly and the suite never substitutes
fixture data for a failed live OpenAlex request.

## Firebase checks after the suite

### TC01 and TC11: Authentication

In Firebase Console, open **Authentication > Users** and confirm the dedicated
account exists. Patrol does not create or store its password.

### TC09: Storage

1. Copy the HTTPS URL displayed in the Profile report section.
2. Open **Firebase Console > Storage > Files**.
3. Confirm the generated PDF is stored under the signed-in user's UID.
4. Open the URL and confirm that a valid PDF is returned.

Firebase download URLs can contain a capability token in the query string.
Never paste the full URL into a public report; redact the query/token in any
screenshot and use the Storage object path as evidence instead.

### TC10: Remote Config

1. Open **Firebase Console > Remote Config**.
2. Compare the published values with the values shown in the Profile screen.
3. Preserve a screenshot containing both parameter names and published values.

## Evidence checklist

For the report, retain:

- The terminal test summary showing 11 successful scenarios.
- The Android native HTML report path printed by Patrol. Without a flavor, it
  is normally under
  `build/app/reports/androidTests/connected/debug/index.html`.
- One emulator screenshot for Authentication, OpenAlex navigation, PDF export,
  and Remote Config.
- Firebase Console screenshots for the authenticated user, uploaded PDF path,
  and published Remote Config values.
- A short note for every scenario stating its action and observed result.

Do not commit account emails, API keys, or Firebase download URL query tokens in
screenshots. Redact them whenever the repository or report may be public.

## Troubleshooting

### The Google account chooser cannot find the configured email

- Confirm the exact email was added under Android emulator accounts.
- Run TC01 with `PATROL_GOOGLE_ACCOUNT` set to that exact email.
- Complete first-time Google Play and consent dialogs manually.
- Recheck debug SHA-1/SHA-256 and download a fresh `google-services.json` if the
  Android Firebase app configuration changed.

### Firebase initialization fails

- Check emulator internet access.
- Check `google-services.json` and Android application ID alignment.
- Confirm the Firebase project services used by the app are enabled.

### TC09 returns permission denied

- Confirm the Patrol account is authenticated.
- Publish Storage rules that permit the current UID's report path.
- Verify the bucket in `google-services.json` matches the bucket inspected in
  Firebase Console.

### OpenAlex tests time out

- Open a website in the emulator to confirm connectivity.
- Confirm a non-empty `OPENALEX_API_KEY` was passed to Patrol. OpenAlex replaced
  the old `mailto` polite-pool mechanism with API keys in February 2026.
- Check the test output or make one lightweight request for HTTP `429`. It can
  mean the daily budget is exhausted; check the OpenAlex usage page or rate
  limit headers, then wait for reset instead of repeatedly rerunning the suite.
- Retry after OpenAlex is reachable. The suite already performs bounded retries
  with backoff, so do not wrap it in an unbounded shell retry loop.
- Do not replace assertions with fixed publication titles or counts.

### A generated `test_bundle.dart` appears

Patrol generates `patrol_test/test_bundle.dart` while bundling tests. It is a
build artifact and must not be committed.

## Design notes

The Patrol bootstrap calls `FirebaseBootstrap.initialize()` and pumps
`JournalSearchApp` directly. It never calls the production `main()` and never
changes `FlutterError.onError`. This keeps real Firebase initialization while
allowing Patrol to observe test failures instead of passing them to the
production Crashlytics handler.

References: [Patrol installation](https://patrol.leancode.co/documentation),
[writing Patrol tests](https://patrol.leancode.co/documentation/write-your-first-test),
[Patrol 4 platform automation migration](https://patrol.leancode.co/native-to-platform-migration),
[logs and native reports](https://patrol.leancode.co/documentation/logs), and
[OpenAlex authentication and limits](https://developers.openalex.org/api-reference/authentication).
