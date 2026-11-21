# Fix\-Printer\-No\-Working \- Note

### Cơ chế hoạt động của script:

1. **Tạm dừng **`Spooler`: Tắt dịch vụ `Print Spooler` để gỡ bỏ khóa truy cập \(file lock\) đối với các file in đang bị kẹt trong hệ thống.
2. **Dọn sạch thư mục Buffer**: Xóa toàn bộ file tạm `.SHD` và `.SPL` lưu trong đường dẫn `C:\Windows\System32\spool\PRINTERS\`.
3. **Mở lại **`Spooler`: Khởi động lại dịch vụ in ấn để Windows nhận diện danh sách máy in sạch.
4. **Bật Online cho toàn bộ máy in**: Gọi đồng thời hai lớp lệnh `Set-Printer` và `Win32_Printer` qua WMI để hủy bỏ tùy chọn `WorkOffline` \(`Use Printer Offline`\), ép máy in về trạng thái sẵn sàng làm việc.