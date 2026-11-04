# Cấu trúc dự án – DVC Guide

## Monorepo Overview

```
dvc-guide/
├── mobile/          # Flutter mobile application
├── server/          # Spring Boot backend API
├── ai-service/      # Python FastAPI + Ollama RAG service (tương lai)
├── docs/            # Tài liệu dự án
├── infrastructure/  # Cấu hình hạ tầng (tương lai)
├── .gitignore
└── README.md
```

---

## `mobile/` – Flutter App

```
mobile/
├── lib/
│   ├── main.dart                    # Entry point, ProviderScope
│   ├── app/
│   │   ├── app.dart                 # MaterialApp.router root
│   │   ├── router/
│   │   │   └── app_router.dart      # go_router configuration
│   │   ├── theme/
│   │   │   ├── app_theme.dart       # ThemeData Material 3
│   │   │   ├── app_colors.dart      # Color palette
│   │   │   └── app_text_styles.dart # Text styles
│   │   └── providers/               # App-level providers
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart   # Base URL, timeouts, app config
│   │   ├── network/
│   │   │   ├── api_client.dart      # Dio singleton với interceptors
│   │   │   ├── api_endpoints.dart   # URL path constants
│   │   │   └── interceptors/
│   │   │       ├── auth_interceptor.dart  # JWT header (tương lai)
│   │   │       └── error_interceptor.dart # Xử lý lỗi HTTP
│   │   ├── error/
│   │   │   ├── app_exception.dart   # Custom exception classes
│   │   │   └── failure.dart         # Failure sealed classes
│   │   ├── storage/                 # Local storage (flutter_secure_storage)
│   │   ├── utils/                   # Helper functions
│   │   └── widgets/                 # Core reusable widgets
│   └── shared/
│       ├── models/                  # Shared data models
│       ├── widgets/                 # Shared UI components
│       └── enums/                   # Shared enums
└── pubspec.yaml
```

### Quy tắc thư mục Feature (tương lai)

Khi thêm feature mới (ví dụ: `procedure`):
```
lib/features/procedure/
├── data/
│   ├── datasources/     # API calls, local cache
│   ├── models/          # JSON models (freezed)
│   └── repositories/    # Repository implementations
├── domain/
│   └── repositories/    # Repository interfaces (abstract)
├── presentation/
│   ├── screens/         # Widget screens
│   ├── widgets/         # Feature-specific widgets
│   └── viewmodels/      # Riverpod Notifiers
```

---

## `server/` – Spring Boot Backend

```
server/
├── src/
│   ├── main/
│   │   ├── java/com/dvcguide/server/
│   │   │   ├── DvcGuideApplication.java   # @SpringBootApplication
│   │   │   ├── config/
│   │   │   │   ├── CorsConfig.java        # CORS configuration
│   │   │   │   ├── OpenApiConfig.java     # Swagger/OpenAPI 3
│   │   │   │   ├── ApplicationConfig.java # Bean definitions
│   │   │   │   └── SecurityConfig.java    # Spring Security (stub)
│   │   │   ├── common/
│   │   │   │   ├── response/
│   │   │   │   │   └── ApiResponse.java   # Standard API wrapper
│   │   │   │   ├── exception/
│   │   │   │   │   ├── GlobalExceptionHandler.java
│   │   │   │   │   └── ResourceNotFoundException.java
│   │   │   │   ├── constant/              # App constants
│   │   │   │   └── util/                 # Utility classes
│   │   │   ├── integration/
│   │   │   │   ├── ai/
│   │   │   │   │   └── AiServiceClient.java  # AI service interface
│   │   │   │   └── rag/
│   │   │   │       └── RagServiceClient.java # RAG service interface
│   │   │   └── health/
│   │   │       └── HealthController.java  # GET /api/v1/health
│   │   └── resources/
│   │       ├── application.yml            # Base config
│   │       ├── application-dev.yml        # Development overrides
│   │       └── application-prod.yml       # Production overrides
│   └── test/
│       └── java/com/dvcguide/server/
│           ├── health/
│           │   └── HealthControllerTest.java
│           └── common/exception/
│               └── GlobalExceptionHandlerTest.java
├── pom.xml
└── .env.example
```

### Quy tắc thư mục Feature (tương lai)

Khi thêm feature mới (ví dụ: `procedure`):
```
com.dvcguide.server.procedure/
├── controller/      # @RestController, @RequestMapping
├── service/         # @Service, business logic
├── repository/      # @Repository extends JpaRepository
├── entity/          # @Entity, @Table
└── dto/
    ├── request/     # @Valid request bodies
    └── response/    # Response DTOs
```

---

## `ai-service/` – Python FastAPI (Skeleton)

```
ai-service/
├── app/
│   ├── main.py                # FastAPI app, lifespan, routers
│   ├── api/
│   │   └── v1/               # API v1 routers (tương lai)
│   ├── core/
│   │   └── config.py         # Pydantic Settings từ .env
│   ├── schemas/              # Pydantic request/response models
│   ├── services/             # Business logic (RAG pipeline)
│   └── integrations/
│       └── ollama/           # Ollama client (tương lai)
├── tests/
├── requirements.txt
├── .env.example
└── README.md
```

---

## `docs/` – Tài liệu

| File | Nội dung |
|------|---------|
| `architecture.md` | Kiến trúc tổng thể, sơ đồ luồng |
| `project-structure.md` | File này – mô tả vai trò thư mục |
| `coding-conventions.md` | Quy tắc đặt tên, code style |
| `development-guide.md` | Hướng dẫn setup và chạy local |

---

## `infrastructure/` – Hạ tầng (Tương lai)

Sẽ chứa: Docker Compose, Kubernetes configs, CI/CD pipeline configs.
