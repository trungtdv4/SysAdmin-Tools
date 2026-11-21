# Network \- IP Manager

### 💡 Ý tưởng & Mục đích

Công cụ dòng lệnh \(CLI\) giúp quản trị viên hệ thống cấu hình nhanh các thông số mạng trên Windows mà không cần thao tác thủ công qua giao diện Network Connections truyền thống. Script hỗ trợ quét trực tiếp danh sách card mạng hiện có trên máy và cho phép tùy chỉnh từng thông số riêng lẻ \(giữ nguyên các giá trị không muốn thay đổi\).

### ✨ Tính năng chính

- **Quét & Chọn Card mạng:** Tự động liệt kê toàn bộ card mạng kèm trạng thái kết nối, chế độ IP hiện tại \(DHCP/Static\), địa chỉ IP, Default Gateway và trạng thái IPv6.
- **Thiết lập IP động \(DHCP\):** Chuyển đổi nhanh card mạng về chế độ nhận IP và DNS tự động, đồng thời làm mới kết nối.
- **Quản lý IPv6:** Bật \(Enable\) hoặc Tắt \(Disable\) giao thức IPv6 trực tiếp trên từng card mạng được chọn.
- Các điểm nâng cấp kỹ thuật đáng chú ý
    - **Cơ chế bỏ qua thông số thông minh \(**`Set-AdapterStaticConfig`**\):**
          - Khi bạn chỉ muốn đổi **Default Gateway** \(nhấn **Enter** bỏ qua IP, Subnet và DNS\), script sẽ kiểm tra chế độ hiện tại của card mạng: nếu card đang ở chế độ IP tĩnh \(`Disabled`\), script chỉ thực hiện gỡ route `0.0.0.0/0` cũ và gán `New-NetRoute` mới mà không làm gián đoạn cấu hình IP/DNS sẵn có.
          - Nếu card đang chạy DHCP \(`Enabled`\) mà bạn chỉ nhập Gateway mới \(bỏ qua IP\), script tự động lấy IPv4 hiện tại của card để chuyển sang tĩnh kèm Gateway mới, tránh tình trạng Windows từ chối gán Gateway tĩnh trên giao diện DHCP.
    - **Hỗ trợ nhập linh hoạt Subnet Mask & DNS:**
          - Ô Subnet Mask chấp nhận cả định dạng thập phân đầy đủ \(ví dụ `255.255.255.0`\) lẫn tiền tố CIDR \(ví dụ `24`\) và kiểm tra tính hợp lệ của dãy bit mặt nạ mạng.
          - Ô DNS tự động tách chuỗi theo dấu phẩy "`,"`, loại bỏ khoảng trắng thừa và kiểm tra từng địa chỉ IPv4 trước khi áp dụng.

### 🚀 Cách sử dụng nhanh

1. **Khởi chạy:** Nhấp đúp chuột trực tiếp vào file `Network - Config Manager.bat` \(chương trình tự động yêu cầu quyền Administrator\).
2. **Chọn Card mạng:** Nhập số thứ tự tương ứng với card mạng cần thao tác từ danh sách hiển thị trên màn hình.
3. **Chọn chức năng cấu hình:**
    - Nhấn **`1`** để chuyển sang **IP động \(DHCP\)**.
    - Nhấn **`2`** để cấu hình **IP tĩnh / Gateway / DNS**:
          - Nhập giá trị mới vào từng mục được hỏi.
          - Nhấn **`Enter`**** \(để trống\)** ở những mục muốn giữ nguyên thông số cũ \(ví dụ: chỉ nhập Default Gateway mới và nhấn `Enter` bỏ qua IP, Subnet, DNS\).
          - Khi nhập nhiều DNS, ngăn cách bằng dấu phẩy \(ví dụ: `8.8.8.8, 1.1.1.1`\).
    - Nhấn **`3`** để **Bật hoặc Tắt IPv6**.
    - Nhấn **`4`** để quay lại chọn card mạng khác hoặc **`0`** để thoát.