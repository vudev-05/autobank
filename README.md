# 🏦 ĐỌC THÔNG BÁO NHẬN TIỀN (AutoBank Ecosystem)
### 🚀 Bản Cập Nhật Toàn Diện: Ngày 24/10/2026 (Phiên bản v1.0.3 · Build 4)

> **Slogan cốt lõi:** *"Tiền vừa sang ~ máy báo vang"*  
> **Giải pháp:** Hệ sinh thái quản lý thanh toán, tự động bắt biến động số dư 66+ ngân hàng & ví điện tử Việt Nam, trợ lý phát loa giọng nói AI tiếng Việt tức thì, đối soát đơn hàng thông minh và chia sẻ biến động số dư Live Web 24/7.

![Platform](https://img.shields.io/badge/Nền_tảng-Android_APK_|_Google_Play_AAB_|_Web_SaaS_|_NestJS_API-0284c7)
![Flutter](https://img.shields.io/badge/Mobile-Flutter_3.x_+_Kotlin_Native-0284c7)
![Backend](https://img.shields.io/badge/Backend-NestJS_12_+_Prisma_ORM-e11d48)
![Database](https://img.shields.io/badge/Database-MySQL_8.0-f59e0b)
![Version](https://img.shields.io/badge/Release-v1.0.3_(24/10/2026)-10b981)
![Security](https://img.shields.io/badge/Security-Root_Screen_Lock_+_Email_OTP-purple)

---

## 📋 MỤC LỤC

1. [Điểm mới nổi bật trong Bản cập nhật 24/10/2026](#-điểm-mới-nổi-bật-trong-bản-cập-nhật-24102026)
2. [Tầm nhìn & Giá trị cốt lõi](#-tầm-nhìn--giá-trị-cốt-lõi)
3. [Chi tiết 14 Chức năng cốt lõi của Hệ thống](#-chi-tiết-14-chức-năng-cốt-lõi-của-hệ-thống)
4. [Cấu trúc Monorepo hoàn chỉnh](#-cấu-trúc-monorepo-hoàn-chỉnh)
5. [Bộ cài đặt & Phát hành (APK & Google Play AAB)](#-bộ-cài-đặt--phát-hành-apk--google-play-aab)
6. [Hướng dẫn cài đặt & Chạy Local](#-hướng-dẫn-cài-đặt--chạy-local)
   - [6.1. Backend API (NestJS + Prisma + MySQL)](#61-backend-api-appsapi)
   - [6.2. Web Portal & Admin Dashboard (Vite)](#62-web-portal--admin-dashboard-appsweb)
   - [6.3. Mobile App (Flutter + Android Native)](#63-mobile-app-appsmobile)
7. [Triển khai hệ thống lên VPS Production](#-triển-khai-hệ-thống-lên-vps-production)
8. [Cam kết bảo mật & Quyền riêng tư](#-cam-kết-bảo-mật--quyền-riêng-tư)

---

## 🌟 ĐIỂM MỚI NỔI BẬT TRONG BẢN CẬP NHẬT 24/10/2026

* 🛡️ **Bảo mật mã PIN tầng gốc (Root Screen Lock):**
  - Chuyển đổi toàn bộ màn hình khóa PIN thành lớp bao phủ Root Widget (`AppLockScreenOverlay`). Khi chưa mở khóa, toàn bộ màn hình app bên dưới hoàn toàn **không được dựng (không render)**.
  - Ngăn chặn 100% việc lọt vào ứng dụng khi bấm nút Back (`PopScope(canPop: false)`) hoặc khi bấm "Quên mã PIN".
  - **Loại bỏ hoàn toàn Master PIN / Mã cứu hộ dự phòng:** Đã gỡ bỏ toàn bộ mã mặc định `1234`/`8888`. Chỉ duy nhất mã PIN chính xác của người dùng mới có thể mở app.
* 📧 **Cấp lại mã PIN bằng mã OTP 6 số qua Email:**
  - Tích hợp dịch vụ gửi mail qua SMTP Gmail chính chủ (`tranquocvu3011@gmail.com`).
  - Khi quên mã, người dùng nhận mã xác thực OTP 6 số qua hộp thư Gmail trong vòng 10 phút để thiết lập mã PIN mới an toàn ngay trên màn hình khóa.
* 🎥 **Hệ thống 5 Video Hướng Dẫn YouTube Tự Động:**
  - **Video 1 (Người mới):** Hướng dẫn mở đầu khi vừa vào app (`videoGuideNewbie`).
  - **Video 2 (Chạy mượt):** Hướng dẫn cấp quyền chạy ngầm 24/7 không bị tắt (`videoGuideSmooth`).
  - **Video 3 (Đọc lại):** Hướng dẫn tra cứu và nghe lại lịch sử giao dịch tại Tab Báo Cáo (`videoGuideHistory`).
  - **Video 4 (Cá nhân hóa câu đọc):** Hướng dẫn tùy biến mẫu câu đọc tiền tại Tab Câu Đọc (`videoGuideVoice`).
  - **Video 5 (Giới thiệu bạn bè):** Hướng dẫn kiếm tiền hoa hồng Affiliate (`videoGuideAffiliate`).
  - Tất cả popup video đều tích hợp trình phát YouTube mượt mà, có nút **"Đóng"** và nút tích **"Không hiển thị lại"** ghi nhớ vĩnh viễn.
* 📦 **Đóng gói phát hành v1.0.3 (Build 4):**
  - Biên dịch bản **APK Release siêu nhẹ (64.0 MB)** cài đặt trực tiếp.
  - Biên dịch bản **Android App Bundle (.aab)** ký chính thức bằng Keystore phát hành (`autobank-release.jks`), đáp ứng Target SDK 36 sẵn sàng tải lên **Google Play Console** làm bản Test/Phát hành.
  - Cung cấp công cụ 1-click cài đặt vào điện thoại qua USB: [`install_apk_to_phone.bat`](install_apk_to_phone.bat).

---

## 💡 TẦM NHÌN & GIÁ TRỊ CỐT LÕI

Hệ sinh thái **AutoBank - Đọc thông báo nhận tiền** được thiết kế để giải quyết triệt để 2 bài toán lớn nhất của các chủ quán cà phê, nhà hàng, tiệm tạp hóa và hộ kinh doanh tại Việt Nam: **Chống gian lận làm giả hình ảnh chuyển khoản ("bill ảo")** và **Tự động hóa quản trị dòng tiền 24/7**.

### 5 Nguyên Tắc Vận Hành Độc Bản:
1. **Tuyệt đối an toàn (Zero Credential Risk):** Ứng dụng **không bao giờ yêu cầu mật khẩu ngân hàng, mã OTP hay mã PIN thẻ**. Hoạt động hoàn toàn dựa trên cơ chế lắng nghe thông báo đẩy (push notification) ngoài hệ điều hành Android.
2. **Tốc độ đọc siêu tức thì (0.1 giây):** Khi có biến động số dư, loa lập tức phát thanh tiếng Việt to rõ qua loa máy hoặc loa Bluetooth ngoài.
3. **Cảnh báo đa giác quan:** Kết hợp âm thanh TTS Chị Google chuẩn giọng tiếng Việt + Hiệu ứng **viền đèn Neon Strobe Flash** chớp sáng toàn màn hình + Pop-up thông báo số tiền cực lớn.
4. **Vận hành Offline-First:** Xử lý trực tiếp trên thiết bị; ngay cả khi mất mạng internet lên server, app vẫn tự bắt thông báo, phát loa đọc tiền và lưu lịch sử cục bộ.
5. **Hệ sinh thái đồng bộ:** Điện thoại chính nhận tiền, máy tính bảng hoặc PC tại quầy kết nối **Live Web** nghe loa từ xa, Admin Portal quản lý toàn bộ người dùng và doanh số.

---

## 📱 CHI TIẾT 14 CHỨC NĂNG CỐT LÕI CỦA HỆ THỐNG

| STT | Tên chức năng | Mô tả chi tiết kỹ thuật |
| :---: | :--- | :--- |
| **1** | **Bắt biến động số dư (Notification Listener)** | Lắng nghe thông báo nền 24/7 từ **66+ ngân hàng & ví điện tử** tại VN (VCB, TCB, MB, ACB, BIDV, MoMo, ZaloPay, Viettel Money...). Regex phân tích chính xác: Số tiền (+/-), Ngân hàng, Người gửi, Nội dung CK, Số tài khoản. Băm **SHA-256 Fingerprint** chống đọc trùng thông báo. |
| **2** | **Trợ lý đọc loa giọng nói (TTS Engine)** | Phát loa giọng Chị Google tự nhiên. Tùy chỉnh tốc độ (0.5x – 2.0x), cao độ (pitch), âm lượng. Hỗ trợ 26 giọng đọc AI vùng miền tiếng Việt (Bắc, Trung, Nam, Chị Google, Loa Siêu Thị). |
| **3** | **Cá nhân hóa câu đọc nhận tiền** | Tùy biến mẫu câu đọc tiền linh hoạt (Dạng siêu ngắn, Dạng chi tiết đối soát, Dạng kéo thả khối thành phần). Tích hợp video hướng dẫn trực quan tại Tab Câu Đọc. |
| **4** | **Quản lý giao dịch & Sổ thu chi** | Danh sách biến động số dư theo thời gian thực (tiền vào xanh `+`, tiền ra đỏ `-`). Bộ lọc đa năng theo ngày, tuần, tháng, ngân hàng, loại dòng tiền. Tìm kiếm tức thì theo nội dung chuyển khoản, số tiền, tên người gửi. |
| **5** | **Trang Đọc Lại (Tra cứu & Nghe lại)** | Cho phép nghe lại âm thanh đọc tiền của từng giao dịch bất cứ lúc nào, hỗ trợ tra cứu đối soát khi khách hàng thắc mắc. Có video hướng dẫn sử dụng riêng. |
| **6** | **Xuất báo cáo tài chính chuyên nghiệp** | Xuất 3 loại báo cáo (Sổ chi tiết giao dịch, Tổng hợp doanh thu trong ngày, Phân bổ dòng tiền theo ngân hàng). Định dạng **Excel/CSV chuẩn UTF-8 BOM** không lỗi font tiếng Việt, chia sẻ nhanh qua Zalo, Messenger, Telegram. |
| **7** | **Quầy thu ngân thông minh (POS Cashier)** | Tạo mã **VietQR động** chuẩn Napas gán sẵn số tiền và mã đơn. Chế độ thu ngân toàn màn hình, đèn Neon chớp xanh rực rỡ và phát chuông xác nhận tiền về quầy ngay lập tức. |
| **8** | **Bảo mật mã PIN tầng gốc (Root Screen Lock)** | Khóa ứng dụng bằng **Mã PIN 4 chữ số**, bảo vệ tại cấp Root Widget. Chặn phím Back và chống vượt rào. Quy trình cấp lại mã PIN bằng OTP qua Email an toàn khép kín. |
| **9** | **Tiện ích Live Web & Nghe loa từ xa** | Đồng bộ dữ liệu giao dịch real-time lên giao diện Web Live qua mã PIN 6 số. Cho phép nhân viên thu ngân hoặc chủ quán nghe loa và theo dõi tiền về trên máy tính PC/iPad từ xa. |
| **10** | **Thống kê & Quản lý Quỹ (Analytics)** | Biểu đồ doanh thu trực quan theo ngày/tuần/tháng. Quản lý Quỹ chi tiêu & Hạn mức ngân sách (Budgeting) kèm cảnh báo vượt hạn mức thông minh. |
| **11** | **Kiếm tiền & Tiếp thị liên kết (Affiliate)** | Tạo mã giới thiệu riêng cho từng tài khoản. Nhận hoa hồng tự động khi người được giới thiệu mua gói VIP. Quản lý số dư hoa hồng và gửi yêu cầu rút tiền về tài khoản ngân hàng. |
| **12** | **Bản quyền & Gói cước VIP** | Đăng nhập an toàn bằng tài khoản Google. Hỗ trợ 5 gói cước: Dùng thử (3 ngày), 1 tháng, 3 tháng, 1 năm, Vĩnh viễn (Lifetime). Áp dụng mã giảm giá Coupon (`NGUOIMOI`) tự động. |
| **13** | **Quản lý quyền & Tối ưu pin** | Kiểm tra trạng thái 3 quyền hệ thống: Đọc thông báo, Bỏ qua tối ưu pin (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`), Hiển thị trên app khác (Overlay). Hướng dẫn cài đặt riêng cho Xiaomi, Oppo, Samsung, Vivo... |
| **14** | **Trang Quản Trị Admin Toàn Diện** | Quản lý ngân hàng, cấu hình 5 link video YouTube, danh sách khách hàng, nhật ký giao dịch, mã giảm giá, duyệt yêu cầu rút tiền hoa hồng Affiliate. |

---

## 📁 CẤU TRÚC MONOREPO HOÀN CHỈNH

```text
auto_bank/
├── apps/
│   ├── mobile/                                # ỨNG DỤNG DI ĐỘNG FLUTTER (ANDROID)
│   │   ├── android/                           # Cầu nối Native Kotlin Android
│   │   │   └── app/src/main/kotlin/vn/autobank/autobank_mobile/
│   │   │       ├── MainActivity.kt            # Xử lý quyền hệ thống, Pin, Wakelock
│   │   │       └── NotificationListener.kt    # Lắng nghe thông báo ngân hàng 24/7
│   │   ├── lib/
│   │   │   ├── core/
│   │   │   │   ├── security/                  # Màn hình khóa Root Overlay & Dịch vụ PIN
│   │   │   │   ├── tts/                       # Trợ lý đọc loa giọng nói (TTS Engine)
│   │   │   │   └── widgets/                   # Video guide modal, Youtube dialog, Rating
│   │   │   └── features/
│   │   │       ├── home/                      # Trang chủ, Cảnh báo đèn Neon Strobe Flash
│   │   │       ├── transactions/              # Quản lý giao dịch, Regex phân tích thông báo
│   │   │       ├── voice_settings/            # Cài đặt giọng đọc & cá nhân hóa câu đọc
│   │   │       ├── pos/                       # Quầy thu ngân thông minh (POS Cashier)
│   │   │       ├── affiliate/                 # Giới thiệu bạn bè & Kiếm tiền hoa hồng
│   │   │       └── subscription/              # Đăng ký gói cước VIP & Thanh toán VietQR
│   │   └── pubspec.yaml                       # Phiên bản v1.0.3+4
│   │
│   ├── api/                                   # BACKEND API SERVER (NESTJS + PRISMA)
│   │   ├── src/
│   │   │   ├── admin/                         # Quản trị hệ thống, Video YouTube, Doanh thu
│   │   │   ├── auth/                          # Đăng nhập Google, Bảo mật OTP Gmail
│   │   │   ├── mail/                          # Dịch vụ gửi mail SMTP tự động
│   │   │   ├── transactions/                  # Webhook, Xử lý giao dịch, SSE Live Stream
│   │   │   ├── tts/                           # 26 Giọng đọc AI & Mẫu câu đọc thông minh
│   │   │   └── coupons/                       # Mã giảm giá (NGUOIMOI)
│   │   └── prisma/schema.prisma               # Mô hình cơ sở dữ liệu MySQL
│   │
│   └── web/                                   # GIAO DIỆN WEB & ADMIN (VITE + VANILLA JS)
│       ├── admin/                             # Dashboard Quản trị viên
│       │   ├── index.html                     # Thống kê tổng quan & Doanh số
│       │   ├── config.html                    # Cấu hình 5 link video YouTube & Tài khoản
│       │   ├── banks.html                     # Bật/tắt 40+ app ngân hàng
│       │   ├── users.html                     # Quản lý thành viên & Gia hạn gói cước
│       │   └── affiliate.html                 # Quản lý yêu cầu rút tiền hoa hồng
│       ├── live.html                          # Tiện ích Live Web nghe loa từ xa qua PC/iPad
│       └── index.html                         # Trang chủ giới thiệu, Bảng giá & Thanh toán
│
├── release_builds/                            # THƯ MỤC CHỨA CÁC BẢN PHÁT HÀNH
│   ├── AutoBank_v1.0.3_Release.apk            # Bản APK cài đặt trực tiếp (64.0 MB)
│   └── AutoBank_v1.0.3_GooglePlay_Test.aab    # Bản AAB chuẩn Google Play Console (Target SDK 36)
├── install_apk_to_phone.bat                   # Script 1-click cài đặt APK vào điện thoại qua USB
└── README.md                                  # Tài liệu hướng dẫn dự án (24/10/2026)
```

---

## 📦 BỘ CÀI ĐẶT & PHÁT HÀNH (APK & GOOGLE PLAY AAB)

| Tên File | Đường dẫn | Mục đích sử dụng |
| :--- | :--- | :--- |
| **AutoBank_v1.0.3_Release.apk** | [`release_builds/AutoBank_v1.0.3_Release.apk`](release_builds/AutoBank_v1.0.3_Release.apk) | File APK Release chính thức (**64.0 MB**), cài trực tiếp trên mọi điện thoại Android (kèm file chạy nhanh [`install_apk_to_phone.bat`](install_apk_to_phone.bat)). |
| **AutoBank_v1.0.3_GooglePlay_Test.aab** | [`release_builds/AutoBank_v1.0.3_GooglePlay_Test.aab`](release_builds/AutoBank_v1.0.3_GooglePlay_Test.aab) | File Android App Bundle (.aab) ký chính thức bằng Keystore phát hành, Target SDK 36, **dùng để tải lên Google Play Console** (Internal / Closed Testing). |

---

## 💻 HƯỚNG DẪN CÀI ĐẶT & CHẠY LOCAL

### 1. Yêu cầu môi trường:
* **Node.js**: >= 18.x (khuyên dùng Node 20+)
* **Flutter SDK**: >= 3.24.x
* **MySQL Database**: >= 8.0
* **Android SDK**: Build Tools 34+ / Target SDK 36

### 2. Cài đặt các phân hệ:

#### 6.1. Backend API (`apps/api`):
```bash
cd apps/api
npm install
npx prisma generate
npx prisma db push
npm run build
node dist/main.js
# Backend API sẽ chạy tại: http://localhost:3000
```

#### 6.2. Web Portal & Admin Dashboard (`apps/web`):
```bash
cd apps/web
npm install
npm run dev
# Giao diện Web sẽ chạy tại: http://localhost:5173
# Trang Admin: http://localhost:5173/admin (admin / autobank@2026)
```

#### 6.3. Mobile App (`apps/mobile`):
```bash
cd apps/mobile
flutter pub get
# Chạy trên máy ảo Web:
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
# Chạy hoặc cài đặt trực tiếp trên điện thoại Android:
flutter run -d <device_id> --release
```

---

## 🌐 TRIỂN KHAI HỆ THỐNG LÊN VPS PRODUCTION

Hệ thống đã tích hợp sẵn script tự động hóa toàn bộ quá trình triển khai lên VPS Linux:
* **Địa chỉ VPS:** `180.93.59.46`
* **Công nghệ vận hành:** Ubuntu Server, Apache2 Reverse Proxy, Node.js + PM2 Daemon Manager, MariaDB.

**Lệnh triển khai tự động chỉ với 1 bước:**
```bash
node scripts/deploy_production_complete.cjs
```
Script sẽ tự động:
1. Đóng gói giao diện Web Dist mới nhất và đồng bộ vào thư mục Apache `/var/www/autobank/apps/web/dist`.
2. Đồng bộ mã nguồn API, cập nhật cấu hình SMTP Email trong `.env`, chạy migration database.
3. Rebuild Backend API và reload dịch vụ PM2 `autobank-api` mà không làm gián đoạn người dùng.
4. Tải bản APK mới nhất vào link tải trực tiếp trên website.

---

## 🛡️ CAM KẾT BẢO MẬT & QUYỀN RIÊNG TƯ

1. **Tuyệt đối không can thiệp tài khoản ngân hàng:** Ứng dụng chỉ đọc nội dung thông báo hiển thị trên thanh trạng thái do hệ điều hành Android cung cấp, hoàn toàn không truy cập vào tài khoản ngân hàng của bạn.
2. **Bảo mật mã PIN cấp Root:** Giao diện bên trong app hoàn toàn được bảo vệ bởi màn hình khóa tầng gốc, ngăn chặn truy cập trái phép khi người khác cầm vào máy.
3. **Mã hóa dữ liệu:** Thông tin biến động số dư được lưu trữ an toàn bằng SQLite cục bộ trên máy và truyền tải qua giao thức HTTPS/WSS có mã hóa SSL.

---
© 2026 **AutoBank Pro**. Phát triển và vận hành bởi đội ngũ Kỹ sư Hệ thống AutoBank.  
Mã nguồn lưu trữ tại: **https://github.com/vudev-05/autobank.git**
