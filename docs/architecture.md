# Kiến trúc tổng thể – DVC Guide

## 1. Tổng quan hệ thống

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                              │
│                  Flutter Mobile App (Android/iOS)                │
│              MVVM • Riverpod • go_router • Dio • Material 3      │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS / REST API
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      BACKEND LAYER                               │
│                Spring Boot 3.x API Server                        │
│          MVC • Spring Data JPA • Spring Security • MySQL          │
│                     Port: 8080                                   │
└──────────┬────────────────────────────────────┬─────────────────┘
           │ JPA                                │ HTTP (Internal)
           ▼                                    ▼
┌──────────────────┐              ┌─────────────────────────────┐
│   MySQL 8.x      │              │    AI/RAG Service (Future)   │
│   Database       │              │   Python FastAPI + Ollama    │
│   Port: 3306     │              │   Port: 8000                 │
└──────────────────┘              └─────────────────────────────┘
```

## 2. Mobile – Flutter MVVM

### Luồng dữ liệu
```
View ──► ViewModel ──► Repository ──► DataSource (Dio/API)
  ◄──────────────────────────────────────────────────────
```

### Trách nhiệm các tầng

| Tầng | Trách nhiệm |
|------|------------|
| **View** | Hiển thị UI, nhận tương tác người dùng, không chứa logic |
| **ViewModel** | Quản lý state (Riverpod), xử lý sự kiện UI |
| **Repository** | Interface trung gian, tổng hợp data từ nhiều nguồn |
| **DataSource** | Gọi API (Dio) hoặc local storage |
| **Model** | Deserialize JSON, immutable data classes |

### State Management (Riverpod)
- `AsyncNotifierProvider` cho async state
- `NotifierProvider` cho sync state
- `Provider` cho dependencies (DI)

### Navigation (go_router)
- Declarative routing
- Deep linking support
- Route guards (tương lai)

## 3. Backend – Spring Boot MVC

### Request Flow
```
HTTP Request
    │
    ▼
Controller (nhận request, validate input, gọi Service)
    │
    ▼
Service (xử lý nghiệp vụ, gọi Repository)
    │
    ▼
Repository (Spring Data JPA, truy vấn database)
    │
    ▼
Entity/MySQL
    │
    ▼ (mapping qua MapStruct/manual)
DTO
    │
    ▼
ApiResponse (wrapper chuẩn)
    │
    ▼
HTTP Response (JSON)
```

### Cấu trúc Package
```
com.dvcguide.server/
├── config/          # Cấu hình Spring (CORS, Security, OpenAPI, ...)
├── common/          # Thành phần dùng chung (ApiResponse, Exception)
├── integration/     # Giao tiếp với dịch vụ ngoài (AI Service)
├── health/          # Health check endpoint
└── [feature]/       # Các module nghiệp vụ (tương lai: user, procedure, ...)
    ├── controller/
    ├── service/
    ├── repository/
    ├── entity/
    └── dto/
```

### ApiResponse Standard
```json
{
  "success": true | false,
  "message": "Mô tả kết quả",
  "data": { /* payload */ },
  "timestamp": "2026-11-04T00:00:00Z"
}
```

## 4. AI Service – Python FastAPI (Tương lai)

### Vai trò dự kiến
- Nhận câu hỏi từ Spring Boot qua REST
- Thực hiện RAG: Retrieval từ vector DB, Augmented Generation với Ollama
- Trả kết quả có trích dẫn nguồn

### Luồng RAG (định hướng)
```
Câu hỏi người dùng
    │
    ▼
Embedding Model (Ollama/local)
    │
    ▼
Vector Search (ChromaDB/Qdrant)
    │
    ▼
Context Retrieval + Reranking
    │
    ▼
LLM Generation (Ollama/Qwen/LLaMA)
    │
    ▼
Response với nguồn trích dẫn
```

## 5. Giao tiếp Flutter ↔ Spring Boot

### Protocol
- **Giao thức:** HTTPS REST (JSON)
- **Authentication (tương lai):** Bearer JWT
- **Content-Type:** `application/json`
- **Base URL Dev:** `http://10.0.2.2:8080` (Android emulator → localhost)
- **Base URL Prod:** `https://api.dvcguide.vn`

### Error Handling
- HTTP 4xx/5xx → Flutter parse `ApiResponse.success = false`
- Network error → `DioException` → `AppException`
- UI hiển thị error state qua ViewModel

## 6. Security (Tương lai)

- Spring Security với JWT
- Flutter: token lưu `flutter_secure_storage`
- Refresh token flow
- Role-based access control (RBAC)
