# ImmoLink Pre-Commit Setup Guide

## 🚀 Automatisierte Qualitätsprüfungen

Pre-Commit Hooks führen automatisch folgende Checks durch:

1. **✨ Code Formatierung** - `dart format`
2. **🔍 Static Analysis** - `flutter analyze`
3. **🧪 Tests** - `flutter test`
4. **🧹 Unused Imports** - Automatische Erkennung und Entfernung

## Installation

### Husky Setup (Git Hooks)

```bash
cd ImmoLink
npm install husky --save-dev
npx husky init
```

Die `.husky/pre-commit` Datei ist bereits konfiguriert.

### Flutter Dependencies

```bash
cd immolink
flutter pub get
```

## Manuelle Commands

```bash
# Code formatieren
dart format .

# Analyze ausführen
flutter analyze

# Tests ausführen
flutter test

# Coverage generieren
flutter test --coverage

# Unused imports prüfen
dart run scripts/check_unused_imports.dart

# Unused imports fixen
dart run scripts/fix_unused_imports.dart
```

## CI/CD Integration

Die GitHub Actions Workflow `.github/workflows/flutter_ci.yml` führt bei jedem Push/PR folgendes durch:

- ✅ Flutter Analyze
- ✅ Code Format Check
- ✅ Unit Tests
- ✅ Integration Tests
- ✅ Coverage Report
- ✅ Build Test (Android APK)

## Test Coverage

Coverage Reports werden automatisch generiert und zu Codecov hochgeladen (optional).

### Lokale Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
# Öffne coverage/html/index.html im Browser
```

## Troubleshooting

### "Husky command not found"
```bash
npm install
```

### "Flutter analyze failed"
```bash
# Fixe automatisch fixierbare Issues
dart fix --apply

# Analysiere einzelne Datei
flutter analyze lib/specific_file.dart
```

### "Tests failed"
```bash
# Führe einzelnen Test aus
flutter test test/specific_test.dart

# Verbose Ausgabe
flutter test --verbose
```

## Best Practices

1. **Vor Commit**: Stelle sicher dass alle Tests lokal laufen
2. **Format**: Nutze `dart format .` vor jedem Commit
3. **Analyze**: Behebe analyzer warnings zeitnah
4. **Tests**: Schreibe Tests für neue Features
5. **Coverage**: Halte Code Coverage über 70%

## Integration mit IDE

### VS Code

Installiere Extensions:
- **Dart** - Offizielle Dart Extension
- **Flutter** - Offizielle Flutter Extension

Settings (`.vscode/settings.json`):
```json
{
  "dart.lineLength": 80,
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll": true
    }
  }
}
```

### Android Studio

1. **Preferences → Editor → Code Style → Dart**
   - Set line length: 80
2. **Enable**: Format on save
3. **Enable**: Optimize imports on save
