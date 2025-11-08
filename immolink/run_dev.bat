@echo off
REM run_dev.bat - Lokaler Development Build mit allen Secrets (Windows)

REM Setze deine lokalen Werte hier:
set API_URL=https://backend.immosync.ch/api
set STRIPE_PUBLISHABLE_KEY=pk_test_DEINE_KEY
set GOOGLE_CLIENT_ID=DEINE_CLIENT_ID.apps.googleusercontent.com

flutter run ^
  --dart-define=API_URL=%API_URL% ^
  --dart-define=STRIPE_PUBLISHABLE_KEY=%STRIPE_PUBLISHABLE_KEY% ^
  --dart-define=GOOGLE_CLIENT_ID=%GOOGLE_CLIENT_ID%
