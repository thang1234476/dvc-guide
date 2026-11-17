# DVC Guide AI Service

FastAPI nhận câu hỏi, trích đoạn thủ tục và lịch sử gần đây từ Spring Boot. Ollama trả về câu trả lời tiếng Việt dưới dạng JSON. FastAPI kiểm tra mã trích dẫn có thuộc các nguồn đã nhận trước khi trả kết quả về Spring Boot.

## Chạy riêng

Chạy từ thư mục `ai-service/`.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

Đặt `OLLAMA_BASE_URL` theo địa chỉ Ollama và `OLLAMA_MODEL` theo tên model đã cài. Mặc định FastAPI chờ Ollama tối đa 45 giây. Đặt `AI_SERVICE_TIMEOUT_SECONDS` của Spring Boot lớn hơn `OLLAMA_TIMEOUT_SECONDS` khi điều chỉnh hai giá trị này. [Hợp đồng API chat của Ollama](https://docs.ollama.com/api/chat)

Swagger mở tại [localhost:8000/docs](http://localhost:8000/docs). Endpoint `GET /api/v1/health` báo tiến trình FastAPI và trạng thái khai báo model. Kiểm tra HTTP đến Ollama diễn ra khi có yêu cầu cần model.

## Hợp đồng với Spring Boot

`POST /api/v1/rag/query` nhận JSON gồm `question`, `sources` và `history`. Mỗi nguồn có `procedure_id`, `code`, `title` và `content`. Lịch sử gồm các mục `role` và `content` theo thứ tự cũ đến mới.

| Trạng thái | Ý nghĩa |
|---|---|
| `answered` | Model trả lời kèm mã trích dẫn thuộc danh sách nguồn |
| `gate` | Danh sách nguồn rỗng. Hệ thống gợi ý chọn thủ tục |
| `guard` | JSON trả về hoặc mã trích dẫn của model không đạt yêu cầu |
| HTTP `503` | Model chưa được cấu hình hoặc Ollama không phản hồi hợp lệ |

Nguồn hiện đến từ thủ tục đã chọn và đang áp dụng trong MySQL. Embedding, tìm kiếm vector và đồng bộ chỉ mục theo phiên bản thủ tục là các bước phát triển tiếp theo.

## Kiểm thử

```bash
python -m pytest
```
