import 'package:flutter_test/flutter_test.dart';
import 'package:edito/core/ai/device_tier_service.dart';
import 'package:edito/core/ai/services/on_device_upscaler_service.dart';
import 'package:edito/features/enhancement/models/video_enhancement_config.dart';
import 'package:edito/features/enhancement/services/ai_video_enhancer_service.dart';

void main() {
  group('VideoEnhancementConfig Real-ESRGAN Tests', () {
    test('Default VideoEnhancementConfig has Real-ESRGAN disabled with scale 4', () {
      const config = VideoEnhancementConfig();
      expect(config.useNeuralRealEsrgan, isFalse);
      expect(config.tiledResolutionScale, 4);
      expect(config.upscaledAssetPath, isNull);
      expect(config.hasActiveEnhancements, isFalse);
    });

    test('copyWith updates Real-ESRGAN neural fields properly', () {
      const config = VideoEnhancementConfig();
      final updated = config.copyWith(
        useNeuralRealEsrgan: true,
        tiledResolutionScale: 4,
        upscaledAssetPath: '/data/user/0/com.edito.app/files/upscaled_test.png',
      );

      expect(updated.useNeuralRealEsrgan, isTrue);
      expect(updated.tiledResolutionScale, 4);
      expect(updated.upscaledAssetPath, '/data/user/0/com.edito.app/files/upscaled_test.png');
      expect(updated.hasActiveEnhancements, isTrue);
    });

    test('Backward compatibility: legacy JSON without Real-ESRGAN fields defaults cleanly', () {
      final legacyJson = <String, dynamic>{
        'is8kUpscaleEnabled': false,
        'isAiSuperResolutionEnabled': true,
        'sharpness': 1.5,
        'deNoise': 0.2,
        'isHdrToneMapping': true,
        'clarity': 1.2,
        'isColorPop': false,
        'modelPreset': 'crispPhoto',
      };

      final parsed = VideoEnhancementConfig.fromJson(legacyJson);
      expect(parsed.isAiSuperResolutionEnabled, isTrue);
      expect(parsed.sharpness, 1.5);
      expect(parsed.modelPreset, EnhanceModelPreset.crispPhoto);
      expect(parsed.useNeuralRealEsrgan, isFalse);
      expect(parsed.tiledResolutionScale, 4);
      expect(parsed.upscaledAssetPath, isNull);
    });

    test('JSON serialization round-trip preserves all Real-ESRGAN fields', () {
      const original = VideoEnhancementConfig(
        is8kUpscaleEnabled: true,
        useNeuralRealEsrgan: true,
        tiledResolutionScale: 4,
        upscaledAssetPath: '/storage/emulated/0/Pictures/Edito/upscale_4x.png',
        sharpness: 1.8,
      );

      final json = original.toJson();
      final restored = VideoEnhancementConfig.fromJson(json);

      expect(restored.useNeuralRealEsrgan, isTrue);
      expect(restored.tiledResolutionScale, 4);
      expect(restored.upscaledAssetPath, '/storage/emulated/0/Pictures/Edito/upscale_4x.png');
      expect(restored.is8kUpscaleEnabled, isTrue);
      expect(restored.sharpness, 1.8);
      expect(restored, equals(original));
    });
  });

  group('AIVideoEnhancerService Technical Honesty & Filter Tests', () {
    test('getResolutionLabel strictly distinguishes Neural Real-ESRGAN from Lanczos', () {
      const neuralConfig = VideoEnhancementConfig(useNeuralRealEsrgan: true);
      expect(AIVideoEnhancerService.getResolutionLabel(neuralConfig), '4x REAL-ESRGAN (NEURAL)');

      const lanczosConfig = VideoEnhancementConfig(is8kUpscaleEnabled: true);
      expect(AIVideoEnhancerService.getResolutionLabel(lanczosConfig), '8K UHD Lanczos (7680x4320)');

      const detailConfig = VideoEnhancementConfig(isAiSuperResolutionEnabled: true);
      expect(AIVideoEnhancerService.getResolutionLabel(detailConfig), 'DETAIL ENHANCED');

      const standardConfig = VideoEnhancementConfig();
      expect(AIVideoEnhancerService.getResolutionLabel(standardConfig), '1080p Standard');
    });

    test('generateFFmpegFilters generates expected Lanczos 8K scaling commands', () {
      const config = VideoEnhancementConfig(
        is8kUpscaleEnabled: true,
        deNoise: 0.3,
        sharpness: 1.5,
      );

      final filters = AIVideoEnhancerService.generateFFmpegFilters(config);
      expect(filters.any((f) => f.contains('hqdn3d=')), isTrue);
      expect(filters.any((f) => f.contains('scale=7680:4320:flags=lanczos')), isTrue);
      expect(filters.any((f) => f.contains('unsharp=5:5:')), isTrue);
    });
  });

  group('OnDeviceUpscalerService Tiling & Speed Notice Tests', () {
    test('estimateProcessingTimeSeconds scales with resolution and hardware tier', () {
      // 1920x1080 with 256x256 tile size (step = 240)
      // numTilesX = ceil(1920/240) = 8
      // numTilesY = ceil(1080/240) = 5
      // totalTiles = 40
      final lowTierSec = OnDeviceUpscalerService.estimateProcessingTimeSeconds(
        width: 1920,
        height: 1080,
        tier: DeviceTier.low,
      );
      final medTierSec = OnDeviceUpscalerService.estimateProcessingTimeSeconds(
        width: 1920,
        height: 1080,
        tier: DeviceTier.medium,
      );
      final highTierSec = OnDeviceUpscalerService.estimateProcessingTimeSeconds(
        width: 1920,
        height: 1080,
        tier: DeviceTier.high,
      );

      expect(lowTierSec, greaterThan(medTierSec));
      expect(medTierSec, greaterThan(highTierSec));
      expect(lowTierSec, 40 * 0.25); // 10.0s
      expect(medTierSec, 40 * 0.12); // 4.8s
      expect(highTierSec, 40 * 0.05); // 2.0s
    });

    test('getSpeedNotice includes honest offline and tiled notice', () {
      final notice = OnDeviceUpscalerService.getSpeedNotice(estimatedSeconds: 6);
      expect(notice, contains('Real-ESRGAN runs 100% on-device'));
      expect(notice, contains('~6s'));
      expect(notice, contains('BSD-3'));
      expect(notice, contains('Tiled processing prevents memory overflow'));
    });

    test('UpscaleResult model handles success and error cases', () {
      const success = UpscaleResult(
        isSuccess: true,
        outputPath: '/path/out.png',
        outputWidth: 3840,
        outputHeight: 2160,
        scaleFactor: 4,
        tilesProcessed: 16,
      );
      expect(success.isSuccess, isTrue);
      expect(success.outputWidth, 3840);
      expect(success.tilesProcessed, 16);
      expect(success.errorMessage, isNull);

      const failure = UpscaleResult(
        isSuccess: false,
        outputPath: '',
        outputWidth: 0,
        outputHeight: 0,
        scaleFactor: 4,
        tilesProcessed: 0,
        errorMessage: 'Out of memory',
      );
      expect(failure.isSuccess, isFalse);
      expect(failure.errorMessage, 'Out of memory');
    });
  });
}
