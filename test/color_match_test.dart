import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/color_match/models/color_match_config.dart';
import 'package:edito/features/color_match/services/color_match_compiler_service.dart';
import 'package:edito/features/color_match/presentation/widgets/color_match_sheet.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/media_asset.dart';

void main() {
  group('Feature 28: CapCut Pro AI Color Match & Tone Palette Transfer Suite Tests', () {
    test('ColorMatchMode and ColorPalettePreset provide accurate labels, descriptions, and swatches', () {
      expect(ColorMatchMode.preset.label, equals('Preset Palette'));
      expect(ColorMatchMode.timelineClip.label, equals('Timeline Clip'));
      expect(ColorMatchMode.custom.label, equals('Custom Match'));

      for (final preset in ColorPalettePreset.values) {
        expect(preset.label.isNotEmpty, isTrue);
        expect(preset.description.isNotEmpty, isTrue);
        expect(preset.previewColors.length, equals(3));
      }
    });

    test('ColorMatchConfig default constructor and factory constructors', () {
      const defaultConfig = ColorMatchConfig();
      expect(defaultConfig.isEnabled, isFalse);
      expect(defaultConfig.mode, equals(ColorMatchMode.preset));
      expect(defaultConfig.preset, equals(ColorPalettePreset.hollywoodTealOrange));
      expect(defaultConfig.intensity, equals(0.85));
      expect(defaultConfig.luminanceWeight, equals(0.80));
      expect(defaultConfig.colorSpread, equals(0.75));
      expect(defaultConfig.saturationMatch, equals(1.0));
      expect(defaultConfig.preserveSkinTones, isTrue);
      expect(defaultConfig.badge, isEmpty);

      final presetConfig = ColorMatchConfig.fromPreset(ColorPalettePreset.cyberpunkNeoTokyo, intensity: 0.90);
      expect(presetConfig.isEnabled, isTrue);
      expect(presetConfig.mode, equals(ColorMatchMode.preset));
      expect(presetConfig.preset, equals(ColorPalettePreset.cyberpunkNeoTokyo));
      expect(presetConfig.intensity, equals(0.90));
      expect(presetConfig.badge, contains('CYBERPUNK NEON 90%'));

      final clipConfig = ColorMatchConfig.fromClip(clipId: 'clip_ref_1', clipName: 'Sunset Ocean', intensity: 0.75);
      expect(clipConfig.isEnabled, isTrue);
      expect(clipConfig.mode, equals(ColorMatchMode.timelineClip));
      expect(clipConfig.referenceClipId, equals('clip_ref_1'));
      expect(clipConfig.referenceClipName, equals('Sunset Ocean'));
      expect(clipConfig.badge, contains('Sunset Ocean 75%'));
    });

    test('ColorMatchConfig JSON serialization and deserialization roundtrip', () {
      const original = ColorMatchConfig(
        isEnabled: true,
        mode: ColorMatchMode.timelineClip,
        preset: ColorPalettePreset.goldenHourSunset,
        referenceClipId: 'ref_99',
        referenceClipName: 'B-Roll Drone',
        intensity: 0.78,
        luminanceWeight: 0.65,
        colorSpread: 0.88,
        saturationMatch: 1.15,
        preserveSkinTones: true,
      );

      final json = original.toJson();
      final restored = ColorMatchConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.mode, equals(ColorMatchMode.timelineClip));
      expect(restored.preset, equals(ColorPalettePreset.goldenHourSunset));
      expect(restored.referenceClipId, equals('ref_99'));
      expect(restored.referenceClipName, equals('B-Roll Drone'));
      expect(restored.intensity, equals(0.78));
      expect(restored.luminanceWeight, equals(0.65));
      expect(restored.colorSpread, equals(0.88));
      expect(restored.saturationMatch, equals(1.15));
      expect(restored.preserveSkinTones, isTrue);
      expect(restored, equals(original));
    });

    test('ColorMatchCompilerService calculates Skia 4x5 ColorFilter matrix accurately', () {
      // 1. Identity matrix when disabled or zero intensity
      const disabled = ColorMatchConfig();
      final identityMatrix = ColorMatchCompilerService.calculateColorMatrix(disabled);
      expect(identityMatrix, equals(ColorMatchCompilerService.identityMatrix));

      const zeroIntensity = ColorMatchConfig(isEnabled: true, intensity: 0.0);
      expect(ColorMatchCompilerService.calculateColorMatrix(zeroIntensity), equals(ColorMatchCompilerService.identityMatrix));

      // 2. Teal & Orange produces non-identity 20-element matrix with enhanced contrast and color balance
      final tealOrange = ColorMatchConfig.fromPreset(ColorPalettePreset.hollywoodTealOrange, intensity: 1.0);
      final toMatrix = ColorMatchCompilerService.calculateColorMatrix(tealOrange);
      expect(toMatrix.length, equals(20));
      expect(toMatrix, isNot(equals(ColorMatchCompilerService.identityMatrix)));

      // 3. Bleach Bypass produces high contrast and reduced saturation
      final bleach = ColorMatchConfig.fromPreset(ColorPalettePreset.moodyBleachBypass, intensity: 1.0);
      final bleachMatrix = ColorMatchCompilerService.calculateColorMatrix(bleach);
      expect(bleachMatrix.length, equals(20));

      // 4. Monochrome produces pure desaturation
      final mono = ColorMatchConfig.fromPreset(ColorPalettePreset.monochromeMood, intensity: 1.0);
      final monoMatrix = ColorMatchCompilerService.calculateColorMatrix(mono);
      expect(monoMatrix.length, equals(20));

      // 5. Skin tone preservation changes red highlight component
      final withoutSkinProtection = tealOrange.copyWith(preserveSkinTones: false);
      final withSkinProtection = tealOrange.copyWith(preserveSkinTones: true);
      final matrixNoSkin = ColorMatchCompilerService.calculateColorMatrix(withoutSkinProtection);
      final matrixSkin = ColorMatchCompilerService.calculateColorMatrix(withSkinProtection);
      expect(matrixNoSkin[0], isNot(equals(matrixSkin[0])));
    });

    test('ColorMatchCompilerService generates deterministic FFmpeg filters', () {
      const disabled = ColorMatchConfig();
      expect(ColorMatchCompilerService.generateFFmpegFilters(disabled), isEmpty);

      // 1. Teal & Orange filters
      final tealOrange = ColorMatchConfig.fromPreset(ColorPalettePreset.hollywoodTealOrange);
      final toFilters = ColorMatchCompilerService.generateFFmpegFilters(tealOrange);
      expect(toFilters.isNotEmpty, isTrue);
      expect(toFilters.any((f) => f.contains('eq=contrast=')), isTrue);
      expect(toFilters.any((f) => f.contains('colorbalance=')), isTrue);

      // 2. Bleach Bypass filters
      final bleach = ColorMatchConfig.fromPreset(ColorPalettePreset.moodyBleachBypass);
      final bleachFilters = ColorMatchCompilerService.generateFFmpegFilters(bleach);
      expect(bleachFilters.any((f) => f.contains('saturation=')), isTrue);

      // 3. Timeline Clip match mode
      final clipMatch = ColorMatchConfig.fromClip(clipId: 'c1', clipName: 'Clip 1');
      final clipFilters = ColorMatchCompilerService.generateFFmpegFilters(clipMatch);
      expect(clipFilters.isNotEmpty, isTrue);
      expect(clipFilters.any((f) => f.contains('colorbalance=')), isTrue);
    });

    test('Clip model integration: ColorMatchConfig copyWith and serialization', () {
      final clip = Clip(
        id: 'c_test_color_match',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      expect(clip.colorMatch.isEnabled, isFalse);

      final updatedClip = clip.copyWith(
        colorMatch: const ColorMatchConfig(
          isEnabled: true,
          preset: ColorPalettePreset.goldenHourSunset,
          intensity: 0.95,
        ),
      );

      expect(updatedClip.colorMatch.isEnabled, isTrue);
      expect(updatedClip.colorMatch.preset, equals(ColorPalettePreset.goldenHourSunset));
      expect(updatedClip.colorMatch.intensity, equals(0.95));

      final json = updatedClip.toJson();
      final roundTrip = Clip.fromJson(json);
      expect(roundTrip.colorMatch.isEnabled, isTrue);
      expect(roundTrip.colorMatch.preset, equals(ColorPalettePreset.goldenHourSunset));
      expect(roundTrip.colorMatch.intensity, equals(0.95));
      expect(roundTrip, equals(updatedClip));
    });

    test('FFmpegCommandBuilder includes color match filters in video pipeline', () {
      final asset = MediaAsset(
        id: 'asset_1',
        path: '/storage/emulated/0/Movies/sample.mp4',
        fileName: 'sample.mp4',
        type: MediaType.video,
        durationMs: 5000,
        width: 1920,
        height: 1080,
      );

      final clip = Clip(
        id: 'clip_1',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        colorMatch: ColorMatchConfig.fromPreset(ColorPalettePreset.hollywoodTealOrange),
      );

      final track = Track(
        id: 'track_1',
        name: 'Main Track',
        type: TrackType.video,
        clips: [clip],
      );

      final project = Project(
        id: 'proj_1',
        name: 'Color Match Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tracks: [track],
        assets: [asset],
      );

      final command = FFmpegCommandBuilder.build(
        project: project,
        outputPath: '/storage/emulated/0/Movies/output.mp4',
        preset: ExportPreset.fhd1080p,
      );

      expect(command.arguments.contains('-filter_complex'), isTrue);
      final filterGraphIndex = command.arguments.indexOf('-filter_complex') + 1;
      final filterGraph = command.arguments[filterGraphIndex];

      expect(filterGraph.contains('colorbalance='), isTrue);
      expect(filterGraph.contains('eq=contrast='), isTrue);
    });

    testWidgets('ColorMatchSheet renders and responds to user interaction', (tester) async {
      ColorMatchConfig current = const ColorMatchConfig();
      bool closed = false;

      final testClips = [
        Clip(
          id: 'ref_clip_1',
          assetId: 'a1',
          trackId: 't1',
          startTimeMs: 0,
          durationMs: 4000,
          sourceInMs: 0,
          sourceOutMs: 4000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ColorMatchSheet(
                  initialConfig: current,
                  availableReferenceClips: testClips,
                  onApply: (val) {
                    setState(() => current = val);
                  },
                  onClose: () => closed = true,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('AI Color Match'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('Pro Palettes'), findsOneWidget);
      expect(find.text('Timeline Clip'), findsOneWidget);
      expect(find.text('Match Intensity'), findsOneWidget);
      expect(find.text('Preserve Skin Tones'), findsOneWidget);

      // Tap on Teal & Orange preset
      await tester.tap(find.text('Teal & Orange'));
      await tester.pumpAndSettle();

      expect(current.isEnabled, isTrue);
      expect(current.preset, equals(ColorPalettePreset.hollywoodTealOrange));

      // Switch to Timeline Clip mode
      await tester.tap(find.text('Timeline Clip'));
      await tester.pumpAndSettle();

      expect(current.mode, equals(ColorMatchMode.timelineClip));
      expect(find.text('Clip 1'), findsOneWidget);

      // Tap on reference clip
      await tester.tap(find.text('Clip 1'));
      await tester.pumpAndSettle();

      expect(current.referenceClipId, equals('ref_clip_1'));

      // Tap close button
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
    });
  });
}
