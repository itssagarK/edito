import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/character_zoom/models/character_zoom_config.dart';
import 'package:edito/features/character_zoom/services/character_zoom_compiler_service.dart';

void main() {
  group('CharacterZoomConfig Auto Tracking Tests', () {
    test('Default configuration enables auto-tracking with 70% smoothing', () {
      const config = CharacterZoomConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isAutoTrackingEnabled, isTrue);
      expect(config.isSubjectTracked, isFalse);
      expect(config.trackingSmoothing, 0.70);
      expect(config.characterCenterX, 0.50);
      expect(config.characterCenterY, 0.35);
    });

    test('applyEmaSmoothing calculates mathematically accurate smoothed focus coordinates', () {
      const initial = CharacterZoomConfig(
        characterCenterX: 0.50,
        characterCenterY: 0.35,
        trackingSmoothing: 0.70, // alpha = 0.30
      );

      // Raw detected coordinates from new video frame
      final smoothed = initial.applyEmaSmoothing(
        detectedX: 0.80,
        detectedY: 0.65,
      );

      // Expected X: 0.30 * 0.80 + 0.70 * 0.50 = 0.24 + 0.35 = 0.59
      // Expected Y: 0.30 * 0.65 + 0.70 * 0.35 = 0.195 + 0.245 = 0.44
      expect(smoothed.characterCenterX, closeTo(0.59, 0.001));
      expect(smoothed.characterCenterY, closeTo(0.44, 0.001));
      expect(smoothed.isSubjectTracked, isTrue);
    });

    test('Manual override disables isAutoTrackingEnabled', () {
      const config = CharacterZoomConfig(
        isAutoTrackingEnabled: true,
        characterCenterX: 0.50,
        characterCenterY: 0.35,
      );

      final overridden = config.copyWith(
        characterCenterX: 0.75,
        characterCenterY: 0.45,
        isAutoTrackingEnabled: false,
      );

      expect(overridden.isAutoTrackingEnabled, isFalse);
      expect(overridden.characterCenterX, 0.75);
      expect(overridden.characterCenterY, 0.45);
    });

    test('JSON serialization maintains 100% backward compatibility with legacy projects', () {
      final legacyJson = <String, dynamic>{
        'isEnabled': true,
        'mode': 'cinematicPushIn',
        'targetZoom': 1.6,
        'startZoom': 1.0,
        'characterCenterX': 0.48,
        'characterCenterY': 0.38,
        'animationDurationSec': 2.5,
        'startDelaySec': 0.0,
        'easing': 'easeInOut',
        'addFocusVignette': true,
        'addSubjectAura': false,
      };

      final parsed = CharacterZoomConfig.fromJson(legacyJson);
      expect(parsed.isEnabled, isTrue);
      expect(parsed.isAutoTrackingEnabled, isTrue); // Defaults to true
      expect(parsed.isSubjectTracked, isFalse);
      expect(parsed.trackingSmoothing, 0.70);
      expect(parsed.characterCenterX, 0.48);
      expect(parsed.characterCenterY, 0.38);

      final serialized = parsed.toJson();
      expect(serialized['isAutoTrackingEnabled'], isTrue);
      expect(serialized['trackingSmoothing'], 0.70);
    });
  });

  group('CharacterZoomCompilerService Tracking Tests', () {
    test('generateFFmpegFilter incorporates tracked coordinates into crop filter', () {
      const config = CharacterZoomConfig(
        isEnabled: true,
        mode: CharacterZoomMode.punchIn,
        targetZoom: 1.5,
        characterCenterX: 0.62,
        characterCenterY: 0.40,
      );

      final filter = CharacterZoomCompilerService.generateFFmpegFilter(config);
      expect(filter, contains('crop='));
      expect(filter, contains('0.62'));
      expect(filter, contains('0.40'));
      expect(filter, contains('scale=1920:1080:flags=lanczos'));
    });

    test('getZoomBadge includes AI indicator when auto-tracking is active', () {
      const config = CharacterZoomConfig(
        isEnabled: true,
        mode: CharacterZoomMode.cinematicPushIn,
        targetZoom: 1.5,
        isAutoTrackingEnabled: true,
      );

      final badge = CharacterZoomCompilerService.getZoomBadge(config);
      expect(badge, contains('🤖 AI TRACK'));
      expect(badge, contains('CHARACTER ZOOM'));
    });

    test('getZoomBadge omits AI indicator during manual override', () {
      const config = CharacterZoomConfig(
        isEnabled: true,
        mode: CharacterZoomMode.cinematicPushIn,
        targetZoom: 1.5,
        isAutoTrackingEnabled: false,
      );

      final badge = CharacterZoomCompilerService.getZoomBadge(config);
      expect(badge, isNot(contains('🤖 AI TRACK')));
      expect(badge, contains('CHARACTER ZOOM'));
    });
  });
}
