import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/transitions/models/transition_type.dart';
import 'package:edito/features/transitions/presentation/widgets/transition_shader_painter.dart';
import 'package:edito/features/transitions/services/transition_compiler_service.dart';

void main() {
  group('Feature 17 - TransitionType & TransitionConfig Domain Model Tests', () {
    test('All 18 TransitionType values define non-empty labels, descriptions, and icons', () {
      expect(TransitionType.values.length, 18);

      for (final type in TransitionType.values) {
        expect(type.label.isNotEmpty, isTrue);
        expect(type.description.isNotEmpty, isTrue);
        expect(type.icon, isNotNull);
        expect(type.category, isNotNull);

        if (type != TransitionType.none) {
          expect(type.ffmpegXFadeName.isNotEmpty, isTrue);
        }
      }
    });

    test('Cinematic Pro transitions are mapped to expected categories', () {
      expect(TransitionType.crossDissolve.category, TransitionCategory.basic);
      expect(TransitionType.fadeBlack.category, TransitionCategory.basic);
      expect(TransitionType.fadeWhite.category, TransitionCategory.basic);

      expect(TransitionType.whipPanLeft.category, TransitionCategory.whip);
      expect(TransitionType.whipPanRight.category, TransitionCategory.whip);
      expect(TransitionType.slideUp.category, TransitionCategory.whip);
      expect(TransitionType.slideDown.category, TransitionCategory.whip);

      expect(TransitionType.filmBurn.category, TransitionCategory.cinematic);
      expect(TransitionType.lensFlash.category, TransitionCategory.cinematic);

      expect(TransitionType.glitchDisplace.category, TransitionCategory.distortion);
      expect(TransitionType.spinClockwise.category, TransitionCategory.distortion);
      expect(TransitionType.spinCounterClockwise.category, TransitionCategory.distortion);
      expect(TransitionType.directionalWarp.category, TransitionCategory.distortion);
      expect(TransitionType.pixelateDissolve.category, TransitionCategory.distortion);
    });

    test('TransitionEasing provides valid Curves and labels', () {
      for (final easing in TransitionEasing.values) {
        expect(easing.label.isNotEmpty, isTrue);
        expect(easing.curve, isNotNull);
      }
      expect(TransitionEasing.easeInOut.curve, Curves.easeInOutCubic);
      expect(TransitionEasing.springPunch.curve, Curves.elasticOut);
    });

    test('TransitionConfig JSON serialization and deserialization retains all fields', () {
      const original = TransitionConfig(
        type: TransitionType.whipPanLeft,
        durationMs: 750,
        easing: TransitionEasing.springPunch,
        playSfx: true,
      );

      final json = original.toJson();
      final restored = TransitionConfig.fromJson(json);

      expect(restored.type, TransitionType.whipPanLeft);
      expect(restored.durationMs, 750);
      expect(restored.easing, TransitionEasing.springPunch);
      expect(restored.playSfx, isTrue);
      expect(restored.isEnabled, isTrue);
      expect(restored, equals(original));
    });

    test('Default TransitionConfig is disabled with neutral parameters', () {
      const def = TransitionConfig();
      expect(def.type, TransitionType.none);
      expect(def.durationMs, 500);
      expect(def.easing, TransitionEasing.easeInOut);
      expect(def.playSfx, isFalse);
      expect(def.isEnabled, isFalse);
    });
  });

  group('Feature 17 - TransitionCompilerService Tests', () {
    test('generateFFmpegXFade produces valid filter syntax for active transitions', () {
      const config = TransitionConfig(
        type: TransitionType.whipPanLeft,
        durationMs: 600,
      );

      final filter = TransitionCompilerService.generateFFmpegXFade(config, offsetSec: 4.5);
      expect(filter, 'xfade=transition=wipeleft:duration=0.60:offset=4.50');
    });

    test('generateFFmpegXFade returns empty string for disabled transitions', () {
      const config = TransitionConfig(type: TransitionType.none);
      final filter = TransitionCompilerService.generateFFmpegXFade(config, offsetSec: 3.0);
      expect(filter, isEmpty);
    });

    test('calculateOverlapMs clamps transition duration within safe boundaries', () {
      const normal = TransitionConfig(type: TransitionType.filmBurn, durationMs: 800);
      expect(TransitionCompilerService.calculateOverlapMs(normal), 800);

      const disabled = TransitionConfig(type: TransitionType.none, durationMs: 500);
      expect(TransitionCompilerService.calculateOverlapMs(disabled), 0);

      const ultraLong = TransitionConfig(type: TransitionType.glitchDisplace, durationMs: 9000);
      expect(TransitionCompilerService.calculateOverlapMs(ultraLong), 3000);
    });

    test('compileTimelineTransitions generates multi-clip xfade filter chain with cumulative offsets', () {
      const clip1 = Clip(
        id: 'c1',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      const clip2 = Clip(
        id: 'c2',
        assetId: 'a2',
        trackId: 't1',
        startTimeMs: 4500,
        durationMs: 6000,
        sourceInMs: 0,
        sourceOutMs: 6000,
        transitionIn: TransitionConfig(
          type: TransitionType.filmBurn,
          durationMs: 500,
        ),
      );

      const clip3 = Clip(
        id: 'c3',
        assetId: 'a3',
        trackId: 't1',
        startTimeMs: 9900,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        transitionIn: TransitionConfig(
          type: TransitionType.glitchDisplace,
          durationMs: 600,
        ),
      );

      final result = TransitionCompilerService.compileTimelineTransitions([clip1, clip2, clip3]);

      expect(result.hasTransitions, isTrue);
      expect(result.transitionCount, 2);
      expect(result.filterGraph, contains('xfade=transition=smoothdown:duration=0.50:offset=4.50'));
      expect(result.filterGraph, contains('xfade=transition=pixelize:duration=0.60:offset=9.90'));
      expect(result.outputLabel, '[outv]');
      expect(result.totalDurationMs, equals((5000 - 500 + 6000 - 600 + 4000)));
    });

    test('getTransitionBadge returns human-readable status', () {
      const active = TransitionConfig(
        type: TransitionType.lensFlash,
        durationMs: 800,
      );
      expect(TransitionCompilerService.getTransitionBadge(active), contains('Anamorphic Flash'));
      expect(TransitionCompilerService.getTransitionBadge(active), contains('0.8s'));

      const inactive = TransitionConfig();
      expect(TransitionCompilerService.getTransitionBadge(inactive), 'No Transition');
    });
  });

  group('Feature 17 - TransitionShaderPainter Skia Tests', () {
    test('TransitionShaderPainter instantiates and triggers repaint on progress update', () {
      final painter1 = TransitionShaderPainter(
        progress: 0.25,
        type: TransitionType.whipPanLeft,
        easing: TransitionEasing.easeInOut,
      );

      final painter2 = TransitionShaderPainter(
        progress: 0.50,
        type: TransitionType.whipPanLeft,
        easing: TransitionEasing.easeInOut,
      );

      final painter3 = TransitionShaderPainter(
        progress: 0.25,
        type: TransitionType.filmBurn,
        easing: TransitionEasing.easeInOut,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
      expect(painter1.shouldRepaint(painter3), isTrue);
      expect(painter1.shouldRepaint(painter1), isFalse);
    });
  });
}
