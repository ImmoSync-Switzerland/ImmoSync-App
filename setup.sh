#!/bin/bash
# Setup script for ImmoLink development environment

echo "🚀 Setting up ImmoLink development environment..."
echo ""

# Check Flutter installation
echo "📦 Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found! Please install Flutter first."
    echo "   Visit: https://docs.flutter.dev/get-started/install"
    exit 1
fi

flutter --version
echo ""

# Check Dart version
echo "📦 Checking Dart version..."
dart --version
echo ""

# Install Node.js dependencies for Husky
echo "📦 Installing Git hooks (Husky)..."
if command -v npm &> /dev/null; then
    npm install
    echo "✅ Husky installed"
else
    echo "⚠️  npm not found - skipping Husky setup"
    echo "   Git hooks will not work without Node.js/npm"
fi
echo ""

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
cd immolink || exit 1
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Flutter dependencies installed"
else
    echo "❌ Failed to install Flutter dependencies"
    cd ..
    exit 1
fi
echo ""

# Run code generation (if needed)
echo "🔨 Running code generation..."
flutter pub run build_runner build --delete-conflicting-outputs
echo ""

# Run initial tests
echo "🧪 Running tests..."
flutter test

if [ $? -eq 0 ]; then
    echo "✅ All tests passed"
else
    echo "⚠️  Some tests failed - please review"
fi
echo ""

# Generate localization
echo "🌍 Generating localizations..."
flutter gen-l10n
echo ""

cd ..

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Copy .env.example to .env and configure"
echo "  2. Add google-services.json for Firebase"
echo "  3. Run: flutter run (from immolink/ directory)"
echo ""
echo "Useful commands:"
echo "  flutter test              # Run tests"
echo "  flutter analyze           # Static analysis"
echo "  dart format .             # Format code"
echo "  flutter pub outdated      # Check for updates"
echo ""
echo "See .github/PRECOMMIT_GUIDE.md for more info"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
