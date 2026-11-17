# DVC Guide

> Ứng dụng mobile hỗ trợ tra cứu thủ tục hành chính bằng AI/RAG

## Tổng quan

**DVC Guide** là nền tảng số hóa hỗ trợ người dân tra cứu, tìm hiểu và thực hiện các thủ tục hành chính công thông qua giao diện hội thoại AI thông minh.

## Kiến trúc tổng thể

```
dvc-guide/
├── mobile/          # Flutter app (Android/iOS) – MVVM + Riverpod
├── server/          # Spring Boot 3.x API Server – MVC + Layered
├── admin-web/       # React + Vite, quản trị thủ tục
├── ai-service/      # Python FastAPI + Ollama, khung hỏi đáp theo nguồn
├── docs/            # Tài liệu kiến trúc và hướng dẫn
├── infrastructure/  # Schema MySQL
└── compose.yaml      # Chạy chung database, API, AI service và admin
```

## Công nghệ

| Thành phần | Công nghệ |
|-----------|-----------|
| Mobile | Flutter 3.x, Dart 3.x, Riverpod, go_router, Dio, Material 3 |
| Backend | Java 17, Spring Boot 3.x, Spring Data JPA, Spring Security, MySQL |
| Admin | React, Vite |
| AI/RAG | Python 3.12, FastAPI, Ollama |
| Database | MySQL 8.x |

## Bắt đầu nhanh với Docker Compose

```bash
cp .env.example .env
# Điền MYSQL_ROOT_PASSWORD và DB_PASSWORD trong .env
docker compose up --build
```

MySQL nhập schema khi tạo volume lần đầu. Mở [Admin Web](http://localhost:5173), [Swagger Spring Boot](http://localhost:8080/swagger-ui.html) hoặc [Swagger AI service](http://localhost:8000/docs). Cách tạo tài khoản quản trị và cấu hình Ollama nằm trong [hướng dẫn chạy chung](docs/development-guide.md#0-chạy-chung-với-docker-compose).

## Chạy từng thành phần

### Backend (Spring Boot)
Chạy từ thư mục gốc với một database trống.

```bash
mysql --default-character-set=utf8mb4 -u root -p < infrastructure/database/schema.sql
cd server
cp .env.example .env   # Điền thông tin kết nối
set -a
source .env
set +a
mvn spring-boot:run
```

Swagger mở tại [localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html).

### Admin (React)

```bash
cd admin-web
npm ci
npm run dev
```

Mở [localhost:5173](http://localhost:5173) sau khi khởi tạo tài khoản quản trị theo [hướng dẫn phát triển](docs/development-guide.md#2-chạy-admin-web-react).

### Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter run --dart-define=API_URL=http://localhost:8080
```

### AI Service (Python FastAPI)
```bash
cd ai-service
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

## Tài liệu

- [Kiến trúc tổng thể](docs/architecture.md)
- [Cấu trúc dự án](docs/project-structure.md)
- [Quy tắc coding](docs/coding-conventions.md)
- [Hướng dẫn phát triển](docs/development-guide.md)

## Trạng thái

> **Phase:** Core Foundation  
> **Phiên bản:** 0.1.0-SNAPSHOT
