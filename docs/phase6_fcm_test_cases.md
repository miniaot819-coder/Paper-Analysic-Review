# Phase 6 - FCM manual test cases

Tài liệu này dùng để verify phần Firebase thật trên Android sau khi automated tests đã pass. Chrome/Web build chỉ dùng regression UI; test FCM chính của Phase 6 phải chạy trên Android emulator/device có Google Play services.

## Chuẩn bị

1. Chạy app Android, đăng nhập Google và mở tab **Profile**.
2. Trong **Notification Center**, bấm **Enable notifications** và chọn **Allow**.
3. Khi trạng thái đổi thành **Notifications are enabled**, bấm **Copy test token**.
4. Mở Firebase Console > **Messaging** > tạo notification campaign/test message.
5. Dùng mẫu nội dung:
   - Title: `AI research trend update`
   - Body: `Transformer publications increased strongly this year.`
   - Custom data `type`: `research_trend`
   - Custom data `topic`: `Transformers`
6. Chọn **Send test message**, dán đúng FCM registration token vừa copy.

Không đưa FCM server key hoặc service-account JSON vào app/repository.

## Test matrix

| ID | Type | Thao tác | Kết quả thành công | Dấu hiệu fail / gián đoạn |
| --- | --- | --- | --- | --- |
| P6-01 | SUCCESS - Permission | Cài mới app, login, vào Profile, bấm **Enable notifications**, chọn Allow. | Trạng thái thành **Notifications are enabled**; xuất hiện **Copy test token**. | Không có dialog trên Android 13+ hoặc status vẫn denied. Kiểm tra app notification permission trong Android Settings. |
| P6-02 | FAIL - Permission denied | Reset permission hoặc cài lại app; bấm **Enable notifications**, chọn Don't allow. | UI báo quyền đang bị từ chối, app không crash, không hiện token. | App crash, loading quay vô hạn, hoặc vẫn báo authorized. |
| P6-03 | SUCCESS - Token | Sau khi Allow, bấm **Copy test token** rồi dán vào một ô text tạm. | Clipboard có chuỗi token dài, không rỗng. | Không có nút copy hoặc báo lỗi FCM initialization. Kiểm tra internet/Google Play services. |
| P6-04 | SUCCESS - Foreground | Để app đang mở ở Home, gửi test message. | Không cần system-tray banner; app hiện SnackBar, Profile có badge `1`, vào Profile thấy title/body/topic và item chưa đọc. | Không có SnackBar lẫn badge/item sau khoảng 10-30 giây. Kiểm tra token và Firebase project. |
| P6-05 | SUCCESS - Foreground action | Gửi foreground message rồi bấm **View** trên SnackBar. | App chuyển sang tab Profile và Notification Center hiện message. | Bấm không chuyển tab hoặc app crash. |
| P6-06 | SUCCESS - Background/opened | Đưa app xuống background bằng nút Home, gửi test message. | Android system tray hiện notification. Tap notification mở app vào Profile, item hiện và được đánh dấu đã đọc. | Có notification nhưng tap không mở app/Profile, item trùng, hoặc crash. |
| P6-07 | SUCCESS - Terminated/initial | Vuốt app khỏi Recent Apps, không dùng Force stop; gửi test rồi tap notification. | App khởi động, login session còn, tự mở Profile và hiện message đã đọc. | App mở nhưng không có message hoặc crash trong startup. |
| P6-08 | INTERRUPTED - Force stop | Force stop app trong Android Settings rồi gửi message. | Có thể không nhận notification; sau khi mở app thủ công FCM hoạt động lại. Đây là giới hạn Android, không tính fail code. | Sau khi mở app lại và gửi token mới mà vẫn không nhận thì mới tính fail. |
| P6-09 | SUCCESS - Open by app icon | App background, nhận notification nhưng không tap; mở app bằng launcher icon rồi vào Profile. | Notification được nạp từ local storage và hiển thị chưa đọc. | System tray có tin nhưng Notification Center không có sau app resume. |
| P6-10 | SUCCESS - Deduplicate | Tap cùng một notification hoặc resume app nhiều lần. | Cùng `messageId` chỉ có một item; opened message chuyển thành đã đọc. | Xuất hiện nhiều item giống hệt nhau. |
| P6-11 | SUCCESS - Persistence | Nhận 1-2 message, đóng và mở lại app. | Các item vẫn còn, sắp xếp mới nhất trước. | Danh sách mất sau restart. |
| P6-12 | SUCCESS - Read controls | Tap item chưa đọc, sau đó test **Mark all as read** và icon **Clear all**. | Badge giảm đúng; mark all as read đưa unread về 0; clear all hiện empty state. | Badge không đồng bộ hoặc item quay lại ngay sau resume. |
| P6-13 | FAIL - Missing payload fields | Gửi data message không có title/body bằng công cụ server hợp lệ nếu có. | App dùng fallback `Research update` và không crash. | Null/blank UI hoặc exception. Không tạo server credential chỉ để làm test này nếu lab không yêu cầu. |
| P6-14 | INTERRUPTED - Offline | Tắt mạng, gửi message, chờ rồi bật mạng lại. | Message có thể đến trễ sau khi kết nối lại; app không crash hay loading vô hạn. | App crash hoặc FCM UI bị kẹt vĩnh viễn. |
| P6-15 | INTERRUPTED - Logout during init | Mở app rồi logout nhanh khi Profile/FCM đang load. | Quay lại Login bình thường, không có `notifyListeners after dispose` hay crash. | Console báo lifecycle exception hoặc app treo. |

## Các source/type sẽ xuất hiện trong app

- `foreground`: app đang mở; item chưa đọc, có SnackBar và badge.
- `background`: background handler đã lưu local; item chưa đọc nếu user chưa tap notification.
- `opened`: user tap notification từ background/terminated; item được đánh dấu đã đọc và app mở Profile.
- Custom payload `type=research_trend`: loại demo phù hợp requirement.
- Custom payload `topic=Transformers`: Profile hiện thêm dòng `Topic: Transformers`.

## Điều kiện kết luận Phase 6 DONE

Phase 6 chỉ đổi từ `IMPLEMENTED, PENDING MANUAL FIREBASE VERIFICATION` sang `DONE` khi P6-01, P6-03 đến P6-07 và P6-09 đến P6-12 đều pass trên Android thật/emulator. P6-02 phải fail an toàn; P6-08, P6-14 và P6-15 là test gián đoạn nên mục tiêu là app không crash.
