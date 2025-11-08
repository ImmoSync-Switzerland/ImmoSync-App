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

1. Clone the repository:

```bash
  git clone https://github.com/ImmoSync-Switzerland/ImmoSync-App.git
  cd ImmoSync/ImmoSync
```

2. Install Flutter dependencies:

```bash
  flutter pub get
```

3. (Optional) Regenerate localization after edits:

```bash
  flutter gen-l10n
```

4. Provide required runtime defines when building manually (match CI):

```bash
  flutter run \
    --dart-define=API_URL=https://api.example.com \
    --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_xxx \
    --dart-define=GOOGLE_CLIENT_ID=clientid.apps.googleusercontent.com
```

5. Build a release split APK locally:

```bash
  flutter build apk --release --split-per-abi \
    --dart-define=API_URL=... \
    --dart-define=STRIPE_PUBLISHABLE_KEY=... \
    --dart-define=GOOGLE_CLIENT_ID=...
```

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
| GitHub Actions Secret       | `SITE_REPO_PAT`                                        | Token to push generated APKs to website repo  |
| Backend config              | `MONGODB_URI`                                          | Mongo connection string                       |
| Backend config              | `MONGODB_DB_NAME`                                      | Mongo database name                           |

Android google services: create a Firebase project → download `google-services.json` (Android) → set one of the secrets above; CI writes it inside `ImmoSync/android/app` before build.

## CI / CD Pipeline Overview

Workflow file: `.github/workflows/android_build.yml`

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
