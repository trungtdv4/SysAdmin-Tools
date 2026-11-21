# Driver \- Backup & Restore Drivers

### 💡 Ý tưởng & Mục tiêu

Tiện ích dòng lệnh tương tác giúp sao lưu và khôi phục nhanh toàn bộ trình điều khiển bên thứ ba \(OEM/Third\-party Drivers\) trên Windows trước và sau khi cài lại hệ điều hành. Công cụ đặc biệt hữu ích cho các dòng máy trạm hoặc laptop nội địa \(như các dòng máy thị trường Trung Quốc\) vốn dùng linh kiện tùy chỉnh khiến Windows Update không thể tự dò tìm driver.

Chương trình kết hợp ưu thế của hai công cụ gốc trên Windows:

- **DISM:** Trích xuất nguyên bản và đầy đủ các gói driver từ kho hệ thống \(`DriverStore`\).
- **PnPUtil:** Nạp và kích hoạt trực tiếp driver cho thiết bị phần cứng ngay lập tức mà không cần thông qua bộ cài `.exe` hay phần mềm rác đi kèm.

---

### 🚀 Cách sử dụng

1. Chạy trực tiếp file script `.bat` \(chương trình tự động yêu cầu quyền **Administrator**\).
2. Nhập phím số tương ứng trên Menu để thực hiện tác vụ:

- **`[1]`** Backup toàn bộ Drivers \(DISM\):
Tự động khởi tạo thư mục `D:DriverBackup` và xuất toàn bộ driver OEM đang hoạt động trên máy vào thư mục này.
- **`[2]`** Restore Drivers \(PnPUtil\):
Nhấn **Enter** để khôi phục nhanh từ thư mục mặc định `D:DriverBackup` \(hoặc dán đường dẫn thư mục driver bất kỳ\). Hệ thống sẽ tự quét đệ quy và cài đặt toàn bộ driver tương thích.
- **`[3]`** Backup chọn lọc theo Hardware:
Tự động quét, gộp nhóm driver theo tên thiết bị hiển thị trong Device Manager và đánh số thứ tự \(STT\). Nhập một hoặc nhiều STT cách nhau bằng dấu phẩy \(ví dụ: `1, 4, 7`\) để trích xuất riêng driver của các phần cứng mong muốn vào `D:DriverBackup_Selected`.
- **`[0]`** Thoát: Đóng chương trình.