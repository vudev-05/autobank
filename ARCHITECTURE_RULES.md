# QUY TẮC RÀNG BUỘC KIẾN TRÚC HỆ THỐNG AUTOBANK (ARCHITECTURE RULES)

Tài liệu này là quy chuẩn bắt buộc cho toàn bộ mã nguồn của hệ thống AutoBank (Mobile App, Web Admin, Backend API). Mọi sự can thiệp hoặc bổ sung tính năng phải tuân thủ nghiêm ngặt các quy tắc dưới đây:

---

## 1. KẾT NỐI MẠNG & DỮ LIỆU VPS MYSQL
- **Máy chủ VPS**: `180.93.59.46`
- **Domain API**: `https://api.docthongbaobank.com`
- **Domain Web**: `https://docthongbaobank.com`
- **Cơ sở dữ liệu**: MariaDB/MySQL `autobank_db` trên VPS.
- **RÀNG BUỘC TUYỆT ĐỐI**:
  - Khi đóng gói file APK Release, **100% kết nối trực tiếp đến VPS**, không bao giờ sử dụng `localhost`, `127.0.0.1`, hay IP mạng LAN nội bộ.
  - Khi cập nhật cấu trúc bảng SQL, **CHỈ ĐƯỢC PHÉP THÊM CỘT MỚI (`ADD COLUMN IF NOT EXISTS`)**, tuyệt đối không xóa bảng, không drop cột, không làm mất dữ liệu người dùng.

---

## 2. QUY CHUẨN GOOGLE PLAY PROTECT (KHÔNG BỊ CHẶN)
Để file APK không bị Google Play Protect gắn cờ cảnh báo hay chặn cài đặt:
1. **Không xin quyền nhạy cảm bị cấm**: Tuyệt đối không thêm `<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />` vào `AndroidManifest.xml`.
2. **Không quét tin nhắn SMS**: Trong `NotificationListenerService` (`NotificationListener.kt`), tuyệt đối không bắt các package tin nhắn như `"sms"`, `"mms"`, `"messaging"`. Chỉ bắt thông báo từ các app ngân hàng và ví điện tử chính thống.
3. **Mã hóa đường truyền**: `android:usesCleartextTraffic="false"` bắt buộc trên toàn hệ thống để đảm bảo 100% dữ liệu truyền qua HTTPS có chứng chỉ SSL.
4. **Ký số V1 + V2**: Bản phát hành APK bắt buộc phải được ký đầy đủ chữ ký JAR (v1) và APK Signature Scheme v2.

---

## 3. XỬ LÝ THÔNG BÁO VÀ TIẾNG NÓI NHẬN TIỀN
1. **Không bắn thanh thông báo khi nhận tiền**:
   - Khi có thông báo tiền về từ ngân hàng, **AutoBank KHÔNG ĐƯỢC GỬI THÊM THÔNG BÁO LÊN KHAY HỆ THỐNG (Status Bar)** để tránh trùng lặp gây phiền toái cho người dùng.
   - **CHỈ ĐỌC TIẾNG LOA TTS** với cao độ (pitch) và tốc độ (rate) khớp chuẩn xác với cài đặt của người dùng.
2. **Đánh thức màn hình & Chọn phân loại chi tiêu**:
   - Khi màn hình đang tắt hoặc tối mờ, nếu nhận được thông báo tiền về: App tự động đánh thức màn hình sáng lên (`wakeUpScreen()`), hiển thị thông báo nhận tiền toàn màn hình với số tiền cực lớn và danh sách nút chọn nhanh phân loại/quỹ chi tiêu.
3. **Tín hiệu kết nối**:
   - Khi mở app: Có thông báo tín hiệu báo hiệu hệ thống đang hoạt động và sẵn sàng nhận tiền.
   - Khi app bị gián đoạn hoặc tắt màn hình: Có thông báo nhắc người dùng bật "Chế độ quầy thu ngân" để giữ tín hiệu 24/24.

---

## 4. CHẾ ĐỘ QUẦY THU NGÂN 24/24 (CASHIER MODE)
1. **Duy trì màn hình không tắt**: Kích hoạt `FLAG_KEEP_SCREEN_ON` để điện thoại giữ sáng liên tục phục vụ thu ngân tại quầy.
2. **Tự động tối ưu pin (Dim Screen sau 30 giây)**:
   - Sau 30 giây không có tương tác chạm, độ sáng màn hình tự động hạ xuống mức thấp nhất (`0.02 - 0.03`) để tiết kiệm pin tối đa.
   - Khi khách hàng hoặc chủ quán chạm vào bất kỳ đâu trên màn hình, độ sáng lập tức phục hồi `1.0` (100%) và hiển thị mã QR thanh toán rõ nét.
3. **Giọng nói thông báo trạng thái**:
   - Khi bật: Đọc `"Đã bật chế độ quầy thu ngân"`.
   - Khi tắt: Đọc `"Đã tắt chế độ quầy thu ngân"`.

---

## 5. TẢI ẢNH MÃ QR CỦA QUÁN
- Chức năng tải ảnh QR sử dụng thư viện `image_picker`, tự động yêu cầu quyền truy cập thư viện ảnh thật từ hệ điều hành Android.
- Ảnh được lưu trữ ở bộ nhớ máy và đồng bộ lên tài khoản quản lý.

---

## 6. ĐÁNH GIÁ CH PLAY
- Đánh giá là gọi trực tiếp liên kết đánh giá trên Google Play Store (`market://details?id=vn.autobank.autobank_mobile` hoặc link cấu hình `chplayLink`).
- Bắt buộc kích hoạt sau 5 - 12 giờ sử dụng đối với người dùng đang dùng thử bản quyền.

---

## 7. CẤU TRÚC DANH MỤC CÀI ĐẶT
- Mỗi ô chức năng trong phần Cài Đặt phải thực hiện **đúng 1 nhiệm vụ độc lập**, không gom chung nhiều chức năng vào 1 trang hướng dẫn chung chung gây trùng lặp.
