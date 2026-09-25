import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/denoise/models/denoise_config.dart';
import 'package:edito/features/denoise/services/denoise_compiler_service.dart';
import 'package:edito/features/denoise/presentation/widgets/denoise_sheet.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/media_asset.dart';

void main() {
  group('Feature 30: CapCut Pro Video De-Noise & Low-Light Studio Suite Tests', () {
    test('DenoiseLevel enums provide accurate labels, descriptions, and thresholds', () {
      expect(DenoiseLevel.none.label, equals('Off'));
      expect(DenoiseLevel.mild.label, equals('Mild Clean'));
      expect(DenoiseLevel.balanced.label, equals('Balanced'));
      expect(DenoiseLevel.lowLightNight.label, equals('Low-Light Night'));
      expect(DenoiseLevel.ultraClean.label, equals('Ultra Clean'));
      expect(DenoiseLevel.custom.label, equals('Custom Tuning'));

      for (final level in DenoiseLevel.values) {
        expect(level.label.isNotEmpty, isTrue);
        expect(level.description.isNotEmpty, isTrue);
      }

      expect(DenoiseLevel.balanced.defaultSpatialLuma, equals(4.0));
      expect(DenoiseLevel.lowLightNight.defaultSpatialLuma, equals(7.5));
      expect(DenoiseLevel.ultraClean.defaultTemporalLuma, equals(16.0));
    });

    test('DenoiseAlgorithm enums provide correct labels and short labels', () {
      expect(DenoiseAlgorithm.spatioTemporal3D.label, contains('3D'));
      expect(DenoiseAlgorithm.adaptiveTemporal.label, contains('Adaptive'));
      expect(DenoiseAlgorithm.edgePreservingBilateral.label, contains('Bilateral'));

      expect(DenoiseAlgorithm.spatioTemporal3D.shortLabel, equals('3D HQ'));
      expect(DenoiseAlgorithm.adaptiveTemporal.shortLabel, equals('Adaptive'));
    });

    test('DenoiseConfig default constructor and fromLevel factory', () {
      const defaultConfig = DenoiseConfig();
      expect(defaultConfig.isEnabled, isFalse);
      expect(defaultConfig.level, equals(DenoiseLevel.none));
      expect(defaultConfig.algorithm, equals(DenoiseAlgorithm.spatioTemporal3D));
      expect(defaultConfig.spatialLuma, equals(4.0));
      expect(defaultConfig.temporalLuma, equals(6.0));
      expect(defaultConfig.detailSharpening, equals(0.35));
      expect(defaultConfig.lowLightBoost, equals(0.0));
      expect(defaultConfig.badge, isEmpty);

      final balanced = DenoiseConfig.fromLevel(DenoiseLevel.balanced, lowLightBoost: 0.25);
      expect(balanced.isEnabled, isTrue);
      expect(balanced.level, equals(DenoiseLevel.balanced));
      expect(balanced.lowLightBoost, equals(0.25));
      expect(balanced.badge, equals('DENOISE: BALANCED'));

      final night = DenoiseConfig.fromLevel(DenoiseLevel.lowLightNight);
      expect(night.isEnabled, isTrue);
      expect(night.level, equals(DenoiseLevel.lowLightNight));
      expect(night.spatialLuma, equals(7.5));
      expect(night.badge, equals('DENOISE: LOW-LIGHT NIGHT'));

      final noneConfig = DenoiseConfig.fromLevel(DenoiseLevel.none);
      expect(noneConfig.isEnabled, isFalse);
    });

    test('DenoiseConfig JSON serialization and deserialization roundtrip', () {
      const original = DenoiseConfig(
        isEnabled: true,
        level: DenoiseLevel.ultraClean,
        algorithm: DenoiseAlgorithm.adaptiveTemporal,
        spatialLuma: 10.0,
        spatialChroma: 12.0,
        temporalLuma: 14.0,
        temporalChroma: 11.0,
        detailSharpening: 0.65,
        lowLightBoost: 0.40,
      );

      final json = original.toJson();
      final restored = DenoiseConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.level, equals(DenoiseLevel.ultraClean));
      expect(restored.algorithm, equals(DenoiseAlgorithm.adaptiveTemporal));
      expect(restored.spatialLuma, equals(10.0));
      expect(restored.spatialChroma, equals(12.0));
      expect(restored.temporalLuma, equals(14.0));
      expect(restored.temporalChroma, equals(11.0));
      expect(restored.detailSharpening, equals(0.65));
      expect(restored.lowLightBoost, equals(0.40));
      expect(restored, equals(original));
    });

    test('DenoiseCompilerService generates deterministic FFmpeg filters', () {
      const disabled = DenoiseConfig();
      expect(DenoiseCompilerService.generateFFmpegFilters(disabled), isEmpty);

      // 1. Spatio-temporal 3D filter
      final balanced = DenoiseConfig.fromLevel(DenoiseLevel.balanced);
      final bFilters = DenoiseCompilerService.generateFFmpegFilters(balanced);
      expect(bFilters.any((f) => f.contains('hqdn3d=')), isTrue);
      expect(bFilters.any((f) => f.contains('unsharp=')), isTrue);

      // 2. Adaptive temporal filter
      final adaptive = balanced.copyWith(algorithm: DenoiseAlgorithm.adaptiveTemporal);
      final aFilters = DenoiseCompilerService.generateFFmpegFilters(adaptive);
      expect(aFilters.any((f) => f.contains('atadenoise=')), isTrue);

      // 3. Bilateral filter
      final bilateral = balanced.copyWith(algorithm: DenoiseAlgorithm.edgePreservingBilateral);
      final biFilters = DenoiseCompilerService.generateFFmpegFilters(bilateral);
      expect(biFilters.any((f) => f.contains('hqdn3d=') && f.contains(':0.0:0.0')), isTrue);

      // 4. Low light boost adds eq filter
      final nightBoost = balanced.copyWith(lowLightBoost: 0.50);
      final nFilters = DenoiseCompilerService.generateFFmpegFilters(nightBoost);
      expect(nFilters.any((f) => f.contains('eq=contrast=') && f.contains('brightness=')), isTrue);
    });

    test('DenoiseCompilerService calculates ColorFilter matrix for viewport feedback', () {
      const disabled = DenoiseConfig();
      expect(DenoiseCompilerService.calculateColorMatrix(disabled), equals(DenoiseCompilerService.identityMatrix));

      const noBoost = DenoiseConfig(isEnabled: true, level: DenoiseLevel.balanced, lowLightBoost: 0.0);
      expect(DenoiseCompilerService.calculateColorMatrix(noBoost), equals(DenoiseCompilerService.identityMatrix));

      const withBoost = DenoiseConfig(isEnabled: true, level: DenoiseLevel.balanced, lowLightBoost: 0.5);
      final matrix = DenoiseCompilerService.calculateColorMatrix(withBoost);
      expect(matrix.length, equals(20));
      expect(matrix, isNot(equals(DenoiseCompilerService.identityMatrix)));
    });

    test('Clip model integration: DenoiseConfig copyWith and serialization', () {
      final clip = Clip(
        id: 'clip_denoise_test',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      expect(clip.denoise.isEnabled, isFalse);

      final updatedClip = clip.copyWith(
        denoise: DenoiseConfig.fromLevel(DenoiseLevel.lowLightNight, lowLightBoost: 0.30),
      );

      expect(updatedClip.denoise.isEnabled, isTrue);
      expect(updatedClip.denoise.level, equals(DenoiseLevel.lowLightNight));
      expect(updatedClip.denoise.lowLightBoost, equals(0.30));

      final json = updatedClip.toJson();
      final roundTrip = Clip.fromJson(json);
      expect(roundTrip.denoise.isEnabled, isTrue);
      expect(roundTrip.denoise.level, equals(DenoiseLevel.lowLightNight));
      expect(roundTrip.denoise.lowLightBoost, equals(0.30));
      expect(roundTrip, equals(updatedClip));
    });

    test('FFmpegCommandBuilder includes denoise filters in video pipeline', () {
      final asset = MediaAsset(
        id: 'asset_denoise_1',
        path: '/storage/emulated/0/Movies/sample.mp4',
        fileName: 'sample.mp4',
        type: MediaType.video,
        durationMs: 5000,
        width: 1920,
        height: 1080,
      );

      final clip = Clip(
        id: 'clip_denoise_1',
        assetId: 'asset_denoise_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        denoise: DenoiseConfig.fromLevel(DenoiseLevel.balanced, lowLightBoost: 0.20),
      );

      final track = Track(
        id: 'track_1',
        name: 'Main Video',
        type: TrackType.video,
        clips: [clip],
      );

      final project = Project(
        id: 'proj_denoise',
        name: 'Denoise Project',
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

      expect(filterGraph.contains('hqdn3d='), isTrue);
      expect(filterGraph.contains('unsharp='), isTrue);
    });

    testWidgets('DenoiseSheet renders and updates state via user taps', (tester) async {
      DenoiseConfig current = const DenoiseConfig();
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DenoiseSheet(
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

      expect(find.text('AI Video De-Noise'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('DENOISE INTENSITY LEVEL'), findsOneWidget);
      expect(find.text('DSP FILTER ENGINE'), findsOneWidget);
      expect(find.text('Balanced'), findsOneWidget);

      // Tap on Balanced preset
      await tester.tap(find.text('Balanced'));
      await tester.pumpAndSettle();

      expect(current.isEnabled, isTrue);
      expect(current.level, equals(DenoiseLevel.balanced));

      // Tap on Adaptive algorithm chip
      await tester.tap(find.text('Adaptive'));
      await tester.pumpAndSettle();

      expect(current.algorithm, equals(DenoiseAlgorithm.adaptiveTemporal));

      // Tap close button
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
    });
  });
}
