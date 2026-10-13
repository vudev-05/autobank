# BÁO CÁO KIỂM TRA QUYỀN VÀ DỊCH VỤ NỀN ANDROID
**Dự án:** AutoBank PRO — Đọc thông báo nhận tiền  
**Ứng dụng:** Android Native (Kotlin) + Flutter  
**Phiên bản tham chiếu:** 1.2.0 Pro  
**Ngày kiểm tra:** 12/10/2026

---

## 1. BẢNG KIỂM TRA TỪNG QUYỀN TRONG ANDROID MANIFEST

| Tên quyền | Mức độ bảo vệ | Mục đích sử dụng | Trạng thái kiểm tra |
| :--- | :--- | :--- | :--- |
| `android.permission.BIND_NOTIFICATION_LISTENER_SERVICE` | Quyền đặc biệt hệ thống | Lắng nghe sự kiện biến động số dư từ hơn 65+ ứng dụng ngân hàng và ví điện tử | **HỢP LỆ & BẮT BUỘC** |
| `android.permission.INTERNET` | Thông thường | Đồng bộ trạng thái đơn hàng, xác thực tài khoản Google và gửi nhận webhook | **HỢP LỆ & BẮT BUỘC** |
| `android.permission.WAKE_LOCK` | Thông thường | Đánh thức CPU trong 1-2 giây để đọc to thông báo khi máy đang tắt màn hình | **HỢP LỆ & CẦN THIẾT** |
| `android.permission.POST_NOTIFICATIONS` | Runtime (Android 13+) | Hiển thị thông báo nhận tiền và trạng thái dịch vụ nền | **HỢP LỆ & BẮT BUỘC** |
| `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Hệ thống | Đề xuất người dùng tắt tối ưu pin để hệ điều hành không đóng app ngầm | **HỢP LỆ & ĐÃ TỐI ƯU** |
| `android.permission.FOREGROUND_SERVICE` | Thông thường | Duy trì dịch vụ chạy nền khi cần duy trì kết nối | **HỢP LỆ** |
| `android.permission.VIBRATE` | Thông thường | Rung máy khi phát hiện thông báo nhận tiền | **HỢP LỆ** |
| `android.permission.FLASHLIGHT` | Thông thường | Nháy đèn flash trợ sáng khi nhận tiền thành công | **HỢP LỆ** |

> **Cam kết:** Ứng dụng TUÂN THỦ TUYỆT ĐỐI nguyên tắc không xin các quyền nguy hiểm không liên quan (như danh bạ, vị trí GPS chính xác, SMS nhạy cảm). Ứng dụng chỉ lắng nghe thông báo và tuyệt đối không bao giờ yêu cầu mật khẩu hoặc mã OTP ngân hàng của khách hàng.

---

## 2. KIỂM TRA DỊCH VỤ NỀN (KOTLIN NOTIFICATION LISTENER)

File kiểm tra: `apps/mobile/android/app/src/main/kotlin/vn/autobank/autobank_mobile/NotificationListener.kt`

- **Cơ chế lọc thông minh:** Hệ thống sử dụng danh sách `knownPackages` bao gồm hơn 65+ mã gói ngân hàng (Vietcombank, MB, Techcombank, BIDV, ACB, MoMo, ZaloPay, Viettel Money...) kết hợp kiểm tra từ khóa tài chính (`VND`, `đ`, `số dư`, `biến động`, `nhận tiền`).
- **Giao tiếp liên tiến trình:** Sử dụng `LocalBroadcastManager` để phát intent nội bộ `vn.autobank.NOTIFICATION` về `MainActivity.kt`.
- **Tránh trùng lặp nội dung:** `MainActivity.kt` chuyển dữ liệu qua `EventChannel` đến Flutter Engine; tại tầng Flutter, hệ thống tính toán fingerprint giao dịch (kết hợp ngân hàng + số tiền + thời gian) để ngăn chặn việc phát âm lặp lại cùng một thông báo.

---

## 3. MÀN HÌNH "SETTINGS > KIỂM TRA HOẠT ĐỘNG"

Đã xây dựng tại: `apps/mobile/lib/features/settings/presentation/pages/activity_check_page.dart`

Bao gồm 4 hạng mục kiểm tra thời gian thực:
1. **Quyền đọc thông báo ngân hàng:** Kiểm tra `isNotificationListenerEnabled()`, cung cấp nút mở thẳng màn hình Cài đặt truy cập thông báo của Android (`ACTION_NOTIFICATION_LISTENER_SETTINGS`).
2. **Chạy nền 24/7 (Bỏ tối ưu pin):** Kiểm tra `isBatteryOptimizationIgnored()`, nút mở hộp thoại xin miễn tối ưu pin (`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`).
3. **Động cơ giọng đọc tiếng Việt (TTS):** Kiểm tra bộ máy Text-to-Speech của máy, cung cấp nút "Phát âm thử" qua loa.
4. **Thông báo đẩy hệ thống:** Kiểm tra trạng thái cấp quyền hiển thị thông báo ứng dụng, cung cấp nút mở trang cài đặt chi tiết (`ACTION_APPLICATION_DETAILS_SETTINGS`).
5. **Nút kiểm tra lại:** Cho phép người dùng bấm quét lại trạng thái bất kỳ lúc nào để cập nhật giao diện ngay lập tức.
