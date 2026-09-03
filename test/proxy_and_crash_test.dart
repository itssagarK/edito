import 'package:flutter_test/flutter_test.dart';
import 'package:edito/core/services/crash_reporting_service.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/features/media/services/proxy_generation_service.dart';

void main() {
  group('Proxy Generation & Crash Reporting Tests', () {
    test('MediaAsset correctly detects 4K footage and proxy support', () {
      const asset1080p = MediaAsset(
        id: 'a1',
        path: '/movies/clip_1080p.mp4',
        fileName: 'clip_1080p.mp4',
        type: MediaType.video,
        durationMs: 5000,
        width: 1920,
        height: 1080,
      );

      const asset4k = MediaAsset(
        id: 'a2',
        path: '/movies/clip_4k.mp4',
        fileName: 'clip_4k.mp4',
        type: MediaType.video,
        durationMs: 8000,
        width: 3840,
        height: 2160,
        proxyPath: '/cache/proxies/proxy_a2.mp4',
      );

      expect(asset1080p.is4kOrHigher, isFalse);
      expect(asset1080p.hasProxy, isFalse);

      expect(asset4k.is4kOrHigher, isTrue);
      expect(asset4k.hasProxy, isTrue);
    });

    test('ProxyGenerationService skips non-4K assets', () async {
      const asset1080p = MediaAsset(
        id: 'a1',
        path: '/movies/clip_1080p.mp4',
        fileName: 'clip_1080p.mp4',
        type: MediaType.video,
        durationMs: 5000,
        width: 1920,
        height: 1080,
      );

      final proxy = await ProxyGenerationService.resolveOrCreateProxy(asset1080p);
      expect(proxy, isNull);
    });

    test('CrashLog correctly serializes and deserializes', () {
      final now = DateTime.now();
      final log = CrashLog(
        message: 'Null pointer in decoder',
        stackTrace: '#0 VideoDecoder.init()',
        timestamp: now,
        reason: 'Codec unsupported',
      );

      final json = log.toJson();
      final restored = CrashLog.fromJson(json);

      expect(restored.message, equals('Null pointer in decoder'));
      expect(restored.reason, equals('Codec unsupported'));
      expect(restored.stackTrace, contains('VideoDecoder.init()'));
    });
  });
}
