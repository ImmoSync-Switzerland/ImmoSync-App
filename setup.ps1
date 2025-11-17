#!/usr/bin/env pwsh
# Setup script for ImmoLink development environment

Write-Host "🚀 Setting up ImmoLink development environment..." -ForegroundColor Cyan
Write-Host ""

# Check Flutter installation
Write-Host "📦 Checking Flutter installation..." -ForegroundColor Yellow
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter not found! Please install Flutter first." -ForegroundColor Red
    Write-Host "   Visit: https://docs.flutter.dev/get-started/install" -ForegroundColor Yellow
    exit 1
}

flutter --version
Write-Host ""

# Check Dart version
Write-Host "📦 Checking Dart version..." -ForegroundColor Yellow
$dartVersion = dart --version 2>&1 | Out-String
Write-Host $dartVersion
Write-Host ""

# Install Node.js dependencies for Husky
Write-Host "📦 Installing Git hooks (Husky)..." -ForegroundColor Yellow
if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm install
    Write-Host "✅ Husky installed" -ForegroundColor Green
} else {
    Write-Host "⚠️  npm not found - skipping Husky setup" -ForegroundColor Yellow
    Write-Host "   Git hooks will not work without Node.js/npm" -ForegroundColor Yellow
}
Write-Host ""

# Install Flutter dependencies
Write-Host "📦 Installing Flutter dependencies..." -ForegroundColor Yellow
Set-Location immolink
flutter pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Flutter dependencies installed" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to install Flutter dependencies" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host ""

# Run code generation (if needed)
Write-Host "🔨 Running code generation..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs
Write-Host ""

# Run initial tests
Write-Host "🧪 Running tests..." -ForegroundColor Yellow
flutter test

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ All tests passed" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some tests failed - please review" -ForegroundColor Yellow
}
Write-Host ""

# Generate localization
Write-Host "🌍 Generating localizations..." -ForegroundColor Yellow
flutter gen-l10n
Write-Host ""

Set-Location ..

# Summary
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Copy .env.example to .env and configure"
Write-Host "  2. Add google-services.json for Firebase"
Write-Host "  3. Run: flutter run (from immolink/ directory)"
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "  flutter test              # Run tests"
Write-Host "  flutter analyze           # Static analysis"
Write-Host "  dart format .             # Format code"
Write-Host "  flutter pub outdated      # Check for updates"
Write-Host ""
Write-Host "See .github/PRECOMMIT_GUIDE.md for more info"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
