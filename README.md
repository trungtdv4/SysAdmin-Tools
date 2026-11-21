# README

Status: Not started
Last edited time: October 23, 2026 12:11 PM

# 🧰 SysAdmin Tools \- Windows Maintenance & Utility Suite

> **SysAdmin Tools** là bộ công cụ bảo trì, chẩn đoán phần cứng, cài đặt ứng dụng tự động và xử lý Multimedia dạng **Portable / Modular** dành cho Quản trị viên hệ thống \(SysAdmin\), kỹ thuật viên IT và người dùng văn phòng.

---

## 🚀 3 Phương thức khởi chạy ứng dụng \(Execution Modes\)

Bạn có thể vận hành SysAdmin Tools linh hoạt theo 3 cách tùy vào ngữ cảnh công việc:

### **1. Chạy trực tiếp trên PC \(Local File Execution\)**

**Dành cho máy làm việc cố định hoặc khi bạn đã lưu mã nguồn dự án trên máy:**

- Clone hoặc tải gói Zip mã nguồn về máy tính.
- Mở thư mục dự án và chạy file **Bootstrapper.bat** bằng quyền **Run as Admin**.
- Giao diện Menu chính sẽ hiển thị và tự nạp tất cả các module local.

### **2. Chạy trực tiếp riêng lẻ từng file Batch**

- Clone hoặc tải gói Zip mã nguồn về máy tính.
- Mở thư mục dự án vào folder **SysAdmin\-Functions.**
- Trong đây vốn có các file Function chức năng, thay vì chạy thành 1 tập hợp menu lệnh như **Cách 1** thì bạn có thể chạy riêng lẻ từng Function bằng cách click chạy từng file .BAT.

### **3. Chạy trực tiếp qua 1 dòng lệnh irm \| iex \(Remote Bootstrapper / Zero\-Footprint\).**

**Dành cho kỹ thuật viên IT đi support máy khách/User bất kỳ mà không cần mang theo USB:**

- Mở cửa sổ PowerShell \(hoặc Terminal\).
- Dán và chạy câu lệnh sau:

```powershell
irm https://bit.ly/SystemAdmin-Tools | iex
```

---

# 📂 Chi tiết các Module tính năng

## App Manager \- Install or Add your Apps

- **Tự động nhận diện trạng thái ứng dụng:** Nhận diện phần mềm đã cài \(`[Installed]`\) nhờ thuật toán so sánh kép Dual\-Match \(WinGet App ID \+ Display Name từ Registry\).
- **Cài đặt Local Packages \(\*\*\*.txt / .**`ps1`**\):** Quét thư mục `WinGet/` để nạp danh sách gói cài đặt có sẵn.

- **Cài đặt hàng loạt thông minh:** Hỗ trợ cài ứng dụng WinGet theo số thứ tự \(ví dụ: `1,3,5`\), nhập App ID thủ công hoặc tìm kiếm kho ứng dụng online.
- **Tùy chọn Y \- Manual WinGet ID:** Cho phép dán trực tiếp App ID \(ví dụ: `Google.Chrome`, `9N4S39MXHM1T`\) để cài ứng dụng đặc thù.
- **Tùy chọn Z \- Online WinGet Search:** Tìm kiếm trực tiếp phần mềm từ kho lưu trữ WinGet Repository và cài đặt tức thì.
- **Tích hợp Windows Feature \(DISM\):** Cho phép bật/tắt các tính năng hệ thống của Windows qua câu lệnh `Enable-WindowsOptionalFeature`.

## App Manager \- Upgrade your Apps

### 1. Ý tưởng & Mục tiêu

- **Winget Auto Upgrade Manager** là module tiện ích độc lập \(plug\-and\-play\) nằm trong hệ sinh thái **AdminSystem Tools**, giúp tự động hóa và kiểm soát trực quan quá trình cập nhật phần mềm trên Windows thông qua công cụ dòng lệnh **Windows Package Manager \(WinGet\).**
- Thay vì phải gõ các câu lệnh thủ công hoặc cập nhật mù toàn bộ ứng dụng, tiện ích cung cấp giao diện bảng danh sách theo số thứ tự \(`STT`\), cho phép quản trị viên chủ động chọn lọc phần mềm cần nâng cấp, ẩn tạm thời trong phiên làm việc hoặc khóa cập nhật vĩnh viễn \(`winget pin`\) đối với các ứng dụng đặc thù cần giữ nguyên phiên bản.

### 2. Tính năng chính

- **Tự động nâng quyền & thực thi độc lập**: Chạy trực tiếp bằng cách click đúp, tự động yêu cầu quyền Administrator và dọn dẹp môi trường sau khi thoát.
- **Quét & hiển thị trực quan**: Liệt kê đầy đủ tên phần mềm, App ID, phiên bản hiện tại và phiên bản mới khả dụng theo số thứ tự \(`STT`\).
- **Cơ chế xử lý dự phòng \(Fallback\)**: Hỗ trợ nhập thủ công App ID chính xác nếu chuỗi ID trên bảng hiển thị bị rút gọn dẫn đến lỗi cập nhật.
- **Bỏ qua & Khóa cập nhật \(********`Pin`********\)**: Cho phép ẩn tạm thời phần mềm trong phiên hiện tại hoặc khóa vĩnh viễn không cho `winget` tự động nâng cấp.
- **Quản lý danh sách khóa \(********`Pin Manager`********\)**: Xem toàn bộ các ứng dụng đang bị khóa và mở khóa từng mục hoặc mở khóa toàn bộ chỉ với một thao tác.

### 3. Hướng dẫn sử dụng nhanh

1. **Thao tác tại Menu chính**:
    - Nhập **`<STT>`** \(ví dụ: `1`, `2`, `15`\): Cập nhật duy nhất phần mềm ở dòng tương ứng.
    - Nhập **`all`**: Cập nhật toàn bộ phần mềm đang hiển thị trên danh sách.
    - Nhập **`s<STT>`** \(ví dụ: `s2`\): Tùy chọn bỏ qua phần mềm ở dòng số 2 \(chọn `1` để ẩn tạm thời trong phiên hoặc `2` để khóa vĩnh viễn\).
    - Nhập **`p`**: Mở giao diện **Quản lý khóa cập nhật \(Pin Manager\)**.
    - Nhập **`0`**: Thoát chương trình.
2. **Thao tác tại Menu Quản lý khóa \(********`p`********\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\)**:
    - Nhập **`<STT>`**: Mở khóa cập nhật cho phần mềm tương ứng.
    - Nhập **`all`**: Mở khóa toàn bộ phần mềm đang bị khóa.
    - Nhập **`0`**: Quay lại menu cập nhật chính.

### 2. 💻 Chẩn đoán phần cứng \(`System - Hardware Information`\)

- Khai thác thông tin chi tiết qua WMI/CIM: Tên Mainboard/Model Laptop, Serial/Service Tag, CPU, tổng RAM & dung lượng RAM đang sử dụng.
- Phân biệt chính xác loại ổ đĩa **SSD vs HDD**, tổng dung lượng và dung lượng trống còn lại.
- Thống kê chi tiết Card mạng và băng thông kết nối thực tế.

### 3. 🛠️ Các tiện ích sửa lỗi & Khôi phục mặc định:

- **Office \- Fix Printer No Working \(Dọn dẹp lệnh in bị kẹt\):** Dừng dịch vụ Print Spooler, dọn sạch rác trong `C:\Windows\System32\spool\PRINTERS` và bật lại dịch vụ mà không xóa nhầm thiết bị máy in trong máy tính.
- **System \- Reset System Defaults:** Khôi phục cảnh báo UAC \(Yes/No prompt\), trả lại cài đặt mặc định cho Windows Firewall và file `hosts`.
- **System \- Adjust Date and Time Vietnamese:** Tự động chỉnh chuẩn múi giờ GMT\+7 \(Bangkok, Hanoi, Jakarta\) và định dạng ngày tháng tiếng Việt \(`dd/MM/yyyy`\).

### Cùng nhiều tính năng khác sẽ được phát triển trong tương lai\!

---