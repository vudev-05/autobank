# BÁO CÁO CÁC LỖI ĐÃ SỬA CHỮA — BUG FIX REPORT
**Dự án:** AutoBank PRO — Đọc thông báo nhận tiền  
**Phiên bản:** 1.2.0 Pro  
**Ngày lập:** 12/10/2026

---

## 1. DANH SÁCH LỖI VÀ HÀNH ĐỘNG KHẮC PHỤC

### Lỗi #1: Dữ liệu giao dịch ảo (Mock Seed Data) tự sinh trong ứng dụng Mobile
- **Mức độ:** Nghiêm trọng (P1)
- **Vị trí:** `apps/mobile/lib/features/transactions/data/datasources/transaction_local_datasource.dart`
- **Hiện trạng trước:** Phương thức `_initSeedDataIfEmpty()` tự động thêm hơn 20 giao dịch mẫu vào bộ nhớ khi danh sách rỗng, khiến ứng dụng luôn hiển thị doanh thu và giao dịch ảo thay vì trạng thái thực tế.
- **Hành động khắc phục:**
  - Loại bỏ hoàn toàn `_initSeedDataIfEmpty()` và các danh sách dữ liệu cứng.
  - Đảm bảo khi người dùng mới cài đặt, ứng dụng trả về danh sách rỗng `[]`, số lượng `0` và tổng tiền `0.0`.
  - Kích hoạt giao diện Empty State chuyên nghiệp: "Chưa có giao dịch nào".

### Lỗi #2: Mã PIN bypass cứng `'606060'` và Heartbeat điện thoại giả trong Backend
- **Mức độ:** Nghiêm trọng (P1 - Bảo mật)
- **Vị trí:** `apps/api/src/admin/admin.service.ts`
- **Hiện trạng trước:** Phương thức `verifyLivePin` cho phép mã PIN cứng `'606060'` truy cập mà không kiểm tra PIN thực; `lastPhoneHeartbeat` được gán sẵn đối tượng giả lập Samsung Galaxy A54 pin 98% khiến admin luôn thấy điện thoại online dù chưa có máy thật nào kết nối.
- **Hành động khắc phục:**
  - Khởi tạo `lastPhoneHeartbeat = null`, trạng thái mặc định là Offline cho đến khi có thiết bị di động thật gửi heartbeat qua `/admin/phone-heartbeat`.
  - Xóa bỏ hoàn toàn backdoor `'606060'`, yêu cầu xác thực đúng mã PIN cấu hình trong database / env.

### Lỗi #3: Khóa FCM giả lập và thiếu trang quản trị AutoBank ThueApi
- **Mức độ:** Cao (P1 / P3)
- **Vị trí:** `apps/web/admin/keys.html` và hệ thống Admin
- **Hiện trạng trước:** Trường nhập FCM Server Key chứa sẵn giá trị mock `AAAA_autobank_fcm_secret_key_mock_2026`. Thiếu giao diện cấu hình ThueApi.Pro.
- **Hành động khắc phục:**
  - Thay thế mock key bằng trường mật khẩu an toàn có placeholder hướng dẫn lấy từ Firebase Console.
  - Tạo mới trang quản trị `apps/web/admin/payment-autobank.html` chuyên biệt cho ThueApi.Pro, hiển thị trạng thái kết nối và lịch sử Webhook.

### Lỗi #4: Thiếu module xác thực Google ID Token và JWT Session ở Backend
- **Mức độ:** Cao (P2)
- **Vị trí:** `apps/api/src/auth/`
- **Hiện trạng trước:** Thư mục `auth/` chỉ có module trống, thiếu cơ chế xác thực ID Token từ Google, không có API cấp session token hoặc bảo vệ route.
- **Hành động khắc phục:**
  - Xây dựng `AuthService` và `AuthController`:
    - Xác thực Google ID Token trực tiếp qua Google OAuth API (`https://oauth2.googleapis.com/tokeninfo`).
    - Kiểm tra issuer (`accounts.google.com`), expiration và audience (`GOOGLE_CLIENT_ID`).
    - Cấp JWT session token chuẩn RFC 7519 với mã hóa HMAC-SHA256.
    - Cung cấp endpoints: `POST /auth/google`, `GET /auth/me`, `POST /auth/logout`, `POST /auth/verify-token`.

### Lỗi #5: Thiếu tích hợp cổng thanh toán ThueApi.Pro và tự động kích hoạt gói
- **Mức độ:** Cao (P3)
- **Vị trí:** `apps/api/src/thueapi/`
- **Hiện trạng trước:** Dự án chưa có module tiếp nhận webhook từ ThueApi.Pro để tự động đối soát và gia hạn bản quyền cho khách hàng.
- **Hành động khắc phục:**
  - Xây dựng `ThueApiService`, `ThueApiController`, `ThueApiModule`:
    - Tiếp nhận Webhook tại `POST /webhooks/thueapi`.
    - Xác thực chữ ký HMAC-SHA256 (`X-Signature`).
    - Cơ chế chống trùng lặp (Idempotency) qua fingerprint giao dịch.
    - Tự động nhận diện mã đơn hàng, đối soát số tiền và kích hoạt bản quyền tương ứng (cộng dồn thời hạn theo gói dịch vụ).
    - Cập nhật database trong một Atomic Transaction an toàn (`prisma.$transaction`).
    - Đánh dấu `BLOCKED: CHƯA CÓ CẤU HÌNH NHÀ CUNG CẤP` rõ ràng khi chưa có API Key.

### Lỗi #6: Thiếu màn hình kiểm tra hoạt động và quyền Android
- **Mức độ:** Trung bình (P5)
- **Vị trí:** `apps/mobile/lib/features/settings/presentation/pages/activity_check_page.dart`
- **Hiện trạng trước:** Ứng dụng chưa có màn hình trực quan để người dùng kiểm tra trạng thái quyền đọc thông báo, quyền chạy ngầm không tối ưu pin và kiểm tra loa phát âm TTS.
- **Hành động khắc phục:**
  - Xây dựng `ActivityCheckPage` với 4 thẻ kiểm tra quyền chi tiết, nút mở đúng màn hình cài đặt Android hệ thống và nút phát âm thử nghiệm TTS.
  - Bổ sung native MethodChannel handlers trong `MainActivity.kt` cho `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` và `ACTION_APPLICATION_DETAILS_SETTINGS`.

### Lỗi #7: Dữ liệu đánh giá giả lập (Fake AggregateRating) trong Technical SEO
- **Mức độ:** Trung bình (P7)
- **Vị trí:** `apps/web/index.html`
- **Hiện trạng trước:** Thẻ Schema JSON-LD khai báo `ratingValue: 4.8` và `ratingCount: 1250` khi chưa có dữ liệu đánh giá thật từ Google Play.
- **Hành động khắc phục:**
  - Loại bỏ khối `aggregateRating` giả lập khỏi JSON-LD.
  - Tạo mới `robots.txt` và `sitemap.xml`, chặn các bot tìm kiếm index trang quản trị nội bộ `/admin/*`.
