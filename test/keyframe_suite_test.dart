import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/overlays/models/keyframe.dart';
import 'package:edito/features/keyframes/services/keyframe_evaluator_service.dart';

void main() {
  group('Universal Keyframe Model Tests', () {
    test('Default Keyframe is centered, unscaled and neutral', () {
      const k = Keyframe(timeOffsetMs: 500);
      expect(k.timeOffsetMs, 500);
      expect(k.positionX, 0.5);
      expect(k.positionY, 0.5);
      expect(k.scale, 1.0);
      expect(k.rotation, 0.0);
      expect(k.opacity, 1.0);
      expect(k.easing, KeyframeEasing.easeInOut);
    });

    test('Keyframe copyWith modifies properties cleanly', () {
      const k = Keyframe(timeOffsetMs: 0);
      final updated = k.copyWith(
        timeOffsetMs: 1200,
        positionX: 0.8,
        positionY: 0.2,
        scale: 1.5,
        rotation: 45.0,
        opacity: 0.75,
        easing: KeyframeEasing.bounce,
      );

      expect(updated.timeOffsetMs, 1200);
      expect(updated.positionX, 0.8);
      expect(updated.positionY, 0.2);
      expect(updated.scale, 1.5);
      expect(updated.rotation, 45.0);
      expect(updated.opacity, 0.75);
      expect(updated.easing, KeyframeEasing.bounce);
    });

    test('Keyframe serializes and deserializes accurately', () {
      const original = Keyframe(
        timeOffsetMs: 2500,
        positionX: 0.3,
        positionY: 0.7,
        scale: 2.0,
        rotation: -90.0,
        opacity: 0.5,
        easing: KeyframeEasing.easeOut,
      );

      final json = original.toJson();
      final deserialized = Keyframe.fromJson(json);

      expect(deserialized, equals(original));
      expect(deserialized.timeOffsetMs, 2500);
      expect(deserialized.easing, KeyframeEasing.easeOut);
    });

    test('KeyframeEasing evaluations hold boundary conditions', () {
      for (final easing in KeyframeEasing.values) {
        expect(easing.evaluate(0.0), closeTo(0.0, 0.001));
        expect(easing.evaluate(1.0), closeTo(1.0, 0.001));
      }

      // Linear midpoint is exactly 0.5
      expect(KeyframeEasing.linear.evaluate(0.5), closeTo(0.5, 0.001));
      // EaseIn at 0.5 is 0.25 (slower start)
      expect(KeyframeEasing.easeIn.evaluate(0.5), closeTo(0.25, 0.001));
      // EaseOut at 0.5 is 0.75 (faster start)
      expect(KeyframeEasing.easeOut.evaluate(0.5), closeTo(0.75, 0.001));
    });
  });

  group('KeyframeEvaluatorService Tests', () {
    test('Empty keyframes returns neutral un-transformed values', () {
      final values = KeyframeEvaluatorService.evaluateTransformAt([], 1500);
      expect(values.isTransformed, false);
      expect(values.positionX, 0.5);
      expect(values.positionY, 0.5);
      expect(values.scale, 1.0);
      expect(values.rotation, 0.0);
      expect(values.opacity, 1.0);
    });

    test('Interpolates scale and position between keyframes with linear easing', () {
      final keyframes = [
        const Keyframe(timeOffsetMs: 0, scale: 1.0, positionX: 0.0, easing: KeyframeEasing.linear),
        const Keyframe(timeOffsetMs: 2000, scale: 2.0, positionX: 1.0, easing: KeyframeEasing.linear),
      ];

      // At t = 0ms
      final vStart = KeyframeEvaluatorService.evaluateTransformAt(keyframes, 0);
      expect(vStart.scale, closeTo(1.0, 0.01));
      expect(vStart.positionX, closeTo(0.0, 0.01));

      // At t = 1000ms (50% progress)
      final vMid = KeyframeEvaluatorService.evaluateTransformAt(keyframes, 1000);
      expect(vMid.scale, closeTo(1.5, 0.01));
      expect(vMid.positionX, closeTo(0.5, 0.01));

      // At t = 2000ms
      final vEnd = KeyframeEvaluatorService.evaluateTransformAt(keyframes, 2000);
      expect(vEnd.scale, closeTo(2.0, 0.01));
      expect(vEnd.positionX, closeTo(1.0, 0.01));
    });

    test('Preset keyframes generate active keyframes', () {
      final zoomIn = KeyframeEvaluatorService.generatePresetKeyframes(KeyframePreset.slowZoomIn, 5000);
      expect(zoomIn.length, 2);
      expect(zoomIn.first.scale, 1.0);
      expect(zoomIn.last.scale, 1.25);

      final spinPop = KeyframeEvaluatorService.generatePresetKeyframes(KeyframePreset.spinAndPop, 4000);
      expect(spinPop.isNotEmpty, true);
      expect(spinPop.first.rotation, -180.0);
      expect(spinPop.first.opacity, 0.0);
    });

    test('generateFFmpegTransformFilters produces proper in-stream filters', () {
      final keyframes = [
        const Keyframe(timeOffsetMs: 0, opacity: 0.0, rotation: 0.0),
        const Keyframe(timeOffsetMs: 1000, opacity: 1.0, rotation: 90.0),
      ];

      final filters = KeyframeEvaluatorService.generateFFmpegTransformFilters(
        keyframes,
        clipDurationMs: 2000,
        targetWidth: 1920,
        targetHeight: 1080,
      );

      expect(filters, contains('format=yuva420p'));
      expect(filters.any((f) => f.contains('colorchannelmixer=aa=')), true);
      expect(filters.any((f) => f.contains('rotate=')), true);
    });
  });

  group('Clip Domain Integration with Universal Keyframes Tests', () {
    test('Clip stores and copies keyframes properly', () {
      const clip = Clip(
        id: 'clip_kf',
        assetId: 'asset_kf',
        trackId: 'track_v0',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      expect(clip.keyframes, isEmpty);

      final updated = clip.copyWith(
        keyframes: [
          const Keyframe(timeOffsetMs: 0, scale: 1.0),
          const Keyframe(timeOffsetMs: 4000, scale: 1.4, easing: KeyframeEasing.easeOut),
        ],
      );

      expect(updated.keyframes.length, 2);
      expect(updated.keyframes.last.scale, 1.4);
      expect(updated.keyframes.last.easing, KeyframeEasing.easeOut);
    });

    test('Clip with keyframes serializes and deserializes properly', () {
      const clip = Clip(
        id: 'clip_kf_json',
        assetId: 'asset_kf_json',
        trackId: 'track_v0',
        startTimeMs: 1000,
        durationMs: 3000,
        sourceInMs: 0,
        sourceOutMs: 3000,
        keyframes: [
          Keyframe(timeOffsetMs: 0, scale: 1.0, rotation: 0.0, easing: KeyframeEasing.linear),
          Keyframe(timeOffsetMs: 3000, scale: 1.5, rotation: 45.0, easing: KeyframeEasing.bounce),
        ],
      );

      final json = clip.toJson();
      final revived = Clip.fromJson(json);

      expect(revived.keyframes.length, 2);
      expect(revived.keyframes.first.scale, 1.0);
      expect(revived.keyframes.last.rotation, 45.0);
      expect(revived.keyframes.last.easing, KeyframeEasing.bounce);
    });
  });
}
