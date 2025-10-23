# ImmoLink/ImmoSync AI Coding Agent Instructions

## Project Overview
ImmoLink (formerly ImmoSync) is a Flutter-based property management app (Android + Windows desktop) with a Node.js backend. It enables landlord-tenant workflows including real-time chat (Matrix protocol), payments (Stripe), document management, and maintenance tracking.

**Key Tech Stack**: Flutter 3.35.5 (Dart ≥3.6), Riverpod state management, GoRouter navigation, Firebase (Auth + Firestore + Storage + Messaging), Matrix SDK (E2EE chat), Stripe (payments), MongoDB backend.

## Architecture & Critical Patterns

### Feature-Based Structure
Code organized by domain features under `lib/features/`:
- `auth/`, `chat/`, `property/`, `payment/`, `maintenance/`, `tenant/`, `landlord/`, `documents/`, etc.
- Each feature follows layered structure: `domain/` (models, services) → `infrastructure/` (implementations) → `presentation/` (providers, pages, widgets)
- **Core principle**: Features are loosely coupled; cross-feature dependencies go through providers or shared services in `lib/core/`

### State Management with Riverpod
- **Provider Pattern**: All state exposed via Riverpod providers (see `lib/features/*/presentation/providers/*.dart`)
- Common provider types:
  - `Provider<T>` for services (e.g., `chatServiceProvider`, `propertyServiceProvider`)
  - `StateNotifierProvider` for mutable state (e.g., `conversationMessagesProvider`)
  - `FutureProvider` / `StreamProvider` for async data (e.g., `propertiesProvider`, `landlordPropertiesProvider`)
  - `.family` modifiers for parameterized providers (e.g., `conversationMessagesProvider.family<String>`)
- **Usage**: Always use `ref.watch()` in build methods, `ref.read()` in event handlers/callbacks
- **Global providers**: `authProvider`, `currentUserProvider`, `routerProvider` accessed across features

### Multi-Platform Database Abstraction
The app adapts database access based on platform (`lib/core/services/database_service.dart`):
- **Web**: `WebDatabaseService` proxies all operations to backend API via HTTP
- **Mobile/Desktop**: `MobileDatabaseService` uses direct `mongo_dart` connection
- **Implementation**: Both implement `IDatabaseService` interface with `query()`, `insert()`, `update()`, `delete()` methods
- **Convention**: Never import platform-specific services directly; use `DatabaseService.instance`

### Dual Chat Backend (Matrix + Legacy Socket.IO)
Chat system supports two transports:
1. **Matrix Protocol** (preferred): E2EE messaging via `matrix` package + `flutter_rust_bridge` for desktop platforms
   - Entry point: `lib/features/chat/infrastructure/matrix_chat_service.dart`
   - Platform detection: Uses Rust bridge on Windows/Linux/macOS, mobile Matrix client (`mobile_matrix_client.dart`) on Android/iOS
   - Room mapping: Backend stores `conversationId → matrixRoomId` mapping; resolved via `getMatrixRoomIdForConversation()`
   - Timeline subscription: `MatrixTimelineService` wraps Matrix sync events into app's `ChatMessage` model
2. **Legacy Socket.IO**: Fallback for unmigrated conversations (`http_chat_service.dart`)

**Chat provider workflow** (`messages_provider.dart`):
- On init, waits for user auth → calls `ensureMatrixReady()` → resolves Matrix roomId → subscribes to timeline
- Falls back to legacy if no Matrix room mapping exists
- Messages sent via `MessageSenderNotifier` which routes to appropriate transport

### Configuration System (Runtime .env + Compile-Time --dart-define)
**Preference order**: Runtime `.env` file > `--dart-define` build args > hardcoded defaults

Key config (`lib/core/config/db_config.dart`):
- `API_URL`: Backend base URL (default: `https://backend.immosync.ch/api`)
- `STRIPE_PUBLISHABLE_KEY`: Stripe public key for payment UI
- `GOOGLE_CLIENT_ID`: OAuth client ID for Google Sign-In
- `MONGODB_URI`, `MONGODB_DB_NAME`: Direct DB connection (mobile/desktop only)
- `WS_URL`: WebSocket endpoint (auto-derived from `API_URL` if not set)

**CI/CD usage**: GitHub Actions passes secrets via `--dart-define` flags (see `.github/workflows/android_build.yml`)

### Routing & Navigation
- **Router**: GoRouter configured in `lib/core/routes/app_router.dart` with `routerProvider`
- **Auth guard**: Router watches `authProvider` to redirect unauthenticated users to `/login`
- **Localization constraint**: Auth pages wrapped in `_GermanOnly` widget (forces `de` locale for registration flows)
- **Deep linking**: Routes defined with named paths (e.g., `/property/:id`, `/chat/:conversationId`)

### Model Patterns & Defensive Parsing
Domain models include defensive parsing to handle legacy/incomplete backend data:

```dart
// Example from lib/features/property/domain/models/property.dart
factory Property.fromMap(Map<String, dynamic> map) {
  try {
    return Property(
      id: (map['_id'] ?? map['id'] ?? '').toString(),
      landlordId: (map['landlordId'] ?? '').toString(),
      // ... parse with fallbacks
    );
  } catch (e, st) {
    print('[Property.fromMap][ERROR] $e');
    // Return safe fallback instance to keep UI resilient
    return Property(/* minimal valid state */);
  }
}
```

**Convention**: Always provide fallback values for optional fields; log parse errors with `[ModelName.fromMap][ERROR]` prefix.

## Development Workflows

### Building & Running
**Local development**:
```powershell
cd immolink
flutter pub get
flutter run --dart-define=API_URL=https://backend.immosync.ch/api `
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx `
  --dart-define=GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
```

**Release APK** (split per ABI):
```powershell
flutter build apk --release --split-per-abi `
  --dart-define=API_URL=... --dart-define=STRIPE_PUBLISHABLE_KEY=... --dart-define=GOOGLE_CLIENT_ID=...
```

**CI pipeline** (`.github/workflows/android_build.yml`):
- Validates Stripe SDK version ≥20.34.0 (required for Stripe Terminal compatibility)
- Writes `google-services.json` from GitHub secret before build
- Produces split APKs, uploads to artifact, optionally publishes to download site via `SITE_REPO_PAT`

### Testing
- **Unit tests**: Standard Flutter test setup in `test/` directory
- **Run tests**: `flutter test` (from `immolink/` directory)
- **Example**: `test/widget_test.dart` validates initial app render and page structure
- **Convention**: Use `ProviderScope` wrapper for tests involving Riverpod providers

### Localization
- **System**: Flutter's `intl` + generated `AppLocalizations` (`lib/l10n/`)
- **Languages**: German (primary), English (partial support)
- **Generate translations**: `flutter gen-l10n` after editing `.arb` files
- **Access**: `AppLocalizations.of(context)!.translationKey` (helper: `lib/l10n_helper.dart`)

### Matrix/Rust Bridge Integration (WIP)
**Status**: Scaffold in place (`native/matrix_bridge/`), bindings generated via `flutter_rust_bridge_codegen`
- **Desktop platforms** (Windows/Linux/macOS): Use Rust-based Matrix SDK via FRB
- **Mobile platforms**: Use Dart `matrix` package directly (`mobile_matrix_client.dart`)
- **Generated code**: `lib/frb_generated.dart`, `lib/bridge_generated.dart/`
- **Rebuild bindings**: See `native/README_RUST_MATRIX.md` and `native/MATRIX_RUST_SDK_INTEGRATION.md`

**Important**: Always call `RustLib.init()` in `main.dart` before using any FRB methods (currently guarded by platform check)

## Project-Specific Conventions

### Error Handling & Logging
- **Debug prints**: Use `debugPrint()` (not `print()`) for release-safe logging
- **Structured prefixes**: `[ComponentName] message` or `[Feature.method] message` (e.g., `[MessagesProvider] Matrix ready`)
- **Error context**: Log exceptions with stack traces; include raw data in parse errors for debugging

### Async Patterns
- **Initialization sequences**: Chain async operations in `main.dart` with explicit ordering (see Firebase → Stripe → FRB → DB connect sequence)
- **Timeout guards**: Use `Future.delayed` + retry loops when waiting for dependent state (e.g., auth user loading in `messages_provider.dart`)
- **Background isolates**: Avoid; all heavy work on main isolate (MongoDB operations are async but single-threaded)

### File Naming
- **Pages**: `*_page.dart` (e.g., `login_page.dart`, `property_details_page.dart`)
- **Providers**: `*_provider.dart` or `*_providers.dart` for collections
- **Services**: `*_service.dart` (e.g., `auth_service.dart`, `database_service.dart`)
- **Models**: Plain names in `domain/models/` (e.g., `property.dart`, `user.dart`)

### Git & Repository
- **Main branch**: `main` (protected; CI runs on push)
- **Ignored paths**: `public/downloads/**` (APK artifacts published separately)
- **Repo structure**: Multi-module monorepo (Flutter app: `immolink/`, backend: `backend/`, scripts: `scripts/`)

## Common Pitfalls & Gotchas

1. **API_URL on mobile APK**: If pointing to `localhost`, device cannot reach backend. Always use network-accessible URL or backend.immosync.ch in production builds.
2. **Matrix sync delay**: After `ensureMatrixReady()`, allow 2-3 seconds before reading timeline to let initial sync complete.
3. **Provider disposal**: `.family` and `.autoDispose` providers cleaned up automatically; avoid manual state management.
4. **Google Sign-In**: Requires `GOOGLE_CLIENT_ID` dart-define; falls back gracefully with error message if missing.
5. **Stripe version**: CI enforces `stripe-android ≥20.34.0`; check `dependency-tree.txt` artifact if build fails.
6. **Windows line endings**: `gradlew` may have CRLF endings when committed from Windows; CI normalizes to LF automatically.

## Key Files Reference
- **App entry**: `lib/main.dart` (initialization sequence, error hooks, app wrapper)
- **Router**: `lib/core/routes/app_router.dart` (all navigation routes)
- **Config**: `lib/core/config/db_config.dart` (environment-aware settings)
- **Auth state**: `lib/features/auth/presentation/providers/auth_provider.dart`
- **Chat orchestration**: `lib/features/chat/presentation/providers/messages_provider.dart`
- **Database abstraction**: `lib/core/services/database_service.dart` + `database_interface.dart`
- **CI workflow**: `.github/workflows/android_build.yml`

## When Making Changes
- **Adding features**: Create new feature directory under `lib/features/` with domain → infrastructure → presentation layers
- **New providers**: Define in feature's `presentation/providers/`, export from barrel file if needed
- **Config changes**: Update both `.env` fallback and dart-define handling in `db_config.dart`
- **Chat modifications**: Be aware of dual transport; test with both Matrix-enabled and legacy conversations
- **Breaking model changes**: Add defensive parsing + fallback to maintain backward compatibility with existing backend data
