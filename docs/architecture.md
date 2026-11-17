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
│   MySQL 8.x      │              │    AI/RAG Service            │
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
└── [feature]/       # Các module nghiệp vụ (account, procedure, chat, ...)
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

## 4. Hội thoại và AI service

```text
Client → Spring Boot → FastAPI → Ollama
              │
              └─ MySQL (thủ tục công khai, hội thoại, tin nhắn, đánh giá)
```

- Spring Boot xác thực quyền sở hữu hội thoại, lấy trích đoạn từ thủ tục đang áp dụng và gửi tối đa sáu tin nhắn gần nhất qua HTTP. Cuộc gọi AI diễn ra ngoài giao dịch MySQL.
- FastAPI nhận `POST /api/v1/rag/query`, chuẩn hóa phản hồi từ Ollama và kiểm tra mã nguồn trích dẫn. Nếu danh sách nguồn rỗng, FastAPI trả `gate`.
- Spring Boot lưu câu hỏi và câu trả lời cùng một giao dịch khi lịch sử vẫn khớp. Nếu hội thoại thay đổi trong lúc gọi AI, API trả `409`.

Luồng hiện dùng ngữ cảnh của thủ tục đã chọn. Tìm kiếm ngữ nghĩa, xếp hạng đoạn trích và dựng lại chỉ mục từ `rag_chunk` là bước tiếp theo.

## 5. Giao tiếp Flutter ↔ Spring Boot

### Protocol
- **Giao thức:** HTTPS REST (JSON)
- **Authentication:** Bearer token lưu phiên ở database
- **Content-Type:** `application/json`
- **Base URL Dev:** `http://10.0.2.2:8080` (Android emulator → localhost)
- **Base URL Prod:** `https://api.dvcguide.vn`

### Error Handling
- HTTP 4xx/5xx → Flutter parse `ApiResponse.success = false`
- Network error → `DioException` → `AppException`
- UI hiển thị error state qua ViewModel

## 6. Xác thực và phân quyền

- Backend cấp Bearer token cho người dùng, lưu bản băm SHA-256 và thu hồi phiên khi đăng xuất.
- Admin React gửi HTTP Basic qua kết nối HTTPS khi triển khai. Backend xác thực mật khẩu BCrypt và giới hạn API quản trị theo vai trò `admin` hoặc `bien_tap`.
- Hồ sơ, checklist, yêu thích và hội thoại được truy cập theo tài khoản đã xác thực.
