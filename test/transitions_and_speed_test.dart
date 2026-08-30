import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/color_grading/models/color_grading_config.dart';
import 'package:edito/features/speed/models/speed_curve_preset.dart';
import 'package:edito/features/speed/services/speed_ramping_service.dart';
import 'package:edito/features/transitions/models/transition_type.dart';
import 'package:edito/features/transitions/services/transition_compiler_service.dart';

void main() {
  group('Transitions & Speed Ramping Engine Tests', () {
    test('TransitionConfig JSON serialization roundtrip', () {
      const config = TransitionConfig(
        type: TransitionType.crossDissolve,
        durationMs: 750,
      );

      final json = config.toJson();
      final restored = TransitionConfig.fromJson(json);

      expect(restored.type, equals(TransitionType.crossDissolve));
      expect(restored.durationMs, equals(750));
      expect(restored.isEnabled, isTrue);
    });

    test('TransitionCompilerService generates valid FFmpeg xfade filter expression', () {
      const configFade = TransitionConfig(
        type: TransitionType.crossDissolve,
        durationMs: 500,
      );
      final fadeStr = TransitionCompilerService.generateFFmpegXFade(configFade, offsetSec: 4.5);
      expect(fadeStr, equals('xfade=transition=fade:duration=0.50:offset=4.50'));

      const configWipe = TransitionConfig(
        type: TransitionType.wipeLeft,
        durationMs: 1000,
      );
      final wipeStr = TransitionCompilerService.generateFFmpegXFade(configWipe, offsetSec: 8.0);
      expect(wipeStr, equals('xfade=transition=wipeleft:duration=1.00:offset=8.00'));
    });

    test('SpeedCurveConfig JSON serialization roundtrip', () {
      final config = SpeedCurveConfig(
        type: SpeedCurveType.montage,
        constantSpeed: 1.0,
        enablePitchCorrection: true,
        curvePoints: SpeedCurveType.montage.defaultCurvePoints,
      );

      final json = config.toJson();
      final restored = SpeedCurveConfig.fromJson(json);

      expect(restored.type, equals(SpeedCurveType.montage));
      expect(restored.enablePitchCorrection, isTrue);
      expect(restored.curvePoints.length, equals(4));
    });

    test('SpeedRampingService calculates accurate source offset under constant speed', () {
      const clip = Clip(
        id: 'c_speed',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 10000,
        speed: 2.0,
      );

      final sourceOffset = SpeedRampingService.calculateSourceOffset(clip, 2500);
      expect(sourceOffset, equals(5000)); // 2500 * 2.0 = 5000ms
    });

    test('SpeedRampingService generates atempo filter chain for audio pitch preservation', () {
      // 1.5x speed (single atempo)
      final filter1_5 = SpeedRampingService.generateAudioSpeedFilter(1.5);
      expect(filter1_5, equals('atempo=1.50'));

      // 3.0x speed (chained atempo: 2.0 * 1.5)
      final filter3_0 = SpeedRampingService.generateAudioSpeedFilter(3.0);
      expect(filter3_0, contains('atempo=2.0'));
      expect(filter3_0, contains('atempo=1.50'));

      // 0.3x speed (slow-mo atempo chain)
      final filter0_3 = SpeedRampingService.generateAudioSpeedFilter(0.3);
      expect(filter0_3, contains('atempo=0.5'));
    });
  });
}
