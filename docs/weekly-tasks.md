# Công việc theo module DVC Guide

Chọn một module của mình, làm phần **Cần làm** rồi thử phần **Xong khi**. Số ngày tính theo ngày làm việc, từ thứ Hai đến thứ Sáu. Các ngày trong tài liệu thuộc năm **2026**, chốt lúc **18:00 giờ Việt Nam**.

## Nền dự án

- [ ] **01 · Database và dữ liệu mẫu** · Thành viên 1 · **2 ngày, 18–19/11**
  - **Ngày 1.** Tạo MySQL dùng thử, nhập `infrastructure/database/schema.sql`, kết nối Spring Boot và mở `/api/v1/health` để kiểm tra server.
  - **Ngày 2.** Tạo `infrastructure/database/demo-data.sql` với 5 thủ tục giả lập. Dùng `DEMO-001` làm mẫu có hai trường hợp, giấy tờ chung và riêng, biểu mẫu và hai nơi tiếp nhận. Thêm bản nháp, bản đã ngừng, phí chưa rõ và địa chỉ AI chưa kiểm chứng để kiểm tra cách app hiển thị. Gửi cách nạp dữ liệu và commit nền cho Thành viên 2.
  - **Xong khi** cả hai nạp được dữ liệu lên MySQL mới, server báo `UP` và tìm thấy `DEMO-001` đang áp dụng.

- [ ] **02 · Khung Flutter và bốn tab** · Thành viên 2 · **2 ngày, 18–19/11**
  - **Cần làm.** Chạy app trên Android emulator. Trong `mobile/lib/app/router/`, tạo Trang chủ, Hỏi trợ lý AI, Hồ sơ của tôi và Cài đặt. Nối app với server để thử một yêu cầu.
  - **Xong khi** bấm được cả bốn tab và app đọc được phản hồi từ `/api/v1/health`.

## Tra cứu, tài khoản và hồ sơ

- [ ] **03 · Controller tra cứu** · Thành viên 1 · **2 ngày, 20–23/11**
  - **Ngày 1.** Mở `ProcedureController.java` và `CatalogController.java`. Chạy các API danh sách thủ tục, danh sách lĩnh vực và chi tiết thủ tục bằng dữ liệu module 01. Gửi JSON mẫu cho Thành viên 2 ngay trong ngày.
  - **Ngày 2.** Kiểm tra và bổ sung chỗ còn thiếu cho tìm tên có dấu, bỏ dấu, mã thủ tục và lọc nhiều lĩnh vực. Trong chi tiết, kiểm tra có đủ trường hợp, giấy tờ và biểu mẫu.
  - **Xong khi** gọi `GET /api/v1/procedures?keyword=DEMO-001` tìm đúng thủ tục, gọi chi tiết bằng ID trả đúng dữ liệu, bản nháp và bản ngừng vắng mặt. Hai controller đã có trong repo, công việc là hoàn thiện và kiểm tra trên MySQL.

- [ ] **04 · Màn hình tra cứu và chi tiết** · Thành viên 2 · **2 ngày, 20–23/11**
  - **Cần làm.** Dùng JSON của module 03 để làm ô tìm, lọc lĩnh vực và danh sách. Khi mở thủ tục có nhiều trường hợp, cho chọn trường hợp rồi hiện giấy tờ, điều kiện, cách nộp, phí và biểu mẫu. Danh sách rỗng có nút sang tab AI.
  - **Xong khi** tìm được `DEMO-001` bằng tên và mã. Đổi trường hợp giữ giấy tờ chung và đổi đúng giấy tờ riêng. Nút tải xuất hiện ở biểu mẫu có URL.

- [ ] **05 · Đăng ký, đăng nhập và đăng xuất** · Thành viên 2 làm app, Thành viên 1 thử API · **2 ngày, 24–25/11**
  - **Ngày 1.** Thành viên 1 thử `POST /api/v1/auth/register` và `POST /api/v1/auth/login` trong `AccountController.java`. Thành viên 2 tạo hai màn hình nhập email, mật khẩu và nối API.
  - **Ngày 2.** Lưu phiên đăng nhập an toàn trên app. Thử mở lại app, nhập sai mật khẩu và đăng xuất bằng `POST /api/v1/auth/logout`.
  - **Xong khi** tạo được tài khoản mới, đăng nhập lại được, sai mật khẩu hiện lỗi và đăng xuất làm phiên cũ hết hiệu lực.

- [ ] **06 · Hồ sơ cá nhân, checklist và yêu thích** · Thành viên 1 làm API, Thành viên 2 làm app · **3 ngày, 26–30/11**
  - **Thành viên 1.** Mở `DossierController.java` và `FavoriteController.java`. Thử lưu hồ sơ có trường hợp, ba trạng thái giấy tờ và bộ lọc **Đã lưu**. Gửi JSON mẫu nơi tiếp nhận, kiểm tra hai ô nơi dự định/thực tế lưu riêng và API báo sai địa chỉ ghi đúng cơ quan.
  - **Thành viên 2.** Thêm nút lưu thủ tục, bộ lọc **Đã lưu** và lối vào hồ sơ đang theo dõi. Làm màn tạo, xem, sửa hồ sơ với năm trạng thái, ngày nộp, mã hồ sơ, ngày hẹn và ghi chú. Cho chọn lại trường hợp, đánh dấu **Đã có / Chưa có / Chưa rõ**, xem phần còn thiếu và mở biểu mẫu có link.
  - **Xong khi** tải lại app vẫn thấy yêu thích, đúng trường hợp và checklist đã lưu. Tài khoản B thử đọc hoặc sửa hồ sơ của A bằng API thì bị từ chối.

## AI, nơi tiếp nhận và quản trị

- [ ] **07 · Màn hình chọn nơi tiếp nhận** · Thành viên 2 · **2 ngày, 01–02/12**
  - **Cần làm.** Từ chi tiết thủ tục hoặc hồ sơ, mở danh sách cơ quan theo địa phương. Thêm sao chép địa chỉ, mở bản đồ, chọn nơi dự định/nơi thực tế và báo sai địa chỉ. Hiện nhãn **Địa chỉ tham khảo do AI cung cấp, cần xác nhận trước khi đến** khi gặp địa chỉ AI chưa kiểm chứng.
  - **Xong khi** chọn được cơ quan từ hồ sơ, mở lại vẫn thấy đúng hai nơi nộp và gửi được báo cáo kèm đúng cơ quan.

- [ ] **08 · Tìm nguồn và trả lời AI** · Thành viên 1 · **3 ngày, 01–03/12**
  - **Cần làm.** Dùng phần tìm từ khóa trong `ai-service/app/services/retrieval.py` để lấy đoạn nguồn cho `ChatService.java` khi người dùng hỏi từ tab AI. Dùng `rag_chunk` cho đoạn trích và lấy phiên bản hiện tại của thủ tục đang áp dụng. Thử một câu có dữ liệu qua Ollama thật, một câu thiếu nguồn và một lần lỗi dịch vụ.
  - **Xong khi** hỏi “Đăng ký hồ sơ demo cần giấy tờ gì?” trong hội thoại mới trả đúng nguồn `DEMO-001`. Thủ tục đã ngừng vắng mặt và khi AI lỗi, lịch sử vẫn giữ nguyên.

- [ ] **09 · Màn hình hội thoại Flutter** · Thành viên 2 · **3 ngày, 03–07/12**
  - **Cần làm.** Mở được hội thoại từ tab AI, chi tiết thủ tục và giấy tờ. Hiện câu trả lời, nút **Xem đầy đủ**, lịch sử, đánh giá và xóa cuộc trò chuyện. Dùng JSON mẫu để làm giao diện rồi ghép với kết quả module 08.
  - **Xong khi** hỏi tiếp trong cùng hội thoại, mở nguồn đến đúng thủ tục và đổi được đánh giá **Hữu ích / Chưa đúng**.

- [ ] **10 · React admin quản lý thủ tục** · Thành viên 1 · **2 ngày, 04–07/12**
  - **Cần làm.** Chạy `admin-web/`, kiểm tra đăng nhập, tạo nháp, chuyển sang đang áp dụng, sửa và ngừng một thủ tục. Kiểm tra nhật ký và số phiên bản sau khi sửa.
  - **Xong khi** app tra cứu và AI dùng dữ liệu mới, thủ tục đã ngừng vắng mặt, hồ sơ đã tạo từ thủ tục đó vẫn mở được bởi chủ sở hữu.

## Hoàn thiện và bàn giao

- [ ] **11 · Cài đặt, nhắc ngày hẹn và xóa dữ liệu** · Thành viên 2 làm màn hình, Thành viên 1 làm nhắc lịch và kiểm tra API · **3 ngày, 08–10/12**
  - **Cần làm.** Thêm công tắc nhắc lịch, đặt/hủy lịch trên Android theo ngày hẹn. Nối xem và xóa lịch sử chat, góp ý, đăng xuất, xóa một hồ sơ, xóa dữ liệu cá nhân và xóa tài khoản. Thêm xác nhận cho các thao tác theo đặc tả.
  - **Xong khi** tắt nhắc thì lịch cũ được hủy, hủy thao tác xóa thì dữ liệu còn nguyên, xác nhận xóa tài khoản thì phiên mất hiệu lực và góp ý đã gửi được ẩn danh.

- [ ] **12 · Kiểm thử và tạo APK** · Cả hai · **2 ngày, 11–14/12**
  - **Cần làm.** Thành viên 1 chạy test Spring Boot, FastAPI và build React. Thành viên 2 chạy `flutter analyze`, `flutter test`, build APK và cài lên Android. Hai người thử tra cứu, đăng nhập, hồ sơ, AI, nơi nộp, Cài đặt và admin.
  - **Xong khi** có APK cài được, mã commit, kết quả thử từng chức năng và danh sách lỗi cần sửa.

- [ ] **13 · Bàn giao trên Git** · Thành viên 1 chốt Git, Thành viên 2 chạy lại · **3 ngày, 15–17/12**
  - **Cần làm.** Trước 16/12, Thành viên 2 tải đúng commit vào thư mục mới để nạp database, chạy và thử lại bản APK. Hai người sửa lỗi ảnh hưởng demo. Ngày 17/12, Thành viên 1 đưa bản đã duyệt lên nhánh bàn giao và gửi mã commit cùng cách lấy APK.
  - **Xong khi** người còn lại lấy được đúng commit trên remote, làm theo tài liệu và chạy được bản demo.

[Lịch theo ngày](deadlines.md) · [Roadmap theo tuần](roadmap.md) · [Lệnh cài và chạy từng phần](development-guide.md)
