# DVC Guide AI Service

FastAPI nhận câu hỏi và danh sách phiên bản thủ tục đang áp dụng từ Spring Boot. RAG tìm kiếm bằng FAISS + BM25 + reranker, dựng ngữ cảnh rồi gọi Ollama. Backend tự gửi thay đổi thủ tục sang AI-service và thử lại khi mất kết nối. [Hướng dẫn nhập dữ liệu và đồng bộ RAG](../docs/import-rag-sync.md)

## Chạy riêng

Chạy từ thư mục `ai-service/`.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
set -a
source .env
set +a
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

Điền `TTHC_API_KEYS` bằng khóa riêng, và dùng một khóa trong danh sách đó cho `AI_SERVICE_API_KEY` của Spring Boot. Đặt `OLLAMA_BASE_URL` theo địa chỉ Ollama và `OLLAMA_MODEL` theo tên model đã cài. Mặc định FastAPI chờ Ollama tối đa 45 giây. Đặt `AI_SERVICE_TIMEOUT_SECONDS` của Spring Boot lớn hơn `OLLAMA_TIMEOUT_SECONDS` khi điều chỉnh hai giá trị này. [Hợp đồng API chat của Ollama](https://docs.ollama.com/api/chat)

Swagger mở tại [localhost:8000/docs](http://localhost:8000/docs). Endpoint `GET /api/v1/health` báo số thủ tục đang nạp và kiểm tra kết nối/model Ollama. BGE-M3 và reranker được nạp khi khởi động; cache giúp tránh tính lại vector không thay đổi. Chạy một worker AI-service như cấu hình mặc định.

## Hợp đồng với Spring Boot

`POST /api/v1/rag/query` yêu cầu `X-API-Key`, nhận `question`, `sources`, `history` và `allowed_procedures`. Mỗi mục được phép gồm `procedure_id`, `code`, `version`; chỉ nguồn đã đồng bộ khớp cả ba trường được dùng. Trả về `source_versions` để backend kiểm tra phiên bản. Lịch sử gồm các mục `role` và `content` theo thứ tự cũ đến mới.

Khi `sources` có dữ liệu, giữ luồng hỏi về thủ tục đã chọn: mỗi nguồn có `procedure_id`, `code`, `title`, `content`, `version`. Khi `sources` rỗng, thực hiện truy xuất trong RAG. Các lệnh kiểm thử AI độc lập có thể bỏ `allowed_procedures` để dùng kho dữ liệu cục bộ.

| Trạng thái | Ý nghĩa |
|---|---|
| `answered` | Model trả lời kèm mã trích dẫn thuộc danh sách nguồn |
| `gate` | Chưa đủ nguồn phù hợp hoặc cần chọn thủ tục/trường hợp |
| `guard` | JSON trả về hoặc mã trích dẫn của model không đạt yêu cầu |
| HTTP `503` | Model chưa được cấu hình hoặc Ollama không phản hồi hợp lệ |

`PUT /api/v1/rag/procedures/{id}` nhận `version`, `code`, `active`, `procedure` với cùng khóa riêng. API cập nhật nguồn và chỉ mục, xử lý đổi mã theo ID cố định, giữ đánh dấu đã gỡ để yêu cầu cũ không đưa thủ tục trở lại. Snapshot `runtime/rag-state.json` giữ dữ liệu và phiên bản qua lần khởi động sau; file `data/clean.json` gốc được giữ nguyên. Không thay renderer, quy tắc chia đoạn hoặc GGUF khi cập nhật nguồn.

## Kiểm thử

```bash
python -m pytest
```

Test dùng dữ liệu tạm và embedding/Ollama mô phỏng, không tải model thật hoặc sửa dữ liệu đang chạy.
