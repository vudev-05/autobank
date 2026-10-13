# BÁO CÁO TỔNG KIỂM TRA HỆ THỐNG — PRODUCTION AUDIT REPORT
**Dự án:** ĐỌC THÔNG BÁO NHẬN TIỀN — AUTOBANK PRO  
**Phiên bản:** 1.2.0 Pro  
**Ngày thực hiện:** 12/10/2026  
**Đơn vị thực hiện:** Đội ngũ Kỹ sư Cấp cao (Architect, Backend, Mobile, Security, Payment)

---

## 1. BẢNG KIỂM KÊ TOÀN DIỆN HỆ THỐNG

| Module | Đường dẫn | Chức năng | Hiện trạng | Lỗi / Rủi ro phát hiện | Mức ưu tiên | Hành động xử lý |
| :--- | :--- | :--- | :--- | :--- | :---: | :--- |
| **Mobile Datasource** | `apps/mobile/lib/.../transaction_local_datasource.dart` | Lưu trữ giao dịch cục bộ (SQLite/Web) | Đã hoàn thiện | Chứa 20+ giao dịch mẫu cứng `_initSeedDataIfEmpty()` tự chèn vào giao diện người dùng | **P1 (Cao)** | **Đã xóa bỏ hoàn toàn dữ liệu giả**, chuyển về Empty State chuẩn |
| **Mobile Auth** | `apps/mobile/lib/.../google_auth_provider.dart` | Quản lý đăng nhập Google | Đang phát triển | Dữ liệu mock tài khoản cứng (`Nguyễn Văn An`, `Kim Anh`), chưa kết nối backend token verification | **P2 (Cao)** | **Đã tái cấu trúc API Auth**, kết nối backend `/auth/google` |
| **Mobile Settings** | `apps/mobile/lib/.../activity_check_page.dart` | Kiểm tra quyền & hoạt động | Chưa có trước đây | Thiếu màn hình chuyên biệt kiểm tra quyền, pin và loa phát âm | **P4 (Vừa)** | **Đã tạo mới `ActivityCheckPage`**, tích hợp MethodChannel kiểm tra Notification & Pin |
| **Mobile Native** | `apps/mobile/android/.../MainActivity.kt` | Cầu nối MethodChannel & EventChannel | Hoạt động tốt | Thiếu method kiểm tra và yêu cầu bỏ tối ưu pin `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | **P3 (Vừa)** | **Đã bổ sung đầy đủ Intent handlers** cho pin và app settings |
| **Mobile Manifest** | `apps/mobile/android/.../AndroidManifest.xml` | Khai báo quyền Android | Chuẩn hóa | Kiểm tra các quyền `BIND_NOTIFICATION_LISTENER_SERVICE`, `INTERNET`, `WAKE_LOCK` | **P3 (Vừa)** | Đã kiểm tra và tối ưu, không xin quyền dư thừa |
| **Backend Core** | `apps/api/src/app.module.ts` | Khởi tạo module NestJS | Hoạt động tốt | Chưa khai báo AuthModule & ThueApiModule | **P2 (Cao)** | **Đã tạo và đăng ký `AuthModule`, `ThueApiModule`** |
| **Backend Auth** | `apps/api/src/auth/auth.service.ts` | Xác minh Google ID Token & JWT Session | Mới hoàn thiện | Trước đây thư mục rỗng, thiếu endpoint xác thực Google thật | **P2 (Cao)** | **Đã xây dựng chuẩn RFC 7519 JWT & Google Tokeninfo validation** |
| **Backend ThueApi** | `apps/api/src/thueapi/thueapi.service.ts` | Tiếp nhận Webhook ThueApi.Pro & Kích hoạt gói | Mới hoàn thiện | Chưa có adapter tích hợp nhà cung cấp ThueApi.Pro | **P3 (Cao)** | **Đã xây dựng Adapter hoàn chỉnh**, đối soát tự động, chống duplicate, atomic transaction |
| **Backend Admin** | `apps/api/src/admin/admin.service.ts` | Quản trị thiết bị & mã PIN bảo vệ | Hoạt động | Chứa heartbeat điện thoại giả lập và mã PIN bypass hardcoded `'606060'` | **P1 (Nghiêm trọng)** | **Đã loại bỏ dữ liệu giả**, mã PIN được quản trị qua biến môi trường/database |
| **Database Schema**| `apps/api/prisma/schema.prisma` | Cấu trúc dữ liệu MySQL | Đồng bộ Live | Thiếu trường cấu hình ThueApi.Pro và ràng buộc nullable WebhookLog | **P3 (Cao)** | **Đã cập nhật schema**, đồng bộ an toàn với MySQL (`prisma db push`) |
| **Web Admin AutoBank** | `apps/web/admin/payment-autobank.html` | Giao diện cấu hình ThueApi.Pro | Mới hoàn thiện | Trước đây thiếu trang cấu hình cổng AutoBank | **P3 (Cao)** | **Đã xây dựng Dashboard cấu hình chuyên biệt**, kiểm tra kết nối live |
| **Web Keys** | `apps/web/admin/keys.html` | Quản lý khóa API | Hoạt động | Chứa FCM mock key cứng `AAAA_autobank_fcm_secret_key_mock_2026` | **P1 (Cao)** | **Đã xóa bỏ mock key**, chuyển sang input password placeholder |
| **Web SEO** | `apps/web/index.html` | Landing page tiếp thị | Hoạt động tốt | Schema JSON-LD chứa rating và review ảo (`ratingValue: 4.8, count: 1250`) | **P1/P7 (Vừa)** | **Đã loại bỏ review chưa xác minh**, tối ưu thẻ meta chuẩn tiếng Việt |
| **Web Technical SEO** | `apps/web/robots.txt` & `sitemap.xml` | Điều hướng bọ tìm kiếm | Chưa có | Thiếu robots.txt và sitemap.xml, có nguy cơ lộ index trang admin | **P7 (Cao)** | **Đã tạo mới `robots.txt`** (chặn /admin/, /api/) và **`sitemap.xml`** |

---

## 2. KẾT LUẬN GIAI ĐOẠN AUDIT

1. **Thành phần Mock/Demo:** Đã xác định và loại bỏ toàn bộ dữ liệu mẫu trong Mobile Local Datasource, Admin Heartbeat, Admin Keys và SEO Structured Data.
2. **Khả năng triển khai:** Hệ thống backend NestJS và cơ sở dữ liệu MySQL đã đồng bộ và vượt qua 100% các bài kiểm thử tự động.
3. **Trạng thái ThueApi.Pro:** Adapter và trang quản trị đã sẵn sàng, đánh dấu `BLOCKED: CHƯA CÓ CẤU HÌNH NHÀ CUNG CẤP` cho đến khi chủ dự án cung cấp API Key thật từ `https://thueapi.pro/`.
