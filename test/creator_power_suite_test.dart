import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/beats/services/beat_cutter_service.dart';
import 'package:edito/features/audio/models/audio_fade_config.dart';
import 'package:edito/features/audio/services/audio_fade_compiler_service.dart';
import 'package:edito/features/vfx/models/impact_flash_config.dart';
import 'package:edito/features/vfx/services/impact_flash_compiler_service.dart';
import 'package:edito/features/editor/providers/editor_provider.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';

void main() {
  group('Creator Power Suite - BeatCutterService Tests', () {
    test('generateTempoGridBeats produces correct interval beat points', () {
      // 120 BPM => 500ms per beat => at 3000ms duration, beats at 0, 500, 1000, 1500, 2000, 2500, 3000
      final beats = BeatCutterService.generateTempoGridBeats(120.0, 3000);
      expect(beats.length, equals(7));
      expect(beats, containsAllInOrder([0, 500, 1000, 1500, 2000, 2500, 3000]));
    });

    test('generateTempoGridBeats handles invalid BPM with safe fallback', () {
      final beats = BeatCutterService.generateTempoGridBeats(0.0, 2000);
      expect(beats.isNotEmpty, isTrue);
    });

    test('cutTrackOnBeats splits video clip on rhythmic cadence', () {
      const clip = Clip(
        id: 'clip_1',
        assetId: 'asset_1',
        timelineInMs: 0,
        durationMs: 4000,
      );

      final track = Track(
        id: 'video_track_1',
        name: 'Main Video',
        type: TrackType.video,
        clips: [clip],
      );

      final project = Project(
        id: 'proj_1',
        title: 'Beat Test',
        tracks: [track],
      );

      // Beats at 1000ms, 2000ms, 3000ms
      final beats = [1000, 2000, 3000];

      // Cadence = 1 (every beat), minDuration = 500ms
      final result = BeatCutterService.cutTrackOnBeats(
        project,
        'video_track_1',
        beats,
        cadence: 1,
        minClipDurationMs: 500,
      );

      final updatedTrack = result.tracks.firstWhere((t) => t.id == 'video_track_1');
      expect(updatedTrack.clips.length, equals(4));
      expect(updatedTrack.clips[0].durationMs, equals(1000));
      expect(updatedTrack.clips[1].durationMs, equals(1000));
      expect(updatedTrack.clips[2].durationMs, equals(1000));
      expect(updatedTrack.clips[3].durationMs, equals(1000));
    });

    test('cutTrackOnBeats honors cadence = 2 (every 2nd beat)', () {
      const clip = Clip(
        id: 'clip_1',
        assetId: 'asset_1',
        timelineInMs: 0,
        durationMs: 4000,
      );

      final track = Track(
        id: 'video_track_1',
        name: 'Main Video',
        type: TrackType.video,
        clips: [clip],
      );

      final project = Project(
        id: 'proj_1',
        title: 'Beat Test',
        tracks: [track],
      );

      // Beats at 1000ms, 2000ms, 3000ms. With cadence 2, only cut at 2000ms.
      final beats = [1000, 2000, 3000];

      final result = BeatCutterService.cutTrackOnBeats(
        project,
        'video_track_1',
        beats,
        cadence: 2,
        minClipDurationMs: 500,
      );

      final updatedTrack = result.tracks.firstWhere((t) => t.id == 'video_track_1');
      expect(updatedTrack.clips.length, equals(2));
      expect(updatedTrack.clips[0].durationMs, equals(2000));
      expect(updatedTrack.clips[1].durationMs, equals(2000));
    });

    test('snapClipsToBeats snaps clip boundary within threshold', () {
      const clip1 = Clip(
        id: 'c1',
        assetId: 'a1',
        timelineInMs: 0,
        durationMs: 980, // 20ms away from 1000ms beat
      );
      const clip2 = Clip(
        id: 'c2',
        assetId: 'a2',
        timelineInMs: 980,
        durationMs: 1000,
      );

      final track = Track(
        id: 'track_1',
        name: 'Video Track',
        type: TrackType.video,
        clips: [clip1, clip2],
      );

      final project = Project(
        id: 'proj_snap',
        title: 'Snap Test',
        tracks: [track],
      );

      final beats = [1000, 2000];

      final snapped = BeatCutterService.snapClipsToBeats(
        project,
        'track_1',
        beats,
        snapThresholdMs: 50,
      );

      final updatedTrack = snapped.tracks.firstWhere((t) => t.id == 'track_1');
      // clip1 duration should snap from 980ms to 1000ms
      expect(updatedTrack.clips[0].durationMs, equals(1000));
      expect(updatedTrack.clips[1].timelineInMs, equals(1000));
    });
  });

  group('Creator Power Suite - AudioFadeConfig & AudioFadeCompilerService Tests', () {
    test('AudioFadeConfig default state and isActive', () {
      const config = AudioFadeConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isActive, isFalse);

      final activeConfig = config.copyWith(isEnabled: true, fadeInMs: 500);
      expect(activeConfig.isActive, isTrue);
    });

    test('AudioFadeConfig JSON serialization roundtrip', () {
      const config = AudioFadeConfig(
        isEnabled: true,
        fadeInMs: 650,
        fadeOutMs: 1200,
        fadeInCurve: AudioFadeCurve.exponential,
        fadeOutCurve: AudioFadeCurve.sCurve,
      );

      final json = config.toJson();
      final revived = AudioFadeConfig.fromJson(json);

      expect(revived, equals(config));
      expect(revived.fadeInCurve, equals(AudioFadeCurve.exponential));
      expect(revived.fadeOutCurve, equals(AudioFadeCurve.sCurve));
    });

    test('AudioFadeCompilerService generates correct FFmpeg afade filters', () {
      const config = AudioFadeConfig(
        isEnabled: true,
        fadeInMs: 500,
        fadeOutMs: 800,
        fadeInCurve: AudioFadeCurve.logarithmic,
        fadeOutCurve: AudioFadeCurve.exponential,
      );

      final filters = AudioFadeCompilerService.generateFFmpegFilters(
        config,
        clipDurationMs: 3000,
      );

      expect(filters.length, equals(2));
      // Fade in: 500ms = 0.500s, curve = log
      expect(filters[0], equals('afade=t=in:ss=0:d=0.500:curve=log'));
      // Fade out: 800ms = 0.800s, clip is 3.000s, start at 3.000 - 0.800 = 2.200s, curve = exp
      expect(filters[1], equals('afade=t=out:st=2.200:d=0.800:curve=exp'));
    });

    test('AudioFadeCompilerService clamps fade durations to half of clip length if combined exceeds total', () {
      const config = AudioFadeConfig(
        isEnabled: true,
        fadeInMs: 2000,
        fadeOutMs: 2000,
      );

      // Clip duration is 1000ms => max fade per side is 500ms
      final filters = AudioFadeCompilerService.generateFFmpegFilters(
        config,
        clipDurationMs: 1000,
      );

      expect(filters.length, equals(2));
      expect(filters[0], contains('d=0.500'));
      expect(filters[1], contains('d=0.500'));
    });
  });

  group('Creator Power Suite - ImpactFlashConfig & ImpactFlashCompilerService Tests', () {
    test('ImpactFlashConfig default state and isActive', () {
      const config = ImpactFlashConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isActive, isFalse);

      final active = config.copyWith(isEnabled: true, durationMs: 250, intensity: 0.9);
      expect(active.isActive, isTrue);
    });

    test('ImpactFlashConfig evaluateOpacity decay behavior', () {
      const config = ImpactFlashConfig(
        isEnabled: true,
        durationMs: 200,
        intensity: 1.0,
        decayCurve: ImpactDecayCurve.linear,
      );

      // Boundary: before 0ms
      expect(config.evaluateOpacity(-10), equals(0.0));
      // At cut point (t = 0): maximum intensity
      expect(config.evaluateOpacity(0), closeTo(1.0, 0.01));
      // Halfway (t = 100ms): linear 0.5
      expect(config.evaluateOpacity(100), closeTo(0.5, 0.01));
      // At or after durationMs (t = 200ms): 0.0
      expect(config.evaluateOpacity(200), equals(0.0));
      expect(config.evaluateOpacity(300), equals(0.0));
    });

    test('ImpactFlashConfig exponential decay reduces faster than linear', () {
      const linearConfig = ImpactFlashConfig(
        isEnabled: true,
        durationMs: 200,
        intensity: 1.0,
        decayCurve: ImpactDecayCurve.linear,
      );
      const expConfig = ImpactFlashConfig(
        isEnabled: true,
        durationMs: 200,
        intensity: 1.0,
        decayCurve: ImpactDecayCurve.exponential,
      );

      final linearMid = linearConfig.evaluateOpacity(100);
      final expMid = expConfig.evaluateOpacity(100);

      expect(expMid, lessThan(linearMid));
    });

    test('ImpactFlashConfig JSON serialization roundtrip', () {
      const config = ImpactFlashConfig(
        isEnabled: true,
        type: ImpactFlashType.rgbStrobe,
        durationMs: 350,
        intensity: 0.75,
        decayCurve: ImpactDecayCurve.sCurve,
      );

      final json = config.toJson();
      final revived = ImpactFlashConfig.fromJson(json);

      expect(revived, equals(config));
      expect(revived.type, equals(ImpactFlashType.rgbStrobe));
      expect(revived.decayCurve, equals(ImpactDecayCurve.sCurve));
    });

    test('ImpactFlashCompilerService generates FFmpeg drawbox filters for all types', () {
      for (final type in ImpactFlashType.values) {
        final config = ImpactFlashConfig(
          isEnabled: true,
          type: type,
          durationMs: 200,
          intensity: 0.85,
        );

        final filters = ImpactFlashCompilerService.generateFFmpegFilters(
          config,
          clipDurationMs: 2000,
          targetWidth: 1920,
          targetHeight: 1080,
        );

        expect(filters.isNotEmpty, isTrue);
        expect(filters.first, contains('drawbox=x=0:y=0:w=iw:h=ih:'));
        expect(filters.first, contains("enable='lte(t,0.200)'"));
      }
    });
  });

  group('Creator Power Suite - EditorTool Enum Completeness', () {
    test('EditorTool contains beatCut, audioFade, impactFlash', () {
      expect(EditorTool.values, contains(EditorTool.beatCut));
      expect(EditorTool.values, contains(EditorTool.audioFade));
      expect(EditorTool.values, contains(EditorTool.impactFlash));
    });

    test('Clip contains audioFade and impactFlash with defaults', () {
      const clip = Clip(
        id: 'test_clip',
        assetId: 'asset_1',
        timelineInMs: 0,
        durationMs: 1000,
      );

      expect(clip.audioFade.isActive, isFalse);
      expect(clip.impactFlash.isActive, isFalse);

      final modified = clip.copyWith(
        audioFade: const AudioFadeConfig(isEnabled: true, fadeInMs: 300),
        impactFlash: const ImpactFlashConfig(isEnabled: true, durationMs: 150),
      );

      expect(modified.audioFade.isActive, isTrue);
      expect(modified.impactFlash.isActive, isTrue);

      final json = modified.toJson();
      final revived = Clip.fromJson(json);
      expect(revived.audioFade.isActive, isTrue);
      expect(revived.impactFlash.isActive, isTrue);
    });
  });
}
