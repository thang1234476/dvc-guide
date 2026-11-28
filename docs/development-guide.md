# Hướng dẫn Phát triển – DVC Guide

## Yêu cầu Môi trường

| Tool | Phiên bản tối thiểu |
|------|-------------------|
| Java | 17 |
| Maven | 3.8+ |
| Flutter | SDK kèm Dart 3.13.1+ |
| Node.js | 20.19+ hoặc 22.12+ (admin web) |
| Python | 3.11+ |
| MySQL | 8.x |

---

## 0. Chạy chung với Docker Compose

Chạy các lệnh sau từ thư mục gốc bằng Docker Compose v2.

```bash
cp .env.example .env
# Điền MYSQL_ROOT_PASSWORD và DB_PASSWORD trong .env
docker compose up --build
```

Để đăng nhập admin, thêm `ADMIN_BOOTSTRAP_EMAIL` và `ADMIN_BOOTSTRAP_PASSWORD` vào `.env` trước lần chạy tạo tài khoản đầu tiên. Mật khẩu admin cần ít nhất 12 ký tự và tối đa 72 byte UTF-8. Sau khi tài khoản đã được tạo, có thể xóa hai giá trị này khỏi `.env` và tạo lại container Spring Boot bằng `docker compose up -d server`.

| Dịch vụ | Địa chỉ mặc định |
|---|---|
| React admin | [127.0.0.1:5173](http://127.0.0.1:5173) |
| Swagger Spring Boot | [127.0.0.1:8080/swagger-ui.html](http://127.0.0.1:8080/swagger-ui.html) |
| Swagger FastAPI | [127.0.0.1:8000/docs](http://127.0.0.1:8000/docs) |
| MySQL | `mysql:3306` trong mạng Docker |

Đổi cổng host trong `.env` nếu cổng mặc định đang được sử dụng. MySQL nhập `infrastructure/database/schema.sql` khi volume còn trống. `docker compose down` dừng stack và giữ volume dữ liệu. [Khởi tạo MySQL](https://hub.docker.com/_/mysql), [Thứ tự khởi động Compose](https://docs.docker.com/compose/how-tos/startup-order/)

### Bật Ollama cho hội thoại gắn thủ tục

Khởi động profile `ollama` và cài model bạn chọn. Thay `TEN_MODEL` bằng tên model thực tế.

```bash
docker compose --profile ollama up -d ollama
docker compose --profile ollama exec ollama ollama pull TEN_MODEL
```

Đặt `OLLAMA_MODEL=TEN_MODEL` trong `.env` và chạy `docker compose up -d ai-service` để cập nhật cấu hình. Nếu dùng Ollama ở nơi khác, đặt `OLLAMA_BASE_URL` thành địa chỉ có thể truy cập từ container FastAPI. [Tài liệu chạy Ollama trong Docker](https://docs.ollama.com/docker)

---

## 1. Chạy Backend (Spring Boot)

### Chuẩn bị

Nhập schema một lần trên database mới. Schema tạo và sử dụng database `dvc_guide`.

```bash
mysql --default-character-set=utf8mb4 -u root -p < infrastructure/database/schema.sql
cd server
cp .env.example .env
```

Điền thông tin kết nối vào `.env` theo cú pháp `KEY=value`. Đặt giá trị có khoảng trắng hoặc ký tự đặc biệt trong dấu nháy phù hợp. Backend tự đọc `server/.env` bằng [dotenv-java](https://github.com/cdimascio/dotenv-java) khi khởi động, rồi kiểm tra schema.

```bash
mvn spring-boot:run
```

Backend đọc `.env` trong `server/` mỗi lần khởi động, cả khi chạy từ thư mục gốc dự án. Các biến môi trường do terminal/Docker/IDE cung cấp được ưu tiên hơn giá trị trong file. Nếu terminal đã nạp cấu hình cũ bằng `source .env`, mở terminal mới để dùng giá trị vừa sửa trong file. Bộ test với profile `test` dùng cấu hình H2 riêng.

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

## 2. Chạy Admin Web (React)

Dùng Node.js 20.19+ hoặc 22.12+. Để tạo quản trị viên đầu tiên, thêm biến môi trường trước khi chạy Spring Boot từ thư mục `server/`.

```bash
export ADMIN_BOOTSTRAP_EMAIL=admin@example.com
read -rs -p 'Mật khẩu admin: ' ADMIN_BOOTSTRAP_PASSWORD
printf '\n'
export ADMIN_BOOTSTRAP_PASSWORD
mvn spring-boot:run
```

Mật khẩu cần ít nhất 12 ký tự và tối đa 72 byte UTF-8. Backend chỉ dùng biến khởi tạo khi bảng quản trị viên còn trống. Sau khi tài khoản đã được tạo, bỏ hai biến này trong lần khởi động tiếp theo.

Ở terminal khác, chạy từ thư mục gốc.

```bash
cd admin-web
npm ci
npm run dev
```

Mở [localhost:5173](http://localhost:5173). Vite chuyển tiếp `/api` đến Spring Boot. Sao chép `admin-web/.env.example` thành `.env` và đổi `ADMIN_API_TARGET` nếu backend chạy trên địa chỉ khác. Khi đưa bản `npm run build` lên máy chủ, phục vụ `dist/` qua HTTPS và chuyển tiếp `/api` trên cùng origin đến Spring Boot. Nếu reverse proxy kết thúc TLS, đặt `CORS_ALLOWED_ORIGINS` theo origin HTTPS của trang admin và `ADMIN_SESSION_COOKIE_SECURE=true` cho backend. Docker Compose nhận hai biến này từ `.env` ở thư mục gốc. [Tài liệu proxy của Vite](https://vite.dev/config/server-options#server-proxy)

Admin có thể tạo, sửa và ngừng áp dụng thủ tục. Mỗi lần thay đổi thành công cập nhật phiên bản và ghi nhật ký trong cùng giao dịch. Import dữ liệu danh mục và nội dung thủ tục để có dữ liệu tra cứu ban đầu. Schema đính kèm chỉ chứa DDL.

Form thủ tục hỗ trợ đầy đủ nội dung theo `clean.json`, kèm xuất JSON toàn bộ / đang áp dụng / từng thủ tục. Xem [quản lý nội dung thủ tục và xuất JSON](admin-procedures.md).

### URL và giữ đăng nhập khi tải lại trang

Trên máy tính, các module nằm trong menu bên trái; trên điện thoại, bấm biểu tượng menu ở góc trên trái để mở. Tên và biểu tượng tài khoản ở góc trên phải dẫn đến **Tài khoản của tôi**. Bảng rộng có thể cuộn ngang và dùng các nút phân trang ở cuối bảng.

| Trang | URL |
|---|---|
| Đăng nhập | `/login` |
| Trang mặc định, chuyển đến quản lý thủ tục | `/admin` hoặc `/` |
| Quản lý thủ tục | `/admin/procedures` |
| Lịch sử thay đổi | `/admin/change-logs` |
| Quản lý tài khoản admin | `/admin/accounts` |
| Tài khoản của tôi | `/admin/me` |

Thanh điều hướng dùng React Router: URL thay đổi theo mục đang mở, hỗ trợ nút quay lại/tiến tới. Có thể mở trực tiếp hoặc tải lại từng URL. Vite và cấu hình Nginx trong `admin-web/nginx.conf` đã chuyển các đường dẫn giao diện về `index.html`; nếu dùng máy chủ khác, cần cấu hình tương tự. [Điều hướng React Router](https://reactrouter.com/start/declarative/navigating)

Khi mở trang hoặc nhấn F5, giao diện gọi `GET /api/v1/admin/me` để khôi phục tài khoản từ phiên backend. Nếu chưa đăng nhập, ứng dụng chuyển sang `/login`; đăng nhập thành công sẽ trở lại đường dẫn cần mở. Nếu backend tạm mất kết nối, trang hiển thị lỗi cùng nút **Thử lại**.

Phiên được giữ bằng cookie `DVC_ADMIN_SESSION`, có `HttpOnly`, `SameSite=Lax` và chỉ gửi đến `/api/v1/admin`. Mật khẩu chỉ gửi khi đăng nhập hoặc đổi mật khẩu, không lưu trong `localStorage` hay `sessionStorage`. Phiên hết hạn sau 8 giờ không hoạt động; đăng xuất hoặc đổi mật khẩu yêu cầu đăng nhập lại. Đổi mật khẩu cũng vô hiệu hóa các phiên khác của cùng tài khoản ở lần gọi API tiếp theo. Phiên lưu trong bộ nhớ backend nên khởi động lại backend cũng yêu cầu đăng nhập lại. [Lưu phiên Spring Security](https://docs.spring.io/spring-security/reference/servlet/authentication/session-management.html)

Sau khi cập nhật code, khởi động lại Spring Boot. Chạy `npm ci` trong `admin-web/` để cài thêm React Router rồi khởi động lại Vite và đăng nhập một lần.

### Quản lý tài khoản admin

Sau khi đăng nhập, dùng các mục trên thanh điều hướng:

1. **Tài khoản admin → Thêm admin:** nhập email, tên hiển thị, mật khẩu ban đầu và nhập lại mật khẩu. Tài khoản mới có quyền `admin`, đăng nhập được ngay. Email không được trùng; mật khẩu cần ít nhất 12 ký tự và tối đa 72 byte UTF-8. Cấp thông tin đăng nhập cho người được giao quản lý.
2. **Tài khoản của tôi → Thông tin tài khoản:** sửa tên hiển thị và bấm **Lưu thông tin**. Email và vai trò hiển thị để đối chiếu.
3. **Tài khoản của tôi → Đổi mật khẩu:** nhập mật khẩu hiện tại, mật khẩu mới và xác nhận. Sau khi lưu thành công, đăng nhập lại bằng mật khẩu mới; mật khẩu cũ không còn dùng được.

Chỉ tài khoản có vai trò `admin` được xem danh sách và tạo admin. Vai trò `bien_tap` được sửa thông tin và đổi mật khẩu của chính mình. Backend luôn xác định tài khoản cần sửa từ thông tin đăng nhập.

| Thao tác | API |
|---|---|
| Xem danh sách admin, có phân trang `page`, `size` | `GET /api/v1/admin/accounts` |
| Tạo admin (`email`, `displayName`, `password`) | `POST /api/v1/admin/accounts` |
| Xem tài khoản đang đăng nhập | `GET /api/v1/admin/me` |
| Sửa tên hiển thị (`displayName`) | `PUT /api/v1/admin/me` |
| Đổi mật khẩu (`currentPassword`, `newPassword`, `confirmPassword`) | `POST /api/v1/admin/me/password` |

Web admin đăng nhập qua `POST /api/v1/admin/auth/login` với `email`, `password`, sau đó gửi cookie phiên trong các yêu cầu cùng origin. `POST /api/v1/admin/auth/logout` hủy phiên. Trước mỗi thao tác ghi, bao gồm đăng nhập và đăng xuất, frontend lấy token từ `GET /api/v1/admin/auth/csrf` rồi gửi trong header `X-CSRF-TOKEN`. HTTP Basic vẫn dùng được với các API quản trị hiện có. Khi thử bằng Swagger/curl mà có gửi kèm cookie phiên, thao tác ghi vẫn cần token CSRF; curl chỉ gửi HTTP Basic và không gửi cookie thì không cần token này.

Chạy kiểm thử module bằng `mvn -Dtest=AdministratorControllerTest,AdministratorSessionTest,AdminModelsTest test` từ thư mục `server/`; test dùng H2 trong bộ nhớ và không đổi dữ liệu thật. Module sử dụng bảng `quan_tri_vien` hiện có, không cần nhập lại schema.

### Nhập dữ liệu và cập nhật RAG

Web admin có thêm **Nhập dữ liệu** (`/admin/imports`) và **Đồng bộ RAG** (`/admin/ai-sources`). Với database đã tạo trước bản cập nhật này, chạy `infrastructure/database/migrations/20261128_rag_vietnamese_names.sql` theo [hướng dẫn nhập và đồng bộ RAG](import-rag-sync.md), cấu hình `AI_SERVICE_API_KEY` khớp `TTHC_API_KEYS`, rồi khởi động lại hai dịch vụ. Script tạo hoặc chuyển ba bảng mới sang tên tiếng Việt, giữ dữ liệu đã có. Thêm, sửa và ngừng áp dụng thủ tục sẽ tự ghi yêu cầu đồng bộ trong cùng giao dịch database.

### Lịch sử thay đổi

Mở **Lịch sử thay đổi** để lọc theo người thay đổi, thao tác, bảng / ID bản ghi và thời gian, rồi xem nội dung trước và sau. Trong trang **Thủ tục**, liên kết **Lịch sử** mở sẵn lịch sử của thủ tục tương ứng. Module dùng bảng `nhat_ky_thay_doi` đã có; tài khoản `admin` và `bien_tap` đều được xem. Xem [hướng dẫn và API lịch sử thay đổi](change-history.md).

---

## 3. Chạy Mobile (Flutter)

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

## 4. Chạy AI Service (Python FastAPI)

```bash
cd ai-service
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

Nhập `OLLAMA_BASE_URL` và `OLLAMA_MODEL` trong `.env` khi muốn gọi model. Spring Boot gọi FastAPI qua biến `AI_SERVICE_URL`. [Hướng dẫn AI service](../ai-service/README.md)

### Thử luồng hội thoại trong Swagger Spring Boot

1. Đăng ký hoặc đăng nhập bằng `/api/v1/auth/register` hoặc `/api/v1/auth/login`. Dán giá trị `data.session.token` vào **Authorize** → `userBearer`.
2. Gọi `POST /api/v1/conversations` với body `{}` để tạo hội thoại. Truyền `procedureId` nếu muốn hỏi về một thủ tục đang áp dụng.
3. Gọi `POST /api/v1/conversations/{id}/messages` với body `{"content":"Hồ sơ cần giấy tờ gì?"}`. Kết quả gồm câu hỏi và câu trả lời. Hội thoại chưa gắn thủ tục nhận trạng thái `gate` và chạy được trước khi cấu hình Ollama.
4. Xem lịch sử theo thứ tự mới nhất trước qua `GET /api/v1/conversations/{id}/messages`. Gọi `PUT /api/v1/conversations/{id}/messages/{messageId}/rating` với body `{"helpful":true}` để đánh giá câu trả lời. Gọi lại với giá trị mới để thay đổi đánh giá.
5. Dùng `DELETE /api/v1/conversations/{id}` để xóa một hội thoại hoặc `DELETE /api/v1/conversations` để xóa lịch sử hội thoại của tài khoản.

Spring Boot trả `503` khi FastAPI hoặc Ollama gặp lỗi và giữ nguyên lịch sử. Khi hai câu hỏi dùng cùng lịch sử và một câu đã được lưu, yêu cầu còn lại nhận `409`; tải lịch sử mới rồi gửi lại.

---

## 5. Kiến trúc Environments

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

## 6. Luồng phát triển tính năng mới

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

## 7. Troubleshooting

### Spring Boot không kết nối được MySQL
```bash
# Kiểm tra MySQL đang chạy
sudo systemctl status mysql

# Kiểm tra host, port và tên database
printf "%s:%s/%s\n" "$DB_HOST" "$DB_PORT" "$DB_NAME"
```

### MariaDB hoặc XAMPP báo sai kiểu JSON

Với MariaDB, điền thêm hai biến sau vào `server/.env` theo host, port và tên database thực tế.

```bash
DB_URL='jdbc:mariadb://localhost:3306/dvc_guide?timezone=UTC'
SPRING_JPA_DATABASE_PLATFORM=com.dvcguide.server.config.MariaDbJsonDialect
```

MariaDB lưu cột JSON bằng LONGTEXT. Driver MariaDB và dialect trên giúp Hibernate kiểm tra kiểu dữ liệu này khi khởi động. [Kiểu JSON của MariaDB](https://mariadb.com/docs/server/reference/data-types/string-data-types/json)

Trong thư mục `server/`, chạy lệnh sau; backend tự đọc lại `.env` mỗi lần khởi động.

```bash
mvn spring-boot:run
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
