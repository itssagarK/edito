import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/highlight/models/character_highlight_config.dart';
import 'package:edito/features/highlight/services/character_highlight_compiler_service.dart';
import 'package:edito/features/cutout/models/smart_cutout_config.dart';
import 'package:edito/features/cutout/services/smart_cutout_compiler_service.dart';
import 'package:edito/core/ai/services/on_device_segmentation_service.dart';

void main() {
  group('CharacterHighlightConfig AI Segmentation Tests', () {
    test('Default configuration enables AI segmentation with safe fallbacks', () {
      const config = CharacterHighlightConfig();
      expect(config.isEnabled, isFalse);
      expect(config.useAiSegmentation, isTrue);
      expect(config.isAiSubjectDetected, isFalse);
      expect(config.characterCenterX, 0.5);
      expect(config.characterCenterY, 0.5);
      expect(config.maskPath, isNull);
      expect(config.subjectBbox, isNull);
    });

    test('copyWith updates AI fields correctly', () {
      const config = CharacterHighlightConfig();
      final updated = config.copyWith(
        isEnabled: true,
        useAiSegmentation: true,
        isAiSubjectDetected: true,
        characterCenterX: 0.62,
        characterCenterY: 0.38,
        maskPath: '/data/user/0/com.edito.app/cache/ai_masks/mask_1.png',
        subjectBbox: [0.2, 0.1, 0.8, 0.9],
      );

      expect(updated.isEnabled, isTrue);
      expect(updated.characterCenterX, 0.62);
      expect(updated.characterCenterY, 0.38);
      expect(updated.isAiSubjectDetected, isTrue);
      expect(updated.maskPath, equals('/data/user/0/com.edito.app/cache/ai_masks/mask_1.png'));
      expect(updated.subjectBbox, equals([0.2, 0.1, 0.8, 0.9]));
    });

    test('JSON serialization maintains 100% backward compatibility with legacy projects', () {
      // Legacy JSON without AI fields
      final legacyJson = <String, dynamic>{
        'isEnabled': true,
        'mode': 'spotlight',
        'highlightColor': 0xFF00FFCC,
        'highlightIntensity': 1.2,
        'spotlightRadius': 0.6,
        'feather': 0.45,
        'backgroundColor': 0xFF141419,
        'backgroundDimming': 0.7,
        'backgroundSaturation': 0.1,
        'characterCenterX': 0.45,
        'characterCenterY': 0.55,
      };

      final parsed = CharacterHighlightConfig.fromJson(legacyJson);
      expect(parsed.isEnabled, isTrue);
      expect(parsed.characterCenterX, 0.45);
      expect(parsed.characterCenterY, 0.55);
      expect(parsed.useAiSegmentation, isTrue); // Defaults to true
      expect(parsed.isAiSubjectDetected, isFalse);
      expect(parsed.maskPath, isNull);

      // Serialize back to JSON
      final serialized = parsed.toJson();
      expect(serialized['useAiSegmentation'], isTrue);
      expect(serialized['isAiSubjectDetected'], isFalse);
      expect(serialized['characterCenterX'], 0.45);
    });
  });

  group('SegmentationResult Tests', () {
    test('fromMap parses map correctly with bounding box and area ratio', () {
      final map = {
        'isSuccess': true,
        'maskPath': '/cache/mask.png',
        'centroidX': 0.48,
        'centroidY': 0.42,
        'bbox': [0.15, 0.10, 0.82, 0.94],
        'subjectAreaRatio': 0.32,
        'width': 1920,
        'height': 1080,
      };

      final result = SegmentationResult.fromMap(map);
      expect(result.isSuccess, isTrue);
      expect(result.maskPath, equals('/cache/mask.png'));
      expect(result.centroidX, 0.48);
      expect(result.centroidY, 0.42);
      expect(result.boundingBox, equals([0.15, 0.10, 0.82, 0.94]));
      expect(result.subjectAreaRatio, 0.32);
      expect(result.width, 1920);
      expect(result.height, 1080);
    });

    test('failure factory creates failed result with error message', () {
      final fail = SegmentationResult.failure('Device out of memory');
      expect(fail.isSuccess, isFalse);
      expect(fail.errorMessage, equals('Device out of memory'));
      expect(fail.maskPath, isNull);
    });
  });

  group('CharacterHighlightCompilerService Tests', () {
    test('generateFFmpegFilter compiles centered vignette from AI centroid', () {
      const config = CharacterHighlightConfig(
        isEnabled: true,
        mode: CharacterHighlightMode.spotlight,
        characterCenterX: 0.65,
        characterCenterY: 0.40,
        backgroundDimming: 0.70,
      );

      final filter = CharacterHighlightCompilerService.generateFFmpegFilter(config);
      expect(filter, contains('vignette='));
      expect(filter, contains('x0=w*0.65'));
      expect(filter, contains('y0=h*0.40'));
    });

    test('getHighlightBadge includes AI indicator when useAiSegmentation is true', () {
      const config = CharacterHighlightConfig(
        isEnabled: true,
        mode: CharacterHighlightMode.neonAura,
        useAiSegmentation: true,
      );

      final badge = CharacterHighlightCompilerService.getHighlightBadge(config);
      expect(badge, contains('🤖 AI'));
      expect(badge, contains('NEON AURA GLOW'));
    });

    test('getHighlightBadge omits AI indicator in manual mode', () {
      const config = CharacterHighlightConfig(
        isEnabled: true,
        mode: CharacterHighlightMode.spotlight,
        useAiSegmentation: false,
      );

      final badge = CharacterHighlightCompilerService.getHighlightBadge(config);
      expect(badge, isNot(contains('🤖 AI')));
      expect(badge, contains('CHARACTER SPOTLIGHT'));
    });
  });

  group('SmartCutoutCompilerService Tests', () {
    test('generateFFmpegFilters compiles transparent format for export', () {
      const config = SmartCutoutConfig(
        isEnabled: true,
        backgroundMode: CutoutBackgroundMode.transparent,
      );

      final filters = SmartCutoutCompilerService.generateFFmpegFilters(config);
      expect(filters, contains('format=yuva420p'));
    });

    test('generateFFmpegFilters compiles blur filter for portrait bokeh', () {
      const config = SmartCutoutConfig.presetPortraitBokeh;
      final filters = SmartCutoutCompilerService.generateFFmpegFilters(config);
      expect(filters.any((f) => f.contains('boxblur=')), isTrue);
    });
  });
}
