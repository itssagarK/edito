import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/color_grading/models/color_grading_config.dart';
import 'package:edito/features/export/models/export_config.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/speed/models/speed_curve_preset.dart';
import 'package:edito/features/speed/services/speed_ramping_service.dart';

void main() {
  group('SpeedCurve Model & Presets Tests', () {
    test('All SpeedCurveType presets have valid normalized bounds', () {
      for (final type in SpeedCurveType.values) {
        final points = type.defaultCurvePoints;
        expect(points.length, greaterThanOrEqualTo(2));
        expect(points.first.x, 0.0);
        expect(points.last.x, 1.0);
        for (final p in points) {
          expect(p.x, inInclusiveRange(0.0, 1.0));
          expect(p.y, inInclusiveRange(0.1, 10.0));
        }
      }
    });

    test('SpeedCurveConfig serialization and deserialization retains all properties', () {
      const config = SpeedCurveConfig(
        type: SpeedCurveType.montage,
        constantSpeed: 2.5,
        enablePitchCorrection: false,
        isSmoothSlowMo: true,
        curvePoints: [
          CurvePoint(0.0, 2.0),
          CurvePoint(0.5, 0.4),
          CurvePoint(1.0, 2.0),
        ],
      );

      final json = config.toJson();
      final deserialized = SpeedCurveConfig.fromJson(json);

      expect(deserialized.type, SpeedCurveType.montage);
      expect(deserialized.constantSpeed, 2.5);
      expect(deserialized.enablePitchCorrection, false);
      expect(deserialized.isSmoothSlowMo, true);
      expect(deserialized.curvePoints.length, 3);
      expect(deserialized, equals(config));
    });
  });

  group('SpeedRampingService Tests', () {
    test('Calculates effective average speed accurately across curve points', () {
      // Linear ramp from 1.0x to 3.0x over 0.0 to 1.0 (Average = 2.0x)
      const rampConfig = SpeedCurveConfig(
        type: SpeedCurveType.custom,
        curvePoints: [
          CurvePoint(0.0, 1.0),
          CurvePoint(1.0, 3.0),
        ],
      );

      final avgSpeed = SpeedRampingService.calculateEffectiveAverageSpeed(rampConfig, 1.0);
      expect(avgSpeed, closeTo(2.0, 0.01));
    });

    test('Calculates source media offset using trapezoidal integration', () {
      const clip = Clip(
        id: 'c-test',
        assetId: 'a-test',
        trackId: 't-test',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 8000,
        speedCurve: SpeedCurveConfig(
          type: SpeedCurveType.custom,
          curvePoints: [
            CurvePoint(0.0, 1.0),
            CurvePoint(1.0, 3.0),
          ],
        ),
      );

      // At start (0ms), source offset is 0
      expect(SpeedRampingService.calculateSourceOffset(clip, 0), 0);

      // At 50% timeline (2000ms), integrated area of triangle/trapezoid:
      // v(0.5) = 2.0. Area = 0.5 * (1.0 + 2.0)/2 = 0.75 / 2 = 0.75 of total?
      // Total area from 0 to 1 is (1+3)/2 = 2.0.
      // Area from 0 to 0.5 is 0.5 * (1 + 2)/2 = 0.75.
      // Relative source position = 0.75 * 8000 = 6000ms.
      final offsetMid = SpeedRampingService.calculateSourceOffset(clip, 2000);
      expect(offsetMid, closeTo(6000, 100));
    });

    test('Generates chained atempo filters for extreme speeds outside 0.5-2.0', () {
      // Normal range: single filter
      expect(SpeedRampingService.generateAudioSpeedFilter(1.5), 'atempo=1.50');
      expect(SpeedRampingService.generateAudioSpeedFilter(0.8), 'atempo=0.80');

      // Extreme high speed (4.0x): chained into 2.0 * 2.0
      final f4 = SpeedRampingService.generateAudioSpeedFilter(4.0);
      expect(f4, 'atempo=2.0,atempo=2.00');

      // Extreme high speed (3.0x): chained into 2.0 * 1.5
      final f3 = SpeedRampingService.generateAudioSpeedFilter(3.0);
      expect(f3, 'atempo=2.0,atempo=1.50');

      // Extreme slow speed (0.25x): chained into 0.5 * 0.5
      final fSlow = SpeedRampingService.generateAudioSpeedFilter(0.25);
      expect(fSlow, 'atempo=0.5,atempo=0.50');
    });

    test('Generates vinyl/tape pitch shift filters when pitch correction is disabled', () {
      // Speed 1.5x with pitch correction disabled modulates sample rate
      final fTapeFast = SpeedRampingService.generateAudioSpeedFilter(1.5, enablePitchCorrection: false);
      expect(fTapeFast, 'asetrate=72000,aresample=48000');

      // Speed 0.5x with pitch correction disabled drops pitch
      final fTapeSlow = SpeedRampingService.generateAudioSpeedFilter(0.5, enablePitchCorrection: false);
      expect(fTapeSlow, 'asetrate=24000,aresample=48000');
    });

    test('Appends optical-flow minterpolate filter when isSmoothSlowMo is active', () {
      const slowConfig = SpeedCurveConfig(
        type: SpeedCurveType.constant,
        constantSpeed: 0.3,
        isSmoothSlowMo: true,
      );

      final filters = SpeedRampingService.generateFFmpegVideoSpeedFilters(
        slowConfig,
        0.3,
        targetFps: 60,
      );

      expect(filters.any((f) => f.contains('setpts=PTS/0.30')), isTrue);
      expect(filters.any((f) => f.contains('minterpolate=fps=60:mi_mode=mci:mc_mode=aobmc:vsbmc=1')), isTrue);
    });
  });

  group('FFmpeg Command Builder Speed Integration', () {
    test('Builds safe chained atempo and setpts filters on export', () {
      const asset = MediaAsset(
        id: 'asset-speed',
        path: '/storage/speed.mp4',
        fileName: 'speed.mp4',
        type: MediaType.video,
        durationMs: 10000,
        hasAudio: true,
      );

      const speedClip = Clip(
        id: 'clip-speed',
        assetId: 'asset-speed',
        trackId: 't-speed',
        startTimeMs: 0,
        durationMs: 2500,
        sourceInMs: 0,
        sourceOutMs: 10000,
        speed: 4.0,
        speedCurve: SpeedCurveConfig(
          type: SpeedCurveType.constant,
          constantSpeed: 4.0,
          enablePitchCorrection: true,
        ),
      );

      const track = Track(
        id: 't-speed',
        name: 'Video',
        type: TrackType.video,
        clips: [speedClip],
      );

      const project = Project(
        id: 'p-speed',
        name: 'Speed Export Test',
        durationMs: 2500,
        tracks: [track],
        assets: [asset],
      );

      final cmd = FFmpegCommandBuilder.build(
        project: project,
        config: const ExportConfig(),
        outputPath: '/storage/speed_export.mp4',
      );

      // Verify setpts speed dilation
      expect(cmd.command.contains('setpts=PTS/4.00'), isTrue);
      // Verify safe chained atempo (never raw atempo=4.0)
      expect(cmd.command.contains('atempo=2.0,atempo=2.00'), isTrue);
    });
  });
}
