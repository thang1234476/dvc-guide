# DVC Guide

> Ứng dụng mobile hỗ trợ tra cứu thủ tục hành chính bằng AI/RAG

## Tổng quan

**DVC Guide** là nền tảng số hóa hỗ trợ người dân tra cứu, tìm hiểu và thực hiện các thủ tục hành chính công thông qua giao diện hội thoại AI thông minh.

## Kiến trúc tổng thể

```
dvc-guide/
├── mobile/          # Flutter app (Android/iOS) – MVVM + Riverpod
├── server/          # Spring Boot 3.x API Server – MVC + Layered
├── ai-service/      # Python FastAPI + Ollama (RAG Service) – Tương lai
├── docs/            # Tài liệu kiến trúc và hướng dẫn
└── infrastructure/  # Cấu hình hạ tầng (tương lai)
```

## Công nghệ

| Thành phần | Công nghệ |
|-----------|-----------|
| Mobile | Flutter 3.x, Dart 3.x, Riverpod, go_router, Dio, Material 3 |
| Backend | Java 17, Spring Boot 3.x, Spring Data JPA, Spring Security, MySQL |
| AI/RAG | Python 3.12, FastAPI, Ollama (tương lai) |
| Database | MySQL 8.x |

## Bắt đầu nhanh

### Backend (Spring Boot)
```bash
cd server
cp .env.example .env   # Điền thông tin database
mvn spring-boot:run -Dspring-boot.run.profiles=dev
# API: http://localhost:8080
# Swagger: http://localhost:8080/swagger-ui.html
```

### Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter run --dart-define=API_URL=http://localhost:8080
```

### AI Service (Python FastAPI)
```bash
cd ai-service
cp .env.example .env
pip install -r requirements.txt
uvicorn app.main:app --reload
# API: http://localhost:8000
```

## Tài liệu

- [Kiến trúc tổng thể](docs/architecture.md)
- [Cấu trúc dự án](docs/project-structure.md)
- [Quy tắc coding](docs/coding-conventions.md)
- [Hướng dẫn phát triển](docs/development-guide.md)

## Trạng thái

> **Phase:** Core Foundation  
> **Phiên bản:** 0.1.0-SNAPSHOT
# dvc-guide
