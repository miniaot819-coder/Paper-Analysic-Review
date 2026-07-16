# Lab 03 - Full App Review, Verification, and Manual Test Guide

Ngày lập: 15/07/2026
Project: Journal Trend Analyzer
Firebase project đã kiểm tra trong cấu hình Android: paperanalysis-858e0
Android package: com.example.journal_trend_analysis

## 1. Mục đích và phạm vi

Tài liệu này có hai mục đích:

1. Ghi lại kết quả review và verify toàn bộ app theo file PRM393 Lab 03 Firebase-Powered Journal Trend Analyzer.pdf.
2. Là runbook để test lại app bằng tay trên Android và thu thập evidence từ Firebase Console.

Patrol/E2E ở trang 8-9 của PDF được đánh dấu DEFERRED theo kế hoạch hiện tại. Patrol không được tính là lỗi trong đợt review này, nhưng vẫn phải bổ sung trước khi nộp Lab 03 chính thức.

Các nhãn dùng trong tài liệu:

| Nhãn | Ý nghĩa |
|---|---|
| AUTO PASS | Đã được kiểm tra bằng lệnh/test tự động trong đợt review này |
| CODE PASS | Code và wiring tồn tại, nhưng tính năng cloud vẫn cần chạy thật |
| AUTO/CODE PASS + MANUAL REQUIRED | Phần local đã pass nhưng vẫn cần device/Console evidence để kết luận requirement |
| MANUAL REQUIRED | Chỉ có thể kết luận sau khi test trên thiết bị/Firebase Console |
| PARTIAL | Có triển khai nhưng còn gap so với requirement hoặc rubric |
| MISSING | Chưa có artifact/evidence bắt buộc |
| DEFERRED | Chủ động để giai đoạn sau, hiện không tính là lỗi |

## 2. Kết quả verify hiện tại

### 2.1 Kiểm tra tự động đã chạy

| Hạng mục | Kết quả |
|---|---|
| flutter analyze | AUTO PASS - No issues found |
| flutter test | AUTO PASS - 114/114 tests passed |
| flutter build apk --debug | AUTO PASS |
| APK tạo ra | build/app/outputs/flutter-apk/app-debug.apk |
| Android signingReport | AUTO PASS |
| SHA-1 debug | 16:B1:58:EB:16:38:2B:6A:C0:3D:04:4D:8F:C6:9F:90:10:A3:C0:2A |
| SHA-256 debug | C6:D5:B3:49:64:16:F6:3C:E7:4B:ED:4D:AC:CF:E0:08:F4:40:C2:7B:A7:8C:A7:65:F2:1B:F3:61:82:10:A2:0D |
| SHA-1 khớp google-services.json | AUTO PASS |
| Android OAuth client và Web OAuth client | Có trong google-services.json |
| Secret scan cơ bản | Không thấy private key hoặc client secret bị hard-code |
| Kiểm tra Firebase runtime | User đã báo các luồng Firebase chính pass khi test tay; các thay đổi hardening trong tài liệu này vẫn cần targeted regression |

Lưu ý:

- SHA fingerprint không phải chuỗi tự điền. Nó phải đến từ keystore dùng để ký build đang chạy.
- google-services.json là Firebase client configuration, không phải service-account credential. Tuy vậy không được đưa service-account JSON, FCM server key hoặc private key vào app/repository.
- Android build hiện thành công nhưng Gradle có cảnh báo migration Kotlin plugin trong tương lai. Đây chưa phải lỗi build hiện tại.

### 2.2 Ma trận requirement PDF

| Requirement | Trạng thái | Kết luận |
|---|---|---|
| Flutter/Dart và OpenAlex API | CODE PASS | Gọi trực tiếp OpenAlex, có async, timeout/retry và cursor pagination |
| 4 tab Home, Journals, Keywords, Profile | CODE PASS | Dùng IndexedStack; state của ba tab tìm kiếm độc lập |
| Login bằng Google Firebase Auth | MANUAL REQUIRED | Code hoàn chỉnh; cần evidence app và Authentication Console |
| Home dashboard và trend analytics | CODE PASS | Có search, chart, metrics, top journals/authors và influential publication |
| Top contributing author | CODE PASS | Có Key Metric Top Author riêng và Top Authors ranking |
| Publication Detail | CODE PASS | Có title, authors, year, journal, citations, DOI, abstract và original link |
| Journals và Journal Detail | CODE PASS | Có ranking, contribution/citation stats và related publications |
| Keywords và Keyword Detail | CODE PASS | Có frequency/trend, related journals/publications và author ranking giảm dần |
| PDF report | AUTO/CODE PASS + MANUAL REQUIRED | Unit test pass; cần xem PDF thật với dữ liệu dài/Unicode |
| Upload Firebase Storage và URL | MANUAL REQUIRED | Code và local rules đúng path theo UID; cần Console evidence |
| FCM Notification Center | MANUAL REQUIRED | Code lifecycle có; chưa có message thật/evidence |
| Remote Config có ít nhất 2 values | MANUAL REQUIRED | Có 2 key; cần publish/fetch và chứng minh ảnh hưởng UI |
| Crashlytics handled và fatal crash | MANUAL REQUIRED | Có hai nút và global handlers; cần Crashlytics Console evidence |
| 7 Analytics events bắt buộc | AUTO/CODE PASS + MANUAL REQUIRED | Đủ tên/parameter trong code và catalog test; cần DebugView evidence |
| Provider/MVVM | CODE PASS | Data loading, dashboard aggregation và detail sorting/ranking đã được tách khỏi Views qua ViewModels |
| Responsive và navigation | MANUAL REQUIRED | Cần test màn nhỏ, xoay màn hình và font scale |
| AI-assisted code review, tối thiểu 3 findings | PARTIAL | Section 12 có findings; vẫn cần screenshot prompt/output và giải thích trong project report |
| Complete source, Firebase config, tests và assets | PARTIAL | Source/config/tests/assets Android có; README còn template, working tree/evidence và Patrol chưa hoàn tất |
| Project report 5-10 trang | MISSING | PDF app sinh ra không phải project report của Lab |
| Demo video 5-10 phút | MISSING | Quay sau khi hoàn tất Firebase evidence và Patrol |
| Repo name PRM393_Lab03_StudentID | MISSING | Remote hiện tại vẫn là PRM393-Lab2 |
| Patrol/E2E | DEFERRED | Sẽ implement sau theo quyết định hiện tại |

## 3. Quy tắc ghi kết quả test

Mỗi test case cần ghi:

| Trường | Cách ghi |
|---|---|
| Actual result | Điều thực tế nhìn thấy, không chỉ ghi “ok” |
| Status | PASS, FAIL, BLOCKED hoặc NOT RUN |
| Time | Thời gian chạy test |
| Device/build | Tên emulator/device và Git commit/build |
| Evidence | Tên screenshot/video/Console screenshot |
| Notes | Error text, độ trễ, điều kiện mạng hoặc cách khôi phục |

Tên evidence đề xuất:

    evidence/<TEST-ID>_<short-description>.png

Không đưa vào screenshot công khai:

- FCM registration token đầy đủ.
- PDF download URL đầy đủ vì đây là link chia sẻ có token.
- Email/UID cá nhân nếu report hoặc video được public.
- Service-account credential, server key hoặc private key.

## 4. Chuẩn bị môi trường test

### 4.1 Android

- Dùng Android emulator/device có Google Play services.
- Android 13 trở lên được khuyến nghị để thấy notification permission dialog.
- Chạy đúng package com.example.journal_trend_analysis.
- Dùng build mới nhất. Có thể chạy bằng:

      flutter run -d emulator-5554

- Chrome chỉ phù hợp để kiểm tra một phần UI/OpenAlex. Không dùng Chrome để kết luận Auth, Storage, FCM, Crashlytics hoặc Analytics của build Android.
- Chuẩn bị hai Google account test: User A và User B.
- Chuẩn bị mạng ổn định và khả năng tắt/bật Wi-Fi hoặc mobile data.
- Cho phép emulator mở browser/PDF viewer ngoài app.

### 4.2 Firebase Console

Kiểm tra trước khi test:

- Project đang chọn là paperanalysis-858e0.
- Project Settings có Android app com.example.journal_trend_analysis.
- SHA-1 và SHA-256 của debug keystore đã thêm.
- Authentication > Sign-in method đã bật Google.
- Storage bucket đã tạo và rules hiện hành đã Publish.
- Remote Config đã tạo hai parameter kiểu Number:

  - max_journals_displayed
  - max_keywords_displayed

- Cloud Messaging/Messaging Console có thể tạo test notification.
- Crashlytics dashboard đã được mở ít nhất một lần.
- Analytics đã bật cho project.

### 4.3 Thứ tự test được khuyến nghị

Chạy theo thứ tự dưới đây để evidence không bị thiếu:

1. Bật Analytics DebugView trước khi login.
2. Test Firebase bootstrap và Authentication.
3. Test navigation, Home, details, Journals, Keywords.
4. Test PDF và Storage.
5. Test Remote Config.
6. Test FCM ở foreground, background và terminated.
7. Test handled exception.
8. Test fatal Crashlytics cuối cùng vì app sẽ bị đóng.
9. Kiểm tra lại đủ 7 Analytics events trong DebugView.

## 5. Test Firebase bootstrap và Authentication

### 5.1 Bật Analytics DebugView trước khi bắt đầu

Khi emulator đã boot:

    adb shell setprop debug.firebase.analytics.app com.example.journal_trend_analysis

Nếu đang ở trong app từ phiên cũ, Sign Out rồi login lại sau khi bật DebugView.

### 5.2 Test cases

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| ENV-01 | SUCCESS | Mở app online sau fresh install | Chỉ thấy Login screen, app không crash |
| ENV-02 | EVIDENCE | Firebase Console > Project Settings > Android app | Package, SHA-1 và SHA-256 đúng build đang chạy |
| AUTH-01 | SUCCESS | Bấm Continue with Google, chọn User A | Vào Home; Authentication > Users có User A và Google provider |
| AUTH-02 | INTERRUPTED | Mở account chooser rồi bấm Back/Cancel | Vẫn ở Login; hiện Could not sign in with Google. Please try again.; không có event login |
| AUTH-03 | INTERRUPTED | Bấm Continue with Google liên tục | Chỉ một flow login; nút đổi thành Signing in... và bị disable |
| AUTH-04 | FAILURE | Tắt mạng rồi login | Có friendly error; không vào MainShell; app không crash |
| AUTH-05 | SUCCESS | Login thành công, đóng app, mở lại | Session được giữ và app vào Home |
| AUTH-06 | SUCCESS | Mở Profile | Avatar hoặc fallback, display name và email đúng User A |
| AUTH-07 | SUCCESS | Bấm Sign Out | Trở về Login; không còn truy cập bốn tab; event logout xuất hiện |
| AUTH-08 | SECURITY | Sau logout, force-close rồi mở lại | Vẫn ở Login |
| AUTH-09 | BOUNDARY | Login account không có photo | Hiện fallback avatar; layout không vỡ |
| AUTH-10 | EVIDENCE | Authentication > Users | Chụp user, UID/provider; che thông tin riêng nếu public |

Sau AUTH-08, login lại User A trước khi tiếp tục các section Home, Storage, FCM và Phase 7.

### 5.3 Firebase initialization failure và recovery

Gap fail-open đã được sửa. Nếu `Firebase.initializeApp` thất bại, app hiển thị màn hình setup error dạng blocking và không dựng Login/MainShell/protected tabs. Nút `Retry Firebase setup` chạy lại bootstrap; chỉ khi thành công app mới chuyển sang AuthGate.

Không xóa `google-services.json` trong branch chính chỉ để test. Hành vi failure/retry đã có widget test bằng initializer giả lập; nếu cần evidence trực quan, tạo controlled test branch/build riêng. Expected là màn hình lỗi có Retry, không nhìn thấy Home/Journals/Keywords/Profile.

## 6. Test navigation và dữ liệu OpenAlex

### 6.1 Navigation và tính độc lập của ba tab

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| NAV-01 | SUCCESS | Quan sát bottom navigation | Đúng 4 tab: Home, Journals, Keywords, Profile |
| NAV-02 | SUCCESS | Home search Artificial Intelligence; Journals search Cybersecurity; Keywords search Healthcare | Mỗi tab có topic/results riêng; search ở tab này không đổi hai tab còn lại |
| NAV-03 | INTERRUPTED | Search topic A rồi ngay lập tức search topic B trên cùng tab | Kết quả cuối chỉ thuộc topic B; response A không overwrite |
| NAV-04 | INTERRUPTED | Chuyển tab khi initial search/load-more đang chạy | Navigation responsive; state từng tab được giữ |
| NAV-05 | SUCCESS | Mở detail rồi bấm Android Back | Trở về đúng tab và giữ topic, results, scroll hợp lý |
| NAV-06 | BOUNDARY | Xoay portrait/landscape | Không overflow, không mất bottom navigation |
| NAV-07 | BOUNDARY | Tăng system font/display size | Nội dung scroll được; không che nút chính hoặc vỡ layout |
| NAV-08 | SUCCESS | Bấm icon search rồi icon notification ở header Home | Search icon focus ô tìm kiếm Home; notification icon chuyển sang Profile |
| NAV-09 | LANGUAGE | Đi qua toàn bộ 8 screens bắt buộc | UI labels/messages dùng English nhất quán, không còn mixed Vietnamese hoặc mojibake |
| NAV-10 | LANGUAGE | Mở PDF app vừa sinh | Nội dung report dùng English nhất quán; guide test này vẫn được viết bằng tiếng Việt |

### 6.2 Home dashboard

OpenAlex chỉ trả tối đa 100 works mỗi request. App vẫn hiển thị trang đầu ngay, nhưng bổ sung hai lựa chọn UX: `Load next 100` để kiểm soát data và `Load all N`/`Load up to 1,000` để tự động đi qua cursor bằng một lần bấm. Bulk load có progress, Cancel và Retry. Metrics/rankings/PDF được tính từ tập đã tải, không phải toàn bộ total matches của OpenAlex.

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| HOME-01 | SUCCESS | Search Artificial Intelligence | Loading rồi hiện dashboard; app không freeze |
| HOME-02 | SUCCESS | Kiểm tra summary | Có Loaded X of Y matching works; trang đầu không quá 100 works |
| HOME-03 | SUCCESS | Kiểm tra Key Metrics | Có Total Publications, Average Citations, Most Active Year, Top Journal, Top Author và Top Paper Citations |
| HOME-04 | REQUIREMENT | Kiểm tra tác giả | Có Key Metric Top Author riêng và Top Authors ranking; hai giá trị phù hợp dữ liệu đã tải |
| HOME-05 | SUCCESS | Kiểm tra charts/lists | Có Publication Trend, Top Journals, Top Authors và Most Influential Publication |
| HOME-06 | SUCCESS | Bấm Load next 100 | Dữ liệu cũ được giữ; loaded count, metrics, charts và rankings cập nhật; không duplicate publication |
| HOME-07 | SUCCESS | Bấm Load all N hoặc Load up to 1,000 | App tự tải tuần tự, progress tăng sau từng page; UI vẫn phản hồi |
| HOME-08 | INTERRUPTION | Đang bulk load, bấm Cancel | Dừng sau request đang chạy; không commit page đang bị hủy; dữ liệu cũ và cursor tiếp tục được giữ |
| HOME-08A | FAILURE | Tắt mạng trước Load next/bulk load | Data cũ còn; có lỗi và Retry; app không crash |
| HOME-09 | INTERRUPTED | Bật mạng rồi Retry | Tiếp tục đúng cursor; không tải lại sai topic |
| HOME-10 | FAILURE | Tắt mạng trước initial search | Có error state/friendly message; app không crash |
| HOME-11 | BOUNDARY | Search chuỗi chỉ có khoảng trắng | Không gửi request invalid; app không crash |
| HOME-12 | BOUNDARY | Search chuỗi ngẫu nhiên gần như không có kết quả | Có empty state, không render chart lỗi |
| HOME-13 | BOUNDARY | Với broad topic, bấm Load up to 1,000 | Dừng ở cap 1,000 và có cap notice; không gọi vô hạn |
| HOME-15 | INDEPENDENCE | Bulk load Home rồi xem Journals/Keywords | Hai tab kia giữ nguyên topic, list và cursor riêng |
| HOME-14 | BOUNDARY | Topic rất dài hoặc có Unicode | Search không crash; kiểm tra text wrap và Analytics boundary |

### 6.3 Publication Detail

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| PUB-01 | SUCCESS | Bấm Most Influential Publication | Mở Publication Detail |
| PUB-02 | SUCCESS | Kiểm tra nội dung | Có title, authors, year, journal, citations, DOI, abstract |
| PUB-03 | BOUNDARY | Mở publication thiếu DOI/abstract/year/authors | Hiện fallback an toàn như N/A; không crash |
| PUB-04 | SUCCESS | Bấm original publication/DOI link | Mở browser/app ngoài bằng DOI, fallback OpenAlex URL |
| PUB-05 | FAILURE | Device không có handler hoặc URL lỗi | App nên hiện Could not open...; cần ghi FAIL nếu Flutter exception xuất hiện |
| PUB-06 | SUCCESS | Copy DOI/citation nếu UI hỗ trợ | Clipboard đúng và có confirmation |
| PUB-07 | ANALYTICS | Mở publication | DebugView có view_publication với publication_title và publication_year |

### 6.4 Journals và Journal Detail

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| JOURNAL-01 | SUCCESS | Journals search Cybersecurity | Có loading rồi summary, contribution chart và ranking |
| JOURNAL-02 | BOUNDARY | So sánh list | Publication count giảm dần; các tie có thứ tự ổn định |
| JOURNAL-03 | SUCCESS | Kiểm tra mỗi journal | Có works/publications, citations và average citations |
| JOURNAL-04 | SUCCESS | Bấm một journal | Detail có name, total publications, total/average citations và related publications |
| JOURNAL-05 | SUCCESS | Bấm related publication | Mở đúng Publication Detail |
| JOURNAL-06 | SUCCESS | Load next 100 rồi thử Load all/up to 1,000 | Ranking cập nhật sau từng page; Home và Keywords không đổi; progress/cancel hoạt động |
| JOURNAL-07 | FAILURE | Tắt mạng rồi thực hiện initial/new search | Search data mới bị clear; hiện error message; retry bằng Search; app không crash |
| JOURNAL-08 | FAILURE | Đã có data, tắt mạng rồi Load next/bulk load | Prior loaded data còn; có load error và Retry đúng cursor |
| JOURNAL-09 | ANALYTICS | Bấm journal | DebugView có view_journal với journal_name |

### 6.5 Keywords và Keyword Detail

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| KEYWORD-01 | SUCCESS | Keywords search Healthcare | Có frequent/trending keyword, frequency data và trend chart |
| KEYWORD-02 | SUCCESS | Bấm một keyword | Detail có trend, related journals/publications và top authors |
| KEYWORD-03 | BOUNDARY | Kiểm tra Top Authors | Publication count giảm dần |
| KEYWORD-04 | SUCCESS | Bấm related publication | Mở đúng Publication Detail |
| KEYWORD-05 | SUCCESS | Load next 100 rồi thử Load all/up to 1,000 | Frequency, trend và rankings cập nhật sau từng page; Home/Journals không đổi; progress/cancel hoạt động |
| KEYWORD-06 | FAILURE | Tắt mạng rồi thực hiện initial/new search | Search data mới bị clear; hiện error message; retry bằng Search; app không crash |
| KEYWORD-07 | FAILURE | Đã có data, tắt mạng rồi Load next/bulk load | Prior loaded data còn; có load error và Retry đúng cursor |
| KEYWORD-08 | BOUNDARY | Topic ít keyword | Có empty/fallback state, không overflow |
| KEYWORD-09 | ANALYTICS | Bấm keyword | DebugView có view_keyword với keyword |

## 7. Test PDF và Firebase Storage

### 7.1 Rules cần đối chiếu

Local storage.rules hiện cho phép read/write khi user đã login và UID trong auth khớp segment userId:

    reports/{userId}/{allPaths=**}
    request.auth != null && request.auth.uid == userId

Local file đúng chưa đủ. Cần mở Firebase Console > Storage > Rules để xác nhận cùng rule đã Publish.

### 7.2 Luồng success

1. Login User A.
2. Home search Artificial Intelligence và đợi dữ liệu thành công.
3. Mở Profile > Report Export.
4. Kiểm tra Home topic và số publications sẽ được đưa vào report.
5. Bấm Generate & Upload PDF.
6. Quan sát Generating PDF document... rồi Uploading to Firebase Storage.
7. Đợi PDF uploaded to Firebase Storage.
8. Chụp URL đã che token, Open PDF và Copy URL.
9. Mở Firebase Console > Storage > Files để kiểm tra file.

Expected Storage path:

    reports/<User-A-UID>/journal_trend_<safe-topic>_<timestamp>.pdf

### 7.3 Test cases

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| STORAGE-01 | FAILURE | Tắt mạng trước initial Home load hoặc chuyển Profile khi Home còn loading, rồi bấm export | Hiện Search for a topic on Home before exporting a report.; không upload |
| STORAGE-02 | SUCCESS | Home có data rồi Generate & Upload PDF | Progress đúng thứ tự; thành công và có download URL |
| STORAGE-03 | EVIDENCE | Mở Storage Console | File nằm dưới reports/User-A-UID, MIME application/pdf, size > 0 |
| STORAGE-04 | SUCCESS | Bấm Open PDF | PDF mở ngoài app |
| STORAGE-05 | SUCCESS | Bấm Copy URL | Clipboard đúng; hiện PDF link copied. |
| STORAGE-06 | PDF | Kiểm tra các trang PDF | Có topic, generated time, OpenAlex source, KPIs, trend, top journals/authors, influential publications, footer/page number |
| STORAGE-07 | PDF/BOUNDARY | Export topic broad có title dài, tiếng Việt và Unicode khác | Không clipping/overflow/page lỗi; tiếng Việt được chuyển sang ASCII không dấu, Unicode chưa hỗ trợ có thể thành dấu ? |
| STORAGE-08 | FAILURE | Tắt mạng trước upload | Không crash; upload timeout sau tối đa 60 giây, task thật được cancel và có Retry |
| STORAGE-09 | INTERRUPTION | Bật mạng rồi bấm Retry | Upload thành công; export_pdf chỉ log sau success |
| STORAGE-10 | INTERRUPTION | Bấm Generate & Upload liên tục | Chỉ một generation/upload; nút disabled khi busy |
| STORAGE-11 | INTERRUPTION | Sign Out trong lúc generation | Trở về Login; không disposed-state exception |
| STORAGE-12 | INTERRUPTION | Sign Out trong lúc actual upload | Không Flutter crash; UploadTask bị cancel; không log export_pdf và không tiếp tục upload dưới session cũ |
| STORAGE-13 | INTERRUPTION | Force-close trong lúc upload | Mở app lại bình thường; resume upload không phải requirement hiện tại |
| STORAGE-14 | SECURITY | Rules Playground/SDK: User B đọc/ghi path của User A | Permission denied |
| STORAGE-15 | SECURITY | Rules Playground/SDK: unauthenticated đọc/ghi | Permission denied |
| STORAGE-16 | SECURITY | Rules Playground/SDK: User A đọc/ghi đúng path của A | Allowed |
| STORAGE-17 | BOUNDARY | Topic có spaces, slash hoặc Unicode | Filename vẫn safe và kết thúc .pdf; nội dung không corrupt |
| STORAGE-18 | ANALYTICS | Cho upload thất bại | Không có export_pdf trong DebugView |

### 7.4 Cách kiểm tra Storage Rules bằng Console

1. Copy UID của User A và User B từ Authentication > Users.
2. Mở Storage > Rules > Rules Playground.
3. Chọn read/get với path reports/<User-A-UID>/manual-test.pdf.
4. Mô phỏng authenticated request có auth.uid = User A UID: expected Allowed.
5. Giữ nguyên path của User A nhưng đổi auth.uid = User B UID: expected Denied.
6. Tắt authenticated user: expected Denied.
7. Lặp lại với write/create nếu Playground hỗ trợ operation này.
8. Chụp cả ba kết quả allow/deny và current published rules.

Quan trọng về security:

- URL từ getDownloadURL là link chia sẻ có token. Người có URL có thể mở file.
- Không dùng việc paste URL vào incognito để kết luận Storage Rules bị bypass.
- Muốn chứng minh rules, dùng Firebase Rules Playground hoặc SDK request có/không có auth.
- Không đăng download URL đầy đủ lên report public.

Upload đã có timeout 60 giây và nút `Cancel export`. Cả timeout, Cancel, Sign Out và ViewModel dispose đều gọi hủy UploadTask thật; các trạng thái này không log `export_pdf` và vẫn cho phép Retry.

## 8. Phase 6 - FCM và Notification Center

Đây là phần chưa được test tay trước đó. Phải chạy trên Android emulator/device có Google Play services; không dùng Chrome.

### 8.1 Cấp permission và lấy token

1. Login và mở Profile.
2. Trong Notification Center, bấm Enable notifications.
3. Chọn Allow trên Android.
4. Expected: hiện Notifications are enabled và Copy test token.
5. Bấm Copy test token.
6. Chỉ dán token vào Firebase Console; không lưu token đầy đủ trong screenshot hoặc Git.

Nếu chọn Deny:

- App phải hiện Notification permission is denied và không crash.
- Trên Android 13+, FlutterFire có thể dùng trạng thái denied cho cả trường hợp chưa từng được hỏi và đã từ chối. Không đánh FAIL chỉ dựa vào status ban đầu; hãy bấm Enable notifications rồi đối chiếu permission dialog và Android Settings.
- Android có thể không hiện dialog lần hai. Vào Settings > Apps > Journal Trend Analyzer > Notifications để bật lại.

### 8.2 Tạo test message trong Firebase Console

Trong Firebase Console:

1. Mở Messaging/Cloud Messaging.
2. Chọn Create campaign, New campaign hoặc Create notification tùy giao diện Console.
3. Chọn Notifications.
4. Nhập:

   - Title: AI research trend update
   - Body: Transformer publications increased strongly this year.

5. Trong Additional options/Advanced options thêm custom data:

   - type = research_trend
   - topic = Transformers

6. Chọn Send test message/Test on device.
7. Dán registration token của thiết bị.
8. Gửi message.
9. Sau khi gửi, xóa token khỏi clipboard nếu không còn dùng.

Notification Center hiện title, body, Topic và thời gian. Model có lưu type/source nhưng UI hiện không hiển thị literal research_trend, foreground, background hoặc opened.

### 8.3 Foreground

Để app đang mở ở Home rồi gửi test message.

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| FCM-01 | SUCCESS | Profile > Enable notifications > Allow | Permission enabled, token sẵn sàng, app không crash |
| FCM-02 | FAILURE | Deny permission | UI báo denied; app vẫn dùng được |
| FCM-03 | SUCCESS | App foreground, gửi message | Có SnackBar; không bắt buộc có Android system banner |
| FCM-04 | SUCCESS | Quan sát Profile destination | Unread badge tăng và item mới ở đầu list |
| FCM-05 | SUCCESS | Bấm View trên SnackBar | Chuyển sang Profile |
| FCM-06 | DATA | Kiểm tra item | Đúng title/body, Topic: Transformers và thời gian |
| FCM-07 | SUCCESS | Bấm item unread | Item thành read và badge giảm |
| FCM-08 | SUCCESS | Bấm Mark all as read | Tất cả read; badge về 0 |
| FCM-09 | SUCCESS | Bấm Clear all | List rỗng và hiện No research notifications yet. |

Foreground notification message không hiện system banner mặc định là hành vi bình thường của FCM. App dùng onMessage để hiện SnackBar và lưu vào Notification Center.

### 8.4 Background

1. Để app đã login.
2. Bấm Home của Android để app chạy background, không Force stop.
3. Gửi một test notification mới từ Console.
4. Expected: notification xuất hiện trong system tray.
5. Bấm chính notification đó.
6. Expected: app mở Profile; item xuất hiện và được đánh dấu read; không duplicate.

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| FCM-10 | SUCCESS | App background, gửi Console notification | Android system tray hiện notification |
| FCM-11 | SUCCESS | Bấm notification trong tray | App mở Profile, item được lưu và đã read |
| FCM-12 | BOUNDARY | Thay vì bấm notification, mở app bằng icon | Không bắt buộc item xuất hiện trong Notification Center |
| FCM-13 | INTERRUPTION | Tắt mạng, gửi message, bật mạng | Message có thể đến trễ; app không crash hoặc loading vô hạn |

FCM-12 là hành vi nền tảng, không phải lỗi: Console gửi notification hoặc notification+data. Khi app ở background, Android hiển thị notification trong tray; data được chuyển cho app khi user bấm notification. Mở app bằng icon không tương đương bấm notification.

### 8.5 Terminated và Force stop

Terminated test:

1. Swipe app khỏi Recent Apps; không bấm Force stop trong App info.
2. Gửi test notification.
3. Bấm notification trong system tray.
4. Expected: app khởi động, session login còn, tự mở Profile và item đã read.

Force-stop boundary:

1. Settings > Apps > Journal Trend Analyzer > Force stop.
2. Gửi message.
3. Android có thể không giao notification.
4. Mở app thủ công để bỏ trạng thái force-stop.
5. Copy token hiện tại và gửi message mới.
6. Chỉ đánh FAIL nếu sau khi mở lại app vẫn không nhận.

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| FCM-14 | SUCCESS | Terminate bằng swipe, gửi rồi tap notification | App cold-start, mở Profile và lưu item |
| FCM-15 | BOUNDARY | Android Force stop rồi gửi | Có thể không nhận; đây không phải app failure |
| FCM-16 | RECOVERY | Mở app lại rồi gửi message mới | Nhận bình thường bằng token hiện tại |

### 8.6 Persistence, duplicate và giới hạn

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| FCM-17 | PERSISTENCE | Nhận/tap message, đóng app rồi mở lại | Message và read state còn |
| FCM-18 | DEDUPE | Tap cùng notification rồi resume app nhiều lần | Không sinh duplicate của cùng FCM messageId |
| FCM-19 | BOUNDARY | Gửi hai message cùng title/body | Có thể tạo hai item vì messageId khác nhau; đây không phải duplicate bug |
| FCM-20 | BOUNDARY | Nhận hơn 50 message trong cùng một phiên | UI, badge và persisted list đều giữ tối đa 50 item ngay lập tức |
| FCM-21 | PRIVACY | User A nhận message, logout, User B login | User B không thấy notification của User A; đăng nhập lại A vẫn thấy history của A |
| FCM-22 | FAILURE/RECOVERY | App đã được cấp permission nhưng startup offline làm getToken lỗi | UI hiện lỗi và Retry notification setup; listeners vẫn hoạt động; bật mạng và Retry phục hồi token, không tạo listener trùng |

FCM-20, FCM-21 và FCM-22 là targeted regression sau hardening. Store v2 được scope theo Firebase UID, trim ngay ở 50, gắn listeners trước bước lấy token và có Retry không tạo subscription trùng. Dữ liệu v1 cũ không được migrate vì không thể xác định chủ sở hữu an toàn.

### 8.7 Optional - test background handler thật bằng data-only message

Firebase Console composer không phải công cụ phù hợp để chứng minh data-only background handler. Muốn nhận và lưu message khi app background mà không cần bấm system notification, cần gửi data-only message bằng Firebase Admin SDK hoặc HTTP v1 từ Cloud Functions/server tin cậy.

Yêu cầu an toàn:

- Không nhúng service account, OAuth access token hoặc server key vào Flutter app.
- Không commit credential vào repository.
- Với Android background/Doze, dùng Android message priority high cho test data-only để giảm nguy cơ message bị trì hoãn.
- Có thể bỏ test optional này nếu Lab chỉ yêu cầu Notification Center nhận FCM message qua Console foreground/background tap.

### 8.8 Evidence bắt buộc cho Phase 6

- Permission enabled và nút Copy test token; che token.
- Màn hình gửi test message trong Firebase Console.
- Foreground SnackBar và unread badge.
- Notification Center item có Topic: Transformers.
- Background system tray.
- Profile sau khi bấm background notification.
- Cold-start/terminated flow.
- Message vẫn còn sau app restart.
- Mark all as read và Clear all.

Phase 6 chỉ được đánh DONE khi foreground, background-tap, terminated-tap và persistence đều PASS trên thiết bị thật/emulator.

## 9. Phase 7 - Remote Config

### 9.1 Publish values

Để dễ đếm trên UI, tạo một version test:

- max_journals_displayed = 4
- max_keywords_displayed = 6

Để chắc chắn thấy message new values fetched, hãy mở app và ghi lại values cũ trước, giữ app đang chạy, sau đó mới chọn data type Number và bấm Publish changes. Chụp Console có version/time đã publish rồi quay lại app bấm Fetch & Activate.

Nếu app chỉ được mở sau khi 4/6 đã publish, bootstrap có thể tự fetch và activate trước khi bạn vào Profile. Khi đó Profile đã hiện 4/6 và lần bấm Fetch & Activate đầu tiên có thể báo values unchanged; đây vẫn là PASS.

### 9.2 Test cases

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| RC-01 | EVIDENCE | Console có 2 keys kiểu Number và đã Publish | Version mới xuất hiện |
| RC-02 | SUCCESS | Publish khi app đang chạy, rồi Profile > Firebase Demo > Fetch & Activate | Hiện 4 và 6; báo new values fetched/activated |
| RC-03 | BOUNDARY | Bấm Fetch & Activate lần hai khi Console không đổi | Báo fetch success nhưng values unchanged |
| RC-04 | BEHAVIOR | Sau fetch, Home search lại broad topic | Top Journals ở Home hiển thị tối đa 4 |
| RC-05 | BEHAVIOR | Keywords search lại broad topic | Keywords list hiển thị tối đa 6 |
| RC-06 | SCOPE | Mở Journals tab | Không dùng tab này để đánh giá max_journals_displayed; key hiện chỉ giới hạn Home Top Journals |
| RC-07 | FAILURE | Tắt mạng rồi Fetch & Activate | Có thể fail ngay hoặc trong fetchTimeout tối đa khoảng 10 giây; có error và app không crash |
| RC-08 | CACHE | Sau RC-07 kiểm tra values | Giữ activated/cached values cũ; không bắt buộc quay về default 10 |
| RC-09 | BOUNDARY | Publish 0 cho một key rồi fetch | App dùng fallback 10 vì chỉ chấp nhận value > 0 |
| RC-10 | RECOVERY | Publish lại 4/6, bật mạng và fetch | Values hoạt động lại |
| RC-11 | DEFAULT/OFFLINE | Clear app data, launch offline để bootstrap dùng defaults; bật mạng nhưng không restart rồi login | Profile hiện default 10/10 cho tới lần fetch thành công |
| RC-12 | INTERRUPTION | Bấm Fetch & Activate liên tục | Nút disabled với Fetching configuration...; chỉ một request chạy |

Remote Config fetch chỉ làm card Profile cập nhật ngay. Để chứng minh ảnh hưởng feature, quay lại Home/Keywords và thực hiện search mới. Không kết luận thất bại chỉ vì list thực tế ít hơn limit; topic phải có đủ journals/keywords.

Evidence:

- Console có hai keys và Published version.
- Profile hiển thị đúng 4/6 và success message.
- Home Top Journals sau search có tối đa 4.
- Keywords list sau search có tối đa 6.
- Offline fetch hiện error nhưng app vẫn hoạt động.

## 10. Phase 7 - Crashlytics

### 10.1 Handled exception

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| CRASH-01 | SUCCESS | Profile > Firebase Demo > Handled exception | App tiếp tục chạy; hiện Handled exception sent. Check the Crashlytics Console. |
| CRASH-02 | EVIDENCE | Đóng/mở app rồi vào Crashlytics Console | Có non-fatal StateError/Bad state: Phase 7 handled exception demo |
| CRASH-03 | EVIDENCE | Mở report details | Reason nói user trigger từ Profile; custom key firebase_demo_type = handled_exception |
| CRASH-04 | INTERRUPTION | Bấm Handled exception liên tục | Button disabled khi đang gửi; chỉ một request/report demo được tạo |

Non-fatal có thể cần app restart để upload. Lọc đúng time, app version và device trong Crashlytics Console.

### 10.2 Fatal test crash

Nên chạy sau cùng và tốt nhất mở app từ launcher thay vì giữ phiên debugger đang điều khiển app.

1. Profile > Test crash.
2. Lần đầu bấm Cancel.
3. Expected: dialog đóng, app tiếp tục.
4. Mở lại Test crash và bấm Crash app.
5. Expected: process app đóng ngay. Đây là PASS của nút test crash, không phải app bug.
6. Mở app lại để Crashlytics upload report.
7. Chờ vài phút rồi refresh Console. Nếu chưa thấy, không đánh FAIL chỉ dựa vào thời gian; kiểm tra mạng, app đã relaunch, đúng Firebase project/build và debug log.

| ID | Type | Thao tác | Expected result |
|---|---|---|---|
| CRASH-05 | SAFETY | Test crash > Cancel | App không đóng, không fatal report từ lần Cancel |
| CRASH-06 | SUCCESS | Test crash > Crash app | App đóng ngay |
| CRASH-07 | RECOVERY | Mở app lại | App login/session hoạt động; report được upload |
| CRASH-08 | EVIDENCE | Crashlytics Console | Có fatal FirebaseCrashlyticsTestCrash hoặc test crash cùng thời gian |
| CRASH-09 | EVIDENCE | Mở fatal report | Custom key firebase_demo_type = fatal_test_crash |

Nếu chưa thấy report, bật Crashlytics debug log trước khi tái hiện lại crash:

    adb shell setprop log.tag.FirebaseCrashlytics DEBUG
    adb logcat -s FirebaseCrashlytics

Giữ logcat chạy, tái hiện test crash, mở app lại rồi tìm report upload complete hoặc HTTP 204. Sau khi kiểm tra:

    adb shell setprop log.tag.FirebaseCrashlytics INFO

Không chạy fatal crash khi đang nhập dữ liệu chưa lưu hoặc trước khi chụp evidence của các phase khác.

## 11. Phase 7 - Analytics

### 11.1 Bảy events bắt buộc

| Thứ tự | User action | Event | Parameter cần mở kiểm tra |
|---|---|---|---|
| 1 | Google login thành công | login | Không yêu cầu custom parameter |
| 2 | Home search Transformers | search_topic | keyword = Transformers |
| 3 | Mở một publication | view_publication | publication_title, publication_year |
| 4 | Journals > mở một journal | view_journal | journal_name |
| 5 | Keywords > mở một keyword | view_keyword | keyword |
| 6 | PDF upload thành công | export_pdf | topic |
| 7 | Sign Out | logout | Không yêu cầu custom parameter |

Các event app_bootstrap, screen_view và user_engagement là event bổ sung. Chúng không thay thế bảy event trong bảng.

### 11.2 Cách kiểm tra

1. Bật DebugView bằng adb trước khi login.
2. Firebase Console > Analytics > DebugView.
3. Chọn đúng debug device.
4. Chạy bảy action theo bảng.
5. Bấm từng event trong timeline và chụp parameter.
6. Với PDF failure, xác nhận không có export_pdf.
7. Với login cancel/failure, xác nhận không có login.

| ID | Type | Expected result |
|---|---|---|
| ANALYTICS-01 | SUCCESS | Có login sau authentication thành công |
| ANALYTICS-02 | SUCCESS | Có search_topic và keyword đúng text search |
| ANALYTICS-03 | SUCCESS | Có view_publication và đúng title/year |
| ANALYTICS-04 | SUCCESS | Có view_journal và đúng journal_name |
| ANALYTICS-05 | SUCCESS | Có view_keyword và đúng keyword |
| ANALYTICS-06 | SUCCESS | Có export_pdf chỉ sau Storage success |
| ANALYTICS-07 | SUCCESS | Có logout sau Sign Out |
| ANALYTICS-08 | NEGATIVE | Không có login sau cancel/failure |
| ANALYTICS-09 | NEGATIVE | Không có export_pdf sau generation/upload failure |
| ANALYTICS-10 | BOUNDARY | Với keyword, publication_title, journal_name hoặc topic trên 100 Unicode characters | Parameter được trim và truncate an toàn còn tối đa 100 characters; event vẫn xuất hiện, numeric parameter giữ nguyên |

AnalyticsTrackingService hiện normalize mọi string parameter trước khi gọi Firebase: trim khoảng trắng và truncate theo Unicode character ở giới hạn 100. Unit test bao phủ chuỗi dài, emoji và khoảng trắng; vẫn cần DebugView evidence trên Android để chứng minh runtime.

Tắt DebugView sau test:

    adb shell setprop debug.firebase.analytics.app .none.

Evidence tối thiểu:

- Timeline có đủ 7 events.
- Event details cho search_topic, view_publication, view_journal, view_keyword và export_pdf.
- Ảnh failure export không tạo export_pdf.
- Có thể dùng nhiều screenshot nếu một timeline không chứa đủ.

## 12. Kết quả AI-assisted code review

Các finding dưới đây đáp ứng phần nội dung “ít nhất 3 issues/opportunities”, nhưng để đúng deliverable PDF vẫn cần đưa screenshot quá trình AI review, giải thích quyết định và trạng thái fix/accept vào project report.

| ID | Mức độ | Finding | Ảnh hưởng | Trạng thái |
|---|---|---|---|---|
| REVIEW-01 | High | Firebase initialization fail-open vào MainShell | Đã thay bằng blocking error + Retry; có widget regression test | Fixed |
| REVIEW-02 | Medium | Business aggregation/sort nằm trong Views | Đã chuyển sang Dashboard/Journal Detail/Keyword Detail ViewModels | Fixed |
| REVIEW-03 | Medium | Icon search và notification ở Home có callback rỗng | Search focus đúng field; notification mở Profile | Fixed |
| REVIEW-04 | Medium | Top author không có Key Metric riêng | Đã thêm Top Author và Top Paper Citations metrics | Fixed |
| REVIEW-05 | Medium | Storage upload không có app-level timeout/cancel | Có timeout 60 giây, Cancel thật, cancel khi sign out/dispose | Fixed |
| REVIEW-06 | Medium | Notification store không scope theo Firebase UID | Store v2 dùng key riêng theo UID; không migrate v1 không rõ owner | Fixed |
| REVIEW-07 | Medium | In-memory notifications không trim ngay ở 50 | Memory/UI/persistence đều trim ngay ở 50 | Fixed |
| REVIEW-08 | Medium | FCM token lỗi không có Retry và listeners chưa gắn | Listeners gắn trước token; có Retry và chống subscription trùng | Fixed |
| REVIEW-09 | Medium | Analytics string parameters chưa truncate | String được trim/truncate an toàn còn tối đa 100 Unicode characters | Fixed |
| REVIEW-10 | Low/Medium | launchUrl chưa catch mọi exception | Bắt false và exception, hiển thị friendly SnackBar | Fixed |
| REVIEW-11 | Release blocker cho IPA | Thiếu ios/Runner/GoogleService-Info.plist, APNs/capabilities/entitlements | Android Lab vẫn chạy; Firebase/FCM iOS chưa sẵn sàng | Open |
| REVIEW-12 | Deliverable | Repo naming, project report, demo video và Console evidence chưa hoàn tất | Chưa sẵn sàng submission | Open |

Targeted regression trước khi nộp: bulk pagination/cancel/retry trên ba tab, Storage cancel/timeout, FCM per-user/limit/retry và Firebase initialization error screen. REVIEW-11 và REVIEW-12 vẫn cần xử lý ngoài vòng code Android hiện tại.

## 13. iOS/IPA readiness

PDF Lab 03 yêu cầu Android/emulator nên iOS không làm fail phạm vi hiện tại. Tuy nhiên kế hoạch xuất IPA sau này chưa sẵn sàng vì hiện thiếu:

- ios/Runner/GoogleService-Info.plist.
- Push Notifications capability.
- Background Modes > Remote notifications.
- aps-environment entitlement.
- APNs authentication key được upload vào Firebase.

Khi chuyển sang Mac, phải tạo/register iOS app trong cùng Firebase project, dùng đúng Bundle ID, tải plist mới và hoàn tất APNs trước khi test FCM iOS.

## 14. Final acceptance checklist

### App và OpenAlex

- [ ] Login/Sign Out và session persistence PASS.
- [ ] 4 tabs đúng và 3 search states độc lập.
- [ ] Home metrics/trend/rankings/detail PASS.
- [ ] `Load next 100` và `Load all N`/`Load up to 1,000` PASS trên Home, Journals và Keywords.
- [ ] Bulk progress, Cancel, Retry, cap 1,000 và state độc lập giữa ba tab PASS.
- [ ] Journals/Journal Detail PASS.
- [ ] Keywords/Keyword Detail PASS.
- [ ] Loading, empty, failure, Retry và interruption PASS.
- [ ] Màn nhỏ, landscape và font scale không overflow.

### Firebase

- [ ] Authentication Console có test user/provider.
- [ ] Storage file đúng reports/UID path.
- [ ] Storage Cancel/timeout thực sự dừng upload và không tạo export_pdf.
- [ ] Rules Playground: User A allow, User B deny, no-auth deny.
- [ ] PDF mở được và nội dung/layout đã kiểm tra.
- [ ] Phase 6 foreground PASS.
- [ ] Phase 6 background notification tap PASS.
- [ ] Phase 6 terminated notification tap PASS.
- [ ] Phase 6 persistence/read/clear PASS.
- [ ] Phase 6 per-user isolation, limit 50 và Retry notification setup PASS.
- [ ] Remote Config có 2 published keys và ảnh hưởng UI đúng.
- [ ] Crashlytics có non-fatal handled exception.
- [ ] Crashlytics có fatal test crash sau relaunch.
- [ ] Analytics DebugView có đủ 7 events và parameters.

### Deliverables

- [ ] Lưu screenshot evidence có ID rõ ràng.
- [ ] Đưa Auth, Storage, FCM, Remote Config, Crashlytics và Analytics Console screenshots vào project report, không chỉ để riêng trong thư mục evidence.
- [ ] AI review có tối thiểu 3 findings, screenshot và giải thích.
- [ ] Repo đổi theo convention PRM393_Lab03_StudentID trước submission.
- [ ] README không còn nội dung Flutter template.
- [ ] Complete source, Firebase configuration, tests và assets đã được commit đúng phạm vi.
- [ ] Project report 5-10 trang có overview, architecture/MVVM, Firebase design, screenshots, Analytics, Crashlytics, Remote Config, AI review, challenges và lessons learned.
- [ ] Demo video 5-10 phút có Auth, topic search/publication detail, Journals, Keywords/author analysis, PDF/Storage, FCM, Remote Config, Crashlytics và AI review.
- [ ] Patrol/E2E được implement và chạy ở phase sau.

Không đánh dấu toàn bộ Lab DONE chỉ dựa trên analyze/test/build. Auth, Storage, FCM, Remote Config, Crashlytics và Analytics bắt buộc phải có device/Console evidence.

## 15. Tài liệu Firebase chính thức

- FCM Flutter receive messages: https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
- FCM Flutter setup/test message: https://firebase.google.com/docs/cloud-messaging/flutter/get-started
- Android notification/data message behavior: https://firebase.google.com/docs/cloud-messaging/android/receive-messages
- Firebase Console message composer: https://firebase.google.com/docs/cloud-messaging/send/firebase-console
- Remote Config Flutter: https://firebase.google.com/docs/remote-config/flutter/get-started
- Crashlytics Flutter: https://firebase.google.com/docs/crashlytics/flutter/get-started
- Crashlytics customize reports: https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports
- Analytics DebugView: https://firebase.google.com/docs/analytics/debugview
- Google Auth Flutter: https://firebase.google.com/docs/auth/flutter/federated-auth
- Storage security conditions: https://firebase.google.com/docs/storage/security/rules-conditions
- Storage upload files: https://firebase.google.com/docs/storage/flutter/upload-files
