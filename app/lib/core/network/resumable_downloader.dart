import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../errors/app_failure.dart';
import '../logs/diwan_logger.dart';
import '../storage/disk_space_checker.dart';

enum DownloadStatus { idle, checkingDisk, downloading, paused, verifying, completed, failed }

class DownloadProgressState {
  final int bytesDownloaded;
  final int totalBytes;
  final double percentage;
  final DownloadStatus status;
  final String statusMessageArabic;
  final AppFailure? failure;

  const DownloadProgressState({
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.percentage,
    required this.status,
    required this.statusMessageArabic,
    this.failure,
  });
}

/// مدير التنزيل عالي المرونة والاستئناف (Resumable Download Manager)
class ResumableDownloader {
  final HttpClient _client;
  bool _isCancelled = false;
  final Random _random = Random();

  ResumableDownloader({HttpClient? client}) : _client = client ?? HttpClient();

  /// تحميل ملف مع استئناف القطع (.part) والتحقق من البصمة الرقمية SHA-256 والتراجع مع الجيتر
  Stream<DownloadProgressState> download({
    required Uri url,
    required String targetPath,
    required int expectedSizeBytes,
    String? expectedSha256,
    int maxRetries = 3,
  }) async* {
    _isCancelled = false;
    final partFilePath = '$targetPath.part';
    final partFile = File(partFilePath);
    final targetFile = File(targetPath);
    final targetDir = targetFile.parent.path;

    yield DownloadProgressState(
      bytesDownloaded: 0,
      totalBytes: expectedSizeBytes,
      percentage: 0.0,
      status: DownloadStatus.checkingDisk,
      statusMessageArabic: 'جاري فحص السعة التخزينية المتاحة قبل التحميل...',
    );

    // 1. فحص السعة التخزينية (حجم الملف + هامش أمان 20%)
    final requiredMb = (expectedSizeBytes / (1024 * 1024)).ceil();
    final safetyMarginMb = (requiredMb * 0.2).ceil().clamp(20, 200);
    final availableMb = await DiskSpaceChecker.getAvailableDiskSpaceMb(targetDir);

    if (availableMb < (requiredMb + safetyMarginMb)) {
      final fail = StorageFullFailure(requiredMb: requiredMb, availableMb: availableMb);
      DiwanLogger.instance.error('Downloader', 'Insufficient disk space for download', fail);
      yield DownloadProgressState(
        bytesDownloaded: 0,
        totalBytes: expectedSizeBytes,
        percentage: 0.0,
        status: DownloadStatus.failed,
        statusMessageArabic: fail.messageArabic,
        failure: fail,
      );
      return;
    }

    // 2. التحقق من وجود جزء سابق للاستئناف (.part file)
    int downloadedBytes = 0;
    if (await partFile.exists()) {
      downloadedBytes = await partFile.length();
      DiwanLogger.instance.info('Downloader', 'Found existing .part file of size: $downloadedBytes bytes');
    }

    int attempt = 0;
    while (attempt <= maxRetries && !_isCancelled) {
      try {
        final request = await _client.getUrl(url);

        // إرسال ترويسة Range للاستئناف في حال توفر جزء سابق
        if (downloadedBytes > 0) {
          request.headers.add(HttpHeaders.rangeHeader, 'bytes=$downloadedBytes-');
        }

        final response = await request.close();
        final isPartial = response.statusCode == HttpStatus.partialContent;
        final isOk = response.statusCode == HttpStatus.ok;

        if (!isPartial && !isOk) {
          throw NetworkFailure(details: 'رمز استجابة الخادم: ${response.statusCode}');
        }

        int totalContent = response.contentLength;
        if (isPartial) totalContent += downloadedBytes;
        if (totalContent <= 0) totalContent = expectedSizeBytes;

        final sink = partFile.openWrite(mode: isPartial ? FileMode.append : FileMode.write);

        await for (final chunk in response) {
          if (_isCancelled) {
            await sink.flush();
            await sink.close();
            yield DownloadProgressState(
              bytesDownloaded: downloadedBytes,
              totalBytes: totalContent,
              percentage: (downloadedBytes / totalContent * 100),
              status: DownloadStatus.paused,
              statusMessageArabic: 'تم إيقاف التحميل مؤقتاً',
            );
            return;
          }

          sink.add(chunk);
          downloadedBytes += chunk.length;
          final pct = (downloadedBytes / totalContent * 100).clamp(0.0, 100.0);

          yield DownloadProgressState(
            bytesDownloaded: downloadedBytes,
            totalBytes: totalContent,
            percentage: pct,
            status: DownloadStatus.downloading,
            statusMessageArabic: 'جاري التحميل: ${pct.toStringAsFixed(1)}%',
          );
        }

        await sink.flush();
        await sink.close();

        // 3. التحقق من البصمة الرقمية (SHA-256 Verification)
        if (expectedSha256 != null && expectedSha256.isNotEmpty) {
          yield DownloadProgressState(
            bytesDownloaded: downloadedBytes,
            totalBytes: totalContent,
            percentage: 100.0,
            status: DownloadStatus.verifying,
            statusMessageArabic: 'جاري التحقق من سلامة البصمة الرقمية...',
          );

          final fileBytes = await partFile.readAsBytes();
          final actualHash = sha256.convert(fileBytes).toString();
          if (actualHash != expectedSha256) {
            await partFile.delete(); // حذف الملف التالف فوراً
            throw const ChecksumFailure();
          }
        }

        // 4. الاستبدال والتسمية الذرية (Atomic Rename on Success)
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await partFile.rename(targetPath);

        DiwanLogger.instance.info('Downloader', 'Download successfully completed and verified: $targetPath');
        yield const DownloadProgressState(
          bytesDownloaded: 100,
          totalBytes: 100,
          percentage: 100.0,
          status: DownloadStatus.completed,
          statusMessageArabic: 'اكتمل التنزيل والتحقق بنجاح تام!',
        );
        return;
      } catch (e, st) {
        attempt++;
        DiwanLogger.instance.warn('Downloader', 'Download attempt $attempt failed: $e');

        if (attempt > maxRetries || _isCancelled) {
          final fail = e is AppFailure ? e : NetworkFailure(details: e.toString());
          yield DownloadProgressState(
            bytesDownloaded: downloadedBytes,
            totalBytes: expectedSizeBytes,
            percentage: (downloadedBytes / (expectedSizeBytes > 0 ? expectedSizeBytes : 1) * 100),
            status: DownloadStatus.failed,
            statusMessageArabic: fail.messageArabic,
            failure: fail,
          );
          return;
        }

        // تراجع أسي مع جيتر (Exponential Backoff with Jitter: 1s, 2s, 4s + random ms)
        final baseSeconds = 1 << (attempt - 1);
        final jitterMs = _random.nextInt(300);
        await Future.delayed(Duration(milliseconds: (baseSeconds * 1000) + jitterMs));
      }
    }
  }

  void cancel() {
    _isCancelled = true;
  }
}
