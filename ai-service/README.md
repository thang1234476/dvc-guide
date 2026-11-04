# DVC Guide AI Service

> Python FastAPI service chuẩn bị cho tích hợp RAG và Ollama trong tương lai.

## Trạng thái hiện tại

**SKELETON ONLY** – Chưa triển khai RAG pipeline.

Hiện tại chỉ có:
- Health check endpoint (`GET /api/v1/health`)
- Cấu hình Pydantic Settings từ environment variables
- Cấu trúc thư mục chuẩn bị cho tương lai

## Vai trò dự kiến

AI Service sẽ xử lý:
1. **Embedding**: Chuyển đổi câu hỏi thành vector
2. **Retrieval**: Tìm kiếm tài liệu liên quan từ vector database (Qdrant)
3. **Reranking**: Sắp xếp kết quả theo độ phù hợp
4. **Generation**: Tạo câu trả lời bằng Ollama LLM (Qwen2/LLaMA)
5. **Citation**: Trả về nguồn trích dẫn cùng câu trả lời

## Chạy service

```bash
# 1. Tạo virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac

# 2. Cài dependencies
pip install -r requirements.txt

# 3. Cấu hình
cp .env.example .env

# 4. Chạy
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- **Swagger:** http://localhost:8000/docs
- **Health:** http://localhost:8000/api/v1/health

## Cấu trúc

```
app/
├── main.py              # FastAPI app entry point
├── core/
│   └── config.py        # Pydantic Settings
├── schemas/
│   └── rag_schemas.py   # Request/Response models (placeholder)
├── services/
│   └── rag_service.py   # RAG pipeline (placeholder)
└── integrations/
    └── ollama/
        └── client.py    # Ollama client (placeholder)
```

## Tích hợp với Spring Boot

Spring Boot sẽ gọi AI Service thông qua REST API:
```
Spring Boot  →  POST /api/v1/rag/query  →  AI Service  →  Ollama
               {question, context}         {answer, sources}
```
