import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/relight/models/relight_config.dart';
import 'package:edito/features/relight/services/relight_compiler_service.dart';
import 'package:edito/features/relight/presentation/widgets/relight_sheet.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/media_asset.dart';

void main() {
  group('Feature 29: CapCut Pro AI Video Relight & Virtual Studio Lighting Suite Tests', () {
    test('RelightMode enums provide accurate labels, descriptions, and defaults', () {
      expect(RelightMode.none.label, equals('Off'));
      expect(RelightMode.facialSpotlight.label, equals('Face Spotlight'));
      expect(RelightMode.studioSoftbox.label, equals('Studio Softbox'));
      expect(RelightMode.rimBacklight.label, equals('Rim Backlight'));
      expect(RelightMode.ambientRingLight.label, equals('Ring Light'));
      expect(RelightMode.goldenSunbeam.label, equals('Golden Sunbeam'));
      expect(RelightMode.cyberNeonDual.label, equals('Cyber Neon Dual'));
      expect(RelightMode.vintageWarmTungsten.label, equals('Warm Tungsten'));

      for (final mode in RelightMode.values) {
        expect(mode.label.isNotEmpty, isTrue);
        expect(mode.description.isNotEmpty, isTrue);
      }

      expect(RelightMode.cyberNeonDual.defaultSecondaryColor, isNotNull);
      expect(RelightMode.studioSoftbox.defaultX, equals(-0.45));
      expect(RelightMode.facialSpotlight.defaultY, equals(-0.20));
    });

    test('RelightConfig default constructor and fromMode factory', () {
      const defaultConfig = RelightConfig();
      expect(defaultConfig.isEnabled, isFalse);
      expect(defaultConfig.mode, equals(RelightMode.none));
      expect(defaultConfig.intensity, equals(0.70));
      expect(defaultConfig.lightX, equals(0.0));
      expect(defaultConfig.lightY, equals(-0.20));
      expect(defaultConfig.radius, equals(0.70));
      expect(defaultConfig.softness, equals(0.85));
      expect(defaultConfig.badge, isEmpty);

      final spotlight = RelightConfig.fromMode(RelightMode.facialSpotlight, intensity: 0.85);
      expect(spotlight.isEnabled, isTrue);
      expect(spotlight.mode, equals(RelightMode.facialSpotlight));
      expect(spotlight.intensity, equals(0.85));
      expect(spotlight.badge, contains('FACE SPOTLIGHT 85%'));

      final neon = RelightConfig.fromMode(RelightMode.cyberNeonDual, intensity: 0.90);
      expect(neon.isEnabled, isTrue);
      expect(neon.mode, equals(RelightMode.cyberNeonDual));
      expect(neon.secondaryColorValue, isNotNull);
      expect(neon.badge, contains('CYBER NEON DUAL 90%'));

      final noneConfig = RelightConfig.fromMode(RelightMode.none);
      expect(noneConfig.isEnabled, isFalse);
    });

    test('RelightConfig JSON serialization and deserialization roundtrip', () {
      const original = RelightConfig(
        isEnabled: true,
        mode: RelightMode.goldenSunbeam,
        intensity: 0.82,
        lightX: -0.45,
        lightY: -0.60,
        radius: 1.15,
        softness: 0.90,
        colorValue: 0xFFFFB347,
        secondaryColorValue: 0xFFFF9F43,
        distance: 0.40,
      );

      final json = original.toJson();
      final restored = RelightConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.mode, equals(RelightMode.goldenSunbeam));
      expect(restored.intensity, equals(0.82));
      expect(restored.lightX, equals(-0.45));
      expect(restored.lightY, equals(-0.60));
      expect(restored.radius, equals(1.15));
      expect(restored.softness, equals(0.90));
      expect(restored.colorValue, equals(0xFFFFB347));
      expect(restored.secondaryColorValue, equals(0xFFFF9F43));
      expect(restored.distance, equals(0.40));
      expect(restored, equals(original));
    });

    test('RelightCompilerService builds hardware-accelerated Skia overlay', () {
      const disabled = RelightConfig();
      final disabledWidget = RelightCompilerService.buildLightingOverlay(disabled, const Size(1920, 1080));
      expect(disabledWidget, isA<SizedBox>());

      final active = RelightConfig.fromMode(RelightMode.facialSpotlight);
      final activeWidget = RelightCompilerService.buildLightingOverlay(active, const Size(1920, 1080));
      expect(activeWidget, isA<IgnorePointer>());
    });

    test('RelightCompilerService generates deterministic FFmpeg filters', () {
      const disabled = RelightConfig();
      expect(RelightCompilerService.generateFFmpegFilters(disabled), isEmpty);

      final spotlight = RelightConfig.fromMode(RelightMode.facialSpotlight);
      final spotFilters = RelightCompilerService.generateFFmpegFilters(spotlight);
      expect(spotFilters.isNotEmpty, isTrue);
      expect(spotFilters.any((f) => f.contains('eq=contrast=')), isTrue);
      expect(spotFilters.any((f) => f.contains('colorbalance=')), isTrue);

      final rim = RelightConfig.fromMode(RelightMode.rimBacklight);
      final rimFilters = RelightCompilerService.generateFFmpegFilters(rim);
      expect(rimFilters.any((f) => f.contains('curves=all=')), isTrue);

      final sunbeam = RelightConfig.fromMode(RelightMode.goldenSunbeam);
      final sunFilters = RelightCompilerService.generateFFmpegFilters(sunbeam);
      expect(sunFilters.any((f) => f.contains('curves=red=')), isTrue);
    });

    test('Clip model integration: RelightConfig copyWith and serialization', () {
      final clip = Clip(
        id: 'clip_relight_test',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      expect(clip.relight.isEnabled, isFalse);

      final updatedClip = clip.copyWith(
        relight: RelightConfig.fromMode(RelightMode.studioSoftbox, intensity: 0.80),
      );

      expect(updatedClip.relight.isEnabled, isTrue);
      expect(updatedClip.relight.mode, equals(RelightMode.studioSoftbox));
      expect(updatedClip.relight.intensity, equals(0.80));

      final json = updatedClip.toJson();
      final roundTrip = Clip.fromJson(json);
      expect(roundTrip.relight.isEnabled, isTrue);
      expect(roundTrip.relight.mode, equals(RelightMode.studioSoftbox));
      expect(roundTrip.relight.intensity, equals(0.80));
      expect(roundTrip, equals(updatedClip));
    });

    test('FFmpegCommandBuilder includes relight filters in video pipeline', () {
      final asset = MediaAsset(
        id: 'asset_relight_1',
        path: '/storage/emulated/0/Movies/sample.mp4',
        fileName: 'sample.mp4',
        type: MediaType.video,
        durationMs: 5000,
        width: 1920,
        height: 1080,
      );

      final clip = Clip(
        id: 'clip_relight_1',
        assetId: 'asset_relight_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        relight: RelightConfig.fromMode(RelightMode.facialSpotlight, intensity: 0.85),
      );

      final track = Track(
        id: 'track_1',
        name: 'Main Video',
        type: TrackType.video,
        clips: [clip],
      );

      final project = Project(
        id: 'proj_relight',
        name: 'Relight Project',
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

      expect(filterGraph.contains('eq=contrast='), isTrue);
      expect(filterGraph.contains('colorbalance='), isTrue);
    });

    testWidgets('RelightSheet renders and updates state via interactive pad', (tester) async {
      RelightConfig current = const RelightConfig();
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return RelightSheet(
                  initialConfig: current,
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

      expect(find.text('AI Video Relight'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('2D VIRTUAL LIGHT POSITION'), findsOneWidget);
      expect(find.text('SELECT LIGHTING PRESET'), findsOneWidget);
      expect(find.text('Face Spotlight'), findsOneWidget);

      // Tap on Face Spotlight preset
      await tester.tap(find.text('Face Spotlight'));
      await tester.pumpAndSettle();

      expect(current.isEnabled, isTrue);
      expect(current.mode, equals(RelightMode.facialSpotlight));

      // Drag on the interactive 2D Light Pad
      await tester.drag(find.text('2D VIRTUAL LIGHT POSITION'), const Offset(30, 20));
      await tester.pumpAndSettle();

      // Tap close button
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
    });
  });
}
