import 'dart:async';
import 'dart:io';
import '../errors/diwan_exception.dart';
import '../logs/diwan_logger.dart';
import '../storage/disk_space_checker.dart';

enum DownloadState { idle, checkingDisk, downloading, paused, completed, failed }

class DownloadProgress {
  final int bytesDownloaded;
  final int totalBytes;
  final double percentage;
  final DownloadState state;
  final String statusMessageArabic;

  const DownloadProgress({
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.percentage,
    required this.state,
    required this.statusMessageArabic,
  });
}

/// خدمة التحميل القابل للاستئناف وإعادة المحاولة التلقائية (Resumable Download Service)
class ResumableDownloader {
  final HttpClient _client;
  bool _isCancelled = false;

  ResumableDownloader({HttpClient? client}) : _client = client ?? HttpClient();

  /// تحميل ملف كبير مع استئناف القطع السابقة (HTTP Range Header) وإعادة المحاولة 3 مرات
  Stream<DownloadProgress> downloadFile({
    required Uri url,
    required String savePath,
    required int estimatedSizeMb,
    int maxRetries = 3,
  }) async* {
    _isCancelled = false;
    final file = File(savePath);
    final targetDir = file.parent.path;

    yield DownloadProgress(
      bytesDownloaded: 0,
      totalBytes: estimatedSizeMb * 1024 * 1024,
      percentage: 0.0,
      state: DownloadState.checkingDisk,
      statusMessageArabic: 'جاري فحص السعة التخزينية المتاحة...',
    );

    // 1. التحقق من كفاية المساحة في القرص
    try {
      await DiskSpaceChecker.ensureSufficientSpace(
        targetDirectory: targetDir,
        requiredSpaceMb: estimatedSizeMb,
      );
    } catch (e, st) {
      DiwanLogger.instance.error('Downloader', 'Disk space check failed', e, st);
      yield DownloadProgress(
        bytesDownloaded: 0,
        totalBytes: estimatedSizeMb * 1024 * 1024,
        percentage: 0.0,
        state: DownloadState.failed,
        statusMessageArabic: e is DiwanException ? e.messageArabic : 'المساحة غير كافية',
      );
      return;
    }

    int downloadedBytes = 0;
    if (await file.exists()) {
      downloadedBytes = await file.length();
      DiwanLogger.instance.info('Downloader', 'Found partial file of size: $downloadedBytes bytes');
    }

    int retryCount = 0;
    while (retryCount <= maxRetries && !_isCancelled) {
      try {
        DiwanLogger.instance.info(
          'Downloader',
          'Attempt ${retryCount + 1}: Downloading from $downloadedBytes bytes',
        );

        final request = await _client.getUrl(url);
        if (downloadedBytes > 0) {
          request.headers.add(HttpHeaders.rangeHeader, 'bytes=$downloadedBytes-');
        }

        final response = await request.close();
        final isPartial = response.statusCode == HttpStatus.partialContent;
        final isOk = response.statusCode == HttpStatus.ok;

        if (!isPartial && !isOk) {
          throw DiwanException.download('رمز استجابة الخادم غير متوقع: ${response.statusCode}');
        }

        int totalBytes = response.contentLength;
        if (isPartial) {
          totalBytes += downloadedBytes;
        }

        final sink = file.openWrite(mode: isPartial ? FileMode.append : FileMode.write);

        await for (final chunk in response) {
          if (_isCancelled) {
            await sink.close();
            yield DownloadProgress(
              bytesDownloaded: downloadedBytes,
              totalBytes: totalBytes,
              percentage: (downloadedBytes / (totalBytes > 0 ? totalBytes : 1) * 100),
              state: DownloadState.paused,
              statusMessageArabic: 'تم إيقاف التحميل مؤقتاً',
            );
            return;
          }

          sink.add(chunk);
          downloadedBytes += chunk.length;
          final pct = totalBytes > 0 ? (downloadedBytes / totalBytes * 100).clamp(0.0, 100.0) : 0.0;

          yield DownloadProgress(
            bytesDownloaded: downloadedBytes,
            totalBytes: totalBytes,
            percentage: pct,
            state: DownloadState.downloading,
            statusMessageArabic: 'جاري التحميل: ${pct.toStringAsFixed(1)}%',
          );
        }

        await sink.flush();
        await sink.close();

        DiwanLogger.instance.info('Downloader', 'Download successfully finished: $savePath');
        yield DownloadProgress(
          bytesDownloaded: downloadedBytes,
          totalBytes: totalBytes,
          percentage: 100.0,
          state: DownloadState.completed,
          statusMessageArabic: 'اكتمل التحميل بنجاح!',
        );
        return;
      } catch (e, st) {
        retryCount++;
        DiwanLogger.instance.warn(
          'Downloader',
          'Download error on attempt $retryCount: $e. Waiting before retry...',
        );

        if (retryCount > maxRetries) {
          DiwanLogger.instance.error('Downloader', 'Max retries exceeded', e, st);
          yield DownloadProgress(
            bytesDownloaded: downloadedBytes,
            totalBytes: estimatedSizeMb * 1024 * 1024,
            percentage: 0.0,
            state: DownloadState.failed,
            statusMessageArabic: 'تعذر إتمام التحميل بعد عدة محاولات، اضغط لمعاودة الاستئناف.',
          );
          return;
        }

        // انتظار تصاعدي (Exponential Backoff: 1s, 2s, 4s)
        await Future.delayed(Duration(seconds: 1 << (retryCount - 1)));
      }
    }
  }

  void cancel() {
    _isCancelled = true;
  }
}
