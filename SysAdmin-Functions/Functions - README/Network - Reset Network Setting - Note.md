# Network \- Reset Network Setting \- Note

Dưới đây là file `Network - Reset Network Setting.bat` được thiết kế theo chuẩn Polyglot \(bọc PowerShell bên trong Batch script\).

File được sắp xếp theo thứ tự tối ưu nhất để làm sạch giao thức và làm tươi lại kết nối mạng:

1. **Giải phóng IP hiện tại \(**`ipconfig /release`**\)**: Ngắt kết nối IP động cũ đang giữ lease trên DHCP Server.
2. **Xóa cache DNS \(**`ipconfig /flushdns`**\)**: Dọn sạch bộ nhớ đệm tên miền bị lỗi hoặc đè IP cũ.
3. **Reset Winsock Catalog \(**`netsh winsock reset`**\)**: Khôi phục Winsock API về trạng thái mặc định \(sửa lỗi hỏng Winsock do phần mềm/malware\).
4. **Reset TCP/IP Stack \(**`netsh int ip reset`**\)**: Thiết lập lại toàn bộ bộ giao thức mạng IPv4/IPv6 gốc của Windows.
5. **Xin cấp IP mới \(**`ipconfig /renew`**\)**: Gửi yêu cầu xin cấp IP động mới từ Router/DHCP Server.