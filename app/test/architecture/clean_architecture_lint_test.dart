import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Clean Architecture Boundaries & Dependency Rules (Gate 3)', () {
    final featuresDir = Directory('lib/features');

    test('طبقة النطاق (domain) نقية ولا تستورد Flutter نهائياً', () {
      if (!featuresDir.existsSync()) return;

      final violations = <String>[];
      for (final entity in featuresDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          if (entity.path.contains('/domain/')) {
            final lines = entity.readAsLinesSync();
            for (var i = 0; i < lines.length; i++) {
              final line = lines[i];
              if (line.contains("import 'package:flutter/") ||
                  line.contains("import 'package:flutter_")) {
                violations.add('${entity.path}:${i + 1}: $line');
              }
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'يُحظر استيراد Flutter داخل طبقة domain النظيفة. المخالفات: $violations',
      );
    });

    test('طبقة العرض (presentation) لا تستورد طبقة البيانات (data) مباشرة', () {
      if (!featuresDir.existsSync()) return;

      final violations = <String>[];
      final dataImportRegex = RegExp(r'''import\s+['"].*/data/.*['"]''');

      for (final entity in featuresDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          if (entity.path.contains('/presentation/')) {
            final lines = entity.readAsLinesSync();
            for (var i = 0; i < lines.length; i++) {
              final line = lines[i];
              if (dataImportRegex.hasMatch(line)) {
                violations.add('${entity.path}:${i + 1}: $line');
              }
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'يُحظر استيراد طبقة data مباشرة داخل presentation. المخالفات: $violations',
      );
    });

    test('حزمة diwan_core مستقلة ونقية تماماً من أي تبعية لـ Flutter', () {
      final coreDir = Directory('packages/diwan_core/lib');
      if (!coreDir.existsSync()) return;

      final violations = <String>[];
      for (final entity in coreDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final lines = entity.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.contains("import 'package:flutter/") ||
                line.contains("import 'package:flutter_")) {
              violations.add('${entity.path}:${i + 1}: $line');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'يُحظر استيراد Flutter داخل packages/diwan_core. المخالفات: $violations',
      );
    });
  });
}
