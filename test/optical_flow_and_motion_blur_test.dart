import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/smoothing/models/video_smoother_config.dart';
import 'package:edito/features/smoothing/services/ai_video_smoother_service.dart';

void main() {
  group('Optical Flow Frame Blending & Velocity Motion Blur Studio Tests', () {
    test('MotionInterpolationMode and MotionBlurDirection enums provide descriptive labels', () {
      expect(MotionInterpolationMode.none.label, equals('Native Off'));
      expect(MotionInterpolationMode.frameBlend.label, contains('Frame Blend'));
      expect(MotionInterpolationMode.opticalFlow.label, contains('Optical Flow'));

      expect(MotionBlurDirection.omnidirectional.label, equals('Omnidirectional'));
      expect(MotionBlurDirection.horizontal.label, equals('Horizontal Pan'));
      expect(MotionBlurDirection.vertical.label, equals('Vertical Tilt'));
    });

    test('VideoSmootherConfig defaults and hasActiveSmoothing behavior', () {
      const defaultConfig = VideoSmootherConfig();
      expect(defaultConfig.hasActiveSmoothing, isFalse);
      expect(defaultConfig.effectiveInterpolationMode, equals(MotionInterpolationMode.none));
      expect(defaultConfig.shutterAngle, equals(180.0));
      expect(defaultConfig.motionBlurSamples, equals(6));
      expect(defaultConfig.motionBlurIntensity, equals(0.65));

      final flowConfig = defaultConfig.copyWith(interpolationMode: MotionInterpolationMode.opticalFlow);
      expect(flowConfig.hasActiveSmoothing, isTrue);

      final blurConfig = defaultConfig.copyWith(isMotionBlurEnabled: true);
      expect(blurConfig.hasActiveSmoothing, isTrue);
    });

    test('VideoSmootherConfig resolves legacy isMotionSmoothingEnabled to opticalFlow', () {
      const legacyConfig = VideoSmootherConfig(isMotionSmoothingEnabled: true);
      expect(legacyConfig.effectiveInterpolationMode, equals(MotionInterpolationMode.opticalFlow));
    });

    test('VideoSmootherConfig presets configure expected cinematic parameters', () {
      final cinema180 = VideoSmootherConfig.getPresetConfig(SmootherPreset.cinema180Shutter);
      expect(cinema180.isMotionBlurEnabled, isTrue);
      expect(cinema180.shutterAngle, equals(180.0));
      expect(cinema180.motionBlurSamples, equals(8));

      final action90 = VideoSmootherConfig.getPresetConfig(SmootherPreset.action90Shutter);
      expect(action90.isMotionBlurEnabled, isTrue);
      expect(action90.shutterAngle, equals(90.0));

      final hyper120 = VideoSmootherConfig.getPresetConfig(SmootherPreset.hyper120fps);
      expect(hyper120.effectiveInterpolationMode, equals(MotionInterpolationMode.opticalFlow));
      expect(hyper120.targetFps, equals(120));

      final frameBlend = VideoSmootherConfig.getPresetConfig(SmootherPreset.frameBlendNatural);
      expect(frameBlend.effectiveInterpolationMode, equals(MotionInterpolationMode.frameBlend));

      final streak360 = VideoSmootherConfig.getPresetConfig(SmootherPreset.dreamyStreak360);
      expect(streak360.shutterAngle, equals(360.0));
      expect(streak360.motionBlurDirection, equals(MotionBlurDirection.horizontal));
    });

    test('VideoSmootherConfig JSON serialization roundtrip preserves all flow and blur attributes', () {
      const config = VideoSmootherConfig(
        interpolationMode: MotionInterpolationMode.opticalFlow,
        targetFps: 120,
        isMotionBlurEnabled: true,
        shutterAngle: 270.0,
        motionBlurSamples: 10,
        motionBlurIntensity: 0.85,
        motionBlurDirection: MotionBlurDirection.horizontal,
        isStabilizationEnabled: true,
        stabilizationStrength: 0.90,
        preset: SmootherPreset.hyper120fps,
      );

      final json = config.toJson();
      final restored = VideoSmootherConfig.fromJson(json);

      expect(restored.interpolationMode, equals(MotionInterpolationMode.opticalFlow));
      expect(restored.targetFps, equals(120));
      expect(restored.isMotionBlurEnabled, isTrue);
      expect(restored.shutterAngle, equals(270.0));
      expect(restored.motionBlurSamples, equals(10));
      expect(restored.motionBlurIntensity, equals(0.85));
      expect(restored.motionBlurDirection, equals(MotionBlurDirection.horizontal));
      expect(restored.isStabilizationEnabled, isTrue);
      expect(restored.stabilizationStrength, equals(0.90));
    });

    test('AIVideoSmootherService generates optical flow minterpolate filter', () {
      const config = VideoSmootherConfig(
        interpolationMode: MotionInterpolationMode.opticalFlow,
        targetFps: 120,
      );

      final filters = AIVideoSmootherService.generateFFmpegFilters(config);
      expect(filters.any((f) => f.contains('minterpolate=fps=120:mi_mode=mci')), isTrue);
    });

    test('AIVideoSmootherService generates frame blend tblend filter', () {
      const config = VideoSmootherConfig(
        interpolationMode: MotionInterpolationMode.frameBlend,
        targetFps: 60,
      );

      final filters = AIVideoSmootherService.generateFFmpegFilters(config);
      expect(filters.any((f) => f.contains('tblend=all_mode=average')), isTrue);
      expect(filters.any((f) => f.contains('fps=fps=60:round=near')), isTrue);
    });

    test('AIVideoSmootherService generates velocity shutter angle tmix filter with normalized weights', () {
      const config = VideoSmootherConfig(
        isMotionBlurEnabled: true,
        shutterAngle: 180.0,
        motionBlurSamples: 6,
        motionBlurIntensity: 0.70,
      );

      final filters = AIVideoSmootherService.generateFFmpegFilters(config);
      expect(filters.any((f) => f.contains('tmix=frames=6:weights=')), isTrue);
    });

    test('AIVideoSmootherService generates directional gblur for horizontal motion blur', () {
      const config = VideoSmootherConfig(
        isMotionBlurEnabled: true,
        shutterAngle: 180.0,
        motionBlurDirection: MotionBlurDirection.horizontal,
        motionBlurIntensity: 0.80,
      );

      final filters = AIVideoSmootherService.generateFFmpegFilters(config);
      expect(filters.any((f) => f.contains('gblur=sigma=')), isTrue);
    });

    test('AIVideoSmootherService getSmootherBadge produces correct status badges', () {
      const empty = VideoSmootherConfig();
      expect(AIVideoSmootherService.getSmootherBadge(empty), isEmpty);

      const opticalFlowOnly = VideoSmootherConfig(
        interpolationMode: MotionInterpolationMode.opticalFlow,
        targetFps: 60,
      );
      expect(AIVideoSmootherService.getSmootherBadge(opticalFlowOnly), equals('🌊 OPTICAL FLOW (60FPS)'));

      const frameBlendOnly = VideoSmootherConfig(
        interpolationMode: MotionInterpolationMode.frameBlend,
        targetFps: 60,
      );
      expect(AIVideoSmootherService.getSmootherBadge(frameBlendOnly), equals('🔄 FRAME BLEND (60FPS)'));

      const blurOnly = VideoSmootherConfig(
        isMotionBlurEnabled: true,
        shutterAngle: 180.0,
      );
      expect(AIVideoSmootherService.getSmootherBadge(blurOnly), equals('🌪️ MOTION BLUR (180°)'));

      const blurAndFlow = VideoSmootherConfig(
        isMotionBlurEnabled: true,
        shutterAngle: 180.0,
        interpolationMode: MotionInterpolationMode.opticalFlow,
        targetFps: 120,
      );
      expect(AIVideoSmootherService.getSmootherBadge(blurAndFlow), equals('🌪️ BLUR (180°) + 🌊 120FPS'));
    });
  });
}
