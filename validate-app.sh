#!/bin/bash

# Dart code validation script
echo "Validating ImmoLink Flutter App Structure..."
echo "============================================="

cd /home/runner/work/ImmoLink/ImmoLink/immolink

# Check for required files
echo "1. Checking core files..."
required_files=(
  "lib/main.dart"
  "pubspec.yaml"
  ".env"
  "lib/core/routes/app_router.dart"
  "lib/core/services/database_service.dart"
)

for file in "${required_files[@]}"; do
  if [ -f "$file" ]; then
    echo "✓ $file exists"
  else
    echo "✗ $file missing"
  fi
done

echo ""

# Check for basic imports
echo "2. Checking critical imports..."
if grep -q "flutter_riverpod" lib/main.dart; then
  echo "✓ Riverpod state management imported"
else
  echo "✗ Missing Riverpod import"
fi

if grep -q "go_router" lib/main.dart; then
  echo "✓ GoRouter navigation imported"
else
  echo "✗ Missing GoRouter import"
fi

if grep -q "http" pubspec.yaml; then
  echo "✓ HTTP package available"
else
  echo "✗ Missing HTTP package"
fi

echo ""

# Check service structure
echo "3. Checking service implementations..."
services=(
  "lib/features/auth/domain/services/auth_service.dart"
  "lib/features/property/domain/services/property_service.dart"
  "lib/features/payment/domain/services/payment_service.dart"
  "lib/features/maintenance/domain/services/maintenance_service.dart"
)

for service in "${services[@]}"; do
  if [ -f "$service" ]; then
    echo "✓ $(basename $service) exists"
  else
    echo "✗ $(basename $service) missing"
  fi
done

echo ""

# Check model structure
echo "4. Checking model implementations..."
models=(
  "lib/features/auth/domain/models/user.dart"
  "lib/features/property/domain/models/property.dart"
  "lib/features/payment/domain/models/payment.dart"
)

for model in "${models[@]}"; do
  if [ -f "$model" ]; then
    echo "✓ $(basename $model) exists"
  else
    echo "✗ $(basename $model) missing"
  fi
done

echo ""

# Count feature modules
echo "5. Feature module analysis..."
feature_count=$(find lib/features -maxdepth 1 -type d | tail -n +2 | wc -l)
echo "✓ Found $feature_count feature modules"

# List features
echo "   Features: $(find lib/features -maxdepth 1 -type d -exec basename {} \; | tail -n +2 | tr '\n' ', ' | sed 's/,$//')"

echo ""

# Check test structure
echo "6. Testing infrastructure..."
if [ -d "test" ]; then
  test_count=$(find test -name "*.dart" | wc -l)
  echo "✓ Test directory exists with $test_count test files"
else
  echo "✗ No test directory found"
fi

echo ""
echo "Flutter app structure validation completed!"