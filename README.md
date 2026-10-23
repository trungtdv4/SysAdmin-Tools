# README

Status: Not started
Last edited time: October 23, 2026 12:11 PM

# 🧰 SysAdmin Tools - Windows Maintenance & Utility Suite

> **SysAdmin Tools** là bộ công cụ bảo trì, chẩn đoán phần cứng, cài đặt ứng dụng tự động và xử lý Multimedia dạng **Portable / Modular** dành cho Quản trị viên hệ thống (SysAdmin), kỹ thuật viên IT và người dùng văn phòng.
> 

---

## 🚀 3 Phương thức khởi chạy ứng dụng (Execution Modes)

Bạn có thể vận hành SysAdmin Tools linh hoạt theo 3 cách tùy vào ngữ cảnh công việc:

### **1. Chạy trực tiếp trên PC (Local File Execution)**

**Dành cho máy làm việc cố định hoặc khi bạn đã lưu mã nguồn dự án trên máy:**

- Clone hoặc tải gói Zip mã nguồn về máy tính.
- Mở thư mục dự án và chạy file **Bootstrapper.bat** bằng quyền **Run as Admin**.
- Giao diện Menu chính sẽ hiển thị và tự nạp tất cả các module local.

### **2. Chạy trực tiếp riêng lẻ từng file Batch**

- Clone hoặc tải gói Zip mã nguồn về máy tính.
- Mở thư mục dự án vào folder **SysAdmin-Functions.**
- Trong đây vốn có các file Function chức năng, thay vì chạy thành 1 tập hợp menu lệnh như **Cách 1** thì bạn có thể chạy riêng lẻ từng Function bằng cách click chạy từng file .BAT.

### **3. Chạy trực tiếp qua 1 dòng lệnh irm | iex (Remote Bootstrapper / Zero-Footprint).**

**Dành cho kỹ thuật viên IT đi support máy khách/User bất kỳ mà không cần mang theo USB:**

- Mở cửa sổ PowerShell (hoặc Terminal).
- Dán và chạy câu lệnh sau:

```powershell
irm https://bit.ly/SystemAdminTools | iex
```

---

## 📂 Chi tiết các Module tính năng

### 1. 🚀 App & Package Manager (`App Manager - Install or Add your Apps`)

- **Tự động nhận diện trạng thái ứng dụng:** Nhận diện phần mềm đã cài (`[Installed]`) nhờ thuật toán so sánh kép Dual-Match (WinGet App ID + Display Name từ Registry).
- **Cài đặt Local Packages (`.txt`*** / ****`.ps1`***):** Quét thư mục `WinGet/` để nạp danh sách gói cài đặt có sẵn.
- **Cài đặt hàng loạt thông minh:** Hỗ trợ cài ứng dụng WinGet theo số thứ tự (ví dụ: `1,3,5`), nhập App ID thủ công hoặc tìm kiếm kho ứng dụng online.
- **Tùy chọn Y - Manual WinGet ID:** Cho phép dán trực tiếp App ID (ví dụ: `Google.Chrome`, `9N4S39MXHM1T`) để cài ứng dụng đặc thù.
- **Tùy chọn Z - Online WinGet Search:** Tìm kiếm trực tiếp phần mềm từ kho lưu trữ WinGet Repository và cài đặt tức thì.
- **Tích hợp Windows Feature (DISM):** Cho phép bật/tắt các tính năng hệ thống của Windows qua câu lệnh `Enable-WindowsOptionalFeature`.

### 2. 💻 Chẩn đoán phần cứng (`System - Hardware Information`)

- Khai thác thông tin chi tiết qua WMI/CIM: Tên Mainboard/Model Laptop, Serial/Service Tag, CPU, tổng RAM & dung lượng RAM đang sử dụng.
- Phân biệt chính xác loại ổ đĩa **SSD vs HDD**, tổng dung lượng và dung lượng trống còn lại.
- Thống kê chi tiết Card mạng và băng thông kết nối thực tế.

### 3. 🛠️ Các tiện ích sửa lỗi & Khôi phục mặc định:

- **Office - Fix Printer No Working (Dọn dẹp lệnh in bị kẹt):** Dừng dịch vụ Print Spooler, dọn sạch rác trong `C:\Windows\System32\spool\PRINTERS` và bật lại dịch vụ mà không xóa nhầm thiết bị máy in trong máy tính.
- **System - Reset System Defaults:** Khôi phục cảnh báo UAC (Yes/No prompt), trả lại cài đặt mặc định cho Windows Firewall và file `hosts`.
- **System - Adjust Date and Time Vietnamese:** Tự động chỉnh chuẩn múi giờ GMT+7 (Bangkok, Hanoi, Jakarta) và định dạng ngày tháng tiếng Việt (`dd/MM/yyyy`).

### Cùng nhiều tính năng khác sẽ được phát triển trong tương lai!

---