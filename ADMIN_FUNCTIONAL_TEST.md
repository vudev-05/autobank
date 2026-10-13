# BÁO CÁO KIỂM THỬ CHỨC NĂNG ADMIN DASHBOARD — ADMIN FUNCTIONAL TEST
**Dự án:** AutoBank PRO — Đọc thông báo nhận tiền  
**Module:** Web Admin Portal (`apps/web/admin/`) & Backend Admin API (`apps/api/src/admin/`)  
**Ngày kiểm thử:** 12/10/2026

---

## BẢNG KIỂM THỬ CHI TIẾT TỪNG CHỨC NĂNG

| STT | Tên chức năng / Nút bấm | Đường dẫn giao diện | API Backend liên quan | Kiểm tra Auth & Quyền | Trạng thái | Ghi chú & Kết quả |
| :---: | :--- | :--- | :--- | :---: | :---: | :--- |
| 1 | **Xem thống kê hệ thống (KPIs)** | `admin/index.html` | `GET /admin/stats` | Admin Token | **PASS** | Hiển thị chính xác tổng user, đơn hàng, doanh thu thực từ database |
| 2 | **Cập nhật cấu hình Web & App** | `admin/config.html` | `POST /admin/configs` | Admin Token | **PASS** | Cập nhật giá gói, hotline, link CHPlay, lưu thành công vào `SystemConfig` |
| 3 | **Quản lý danh sách 65+ Ngân hàng** | `admin/banks.html` | `GET /admin/banks`, `POST /admin/banks`, `DELETE /admin/banks/:id` | Admin Token | **PASS** | Tải danh sách, thêm/sửa ngân hàng, xóa ngân hàng khỏi hệ thống |
| 4 | **Quản lý người dùng & Thiết bị** | `admin/users.html` | `GET /admin/users`, `PUT /admin/users/:email/extend`, `PUT /admin/users/:email/toggle-block` | Admin Token | **PASS** | Gia hạn thủ công ngày dùng, khóa tài khoản vi phạm, hủy liên kết thiết bị |
| 5 | **Bắn thông báo đẩy đến App** | `admin/notifications.html` | `POST /admin/push` | Admin Token | **PASS** | Tạo thông báo broadcast, lưu vào bảng `push_broadcasts` |
| 6 | **Quản lý Đơn hàng & Duyệt đơn** | `admin/orders.html` | `GET /admin/orders`, `PUT /admin/orders/:code/approve`, `DELETE /admin/orders/:code` | Admin Token | **PASS** | Xem danh sách đơn, duyệt kích hoạt thủ công, xóa đơn test |
| 7 | **Cấu hình Cổng AutoBank (ThueApi)** | `admin/payment-autobank.html` | `GET /admin/thueapi/config`, `POST /admin/thueapi/config` | Admin Token | **PASS** | Bật/tắt cổng, lưu API Key (mã hóa), lưu số tài khoản nhận tiền |
| 8 | **Kiểm tra kết nối ThueApi (Ping Test)** | `admin/payment-autobank.html` | `POST /admin/thueapi/test` | Admin Token | **PASS** | Khi chưa có key trả về `BLOCKED: CHƯA CÓ CẤU HÌNH NHÀ CUNG CẤP` rõ ràng |
| 9 | **Xem lịch sử Webhook đối soát** | `admin/payment-autobank.html` | `GET /admin/thueapi/webhooks` | Admin Token | **PASS** | Tải và hiển thị danh sách nhật ký webhook từ bảng `webhook_logs` |
| 10 | **Quản lý API Keys & Secret** | `admin/keys.html` | `GET /admin/keys` | Admin Token | **PASS** | Đã loại bỏ mock FCM key, trường input mật khẩu bảo mật |
| 11 | **Đăng xuất Quản trị viên** | Nút đăng xuất góc trái dưới | Client Session Clear | Không cần | **PASS** | Xóa token phiên làm việc và chuyển hướng về `admin/login.html` |
