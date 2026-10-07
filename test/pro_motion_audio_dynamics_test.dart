import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/timeline/models/freeze_climax_config.dart';
import 'package:edito/features/timeline/services/freeze_climax_service.dart';
import 'package:edito/features/speed/models/speed_ease_config.dart';
import 'package:edito/features/speed/services/speed_ease_compiler_service.dart';
import 'package:edito/features/audio/models/spatial_audio_pan_config.dart';
import 'package:edito/features/audio/services/spatial_pan_compiler_service.dart';
import 'package:edito/features/editor/providers/editor_provider.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';

void main() {
  group('Phase 15 - FreezeClimaxService & FreezeClimaxConfig Tests', () {
    test('FreezeClimaxConfig default state and serialization', () {
      const config = FreezeClimaxConfig();
      expect(config.freezeDurationMs, equals(1500));
      expect(config.zoomScale, equals(1.25));
      expect(config.flashAccent, isTrue);
      expect(config.accentStyle, equals(FreezeAccentStyle.actionGrit));

      final json = config.toJson();
      final revived = FreezeClimaxConfig.fromJson(json);
      expect(revived, equals(config));
    });

    test('insertFreezeClimax splits target clip and inserts freeze frame with zoom and flash', () {
      const clip = Clip(
        id: 'clip_original',
        assetId: 'asset_1',
        timelineInMs: 0,
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      final track = Track(
        id: 'video_track_1',
        name: 'Video Track',
        type: TrackType.video,
        clips: [clip],
      );

      final audioClip = const Clip(
        id: 'audio_clip_1',
        assetId: 'asset_audio',
        timelineInMs: 0,
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      final audioTrack = Track(
        id: 'audio_track_1',
        name: 'Audio Track',
        type: TrackType.audio,
        clips: [audioClip],
      );

      final project = Project(
        id: 'proj_freeze',
        title: 'Freeze Test',
        tracks: [track, audioTrack],
      );

      // Target position: 2000ms (dead center)
      final updatedProject = FreezeClimaxService.insertFreezeClimax(
        project,
        trackId: 'video_track_1',
        clipId: 'clip_original',
        targetPositionMs: 2000,
        config: const FreezeClimaxConfig(
          freezeDurationMs: 1500,
          zoomScale: 1.35,
          flashAccent: true,
          accentStyle: FreezeAccentStyle.monochrome,
          muteAudioDuringFreeze: true,
        ),
        rippleAllTracks: true,
      );

      final updatedVideoTrack = updatedProject.tracks.firstWhere((t) => t.id == 'video_track_1');
      // Original clip split into left, freeze, right
      expect(updatedVideoTrack.clips.length, equals(3));

      final leftClip = updatedVideoTrack.clips[0];
      final freezeClip = updatedVideoTrack.clips[1];
      final rightClip = updatedVideoTrack.clips[2];

      // Left clip: 0ms to 2000ms
      expect(leftClip.startTimeMs, equals(0));
      expect(leftClip.durationMs, equals(2000));
      expect(leftClip.sourceOutMs, equals(2000));

      // Freeze clip: starts at 2000ms, duration 1500ms
      expect(freezeClip.startTimeMs, equals(2000));
      expect(freezeClip.durationMs, equals(1500));
      expect(freezeClip.isFreezeFrame, isTrue);
      expect(freezeClip.freezeSourceMs, equals(2000));
      expect(freezeClip.transform.scale, equals(1.35));
      expect(freezeClip.impactFlash.isActive, isTrue);
      expect(freezeClip.colorGrading.saturation, equals(0.0)); // Monochrome accent
      expect(freezeClip.volume, equals(0.0)); // Muted during freeze

      // Right clip: starts after freeze at 3500ms (2000 + 1500)
      expect(rightClip.startTimeMs, equals(3500));
      expect(rightClip.durationMs, equals(2000));
      expect(rightClip.sourceInMs, equals(2000));
      expect(rightClip.sourceOutMs, equals(4000));
    });
  });

  group('Phase 15 - SpeedEaseConfig & SpeedEaseCompilerService Tests', () {
    test('SpeedEaseConfig default state and JSON roundtrip', () {
      const config = SpeedEaseConfig(
        isEnabled: true,
        preset: SpeedEasePreset.heroEntrance,
        p1x: 0.1,
        p1y: 0.9,
        p2x: 0.2,
        p2y: 1.0,
        minSpeed: 0.2,
        maxSpeed: 4.0,
      );

      expect(config.isActive, isTrue);
      final json = config.toJson();
      final revived = SpeedEaseConfig.fromJson(json);

      expect(revived, equals(config));
      expect(revived.preset, equals(SpeedEasePreset.heroEntrance));
    });

    test('SpeedEaseConfig Newton-Raphson boundary conditions', () {
      const config = SpeedEaseConfig(isEnabled: true);

      // Easing at 0.0 must be 0.0
      expect(config.evaluateEasing(0.0), equals(0.0));
      // Easing at 1.0 must be 1.0
      expect(config.evaluateEasing(1.0), equals(1.0));
      // Monotonic interpolation within bounds
      final midEase = config.evaluateEasing(0.5);
      expect(midEase, inInclusiveRange(0.0, 1.0));
    });

    test('SpeedEaseConfig evaluateSpeedAt respects minSpeed and maxSpeed bounds', () {
      const config = SpeedEaseConfig(
        isEnabled: true,
        minSpeed: 0.25,
        maxSpeed: 3.0,
      );

      final speedAtStart = config.evaluateSpeedAt(0.0);
      final speedAtEnd = config.evaluateSpeedAt(1.0);
      final speedAtMid = config.evaluateSpeedAt(0.5);

      expect(speedAtStart, closeTo(0.25, 0.01));
      expect(speedAtEnd, closeTo(3.0, 0.01));
      expect(speedAtMid, inInclusiveRange(0.25, 3.0));
    });

    test('SpeedEaseCompilerService generates valid piecewise points and FFmpeg filters', () {
      const config = SpeedEaseConfig(
        isEnabled: true,
        minSpeed: 0.5,
        maxSpeed: 2.0,
      );

      final points = SpeedEaseCompilerService.convertToCurvePoints(config, subdivisions: 4);
      expect(points.length, equals(5));
      expect(points.first.x, equals(0.0));
      expect(points.last.x, equals(1.0));

      final filters = SpeedEaseCompilerService.generateFFmpegFilters(
        config,
        clipDurationMs: 2000,
        targetFps: 30,
      );

      expect(filters.isNotEmpty, isTrue);
      expect(filters[0], contains('setpts='));
      expect(filters[1], contains('fps=fps=30'));
    });
  });

  group('Phase 15 - SpatialAudioPanConfig & SpatialPanCompilerService Tests', () {
    test('Equal-power panning preserves total energy', () {
      const config = SpatialAudioPanConfig(isEnabled: true);

      // At center (pan = 0): angle = pi/4, L = R = cos(pi/4) ~= 0.7071
      final centerGains = config.calculateEqualPowerGains(0.0);
      expect(centerGains.$1, closeTo(math.cos(math.pi / 4.0), 0.001));
      expect(centerGains.$2, closeTo(math.sin(math.pi / 4.0), 0.001));
      // Power preservation: L^2 + R^2 == 1.0
      final totalPower = (centerGains.$1 * centerGains.$1) + (centerGains.$2 * centerGains.$2);
      expect(totalPower, closeTo(1.0, 0.001));

      // At full left (pan = -1.0): angle = 0, L = 1.0, R = 0.0
      final leftGains = config.calculateEqualPowerGains(-1.0);
      expect(leftGains.$1, closeTo(1.0, 0.001));
      expect(leftGains.$2, closeTo(0.0, 0.001));

      // At full right (pan = +1.0): angle = pi/2, L = 0.0, R = 1.0
      final rightGains = config.calculateEqualPowerGains(1.0);
      expect(rightGains.$1, closeTo(0.0, 0.001));
      expect(rightGains.$2, closeTo(1.0, 0.001));
    });

    test('8D Orbit calculates continuous sinusoidal trajectory', () {
      const config = SpatialAudioPanConfig(
        isEnabled: true,
        pan: 0.0,
        is8DOrbitEnabled: true,
        orbitSpeedHz: 0.5, // 1 cycle every 2 seconds
        orbitDepth: 0.8,
      );

      // At t = 0: sin(0) = 0 => pan = 0.0
      expect(config.calculateInstantaneousPan(0.0), closeTo(0.0, 0.01));
      // At t = 0.5s: sin(pi/2) = 1 => pan = +0.8
      expect(config.calculateInstantaneousPan(0.5), closeTo(0.8, 0.01));
      // At t = 1.5s: sin(3pi/2) = -1 => pan = -0.8
      expect(config.calculateInstantaneousPan(1.5), closeTo(-0.8, 0.01));
    });

    test('SpatialPanCompilerService generates valid static and 8D FFmpeg filters with limiter', () {
      const staticConfig = SpatialAudioPanConfig(isEnabled: true, pan: -0.5);
      final staticFilters = SpatialPanCompilerService.generateFFmpegFilters(staticConfig);

      expect(staticFilters.length, equals(2));
      expect(staticFilters[0], contains('pan=stereo|c0='));
      expect(staticFilters[1], contains('alimiter=limit=0.95')); // Rule 4 compliant

      const orbitConfig = SpatialAudioPanConfig(
        isEnabled: true,
        is8DOrbitEnabled: true,
        orbitSpeedHz: 0.3,
        orbitDepth: 0.9,
      );
      final orbitFilters = SpatialPanCompilerService.generateFFmpegFilters(orbitConfig);

      expect(orbitFilters.length, equals(2));
      expect(orbitFilters[0], contains("stereotools=mpan='"));
      expect(orbitFilters[0], contains('sin(2*PI*'));
      expect(orbitFilters[1], contains('alimiter=limit=0.95'));
    });
  });

  group('Phase 15 - Tool & Model Completeness', () {
    test('EditorTool contains freezeClimax, speedEase, spatialPan', () {
      expect(EditorTool.values, contains(EditorTool.freezeClimax));
      expect(EditorTool.values, contains(EditorTool.speedEase));
      expect(EditorTool.values, contains(EditorTool.spatialPan));
    });

    test('Clip contains speedEase and spatialPan with clean defaults', () {
      const clip = Clip(
        id: 'clip_p15',
        assetId: 'asset_p15',
        timelineInMs: 0,
        startTimeMs: 0,
        durationMs: 1000,
        sourceInMs: 0,
        sourceOutMs: 1000,
      );

      expect(clip.speedEase.isActive, isFalse);
      expect(clip.spatialPan.isActive, isFalse);

      final modified = clip.copyWith(
        speedEase: const SpeedEaseConfig(isEnabled: true, minSpeed: 0.2),
        spatialPan: const SpatialAudioPanConfig(isEnabled: true, pan: 0.5),
      );

      expect(modified.speedEase.isActive, isTrue);
      expect(modified.spatialPan.isActive, isTrue);

      final json = modified.toJson();
      final revived = Clip.fromJson(json);
      expect(revived.speedEase.isActive, isTrue);
      expect(revived.spatialPan.isActive, isTrue);
    });
  });
}
