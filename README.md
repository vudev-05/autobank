# 🏦 AutoBank PRO

> **Nền tảng quản lý thanh toán tự động** — Hệ thống Monorepo tích hợp Backend NestJS + Landing Page Web + App Mobile Flutter, hỗ trợ đối soát giao dịch ngân hàng theo thời gian thực qua ThueAPI.Pro và VietQR.

![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Mobile%20%7C%20API-blue)
![NestJS](https://img.shields.io/badge/NestJS-v10-red)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![MySQL](https://img.shields.io/badge/Database-MySQL%208.0-orange)
![License](https://img.shields.io/badge/License-Private-red)

---

## 📋 Mục lục

1. [Tổng quan hệ thống](#-tổng-quan-hệ-thống)
2. [Cấu trúc Monorepo](#-cấu-trúc-monorepo)
3. [Yêu cầu môi trường](#-yêu-cầu-môi-trường)
4. [Hướng dẫn cài đặt LOCAL](#-hướng-dẫn-cài-đặt-local)
   - [Bước 1: Clone dự án](#bước-1-clone-dự-án)
   - [Bước 2: Cài đặt MySQL & tạo Database](#bước-2-cài-đặt-mysql--tạo-database)
   - [Bước 3: Cấu hình biến môi trường](#bước-3-cấu-hình-biến-môi-trường)
   - [Bước 4: Cài đặt & khởi động Backend API](#bước-4-cài-đặt--khởi-động-backend-api)
   - [Bước 5: Cài đặt & khởi động Web Dashboard](#bước-5-cài-đặt--khởi-động-web-dashboard)
   - [Bước 6: Cài đặt & chạy App Mobile Flutter](#bước-6-cài-đặt--chạy-app-mobile-flutter)
5. [Cấu hình Admin Dashboard](#-cấu-hình-admin-dashboard)
6. [Tích hợp ThueAPI.Pro](#-tích-hợp-thueapipro)
7. [Tích hợp Google OAuth 2.0](#-tích-hợp-google-oauth-20)
8. [Deploy lên Production](#-deploy-lên-production)
9. [Tài khoản mặc định](#-tài-khoản-mặc-định)
10. [Câu hỏi thường gặp](#-câu-hỏi-thường-gặp)

---

## 🌟 Tổng quan hệ thống

AutoBank PRO là một hệ thống **tự động hóa thanh toán và đối soát giao dịch ngân hàng** hoạt động như sau:

```
Khách hàng mua gói ──► Quét VietQR ──► Chuyển khoản ngân hàng
         │
         ▼
ThueAPI.Pro nhận webhook ──► NestJS API xác thực ──► Kích hoạt bản quyền tự động
         │
         ▼
App Flutter nhận thông báo ──► Merchant quản lý qua Admin Dashboard
```

### Tính năng chính:
- ✅ **Tự động đối soát** giao dịch ngân hàng qua ThueAPI.Pro
- ✅ **Admin Dashboard** quản lý đơn hàng, người dùng, cấu hình hệ thống
- ✅ **Landing Page** bán gói dịch vụ với VietQR thanh toán
- ✅ **App Mobile Flutter** cho merchant xem thống kê, nhận thông báo
- ✅ **Google OAuth 2.0** đăng nhập bằng tài khoản Google
- ✅ **FCM Push Notification** thông báo giao dịch real-time
- ✅ **SMTP Email** gửi xác nhận đơn hàng tự động

---

## 📁 Cấu trúc Monorepo

```
autobank/
├── apps/
│   ├── api/                    # Backend NestJS (Port 3000)
│   │   ├── src/
│   │   │   ├── admin/          # Module quản trị
│   │   │   ├── auth/           # Xác thực JWT & Google OAuth
│   │   │   ├── orders/         # Quản lý đơn hàng
│   │   │   ├── thueapi/        # Tích hợp ThueAPI.Pro
│   │   │   ├── tts/            # Text-to-speech notification
│   │   │   └── users/          # Quản lý người dùng
│   │   ├── prisma/
│   │   │   └── schema.prisma   # Schema MySQL (Prisma ORM)
│   │   ├── .env.example        # Template biến môi trường
│   │   └── package.json
│   │
│   ├── web/                    # Landing Page + Admin (Vite, Port 5173)
│   │   ├── admin/              # Các trang HTML admin
│   │   ├── assets/
│   │   │   ├── css/            # Stylesheets
│   │   │   └── js/             # JavaScript modules
│   │   └── vite.config.js
│   │
│   └── mobile/                 # App Flutter (Android/iOS/Web)
│       ├── lib/
│       │   ├── features/       # Các tính năng theo module
│       │   └── main.dart       # Entry point
│       └── pubspec.yaml
│
├── docs/                       # Tài liệu bổ sung
├── packages/                   # Shared packages
├── GOOGLE_OAUTH_SETUP.md       # Hướng dẫn thiết lập Google OAuth
├── THUEAPI_INTEGRATION_GUIDE.md
└── package.json                # Monorepo root config
```

---

## 🔧 Yêu cầu môi trường

Đảm bảo máy tính đã cài đặt đầy đủ các công cụ sau trước khi bắt đầu:

| Công cụ | Phiên bản tối thiểu | Tải về |
|---------|-------------------|--------|
| **Node.js** | v18.x trở lên | [nodejs.org](https://nodejs.org) |
| **npm** | v9.x trở lên | (đi kèm Node.js) |
| **MySQL** | 8.0 trở lên | [mysql.com](https://dev.mysql.com/downloads/) |
| **Flutter SDK** | 3.x trở lên | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| **Git** | 2.x trở lên | [git-scm.com](https://git-scm.com) |
| **Android Studio** | Bất kỳ | [developer.android.com](https://developer.android.com/studio) |

> ⚠️ **Quan trọng**: Kiểm tra bằng lệnh `node -v`, `flutter --version`, `mysql --version` trước khi tiếp tục.

---

## 🚀 Hướng dẫn cài đặt LOCAL

### Bước 1: Clone dự án

```bash
git clone https://github.com/vudev-05/autobank.git
cd autobank
```

---

### Bước 2: Cài đặt MySQL & tạo Database

#### 2.1 Khởi động MySQL Server
- **Windows**: Mở Services → tìm `MySQL80` → Start
- **macOS**: `brew services start mysql`
- **Linux**: `sudo systemctl start mysql`

#### 2.2 Đăng nhập và tạo Database

```sql
-- Đăng nhập MySQL
mysql -u root -p

-- Tạo database cho dự án
CREATE DATABASE autobank CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Tạo user riêng (khuyến nghị, không dùng root)
CREATE USER 'autobank_user'@'localhost' IDENTIFIED BY 'your_strong_password';
GRANT ALL PRIVILEGES ON autobank.* TO 'autobank_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

#### 2.3 Ghi lại thông tin kết nối
```
Host:     localhost
Port:     3306
Database: autobank
Username: autobank_user   (hoặc root)
Password: your_strong_password
```

---

### Bước 3: Cấu hình biến môi trường

#### 3.1 Tạo file `.env` cho Backend API

```bash
# Vào thư mục API
cd apps/api

# Sao chép file mẫu
copy .env.example .env        # Windows
cp .env.example .env          # macOS/Linux
```

#### 3.2 Chỉnh sửa file `apps/api/.env`

Mở file `.env` và điền thông tin thực tế:

```env
# ==============================================================
# AUTOBANK PRO - CẤU HÌNH MÔI TRƯỜNG
# ==============================================================

# 1. CẤU HÌNH SERVER & DATABASE
PORT=3000
DATABASE_URL="mysql://autobank_user:your_strong_password@localhost:3306/autobank?connection_limit=20"
APP_URL="http://localhost:5173"

# 2. KHÓA BẢO MẬT (Bắt buộc đổi thành chuỗi ngẫu nhiên ≥ 32 ký tự)
JWT_SECRET="thay_bang_chuoi_ngau_nhien_rat_dai_va_phuc_tap_hon_32_ki_tu"
ADMIN_USERNAME=admin
ADMIN_PASSWORD=autobank@2026

# 3. GOOGLE OAUTH 2.0 (xem GOOGLE_OAUTH_SETUP.md để lấy key)
GOOGLE_CLIENT_ID="your_google_client_id.apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET="your_google_client_secret"

# 4. THUEAPI.PRO (đăng ký tại https://thueapi.pro/)
THUEAPI_ENABLED=true
THUEAPI_API_KEY="api_key_lay_tu_thueapi_pro"
THUEAPI_BANK_ACC="so_tai_khoan_ngan_hang"
THUEAPI_BANK_CODE="MB"   # MB / VCB / TCB / ACB / ...

# 5. FIREBASE FCM (tùy chọn)
FCM_SERVER_KEY=""

# 6. SMTP EMAIL (tùy chọn, dùng Gmail App Password)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="email@gmail.com"
SMTP_PASS="app_password_16_ki_tu"
SMTP_FROM="AutoBank PRO <email@gmail.com>"
```

> 💡 **Tạo JWT_SECRET ngẫu nhiên**: Chạy lệnh `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"` và dán kết quả vào.

---

### Bước 4: Cài đặt & khởi động Backend API

```bash
# Đảm bảo bạn đang ở thư mục gốc của dự án
cd apps/api

# Cài đặt dependencies
npm install

# Chạy Prisma migration (tạo tất cả bảng trong MySQL)
npx prisma migrate deploy

# Hoặc nếu là lần đầu (development):
npx prisma db push

# Xem giao diện quản lý DB (tùy chọn)
npx prisma studio

# Khởi động server ở chế độ Development (hot-reload)
npm run start:dev
```

✅ **Kiểm tra thành công**: Mở trình duyệt → `http://localhost:3000` → thấy phản hồi JSON.

**Các API endpoint quan trọng:**
```
GET  http://localhost:3000/admin/configs      # Lấy cấu hình hệ thống
POST http://localhost:3000/auth/login         # Đăng nhập admin
POST http://localhost:3000/webhooks/thueapi   # Webhook nhận giao dịch
GET  http://localhost:3000/admin/orders       # Danh sách đơn hàng
```

---

### Bước 5: Cài đặt & khởi động Web Dashboard

> Mở **terminal mới** (không đóng terminal API)

```bash
# Vào thư mục web
cd apps/web

# Cài đặt dependencies
npm install

# Khởi động Vite dev server
npm run dev
```

✅ **Kiểm tra thành công**: Mở trình duyệt:
- **Landing Page**: `http://localhost:5173/`
- **Admin Dashboard**: `http://localhost:5173/admin/`

---

### Bước 6: Cài đặt & chạy App Mobile Flutter

> Mở **terminal thứ 3**

```bash
# Vào thư mục mobile
cd apps/mobile

# Tải packages Flutter
flutter pub get

# Kiểm tra thiết bị kết nối
flutter devices

# ── Chạy trên Emulator / Thiết bị Android ──
flutter run

# ── Chạy trên Web Browser (để test nhanh) ──
flutter run -d web-server --web-port=8088 --web-hostname=localhost

# ── Build APK để cài lên điện thoại ──
flutter build apk --release
```

> ⚠️ Đảm bảo đã mở **Android Emulator** hoặc cắm điện thoại và bật **USB Debugging**.

---

## ⚙️ Cấu hình Admin Dashboard

Sau khi hệ thống chạy, truy cập Admin để thiết lập:

### 1. Đăng nhập Admin
```
URL:      http://localhost:5173/admin/
Username: admin
Password: autobank@2026
```

### 2. Cấu hình Thanh toán AutoBank
```
Menu: Admin → Thanh toán AutoBank
```
Điền thông tin tài khoản ngân hàng nhận tiền:
- **Số tài khoản**: Số TK ngân hàng của bạn
- **Ngân hàng**: Chọn mã ngân hàng (MB, VCB, TCB...)
- **Tên chủ tài khoản**: Tên thật trên tài khoản
- **API Key ThueAPI**: Lấy từ dashboard [thueapi.pro](https://thueapi.pro)

### 3. Cấu hình Webhook ThueAPI
```
URL Webhook: http://your-server.com/webhooks/thueapi
```
Dán URL này vào phần cấu hình webhook trên website ThueAPI.Pro.

---

## 🔑 Tích hợp ThueAPI.Pro

ThueAPI.Pro là dịch vụ đọc biến động số dư tài khoản ngân hàng tự động.

### Bước thiết lập:

1. **Đăng ký tài khoản** tại [https://thueapi.pro/](https://thueapi.pro/)
2. **Kết nối tài khoản ngân hàng** theo hướng dẫn trên web
3. **Lấy API Key** từ Dashboard
4. **Cấu hình Webhook URL**:
   - Development: Dùng [ngrok](https://ngrok.com) để tạo URL public
     ```bash
     ngrok http 3000
     # Copy URL dạng: https://xxxx.ngrok-free.app
     # Webhook URL: https://xxxx.ngrok-free.app/webhooks/thueapi
     ```
   - Production: `https://your-domain.com/webhooks/thueapi`
5. **Nhập API Key** vào Admin Dashboard → Thanh toán AutoBank

> 📖 Xem chi tiết: [THUEAPI_INTEGRATION_GUIDE.md](./THUEAPI_INTEGRATION_GUIDE.md)

---

## 🔐 Tích hợp Google OAuth 2.0

Cho phép người dùng đăng nhập bằng tài khoản Google.

### Bước thiết lập:

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo Project mới hoặc chọn project có sẵn
3. Vào **APIs & Services → Credentials**
4. Tạo **OAuth 2.0 Client ID** (loại: Web application)
5. Thêm **Authorized redirect URIs**:
   ```
   http://localhost:3000/auth/google/callback
   https://your-domain.com/auth/google/callback
   ```
6. Sao chép `Client ID` và `Client Secret` vào file `.env`

> 📖 Xem chi tiết: [GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md)

---

## 🌐 Deploy lên Production

### Yêu cầu server:
- VPS/Server Linux (Ubuntu 20.04+ khuyến nghị)
- RAM: Tối thiểu 1GB (khuyến nghị 2GB)
- CPU: 1 vCPU trở lên
- MySQL 8.0 đã cài sẵn
- Domain đã trỏ về IP server

### Các bước deploy:

#### 1. Cài đặt Node.js & PM2

```bash
# Cài Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Cài PM2 để quản lý process
npm install -g pm2
```

#### 2. Clone & cấu hình

```bash
git clone https://github.com/vudev-05/autobank.git
cd autobank/apps/api
cp .env.example .env
nano .env   # Điền thông tin production
```

#### 3. Build và chạy Backend API

```bash
cd apps/api
npm install
npx prisma migrate deploy
npm run build

# Chạy với PM2
pm2 start dist/main.js --name "autobank-api"
pm2 save
pm2 startup
```

#### 4. Build Web

```bash
cd apps/web
npm install
npm run build
# Thư mục dist/ chứa các file tĩnh → upload lên Nginx/Apache
```

#### 5. Cấu hình Nginx

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Landing Page & Admin Web
    location / {
        root /path/to/autobank/apps/web/dist;
        try_files $uri $uri/ /index.html;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Webhook endpoint
    location /webhooks/ {
        proxy_pass http://localhost:3000/webhooks/;
    }
}
```

#### 6. Cài SSL (HTTPS) miễn phí

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

---

## 👤 Tài khoản mặc định

| Vai trò | Username | Password | Ghi chú |
|---------|----------|----------|---------|
| **Admin** | `admin` | `autobank@2026` | ⚠️ Đổi ngay sau khi cài đặt |

> 🔒 **Bắt buộc** thay đổi mật khẩu Admin và `JWT_SECRET` trước khi deploy production!

---

## ❓ Câu hỏi thường gặp

### Q: Lỗi `Cannot connect to database`
**A:** Kiểm tra:
1. MySQL đang chạy chưa: `mysql -u root -p`
2. Thông tin `DATABASE_URL` trong `.env` có đúng không
3. Database `autobank` đã được tạo chưa

### Q: Lỗi `Prisma migrate` thất bại
**A:** Thử chạy: `npx prisma db push --force-reset` (⚠️ sẽ xóa toàn bộ dữ liệu)

### Q: App Flutter không kết nối được API
**A:** Kiểm tra `BASE_URL` trong `apps/mobile/lib/core/constants/api_constants.dart`. Khi chạy emulator Android, dùng `http://10.0.2.2:3000` thay vì `localhost`.

### Q: Webhook ThueAPI không nhận được
**A:** 
1. Server phải có IP/domain public (không dùng localhost)
2. Dùng ngrok để test: `ngrok http 3000`
3. Kiểm tra log: `pm2 logs autobank-api`

### Q: Google OAuth lỗi `redirect_uri_mismatch`
**A:** Thêm đúng URL callback vào Google Cloud Console. Xem [GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md)

---

## 📞 Liên hệ & Hỗ trợ

- **GitHub Issues**: [github.com/vudev-05/autobank/issues](https://github.com/vudev-05/autobank/issues)
- **Tài liệu kiến trúc**: [TONG_QUAN_VA_KIEN_TRUC_DU_AN.md](./TONG_QUAN_VA_KIEN_TRUC_DU_AN.md)

---

<div align="center">
  <strong>AutoBank PRO</strong> — Được phát triển với ❤️ bởi vudev-05
</div>
