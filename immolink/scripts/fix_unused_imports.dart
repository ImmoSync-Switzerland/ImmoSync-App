#!/usr/bin/env dart
/// Auto-fix unused imports by removing them
/// Run with: dart run scripts/fix_unused_imports.dart

import 'dart:io';

void main() {
  print('🧹 Fixing unused imports...\n');
  
  // For now, rely on Flutter's built-in formatter
  // which doesn't remove unused imports automatically
  
  print('ℹ️  Use your IDE to organize imports or:');
  print('   - VS Code: Right-click → "Organize Imports"');
  print('   - Android Studio: Code → Optimize Imports');
  print('   - dart fix --apply (for some fixes)\n');
  
  // Run dart fix to apply automated fixes
  final result = Process.runSync('dart', ['fix', '--apply']);
  
  if (result.exitCode == 0) {
    print('✅ Applied automated fixes');
    print(result.stdout);
  } else {
    print('⚠️  Some fixes could not be applied automatically');
    print(result.stderr);
  }
  
  exit(0);
}
