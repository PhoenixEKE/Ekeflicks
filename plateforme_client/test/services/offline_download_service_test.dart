import 'package:app_ekeflicks/services/offline_download_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfflineDownload', () {
    test('only completed downloads with an active license can play', () {
      final downloading = OfflineDownload.fromMap({
        'assetId': 'movie-1',
        'status': 'downloading',
        'expiresAt': '2099-01-01T00:00:00Z',
      });
      final completed = OfflineDownload.fromMap({
        'assetId': 'movie-2',
        'status': 'completed',
        'expiresAt': '2099-01-01T00:00:00Z',
      });
      final expired = OfflineDownload.fromMap({
        'assetId': 'movie-3',
        'status': 'completed',
        'expiresAt': '2000-01-01T00:00:00Z',
      });

      expect(downloading.canPlay, isFalse);
      expect(completed.canPlay, isTrue);
      expect(expired.isExpired, isTrue);
      expect(expired.canPlay, isFalse);
    });

    test('normalizes native progress to the display range', () {
      final download = OfflineDownload.fromMap({
        'assetId': 'movie-4',
        'status': 'queued',
        'progress': 140,
      });

      expect(download.progress, 100);
      expect(download.canPlay, isFalse);
    });
  });
}
