# Phase 7 - Firebase demo and evidence test cases

Phase 7 đã hoàn tất code khi analyzer, tests và build pass. Phase chỉ được đổi sang `DONE` sau khi các giá trị/report/event thật xuất hiện trong Firebase Console.

## 1. Remote Config

Trong Firebase Console > Remote Config, tạo hoặc sửa và **Publish changes**:

- `max_journals_displayed`: ví dụ `12`
- `max_keywords_displayed`: ví dụ `8`

| ID | Type | Thao tác | Kết quả thành công | Fail / gián đoạn |
| --- | --- | --- | --- | --- |
| RC-01 | SUCCESS - Defaults | Tắt mạng, mở app và vào Profile. | Hai giá trị vẫn là số dương; khi chưa từng fetch sẽ dùng default `10`. | App crash hoặc hiện 0/giá trị âm. |
| RC-02 | SUCCESS - Fetch changed | Bật mạng, publish `12` và `8`, bấm **Fetch & Activate**. | UI báo đã activate giá trị mới và hiện `12`, `8`. Journals/Keywords dùng limit tương ứng ở lần render/search tiếp theo. | UI vẫn 10 dù Console đã Publish đúng project/app và mạng ổn. |
| RC-03 | SUCCESS - Fetch unchanged | Bấm **Fetch & Activate** lần nữa khi Console không đổi. | UI báo fetch thành công nhưng giá trị không thay đổi. | Báo error hoặc loading vô hạn. |
| RC-04 | FAIL SAFE - Offline refresh | Tắt mạng rồi bấm **Fetch & Activate**. | UI báo không thể refresh; app vẫn dùng giá trị đã activate/default và không crash. | Giá trị mất, app treo hoặc crash. |
| RC-05 | INTERRUPTED - Duplicate tap | Bấm refresh liên tục khi đang loading. | Nút bị disable và chỉ có một request đang chạy. | Nhiều loading/request chồng nhau hoặc state nhảy sai. |

Evidence cần chụp:

1. Firebase Console có hai key và giá trị đã Publish.
2. Profile trước fetch hoặc với default.
3. Profile sau fetch hiển thị đúng giá trị mới và success message.

## 2. Crashlytics

### Handled exception

1. Mở Profile > Firebase Demo.
2. Bấm **Handled exception**.
3. App phải tiếp tục chạy và hiện thông báo đã gửi.
4. Đóng/mở lại app nếu report chưa được upload ngay.
5. Firebase Console > Crashlytics, chờ vài phút rồi refresh.

Report mong đợi có:

- Non-fatal `StateError` với message `Phase 7 handled exception demo`.
- Reason liên quan user trigger từ Profile.
- Custom key `firebase_demo_type = handled_exception` nếu metadata ghi thành công.

### Fatal test crash

1. Bấm **Test crash**.
2. Ở dialog, test nút **Cancel** trước: dialog đóng, app không crash.
3. Mở lại dialog, đọc cảnh báo rồi bấm **Crash app**.
4. Kết quả đúng là process app đóng ngay. Đây là hành vi thành công, không phải bug.
5. Mở app lại để Crashlytics gửi report, sau đó kiểm tra Console.

| ID | Type | Kết quả thành công | Fail / gián đoạn |
| --- | --- | --- | --- |
| CL-01 | SUCCESS - Non-fatal | Handled exception không đóng app và xuất hiện trong Console. | App crash hoặc Console không có sau khi restart/chờ vài phút. |
| CL-02 | SUCCESS - Cancel | **Cancel** đóng dialog và không gọi crash. | App đóng khi bấm **Cancel**. |
| CL-03 | EXPECTED FATAL | Xác nhận làm app đóng; sau khi mở lại có fatal issue trong Console. | App không đóng hoặc không có report sau restart/chờ. |
| CL-04 | FAIL SAFE - Duplicate handled tap | Nút handled bị disable lúc gửi, chỉ tạo một request. | Tạo nhiều report vì tap liên tục hoặc loading vô hạn. |

Evidence cần chụp:

1. Profile hiện handled success.
2. Dialog cảnh báo test crash.
3. Crashlytics issue list có non-fatal và fatal.
4. Chi tiết issue có stack trace và custom key nếu có.

## 3. Analytics - đủ 7 events

Package Android hiện tại: `com.example.journal_trend_analysis`.

Bật DebugView trên emulator/device:

```powershell
adb shell setprop debug.firebase.analytics.app com.example.journal_trend_analysis
```

Sau đó mở Firebase Console > Analytics > DebugView và thực hiện lần lượt:

| Event | Thao tác trong app | Parameter phải kiểm tra |
| --- | --- | --- |
| `login` | Đăng nhập Google thành công. | Không bắt buộc; provider là optional. |
| `search_topic` | Search một topic ở Home/Journals/Keywords. | `keyword` đúng topic đã search. |
| `view_publication` | Mở Publication Detail. | `publication_title`, `publication_year`. |
| `view_journal` | Mở Journal Detail. | `journal_name`. |
| `view_keyword` | Mở Keyword Detail. | `keyword`. |
| `export_pdf` | Generate và upload PDF thành công. | `topic`; event không được xuất hiện nếu upload fail. |
| `logout` | Sign Out trong Profile. | Không bắt buộc parameter. |

Tắt debug mode sau khi thu evidence:

```powershell
adb shell setprop debug.firebase.analytics.app .none.
```

Các event `screen_view`, `user_engagement`, `app_bootstrap` có thể xuất hiện thêm; chúng không thay thế bảy event bắt buộc.

## 4. Auth và Storage evidence bổ sung

- Authentication: chụp Firebase Console có Google user và app Profile có cùng email/display name.
- Storage: chụp file tại `reports/{uid}/{fileName}.pdf`, app hiện download URL và PDF mở được.
- Không chụp hoặc commit service-account key, FCM server credential hay token nhạy cảm vào report public.

## 5. Điều kiện kết luận Phase 7 DONE

Chỉ đánh dấu Phase 7 `DONE` khi:

- RC-01 đến RC-04 đạt hành vi mong đợi.
- CL-01, CL-02 và CL-03 có evidence.
- DebugView có đủ đúng bảy event và parameters phù hợp.
- Có ảnh Auth, Storage, Remote Config, Analytics và Crashlytics dùng cho report/demo video.
