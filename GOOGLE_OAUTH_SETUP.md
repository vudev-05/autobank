# HƯỚNG DẪN CẤU HÌNH GOOGLE OAUTH 2.0 & ĐĂNG NHẬP GOOGLE
**Dự án:** AutoBank PRO — Đọc thông báo nhận tiền  
**Mục tiêu:** Cấu hình xác thực người dùng thật qua Google Identity Services trên Android và Website.

---

## 1. THÔNG SỐ KỸ THUẬT ỨNG DỤNG ANDROID

- **Tên gói ứng dụng (Android Package Name):** `vn.autobank.autobank_mobile`  
  *(Cần khớp chính xác với `applicationId` trong `apps/mobile/android/app/build.gradle`)*
- **Tên thương hiệu:** Đọc thông báo nhận tiền — AutoBank PRO
- **Email hỗ trợ kỹ thuật:** `tranquocvu3011@gmail.com`

---

## 2. HƯỚNG DẪN LẤY SHA-1 VÀ SHA-256 FINGERPRINT

Mở PowerShell tại thư mục `apps/mobile/android` và chạy lệnh:

### Đối với môi trường Phát triển (Debug Keystore):
```powershell
./gradlew signingReport
```
Hoặc dùng công cụ `keytool` của JDK:
```powershell
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Lưu lại 2 giá trị xuất hiện:
- **SHA-1:** `AA:BB:CC:...`
- **SHA-256:** `11:22:33:...`

### Đối với bản phát hành Production (Release Keystore):
Dùng `keytool` trỏ tới file Keystore phát hành của bạn:
```powershell
keytool -list -v -keystore path/to/your/upload-keystore.jks
```

---

## 3. CÁC BƯỚC THIẾT LẬP TRÊN GOOGLE CLOUD CONSOLE

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/).
2. Chọn hoặc tạo mới dự án: `AutoBank PRO`.
3. Vào **APIs & Services > OAuth consent screen (Màn hình đồng ý OAuth)**:
   - User Type: **External (Bên ngoài)**.
   - App name: **Đọc thông báo nhận tiền — AutoBank PRO**.
   - User support email: Email quản trị của bạn.
   - Scopes (Phạm vi): Thêm `.../auth/userinfo.email`, `.../auth/userinfo.profile`, `openid`.
4. Vào **APIs & Services > Credentials (Thông tin xác thực)**:
   - Nhấn **Create Credentials > OAuth client ID**.
   - **Tạo Client ID thứ nhất (Dành cho Android):**
     * Application type: **Android**.
     * Package name: `vn.autobank.autobank_mobile`.
     * SHA-1 certificate fingerprint: Dán mã SHA-1 vừa lấy ở bước 2.
   - **Tạo Client ID thứ hai (Dành cho Web & Backend Verification):**
     * Application type: **Web application**.
     * Name: `AutoBank PRO Backend Server`.
     * Authorized redirect URIs: `https://your-domain.com/auth/google/callback` hoặc `http://localhost:3000/auth/google/callback`.
     * Lưu lại **Client ID** và **Client Secret**.

---

## 4. CẤU HÌNH VÀO BACKEND AUTOBANK PRO

Mở file `apps/api/.env` và cập nhật:

```env
GOOGLE_CLIENT_ID="123456789012-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET="GOCSPX-your_google_client_secret_here"
JWT_SECRET="mot_chuoi_bi_mat_ngau_nhien_dai_it_nhat_32_ky_tu_2026"
```

Sau khi cấu hình, backend sẽ tự động:
- Xác thực chữ ký token từ máy chủ chính thức của Google.
- Kiểm tra trùng khớp `aud` (Audience) với `GOOGLE_CLIENT_ID`.
- Kiểm tra tính hợp lệ và thời hạn sống của token Google.
- Cấp JWT session token an toàn cho ứng dụng di động.
