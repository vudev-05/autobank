# BÁO CÁO KIỂM THỬ ỨNG DỤNG DI ĐỘNG — MOBILE FUNCTIONAL TEST
**Dự án:** AutoBank PRO — Đọc thông báo nhận tiền  
**Nền tảng:** Flutter + Android Native (Kotlin)  
**Phiên bản:** 1.2.0 Pro  
**Ngày kiểm thử:** 12/10/2026

---

## BẢNG KIỂM THỬ CHI TIẾT CÁC TÍNH NĂNG TRÊN MOBILE

| STT | Chức năng kiểm thử | Thao tác thực hiện | Kỳ vọng & Kết quả | Trạng thái |
| :---: | :--- | :--- | :--- | :---: |
| 1 | **Khởi chạy ứng dụng** | Mở ứng dụng lần đầu sau khi tải | Tải giao diện trang chủ nhanh chóng, không crash, không lag | **PASS** |
| 2 | **Lắng nghe thông báo ngân hàng** | Nhận thông báo tiền vào từ ứng dụng ngân hàng | `NotificationListenerService` bắt sự kiện, trích xuất số tiền và ngân hàng chính xác | **PASS** |
| 3 | **Phát âm Text-to-Speech (TTS)** | Tự động đọc to khi phát hiện biến động | Giọng Chị Google phát âm to rõ ràng, đúng số tiền và lời cảm ơn theo cấu hình | **PASS** |
| 4 | **Trang Kiểm tra hoạt động** | Mở `Cài đặt > Kiểm tra hoạt động` | Hiển thị chính xác trạng thái quyền đọc thông báo, pin và cho phép bấm mở cài đặt hệ thống | **PASS** |
| 5 | **Đăng ký / Gia hạn bản quyền** | Chọn gói cước và bấm mở phương thức thanh toán | Tạo mã đơn hàng duy nhất, hiển thị mã VietQR động có sẵn số tiền và nội dung chuyển khoản | **PASS** |
| 6 | **Áp dụng Mã giảm giá (Coupon)** | Nhập mã `AUTOBANK20` hoặc `TET2026` | Hệ thống kiểm tra hợp lệ, tự động trừ tiền giảm giá và cập nhật lại mã VietQR ngay lập tức | **PASS** |
| 7 | **Tùy chỉnh giọng đọc & Âm lượng** | Thay đổi tốc độ, cao độ, câu mở đầu, câu kết thúc | Lưu cấu hình cục bộ và đồng bộ lên tài khoản người dùng, nghe thử ngay tức thì | **PASS** |
| 8 | **Chống đọc trùng lặp (Deduplication)** | Nhận cùng 1 thông báo liên tiếp trong thời gian ngắn | Tính toán fingerprint và bỏ qua các thông báo trùng, tránh phát âm lặp lại phiền hà | **PASS** |
| 9 | **Chế độ Ngoại tuyến (Offline Mode)** | Nhận thông báo khi máy mất kết nối Internet tạm thời | Dịch vụ đọc giọng nói TTS trên máy vẫn đọc to bình thường, lưu giao dịch vào SQLite nội bộ | **PASS** |
