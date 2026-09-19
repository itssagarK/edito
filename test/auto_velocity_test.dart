import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/beats/models/beat_detection_config.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/speed/models/auto_velocity_config.dart';
import 'package:edito/features/speed/models/speed_curve_preset.dart';
import 'package:edito/features/speed/services/auto_velocity_service.dart';
import 'package:edito/features/speed/presentation/widgets/auto_velocity_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature 21 - AutoVelocityConfig Model & Presets Tests', () {
    test('Default constructor sets expected fallback parameters', () {
      const config = AutoVelocityConfig();
      expect(config.isEnabled, isFalse);
      expect(config.style, AutoVelocityStyle.classic);
      expect(config.interval, VelocityInterval.everyBeat);
      expect(config.slowSpeed, 0.35);
      expect(config.fastSpeed, 3.5);
      expect(config.enableSmoothSlowMo, isTrue);
      expect(config.enableFlashPulse, isTrue);
      expect(config.flashIntensity, 0.70);
      expect(config.enableMicroZoom, isTrue);
      expect(config.microZoomFactor, 1.08);
      expect(config.enableRgbGlitch, isFalse);
    });

    test('All CapCut Pro velocity presets are configured with valid ranges', () {
      expect(AutoVelocityConfig.presetClassic.isEnabled, isTrue);
      expect(AutoVelocityConfig.presetClassic.style, AutoVelocityStyle.classic);
      expect(AutoVelocityConfig.presetClassic.fastSpeed, 3.5);

      expect(AutoVelocityConfig.presetPhonkTrap.isEnabled, isTrue);
      expect(AutoVelocityConfig.presetPhonkTrap.style, AutoVelocityStyle.phonkTrap);
      expect(AutoVelocityConfig.presetPhonkTrap.fastSpeed, 6.0);
      expect(AutoVelocityConfig.presetPhonkTrap.enableRgbGlitch, isTrue);

      expect(AutoVelocityConfig.presetHyperDrift.isEnabled, isTrue);
      expect(AutoVelocityConfig.presetHyperDrift.style, AutoVelocityStyle.hyperDrift);
      expect(AutoVelocityConfig.presetHyperDrift.slowSpeed, 0.25);

      expect(AutoVelocityConfig.presetStutterBpm.isEnabled, isTrue);
      expect(AutoVelocityConfig.presetStutterBpm.interval, VelocityInterval.halfBeat);

      expect(AutoVelocityConfig.presetLofiChill.isEnabled, isTrue);
      expect(AutoVelocityConfig.presetLofiChill.slowSpeed, 0.70);
      expect(AutoVelocityConfig.presetLofiChill.fastSpeed, 1.50);
    });

    test('Json serialization and deserialization retains all fields', () {
      const config = AutoVelocityConfig(
        isEnabled: true,
        style: AutoVelocityStyle.phonkTrap,
        interval: VelocityInterval.halfBeat,
        slowSpeed: 0.15,
        fastSpeed: 7.2,
        enableSmoothSlowMo: false,
        enableFlashPulse: true,
        flashIntensity: 0.85,
        enableMicroZoom: true,
        microZoomFactor: 1.20,
        enableRgbGlitch: true,
      );

      final json = config.toJson();
      final roundtrip = AutoVelocityConfig.fromJson(json);

      expect(roundtrip, equals(config));
      expect(roundtrip.slowSpeed, 0.15);
      expect(roundtrip.fastSpeed, 7.2);
      expect(roundtrip.enableRgbGlitch, isTrue);
      expect(roundtrip.microZoomFactor, 1.20);
    });
  });

  group('Feature 21 - AutoVelocityService Curve Generation Tests', () {
    const baseClip = Clip(
      id: 'c-test',
      assetId: 'a-test',
      trackId: 't-test',
      startTimeMs: 0,
      durationMs: 5000,
      sourceInMs: 0,
      sourceOutMs: 5000,
    );

    test('generateVelocityCurve returns existing curve when disabled', () {
      const config = AutoVelocityConfig(isEnabled: false);
      final curve = AutoVelocityService.generateVelocityCurve(baseClip, config);
      expect(curve, equals(baseClip.speedCurve));
    });

    test('generateVelocityCurve builds synchronized Bezier bursts on beat timestamps', () {
      const config = AutoVelocityConfig(
        isEnabled: true,
        slowSpeed: 0.2,
        fastSpeed: 4.0,
      );

      final beatTimestamps = [1000, 2500, 4000];
      final curve = AutoVelocityService.generateVelocityCurve(
        baseClip,
        config,
        explicitBeatMs: beatTimestamps,
      );

      expect(curve.type, SpeedCurveType.custom);
      expect(curve.curvePoints.isNotEmpty, isTrue);
      expect(curve.curvePoints.first.x, 0.0);
      expect(curve.curvePoints.last.x, 1.0);

      // Verify peaks near 1000ms (0.2), 2500ms (0.5), 4000ms (0.8)
      final peak1 = curve.curvePoints.firstWhere((p) => (p.x - 0.20).abs() < 0.02);
      final peak2 = curve.curvePoints.firstWhere((p) => (p.x - 0.50).abs() < 0.02);
      final peak3 = curve.curvePoints.firstWhere((p) => (p.x - 0.80).abs() < 0.02);

      expect(peak1.y, 4.0);
      expect(peak2.y, 4.0);
      expect(peak3.y, 4.0);
    });

    test('generateVelocityCurve synthesizes rhythmic BPM grid when no beat markers exist', () {
      const config = AutoVelocityConfig(
        isEnabled: true,
        slowSpeed: 0.3,
        fastSpeed: 3.0,
      );

      final curve = AutoVelocityService.generateVelocityCurve(
        baseClip,
        config,
        fallbackBpm: 120.0, // 500ms intervals over 5000ms -> ~9 internal beats
      );

      expect(curve.curvePoints.length, greaterThan(6));
      expect(curve.isSmoothSlowMo, isTrue);
    });
  });

  group('Feature 21 - AutoVelocityService Micro-Effects & Badges', () {
    const config = AutoVelocityConfig(
      isEnabled: true,
      enableMicroZoom: true,
      microZoomFactor: 1.12,
      enableFlashPulse: true,
      flashIntensity: 0.80,
    );
    final beats = [1000, 2000, 3000];

    test('calculateMicroZoom returns peak zoom at exact beat and decays with distance', () {
      // At exact beat (1000ms), zoom is max
      final zoomOnBeat = AutoVelocityService.calculateMicroZoom(1000, beats, config);
      expect(zoomOnBeat, closeTo(1.12, 0.001));

      // 60ms away (1060ms), zoom decays midway
      final zoomOffset = AutoVelocityService.calculateMicroZoom(1060, beats, config);
      expect(zoomOffset, greaterThan(1.0));
      expect(zoomOffset, lessThan(1.12));

      // 500ms away (1500ms), completely neutral 1.0
      final zoomFar = AutoVelocityService.calculateMicroZoom(1500, beats, config);
      expect(zoomFar, 1.0);
    });

    test('calculateFlashOpacity peaks on beat and fades forward', () {
      // Exactly on beat
      final flashOnBeat = AutoVelocityService.calculateFlashOpacity(1000, beats, config);
      expect(flashOnBeat, closeTo(0.80 * 0.75, 0.01));

      // 50ms after beat
      final flashHalf = AutoVelocityService.calculateFlashOpacity(1050, beats, config);
      expect(flashHalf, greaterThan(0.0));
      expect(flashHalf, lessThan(flashOnBeat));

      // 200ms after beat
      final flashNone = AutoVelocityService.calculateFlashOpacity(1200, beats, config);
      expect(flashNone, 0.0);
    });

    test('generateFFmpegFilters creates brightness and rgbashift filter expressions', () {
      final clipWithBeats = Clip(
        id: 'c1',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        beatConfig: const BeatDetectionConfig(
          isEnabled: true,
          beatTimestampsMs: [1000, 2000],
        ),
      );

      const phConfig = AutoVelocityConfig(
        isEnabled: true,
        enableFlashPulse: true,
        flashIntensity: 0.8,
        enableRgbGlitch: true,
      );

      final filters = AutoVelocityService.generateFFmpegFilters(clipWithBeats, phConfig);
      expect(filters.any((f) => f.contains('eq=brightness=')), isTrue);
      expect(filters.any((f) => f.contains('between(t\\,1.000\\,1.000+0.08)')), isTrue);
      expect(filters.any((f) => f.contains('rgbashift=rh=5:bh=-5')), isTrue);
    });

    test('getBadge produces informative HUD titles', () {
      expect(AutoVelocityService.getBadge(AutoVelocityConfig.presetClassic), contains('3.5x'));
      expect(AutoVelocityService.getBadge(AutoVelocityConfig.presetPhonkTrap), contains('PHONK RUSH'));
      expect(AutoVelocityService.getBadge(const AutoVelocityConfig(isEnabled: false)), isEmpty);
    });
  });

  group('Feature 21 - AutoVelocitySheet Widget Tests', () {
    testWidgets('Renders AutoVelocitySheet with preset chips and sliders', (tester) async {
      Clip? savedClip;

      const clip = Clip(
        id: 'c-widget',
        assetId: 'a-widget',
        trackId: 't-widget',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoVelocitySheet(
              clip: clip,
              onSave: (c) => savedClip = c,
            ),
          ),
        ),
      );

      expect(find.text('AI Auto-Velocity Studio'), findsOneWidget);
      expect(find.text('⚡ Classic Velocity'), findsOneWidget);
      expect(find.text('💥 Phonk / Trap Rush'), findsOneWidget);
      expect(find.text('Re-Calculate & Apply Velocity Ramp'), findsOneWidget);

      // Tap Phonk / Trap preset
      await tester.tap(find.text('💥 Phonk / Trap Rush'));
      await tester.pumpAndSettle();

      expect(savedClip, isNotNull);
      expect(savedClip!.autoVelocity.style, AutoVelocityStyle.phonkTrap);
      expect(savedClip!.autoVelocity.fastSpeed, 6.0);
    });
  });

  group('Feature 21 - FFmpegCommandBuilder Auto-Velocity Integration', () {
    test('FFmpegCommandBuilder integrates Auto-Velocity micro-effects into export command', () {
      const asset = MediaAsset(
        id: 'a-velocity',
        path: '/storage/dance.mp4',
        fileName: 'dance.mp4',
        type: MediaType.video,
        durationMs: 5000,
      );

      final velocityClip = Clip(
        id: 'c-velocity',
        assetId: 'a-velocity',
        trackId: 't-velocity',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        beatConfig: const BeatDetectionConfig(
          isEnabled: true,
          beatTimestampsMs: [1200, 2400],
        ),
        autoVelocity: const AutoVelocityConfig(
          isEnabled: true,
          style: AutoVelocityStyle.phonkTrap,
          enableFlashPulse: true,
          flashIntensity: 0.9,
          enableRgbGlitch: true,
        ),
      );

      final track = Track(
        id: 't-velocity',
        name: 'Velocity Track',
        type: TrackType.video,
        clips: [velocityClip],
      );

      final project = Project(
        id: 'p-velocity',
        name: 'Velocity Export Test',
        durationMs: 5000,
        tracks: [track],
        assets: [asset],
      );

      final result = FFmpegCommandBuilder.build(
        project: project,
        config: const ExportConfiguration(),
        outputPath: '/storage/velocity_out.mp4',
      );

      expect(result.command.contains('eq=brightness='), isTrue);
      expect(result.command.contains('between(t\\,1.200\\,1.200+0.08)'), isTrue);
      expect(result.command.contains('rgbashift=rh=5:bh=-5'), isTrue);
    });
  });
}
