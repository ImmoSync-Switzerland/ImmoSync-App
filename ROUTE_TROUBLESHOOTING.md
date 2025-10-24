# Route Test & Troubleshooting

## Problem
`GoException: no routes for location: /landlord/payments`

## Ursache
GoRouter lädt die Routen beim App-Start. Änderungen an Routen erfordern einen **vollständigen App-Neustart** (Hot Reload/Hot Restart reicht nicht aus).

## Lösung

### Option 1: Vollständiger Neustart (Empfohlen)
```bash
# Im Terminal:
cd d:\GitHub\ImmoLink\immolink

# App stoppen (falls sie läuft)
# Drücke 'q' im Flutter Terminal

# Neu starten
flutter run -d windows --dart-define=API_URL=https://backend.immosync.ch/api
```

### Option 2: Hot Restart
Falls die App läuft:
1. Drücke `R` (Shift+R) im Flutter Terminal
2. Warte auf "Restarted application"
3. Versuche erneut die Route

### Option 3: Code-Verifizierung

**Prüfe, ob die Route existiert:**
```dart
// In app_router.dart (Zeile 173-177):
GoRoute(
  path: '/landlord/payments',
  builder: (context, state) => const LandlordPaymentsPage(),
),
```

**Prüfe den Import:**
```dart
// In app_router.dart (Zeile 41):
import 'package:immosync/features/payment/presentation/pages/landlord_payments_page.dart';
```

**Prüfe die Navigation:**
```dart
// In landlord_dashboard.dart (Zeile 699):
context.push('/landlord/payments');
```

## Verifikation

Nach dem Neustart sollte:
1. ✅ Quick Action "Zahlungen" im Dashboard sichtbar sein
2. ✅ Klick auf "Zahlungen" öffnet die Payments-Seite
3. ✅ Keine GoException mehr

## Debugging

Falls das Problem weiterhin besteht:

### 1. Überprüfe Router-Registrierung
```dart
// In app_router.dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      // ... alle Routen
      GoRoute(
        path: '/landlord/payments',  // <- Muss hier sein
        builder: (context, state) => const LandlordPaymentsPage(),
      ),
    ],
  );
});
```

### 2. Überprüfe Provider
```dart
// In main.dart oder wo auch immer der Router verwendet wird
final router = ref.watch(routerProvider);
MaterialApp.router(
  routerConfig: router,  // <- Router muss übergeben werden
);
```

### 3. Teste Route direkt
```dart
// Temporär in einem Button:
ElevatedButton(
  onPressed: () {
    try {
      context.go('/landlord/payments');
      print('Navigation erfolgreich!');
    } catch (e) {
      print('Navigation fehlgeschlagen: $e');
    }
  },
  child: Text('Test Route'),
)
```

### 4. Router Debug-Modus
```dart
// In app_router.dart
return GoRouter(
  debugLogDiagnostics: true,  // <- Aktiviere Debug-Logs
  routes: [...],
);
```

## Häufige Probleme

### Problem: "No routes" trotz korrekter Route
**Lösung:** 
- App vollständig neu starten (nicht nur Hot Reload)
- Build-Cache leeren: `flutter clean && flutter pub get`

### Problem: Import-Fehler
**Lösung:**
```bash
flutter pub get
flutter clean
flutter run
```

### Problem: Route wird nicht gefunden bei context.push()
**Lösung:**
```dart
// Verwende IMMER context.push() oder context.go()
// NICHT: Navigator.pushNamed()

// ✅ Richtig:
context.push('/landlord/payments');

// ❌ Falsch:
Navigator.pushNamed(context, '/landlord/payments');
```

## Erfolgstest

Führe nach dem Neustart diesen Test durch:

1. **App starten** → Login
2. **Dashboard öffnen** → sollte "Zahlungen" Quick Action zeigen
3. **Auf "Zahlungen" klicken** → sollte Payments-Seite öffnen
4. **Zurück-Button** → sollte zu Dashboard zurückkehren
5. **Direkte Navigation testen:**
   ```dart
   context.push('/landlord/payments');
   ```

Alle 5 Tests sollten erfolgreich sein.

## Status

- ✅ Route definiert in `app_router.dart`
- ✅ Import vorhanden
- ✅ Page erstellt (`landlord_payments_page.dart`)
- ✅ Quick Action im Dashboard
- ⏳ **App-Neustart erforderlich**

## Nächste Schritte

1. **Stoppe die laufende App** (Drücke 'q' im Terminal)
2. **Starte die App neu:**
   ```bash
   flutter run -d windows --dart-define=API_URL=https://backend.immosync.ch/api
   ```
3. **Teste die Navigation** zu /landlord/payments
4. ✅ **Problem gelöst!**
