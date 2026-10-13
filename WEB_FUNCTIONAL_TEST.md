# BÁO CÁO KIỂM THỬ CHỨC NĂNG WEBSITE NGƯỜI DÙNG — WEB FUNCTIONAL TEST
**Dự án:** AutoBank PRO — Đọc thông báo nhận tiền  
**Trang web:** `apps/web/index.html` (Landing Page & Khách hàng)  
**Ngày kiểm thử:** 12/10/2026

---

## BẢNG KIỂM THỬ LUỒNG NGƯỜI DÙNG TRÊN WEBSITE

| STT | Luồng người dùng / Thao tác | Mô tả chi tiết | Kiểm tra Responsive | Trạng thái | Kết quả kiểm thử |
| :---: | :--- | :--- | :---: | :---: | :--- |
| 1 | **Tải trang chủ (Landing Page)** | Hiển thị Banner Hero, Slogan "Tiền vừa sang ~ máy báo vang", mockup điện thoại | Desktop & Mobile | **PASS** | Tải trang mượt mà, phong cách Water Blue hiện đại, không vỡ layout |
| 2 | **Bảng danh sách 65+ Ngân hàng** | Xem danh sách các ngân hàng và ví điện tử được hỗ trợ tại Việt Nam | Desktop, Tablet, Mobile | **PASS** | Logo hiển thị sắc nét, phân loại rõ ràng (Ngân hàng TMCP, Neobank, Ví điện tử) |
| 3 | **Bảng giá các gói cước** | Xem giá các gói: 1 tháng, 3 tháng, 6 tháng, 1 năm, Vĩnh viễn | Mọi kích thước màn hình | **PASS** | Dữ liệu giá đồng bộ với cấu hình `SystemConfig`, hiển thị chi tiết quyền lợi |
| 4 | **Nút Tải ứng dụng Android** | Chuyển hướng tới Google Play Store | Mobile & Desktop | **PASS** | Trỏ đúng đường link Google Play chính thức của ứng dụng |
| 5 | **Bộ câu hỏi thường gặp (FAQ)** | Accordion câu hỏi giải đáp cách cấp quyền và an toàn bảo mật | Mọi kích thước | **PASS** | Đóng/mở mượt mà, nội dung khẳng định app không yêu cầu mật khẩu ngân hàng |
| 6 | **Chính sách bảo mật & Điều khoản** | Xem thông tin pháp lý, quyền riêng tư và cam kết bảo vệ dữ liệu | Mọi kích thước | **PASS** | Các điều khoản rõ ràng, cam kết xử lý thông báo cục bộ theo quy chuẩn an toàn |
| 7 | **Hộp thoại hỗ trợ trực tuyến** | Nút liên hệ qua Zalo / Hotline / Facebook | Mọi kích thước | **PASS** | Chuyển hướng chính xác đến kênh hỗ trợ kỹ thuật 24/7 |
