# Lab 03 Requirements and Implementation Roadmap

> Nguon yeu cau: `docs/PRM393 Lab 03 Firebase-Powered Journal Trend Analyzer.pdf` (11 trang).  
> Ngay doi chieu gan nhat: 2026-07-15.
> File nay la tai lieu chuan de tiep tuc phat trien Lab 03. Cac lan sau can doc file nay truoc, khong can doc lai PDF neu de bai khong thay doi.

## 1. Muc tieu cua Lab 03

Nang cap ung dung Journal Trend Analyzer cua Lab 02 thanh ung dung Flutter co ket noi Firebase, van dung OpenAlex API lam nguon du lieu publication chinh.

Ung dung phai ho tro:

- Google Sign-In bang Firebase Authentication.
- Phan tich publication, journal va keyword tu OpenAlex.
- Xuat bao cao PDF va upload len Firebase Storage.
- Push notification bang Firebase Cloud Messaging (FCM).
- Theo doi hanh vi bang Firebase Analytics.
- Theo doi loi/crash bang Firebase Crashlytics.
- Dieu khien cau hinh bang Firebase Remote Config.
- Kiem thu E2E bang Patrol.
- AI-assisted code review.
- Kien truc MVVM voi Provider hoac Riverpod.

## 2. Cac quyet dinh rieng cua project

- Android application ID hien tai duoc giu la `com.example.journal_trend_analysis` theo yeu cau cua chu project; chua doi sang Student ID.
- Giai doan phat trien va test chinh dung Android Studio va Android emulator.
- iOS/IPA se duoc cau hinh va build sau tren macOS.
- Search state cua Home, Journals va Keywords phai doc lap. Search o mot tab khong tu dong thay doi topic/ket qua cua hai tab con lai.
- Toan bo text hien thi trong app va PDF report dung tieng Anh de dong nhat san pham; tai lieu noi bo co the tiep tuc dung tieng Viet.
- Topic analysis dung OpenAlex cursor pagination: 100 works/request, `Load next 100`, `Load all N`/`Load up to 1,000`, progress/cancel/retry, total count tu metadata va safety cap 1,000 works/tab. Khong fetch toan bo result set tren mobile. Chi tiet: `docs/openalex_pagination_decision.md`.
- OpenAlex van la nguon publication data chinh; Firebase khong thay the OpenAlex.
- Crashlytics va FCM duoc trien khai o phase rieng, khong duoc lam hong Auth/Analytics/Remote Config hien tai.

## 3. Functional requirements

### 3.1 Authentication

- Co Login screen.
- Dang nhap bang Google account qua Firebase Authentication.
- Hien profile picture, display name va email cua user da dang nhap.
- Co Sign Out.
- Sau login thanh cong, dieu huong den Home.
- Sau logout, quay lai Login.

### 3.2 Bottom navigation

De bai bat buoc dung Bottom Navigation Bar gom dung bon khu vuc:

1. Home
2. Journals
3. Keywords
4. Profile

### 3.3 Home

- Search publication theo topic.
- Hien publication trend theo thoi gian bang chart.
- Hien total publications.
- Hien average citation count.
- Hien most active publication year.
- Hien top contributing author.
- Hien top journal.
- Hien most influential publication.
- Chon publication de mo Publication Detail.

### 3.4 Publication Detail

- Title.
- Authors.
- Publication year.
- Journal name.
- Citation count.
- DOI.
- Abstract neu co.
- Link mo publication goc neu co.

### 3.5 Journals

- Search/analyze theo topic rieng cua tab Journals.
- Top journals xep theo publication count.
- Publication statistics cua tung journal.
- Journal contribution chart.
- Citation statistics theo journal.
- Chon journal de mo Journal Detail.

### 3.6 Journal Detail

- Journal name.
- Total publications.
- Total citations.
- Average citations per publication.
- Related publications.

### 3.7 Keywords

- Search/analyze theo topic rieng cua tab Keywords.
- Most frequent keywords.
- Trending keywords.
- Keyword frequency statistics.
- Keyword trend charts.
- Chon keyword de mo Keyword Detail.

### 3.8 Keyword Detail

- Publication trends over time.
- Related journals.
- Related publications.
- Top contributing authors.
- Author publication counts.
- Author ranking/list/chart sap xep giam dan theo so publication lien quan den keyword.

### 3.9 Profile

Profile la noi tap trung user account va cac Firebase demo.

User information:

- Profile picture.
- User name.
- Email.
- Sign Out.

Notification Center:

- Hien notification nhan tu FCM.
- Co the demo trending topic, highly cited publication alert hoac research trend update.

Report Export:

- Tao PDF tu dashboard analytics.
- Upload PDF len Firebase Storage.
- Hien URL cua file da upload.

Remote Config Demo:

- Lay va hien toi thieu hai gia tri Remote Config.
- Project dung `max_journals_displayed` va `max_keywords_displayed`, default deu la `10`.

Crashlytics Demo:

- Nut tao handled exception.
- Nut tao test crash.

## 4. Firebase requirements

| Firebase service | Muc dich bat buoc | Trang thai hien tai |
| --- | --- | --- |
| Authentication | Google Sign-In | Phase 2 da hoan tat Login Screen, auth gate, user banner va logout; Profile day du lam o Phase 5 |
| Storage | Luu PDF export | Phase 5 da co generate/upload PDF, progress, retry va URL; cho Firebase Console evidence |
| Cloud Messaging | Push notification | Phase 6 da implement Notification Center va lifecycle FCM; cho Android Console evidence |
| Analytics | Theo doi user activity | Du 7 event bat buoc va automated catalog test; cho DebugView evidence |
| Crashlytics | Crash monitoring | Phase 7 da co handled exception/test crash an toan; cho Console evidence |
| Remote Config | Dynamic configuration | Da fetch, dung/hien hai limit va co Fetch & Activate demo trong Profile |

### 4.1 Analytics events bat buoc

| Event | Khi nao gui | Parameters bat buoc/phu hop |
| --- | --- | --- |
| `login` | Google login thanh cong | Co the them provider |
| `search_topic` | User search topic | `keyword` |
| `view_publication` | Mo Publication Detail | `publication_title`, `publication_year` |
| `view_journal` | Mo Journal Detail | `journal_name` |
| `view_keyword` | Mo Keyword Detail | `keyword` |
| `export_pdf` | Export va upload PDF | `topic` |
| `logout` | User sign out | Khong bat buoc parameter |

Can chup evidence cac event da record de dua vao project report.

### 4.2 Storage convention va rules

- Duong dan report du kien: `reports/{userId}/{fileName}.pdf`.
- Chi user da authenticate va co UID trung voi `{userId}` moi duoc read/write.
- Khong dua service-account key hoac FCM server credential vao mobile app/repository.

## 5. Technical and architecture requirements

- Flutter va Dart.
- Goi truc tiep OpenAlex API.
- API communication bat dong bo.
- Co loading, empty va error state ro rang.
- Cau truc sach, de bao tri.
- State management bang Provider hoac Riverpod.
- Bat buoc MVVM, tach ro:
  - Models
  - Services/Repositories
  - ViewModels
  - Views/Screens
- Business logic khong dat truc tiep trong UI screen.
- Chay duoc tren Android device va Android emulator.
- UI responsive, consistent va de dieu huong.

## 6. Screens bat buoc

1. Login Screen
2. Home Screen
3. Publication Detail Screen
4. Journals Screen
5. Journal Detail Screen
6. Keywords Screen
7. Keyword Detail Screen
8. Profile Screen

## 7. Patrol E2E requirements

Phai co day du 11 test scenario:

1. Google Sign-In: launch, login, xac nhan vao Home.
2. Topic Search: nhap topic, search, co publication results.
3. Publication Details: mo publication va xac nhan thong tin.
4. Journals Navigation: mo Journals, co statistics va journal list.
5. Journal Details: mo journal va xac nhan detail.
6. Keywords Navigation: mo Keywords, co statistics va keyword list.
7. Keyword Details: mo keyword va xac nhan analysis.
8. Profile Navigation: mo Profile va xac nhan user info.
9. PDF Export: generate, upload Storage va xac nhan thanh cong.
10. Remote Config: retrieve va xac nhan config values.
11. Logout: logout va xac nhan quay lai Login.

Suggested test structure:

```text
patrol_tests/
|-- authentication_test.dart
|-- publication_test.dart
|-- journal_test.dart
|-- keyword_test.dart
|-- profile_test.dart
|-- export_test.dart
`-- remote_config_test.dart
```

Evidence can co source-code screenshots, execution screenshots, result summary va giai thich ngan cho tung scenario.

## 8. Deliverables

### 8.1 Source code

- GitHub repository theo ten de bai: `PRM393_Lab03_StudentID`.
- Complete source code.
- Firebase configuration files can thiet.
- Patrol test scripts.
- Assets va resources.

Luu y: project hien tai tam thoi van giu application ID `.example` theo quyet dinh cua chu project.

### 8.2 Project report

Bao cao khoang 5-10 trang, gom:

- Project overview.
- System architecture.
- MVVM implementation.
- Firebase integration design.
- Feature screenshots.
- Firebase Analytics events.
- Crashlytics reports.
- Remote Config demo.
- Patrol scenarios va results.
- AI-assisted code review findings.
- Challenges va lessons learned.

### 8.3 Demonstration video

Video khoang 5-10 phut, demo:

- Google Sign-In.
- Topic search.
- Publication details.
- Journal analysis.
- Keyword analysis.
- Author analysis.
- PDF export/upload.
- Push notifications.
- Remote Config.
- Crashlytics testing.
- Patrol testing.
- AI-assisted code review.

## 9. Evaluation weights

| Criterion | Weight |
| --- | ---: |
| Functional Requirements | 30% |
| Firebase Integration and Analytics | 25% |
| Architecture - MVVM and Provider/Riverpod | 10% |
| UI/UX and App Quality | 10% |
| Patrol Automated Testing | 15% |
| AI-Assisted Code Review | 5% |
| Report and Demonstration | 5% |

## 10. Current project audit

### 10.1 Da co

- OpenAlex service, repository, models va analytics calculations.
- Dashboard, analysis/search UI va Publication Detail.
- Loading/error handling cho phan OpenAlex.
- Ba search state doc lap bang ba `ValueNotifier`, dung voi quyet dinh cua project.
- Firebase dependencies va Android Google Services configuration.
- Google Authentication da test login thanh cong.
- Da co Login Screen/auth gate: chua login khong vao app; login vao app; logout quay lai Login.
- Da co Bottom Navigation 4 tab bat buoc: Home, Journals, Keywords, Profile.
- Da them Provider va `viewmodels/` cho authentication cung ba research tab doc lap.
- Data loading, topic, publication limit va recent searches da duoc chuyen vao ViewModel.
- Da co Profile foundation hien user, sign out va hai Remote Config values.
- Da co typed route helper cho Publication Detail.
- Da chan stale OpenAlex response va update state sau khi repository dispose.
- Home, Journals va Keywords dung cursor pagination 100 works/request, co tai tung trang hoac tai tu dong mot cham den cap, hien progress/cancel/retry va gioi han 1,000 works cho moi tab.
- Da co Journals Screen, journal contribution/statistics va Journal Detail.
- Da co Keywords Screen, frequency/trending/trend chart va Keyword Detail voi author ranking.
- Publication Detail co link mo DOI/OpenAlex publication goc.
- SHA-1 va SHA-256 da them vao Firebase Android app.
- Remote Config defaults/fetch va gioi han journal/keyword.
- Analytics tracking service cho day du ten event bat buoc.
- Analytics navigator observer da duoc gan khi Firebase active.
- Analytics va Remote Config dung lazy Firebase access, khong lam crash widget test/offline fallback.
- Storage service va user-scoped Storage Rules khung.
- Profile co PDF export tu analytics cua Home, upload progress, download URL, open/copy URL va retry.
- PDF report co key metrics, publication trend, top journals, top authors va top influential publications.
- Upload report dung path `reports/{uid}/{fileName}.pdf`; `export_pdf` chi gui sau khi upload thanh cong.
- Messaging service/bootstrap va Crashlytics service khung.
- Phase 6 co Notification Center luu local toi da 50 tin, unread badge, permission/token UI va xu ly foreground/background/opened.
- Phase 7 co Firebase Demo ViewModel/UI cho Remote Config refresh, handled exception va test crash co confirmation.
- Analytics dung catalog constants cho dung 7 event bat buoc va cac parameter theo requirement.
- Analyzer sach, 114 automated tests pass; Android debug APK build thanh cong sau OpenAlex pagination va robustness review.
- Report export co lifecycle guard, khong notify/upload tiep neu ViewModel bi dispose trong luc generate.
- Toan bo user-facing copy cua app va PDF report da duoc chuyen sang tieng Anh; PDF mau 2 trang da render va kiem tra truc quan.
- Patrol 4 da duoc cau hinh cho Android Test Orchestrator; 8 ordered test target bao phu dung 11 scenario cua de bai va full baseline dat 11/11 tren `emulator-5554` ngay 2026-07-16.

### 10.2 Con thieu hoac chua dat

- Phase 6 con cho manual FCM Console verification tren Android emulator/device.
- Phase 7 con cho manual Crashlytics, Remote Config va Analytics Console evidence.
- Phase 5 con cho manual verification tren Android/Firebase Console: file trong bucket dung UID, URL mo duoc va rules chan user khac.
- Con can chup/luu screenshot Firebase Console va Patrol HTML report de dua vao bao cao; source test va execution summary da co.
- Chua hoan tat report va demo video.
- iOS Firebase config chua hoan tat; se xu ly tren Mac truoc khi build IPA.

## 11. Implementation roadmap

Roadmap nay thay the cac ghi chu phase khong chinh thuc truoc day. Moi phase chi duoc danh dau complete khi dat Definition of Done.

### Phase 1 - Firebase foundation - DONE

Scope:

- Them FlutterFire dependencies.
- Android Google Services/Crashlytics Gradle setup.
- Dat `google-services.json` dung package `.example`.
- Tao Firebase bootstrap va service wrappers.
- Tao Remote Config keys va Storage rules khung.
- Firebase Console: Auth, Analytics, Storage va Remote Config.
- Them SHA-1 va SHA-256.

Definition of Done:

- App khoi dong duoc tren Android emulator voi Firebase initialized.
- Khong dua secret server-side vao repo.

### Phase 2 - Authentication, Analytics and Remote Config core - DONE

Scope da hoan tat:

- Google Sign-In/Sign-Out service.
- Login thanh cong tren emulator.
- Login Screen va auth gate theo Firebase auth state.
- User chua login chi thay Login; login thanh cong vao app; logout quay lai Login.
- Loading/error state va chan duplicate tap khi Google Sign-In.
- Analytics wrappers va gan event vao cac flow hien co.
- Analytics navigator observer.
- Fetch/activate Remote Config.
- Dung config cho max journals va max keywords.
- Remote Config/Analytics khong lam crash app/test khi Firebase unavailable.
- Analyzer sach va toan bo 26 test hien tai pass.

Cong viec lien quan se lam o phase sau:

- Dua user info, logout va config values vao Profile.
- Kiem chung Analytics DebugView va chup evidence.

### Phase 3 - MVVM foundation and required navigation - DONE

Scope:

- Chon Provider lam state management mac dinh neu khong co yeu cau khac.
- Tao `viewmodels/` va chuyen data loading/search/business state ra khoi screens.
- Doi shell thanh 4 tab: Home, Journals, Keywords, Profile.
- Map/tach UI hien co sang cac tab moi ma khong mat tinh nang OpenAlex.
- Giu search state cua Home/Journals/Keywords doc lap.
- Tao route/navigation typed hoac helper ro rang cho cac detail screen.

Ket qua:

- Dung Provider `6.1.5+1` va tao `AuthenticationViewModel`, `ResearchTabViewModel`.
- Home, Journals va Keywords co ba ViewModel/repository rieng, khong share topic/search state.
- Shell da co 4 tab va login thanh cong mac dinh vao Home.
- UI hien co duoc map tam thoi: Dashboard -> Home, Search -> Journals, Analysis -> Keywords.
- Profile foundation hien user info, Remote Config va Sign Out.
- Data loading/search orchestration da roi khoi cac screen chinh.
- Publication Detail dung route helper co route name/argument.
- OpenAlex repository bo qua response cu va khong update notifier sau dispose.
- Analyzer sach, 30 test pass, Flutter Web build thanh cong va da smoke test bang Chrome.

Definition of Done:

- Chay du 4 tab bat buoc.
- Login/logout navigation dung.
- Khong share search topic ngoai y muon giua ba tab.
- Business/data-loading logic chinh nam trong ViewModel, khong nam trong UI.
- Unit/widget tests hien co van qua.

### Phase 4 - Complete Home, Journals, Keywords and detail flows - DONE

Scope:

- Hoan thien Home metrics/chart va Publication Detail.
- Hoan thien Journals list, charts/statistics va Journal Detail.
- Hoan thien Keywords list, trend/frequency va Keyword Detail.
- Keyword Detail co related journals/publications va author ranking giam dan.
- Gan Analytics events tai dung thoi diem mo detail.

Definition of Done:

- Tat ca functional requirements muc 3.3-3.8 co UI va data thuc tu OpenAlex.
- Loading/empty/error states ro rang.
- Moi detail flow dieu huong dung va gui Analytics event dung parameters.

Ket qua:

- Chon fetch toi da 200 OpenAlex works cho moi topic; ViewModel va OpenAlex service deu gioi han o 200.
- Tai thoi diem Phase 4, Home dung sample 200. Quyet dinh nay da duoc thay the boi cursor pagination 100 works/request va cap 1,000 trong OpenAlex pagination upgrade.
- Publication Detail hien title, authors, year, journal, citations, DOI, abstract va link publication goc.
- Journals Screen xep hang journal theo publication count, co contribution bars va citation statistics.
- Journal Detail hien total publications, total/average citations va related publications.
- Keywords Screen hien frequency, trending ranking va keyword trend chart.
- Keyword Detail hien publication trend, related journals/publications va author ranking giam dan.
- `search_topic`, `view_publication`, `view_journal`, `view_keyword` duoc gui tai dung flow.
- Journal/keyword duoc chuan hoa khong phan biet hoa thuong va khong dem trung keyword trong cung publication.
- Analyzer sach, 34 tests pass va Flutter Web build thanh cong.

### Phase 5 - Profile, PDF export and Firebase Storage - IMPLEMENTED, PENDING MANUAL FIREBASE VERIFICATION

Scope:

- Profile user info va Sign Out.
- Tao PDF dashboard analytics cua topic duoc chon.
- Upload file vao `reports/{uid}/{fileName}.pdf`.
- Hien upload progress/result va download URL.
- Xu ly user chua login, upload failure va retry.
- Gui `export_pdf` sau khi export/upload thanh cong.

Definition of Done:

- PDF mo duoc, co noi dung analytics de doc va layout on dinh.
- File xuat hien trong Firebase Storage dung UID.
- User khac khong doc/ghi duoc report cua user hien tai.
- URL duoc hien tren Profile va event `export_pdf` duoc ghi.

Ket qua code va automated verification:

- Home ViewModel duoc chia se cho Profile trong `MainShell`; Journals va Keywords van co search state rieng.
- `PdfReportService` tao PDF A4 hai phan voi header/footer/page number, key metrics, trend va ranking tables.
- `ReportExportViewModel` quan ly generating/uploading/success/failure, upload progress va retry request gan nhat.
- Profile hien topic Home, so publication, nut generate/upload, status, download URL, open/copy va retry.
- Storage upload dung content type `application/pdf` va path `reports/{uid}/{fileName}.pdf`.
- Da render/kiem tra PDF mau 2 trang: text doc duoc, khong clipping/overlap va section publication khong bi orphan row.
- Analyzer sach, 44 tests pass; Flutter Web va Android debug build thanh cong.
- Bo sung regression tests cho OpenAlex limit, OpenAlex failure, duplicate export va dispose khi export bi gian doan.

Manual verification con lai truoc khi doi status thanh `DONE`:

- Export tren Android voi Firebase user that va xac nhan file xuat hien dung UID trong Storage Console.
- Mo download URL tu Profile va xac nhan PDF thuc te.
- Kiem tra rules khong cho user khac doc/ghi path cua UID hien tai.
- Xac nhan `export_pdf` trong Analytics DebugView/Events.

### Phase 6 - FCM and Notification Center - IMPLEMENTED, PENDING MANUAL FIREBASE VERIFICATION

Scope:

- Hoan tat Firebase Cloud Messaging Console/platform setup.
- Xin notification permission dung thoi diem.
- Xu ly foreground, background va notification-opened-app.
- Luu/hien notifications trong Profile Notification Center.
- Demo mot notification co nghia lien quan research trend.

Definition of Done:

- Emulator/device nhan duoc test notification.
- Notification Center hien thong tin nhan duoc.
- Tap notification dua user vao app va khong crash.

Ket qua code va automated verification:

- Notification permission chi duoc xin khi user bam `Enable notifications` trong Profile, khong prompt ngay luc app bootstrap.
- `NotificationCenterViewModel` xu ly `onMessage`, `onMessageOpenedApp`, `getInitialMessage` va token refresh.
- Foreground message hien SnackBar, unread badge o Profile va duoc them vao Notification Center.
- Background handler luu message bang `SharedPreferencesAsync`; app reload local store khi resume.
- Tap notification tu background/terminated dua app thang den tab Profile va danh dau message da doc.
- Notification duoc deduplicate theo FCM `messageId`, sap xep moi nhat truoc va gioi han 50 item.
- Profile cho copy FCM registration token de gui test message tu Firebase Console, danh dau da doc va xoa tat ca.
- Co fallback title/body cho data-only payload thieu noi dung; khong luu server key/service-account credential trong app.
- Co lifecycle guard neu logout/dispose trong luc FCM dang initialize.
- Analyzer sach, 55 automated tests pass; Flutter Web va Android debug build thanh cong.

Manual verification con lai truoc khi doi status thanh `DONE`:

- Cap notification permission tren Android emulator/device co Google Play services.
- Copy FCM token trong Profile va gui test message tu Firebase Console.
- Xac nhan foreground SnackBar/badge/Notification Center.
- Xac nhan background va terminated system notification; tap notification mo dung Profile va khong crash.
- Xac nhan notification van con sau khi restart app; checklist chi tiet o `docs/phase6_fcm_test_cases.md`.

### Phase 7 - Crashlytics, Remote Config demo and Firebase evidence - IMPLEMENTED, PENDING MANUAL FIREBASE EVIDENCE

Scope:

- Profile hien hai gia tri Remote Config.
- Them Refresh/Fetch config neu can cho demo.
- Them handled exception button.
- Them test crash button kem canh bao ro rang.
- Kiem chung 7 Analytics events bat buoc.
- Chup evidence Analytics, Crashlytics, Remote Config, Auth va Storage.

Definition of Done:

- Hai config values hien dung va thay doi theo Firebase Console.
- Handled error va test crash xuat hien trong Crashlytics.
- Tat ca event bat buoc xuat hien trong Analytics evidence.

Ket qua code va automated verification:

- Profile co Firebase Demo card hien `max_journals_displayed` va `max_keywords_displayed`.
- Nut `Fetch & Activate` tam bo qua minimum interval cho mot fetch demo, sau do khoi phuc interval 1 gio.
- Remote Config co loading, changed/unchanged success va network/Console error state.
- Handled exception ghi non-fatal `StateError`, reason, Crashlytics log va custom key `firebase_demo_type=handled_exception`.
- Test crash chi chay sau dialog canh bao ro app se dong va co nut `Cancel` an toan.
- Fatal demo gan custom key `firebase_demo_type=fatal_test_crash`; loi metadata khong chan crash da duoc user xac nhan.
- `FirebaseDemoViewModel` tach business state khoi Profile va co lifecycle guard khi dispose.
- Analytics dung mot catalog constants gom dung 7 event bat buoc: `login`, `search_topic`, `view_publication`, `view_journal`, `view_keyword`, `export_pdf`, `logout`.
- Analyzer sach, 69 automated tests pass; Flutter Web va Android debug build thanh cong.

Manual evidence con lai truoc khi doi status thanh `DONE`:

- Publish hai Remote Config value khac `10`, fetch trong Profile va chup ca Console + app.
- Gui handled exception, test crash, mo lai app va chup hai report trong Crashlytics Console.
- Chay du 7 user flow trong Analytics DebugView va chup event parameters.
- Chup them Auth user va Storage report de hoan tat Firebase evidence bundle.
- Checklist chi tiet: `docs/phase7_firebase_evidence_test_cases.md`.

### OpenAlex pagination upgrade - DONE

Scope:

- Migrate query parameter tu contract cu sang `per_page` toi da 100.
- Parse `meta.count`, `meta.next_cursor` va optional request cost.
- Cursor `*` cho trang dau; dung opaque next cursor cho trang sau.
- `Load next 100`, `Load all N`/`Load up to 1,000`, progress/cancel/retry/cap UI tren Home, Journals va Keywords.
- Gioi han 1,000 loaded works cho moi tab, khong fetch all tren device.
- Giu search/list/cursor state doc lap giua ba tab.
- Xu ly stale response, duplicate load-more, duplicate publication ID va repeated cursor; repeated cursor se dung pagination thay vi tao Retry loop.
- Retry co gioi han cho HTTP 429/5xx.
- Lazy-render journal cards va cache journal/keyword aggregation theo loaded list.

Ket qua:

- First page hien ngay 100 works va full result count tu OpenAlex metadata.
- Load-more failure khong xoa data/analytics da tai; user co the Retry dung cursor cu.
- Search topic moi invalidates first-page/load-more response cu.
- Publication Detail lookup khong con ghi de topic list/cursor state.
- UI ghi ro metrics va ranking chi dua tren loaded works.
- Analyzer sach, 114 automated tests pass; Android debug APK build thanh cong sau final review.
- Live OpenAlex smoke request xac nhan `meta.count`, `per_page` va `next_cursor`.

### Phase 8 - Automated testing and quality - DONE

Scope:

- Them Patrol dependency/config.
- Implement 11 E2E scenarios cua de bai.
- Hoan thien unit tests cho services, repositories va ViewModels.
- Widget tests cho loading/error/navigation quan trong.
- Chay analyzer, unit/widget tests va Patrol.

Definition of Done:

- 11 Patrol scenarios co source code va ket qua.
- Cac test co the chay lap lai tren Android emulator.
- Khong con analyzer error nghiem trong.
- Co HTML result summary va runbook/evidence checklist; screenshot submission duoc dong goi trong Phase 9.

Ket qua:

- Pin `patrol: 4.7.1`, Patrol CLI `4.5.1`, Android Test Orchestrator va native `PatrolJUnitRunner`.
- Co 8 ordered test target trong `patrol_test/`, bao phu dung TC01-TC11; numeric prefix va file TC11 rieng dam bao Patrol discovery chay dung thu tu. Moi scenario tu khoi tao Firebase va tu dam bao auth state.
- Google account email la optional `--dart-define`; neu khong truyen, test chon account dau tien trong native chooser ma co text chua `@`. Khong luu password/token trong repo.
- OpenAlex service ho tro optional `OPENALEX_API_KEY` qua `--dart-define` va gan `api_key` tap trung cho moi request list/detail; key khong duoc hard-code/commit/log. Dart define van nam trong client binary, nen chi dung cho local/Patrol; production can backend proxy neu key phai duoc bao mat.
- OpenAlex assertions khong hard-code title/count; Journal va Keyword dung `scrollTo()` de ho tro lazy-render list item. Test cho initial request cua tab ket thuc, con service so huu duy nhat mot retry policy 3 HTTP attempts voi backoff 1/2 giay de tranh stacked retry lam tang request.
- Full Patrol baseline tren Android `emulator-5554` ngay 2026-07-16: 11 total, 11 successful, 0 failed, 0 skipped, 8m16s. Baseline nay co truoc final API-key/request/assertion hardening; can refresh 11/11 voi free OpenAlex key truoc khi chup evidence.
- HTML report tam thoi nam tai `build/app/reports/androidTests/connected/debug/index.html` va co the bi ghi de boi diagnostic run; khong xem artifact local la 11/11 neu terminal summary khong khop. Runbook/evidence checklist: `docs/patrol_test_guide.md`.
- `flutter analyze --no-pub` sach va 116 unit/widget tests pass sau final review fixes.
- Screenshot terminal/HTML report va Firebase Console van can duoc luu vao report submission o Phase 9; day la evidence packaging, khong con la gap code/test.

### Phase 9 - AI review, documentation and release preparation

Scope:

- AI-assisted code review va ghi nhan toi thieu ba findings.
- Sua cac finding phu hop va document before/after.
- Viet report 5-10 trang.
- Quay demo video 5-10 phut theo checklist.
- Ra soat repository naming/config files/assets.
- Android release smoke test.
- Cau hinh Firebase iOS tren Mac, kiem tra Google Sign-In va build IPA.

Definition of Done:

- Source, report, video va evidence day du theo de.
- App demo end-to-end tren Android.
- iOS config/build duoc thuc hien tren Mac neu can nop IPA.

## 12. Quy tac cap nhat file nay

- Sau moi phase, doi status cua phase va cap nhat `Current project audit`.
- Neu de bai thay doi, doc lai PDF moi va cap nhat ngay nguon/ngay doi chieu.
- Khong danh dau `DONE` chi vi da viet service; phai dat Definition of Done va co test/evidence phu hop.
- Khi bat dau mot turn moi, doc muc 10 va 11 de biet trang thai va next phase.
