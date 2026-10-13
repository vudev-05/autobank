# AUTOBANK - KẾ HOẠCH TRIỂN KHAI TỔNG THỂ (MASTER PLAN)

Tài liệu này được biên soạn lại từ bản thiết kế hệ thống gốc, đóng vai trò là "kim chỉ nam" để chúng ta bắt đầu những dòng code đầu tiên. Hệ thống được chia thành các Giai đoạn (Phase) để đảm bảo đi từ "sản phẩm cốt lõi dùng được ngay" (MVP) đến "hệ sinh thái SaaS hoàn chỉnh".

---

## 1. Tổng quan Kiến trúc & Tech Stack

- **Mô hình Repository**: Monorepo (Quản lý chung mã nguồn Mobile, API, Web, Webhooks, v.v.).
- **Mobile App**: Flutter (Dart) + Kotlin (Android Native cho việc lắng nghe thông báo).
- **Backend API**: NestJS (TypeScript), MySQL (Database chính qua Prisma ORM), Redis (Cache & Queue).
- **Web Dashboard**: Next.js (TypeScript).
- **Architecture Pattern**: Clean Architecture (cho Mobile), Modular Monolith (cho Backend), Event-Driven (cho Luồng xử lý giao dịch).

---

## 2. Lộ trình phát triển chi tiết (Roadmap)

### Phase 1: Nền tảng cốt lõi Mobile (Hoàn thiện đồ án & Demo)
*Mục tiêu: Một app Android có khả năng đọc thông báo biến động số dư, lưu trữ cục bộ, lọc trùng lặp và phát thông báo bằng giọng nói (TTS).*

- [x] **Step 1.1: Khởi tạo Monorepo & Kiến trúc Flutter**
  - Khởi tạo thư mục gốc `autobank-platform`.
  - Khởi tạo Flutter project tại `apps/mobile`.
  - Thiết lập cấu trúc thư mục chuẩn Clean Architecture (`core`, `features`, `domain`, `data`, `presentation`).
- [x] **Step 1.2: Cầu nối Android Notification Listener (Kotlin)**
  - Cấu hình quyền `BIND_NOTIFICATION_LISTENER_SERVICE`.
  - Viết class `NotificationListener` bằng Kotlin để bắt thông báo.
  - Dùng `MethodChannel`/`EventChannel` truyền dữ liệu notification realtime từ Kotlin sang Dart.
- [x] **Step 1.3: Transaction Parser & Core Domain**
  - Định nghĩa model `NormalizedTransaction`.
  - Viết Regex/Parser xử lý text cho 2 ngân hàng phổ biến (MBBank, Vietcombank) để trích xuất: Tiền, Nội dung, Thời gian, Số tài khoản.
  - **Viết Unit Test** cho các trường hợp parse chuỗi (Đạt 100% test pass).
- [x] **Step 1.4: Lưu trữ & Xử lý trùng lặp (Local Database)**
  - Tích hợp SQLite (`sqflite`).
  - Thuật toán `fingerprint` SHA256 (bank + account + amount + type + content + time window) để ngăn tạo 2 giao dịch trùng lặp.
- [x] **Step 1.5: UI & Text-to-Speech (TTS)**
  - Giao diện Dashboard Material 3 liệt kê lịch sử giao dịch đẹp, mượt, có thống kê tiền trong ngày.
  - Tích hợp package TTS, đọc số tiền tiếng Việt và mã đơn hàng ("Đã nhận một trăm nghìn đồng...").
  - Tích hợp công cụ Giả lập giao dịch (Simulation) để test trực tiếp trên app.

### Phase 2: Backend Foundation & Đồng bộ Cloud
*Mục tiêu: Đưa dữ liệu lên server, quản lý Merchant (Cửa hàng) và chuẩn bị hạ tầng mở rộng.*

- [x] **Step 2.1: Khởi tạo Backend NestJS**
  - Setup NestJS tại `apps/api` với Prisma ORM và MySQL (XAMPP / Local).
  - Khởi tạo Schema đầy đủ: `merchants`, `users`, `merchant_members`, `bank_accounts`, `transactions`, `orders`, `webhook_logs`.
- [ ] **Step 2.2: Authentication & Quản lý User/Merchant**
  - Tích hợp Firebase Auth làm Authentication Provider.
  - Xây dựng module `users`, `merchants`, và `merchant_members` (Phân quyền).
- [x] **Step 2.3: Core Transaction API**
  - Mobile app gọi API `POST /transactions` đẩy giao dịch lên Backend không đồng bộ.
  - Xử lý Idempotency triệt để qua `fingerprint` trên database MySQL.
- [ ] **Step 2.4: Realtime & Push Notification (FCM)**
  - Setup Firebase Cloud Messaging.
  - App nhận Push Notification khi server xử lý xong giao dịch mới.

### Phase 3: Order, Reconciliation & Thanh toán tự động (Trái tim của hệ thống)
*Mục tiêu: Khách hàng quét mã -> Ngân hàng báo nhận -> Server đối soát -> Trạng thái đơn hàng tự động chuyển sang PAID.*

- [x] **Step 3.1: Hệ thống Quản lý Đơn hàng (Order Engine)**
  - Tạo đơn hàng với mã định danh (vd: `DH1058`).
  - Sinh QR Code động (VietQR) tự động gán sẵn Số tiền + Nội dung là mã đơn.
- [x] **Step 3.2: Động cơ Đối soát (Reconciliation Engine)**
  - Thuật toán matching đa cấp độ (Kiểm thử tự động 100% pass):
    - *Level 1*: Đúng mã, đúng tiền -> Auto PAID.
    - *Level 2*: Đúng mã, thiếu tiền -> PARTIALLY_PAID.
    - *Level 3*: Đúng mã, thừa tiền -> OVERPAID.
  - Khóa giao dịch MySQL bảo toàn ACID.
- [ ] **Step 3.3: Payment Inbox (Xử lý thủ công)**
  - UI để chủ shop tự phân bổ các giao dịch không xác định được (Unmatched).

### Phase 4: Web SaaS & Developer Platform (Định hướng kinh doanh)
*Mục tiêu: Biến Autobank thành 1 nền tảng dịch vụ cho các doanh nghiệp và hệ thống khác.*

- [ ] **Step 4.1: Merchant Dashboard (Next.js)**
  - Giao diện Web thống kê doanh thu, quản lý nhân viên, lịch sử đơn hàng.
- [ ] **Step 4.2: Server-side Bank Connection**
  - Tích hợp trực tiếp với API của ngân hàng (OpenAPI) hoặc các Provider (SePay, Pay2S) để không phụ thuộc 100% vào điện thoại.
- [ ] **Step 4.3: Hệ thống Webhook & Developer API**
  - Sinh API Keys cho Merchant.
  - Server Autobank chủ động gọi Webhook (`payment.success`) đến Website của khách hàng (có retry mechanism logic).

---

## 3. Nguyên tắc Lập trình (Coding Guidelines)

1. **Isolation / Adapter Pattern**: Không "nhúng" trực tiếp thư viện bên thứ 3 (Firebase, RevenueCat, SePay) vào Core Domain. Mọi thứ phải giao tiếp qua Interfaces (vd: `IBankProvider`, `INotificationService`).
2. **Event-Driven Architecture**: Code không chạy tuần tự một chuỗi dài. Transaction sinh ra -> bắn event `TransactionReceived` -> Các module khác (Match Order, TTS, Push) tự lắng nghe và xử lý độc lập.
3. **Tuyệt đối không lưu Credentials Plaintext**: Luôn mã hóa, sử dụng kiến trúc bảo mật tiêu chuẩn nếu sau này xử lý mật khẩu ngân hàng.

---

## 4. Chiến lược UI/UX & Tính năng lõi (SaaS Features)

### 4.1. Mobile App (Flutter)
- **Framework**: Material 3 (M3) hỗ trợ Dynamic Color cho cảm giác hiện đại.
- **Animations**: Sử dụng **Rive** hoặc **Lottie** cho các tương tác micro-interactions (ví dụ: Hiệu ứng tick xanh khi đối soát thành công đơn hàng).
- **State Management**: Riverpod/Bloc giúp UI mượt mà, phản hồi ngay lập tức (real-time) với luồng thông báo từ Native Android.

### 4.2. Web Dashboard (Next.js)
- **Hiệu ứng & Giao diện**: Áp dụng phong cách **Glassmorphism** (kính mờ) và **Dark Mode** sâu. Sử dụng **Vanilla CSS / CSS Modules** để kiểm soát pixel-perfect (không dùng Tailwind trừ khi thực sự cần thiết). Tích hợp **Framer Motion** để tạo độ nảy/trượt mượt mà cho các thẻ (Cards).
- **Biểu đồ Analytics**: Dùng **Recharts** hoặc **Visx** cho các biểu đồ doanh thu tương tác cao.

### 4.3. Tiện ích & Tính năng "vay mượn" từ các nền tảng lớn
1. **Webhook Sandbox (Như Stripe)**: Bảng điều khiển cho Developer test gửi thử Webhook giả lập thanh toán thành công mà không cần chuyển tiền thật. Quản lý API Keys bảo mật (chỉ hiện Secret Key 1 lần duy nhất).
2. **Real-time Payment Feed (Như SePay/VNPAY)**: Mã QR thanh toán (VietQR) sinh động trên màn hình, và giao diện web tự động cập nhật trạng thái "Đã thanh toán" ngay khi App nhận được tiền nhờ WebSockets / Server-Sent Events (SSE).
3. **Payment Inbox**: Bảng điều khiển giao dịch được thiết kế giống hộp thư email. Giao dịch nào không tự động match được với đơn hàng sẽ bị đưa vào nhãn `Cần xử lý` (màu cam) để kế toán can thiệp thủ công.

---

## 5. Hành động ngay lập tức (Next Action)

Để bắt đầu làm thật, chúng ta sẽ đi vào **Phase 1 - Step 1 & 2**:
Thiết lập thư mục **Monorepo**, khởi tạo **Flutter project** và viết cầu nối **Android Notification Listener bằng Kotlin**.
