# Hướng dẫn Phát triển – DVC Guide

## Yêu cầu Môi trường

| Tool | Phiên bản tối thiểu |
|------|-------------------|
| Java | 17 |
| Maven | 3.8+ |
| Flutter | 3.x (Dart 3.x) |
| Python | 3.11+ |
| MySQL | 8.x |

---

## 1. Chạy Backend (Spring Boot)

### Chuẩn bị

```bash
# 1. Clone và vào thư mục server
cd server

# 2. Sao chép file cấu hình môi trường
cp .env.example .env

# 3. Chỉnh sửa .env với thông tin database local của bạn
nano .env
```

Nội dung `.env` cần điền:
```bash
DB_HOST=localhost
DB_PORT=3306
DB_NAME=dvcguide_dev
DB_USERNAME=your_username
DB_PASSWORD=your_password
AI_SERVICE_URL=http://localhost:8000
```

### Tạo database MySQL

```sql
CREATE DATABASE dvcguide_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE dvcguide_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### Chạy ứng dụng

```bash
# Development mode
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# Hoặc set environment variables rồi chạy
export $(cat .env | xargs)
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

### Kiểm tra

- **API Health:** `curl http://localhost:8080/api/v1/health`
- **Swagger UI:** http://localhost:8080/swagger-ui.html
- **OpenAPI JSON:** http://localhost:8080/v3/api-docs

### Chạy Tests

```bash
# Tất cả tests
mvn test

# Test cụ thể
mvn test -Dtest=HealthControllerTest
```

---

## 2. Chạy Mobile (Flutter)

### Chuẩn bị

```bash
cd mobile

# Cài packages
flutter pub get
```

### Chạy ứng dụng

```bash
# Development (Android emulator – trỏ về localhost Spring Boot)
flutter run --dart-define=API_URL=http://10.0.2.2:8080

# Development (thiết bị thật)
flutter run --dart-define=API_URL=http://YOUR_MACHINE_IP:8080

# Production
flutter run --dart-define=API_URL=https://api.dvcguide.vn
```

> **Lưu ý:** Trên Android Emulator, `10.0.2.2` là địa chỉ host machine.

### Build APK Debug

```bash
flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8080
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Phân tích và Test

```bash
# Phân tích code
flutter analyze

# Unit tests
flutter test

# Coverage
flutter test --coverage
```

---

## 3. Chạy AI Service (Python FastAPI) – Tương lai

```bash
cd ai-service

# Tạo virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac

# Cài dependencies
pip install -r requirements.txt

# Cấu hình
cp .env.example .env
nano .env

# Chạy development server
uvicorn app.main:app --reload --port 8000
```

- **API:** http://localhost:8000
- **Docs:** http://localhost:8000/docs

---

## 4. Kiến trúc Environments

### Spring Boot

| Profile | File | Mục đích |
|---------|------|---------|
| `dev` | `application-dev.yml` | Local development, log chi tiết |
| `prod` | `application-prod.yml` | Production, log tối thiểu |

Kích hoạt profile:
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=dev
# hoặc
java -jar app.jar --spring.profiles.active=prod
```

### Flutter

Không dùng Flutter flavors trong giai đoạn này. Dùng `--dart-define`:

| Biến | Dev | Prod |
|------|-----|------|
| `API_URL` | `http://10.0.2.2:8080` | `https://api.dvcguide.vn` |

---

## 5. Luồng phát triển tính năng mới

### Backend
1. Tạo Entity → Repository → Service Interface → Service Impl → Controller
2. Tạo DTO (Request + Response)
3. Viết unit test cho Service và Controller
4. Test qua Swagger UI

### Flutter
1. Tạo Model (freezed) → DataSource → Repository → ViewModel → Screen
2. Thêm route vào `app_router.dart`
3. Viết widget test cho Screen

---

## 6. Troubleshooting

### Spring Boot không kết nối được MySQL
```bash
# Kiểm tra MySQL đang chạy
sudo systemctl status mysql

# Kiểm tra biến môi trường
echo $DB_PASSWORD
```

### Flutter build lỗi
```bash
# Clean cache
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Android Emulator không kết nối được API
- Dùng `10.0.2.2` thay vì `localhost` hoặc `127.0.0.1`
- Kiểm tra Spring Boot đang chạy trên port 8080
- Thêm `android:usesCleartextTraffic="true"` trong AndroidManifest nếu dùng HTTP (dev only)
