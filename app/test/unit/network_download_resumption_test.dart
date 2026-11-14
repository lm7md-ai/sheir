import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diwan/core/errors/app_failure.dart';
import 'package:diwan/core/logging/rotating_file_logger.dart';
import 'package:diwan/core/logs/diwan_logger.dart';
import 'package:diwan/core/network/resumable_downloader.dart';
import 'package:diwan/core/storage/disk_space_checker.dart';

void main() {
  group('Fake HTTP Server Tests: Resume, Checksum, Low-Disk, and File Logging', () {
    late HttpServer server;
    late Uri serverUri;
    late Directory tempDir;
    final payload = utf8.encode('DIWAN_AI_MODEL_STREAMING_BINARY_DATA_WITH_ROBUST_RANGE_RESUME_1234567890');
    final validChecksum = sha256.convert(payload).toString();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('diwan_download_test_');
      DiskSpaceChecker.mockAvailableSpaceMb = null; // إعادة تعيين الفاحص

      // إنشاء خادم HTTP محلي يدعم ترويسة Range للاستئناف
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      serverUri = Uri.parse('http://${server.address.host}:${server.port}/model.bin');

      server.listen((HttpRequest request) async {
        final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
        if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
          final rangeParts = rangeHeader.substring(6).split('-');
          final start = int.parse(rangeParts[0]);
          final end = payload.length - 1;
          final chunk = payload.sublist(start);

          request.response.statusCode = HttpStatus.partialContent;
          request.response.headers.set(HttpHeaders.contentTypeHeader, 'application/octet-stream');
          request.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/${payload.length}');
          request.response.headers.set(HttpHeaders.contentLengthHeader, chunk.length.toString());
          request.response.add(chunk);
          await request.response.close();
        } else {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.set(HttpHeaders.contentTypeHeader, 'application/octet-stream');
          request.response.headers.set(HttpHeaders.contentLengthHeader, payload.length.toString());
          request.response.add(payload);
          await request.response.close();
        }
      });
    });

    tearDown(() async {
      await server.close(force: true);
      DiskSpaceChecker.mockAvailableSpaceMb = null;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('(1) استئناف التنزيل من موضع البايت الصحيح عبر ترويسة Range (Correct-Byte Resume)', () async {
      final targetPath = '${tempDir.path}/downloaded_model.bin';
      final partFile = File('$targetPath.part');

      // 1. محاكاة وجود جزء تم تنزيله سابقاً (أول 20 بايت)
      const partialLength = 20;
      await partFile.writeAsBytes(payload.sublist(0, partialLength));

      final downloader = ResumableDownloader();
      final states = <DownloadProgressState>[];

      await for (final state in downloader.download(
        url: serverUri,
        targetPath: targetPath,
        expectedSizeBytes: payload.length,
        expectedSha256: validChecksum,
      )) {
        states.add(state);
      }

      // التحقق من اكتمال التنزيل بنجاح
      final finalFile = File(targetPath);
      expect(await finalFile.exists(), isTrue);
      final finalBytes = await finalFile.readAsBytes();
      expect(finalBytes, equals(payload));
      expect(states.any((s) => s.status == DownloadStatus.completed), isTrue);
    });

    test('(2) رفض الملف عند عدم تطابق بصمة SHA-256 وإعادة المحاولة (Checksum Mismatch Rejection & Retry)', () async {
      final targetPath = '${tempDir.path}/corrupt_model.bin';
      const fakeCorruptedChecksum = '0000000000000000000000000000000000000000000000000000000000000000';

      final downloader = ResumableDownloader();
      final states = <DownloadProgressState>[];

      await for (final state in downloader.download(
        url: serverUri,
        targetPath: targetPath,
        expectedSizeBytes: payload.length,
        expectedSha256: fakeCorruptedChecksum,
        maxRetries: 1,
      )) {
        states.add(state);
      }

      // يجب أن يفشل التحميل بسبب عدم تطابق البصمة
      final lastState = states.last;
      expect(lastState.status, equals(DownloadStatus.failed));
      expect(lastState.failure, isA<ChecksumFailure>());
      // التأكد من حذف الملف المؤقت التالف وعدم إنتاج الملف النهائي
      expect(await File(targetPath).exists(), isFalse);
    });

    test('(3) حظر التنزيل عند انخفاض سعة القرص التخزينية بالخطأ المناسب (Low-Disk Blocking)', () async {
      final targetPath = '${tempDir.path}/blocked_model.bin';

      // محاكاة سعة متبقية 5 ميغابايت فقط بينما نحتاج أكثر من ذلك
      DiskSpaceChecker.mockAvailableSpaceMb = 5;

      final downloader = ResumableDownloader();
      final states = <DownloadProgressState>[];

      await for (final state in downloader.download(
        url: serverUri,
        targetPath: targetPath,
        expectedSizeBytes: 50 * 1024 * 1024, // 50 MB
      )) {
        states.add(state);
      }

      final lastState = states.last;
      expect(lastState.status, equals(DownloadStatus.failed));
      expect(lastState.failure, isA<StorageFullFailure>());
      final storageFail = lastState.failure as StorageFullFailure;
      expect(storageFail.availableMb, equals(5));
      expect(storageFail.messageArabic, contains('المساحة المتبقية على جهازك هي 5 ميغابايت'));
    });

    test('(4) معالج الأخطاء العام يسجل الاستثناءات في ملف السجل المتناوب (Global Error Logging to File)', () async {
      final logDir = Directory('${tempDir.path}/logs');
      await logDir.create(recursive: true);

      final rotatingLogger = RotatingFileLogger(
        directoryPath: logDir.path,
        maxFileSize: 10 * 1024,
      );
      await rotatingLogger.init();

      // تسجيل خطأ استثنائي عالمي
      try {
        throw const StorageFullFailure(requiredMb: 100, availableMb: 10);
      } catch (e, st) {
        await rotatingLogger.log('ERROR', 'GlobalErrorHandler', 'Caught uncaught exception in pipeline: $e', st.toString());
      }

      final activeLogFile = File(rotatingLogger.currentLogFilePath);
      expect(await activeLogFile.exists(), isTrue);

      final logContent = await activeLogFile.readAsString();
      expect(logContent, contains('[ERROR]'));
      expect(logContent, contains('GlobalErrorHandler'));
      expect(logContent, contains('StorageFullFailure'));
      expect(logContent, contains('المساحة التخزينية غير كافية'));
    });
  });
}
