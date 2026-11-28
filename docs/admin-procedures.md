# Quản lý đầy đủ nội dung thủ tục và xuất JSON

## Xem, thêm và sửa

Trong **Thủ tục**, bấm tên thủ tục để xem đầy đủ dữ liệu; bấm **Chỉnh sửa** để sửa. Nút **Sửa** trong bảng mở trực tiếp chế độ chỉnh sửa. Form có sáu nhóm:

1. **Thông tin chung:** mã, tên, số quyết định, cấp thực hiện, loại thủ tục, đối tượng, lĩnh vực và trạng thái.
2. **Cơ quan:** thực hiện, có thẩm quyền, địa chỉ tiếp nhận, được ủy quyền, phối hợp.
3. **Quy trình và cách nộp:** danh sách bước, các cách nộp; mỗi cách có thời hạn, mô tả và nhiều khoản phí riêng.
4. **Hồ sơ và biểu mẫu:** nhóm, trường hợp, nội dung giấy tờ, số bản chính / bản sao, các biểu mẫu và link Drive tương ứng.
5. **Căn cứ và điều kiện:** danh sách văn bản, số hiệu, nội dung căn cứ; yêu cầu và điều kiện.
6. **Kết quả và từ khóa:** danh sách kết quả gồm mã / tên, mỗi dòng một từ khóa, nguồn và link dịch vụ công.

Các danh sách có nút thêm, bỏ, đưa lên / xuống. Mở từng mục để sửa nội dung dài. Các mục “Lưu ý” vẫn nằm trong `ho_so` theo đúng file nguồn, không tự đổi nhóm. Các thông tin kỹ thuật, ID nguồn và trường bổ sung được giữ lại khi chỉnh sửa. `null` và số `0` được phân biệt; dữ liệu “3 OTHER” không tự chuyển thành “3 ngày”.

Bản gốc JSON đầy đủ được lưu trong `thu_tuc_du_lieu_goc`, các bảng quan hệ được cập nhật trong cùng giao dịch. API chi tiết trả thêm `cleanData` để ứng dụng lấy những trường không có cột riêng, như số quyết định, cơ quan theo vai trò, mô tả cách nộp, mã kết quả và từ khóa. Các API cũ và thông tin chi tiết đã có tiếp tục sử dụng được.

Mỗi lần thay đổi thực sự tăng phiên bản, ghi lịch sử và tạo yêu cầu đồng bộ RAG. Yêu cầu sửa dùng phiên bản đã mở; khi người khác đã sửa trước, API trả `409`, cần mở lại dữ liệu mới.

## Xuất JSON thủ công

Nút **Xuất JSON** ở đầu trang có hai lựa chọn:

- **Tất cả thủ tục:** gồm cả bản nháp và thủ tục ngừng áp dụng; phù hợp để đối chiếu hoặc chuyển dữ liệu.
- **Chỉ thủ tục đang áp dụng:** các thủ tục đang được công khai và dùng cho RAG.

Phạm vi xuất là toàn bộ nhóm đã chọn, không chỉ trang đang hiển thị hoặc từ khóa đang tìm kiếm. File luôn là một danh sách JSON theo cấu trúc `clean.json`. Trạng thái và phiên bản quản trị không được chèn thành trường mới trong JSON nghiệp vụ.

Trong màn hình xem / sửa một thủ tục, nút **Xuất JSON bản đã lưu** tải danh sách chứa riêng thủ tục đó. Nội dung chưa bấm **Lưu thủ tục** chưa có trong file; lưu trước nếu cần xuất bản mới nhất. File xuất không ghi đè `clean.json` ban đầu trên máy.

## Đồng bộ RAG khi AI-service tắt

Cơ chế giữ như trước:

1. Lưu database, lịch sử và hàng đợi trước, không phụ thuộc AI-service đang bật.
2. Worker tự gửi phiên bản mới nhất. AI-service lỗi thì yêu cầu được giữ lại và thử lại sau.
3. Trong **Đồng bộ RAG**, có thể bấm **Đồng bộ lại** một thủ tục hoặc **Đồng bộ lại trang này** để chủ động thử lại.
4. Chỉ thủ tục `dang_dung` được đưa vào chỉ mục; `nhap` và `ngung` được gỡ khỏi RAG.

Xuất file thủ công không kích hoạt đồng bộ. Phần đồng bộ qua API và file tải về cùng dùng bộ dựng JSON từ dữ liệu đã lưu. AI-service giữ các đoạn tìm kiếm cơ sở đã có, bổ sung đoạn cho cơ quan theo vai trò, địa chỉ, số lượng giấy tờ, biểu mẫu, mã kết quả và từ khóa.

## API

| API | Nội dung |
|---|---|
| `GET /api/v1/admin/procedures/{id}/content` | JSON đầy đủ của một thủ tục để mở form |
| `POST /api/v1/admin/procedures` | Tạo; `content` chứa JSON nghiệp vụ, các trường quản trị ở ngoài |
| `PUT /api/v1/admin/procedures/{id}` | Sửa; gửi `version` cùng `content` và thông tin chung |
| `GET /api/v1/admin/procedures/export?activeOnly=false` | Tải tất cả thủ tục |
| `GET /api/v1/admin/procedures/export?activeOnly=true` | Tải thủ tục đang áp dụng |
| `GET /api/v1/admin/procedures/{id}/export` | Tải riêng một thủ tục |

Các API quản trị yêu cầu tài khoản admin hoặc biên tập viên. API xuất trả trực tiếp nội dung file và header `Content-Disposition`, không bọc trong `ApiResponse`. API CRUD cũ không gửi `content` vẫn giữ nội dung mở rộng đang lưu.

Khởi động lại backend để nạp các API mới; khởi động lại AI-service đang chạy để nạp phần tìm kiếm bổ sung. Không cần thêm bảng hoặc cột database cho bản cập nhật này. Khi mở lại backend, phiên đăng nhập trong bộ nhớ kết thúc và cần đăng nhập lại.
