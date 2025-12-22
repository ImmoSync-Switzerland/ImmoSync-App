# ImmoLink (ImmoSync) 🏠

ImmoLink ist eine umfassende Immobilienverwaltungs-App für Android und Windows Desktop, die Vermieter-Mieter-Workflows mit Echtzeit-Chat, Zahlungsabwicklung und Dokumentenverwaltung ermöglicht.

## 🚀 Features

### Für Vermieter
- **Immobilienverwaltung**: Verwaltung mehrerer Immobilien mit detaillierten Informationen
- **Finanzübersicht**: Monatliche Einnahmen und ausstehende Zahlungen im Überblick
- **Mieter-Management**: Einladung und Verwaltung von Mietern
- **Dokumente**: Zentrale Dokumentenverwaltung mit Firebase Storage
- **Wartungsanfragen**: Verfolgung und Bearbeitung von Wartungstickets
- **Chat**: Ende-zu-Ende verschlüsselte Kommunikation via Matrix Protocol

### Für Mieter
- **Zahlungsübersicht**: Aktuelle und vergangene Mietzahlungen
- **Wartungsanfragen**: Erstellung und Verfolgung von Reparaturanfragen
- **Dokumentenzugriff**: Zugriff auf Mietverträge und wichtige Dokumente
- **Chat**: Direkte Kommunikation mit dem Vermieter

## 🛠 Tech Stack

- **Frontend**: Flutter 3.35.5 (Dart ≥3.6.0)
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Backend**: Node.js mit MongoDB
- **Authentication**: Firebase Auth (Email, Google Sign-In)
- **Database**: 
  - Firebase Firestore (Echtzeit-Synchronisation)
  - MongoDB (Backend-Datenbank)
  - Plattform-adaptive Abstraktionsschicht (Web → HTTP API, Mobile/Desktop → direkte MongoDB-Verbindung)
- **Chat**: Matrix Protocol mit E2EE (Matrix SDK + Flutter Rust Bridge für Desktop)
- **Zahlungen**: Stripe Integration
- **Push Notifications**: Firebase Cloud Messaging
- **Lokalisierung**: 4 Sprachen (Deutsch, Englisch, Französisch, Italienisch)

## 📋 Voraussetzungen

- Flutter SDK 3.35.5 oder höher
- Dart SDK ≥3.6.0
- Android Studio / Xcode (für mobile Entwicklung)
- Visual Studio 2022 (für Windows Desktop)
- Firebase-Projekt mit konfiguriertem `google-services.json`
- Node.js (für Backend-Entwicklung)

### iOS CI Signing (GitHub Actions)

Der Workflow `.github/workflows/ios_build.yml` erwartet diese Secrets:
- `IOS_CERT_P12_B64`: base64 der iOS Signing Certificate `.p12`
- `IOS_CERT_PASSWORD`: Passwort der `.p12`
- `IOS_PROVISIONING_PROFILE_B64`: base64 der `.mobileprovision`

Wenn der Import mit `SecKeychainItemImport: MAC verification failed during PKCS12 import` fehlschlaegt, ist meist `IOS_CERT_PASSWORD` falsch oder `IOS_CERT_P12_B64` ist nicht die vollstaendige base64 der binaeren `.p12`.

## 🔧 Installation & Setup

### 1. Repository klonen
```bash
git clone https://github.com/ImmoSync-Switzerland/ImmoSync-App.git
cd ImmoSync-App/immolink
```

### 2. Dependencies installieren
```bash
flutter pub get
```

### 3. Umgebungsvariablen konfigurieren

Erstellen Sie eine `.env` Datei im Root-Verzeichnis:
```env
API_URL=https://backend.immosync.ch/api
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB_NAME=immosync
```

### 4. Firebase konfigurieren

Platzieren Sie `google-services.json` in `android/app/`:
```json
{
  "project_info": {
    "project_number": "YOUR_PROJECT_NUMBER",
    "project_id": "YOUR_PROJECT_ID"
  },
  ...
}
```

Fuer iOS platzieren Sie `GoogleService-Info.plist` in `ios/Runner/` (nicht ins Repo committen).

CI (GitHub Actions) verwendet Secrets und schreibt die Datei waehrend des Builds nach `immolink/ios/Runner/GoogleService-Info.plist`.

### 5. App starten

**Android (Debug)**:
```powershell
flutter run --dart-define=API_URL=https://backend.immosync.ch/api `
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx `
  --dart-define=GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
```

**Android (Release APK)**:
```powershell
flutter build apk --release --split-per-abi `
  --dart-define=API_URL=https://backend.immosync.ch/api `
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_xxx `
  --dart-define=GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
```

**Windows Desktop**:
```powershell
flutter run -d windows
```

### Development Scripts

- `run_dev.bat` (Windows) / `run_dev.sh` (Unix): Lokale Entwicklung mit vordefinierten Variablen
- `debug_apk.bat`: Debug-APK mit Split per ABI erstellen

## 🏗 Projektstruktur

```
lib/
├── core/                          # Gemeinsame Funktionalität
│   ├── config/                   # Konfiguration (db_config.dart)
│   ├── routes/                   # App-Router (GoRouter)
│   ├── services/                 # Core Services (Database, Token Manager)
│   ├── providers/                # Globale Provider
│   └── widgets/                  # Wiederverwendbare Widgets
├── features/                      # Feature-basierte Struktur
│   ├── auth/                     # Authentifizierung
│   │   ├── domain/              # Models & Services
│   │   ├── infrastructure/      # Implementierungen
│   │   └── presentation/        # UI & Provider
│   ├── chat/                     # Matrix Chat
│   ├── property/                 # Immobilienverwaltung
│   ├── payment/                  # Stripe Zahlungen
│   ├── maintenance/              # Wartungsanfragen
│   ├── documents/                # Dokumentenverwaltung
│   ├── tenant/                   # Mieter-Features
│   ├── landlord/                 # Vermieter-Features
│   └── subscription/             # Abo-Management
├── l10n/                         # Lokalisierung (.arb Dateien)
└── main.dart                     # App Entry Point
```

## 🔐 Authentifizierung

Die App unterstützt mehrere Auth-Methoden:
- **Email/Passwort**: Standard Firebase Auth
- **Google Sign-In**: OAuth 2.0 Integration
- **Token-basiert**: JWT für Backend-API-Aufrufe

## 💬 Chat-System

Dual-Transport-Architektur:
1. **Matrix Protocol** (bevorzugt): E2EE Messaging
   - Desktop: Rust-basiertes Matrix SDK via Flutter Rust Bridge
   - Mobile: Dart `matrix` Package
2. **Legacy Socket.IO**: Fallback für nicht-migrierte Konversationen

## 💳 Stripe Integration

- **Zahlungsabwicklung**: Stripe Elements für sichere Karteneingabe
- **Abo-Management**: Verwaltung von Mieterabonnements
- **Stripe Terminal**: Support für physische Kartenlesegeräte (Android ≥20.34.0)

## 🌍 Lokalisierung

Unterstützte Sprachen:
- 🇩🇪 Deutsch (Primär)
- 🇬🇧 Englisch
- 🇫🇷 Französisch
- 🇮🇹 Italienisch

Generierung der Übersetzungen:
```bash
flutter gen-l10n
```

## 🧪 Testing

```bash
flutter test
```

## 📦 Build & Deployment

### Android APK (Split per ABI)
```bash
flutter build apk --release --split-per-abi
```
Ausgabe: `build/app/outputs/flutter-apk/`
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-x86_64-release.apk` (64-bit Intel)

### CI/CD (GitHub Actions)

Der Workflow `.github/workflows/android_build.yml` baut automatisch:
1. Validiert Stripe SDK Version (≥20.34.0)
2. Injiziert `google-services.json` aus Secrets
3. Baut Split-APKs
4. Veröffentlicht auf Download-Seite (optional)

Erforderliche GitHub Secrets:
- `GOOGLE_SERVICES_JSON`
- `CLIENT_API_URL`
- `STRIPE_PUBLISHABLE_KEY`
- `GOOGLE_CLIENT_ID`
- `SITE_REPO_PAT` (optional, für Deployment)

## 🐛 Troubleshooting

### Problem: "No routes for location /..."
**Lösung**: Full Restart erforderlich (R-Taste), Hot Reload reicht nicht für Router-Änderungen.

### Problem: Google Sign-In funktioniert nicht
**Lösung**: 
1. Firebase Console → Authentication → Sign-in method → Google aktivieren
2. SHA-1 Fingerprint registrieren:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey
   ```
3. OAuth Web Client ID in `--dart-define` angeben

### Problem: "currentPeriodEnd" zeigt 1.1.1970
**Lösung**: Backend sendet ungültiges Datum. Die App erkennt dies jetzt und berechnet einen Fallback basierend auf Startdatum + Billing-Intervall.

### Problem: Matrix Chat verbindet nicht
**Lösung**: 
1. DTD (Dart Tooling Daemon) URI überprüfen
2. `ensureMatrixReady()` Logs überprüfen
3. 2-3 Sekunden Sync-Zeit nach Init einplanen

## 📄 Lizenz

Copyright © 2025 ImmoSync Switzerland

## 🤝 Contributing

Contributions sind willkommen! Bitte erstellen Sie ein Issue oder Pull Request.

## 📧 Kontakt

Bei Fragen oder Support: [Ihre Kontaktinformationen]

---

**Hinweis**: Dies ist ein aktives Entwicklungsprojekt. Features und API können sich ändern.
