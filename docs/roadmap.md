# Roadmap DVC Guide theo module

Hai thành viên có khoảng một tháng để bàn giao mã nguồn, dữ liệu mẫu, hướng dẫn chạy và APK Android. Hạn cuối là **18:00 ngày 17/12/2026**, giờ Việt Nam.

**Bắt đầu với hai việc song song.** Thành viên 1 dựng Database và nạp dữ liệu mẫu. Thành viên 2 chạy Flutter và tạo bốn tab. Mỗi phần có ngày chốt, nơi sửa và kết quả cần thử trong [danh sách 13 module](weekly-tasks.md).

## Thứ tự triển khai

| Tuần | Thành viên 1 | Thành viên 2 | Cuối tuần phải làm được |
|---|---|---|---|
| **18–23/11** | Database, dữ liệu mẫu và Controller tra cứu | Khung Flutter, màn tìm và chi tiết | Tìm `DEMO-001` trên app, chọn trường hợp và xem đúng giấy tờ |
| **24–30/11** | Thử API đăng ký/đăng nhập, hồ sơ, checklist và dữ liệu cơ quan | Đăng ký/đăng nhập, hồ sơ, checklist và yêu thích | Đăng nhập, lập hồ sơ và mở lại app thấy dữ liệu đã lưu |
| **01–07/12** | Tìm nguồn cho AI, chạy Ollama thật và thử React admin | Nơi tiếp nhận và màn hội thoại | Hỏi từ tab AI và mở được nguồn. Chọn nơi nộp. Sửa nội dung trên admin và tra cứu thấy thay đổi |
| **08–14/12** | Kiểm tra xóa dữ liệu, làm nhắc ngày hẹn và chạy test server | Cài đặt, kiểm thử Android và tạo APK | Có APK thử được các chức năng chính và có danh sách lỗi |
| **15–17/12** | Sửa lỗi và chốt mã nguồn trên Git | Chạy lại từ commit bàn giao và kiểm tra APK | Hai người lấy được cùng mã commit và chạy được demo từ hướng dẫn |

## Bản demo gồm những phần nào

- **Trang chủ** tìm theo tên hoặc mã, lọc nhiều lĩnh vực, xem chi tiết theo trường hợp và lưu yêu thích. Giấy tờ chung xuất hiện ở mọi trường hợp. Phí chưa có số tiền và trạng thái pháp lý chưa xác minh hiện đúng dữ liệu. Nút tải chỉ hiện khi có link.
- **Hỏi trợ lý AI** trả lời từ tab riêng hoặc theo thủ tục/giấy tờ, mở được nguồn, hỏi tiếp, xem lịch sử và đánh giá. Trong tháng này, phần tìm nguồn dùng BM25 trên dữ liệu mẫu. Thêm `bge-m3` và đồng bộ chỉ mục tự động là việc sau MVP.
- **Hồ sơ của tôi** tạo hồ sơ, cập nhật năm trạng thái và đánh dấu ba mức checklist. Tìm nơi tiếp nhận mở từ chi tiết thủ tục hoặc hồ sơ. Nơi dự định nộp và nơi thực tế đã nộp được lưu riêng.
- **Cài đặt** bật tắt nhắc ngày hẹn, góp ý, quản lý lịch sử, đăng xuất và xóa hồ sơ/dữ liệu/tài khoản.
- **React admin** tạo, sửa và ngừng thủ tục. Thủ tục đã ngừng ẩn khỏi tra cứu và nguồn AI. Nhật ký lưu thay đổi và hồ sơ đã lập vẫn còn để chủ sở hữu theo dõi.

Các module dựa trên đặc tả Flutter và [schema SQL](../infrastructure/database/schema.sql). Database dùng schema có sẵn và thêm dữ liệu thử. Các Controller hiện có được hoàn thiện và kiểm tra theo từng chức năng.

[Danh sách việc theo module](weekly-tasks.md) · [Hạn chốt và bài thử](deadlines.md) · [Cách chạy dự án](development-guide.md)
