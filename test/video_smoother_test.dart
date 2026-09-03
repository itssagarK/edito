import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/smoothing/models/video_smoother_config.dart';
import 'package:edito/features/smoothing/services/ai_video_smoother_service.dart';

void main() {
  group('Video Smoother & Anti-Flutter Tests', () {
    test('VideoSmootherConfig JSON serialization roundtrip', () {
      const config = VideoSmootherConfig(
        isStabilizationEnabled: true,
        stabilizationStrength: 0.85,
        isMotionSmoothingEnabled: true,
        targetFps: 60,
        isDeGlitchEnabled: true,
        isDeFlickerEnabled: true,
        preset: SmootherPreset.gimbalSmooth,
      );

      final json = config.toJson();
      final restored = VideoSmootherConfig.fromJson(json);

      expect(restored.isStabilizationEnabled, isTrue);
      expect(restored.stabilizationStrength, equals(0.85));
      expect(restored.isMotionSmoothingEnabled, isTrue);
      expect(restored.targetFps, equals(60));
      expect(restored.isDeGlitchEnabled, isTrue);
      expect(restored.isDeFlickerEnabled, isTrue);
      expect(restored.preset, equals(SmootherPreset.gimbalSmooth));
    });

    test('AIVideoSmootherService generates correct deshake, minterpolate, and de-glitch filters', () {
      const config = VideoSmootherConfig(
        isStabilizationEnabled: true,
        stabilizationStrength: 0.80,
        isMotionSmoothingEnabled: true,
        targetFps: 60,
        isDeGlitchEnabled: true,
        isDeFlickerEnabled: true,
      );

      final filters = AIVideoSmootherService.generateFFmpegFilters(config);

      // 1. Anti-Flicker
      expect(filters.any((f) => f.contains('deflicker=')), isTrue);
      // 2. De-glitch / anti-flutter
      expect(filters.any((f) => f == 'mpdecimate'), isTrue);
      expect(filters.any((f) => f.contains('fps=fps=60:round=near')), isTrue);
      // 3. AI Camera Stabilization (deshake)
      expect(filters.any((f) => f.contains('deshake=') && f.contains('edge=mirror')), isTrue);
      // 4. Optical Flow 60fps Motion Interpolation
      expect(filters.any((f) => f.contains('minterpolate=fps=60')), isTrue);
    });

    test('Smoother presets configure expected properties', () {
      const gimbalConfig = VideoSmootherConfig(
        isStabilizationEnabled: true,
        isMotionSmoothingEnabled: true,
        preset: SmootherPreset.gimbalSmooth,
      );
      expect(AIVideoSmootherService.getSmootherBadge(gimbalConfig), equals('GIMBAL + 60FPS'));

      const antiGlitchConfig = VideoSmootherConfig(
        isDeGlitchEnabled: true,
        preset: SmootherPreset.antiGlitch,
      );
      expect(AIVideoSmootherService.getSmootherBadge(antiGlitchConfig), equals('ANTI-GLITCH'));
    });
  });
}
