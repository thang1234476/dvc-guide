# Module lịch sử thay đổi

## Cách sử dụng trên web admin

1. Đăng nhập rồi bấm **Lịch sử thay đổi** trên thanh menu. Đường dẫn là `/admin/change-logs`.
2. Danh sách cho biết thời gian, người thay đổi, bảng dữ liệu, ID bản ghi và thao tác. Mỗi trang có 20 dòng, lần mới nhất đứng trước.
3. Chọn các điều kiện rồi bấm **Lọc lịch sử**:
   - **Người thay đổi:** chọn người đã ghi nhật ký. Danh sách vẫn có người đã ngừng hoạt động nếu tài khoản còn trong database.
   - **Thao tác:** tạo mới, chỉnh sửa, xóa / ngừng áp dụng. Với thủ tục, thao tác `xoa` được hiển thị là **Ngừng áp dụng**.
   - **Bảng dữ liệu:** nhập `thu_tuc` khi cần xem các thay đổi của thủ tục.
   - **ID bản ghi:** ID trong database, ví dụ `123`; đây không phải mã thủ tục từ `clean.json`. Kết hợp với bảng dữ liệu để xác định đúng bản ghi.
   - **Từ thời điểm / Đến thời điểm:** chọn ngày, giờ theo múi giờ của trình duyệt. Có thể chỉ điền một đầu khoảng thời gian. Hai mốc được tính vào kết quả.
4. Bấm **Xem chi tiết** ở một dòng. Bảng so sánh chỉ liệt kê các trường khác nhau, với tên trường và giá trị trước / sau. Có thể bấm **Xem thêm trường thay đổi** nếu bản ghi có nhiều thay đổi.
5. Mở **Xem dữ liệu đầy đủ trước / sau** để đối chiếu JSON đã lưu. Giá trị `null`, chuỗi rỗng và trường không tồn tại được phân biệt.
6. Bấm **Đóng chi tiết** để quay lại danh sách; **Xóa bộ lọc** để xem tất cả; **Làm mới** để lấy các thay đổi mới.

Trong trang **Thủ tục**, bấm **Lịch sử** cạnh một thủ tục để mở sẵn bộ lọc bảng `thu_tuc` và ID tương ứng. Bộ lọc, số trang và dòng chi tiết đang mở được lưu trong URL, nên có thể tải lại trang hoặc dùng nút quay lại của trình duyệt.

## Dữ liệu được ghi

Module đọc bảng `nhat_ky_thay_doi` hiện có, không cần tạo bảng hoặc cột mới.

| Cách thay đổi thủ tục | Nhật ký |
|---|---|
| Tạo trên web / API quản trị | `tao`, lưu dữ liệu sau |
| Chỉnh sửa trên web / API quản trị | `sua`, lưu dữ liệu trước và sau |
| Ngừng áp dụng | `xoa`, lưu trạng thái trước và sau; thủ tục vẫn còn trong database |
| Nhập JSON để thêm hoặc cập nhật | `tao` hoặc `sua`, lưu bản JSON nguồn do luồng nhập cung cấp |

Hai cấu trúc dữ liệu đã có đều được hỗ trợ: dữ liệu chỉnh sửa chứa `procedure`, `documents`… và dữ liệu nhập chứa `ma_thu_tuc`, `ho_so`… Mảng được so sánh theo vị trí; nếu thay đổi thứ tự, nhiều mục có thể được báo thay đổi. Chi tiết phản ánh đúng hai bản đã lưu, không tự tạo lại bản trước nếu nhật ký cũ không có dữ liệu đó.

Tên người thay đổi được lấy từ tài khoản hiện tại, dùng email nếu chưa có tên hiển thị. Nếu tài khoản đã bị xóa hoặc nhật ký không lưu người thực hiện, dòng nhật ký vẫn xem được. Thay đổi trực tiếp bằng SQL không tự tạo nhật ký qua module này.

## API backend

Các API yêu cầu đăng nhập bằng tài khoản `admin` hoặc `bien_tap`. Tài khoản người dùng ứng dụng không truy cập được. Module cung cấp các API đọc sau:

| API | Kết quả |
|---|---|
| `GET /api/v1/admin/change-logs` | Danh sách tóm tắt, phân trang; không gửi JSON trước/sau trong từng dòng |
| `GET /api/v1/admin/change-logs/{id}` | Chi tiết, gồm `before`, `after` |
| `GET /api/v1/admin/change-logs/administrators` | ID và tên của những quản trị viên có nhật ký, dùng cho bộ lọc |

Các tham số tìm kiếm đều tùy chọn:

| Tham số | Ý nghĩa |
|---|---|
| `administratorId` | ID quản trị viên, số nguyên dương |
| `tableName` | Tên bảng chính xác, tối đa 64 ký tự |
| `recordId` | ID bản ghi chính xác, tối đa 64 ký tự |
| `action` | `tao`, `sua`, `xoa` |
| `from`, `to` | Thời điểm ISO 8601 có múi giờ, ví dụ `2026-11-28T00:00:00Z` |
| `page` | Bắt đầu từ `0`, tối đa `100000` |
| `size` | Từ `1` đến `100`, mặc định `20` |

Ví dụ xem lịch sử thủ tục số 123:

```text
GET /api/v1/admin/change-logs?tableName=thu_tuc&recordId=123&page=0&size=20
```

API trả `400` nếu bộ lọc không hợp lệ hoặc mốc bắt đầu lớn hơn mốc kết thúc; `404` nếu ID nhật ký không tồn tại. Thứ tự kết quả là thời gian giảm dần, rồi ID nhật ký giảm dần để ổn định phân trang khi các dòng cùng thời gian.

## Chạy và kiểm thử

Khởi động lại backend, chạy admin bằng `npm run dev` trong `admin-web/`, đăng nhập và mở menu mới. Có thể tạo một thủ tục, sửa tên, rồi ngừng áp dụng để kiểm tra ba loại nhật ký.

Nếu frontend đã có menu mới nhưng lịch sử báo lỗi, kiểm tra `http://localhost:8080/v3/api-docs` có đường dẫn `/api/v1/admin/change-logs` hay chưa. Nếu chưa, backend đang chạy bản cũ: dừng bằng `Ctrl+C` trong terminal chạy backend rồi chạy lại `mvn spring-boot:run` từ thư mục `server/`. Vite tự cập nhật giao diện khi sửa file, còn backend cần khởi động lại để nạp controller mới. Khởi động lại backend sẽ kết thúc các phiên đăng nhập đang lưu trong bộ nhớ; đăng nhập lại để tiếp tục.

Kiểm thử backend dùng H2 trong bộ nhớ:

```bash
cd /home/thawn/worksapce/DVC/server
mvn -Dtest=ChangeLogControllerTest,ProcedureImportAndRagTest test
```

Kiểm thử so sánh dữ liệu và build giao diện:

```bash
cd /home/thawn/worksapce/DVC/admin-web
node --test tests/changeLogHelpers.test.js
npm run build
```
