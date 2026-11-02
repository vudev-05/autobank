# KỊCH BẢN DEMO THỰC TẾ: AUTOBANK DỰA TRÊN DỮ LIỆU ĐANG CHẠY
**Đề tài:** AutoBank - Đọc thông báo nhận tiền  
**Nhóm thực hiện (23DTHD3 - HUTECH):** Trần Quốc Vũ, Võ Trương Thành Dân, Huỳnh Nhật Phát, Hoàng Công Huy  

---

## I. GIẢI THÍCH DỮ LIỆU ĐANG HIỂN THỊ TRÊN WEB LIVE (ẢNH THỰC TẾ)

Dữ liệu đang hiển thị trên trang Web Live của bạn gồm **8 giao dịch thực tế** phát sinh từ điện thoại:
* **Tổng tiền nhận vào (+):** `100.000đ` (3 giao dịch: +25.000đ, +50.000đ, +25.000đ)
* **Tổng tiền chuyển đi (-):** `75.104đ` (5 giao dịch: -1.993đ, -42.000đ, -1.111đ, -30.000đ, -2.000đ MoMo)
* **Dòng tiền ròng (Net):** `+24.896đ`
* **Nguồn nhận dạng:** `OTHER_BANK` (các thông báo khuyến mãi / biến động số dư từ app ngân hàng / ví điện tử) và `MOMO`.

---

## II. KỊCH BẢN THUYẾT TRÌNH BÁM SÁT DỮ LIỆU ĐANG CÓ (10 PHÚT)

### 1. Mở đầu: Thực trạng thu chi & nhận tiền tại quầy (2 phút)
* **Lời thoại:**
  > *"Kính thưa Thầy/Cô, trong kinh doanh hàng ngày, chủ cửa hàng vừa phải bán hàng, vừa liên tục mở điện thoại xem biến động số dư. Việc này rất mất thời gian và dễ gặp rủi ro 'biên lai chuyển tiền giả' (fake bill). Giải pháp AutoBank ra đời giúp tự động đọc to số tiền ngay khi có thông báo và đồng bộ tức thì lên màn hình Web Live để quản lý theo dõi từ xa."*

### 2. Trình diễn Web Live 24/7 với Dữ Liệu Thật (3 phút)
* **Thao tác:** Chiếu trực tiếp trang Web Live đang mở trên trình duyệt.
* **Lời thoại thuyết minh số liệu:**
  > *"Như Thầy/Cô đang thấy trên màn hình Web Live:
  > - Hệ thống tự động tổng hợp số liệu trong ngày hôm nay: Quán đã nhận **3 giao dịch** với tổng thu **100.000đ**, chi ra **75.104đ**, dòng tiền thực tế chênh lệch dương **+24.896đ**.
  > - Danh sách bên dưới hiển thị chi tiết từng giao dịch kèm thời gian chính xác đến từng giây.
  > - Trạng thái: 'KẾT NỐI REALTIME 24/7' và 'Loa Sẵn Sàng' giúp chủ quán ở bất kỳ đâu cũng nghe được tiền về mà không cần cầm điện thoại của nhân viên."*

### 3. Demo Nhận Tiền Từ Điện Thoại Sang Web (Realtime 0s) (3 phút)
* **Thao tác:** 
  1. Mở app AutoBank trên điện thoại OPPO (đang cắm cáp).
  2. Bấm **"Mô phỏng thông báo"** (hoặc chuyển khoản thật 1 giao dịch nhỏ).
* **Hiện tượng xảy ra:**
  1. Loa điện thoại và loa trình duyệt Web cùng đọc to số tiền.
  2. Dòng giao dịch mới tự động chèn lên đầu danh sách Web Live ngay lập tức.
  3. Thẻ **Tổng tiền nhận vào** tự động cộng dồn lên chuẩn xác.

### 4. Trình diễn Sổ Thu Chi & Báo Cáo Tài Chính trên Điện Thoại (2 phút)
* **Thao tác trên điện thoại:**
  * Mở tab **Sổ Thu Chi / Báo Cáo**:
  * Chế độ **Doanh nghiệp**: Khớp với số liệu trên Web Live (Tổng thu, tổng chi).
  * Chế độ **Cá nhân**: Phân chia chi tiêu theo **Hũ Locket 55%**, hiển thị chi tiêu trung bình ngày và cho phép bấm thêm chi tiêu bằng tay ngoài ngân hàng.

---

## III. CÁC TÍNH NĂNG ĐẶC BIỆT CẦN NHẤN MẠNH VỚI GIẢNG VIÊN

1. **Khả năng nhận diện đa ngân hàng:** Không chỉ MBBank hay Vietcombank, bộ lọc `GenericBankParser` nhận diện thông báo từ mọi ngân hàng và ví điện tử (kể cả MoMo hiển thị trên màn hình).
2. **Đồng bộ thời gian thực qua Server-Sent Events (SSE):** Dữ liệu được đẩy từ điện thoại lên NestJS API rồi truyền thẳng xuống trình duyệt Web Live với độ trễ cực thấp.
3. **Phân tách 2 chế độ thông minh:** Trong cùng một thiết bị, người dùng có thể tách bạch tiền bán hàng của quán và tiền sinh hoạt cá nhân thông qua thuộc tính `app_mode` được lưu trong SQLite version 3.
