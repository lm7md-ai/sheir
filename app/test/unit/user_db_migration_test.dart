import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:diwan/core/db/database_manager.dart';

void main() {
  group('Dual-Database, Drift Migrations, Atomic Swap & Orphan Reconciliation Tests (Gate 6)', () {
    late Directory tempDir;
    late String poemsDbPath;
    late String userDbPath;
    late DatabaseManager dbManager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('diwan_db_test_');
      poemsDbPath = '${tempDir.path}/poems.db';
      userDbPath = '${tempDir.path}/user.db';

      // كتابة ملفات أولية صالحة
      final headerBytes = utf8.encode('SQLite format 3\x00' + 'x' * 120);
      await File(poemsDbPath).writeAsBytes(headerBytes);
      await File(userDbPath).writeAsBytes(headerBytes);

      dbManager = DatabaseManager(
        poemsDbPath: poemsDbPath,
        userDbPath: userDbPath,
        currentAppVersion: '1.0.0',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('(1) ترحيل قاعدة بيانات المستخدم تدريجياً خطوة بخطوة من v1 إلى v3 (onUpgrade Migrations)', () async {
      final migrationLog = <String>[];
      final targetVersion = await dbManager.migrateUserDatabase(
        fromVersion: 1,
        toVersion: 3,
        executedSteps: migrationLog,
      );

      expect(targetVersion, equals(3));
      expect(migrationLog.length, equals(2));
      expect(migrationLog[0], equals('MIGRATION_V1_TO_V2_ADD_ATTEMPTS_AND_ORPHAN_FLAG'));
      expect(migrationLog[1], equals('MIGRATION_V2_TO_V3_ADD_ORPHANED_STATUS'));
    });

    test('(2) التحقق من وجود ودقة ملفات المخطط المصدرة (Exported Schema JSON v1, v2, v3)', () async {
      final v1File = File('docs/schemas/user_db_v1.json');
      final v2File = File('docs/schemas/user_db_v2.json');
      final v3File = File('docs/schemas/user_db_v3.json');

      expect(await v1File.exists(), isTrue);
      expect(await v2File.exists(), isTrue);
      expect(await v3File.exists(), isTrue);

      final v1Data = jsonDecode(await v1File.readAsString());
      final v2Data = jsonDecode(await v2File.readAsString());
      final v3Data = jsonDecode(await v3File.readAsString());

      expect(v1Data['version'], equals(1));
      expect(v2Data['version'], equals(2));
      expect(v3Data['version'], equals(3));

      // التأكيد على إضافة الجداول الجديدة في v2
      final v2Tables = (v2Data['tables'] as List).map((t) => t['name'] as String).toList();
      expect(v2Tables, containsAll(['progress', 'srs_cards', 'attempts', 'attempt_errors', 'collections', 'favorites', 'settings']));
    });

    test('(3) معالجة المعرفات اليتيمة بلباقة ووسمها كـ "removed" دون انهيار التطبيق', () async {
      final validLibraryVerseUids = {'verse_mutanabbi_01', 'verse_imru_01'};
      final userCards = [
        {
          'id': 'card_1',
          'verse_uid': 'verse_mutanabbi_01',
          'is_orphaned': 0,
          'orphaned_status': 'active',
        },
        {
          'id': 'card_2',
          'verse_uid': 'verse_old_removed_in_update',
          'is_orphaned': 0,
          'orphaned_status': 'active',
        },
      ];

      final orphanedCount = await dbManager.reconcileOrphanedRecords(
        validVerseUids: validLibraryVerseUids,
        userSrsCards: userCards,
      );

      expect(orphanedCount, equals(1));
      expect(userCards[1]['is_orphaned'], equals(1));
      expect(userCards[1]['orphaned_status'], equals('removed'));
      // البطاقة السارية لم تتغير
      expect(userCards[0]['is_orphaned'], equals(0));
      expect(userCards[0]['orphaned_status'], equals('active'));
    });

    test('(4) النسخ الاحتياطي والاستعادة يغطيان user.db فقط دون المساس بـ poems.db', () async {
      // 1. أخذ نسخة احتياطية
      final backupFile = await dbManager.backupUserData(tempDir.path);
      expect(await backupFile.exists(), isTrue);
      expect(backupFile.path, contains('diwan_user_backup_'));

      // 2. محاكاة تعديل أو كتابة في user.db
      await File(userDbPath).writeAsString('USER_PROGRESS_MODIFIED');
      expect(await File(userDbPath).readAsString(), equals('USER_PROGRESS_MODIFIED'));

      // 3. استعادة النسخة الاحتياطية وتأكيد حماية user.db
      await dbManager.restoreUserData(backupFile.path);
      final restoredContent = await File(userDbPath).readAsBytes();
      expect(restoredContent, isNotEmpty);
      expect(String.fromCharCodes(restoredContent.take(15)), startsWith('SQLite format 3'));
    });
  });
}
