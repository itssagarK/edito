import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/enhancement/models/video_enhancement_config.dart';
import 'package:edito/features/enhancement/services/ai_video_enhancer_service.dart';
import 'package:edito/features/export/models/export_preset.dart';

void main() {
  group('Video & Photo 8K Enhancement Tests', () {
    test('VideoEnhancementConfig JSON serialization roundtrip', () {
      const config = VideoEnhancementConfig(
        is8kUpscaleEnabled: true,
        isAiSuperResolutionEnabled: true,
        sharpness: 1.5,
        deNoise: 0.3,
        isHdrToneMapping: true,
        clarity: 1.2,
        isColorPop: true,
        modelPreset: EnhanceModelPreset.ultraCinema8k,
      );

      final json = config.toJson();
      final restored = VideoEnhancementConfig.fromJson(json);

      expect(restored.is8kUpscaleEnabled, isTrue);
      expect(restored.isAiSuperResolutionEnabled, isTrue);
      expect(restored.sharpness, equals(1.5));
      expect(restored.deNoise, equals(0.3));
      expect(restored.isHdrToneMapping, isTrue);
      expect(restored.clarity, equals(1.2));
      expect(restored.isColorPop, isTrue);
      expect(restored.modelPreset, equals(EnhanceModelPreset.ultraCinema8k));
    });

    test('AIVideoEnhancerService generates 8K Lanczos scaling and unsharp filters', () {
      const config = VideoEnhancementConfig(
        is8kUpscaleEnabled: true,
        isAiSuperResolutionEnabled: true,
        sharpness: 1.4,
        deNoise: 0.2,
        isHdrToneMapping: true,
      );

      final filters = AIVideoEnhancerService.generateFFmpegFilters(config);

      // Should contain de-noise
      expect(filters.any((f) => f.contains('hqdn3d=')), isTrue);
      // Should contain 8K Lanczos scale
      expect(filters.any((f) => f.contains('scale=7680:4320:flags=lanczos')), isTrue);
      // Should contain unsharp mask
      expect(filters.any((f) => f.contains('unsharp=5:5:')), isTrue);
      // Should contain HDR tone mapping
      expect(filters.any((f) => f.contains('eq=contrast=1.15')), isTrue);
    });

    test('ExportResolution enum includes 8K Ultra HD with 7680x4320 dimensions', () {
      const res8k = ExportResolution.res8k;
      expect(res8k.width, equals(7680));
      expect(res8k.height, equals(4320));
      expect(res8k.label, contains('8K Ultra HD'));
      expect(res8k.baseBitrateMbps, equals(80.0));
    });
  });
}
