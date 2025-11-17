#!/usr/bin/env dart
/// Check for unused imports in Dart files
/// Run with: dart run scripts/check_unused_imports.dart

import 'dart:io';

void main() {
  print('🔍 Checking for unused imports...\n');
  
  final libDir = Directory('lib');
  final testDir = Directory('test');
  
  if (!libDir.existsSync()) {
    print('❌ lib directory not found');
    exit(1);
  }
  
  int unusedCount = 0;
  
  // Check lib files
  final libFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
      
  for (final file in libFiles) {
    final unused = _checkFile(file);
    unusedCount += unused;
  }
  
  // Check test files
  if (testDir.existsSync()) {
    final testFiles = testDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
        
    for (final file in testFiles) {
      final unused = _checkFile(file);
      unusedCount += unused;
    }
  }
  
  if (unusedCount > 0) {
    print('\n⚠️  Found $unusedCount file(s) with potential unused imports');
    print('Run: dart run scripts/fix_unused_imports.dart to fix');
    exit(1);
  }
  
  print('✅ No unused imports found');
  exit(0);
}

int _checkFile(File file) {
  try {
    final content = file.readAsStringSync();
    final lines = content.split('\n');
    
    final imports = <String>[];
    final usedIdentifiers = <String>{};
    
    // Extract imports
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('import ')) {
        imports.add(line);
      } else if (line.isNotEmpty && !line.startsWith('//')) {
        // Collect identifiers from code
        final words = RegExp(r'\b\w+\b').allMatches(line);
        usedIdentifiers.addAll(words.map((m) => m.group(0)!));
      }
    }
    
    // Simple heuristic check (not perfect, but catches obvious cases)
    int unused = 0;
    for (final import in imports) {
      // Skip relative imports and essential Flutter imports
      if (import.contains('package:flutter/') ||
          import.contains('dart:') ||
          import.contains('../') ||
          import.contains('./')) {
        continue;
      }
      
      // Extract package name
      final match = RegExp(r"import\s+'package:(\w+)/").firstMatch(import);
      if (match != null) {
        final packageName = match.group(1)!;
        
        // Very basic check: if package name isn't referenced, might be unused
        // This is a heuristic and can have false positives
        if (!usedIdentifiers.contains(packageName) &&
            !content.contains(packageName)) {
          unused++;
        }
      }
    }
    
    return unused;
  } catch (e) {
    // Ignore files we can't read
    return 0;
  }
}
