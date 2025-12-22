# ImmoSync

A modern multi-platform (Android / Windows desktop WIP) property management application built with Flutter and a Node.js backend. It connects landlords and tenants with real‑time chat, maintenance workflows, documents and payments.

## Features

- **User Authentication**

  - Secure login/registration system
  - Role-based access (Landlord/Tenant)
  - Session management
- **Landlord Dashboard**

  - Property portfolio overview
  - Tenant management
  - Rent collection tracking
  - Maintenance request handling
  - Financial analytics
- **Tenant Dashboard**

  - Rent payment system
  - Maintenance request submission
  - Property information
  - Communication with landlord
  - Payment history

## Tech Stack

| Layer                   | Technology                                            |
| ----------------------- | ----------------------------------------------------- |
| Mobile / Desktop Client | Flutter (Dart), Riverpod, GoRouter                    |
| Authentication          | Firebase Auth + (2FA routes in backend)               |
| Payments                | Stripe (stripe-android SDK ≥ 20.34.0, Connect WIP)   |
| Realtime Chat           | Matrix (provisioning scripts + custom chat store)     |
| Backend API             | Node.js + Express                                     |
| Database                | MongoDB (core domain) + DynamoDB (chat store variant) |
| Storage                 | Firebase Storage (attachments / images)               |
| CI/CD                   | GitHub Actions (apk build + release + site publish)   |

> See `backend/` and `ImmoSync/` directories for server and Flutter sources respectively.

## Getting Started (Client)

### Quick Setup (Recommended)

Run the automated setup script to initialize your development environment:

**Windows (PowerShell)**:
```powershell
.\setup.ps1
```

**Linux/macOS**:
```bash
chmod +x setup.sh
./setup.sh
```

The script will:
- ✅ Validate Flutter installation
- ✅ Check Dart version (≥3.6 required)
- ✅ Install dependencies
- ✅ Set up Git hooks (pre-commit automation)
- ✅ Run tests to verify setup
- ✅ Display environment summary

### Manual Setup

1. Clone the repository:

```bash
  git clone https://github.com/ImmoSync-Switzerland/ImmoSync-App.git
  cd ImmoSync/immolink
```

2. Install Flutter dependencies:

```bash
  flutter pub get
```

3. Install Git hooks (pre-commit quality checks):

```bash
  cd ..
  npm install  # Installs Husky
```

4. (Optional) Regenerate localization after edits:

```bash
  flutter gen-l10n
```

5. Provide required runtime defines when building manually (match CI):

```bash
  flutter run \
    --dart-define=API_URL=https://api.example.com \
    --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_xxx \
    --dart-define=GOOGLE_CLIENT_ID=clientid.apps.googleusercontent.com
```

6. Build a release split APK locally:

```bash
  flutter build apk --release --split-per-abi \
    --dart-define=API_URL=... \
    --dart-define=STRIPE_PUBLISHABLE_KEY=... \
    --dart-define=GOOGLE_CLIENT_ID=...
```

## Development Workflow

### Pre-Commit Quality Automation

Git hooks automatically run on every commit:

1. **✨ Code Format** - `dart format` with auto-fix
2. **🔍 Static Analysis** - `flutter analyze --fatal-infos`
3. **🧪 Tests** - `flutter test --coverage`
4. **🧹 Unused Imports** - Auto-detection and removal

**Manual commands**:
```bash
dart format .                                    # Format code
flutter analyze                                  # Static analysis
flutter test                                     # Run tests
dart run scripts/check_unused_imports.dart       # Check imports
dart run scripts/fix_unused_imports.dart         # Fix imports
```

See [`.github/PRECOMMIT_GUIDE.md`](.github/PRECOMMIT_GUIDE.md) for detailed setup instructions.

### Testing

We maintain comprehensive test coverage across all features:

```bash
# Run all tests
flutter test

# Run with coverage report
flutter test --coverage

# Run specific feature tests
flutter test test/features/auth_test.dart
flutter test test/features/property_test.dart
flutter test test/features/chat_test.dart

# Run integration tests
flutter test integration_test/
```

**Test Structure**:
- `test/features/` - Unit tests for domain features
  - `auth_test.dart` - Authentication flows
  - `property_test.dart` - Property management
  - `chat_test.dart` - Matrix E2EE messaging
  - `payment_test.dart` - Stripe payments
  - `maintenance_test.dart` - Maintenance requests
  - `document_test.dart` - Document management
- `integration_test/` - End-to-end integration tests

**Coverage Goals**: ≥70% overall, ≥80% for models, ≥75% for services

See [`.github/TESTING_GUIDE.md`](.github/TESTING_GUIDE.md) for comprehensive testing documentation.

## Backend Quick Start

1. Copy `backend/config.example.js` to `backend/config.js` and adjust values.
2. Provision MongoDB & (optional) DynamoDB resources.
3. Install dependencies & start:

```bash
  cd backend
  npm install
  node server.js
```

4. Run schema / data helper scripts (see `backend/scripts/`).

## Environment & Secrets

| Context                     | Variable / Secret                                        | Purpose                                       |
| --------------------------- | -------------------------------------------------------- | --------------------------------------------- |
| Flutter build (dart-define) | `API_URL`                                              | Backend base URL                              |
| Flutter build (dart-define) | `STRIPE_PUBLISHABLE_KEY`                               | Stripe publishable key                        |
| Flutter build (dart-define) | `GOOGLE_CLIENT_ID`                                     | Google Sign-In / oAuth usage                  |
| GitHub Actions Secret       | `GOOGLE_SERVICES_JSON` or `GOOGLE_SERVICES_JSON_B64` | Android `google-services.json` provisioning |
| GitHub Actions Secret       | `GOOGLE_SERVICE_INFO_PLIST` or `GOOGLE_SERVICE_INFO_PLIST_B64` | iOS `GoogleService-Info.plist` provisioning |
| GitHub Actions Secret       | `IOS_CERT_P12_B64`                                      | Base64 `.p12` signing cert (with private key) |
| GitHub Actions Secret       | `IOS_CERT_PASSWORD`                                     | Password for the `.p12`                      |
| GitHub Actions Secret       | `IOS_PROVISIONING_PROFILE_B64`                          | Base64 `.mobileprovision` profile            |
| GitHub Actions Secret       | `IOS_DEVELOPMENT_TEAM`                                  | Apple team ID (must match provisioning profile) |
| GitHub Actions Secret       | `IOS_BUNDLE_IDENTIFIER`                                 | Bundle identifier (must match provisioning profile) |
| GitHub Actions Secret       | `IOS_EXPORT_OPTIONS_PLIST` (optional)                   | Full `export-options.plist` override for `xcodebuild -exportArchive` |
| GitHub Actions Secret       | `IOS_EXPORT_METHOD` (optional)                          | Export method override (`app-store`, `ad-hoc`, `enterprise`, `development`) |
| GitHub Actions Secret       | `SITE_REPO_PAT`                                        | Token to push generated APKs to website repo  |
| Backend config              | `MONGODB_URI`                                          | Mongo connection string                       |
| Backend config              | `MONGODB_DB_NAME`                                      | Mongo database name                           |

Android google services: create a Firebase project → download `google-services.json` (Android) → set one of the secrets above; CI writes it inside `ImmoSync/android/app` before build.

## CI / CD Pipeline Overview

### Quality Assurance Workflow (`.github/workflows/flutter_ci.yml`)

Runs on every push and pull request to enforce code quality:

**Jobs**:

1. **test** - Run all unit and integration tests with coverage reporting
   - Executes `flutter test --coverage`
   - Uploads coverage to Codecov
   - Generates coverage summary comment on PRs

2. **analyze** - Static code analysis
   - Runs `flutter analyze --fatal-infos`
   - Checks code formatting with `dart format`
   - Enforces 60+ lint rules from `analysis_options.yaml`

3. **build-test** - Validate build process
   - Builds debug APK to catch build issues early
   - Runs on Ubuntu with Java 17 + Flutter 3.35.5

### Android Build & Release Workflow (`.github/workflows/android_build.yml`)

Jobs:

1. **build-apk** – Sets up Flutter + JDK, validates Stripe SDK minimum version, builds split ABI release APKs, normalizes filenames, uploads a single artifact named `immosync-apk` containing:

- `immosync-<version>.apk` (primary / universal or chosen ABI)
- `immosync-<version>-<abi>.apk` (per ABI splits)
- `immosync-latest.apk` alias
- `BUILD_METADATA.txt` summary

2. **publish-github-release** – Downloads artifact, ensures main alias, creates/updates GitHub Release tag `v<version>` with the primary + latest APK.
3. **publish-to-site-repo** – Checks out web repo (`FabianBoni/immosync.ch`) in `site/`, downloads artifact into `site/apk`, publishes to `public/downloads/` (versioned + latest + checksums + manifest + HTML index) then commits.

Artifact naming is constant (no version in artifact name) → download always uses `immosync-apk` to avoid mismatches.

### Generated Site Files

In the site repo under `public/downloads/`:

- `immosync-<version>.apk`
- `immosync-latest.apk`
- `<apk>.sha256` checksum files
- `manifest.json` with version listing & timestamp
- `index.html` simple directory index page

## Versioning

App version is read from `ImmoSync/pubspec.yaml` (`version:`). That raw string (e.g. `1.0.0+1`) is used for file naming. If introducing build metadata with characters that are problematic for shell/glob patterns, prefer restrict to `[0-9A-Za-z.+-]`.

## Troubleshooting

| Symptom                                          | Likely Cause                                                    | Fix                                                           |
| ------------------------------------------------ | --------------------------------------------------------------- | ------------------------------------------------------------- |
| Missing `apk` directory in publish-to-site job | Checkout overwrote earlier download (fixed in current workflow) | Ensure download happens after checkout into subfolder.        |
| `No APK candidates found`                      | Build failed or artifact upload empty                           | Inspect build-apk job logs around "Collect APKs" step.        |
| `stripe-android version below required`        | Outdated transitive dependency                                  | Bump dependency or resolve version conflict until ≥ 20.34.0. |
| `google-services.json missing expected key`    | Wrong secret (firebase config instead)                          | Provide actual Android `google-services.json`.              |
| Release shows wrong version                      | pubspec version not updated pre-push                            | Update `pubspec.yaml` then push/tag.                        |

## Future Enhancements

- Add Android App Bundle (AAB) build + upload
- Integrate code signing & verify checksums in Release assets
- Automate semantic version bump & changelog generation
- Include Windows binary packaging once stable

## License

TBD (add a LICENSE file – e.g., MIT or Apache-2.0) if open sourcing.

---

For questions or contributions open an issue or submit a PR.
