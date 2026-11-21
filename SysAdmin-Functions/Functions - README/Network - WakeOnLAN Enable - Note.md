# WakeOnLAN\-Enable \- Note

### Các tính năng script sẽ tự động kích hoạt:

1. **Yêu cầu quyền Administrator**: Tự động tự nâng quyền Run as Administrator khi khởi chạy.
2. **Cấu hình Card mạng \(NIC Adapter properties\)**:
    - Bật `Magic Packet` \(`*WakeOnMagicPacket` = Enabled\).
    - Bật `Pattern Match` \(`*WakeOnPattern` = Enabled\).
    - Bật tính năng nhận lệnh WoL khi máy đang ở trạng thái tắt S5/Energy Efficient Ethernet.
3. **Cấu hình Quản lý Nguồn điện Card mạng \(Power Management\)**:
    - Cho phép thiết bị bật máy \(`Allow Device to Wake the Computer`\).
    - Yêu cầu chỉ bật khi nhận gói tin Magic Packet \(`Only allow a magic packet to wake the computer`\).
4. **Tắt Fast Startup \(Khởi động nhanh\)**: Tắt tính năng Fast Startup của Windows vì tính năng này đưa máy vào trạng thái ngủ đông sâu \(Hybrid Shutdown\), làm ngắt nguồn Card mạng làm WoL không hoạt động.
5. **Cấu hình Tường lửa \(Windows Firewall\)**: Mở các cổng UDP `7` và UDP `9` cho giao thức WoL.