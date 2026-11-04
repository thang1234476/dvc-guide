# Quy tắc Coding – DVC Guide

## 1. Ngôn ngữ viết code

- **Comments trong code:** Tiếng Anh (class, method, variable comments)
- **Commit messages:** Tiếng Anh, theo Conventional Commits
- **Tài liệu (docs/):** Tiếng Việt
- **Tên biến/hàm/class:** Tiếng Anh

---

## 2. Java / Spring Boot

### Đặt tên

| Thành phần | Convention | Ví dụ |
|-----------|-----------|-------|
| Package | `snake_case` lowercase | `com.dvcguide.server.procedure` |
| Class | `PascalCase` | `ProcedureController` |
| Interface | `PascalCase` | `ProcedureRepository` |
| Method | `camelCase` | `findProcedureById()` |
| Variable | `camelCase` | `procedureId` |
| Constant | `UPPER_SNAKE_CASE` | `MAX_PAGE_SIZE` |
| Enum | `PascalCase` + `UPPER_SNAKE_CASE` values | `ProcedureStatus.ACTIVE` |

### Controller Rules
```java
// ✅ Đúng
@RestController
@RequestMapping("/api/v1/procedures")
public class ProcedureController {

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ProcedureDto>> getById(@PathVariable Long id) {
        // Chỉ nhận request, delegate sang Service
        return ResponseEntity.ok(ApiResponse.success(service.findById(id)));
    }
}

// ❌ Sai – Logic nghiệp vụ trong Controller
@GetMapping("/{id}")
public ResponseEntity<?> getById(@PathVariable Long id) {
    Procedure p = repository.findById(id).orElseThrow(...); // WRONG
    return ResponseEntity.ok(p);
}
```

### Service Rules
```java
// ✅ Đúng – Interface + Implementation
public interface ProcedureService {
    ProcedureDto findById(Long id);
}

@Service
@RequiredArgsConstructor  // Lombok
public class ProcedureServiceImpl implements ProcedureService {
    private final ProcedureRepository repository;

    @Override
    public ProcedureDto findById(Long id) {
        return repository.findById(id)
            .map(this::toDto)
            .orElseThrow(() -> new ResourceNotFoundException("Procedure", id));
    }
}
```

### DTO Rules
- Request DTO: `@Valid` annotations, tên dạng `CreateProcedureRequest`
- Response DTO: tên dạng `ProcedureResponse` hoặc `ProcedureDto`
- Không dùng Entity trực tiếp trong API response

### Entity Rules
```java
@Entity
@Table(name = "procedures")
@Getter @Setter @NoArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class Procedure {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
```

---

## 3. Flutter / Dart

### Đặt tên

| Thành phần | Convention | Ví dụ |
|-----------|-----------|-------|
| File | `snake_case.dart` | `procedure_list_screen.dart` |
| Class | `PascalCase` | `ProcedureListScreen` |
| Variable/Method | `camelCase` | `procedureList` |
| Constant | `camelCase` (lowerCamelCase) | `defaultTimeout` |
| Enum | `PascalCase` | `LoadingState` |
| Enum value | `camelCase` | `LoadingState.loading` |

### Widget Rules
```dart
// ✅ View chỉ hiển thị, không chứa logic
class ProcedureListScreen extends ConsumerWidget {
  const ProcedureListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(procedureListViewModelProvider);
    return state.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => ErrorDisplay(message: e.toString()),
      data: (list) => ProcedureListView(items: list),
    );
  }
}
```

### ViewModel Rules
```dart
// ✅ ViewModel kế thừa AsyncNotifier
@riverpod
class ProcedureListViewModel extends _$ProcedureListViewModel {
  @override
  Future<List<ProcedureModel>> build() async {
    return ref.read(procedureRepositoryProvider).getAll();
  }
}
```

### File Organization
- Mỗi screen có file riêng
- Tránh file > 300 dòng
- Import theo thứ tự: dart → flutter → packages → local

---

## 4. Commit Messages (Conventional Commits)

```
feat: add procedure list screen
fix: correct API base URL for Android emulator
refactor: extract error handling to interceptor
docs: update development guide
test: add health controller unit test
chore: update dependencies
```

### Scope (tùy chọn)
```
feat(mobile): implement go_router navigation
feat(server): add health check endpoint
fix(ai-service): correct config loading
```

---

## 5. API Naming

- Base path: `/api/v1/`
- Resource plural: `/api/v1/procedures`
- Actions: dùng HTTP verbs, không dùng verb trong URL
  - `GET /api/v1/procedures` – list
  - `GET /api/v1/procedures/{id}` – get one
  - `POST /api/v1/procedures` – create
  - `PUT /api/v1/procedures/{id}` – update
  - `DELETE /api/v1/procedures/{id}` – delete

---

## 6. Environment Variables

- **Không hardcode** credentials, API keys, URLs trong source code
- Dùng `.env.example` làm template, **không commit** `.env`
- Spring Boot: `${ENV_VAR_NAME:default}` trong `application.yml`
- Flutter: `--dart-define=KEY=value`
- Python: Pydantic `BaseSettings` đọc từ `.env`
