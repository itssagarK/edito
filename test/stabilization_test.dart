import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/stabilization/models/stabilization_config.dart';
import 'package:edito/features/stabilization/services/stabilization_compiler_service.dart';
import 'package:edito/features/stabilization/presentation/widgets/stabilization_sheet.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/media_asset.dart';

void main() {
  group('Feature 26: CapCut Pro AI Video Stabilization & Gyro Flow Studio Suite Tests', () {
    test('StabilizationLevel enums provide accurate labels and descriptions', () {
      expect(StabilizationLevel.none.label, equals('Off'));
      expect(StabilizationLevel.minimalCrop.label, equals('Minimal Crop'));
      expect(StabilizationLevel.recommended.label, equals('Recommended'));
      expect(StabilizationLevel.mostStable.label, equals('Most Stable'));
      expect(StabilizationLevel.custom.label, equals('Custom'));

      expect(StabilizationLevel.minimalCrop.description, contains('~4% crop'));
      expect(StabilizationLevel.recommended.description, contains('~10% crop'));
      expect(StabilizationLevel.mostStable.description, contains('~18% crop'));

      expect(StabilizationLevel.minimalCrop.defaultCropMargin, equals(0.04));
      expect(StabilizationLevel.recommended.defaultCropMargin, equals(0.10));
      expect(StabilizationLevel.mostStable.defaultCropMargin, equals(0.18));
    });

    test('StabilizationAlgorithm and EdgePaddingMode enums provide correct metadata', () {
      expect(StabilizationAlgorithm.gyroFlow.label, equals('Gyro Flow'));
      expect(StabilizationAlgorithm.opticalDeshake.label, equals('Optical Deshake'));
      expect(StabilizationAlgorithm.warpPerspective.label, equals('Warp Stabilizer'));

      expect(EdgePaddingMode.adaptiveCrop.label, contains('Zoom Crop'));
      expect(EdgePaddingMode.mirrorEdge.label, contains('Mirror'));
      expect(EdgePaddingMode.blurredMargin.label, contains('Blurred'));
    });

    test('StabilizationConfig default constructor and fromLevel factory', () {
      const defaultConfig = StabilizationConfig();
      expect(defaultConfig.isEnabled, isFalse);
      expect(defaultConfig.level, equals(StabilizationLevel.none));
      expect(defaultConfig.algorithm, equals(StabilizationAlgorithm.gyroFlow));
      expect(defaultConfig.edgeMode, equals(EdgePaddingMode.adaptiveCrop));
      expect(defaultConfig.smoothingStrength, equals(0.65));
      expect(defaultConfig.cropMargin, equals(0.10));
      expect(defaultConfig.rollingShutterCorrection, isTrue);

      final recConfig = StabilizationConfig.fromLevel(StabilizationLevel.recommended);
      expect(recConfig.isEnabled, isTrue);
      expect(recConfig.level, equals(StabilizationLevel.recommended));
      expect(recConfig.cropMargin, equals(0.10));

      final mostStable = StabilizationConfig.fromLevel(StabilizationLevel.mostStable);
      expect(mostStable.isEnabled, isTrue);
      expect(mostStable.cropMargin, equals(0.18));
      expect(mostStable.smoothingStrength, equals(0.90));

      final noneConfig = StabilizationConfig.fromLevel(StabilizationLevel.none);
      expect(noneConfig.isEnabled, isFalse);
    });

    test('StabilizationConfig JSON serialization roundtrip preserves all attributes', () {
      const original = StabilizationConfig(
        isEnabled: true,
        level: StabilizationLevel.mostStable,
        algorithm: StabilizationAlgorithm.opticalDeshake,
        edgeMode: EdgePaddingMode.mirrorEdge,
        smoothingStrength: 0.88,
        cropMargin: 0.16,
        pitchYawDampening: 0.82,
        rollDampening: 0.94,
        rollingShutterCorrection: false,
        isAnalyzing: false,
      );

      final json = original.toJson();
      final restored = StabilizationConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.level, equals(StabilizationLevel.mostStable));
      expect(restored.algorithm, equals(StabilizationAlgorithm.opticalDeshake));
      expect(restored.edgeMode, equals(EdgePaddingMode.mirrorEdge));
      expect(restored.smoothingStrength, equals(0.88));
      expect(restored.cropMargin, equals(0.16));
      expect(restored.pitchYawDampening, equals(0.82));
      expect(restored.rollDampening, equals(0.94));
      expect(restored.rollingShutterCorrection, isFalse);
      expect(restored, equals(original));
    });

    test('StabilizationCompilerService generates deterministic FFmpeg deshake and crop filters', () {
      const disabled = StabilizationConfig();
      expect(
        StabilizationCompilerService.generateFFmpegFilters(disabled, targetWidth: 1920, targetHeight: 1080),
        isEmpty,
      );

      final enabled = StabilizationConfig.fromLevel(StabilizationLevel.recommended);
      final filters = StabilizationCompilerService.generateFFmpegFilters(
        enabled,
        targetWidth: 1920,
        targetHeight: 1080,
      );

      expect(filters, isNotEmpty);
      expect(filters.any((f) => f.contains('deshake=')), isTrue);
      expect(filters.any((f) => f.contains('crop=')), isTrue);
      expect(filters.any((f) => f.contains('scale=1920:1080:flags=lanczos')), isTrue);

      final mirrorConfig = enabled.copyWith(edgeMode: EdgePaddingMode.mirrorEdge);
      final mirrorFilters = StabilizationCompilerService.generateFFmpegFilters(
        mirrorConfig,
        targetWidth: 1920,
        targetHeight: 1080,
      );
      expect(mirrorFilters.any((f) => f.contains('edge=mirror')), isTrue);
    });

    test('StabilizationCompilerService computePreviewTransform applies counter-dampening matrix', () {
      const disabled = StabilizationConfig();
      final idMatrix = StabilizationCompilerService.computePreviewTransform(disabled, 0.5);
      expect(idMatrix.isIdentity(), isTrue);

      final enabled = StabilizationConfig.fromLevel(StabilizationLevel.recommended);
      final activeMatrix = StabilizationCompilerService.computePreviewTransform(enabled, 0.25);
      expect(activeMatrix.isIdentity(), isFalse);
      // Zoom scale must be greater than 1.0 to compensate for crop margin
      expect(activeMatrix.storage[0], greaterThan(1.0));
    });

    test('StabilizationCompilerService getStabilizationBadge generates descriptive HUD string', () {
      const disabled = StabilizationConfig();
      expect(StabilizationCompilerService.getStabilizationBadge(disabled), isEmpty);
      expect(disabled.badge, isEmpty);

      final enabled = StabilizationConfig.fromLevel(StabilizationLevel.recommended);
      expect(enabled.badge, contains('STABILIZED'));
      expect(enabled.badge, contains('RECOMMENDED'));
      expect(enabled.badge, contains('10% CROP'));
    });

    test('FFmpegCommandBuilder integrates stabilization filter commands into export pipeline', () {
      final stabClip = Clip(
        id: 'clip_stab_01',
        assetId: 'asset_01',
        trackId: 'track_video_01',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        stabilization: StabilizationConfig.fromLevel(StabilizationLevel.recommended),
      );

      final project = Project(
        id: 'proj_stab_test',
        name: 'Stabilization Test Project',
        assets: const [
          MediaAsset(
            id: 'asset_01',
            path: '/media/action_run.mp4',
            fileName: 'action_run.mp4',
            type: MediaType.video,
            durationMs: 4000,
          ),
        ],
        tracks: [
          Track(
            id: 'track_video_01',
            name: 'Main Video',
            type: TrackType.video,
            clips: [stabClip],
          ),
        ],
      );

      const config = ExportConfiguration(
        outputPath: '/out/stabilized_render.mp4',
      );

      final cmd = FFmpegCommandBuilder.buildArguments(project, config);

      expect(cmd.any((arg) => arg.contains('deshake=')), isTrue);
      expect(cmd.any((arg) => arg.contains('scale=')), isTrue);
    });

    testWidgets('StabilizationSheet renders studio controls and responds to level selection', (tester) async {
      StabilizationConfig curConfig = const StabilizationConfig();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StabilizationSheet(
              initialConfig: curConfig,
              onApply: (newConf) => curConfig = newConf,
            ),
          ),
        ),
      );

      // Verify Header and Gyro HUD
      expect(find.text('AI Video Stabilization'), findsOneWidget);
      expect(find.text('GYRO HORIZON LOCK'), findsOneWidget);

      // Verify Level Selector
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Minimal Crop'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('Most Stable'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Tap on Recommended
      await tester.tap(find.text('Recommended'));
      await tester.pumpAndSettle();

      expect(curConfig.isEnabled, isTrue);
      expect(curConfig.level, equals(StabilizationLevel.recommended));
      expect(curConfig.cropMargin, equals(0.10));

      // Sliders & Algorithm section should now be visible
      expect(find.text('ENGINE ALGORITHM'), findsOneWidget);
      expect(find.text('DAMPENING CONTROLS'), findsOneWidget);
      expect(find.text('Smoothing Factor'), findsOneWidget);
      expect(find.text('Zoom Crop Margin'), findsOneWidget);

      // Hold to compare raw video
      expect(find.text('Hold to Compare Raw Video'), findsOneWidget);
      final rawButtonFinder = find.byType(GestureDetector).last;
      final gesture = await tester.startGesture(tester.getCenter(rawButtonFinder));
      await tester.pump();
      expect(find.text('Showing Raw Shaky Video'), findsOneWidget);

      await gesture.up();
      await tester.pump();
      expect(find.text('Hold to Compare Raw Video'), findsOneWidget);
    });
  });
}
