# App Manager \- Upgrade your Apps

## 1. Ý tưởng & Mục tiêu

- **Winget Auto Upgrade Manager** là module tiện ích độc lập \(plug\-and\-play\) nằm trong hệ sinh thái AdminSystem Tools, giúp tự động hóa và kiểm soát trực quan quá trình cập nhật phần mềm trên Windows thông qua công cụ dòng lệnh **Windows Package Manager \(WinGet\)**.
- Thay vì phải gõ các câu lệnh thủ công hoặc cập nhật mù toàn bộ ứng dụng, tiện ích cung cấp giao diện bảng danh sách theo số thứ tự \(STT\), cho phép quản trị viên chủ động chọn lọc phần mềm cần nâng cấp, ẩn tạm thời trong phiên làm việc hoặc khóa cập nhật vĩnh viễn \(winget pin\) đối với các ứng dụng đặc thù cần giữ nguyên phiên bản.

## 2. Tính năng chính

- **Tự động nâng quyền & thực thi độc lập:** Chạy trực tiếp bằng cách click đúp, tự động yêu cầu quyền Administrator và dọn dẹp môi trường sau khi thoát.
- **Quét & hiển thị trực quan:** Liệt kê đầy đủ tên phần mềm, App ID, phiên bản hiện tại và phiên bản mới khả dụng theo số thứ tự \(STT\).
- **Cơ chế xử lý dự phòng \(Fallback\):** Hỗ trợ nhập thủ công App ID chính xác nếu chuỗi ID trên bảng hiển thị bị rút gọn dẫn đến lỗi cập nhật.
- **Bỏ qua & Khóa cập nhật \(Pin\):** Cho phép ẩn tạm thời phần mềm trong phiên hiện tại hoặc khóa vĩnh viễn không cho winget tự động nâng cấp.
- **Quản lý danh sách khóa \(Pin Manager\):** Xem toàn bộ các ứng dụng đang bị khóa và mở khóa từng mục hoặc mở khóa toàn bộ chỉ với một thao tác.

## 3. Hướng dẫn sử dụng nhanh

### 3.1. Thao tác tại Menu chính:

- **Nhập stt \(ví dụ: 1, 2, 15\):** Cập nhật duy nhất phần mềm ở dòng tương ứng.
- **Nhập "all":** Cập nhật toàn bộ phần mềm đang hiển thị trên danh sách.
- **Nhập s \+ stt \(ví dụ: s2\):** Tùy chọn bỏ qua phần mềm ở dòng số 2 \(chọn 1 để ẩn tạm thời trong phiên hoặc 2 để khóa vĩnh viễn\).
- **Nhập p:** Mở giao diện Quản lý khóa cập nhật \(Pin Manager\).
- Nhập 0: Thoát chương trình.

### 3.2. Thao tác tại Menu Quản lý khóa \(p\):

- **Nhập stt:** Mở khóa cập nhật cho phần mềm tương ứng.
- **Nhập all:** Mở khóa toàn bộ phần mềm đang bị khóa.
- **Nhập 0:** Quay lại menu cập nhật chính.