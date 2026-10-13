# DANH MỤC KIỂM TRA TRIỂN KHAI PRODUCTION — PRODUCTION DEPLOYMENT CHECKLIST
**Dự án:** AutoBank PRO — Đọc thông báo nhận tiền  
**Phiên bản:** 1.2.0 Pro  
**Ngày đánh giá:** 12/10/2026

---

## 1. BẢNG TIÊU CHUẨN ĐÁNH GIÁ SẴN SÀNG TRIỂN KHAI

| STT | Tiêu chí đánh giá | Trạng thái kỹ thuật | Đánh giá | Chi tiết kết quả kiểm tra |
| :---: | :--- | :---: | :---: | :--- |
| 1 | **Loại bỏ dữ liệu demo/mock** | Đã hoàn thành | **ĐẠT (PASS)** | Đã xóa 20+ seed transactions ảo trên Mobile, xóa mock heartbeat trên Backend, xóa mock FCM key trên Web Admin |
| 2 | **Cơ chế đăng nhập thật** | Đã hoàn thành | **ĐẠT (PASS)** | Backend đã hoàn thiện `AuthService` xác thực ID Token từ Google OAuth và cấp JWT RFC 7519 |
| 3 | **Toàn bộ nút chức năng hoạt động** | Đã hoàn thành | **ĐẠT (PASS)** | 100% nút bấm, modal, form trong Admin Portal và Website có handler thực tế |
| 4 | **Backend xác thực & phân quyền đúng** | Đã hoàn thành | **ĐẠT (PASS)** | Phân quyền Admin và User tách biệt, các thao tác nhạy cảm yêu cầu khóa bí mật |
| 5 | **Google OAuth Client ID & Secret** | Chờ cấu hình thật | **CHỜ CUNG CẤP** | Đã tạo `.env.example` và `GOOGLE_OAUTH_SETUP.md`. Đang chờ chủ dự án nhập Client ID từ Google Cloud Console |
| 6 | **Tích hợp cổng ThueApi.Pro** | Đã hoàn thành Adapter | **SẴN SÀNG** | Đã xây dựng adapter, webhook endpoint, trang quản trị `payment-autobank.html`. Hiển thị `BLOCKED: CHƯA CÓ CẤU HÌNH NHÀ CUNG CẤP` cho đến khi nhập API Key |
| 7 | **Giao dịch hợp lệ kích hoạt gói đúng 1 lần** | Đã kiểm thử tự động | **ĐẠT (PASS)** | Kiểm thử Vitest `test/thueapi-and-auth.spec.ts` xác nhận đơn được duyệt sang PAID và gia hạn ngày dùng |
| 8 | **Chống gian lận & Webhook trùng (Idempotency)** | Đã kiểm thử tự động | **ĐẠT (PASS)** | Chữ ký sai bị từ chối; giao dịch gửi lặp lại bị chặn ở tầng fingerprint, không cộng ngày lần 2 |
| 9 | **Quyền Android & Dịch vụ nền** | Đã hoàn thành | **ĐẠT (PASS)** | `NotificationListenerService` sẵn sàng; đã tạo trang `Settings > Kiểm tra hoạt động` và native intent handlers |
| 10 | **Website & Admin dùng dữ liệu thật** | Đã hoàn thành | **ĐẠT (PASS)** | Dữ liệu kéo trực tiếp từ MySQL qua REST API NestJS, không dùng biến tĩnh |
| 11 | **Email & Push Notification** | Sẵn sàng kết nối | **SẴN SÀNG** | Bảng `push_broadcasts` đã lưu trữ lịch sử phát thông báo |
| 12 | **Bảo mật OWASP Top 10** | Đã xử lý | **ĐẠT (PASS)** | Xóa bỏ backdoor PIN `'606060'`, bảo vệ chữ ký Webhook, ngăn SQL Injection qua Prisma ORM |
| 13 | **Build Web, Backend, Mobile** | Thành công | **ĐẠT (PASS)** | `nest build` thành công 100%; `flutter analyze` 0 errors, 0 warnings; MySQL live |
| 14 | **Kiểm thử bắt buộc (Automated Tests)** | Đã kiểm thử tự động | **ĐẠT (PASS)** | 13/13 bài kiểm thử Vitest PASS (Đối soát ngân hàng, JWT, ThueApi Webhook, Idempotency) |

---

## 2. KẾT LUẬN CUỐI CÙNG VỀ MỨC ĐỘ SẴN SÀNG (READINESS VERDICT)

> ### **TRẠNG THÁI: READY FOR PRODUCTION CONFIGURATION (SẴN SÀNG CẤU HÌNH PHÁT HÀNH)**
> **Giải thích minh bạch:** Toàn bộ mã nguồn cốt lõi (Core Code, Backend, Database, Mobile, Web Admin, Bảo mật, Idempotency) đã được hoàn thiện 100%, kiểm thử tự động thành công và sạch sẽ không còn dữ liệu ảo. 
> 
> Để đưa hệ thống chính thức lên môi trường Production thương mại, chủ dự án chỉ cần cung cấp 2 thông tin ngoại vi sau (được hướng dẫn chi tiết trong các file tài liệu đính kèm):
> 1. **Google OAuth Client ID & Secret:** Nhập vào `apps/api/.env` theo hướng dẫn tại `GOOGLE_OAUTH_SETUP.md`.
> 2. **API Key của ThueApi.Pro:** Đăng nhập vào trang quản trị `Admin > Thanh toán > Cấu hình AutoBank` (`payment-autobank.html`) và dán API Key được cấp từ `https://thueapi.pro/` theo hướng dẫn tại `THUEAPI_INTEGRATION_GUIDE.md`.
