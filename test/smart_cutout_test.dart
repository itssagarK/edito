import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/cutout/models/smart_cutout_config.dart';
import 'package:edito/features/cutout/services/smart_cutout_compiler_service.dart';
import 'package:edito/features/cutout/presentation/widgets/smart_cutout_preview_wrapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature 20 - SmartCutoutConfig Model & Presets', () {
    test('Default constructor sets expected fallback values', () {
      const config = SmartCutoutConfig();
      expect(config.isEnabled, isFalse);
      expect(config.type, CutoutType.autoPortrait);
      expect(config.strokeStyle, CutoutStrokeStyle.none);
      expect(config.strokeColorValue, 0xFF00E5FF);
      expect(config.strokeWidth, 4.0);
      expect(config.glowSpread, 10.0);
      expect(config.edgeFeather, 0.25);
      expect(config.isInverted, isFalse);
      expect(config.backgroundMode, CutoutBackgroundMode.transparent);
    });

    test('All CapCut Pro presets have valid configurations', () {
      expect(SmartCutoutConfig.presetNeonCyan.isEnabled, isTrue);
      expect(SmartCutoutConfig.presetNeonCyan.strokeStyle, CutoutStrokeStyle.neonGlow);
      expect(SmartCutoutConfig.presetNeonCyan.strokeColorValue, 0xFF00E5FF);

      expect(SmartCutoutConfig.presetCyberPink.isEnabled, isTrue);
      expect(SmartCutoutConfig.presetCyberPink.strokeStyle, CutoutStrokeStyle.cyberPink);
      expect(SmartCutoutConfig.presetCyberPink.strokeColorValue, 0xFFFF007F);

      expect(SmartCutoutConfig.presetGoldenAura.isEnabled, isTrue);
      expect(SmartCutoutConfig.presetGoldenAura.strokeStyle, CutoutStrokeStyle.goldenAura);

      expect(SmartCutoutConfig.presetMatrixGreen.isEnabled, isTrue);
      expect(SmartCutoutConfig.presetMatrixGreen.strokeStyle, CutoutStrokeStyle.matrixGreen);

      expect(SmartCutoutConfig.presetWhiteSticker.isEnabled, isTrue);
      expect(SmartCutoutConfig.presetWhiteSticker.strokeStyle, CutoutStrokeStyle.solidBorder);

      expect(SmartCutoutConfig.presetPortraitBokeh.isEnabled, isTrue);
      expect(SmartCutoutConfig.presetPortraitBokeh.backgroundMode, CutoutBackgroundMode.blur);
      expect(SmartCutoutConfig.presetPortraitBokeh.backgroundBlur, 16.0);

      expect(SmartCutoutConfig.presetStudioDark.isEnabled, isTrue);
      expect(SmartCutoutConfig.presetStudioDark.backgroundMode, CutoutBackgroundMode.solidColor);
    });

    test('Json serialization and deserialization roundtrip preserves all properties', () {
      const config = SmartCutoutConfig(
        isEnabled: true,
        type: CutoutType.autoPortrait,
        strokeStyle: CutoutStrokeStyle.neonGlow,
        strokeColorValue: 0xFF00E5FF,
        strokeWidth: 6.5,
        glowSpread: 18.0,
        edgeFeather: 0.4,
        isInverted: true,
        backgroundMode: CutoutBackgroundMode.blur,
        backgroundBlur: 20.0,
        backgroundColorValue: 0xFF000000,
      );

      final json = config.toJson();
      final roundtrip = SmartCutoutConfig.fromJson(json);

      expect(roundtrip, equals(config));
      expect(roundtrip.strokeWidth, 6.5);
      expect(roundtrip.glowSpread, 18.0);
      expect(roundtrip.isInverted, isTrue);
      expect(roundtrip.backgroundBlur, 20.0);
    });
  });

  group('Feature 20 - SmartCutoutCompilerService FFmpeg & Badges', () {
    test('generateFFmpegFilters returns empty list when disabled', () {
      const config = SmartCutoutConfig(isEnabled: false);
      final filters = SmartCutoutCompilerService.generateFFmpegFilters(config);
      expect(filters, isEmpty);
    });

    test('generateFFmpegFilters generates boxblur for blur background mode', () {
      const config = SmartCutoutConfig(
        isEnabled: true,
        backgroundMode: CutoutBackgroundMode.blur,
        backgroundBlur: 15.0,
      );
      final filters = SmartCutoutCompilerService.generateFFmpegFilters(config);
      expect(filters.any((f) => f.contains('boxblur=luma_radius=15.0:luma_power=2')), isTrue);
    });

    test('generateFFmpegFilters generates colorbalance for solid color background mode', () {
      const config = SmartCutoutConfig(
        isEnabled: true,
        backgroundMode: CutoutBackgroundMode.solidColor,
        backgroundColorValue: 0xFF000000,
      );
      final filters = SmartCutoutCompilerService.generateFFmpegFilters(config);
      expect(filters.any((f) => f.contains('colorbalance=rm=-0.70:gm=-0.70:bm=-0.70')), isTrue);
    });

    test('generateFFmpegFilters generates yuva420p format for transparent background mode', () {
      const config = SmartCutoutConfig(
        isEnabled: true,
        backgroundMode: CutoutBackgroundMode.transparent,
      );
      final filters = SmartCutoutCompilerService.generateFFmpegFilters(config);
      expect(filters.contains('format=yuva420p'), isTrue);
    });

    test('generateFFmpegFilters generates neon glow colorchannelmixer', () {
      const config = SmartCutoutConfig(
        isEnabled: true,
        strokeStyle: CutoutStrokeStyle.neonGlow,
        strokeColorValue: 0xFF00E5FF,
      );
      final filters = SmartCutoutCompilerService.generateFFmpegFilters(config);
      expect(filters.any((f) => f.contains('colorchannelmixer=rr=0.00:gg=1.80:bb=2.00')), isTrue);
    });

    test('generateFFmpegFilters generates cyber pink colorchannelmixer', () {
      const config = SmartCutoutConfig(
        isEnabled: true,
        strokeStyle: CutoutStrokeStyle.cyberPink,
      );
      final filters = SmartCutoutCompilerService.generateFFmpegFilters(config);
      expect(filters.any((f) => f.contains('colorchannelmixer=rr=2.00:gg=0.00:bb=1.60')), isTrue);
    });

    test('generateFFmpegFilters includes negate filter when isInverted is true', () {
      const config = SmartCutoutConfig(
        isEnabled: true,
        isInverted: true,
      );
      final filters = SmartCutoutCompilerService.generateFFmpegFilters(config);
      expect(filters.contains('negate'), isTrue);
    });

    test('getCutoutBadge formats accurate live HUD titles', () {
      expect(SmartCutoutCompilerService.getCutoutBadge(SmartCutoutConfig.presetNeonCyan), contains('NEON GLOW'));
      expect(SmartCutoutCompilerService.getCutoutBadge(SmartCutoutConfig.presetCyberPink), contains('CYBER PINK'));
      expect(SmartCutoutCompilerService.getCutoutBadge(SmartCutoutConfig.presetPortraitBokeh), contains('PORTRAIT BOKEH'));
      expect(SmartCutoutCompilerService.getCutoutBadge(const SmartCutoutConfig(isEnabled: false)), isEmpty);
    });

    test('generatePreviewMatrix yields identity matrix when disabled or stroke is none', () {
      const config = SmartCutoutConfig(isEnabled: false);
      final matrix = SmartCutoutCompilerService.generatePreviewMatrix(config);
      expect(matrix[0], 1.0);
      expect(matrix[6], 1.0);
      expect(matrix[12], 1.0);
      expect(matrix[18], 1.0);
    });
  });

  group('Feature 20 - SmartCutoutPreviewWrapper & Viewport Rendering', () {
    testWidgets('Renders child unchanged when cutout is disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartCutoutPreviewWrapper(
              config: SmartCutoutConfig(isEnabled: false),
              child: Text('Raw Video Frame'),
            ),
          ),
        ),
      );

      expect(find.text('Raw Video Frame'), findsOneWidget);
    });

    testWidgets('Renders glowing stroke painter and blur background when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartCutoutPreviewWrapper(
              config: SmartCutoutConfig.presetNeonCyan.copyWith(
                backgroundMode: CutoutBackgroundMode.blur,
                backgroundBlur: 10.0,
              ),
              child: const SizedBox(
                width: 300,
                height: 400,
                child: Text('Cutout Subject Frame'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cutout Subject Frame'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('Feature 20 - FFmpegCommandBuilder Full Integration', () {
    test('FFmpegCommandBuilder integrates SmartCutout filters into export command', () {
      const asset = MediaAsset(
        id: 'asset-cutout',
        path: '/storage/cutout_input.mp4',
        fileName: 'cutout_input.mp4',
        type: MediaType.video,
        durationMs: 5000,
      );

      const cutoutClip = Clip(
        id: 'clip-cutout',
        assetId: 'asset-cutout',
        trackId: 'track-cutout',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        smartCutout: SmartCutoutConfig(
          isEnabled: true,
          type: CutoutType.autoPortrait,
          strokeStyle: CutoutStrokeStyle.cyberPink,
          backgroundMode: CutoutBackgroundMode.blur,
          backgroundBlur: 14.0,
        ),
      );

      const track = Track(
        id: 'track-cutout',
        name: 'Cutout Track',
        type: TrackType.video,
        clips: [cutoutClip],
      );

      final project = Project(
        id: 'p-cutout',
        name: 'Cutout Project',
        durationMs: 5000,
        tracks: [track],
        assets: [asset],
      );

      final result = FFmpegCommandBuilder.build(
        project: project,
        config: const ExportConfiguration(),
        outputPath: '/storage/cutout_export.mp4',
      );

      // Verify that the compiled command includes background blur and neon stroke outline filter
      expect(result.command.contains('boxblur=luma_radius=14.0:luma_power=2'), isTrue);
      expect(result.command.contains('colorchannelmixer=rr=2.00:gg=0.00:bb=1.60'), isTrue);
    });
  });
}
