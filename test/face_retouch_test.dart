import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/retouch/models/face_retouch_config.dart';
import 'package:edito/features/retouch/services/face_retouch_compiler_service.dart';
import 'package:edito/features/retouch/presentation/widgets/face_retouch_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature 24: CapCut Pro AI Face & Body Retouching Studio Tests', () {
    test('SkinToneStyle enums have labels, descriptions, and color previews', () {
      expect(SkinToneStyle.natural.label, contains('Natural'));
      expect(SkinToneStyle.porcelain.label, contains('Porcelain'));
      expect(SkinToneStyle.warmPeach.label, contains('Peach'));
      expect(SkinToneStyle.goldenHoney.label, contains('Golden'));
      expect(SkinToneStyle.bronzeSun.label, contains('Bronze'));
      expect(SkinToneStyle.cinemaSoft.label, contains('Cinema'));

      expect(SkinToneStyle.porcelain.previewColor, isNonZero);
      expect(SkinToneStyle.goldenHoney.description, contains('golden'));
    });

    test('RetouchPreset enums provide distinct beauty preset names', () {
      expect(RetouchPreset.none.label, contains('None'));
      expect(RetouchPreset.naturalGlow.label, contains('Natural Glow'));
      expect(RetouchPreset.porcelainFlawless.label, contains('Porcelain Flawless'));
      expect(RetouchPreset.goldenHour.label, contains('Golden Hour'));
      expect(RetouchPreset.glamourPortrait.label, contains('Glamour Portrait'));
    });

    test('FaceRetouchConfig model supports full JSON roundtrip and copyWith', () {
      const config = FaceRetouchConfig(
        isEnabled: true,
        skinSmooth: 0.65,
        skinRadiance: 0.40,
        skinTone: SkinToneStyle.porcelain,
        eyeBrighten: 0.35,
        teethWhiten: 0.30,
        darkCircles: 0.45,
        faceSlimming: 0.25,
        waistSlimming: 0.15,
        legLengthening: 0.10,
        activePreset: RetouchPreset.porcelainFlawless,
      );

      final json = config.toJson();
      expect(json['isEnabled'], isTrue);
      expect(json['skinSmooth'], equals(0.65));
      expect(json['skinRadiance'], equals(0.40));
      expect(json['skinTone'], equals('porcelain'));
      expect(json['eyeBrighten'], equals(0.35));
      expect(json['teethWhiten'], equals(0.30));
      expect(json['darkCircles'], equals(0.45));
      expect(json['faceSlimming'], equals(0.25));
      expect(json['waistSlimming'], equals(0.15));
      expect(json['legLengthening'], equals(0.10));
      expect(json['activePreset'], equals('porcelainFlawless'));

      final restored = FaceRetouchConfig.fromJson(json);
      expect(restored, equals(config));
      expect(restored.badge, contains('PORCELAIN'));

      final modified = restored.copyWith(skinSmooth: 0.85);
      expect(modified.skinSmooth, equals(0.85));
      expect(modified.eyeBrighten, equals(0.35));
    });

    test('FaceRetouchConfig.getPresetConfig generates verified CapCut Pro presets', () {
      final natural = FaceRetouchConfig.getPresetConfig(RetouchPreset.naturalGlow);
      expect(natural.isEnabled, isTrue);
      expect(natural.skinSmooth, equals(0.45));
      expect(natural.skinRadiance, equals(0.35));

      final porcelain = FaceRetouchConfig.getPresetConfig(RetouchPreset.porcelainFlawless);
      expect(porcelain.skinTone, equals(SkinToneStyle.porcelain));
      expect(porcelain.skinSmooth, equals(0.75));
      expect(porcelain.faceSlimming, equals(0.20));

      final golden = FaceRetouchConfig.getPresetConfig(RetouchPreset.goldenHour);
      expect(golden.skinTone, equals(SkinToneStyle.goldenHoney));
      expect(golden.skinRadiance, equals(0.45));

      final glamour = FaceRetouchConfig.getPresetConfig(RetouchPreset.glamourPortrait);
      expect(glamour.skinSmooth, equals(0.80));
      expect(glamour.teethWhiten, equals(0.50));
      expect(glamour.waistSlimming, equals(0.20));
    });

    test('FaceRetouchCompilerService.generateFFmpegFilters produces smartblur, eq, and colorbalance', () {
      // Disabled case returns empty
      expect(FaceRetouchCompilerService.generateFFmpegFilters(const FaceRetouchConfig()), isEmpty);

      const config = FaceRetouchConfig(
        isEnabled: true,
        skinSmooth: 0.70,
        skinRadiance: 0.50,
        skinTone: SkinToneStyle.goldenHoney,
        eyeBrighten: 0.40,
        teethWhiten: 0.35,
      );

      final filters = FaceRetouchCompilerService.generateFFmpegFilters(config);
      expect(filters, isNotEmpty);

      // Verify smartblur bilateral smoothing filter
      expect(filters.any((f) => f.contains('smartblur=lr=') && f.contains(':ls=') && f.contains(':lt=')), isTrue);

      // Verify unsharp mask for detail retention
      expect(filters.any((f) => f.contains('unsharp=5:5:')), isTrue);

      // Verify eq brightness, contrast, and saturation
      expect(filters.any((f) => f.contains('eq=brightness=') && f.contains(':contrast=') && f.contains(':saturation=')), isTrue);

      // Verify golden honey skin tone colorbalance
      expect(filters.any((f) => f.contains('colorbalance=rm=')), isTrue);

      // Verify teeth whitening blue lift
      expect(filters.any((f) => f.contains('bh=') && f.contains('rh=')), isTrue);
    });

    test('FaceRetouchCompilerService.generateColorFilterMatrix creates valid 4x5 Skia matrices', () {
      final identity = FaceRetouchCompilerService.generateColorFilterMatrix(const FaceRetouchConfig());
      expect(identity.length, equals(20));
      expect(identity[0], equals(1.0));
      expect(identity[6], equals(1.0));
      expect(identity[12], equals(1.0));
      expect(identity[18], equals(1.0));

      const activeConfig = FaceRetouchConfig(
        isEnabled: true,
        skinRadiance: 0.60,
        skinTone: SkinToneStyle.warmPeach,
        teethWhiten: 0.40,
      );

      final activeMatrix = FaceRetouchCompilerService.generateColorFilterMatrix(activeConfig);
      expect(activeMatrix.length, equals(20));
      // Brightness offset in column 4 (R, G, B channels)
      expect(activeMatrix[4], greaterThan(0.0));
      expect(activeMatrix[9], greaterThan(0.0));
      expect(activeMatrix[14], greaterThan(0.0));
      // Red multiplier for peach tone
      expect(activeMatrix[0], greaterThan(activeMatrix[12]));
    });

    test('Clip model preserves retouch configuration through serialization and copyWith', () {
      const retouch = FaceRetouchConfig(
        isEnabled: true,
        skinSmooth: 0.60,
        skinRadiance: 0.45,
        skinTone: SkinToneStyle.bronzeSun,
        activePreset: RetouchPreset.goldenHour,
      );

      const clip = Clip(
        id: 'clip_retouch_test',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        retouch: retouch,
      );

      final json = clip.toJson();
      expect(json['retouch'], isNotNull);
      expect(json['retouch']['skinSmooth'], equals(0.60));
      expect(json['retouch']['skinTone'], equals('bronzeSun'));

      final restored = Clip.fromJson(json);
      expect(restored.retouch.isEnabled, isTrue);
      expect(restored.retouch.skinTone, equals(SkinToneStyle.bronzeSun));
      expect(restored.retouch.skinRadiance, equals(0.45));

      final modified = restored.copyWith(
        retouch: restored.retouch.copyWith(skinSmooth: 0.90),
      );
      expect(modified.retouch.skinSmooth, equals(0.90));
    });

    testWidgets('FaceRetouchSheet renders all tabs and updates state', (tester) async {
      Clip testClip = const Clip(
        id: 'clip_test',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FaceRetouchSheet(
              clip: testClip,
              onSave: (updated) => testClip = updated,
              isDocked: true,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('AI Face & Body Retouch'), findsOneWidget);
      expect(find.text('Skin & Complexion'), findsOneWidget);
      expect(find.text('Facial Features'), findsOneWidget);
      expect(find.text('Body & Silhouette'), findsOneWidget);

      // Tap preset chip
      expect(find.text('🌟 Natural Glow'), findsOneWidget);
      await tester.tap(find.text('🌟 Natural Glow'));
      await tester.pump();

      expect(testClip.retouch.isEnabled, isTrue);
      expect(testClip.retouch.skinSmooth, equals(0.45));

      // Switch to Facial Features tab
      await tester.tap(find.text('Facial Features'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Eye Brightening'), findsOneWidget);
      expect(find.textContaining('Teeth Whitening'), findsOneWidget);

      // Switch to Body & Silhouette tab
      await tester.tap(find.text('Body & Silhouette'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Waist & Silhouette Slimming'), findsOneWidget);
      expect(find.textContaining('Leg Lengthening'), findsOneWidget);
    });
  });
}
