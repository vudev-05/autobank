# 🏦 ĐỌC THÔNG BÁO NHẬN TIỀN (AutoBank Ecosystem)

> **Slogan cốt lõi:** *"Tiền vừa sang ~ máy báo vang"*  
> **Giải pháp:** Hệ sinh thái quản lý thanh toán, tự động bắt biến động số dư 66+ ngân hàng & ví điện tử, loa phát thanh tiếng Việt tức thì và đối soát đơn hàng 24/7.

![Platform](https://img.shields.io/badge/Nền_tảng-Android_APK_|_Web_SaaS_|_NestJS_API-0284c7)
![Flutter](https://img.shields.io/badge/Mobile-Flutter_3.x_+_Kotlin_Native-0284c7)
![Backend](https://img.shields.io/badge/Backend-NestJS_12_+_Prisma_ORM-e11d48)
![Database](https://img.shields.io/badge/Database-MySQL_8.0-f59e0b)
![Architecture](https://img.shields.io/badge/Kiến_trúc-Monorepo_Clean_Architecture-10b981)

---

## 📋 MỤC LỤC

1. [Tầm nhìn & Giá trị cốt lõi](#-tầm-nhìn--giá-trị-cốt-lõi)
2. [Chi tiết 12 Chức năng cốt lõi của APK](#-chi-tiết-12-chức-năng-cốt-lõi-của-apk)
3. [Cấu trúc Monorepo hoàn chỉnh](#-cấu-trúc-monorepo-hoàn-chỉnh)
4. [Khởi động nhanh trong 1 Click (Quick Start)](#-khởi-động-nhanh-trong-1-click-quick-start)
5. [Hướng dẫn cài đặt chi tiết từng phân hệ](#-hướng-dẫn-cài-đặt-chi-tiết-từng-phân-hệ)
   - [5.1. Backend API (NestJS + Prisma + MySQL)](#51-backend-api-appsapi)
   - [5.2. Web Portal & Admin Dashboard (Vite)](#52-web-portal--admin-dashboard-appsweb)
   - [5.3. Mobile App (Flutter + Android Native)](#53-mobile-app-appsmobile)
6. [Cổng thanh toán tự động & Kích hoạt bản quyền](#-cổng-thanh-toán-tự-động--kích-hoạt-bản-quyền)
7. [Cam kết bảo mật & Chính sách quyền Android](#-cam-kết-bảo-mật--chính-sách-quyền-android)
8. [Đóng gói phát hành APK Release](#-đóng-gói-phát-hành-apk-release)

---

## 🌟 TẦM NHÌN & GIÁ TRỊ CỐT LÕI

Hệ sinh thái **AutoBank - Đọc thông báo nhận tiền** được thiết kế để giải quyết triệt để 2 bài toán lớn nhất của các chủ quán cà phê, nhà hàng, tiệm tạp hóa và hộ kinh doanh tại Việt Nam: **Chống gian lận làm giả hình ảnh chuyển khoản ("bill ảo")** và **Tự động hóa quản trị dòng tiền 24/7**.

### 5 Nguyên Tắc Vận Hành Độc Bản:
1. **Tuyệt đối an toàn (Zero Credential Risk):** Ứng dụng **không bao giờ yêu cầu mật khẩu ngân hàng, mã OTP hay mã PIN thẻ**. Hoạt động hoàn toàn dựa trên cơ chế lắng nghe thông báo đẩy (push notification) ngoài hệ điều hành Android.
2. **Tốc độ đọc siêu tức thì (0.1 giây):** Khi có biến động số dư, loa lập tức phát thanh tiếng Việt to rõ qua loa máy hoặc loa Bluetooth.
3. **Cảnh báo đa giác quan:** Kết hợp âm thanh TTS Chị Google chuẩn giọng tiếng Việt + Hiệu ứng **viền đèn Neon Strobe Flash** chớp sáng toàn màn hình + Pop-up thông báo số tiền cực lớn.
4. **Vận hành Offline-First:** Xử lý trực tiếp trên thiết bị; ngay cả khi mất mạng internet lên server, app vẫn tự bắt thông báo, phát loa đọc tiền và lưu lịch sử cục bộ.
5. **Hệ sinh thái đồng bộ:** Điện thoại chính nhận tiền, máy tính bảng hoặc PC tại quầy kết nối **Live Web** nghe loa từ xa, Admin Portal quản lý toàn bộ người dùng và doanh số.

---

## 📱 CHI TIẾT 12 CHỨC NĂNG CỐT LÕI CỦA APK

| STT | Tên chức năng | Mô tả chi tiết kỹ thuật |
| :---: | :--- | :--- |
| **1** | **Bắt biến động số dư (Notification Listener)** | Lắng nghe thông báo nền 24/7 từ **66+ ngân hàng & ví điện tử** tại VN (VCB, TCB, MB, ACB, BIDV, MoMo, ZaloPay, Viettel Money...). Regex phân tích chính xác: Số tiền (+/-), Ngân hàng, Người gửi, Nội dung CK, Số tài khoản. Băm **SHA-256 Fingerprint** chống đọc trùng thông báo. |
| **2** | **Trợ lý đọc loa giọng nói (TTS Engine)** | Phát loa giọng Chị Google tự nhiên. Tùy chỉnh tốc độ (0.5x – 2.0x), cao độ (pitch), âm lượng. Hỗ trợ tùy biến mẫu câu đọc, bộ lọc số tiền tối thiểu, tính năng nhắc lại 2 lần và **Chế độ im lặng ban đêm** (hẹn giờ bắt đầu - kết thúc). |
| **3** | **Quản lý giao dịch & Sổ thu chi** | Danh sách biến động số dư theo thời gian thực (tiền vào xanh `+`, tiền ra đỏ `-`). Bộ lọc đa năng theo ngày, tuần, tháng, ngân hàng, loại dòng tiền. Tìm kiếm tức thì theo nội dung chuyển khoản, số tiền, tên người gửi. |
| **4** | **Xuất báo cáo tài chính chuyên nghiệp** | Xuất 3 loại báo cáo (Sổ chi tiết giao dịch, Tổng hợp doanh thu trong ngày, Phân bổ dòng tiền theo ngân hàng). Định dạng **Excel/CSV chuẩn UTF-8 BOM** không lỗi font tiếng Việt, chia sẻ nhanh qua Zalo, Messenger, Telegram. |
| **5** | **Quầy thu ngân thông minh (POS Cashier)** | Tạo mã **VietQR động** chuẩn Napas gán sẵn số tiền và mã đơn. Chế độ thu ngân toàn màn hình, đèn Neon chớp xanh rực rỡ và phát chuông xác nhận tiền về quầy ngay lập tức. |
| **6** | **Bảo mật & Mã PIN an toàn** | Khóa ứng dụng bằng **Mã PIN 4 chữ số** mã hóa cục bộ. Yêu cầu nhập PIN khi xem doanh thu, cài đặt, xuất báo cáo, hoặc khi app resume sau thời gian chờ. |
| **7** | **Tiện ích Live Web & Nghe loa từ xa** | Đồng bộ dữ liệu giao dịch real-time lên giao diện Web Live ([`apps/web/live.html`](file:///c:/Users/ACER/Downloads/auto_bank/apps/web/live.html)). Cho phép nhân viên thu ngân hoặc chủ quán nghe loa và theo dõi tiền về trên máy tính PC/iPad thông qua mã PIN xác thực. |
| **8** | **Thống kê & Quản lý Quỹ (Analytics)** | Biểu đồ doanh thu trực quan theo ngày/tuần/tháng. **Quản lý Quỹ chi tiêu & Hạn mức ngân sách (Budgeting):** Thêm quỹ mới (Tiền nhà, Ăn uống, Tiết kiệm...) kèm 4 cấp độ cảnh báo: Tốt, Cảnh báo, Nguy kịch, Lố hạn mức. |
| **9** | **Kiếm tiền & Affiliate** | Tạo mã giới thiệu riêng cho từng tài khoản. Nhận hoa hồng tự động khi người được giới thiệu mua gói VIP. Theo dõi doanh số, quản lý số dư hoa hồng và gửi yêu cầu rút tiền về tài khoản ngân hàng. |
| **10** | **Bản quyền & Gói cước VIP** | Đăng nhập an toàn bằng tài khoản Google. Hỗ trợ 5 gói cước: Dùng thử (3 ngày), 1 tháng, 3 tháng, 1 năm, Vĩnh viễn (Lifetime). Áp dụng mã giảm giá Coupon và tự động kích hoạt gói sau khi quét VietQR. |
| **11** | **Quản lý quyền & Tối ưu pin** | Kiểm tra trạng thái 3 quyền hệ thống: Đọc thông báo, Bỏ qua tối ưu pin (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`), Hiển thị trên app khác (Overlay). Dẫn trực tiếp vào màn hình cài đặt tự khởi chạy riêng của Xiaomi, Oppo, Samsung, Vivo... |
| **12** | **Trung tâm trợ giúp & CSKH** | Tích hợp video YouTube hướng dẫn cài đặt và cấp quyền từng bước trực tiếp trong modal ứng dụng. Kênh liên hệ hỗ trợ nhanh qua Hotline & Zalo. |

---

## 📁 CẤU TRÚC MONOREPO HOÀN CHỈNH

```text
auto_bank/
├── apps/
│   ├── mobile/                                # ỨNG DỤNG DI ĐỘNG FLUTTER (ANDROID)
│   │   ├── android/                           # Cầu nối Native Kotlin Android
│   │   │   └── app/src/main/kotlin/vn/autobank/autobank_mobile/
│   │   │       ├── MainActivity.kt            # Xử lý quyền hệ thống, Pin, Wakelock
│   │   │       └── NotificationListener.kt    # Service lắng nghe thông báo 24/7
│   │   ├── assets/images/banks/               # Kho 66 logo ngân hàng nội bộ
│   │   ├── lib/                               # Mã nguồn Flutter (Clean Architecture)
│   │   │   ├── core/                          # Tầng lõi: TTS, Security PIN, Theme, Utils
│   │   │   ├── features/
│   │   │   │   ├── affiliate/                 # Tiếp thị liên kết & Hoa hồng
│   │   │   │   ├── analytics/                 # Phân tích doanh thu & Quản lý quỹ
│   │   │   │   ├── auth/                      # Đăng nhập Google & Landing Page
│   │   │   │   ├── home/                      # Dashboard trực quầy & Giả lập test
│   │   │   │   ├── navigation/                # Điều hướng 5 tab & Viền đèn Neon
│   │   │   │   ├── notification_center/       # Trung tâm thông báo nội bộ app
│   │   │   │   ├── notification_listener/     # Dịch vụ bắt thông báo ngân hàng
│   │   │   │   ├── pos/                       # Quầy thu ngân thông minh & VietQR
│   │   │   │   ├── settings/                  # Hướng dẫn cấp quyền & Kết nối Live Web
│   │   │   │   ├── settings_hub/              # Video hướng dẫn YouTube & CSKH
│   │   │   │   ├── subscription/              # Đăng ký & Kích hoạt gói VIP
│   │   │   │   ├── system/                    # Cấu hình thương hiệu, hotline động
│   │   │   │   ├── transactions/              # Lịch sử giao dịch & Đối soát SHA-256
│   │   │   │   └── voice_settings/            # Cài đặt chi tiết giọng đọc loa
│   │   │   └── main.dart                      # Điểm khởi chạy ứng dụng & MultiProvider
│   │   └── pubspec.yaml
│   │
│   ├── api/                                   # MÁY CHỦ BACKEND (NESTJS)
│   │   ├── prisma/
│   │   │   └── schema.prisma                  # Lược đồ CSDL MySQL (Users, Orders, Tx...)
│   │   ├── src/
│   │   │   ├── admin/                         # Quản trị User, Cấu hình, Bắn push
│   │   │   ├── auth/                          # Google OAuth 2.0 & JWT Token
│   │   │   ├── bank-connections/              # Quản lý tài khoản ngân hàng kết nối
│   │   │   ├── mail/                          # Gửi email hóa đơn & thông báo
│   │   │   ├── merchants/                     # Quản lý cửa hàng & nhân viên
│   │   │   ├── orders/                        # Đơn hàng, VietQR & Động cơ đối soát
│   │   │   ├── thueapi/                       # Webhook thanh toán tự động ThueApi.Pro
│   │   │   ├── transactions/                  # Ingestion API nhận giao dịch từ mobile
│   │   │   ├── tts/                           # Engine tổng hợp giọng nói Backend
│   │   │   └── main.ts                        # Entry point NestJS (Port 3000)
│   │   ├── .env.example
│   │   └── package.json
│   │
│   └── web/                                   # CỔNG THÔNG TIN WEB SAAS & ADMIN
│       ├── index.html                         # Landing Page bán gói, test giọng, tải APK
│       ├── live.html                          # Màn hình Live Stream thu ngân nghe loa
│       ├── blog.html / article.html           # Hệ sinh thái 50+ bài viết chuẩn SEO
│       ├── privacy.html                       # Chính sách bảo mật chuẩn Google Play
│       ├── admin/                             # ADMIN DASHBOARD PORTAL
│       │   ├── index.html                     # Thống kê tổng quan & Chart.js
│       │   ├── users.html                     # Quản lý người dùng, gia hạn VIP
│       │   ├── orders.html                    # Danh sách đơn hàng & duyệt VietQR
│       │   ├── config.html                    # Cấu hình giá gói, hotline, video
│       │   ├── coupons.html                   # Quản lý mã giảm giá
│       │   ├── banks.html                     # Quản lý danh mục 66 ngân hàng
│       │   ├── payment-autobank.html          # Cấu hình cổng ThueApi.Pro
│       │   ├── notifications.html             # Bắn thông báo đẩy đến Mobile App
│       │   └── keys.html                      # API Keys & Webhook bên thứ 3
│       └── vite.config.js
│
├── scripts/                                   # BỘ TOOL TRIỂN KHAI & TỰ ĐỘNG HÓA
│   ├── deploy_full_system.js                  # Triển khai toàn bộ hệ thống lên VPS
│   ├── setup_vps_autobank.js                  # Thiết lập môi trường VPS ban đầu
│   ├── upload_apk.js                          # Upload file APK mới lên server tải
│   ├── generate_seo_articles.js               # Tool tự động sinh bài viết SEO
│   └── generate_favicons.ps1                  # Tool sinh bộ icon/banner đa kích thước
│
├── start_all.bat                              # File 1-Click khởi động toàn bộ dịch vụ local
├── package.json                               # Cấu hình Monorepo root workspaces
├── DANH_SACH_CHUC_NANG_APK.txt                # Danh mục 12 chức năng ứng dụng
└── DocThongBaoNhanTien_Release_v1.0.3.apk     # Bộ cài đặt APK phát hành mới nhất
```

---

## ⚡ KHỞI ĐỘNG NHANH TRONG 1 CLICK (QUICK START)

Trên Windows, bạn chỉ cần nhấp đúp vào file [`start_all.bat`](file:///c:/Users/ACER/Downloads/auto_bank/start_all.bat) ở thư mục gốc:

```cmd
start_all.bat
```

Hệ thống sẽ tự động mở 3 cửa sổ dịch vụ và trình duyệt web:
* 🌐 **Web Landing Page & Admin:** `http://localhost:5173` (Admin: `/admin`)
* 🔊 **Màn hình Live Stream nghe loa:** `http://localhost:5173/live`
* 📱 **Giả lập Mobile App Preview:** `http://localhost:8080`
* ⚡ **Backend API Server:** `http://localhost:3000`

---

## 🛠️ HƯỚNG DẪN CÀI ĐẶT CHI TIẾT TỪNG PHÂN HỆ

### 5.1. Backend API (`apps/api`)
```bash
# 1. Chuyển vào thư mục api
cd apps/api

# 2. Tạo file cấu hình môi trường từ mẫu
cp .env.example .env

# 3. Chỉnh sửa DATABASE_URL trong .env trỏ đến MySQL của bạn:
# DATABASE_URL="mysql://root:password@localhost:3306/autobank"

# 4. Sinh Prisma Client và migrate database
npx prisma generate
npx prisma db push

# 5. Khởi động Backend API ở chế độ dev
npm run start:dev
```

### 5.2. Web Portal & Admin Dashboard (`apps/web`)
```bash
# 1. Chuyển vào thư mục web
cd apps/web

# 2. Cài đặt dependencies (nếu chạy riêng lẻ)
npm install

# 3. Khởi động máy chủ phát triển Vite
npm run dev
```

### 5.3. Mobile App (`apps/mobile`)
```bash
# 1. Chuyển vào thư mục mobile
cd apps/mobile

# 2. Tải các package Flutter
flutter pub get

# 3. Chạy ứng dụng trên thiết bị Android thật (bật USB Debugging):
flutter run -d android

# Hoặc chạy kiểm thử nhanh trên nền web:
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```

---

## 💳 CỔNG THANH TOÁN TỰ ĐỘNG & KÍCH HOẠT BẢN QUYỀN

AutoBank tích hợp sẵn cơ chế kích hoạt gói bản quyền 24/7 hoàn toàn tự động:
1. Người dùng chọn gói cước trên App hoặc Web (1 tháng, 3 tháng, 1 năm, Vĩnh viễn).
2. Hệ thống sinh mã **VietQR động** chứa số tiền chính xác và nội dung đơn hàng (Ví dụ: `DH1024`).
3. Khách hàng quét mã chuyển khoản qua bất kỳ app ngân hàng nào.
4. Cổng thanh toán tự động (**ThueApi.Pro**) nhận biến động và gửi Webhook về Backend API.
5. Động cơ đối soát (`Reconciliation Engine`) so khớp mã đơn và số tiền:
   - **Đúng số tiền & đúng mã đơn:** Tự động chuyển trạng thái `PAID` và gia hạn gói trên tài khoản Google của khách ngay tức khắc.
   - Bắn thông báo chúc mừng về thiết bị di động.

---

## 🔒 CAM KẾT BẢO MẬT & CHÍNH SÁCH QUYỀN ANDROID

* **Không yêu cầu mật khẩu:** Ứng dụng hoạt động theo cơ chế thụ động thông qua `NotificationListenerService`. Không có bất kỳ dòng code nào yêu cầu người dùng nhập thông tin đăng nhập ngân hàng.
* **Mã hóa cục bộ:** Mã PIN bảo mật 4 chữ số được băm và lưu trữ bằng `SharedPreferences` bảo vệ bởi sandbox hệ điều hành Android.
* **Chống trùng lặp:** Toàn bộ thông báo được kiểm tra qua thuật toán băm SHA-256 fingerprint trên RAM trước khi kích hoạt âm thanh đọc tiền.

---

## 📦 ĐÓNG GÓI PHÁT HÀNH APK RELEASE

Để tạo bản cài đặt APK chuẩn phát hành cho khách hàng:

```bash
cd apps/mobile
flutter build apk --release --split-per-abi
# Hoặc tạo file APK fat universal duy nhất:
flutter build apk --release
```

File cài đặt APK đầu ra sẽ nằm tại:  
`apps/mobile/build/app/outputs/flutter-apk/app-release.apk`

---

*Hệ thống được phát triển và vận hành bởi AutoBank Ecosystem — 2026.*
