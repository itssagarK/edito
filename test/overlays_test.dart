import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/overlays/models/keyframe.dart';
import 'package:edito/features/overlays/models/text_overlay_config.dart';
import 'package:edito/features/overlays/services/overlay_compiler_service.dart';

void main() {
  group('Text, Motion Titles & Overlays Tests', () {
    test('TextOverlayConfig JSON serialization roundtrip', () {
      const config = TextOverlayConfig(
        text: 'Cinematic Masterpiece',
        fontFamily: 'Montserrat',
        fontSize: 32.0,
        textColor: 0xFFFFEAA7,
        backgroundColor: 0x80000000,
        positionX: 0.5,
        positionY: 0.8,
        scale: 1.2,
        rotation: 5.0,
        opacity: 0.9,
        animationType: TextAnimationType.typewriter,
      );

      final json = config.toJson();
      final restored = TextOverlayConfig.fromJson(json);

      expect(restored.text, equals('Cinematic Masterpiece'));
      expect(restored.fontFamily, equals('Montserrat'));
      expect(restored.fontSize, equals(32.0));
      expect(restored.textColor, equals(0xFFFFEAA7));
      expect(restored.positionX, equals(0.5));
      expect(restored.positionY, equals(0.8));
      expect(restored.animationType, equals(TextAnimationType.typewriter));
    });

    test('Keyframe linear interpolation calculates intermediate position and scale', () {
      const clip = Clip(
        id: 'c_keyframe',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        textOverlay: TextOverlayConfig(text: 'Moving Title'),
        keyframes: [
          Keyframe(timeOffsetMs: 0, positionX: 0.0, positionY: 0.0, scale: 1.0),
          Keyframe(timeOffsetMs: 2000, positionX: 1.0, positionY: 1.0, scale: 2.0),
        ],
      );

      // At midpoint (1000ms): position should be (0.5, 0.5) and scale 1.5
      final evaluated = OverlayCompilerService.evaluateOverlayAt(clip, 1000);
      expect(evaluated.positionX, closeTo(0.5, 0.01));
      expect(evaluated.positionY, closeTo(0.5, 0.01));
      expect(evaluated.scale, closeTo(1.5, 0.01));
    });

    test('OverlayCompilerService generates valid FFmpeg drawtext filter string', () {
      const clip = Clip(
        id: 'c_text',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 1000,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      const config = TextOverlayConfig(
        text: 'Episode 1: The Beginning',
        fontSize: 28.0,
        positionX: 0.5,
        positionY: 0.85,
        backgroundColor: 0x80000000,
      );

      final filterStr = OverlayCompilerService.generateFFmpegDrawText(clip, config);

      expect(filterStr, contains("drawtext=text='Episode 1\\: The Beginning'"));
      expect(filterStr, contains('fontsize=28'));
      expect(filterStr, contains('fontcolor=white'));
      expect(filterStr, contains("enable='between(t,1.00,6.00)'"));
      expect(filterStr, contains('box=1'));
    });
  });
}
