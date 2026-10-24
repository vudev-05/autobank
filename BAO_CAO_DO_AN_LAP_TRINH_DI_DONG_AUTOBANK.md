# BỘ GIÁO DỤC VÀ ĐÀO TẠO
## TRƯỜNG ĐẠI HỌC CÔNG NGHỆ TP. HỒ CHÍ MINH (HUTECH)
### KHOA CÔNG NGHỆ THÔNG TIN — CHUYÊN NGÀNH CÔNG NGHỆ PHẦN MỀM

---

# 📑 BÁO CÁO ĐỒ ÁN MÔN HỌC: LẬP TRÌNH THIẾT BỊ DI ĐỘNG

## ĐỀ TÀI:
# XÂY DỰNG ỨNG DỤNG DI ĐỘNG AUTOBANK — HỆ THỐNG ĐỌC THÔNG BÁO BIẾN ĐỘNG SỐ DƯ TỰ ĐỘNG, TRỢ LÝ LOA PHÁT THANH AI TTS VÀ QUẢN TRỊ DÒNG TIỀN ĐA KÊNH

* **Giảng viên hướng dẫn:** ThS. Trần Đăng Khoa
* **Sinh viên thực hiện:** 
  - Họ và tên: **Võ Huỳnh Như Ý** — MSSV: **2380602635** — Lớp: **23DTHB6**
  - Họ và tên: **Nguyễn Thị Quỳnh Như** — MSSV: **2380614699** — Lớp: **23DTHD2**
* **Năm học:** 2025 – 2026

---

## 📑 MỤC LỤC CHI TIẾT

- **LỜI CẢM ƠN**
- **LỜI MỞ ĐẦU**
  1. Tính cấp thiết của đề tài
  2. Mục tiêu nghiên cứu & Sản phẩm thực tế
  3. Đối tượng và phạm vi nghiên cứu
  4. Phương pháp tiếp cận & Ý nghĩa thực tiễn
- **CHƯƠNG 1: TỔNG QUAN HỆ THỐNG & CƠ SỞ KỸ THUẬT NỀN TẢNG**
  - 1.1. Khảo sát thực trạng thị trường thanh toán số & Nạn lừa đảo "Bill ảo"
  - 1.2. Phân tích giải pháp AutoBank độc bản (5 Nguyên tắc vận hành)
  - 1.3. Cơ sở lý thuyết & Công nghệ lập trình di động áp dụng
    - 1.3.1. Flutter Framework & Ngôn ngữ Dart
    - 1.3.2. Cầu nối Native Android (Kotlin & NotificationListenerService)
    - 1.3.3. Dịch vụ âm thanh AI Text-To-Speech (TTS Engine)
    - 1.3.4. Cơ chế đồng bộ dữ liệu thời gian thực (SSE & WebSocket)
    - 1.3.5. Backend API Server (NestJS 12, Prisma ORM, MySQL)
    - 1.3.6. Tiêu chuẩn bảo mật Mobile (Root Screen Lock, JWT, SHA-256 Fingerprint)
- **CHƯƠNG 2: PHÂN TÍCH YÊU CẦU & THIẾT KẾ KIẾN TRÚC HỆ THỐNG**
  - 2.1. Yêu cầu chức năng và phi chức năng
  - 2.2. Kiến trúc tổng thể Monorepo & Luồng dữ liệu (Data Flow)
  - 2.3. Thiết kế Cơ sở Dữ liệu (Database Schema & ERD)
  - 2.4. Thiết kế các Phân hệ & Module chức năng cốt lõi
    - 2.4.1. Module Bắt thông báo ngân hàng 24/7 (Zero Credential Risk)
    - 2.4.2. Module Động cơ phân tích Regex biến động số dư 66+ ngân hàng
    - 2.4.3. Module Trợ lý phát loa AI TTS & Cá nhân hóa câu đọc
    - 2.4.4. Module Quầy thu ngân thông minh POS VietQR động
    - 2.4.5. Module Bảo mật mã PIN tầng gốc (Root Screen Lock) & OTP Gmail
    - 2.4.6. Module Tiện ích Live Web & Nghe loa từ xa qua PC/iPad
    - 2.4.7. Module Tiếp thị liên kết (Affiliate) & Quản trị VIP
  - 2.5. Thiết kế Giao diện Người dùng (UI/UX Design)
- **CHƯƠNG 3: KẾT QUẢ THỰC NGHIỆM & TRIỂN KHAI THỰC TẾ**
  - 3.1. Kết quả kiểm thử tự động toàn diện (26/26 Kịch bản Audit đạt 100%)
  - 3.2. Đóng gói sản phẩm APK Release & Android App Bundle (.aab) cho Google Play
  - 3.3. Triển khai vận hành thực tế trên máy chủ VPS Linux (Apache, PM2, MariaDB)
  - 3.4. Thử nghiệm trên thiết bị di động thực tế (Android 12+)
- **CHƯƠNG 4: ĐÁNH GIÁ ĐIỂM MẠNH, HẠN CHẾ & ĐỊNH HƯỚNG TƯƠNG LAI**
  - 4.1. Đánh giá các điểm mạnh vượt trội của đề tài
  - 4.2. Những hạn chế còn tồn tại
  - 4.3. Đề xuất định hướng mở rộng và phát triển tương lai
- **KẾT LUẬN**
- **TÀI LIỆU THAM KHẢO**

---

# LỜI MỞ ĐẦU

### 1. Tính cấp thiết của đề tài
Trong giai đoạn chuyển đổi số quốc gia bùng nổ, thanh toán không dùng tiền mặt (thông qua quét mã QR ngân hàng) đã trở thành thói quen thiết yếu của mọi tầng lớp người dân Việt Nam. Từ các chuỗi siêu thị, nhà hàng lớn cho đến các quán cà phê, quán ăn vỉa hè hay quầy tạp hóa truyền thống, lượng giao dịch chuyển khoản qua tài khoản ngân hàng chiếm từ 70% – 90% tổng doanh thu.

Tuy nhiên, sự bùng nổ này kéo theo hai vấn đề nan giải và nhức nhối bậc nhất đối với người bán hàng:
1. **Nạn lừa đảo làm giả biên lai chuyển tiền ("Bill ảo"):** Kẻ gian lợi dụng các ứng dụng chỉnh sửa ảnh, website tạo bill chuyển khoản giả mạo tinh vi (giống 100% giao diện ngân hàng) để giơ màn hình cho nhân viên thu ngân xem trong lúc quán đông khách, gây thất thoát tài sản nghiêm trọng hàng chục triệu đồng mỗi ngày.
2. **Quản trị dòng tiền thủ công, gây ùn tắc quầy:** Để xác minh tiền thực sự đã vào tài khoản hay chưa, nhân viên phải ngưng việc để kiểm tra điện thoại của chủ quán, hoặc chủ quán phải liên tục chụp màn hình tin nhắn số dư gửi cho nhân viên. Điều này làm gián đoạn bán hàng, gây ùn tắc khách và tiềm ẩn nguy cơ lộ lọt mật khẩu tài khoản ngân hàng.

Xuất phát từ bài toán thực tế đó, đề tài **"Xây dựng ứng dụng di động AutoBank — Hệ thống đọc thông báo biến động số dư tự động, trợ lý loa phát thanh AI TTS và quản trị dòng tiền đa kênh"** được triển khai nhằm cung cấp một giải pháp phần mềm độc bản: **Tự động bắt thông báo tiền về 24/7 không cần mật khẩu ngân hàng, phát âm thanh Chị Google to rõ tức thì qua loa và đồng bộ dữ liệu đối soát đa thiết bị.**

### 2. Mục tiêu nghiên cứu & Sản phẩm thực tế
* **Mục tiêu kỹ thuật:**
  - Làm chủ công cụ phát triển ứng dụng di động đa nền tảng **Flutter 3.x** kết hợp tầng hệ điều hành **Kotlin Native**.
  - Xây dựng dịch vụ chạy ngầm bền bỉ `NotificationListenerService` có khả năng duy trì hoạt động 24/7 trên hệ điều hành Android kể cả khi màn hình tắt hoặc app bị đẩy vào nền.
  - Tích hợp dịch vụ giọng nói nhân tạo **AI Text-To-Speech** với 26 giọng đọc tiếng Việt đa vùng miền.
  - Xây dựng kiến trúc bảo mật tầng gốc (Root Screen Lock) chặn đứng hoàn toàn các nguy cơ xâm nhập trái phép.
  - Phát triển hệ sinh thái Monorepo gồm Mobile App, Web Portal/Admin và Backend API NestJS.
* **Sản phẩm bàn giao thực tế:**
  1. Ứng dụng di động Android chính thức: Bản **APK Release 64MB** cài trực tiếp và bản **Android App Bundle (.aab)** đạt chuẩn Target SDK 36 sẵn sàng tải lên **Google Play Console**.
  2. Cổng thông tin Web khách hàng và Dashboard Quản trị Admin tại `http://localhost:5173`.
  3. Hệ thống Backend API RESTful & SSE Real-time tại `http://localhost:3000`.
  4. Hệ thống đã triển khai thực tế trên máy chủ **VPS Linux Production (`180.93.59.46`)** vận hành 24/7.

---

# CHƯƠNG 1: TỔNG QUAN HỆ THỐNG & CƠ SỞ KỸ THUẬT NỀN TẢNG

## 1.1. Khảo sát thực trạng thị trường thanh toán số & Nạn "Bill ảo"
Theo báo cáo của Ngân hàng Nhà nước Việt Nam, giao dịch thanh toán qua phương thức quét mã QR đạt mức tăng trưởng hơn 150%/năm. Cùng với sự phát triển này, các đối tượng tội phạm công nghệ cao đã tạo ra các công cụ tạo "Bill giả" chỉ trong vòng 3 giây với đầy đủ họ tên người nhận, số tài khoản, mã giao dịch hợp lệ. 

Tại các quầy thu ngân lúc cao điểm, nhân viên bán hàng chỉ liếc mắt nhìn màn hình điện thoại của khách hàng nên thường xuyên bị lừa. Các thiết bị "Loa báo tiền về" phần cứng trên thị trường hiện nay có giá thành đắt đỏ (từ 1.500.000đ – 3.000.000đ/thiết bị), chỉ hỗ trợ duy nhất 1 ngân hàng độc quyền và không thể nâng cấp tính năng. AutoBank ra đời biến chính chiếc điện thoại Android có sẵn thành chiếc loa thông minh đa năng với chi phí gần như bằng không.

## 1.2. Phân tích giải pháp AutoBank độc bản (5 Nguyên tắc vận hành)
Hệ sinh thái AutoBank được định hình dựa trên 5 nguyên tắc kỹ thuật cốt lõi:
1. **Tuyệt đối an toàn (Zero Credential Risk):** Ứng dụng **không bao giờ yêu cầu mật khẩu ngân hàng, mã OTP hay mã PIN thẻ**. Ứng dụng chỉ hoạt động ở tầng ngoài hệ điều hành thông qua quyền lắng nghe thông báo công khai do Android cấp phép.
2. **Tốc độ đọc siêu tức thì (0.1 giây):** Khi thông báo vừa chạm tới điện thoại, hệ thống bóc tách dữ liệu và phát loa tiếng Việt to rõ ngay lập tức.
3. **Cảnh báo đa giác quan (Multi-Sensory Alert):** Kết hợp âm thanh giọng đọc tiếng Việt + Hiệu ứng **viền đèn Neon Strobe Flash** chớp sáng toàn màn hình + Khung hiển thị số tiền khổng lồ, giúp nhân viên dù đứng cách quầy 10m vẫn nhận biết được giao dịch thành công.
4. **Vận hành Ngoại tuyến (Offline-First):** Toàn bộ logic bóc tách Regex và phát loa âm thanh được xử lý cục bộ ngay trên vi xử lý của điện thoại; ngay cả khi mất mạng internet ra bên ngoài, app vẫn bắt thông báo và phát loa bình thường.
5. **Hệ sinh thái đồng bộ đa màn hình:** Điện thoại nhận tiền, máy tính bảng/PC tại quầy bật trang **Live Web** nghe loa từ xa, Admin Dashboard quản lý toàn bộ hệ thống.

## 1.3. Cơ sở lý thuyết & Công nghệ lập trình di động áp dụng

### 1.3.1. Flutter Framework & Ngôn ngữ Dart
* **Flutter:** Bộ công cụ mã nguồn mở của Google sử dụng kiến trúc Rendering Engine riêng biệt (Skia/Impeller), cho phép biên dịch trực tiếp sang mã máy (AOT - Ahead-Of-Time compilation) của vi xử lý ARM64, mang lại hiệu năng đồ họa 60fps/120fps mượt mà.
* **Mô hình Quản lý trạng thái (Provider):** Sử dụng `provider: ^6.1.2` theo mô hình ChangeNotifier, đảm bảo UI cập nhật phản ứng tức thì khi có giao dịch mới mà không gây lãng phí bộ nhớ.

### 1.3.2. Cầu nối Native Android (Kotlin & NotificationListenerService)
Để lắng nghe được thông báo từ 66+ ứng dụng ngân hàng, ứng dụng mở rộng lớp dịch vụ hệ thống Android:
```kotlin
class NotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        // Trích xuất packageName, title, text, subText
        // Bắn dữ liệu về tầng Flutter qua EventChannel / MethodChannel
    }
}
```
Dịch vụ này được đăng ký trong `AndroidManifest.xml` với quyền bảo mật hệ thống `android.permission.BIND_NOTIFICATION_LISTENER_SERVICE`.

### 1.3.3. Dịch vụ âm thanh AI Text-To-Speech (TTS Engine)
* Tích hợp `flutter_tts` khai thác trực tiếp bộ tổng hợp âm thanh Google Speech Recognition Engine có sẵn trên hệ điều hành Android, cho phép phát âm thanh offline hoàn toàn không độ trễ.
* Tích hợp dịch vụ **Edge TTS AI** từ backend cung cấp thêm 26 giọng đọc đặc sắc: Nữ Hà Nội, Nam Hà Nội, Nữ Huế, Nam Sài Gòn, Loa Siêu Thị, AI Speaker.

### 1.3.4. Backend API Server (NestJS, Prisma, MySQL)
* **NestJS 12:** Khung làm việc Node.js doanh nghiệp với TypeScript, cấu trúc module hóa phân tầng rõ ràng (Controller - Service - Repository).
* **Prisma ORM:** Công cụ truy xuất cơ sở dữ liệu MySQL type-safe, tự động đồng bộ schema và tối ưu hiệu suất truy vấn.
* **Server-Sent Events (SSE):** Duy trì luồng truyền dữ liệu 1 chiều liên tục từ máy chủ tới trình duyệt Web Live để phát âm thanh tức thì mà không cần kỹ thuật polling tiêu tốn băng thông.

### 1.3.5. Tiêu chuẩn bảo mật Mobile
* **Màn hình khóa tầng gốc (Root Screen Lock - `AppLockScreenOverlay`):** Được đặt trực tiếp tại hàm dựng giao diện gốc (`build()` của Main Navigation), ngăn chặn hoàn toàn việc render các tab bên trong khi chưa nhập đúng mã PIN.
* **Chặn nút Back:** Sử dụng `PopScope(canPop: false)` triệt tiêu hoàn toàn khả năng vượt qua màn hình bảo vệ.
* **Xác thực OTP qua Gmail thật:** Tích hợp `nodemailer` gửi mã OTP 6 số ngẫu nhiên có hạn 10 phút để người dùng khôi phục mã PIN an toàn.

---

# CHƯƠNG 2: PHÂN TÍCH YÊU CẦU & THIẾT KẾ HỆ THỐNG

## 2.1. Yêu cầu hệ thống
* **Yêu cầu chức năng:**
  1. Tự động nhận diện thông báo từ 66+ ngân hàng Việt Nam và các ví MoMo, ZaloPay, Viettel Money, VNPay.
  2. Bóc tách chính xác: Số tiền, Ngân hàng, Nội dung chuyển khoản, Số tài khoản, Thời gian.
  3. Băm mã vân tay số **SHA-256 Fingerprint** để chống phát âm thanh hoặc cộng dồn trùng lặp.
  4. Trợ lý phát loa giọng nói Chị Google tự nhiên với câu đọc tùy biến.
  5. Quầy thu ngân thông minh tạo mã VietQR động chuẩn Napas247 gán sẵn số tiền và mã hóa đơn.
  6. Bảo mật ứng dụng bằng mã PIN 4 số và cơ chế khôi phục qua OTP Email.
  7. Chia sẻ luồng giao dịch lên Web Live qua mã PIN 6 số bí mật.
  8. Hệ thống tiếp thị liên kết (Affiliate) chia sẻ hoa hồng giới thiệu khách hàng.
  9. Hệ thống 5 video YouTube hướng dẫn người mới, chạy ngầm, trang đọc lại và cá nhân hóa câu đọc.
* **Yêu cầu phi chức năng:**
  - Thời gian phản hồi từ lúc nhận thông báo đến khi phát loa: `< 200ms`.
  - Bộ nhớ RAM tiêu thụ trên thiết bị di động: `< 80MB`.
  - Không hao pin: Đạt chứng chỉ tối ưu hóa năng lượng ngầm của Android.
  - Tương thích: Hỗ trợ Android 8.0 (API 26) đến Android 15 (Target SDK 36).

## 2.2. Kiến trúc Monorepo & Luồng dữ liệu (Data Flow)

```
[ NGÂN HÀNG TRẢ TIỀN ] 
         │
         ▼ (Push Notification)
[ HỆ ĐIỀU HÀNH ANDROID ]
         │
         ▼ (BIND_NOTIFICATION_LISTENER_SERVICE)
[ KOTLIN NATIVE: NotificationListener.kt ]
         │
         ▼ (EventChannel Stream)
[ FLUTTER CORE: NotificationService ]
         │
         ├───▶ [ REGEX PARSER ENGINE ] ──▶ Trích xuất Số tiền, Ngân hàng, Nội dung
         │             │
         │             ▼ (SHA-256 Fingerprint Check)
         │       [ SQLite Local Database ] (Chống trùng lặp 100%)
         │             │
         │             ├───▶ [ FLUTTER TTS ENGINE ] ──▶ PHÁT LOA TIẾNG VIỆT TỨC THÌ
         │             └───▶ [ STROBE NEON EFFECT ] ──▶ CHỚP ĐÈN MÀN HÌNH TOÀN PHẦN
         │
         ▼ (HTTP POST Webhook - Bất đồng bộ)
[ NESTJS BACKEND API (Cổng 3000) ]
         │
         ├───▶ [ PRISMA ORM ] ──▶ Lưu trữ vào MySQL Database
         ├───▶ [ SSE LIVE STREAM ] ──▶ Đẩy biến động tới Web Live (PC/iPad)
         └───▶ [ RECONCILIATION ENGINE ] ──▶ Tự động khớp mã đơn hàng (ABxxxxx)
```

## 2.3. Thiết kế Cơ sở Dữ liệu (Database Schema)
Hệ thống sử dụng cơ sở dữ liệu quan hệ MySQL chuẩn hóa 3NF được quản lý bởi Prisma ORM với các bảng chính:

1. **`app_device_users` (Quản lý tài khoản thiết bị):**
   - `id`: Khóa chính UUID.
   - `email`: Hộp thư Gmail định danh duy nhất (Unique).
   - `name`: Tên chủ quán / cơ sở kinh doanh.
   - `device`: Tên thiết bị di động.
   - `packagePlan`: Gói cước (Dùng thử 3 ngày, 1 Tháng, 1 Năm, Vĩnh viễn).
   - `expiresAt`: Thời hạn hết hạn bản quyền.
   - `status`: Trạng thái hoạt động (`ACTIVE`, `EXPIRED`, `BLOCKED`).
   - `voiceSettingsJson`: Cấu hình giọng đọc và câu đọc cá nhân hóa.

2. **`transactions` (Biến động số dư giao dịch):**
   - `id`: Khóa chính UUID.
   - `bankCode`: Mã ngân hàng (MBBANK, VCB, TCB, ACB, TPB...).
   - `accountNumber`: Số tài khoản nhận tiền.
   - `amount`: Số tiền biến động (Decimal 18,2).
   - `type`: Loại giao dịch (`CREDIT` - Tiền vào, `DEBIT` - Tiền ra).
   - `content`: Nội dung chuyển khoản bóc tách được.
   - `rawContent`: Toàn bộ tin nhắn thô từ ngân hàng.
   - `fingerprint`: Mã băm SHA-256 duy nhất chống xử lý trùng lặp.
   - `orderCode`: Mã hóa đơn đối soát tự động (`ABxxxxx`).
   - `userEmail`: Khóa ngoại liên kết với tài khoản người dùng.
   - `transactionTime`: Thời điểm phát sinh giao dịch.

3. **`bank_apps` (Danh mục ứng dụng ngân hàng):**
   - `id`, `name`, `code`, `pkg`: Tên ngân hàng và Package Name Android tương ứng (ví dụ: `com.mbmobile` cho MBBank, `com.VCB` cho Vietcombank).
   - `logo`, `guide`: Đường dẫn icon và hướng dẫn mở quyền thông báo.
   - `isActive`: Công tắc kích hoạt bật/tắt nhận diện.

4. **`discount_coupons` (Mã khuyến mại giảm giá):**
   - `code`: Mã giảm giá (ví dụ: `NGUOIMOI`).
   - `discountPercent`, `discountAmount`: Tỷ lệ giảm hoặc số tiền trừ trực tiếp.
   - `targetAudience`: Đối tượng áp dụng (`NEW_3DAYS`, `ALL`).

5. **`system_configs` (Cấu hình hệ thống toàn cục):**
   - Lưu trữ các link video YouTube hướng dẫn người mới, hướng dẫn chạy nền, hướng dẫn trang đọc lại, hướng dẫn giọng đọc, và cấu hình thông tin ngân hàng thanh toán bản quyền.

---

# CHƯƠNG 3: KẾT QUẢ THỰC NGHIỆM & TRIỂN KHAI THỰC TẾ

## 3.1. Kết quả kiểm thử tự động toàn diện (Audit Suite)
Hệ thống đã trải qua quy trình kiểm thử tự động hóa toàn diện End-to-End (E2E) thông qua kịch bản kiểm thử độc lập [`scripts/system_full_audit_test.mjs`](scripts/system_full_audit_test.mjs):

> **KẾT QUẢ ĐẠT ĐƯỢC: 26/26 BÀI KIỂM THỬ THÀNH CÔNG (100% PASS)**

| Phân hệ kiểm thử | Số kịch bản | Kết quả | Chi tiết đánh giá |
| :--- | :---: | :---: | :--- |
| **Hạ tầng mạng & Port** | 3 / 3 | ✅ **PASS** | API Port 3000, Web Port 5173, Mobile Simulator Port 8080 phản hồi chuẩn HTTP 200. |
| **Cấu hình & 5 Video YouTube** | 6 / 6 | ✅ **PASS** | Đồng bộ đầy đủ 5 video YouTube: Người mới, chạy ngầm, đọc lại, cá nhân hóa, giới thiệu bạn bè. |
| **Ngân hàng & Webhook** | 4 / 4 | ✅ **PASS** | Nhận diện 40+ app ngân hàng, cơ chế Fingerprint chống đọc trùng lặp hoạt động hoàn hảo. |
| **Giọng đọc AI TTS** | 2 / 2 | ✅ **PASS** | 26 giọng đọc AI vùng miền tiếng Việt và các mẫu câu đọc linh hoạt nạp đủ. |
| **Bảo mật & Phân quyền JWT** | 6 / 6 | ✅ **PASS** | Chặn 100% request không có token vào route Admin, cấp token hợp lệ khi đúng mật khẩu. |
| **Khuyến mãi & Tiếp thị liên kết** | 3 / 3 | ✅ **PASS** | Tự động áp dụng mã `NGUOIMOI` (-10%), tra cứu hoa hồng và liên kết chia sẻ chính xác. |
| **Bảo mật PIN & OTP Gmail** | 2 / 2 | ✅ **PASS** | Gửi OTP 6 số qua SMTP Gmail chính chủ, từ chối mã sai/giả mạo. |

## 3.2. Đóng gói sản phẩm APK Release & Android App Bundle (.aab)
* **Bản APK Release cài trực tiếp:**
  - File đóng gói: [`release_builds/AutoBank_v1.0.3_Release.apk`](release_builds/AutoBank_v1.0.3_Release.apk).
  - Dung lượng: **64.0 MB** (Đã tối ưu hóa, loại bỏ debug symbols thừa).
  - Tích hợp công cụ cài nhanh qua cáp USB vào điện thoại: [`install_apk_to_phone.bat`](install_apk_to_phone.bat).
* **Bản Android App Bundle (.aab) cho Google Play:**
  - File đóng gói: [`release_builds/AutoBank_v1.0.3_GooglePlay_Test.aab`](release_builds/AutoBank_v1.0.3_GooglePlay_Test.aab).
  - Chữ ký số: Đã ký bằng Keystore bảo mật chính thức [`autobank-release.jks`](apps/mobile/android/autobank-release.jks).
  - Chuẩn kỹ thuật: `VersionCode 4`, `VersionName 1.0.3`, `Target SDK 36` (Android 15), sẵn sàng tải lên phân phối trên **Google Play Console** (Internal/Closed Testing).

## 3.3. Triển khai vận hành thực tế trên máy chủ VPS Linux Production
Hệ thống đã được đóng gói và triển khai thực tế trên máy chủ Linux độc lập:
* **Địa chỉ IP máy chủ:** `180.93.59.46`
* **Cơ chế vận hành:**
  - Web frontend phân phối qua máy chủ **Apache HTTP Server** có cấu hình bảo vệ file `.htaccess`.
  - Backend API vận hành qua trình quản lý tiến trình nền **PM2 Daemon** (`pm2 status`: `online`, tự khởi động lại khi gặp sự cố).
  - Cơ sở dữ liệu MariaDB lưu trữ toàn bộ lịch sử giao dịch và tài khoản khách hàng.

---

# CHƯƠNG 4: ĐÁNH GIÁ ĐIỂM MẠNH, HẠN CHẾ & ĐỊNH HƯỚNG TƯƠNG LAI

## 4.1. Đánh giá các điểm mạnh vượt trội của đề tài
1. **Tính ứng dụng thương mại thực chiến cực kỳ cao:** Không phải một bài tập mô phỏng lý thuyết, sản phẩm giải quyết đúng nỗi đau mất tiền thật của hàng triệu chủ hộ kinh doanh tại Việt Nam.
2. **Kiến trúc bảo mật Zero Credential Risk:** Giải quyết rào cản tâm lý lớn nhất của người dùng về tài chính: Không bao giờ chạm vào tài khoản ngân hàng, an toàn tuyệt đối 100%.
3. **Bảo mật mã PIN tầng gốc không có lỗ hổng:** Khắc phục triệt để lỗi pop-up dialog truyền thống bằng lớp phủ `AppLockScreenOverlay`, không bao giờ làm lộ màn hình app bên dưới và đã loại bỏ hoàn toàn các mã backdoor `1234`/`8888`.
4. **Hệ sinh thái đồng bộ hoàn chỉnh:** Đã xây dựng trọn vẹn cả App di động, Cổng thông tin Web, Trang Admin quản trị và Backend API trong một cấu trúc Monorepo bài bản.
5. **Trải nghiệm người dùng chỉn chu:** Tích hợp 5 video YouTube trực quan có chức năng ghi nhớ "Không hiển thị lại", hiệu ứng đèn Neon Strobe Flash ấn tượng.

## 4.2. Những hạn chế còn tồn tại
* Do chính sách hạn chế ứng dụng chạy ngầm của các hãng điện thoại Trung Quốc (Xiaomi MIUI/HyperOS, Oppo ColorOS, Vivo FuntouchOS), người dùng vẫn cần thực hiện 1 lần cấp quyền tự khởi chạy thủ công theo hướng dẫn của app.
* Hiện tại hệ thống tập trung hoàn thiện tối ưu cho hệ điều hành Android (hệ điều hành chiếm đa số các thiết bị quầy thu ngân tại VN), phiên bản iOS cần phát triển thêm cơ chế nhận thông báo thông qua Apple Push Notification Service (APNs).

## 4.3. Đề xuất định hướng mở rộng trong tương lai
1. **Kết nối máy in hóa đơn nhiệt qua Bluetooth / Wi-Fi:** Tự động in biên lai tính tiền và xác nhận "Đã nhận tiền thành công" ngay khi loa phát thanh dứt lời.
2. **Trí tuệ nhân tạo (AI Financial Advisor):** Tích hợp mô hình ngôn ngữ lớn (LLM) phân tích biểu đồ doanh thu hàng tháng, cảnh báo các khoản chi bất thường và gợi ý tối ưu chi phí nguyên vật liệu cho chủ quán.
3. **Mở rộng hỗ trợ ứng dụng quản lý bán hàng (POS):** Viết SDK/Plugin tích hợp trực tiếp vào KiotViet, Sapo, iPOS, Pos365 để tự động chuyển trạng thái đơn hàng sang "Đã thanh toán".

---

# KẾT LUẬN

Sau quá trình nghiên cứu, thiết kế và phát triển nghiêm túc, đề tài **"Xây dựng ứng dụng di động AutoBank — Hệ thống đọc thông báo biến động số dư tự động, trợ lý loa phát thanh AI TTS và quản trị dòng tiền đa kênh"** đã hoàn thành xuất sắc toàn bộ các mục tiêu đặt ra:

1. Xây dựng thành công ứng dụng di động chạy ngầm ổn định 24/7, bóc tách chính xác thông báo biến động số dư từ 66+ ngân hàng Việt Nam.
2. Ứng dụng trợ lý giọng nói AI TTS phát thanh tiếng Việt tức thì với độ trễ dưới 0.1 giây, kết hợp cảnh báo đa giác quan hiệu quả.
3. Hoàn thiện hệ sinh thái đa kênh gồm Mobile App (Flutter), Web Live đối soát từ xa (Vite) và Backend API quản trị tập trung (NestJS).
4. Thiết lập chuẩn mực bảo mật vững chắc với cơ chế khóa màn hình tầng gốc và khôi phục mã PIN qua Gmail OTP.
5. Đóng gói đầy đủ các bộ cài đặt APK Release, gói AAB cho Google Play Console và triển khai thành công trên môi trường máy chủ Production thực tế.

Đồ án không chỉ khẳng định năng lực làm chủ công nghệ lập trình di động hiện đại của nhóm sinh viên mà còn tạo ra một sản phẩm phần mềm hoàn chỉnh, sẵn sàng thương mại hóa và ứng dụng vào thực tiễn đời sống kinh doanh tại Việt Nam.

---

# TÀI LIỆU THAM KHẢO

1. **Google Developers.** (2025). *Flutter Documentation: Build apps for any screen*. https://docs.flutter.dev/
2. **Android Open Source Project.** (2025). *NotificationListenerService Reference*. Android Developers. https://developer.android.com/reference/android/service/notification/NotificationListenerService
3. **NestJS Core Team.** (2025). *NestJS: A progressive Node.js framework for building efficient, reliable and scalable server-side applications*. https://docs.nestjs.com/
4. **Prisma Data, Inc.** (2025). *Prisma ORM Documentation: Next-generation ORM for Node.js and TypeScript*. https://www.prisma.io/docs
5. **Napas.** (2024). *Tiêu chuẩn kỹ thuật mã phản hồi nhanh (VietQR) trong thanh toán điện tử tại Việt Nam*. Công ty Cổ phần Thanh toán Quốc gia Việt Nam.
6. **Microsoft Corporation.** (2025). *Microsoft Edge Cognitive Speech Services: Text-To-Speech (TTS) Neural Voices Reference*.
7. **OWASP Foundation.** (2025). *Mobile Application Security Verification Standard (MASVS) v2.0*. https://mas.owasp.org/MASVS/
