import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/audio/models/audio_effects_config.dart';
import 'package:edito/features/audio/services/audio_ducking_service.dart';
import 'package:edito/features/audio/services/audio_vad_service.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';

void main() {
  group('AudioEffectsConfig VAD Ducking Tests', () {
    test('Default AudioEffectsConfig has VAD ducking enabled with empty intervals', () {
      const config = AudioEffectsConfig();
      expect(config.isVadDuckingEnabled, isTrue);
      expect(config.speechIntervalsMs, isEmpty);
      expect(config.hasCustomSpeechIntervals, isFalse);
    });

    test('copyWith updates VAD fields accurately', () {
      const config = AudioEffectsConfig();
      final updated = config.copyWith(
        isVadDuckingEnabled: true,
        speechIntervalsMs: [
          [500, 2500],
          [4000, 7500],
        ],
      );

      expect(updated.isVadDuckingEnabled, isTrue);
      expect(updated.hasCustomSpeechIntervals, isTrue);
      expect(updated.speechIntervalsMs.length, 2);
      expect(updated.speechIntervalsMs[0], [500, 2500]);
    });

    test('Backward compatibility: legacy JSON without VAD fields defaults safely', () {
      final legacyJson = <String, dynamic>{
        'isDuckingEnabled': true,
        'duckingAttenuation': 0.25,
        'duckingAttackMs': 60,
        'duckingReleaseMs': 400,
      };

      final parsed = AudioEffectsConfig.fromJson(legacyJson);
      expect(parsed.isDuckingEnabled, isTrue);
      expect(parsed.isVadDuckingEnabled, isTrue);
      expect(parsed.speechIntervalsMs, isEmpty);
      expect(parsed.duckingAttenuation, 0.25);
    });

    test('JSON serialization round-trip preserves VAD speech intervals', () {
      const original = AudioEffectsConfig(
        isDuckingEnabled: true,
        isVadDuckingEnabled: true,
        speechIntervalsMs: [
          [200, 1800],
          [3000, 5500],
        ],
      );

      final json = original.toJson();
      final deserialized = AudioEffectsConfig.fromJson(json);

      expect(deserialized.isVadDuckingEnabled, isTrue);
      expect(deserialized.speechIntervalsMs.length, 2);
      expect(deserialized.speechIntervalsMs[1], [3000, 5500]);
    });
  });

  group('AudioVadService On-Device Speech Detection Tests', () {
    test('detectSpeechFromPcm isolates distinct speech bursts separated by silence', () {
      // 100 samples across 10000ms (100ms per sample)
      // Samples 10-30: speech (high energy)
      // Samples 31-60: silence (low energy)
      // Samples 61-85: speech (high energy)
      final pcm = List<double>.filled(100, 0.01);
      for (int i = 10; i <= 30; i++) {
        pcm[i] = 0.65;
      }
      for (int i = 61; i <= 85; i++) {
        pcm[i] = 0.80;
      }

      final segments = AudioVadService.detectSpeechFromPcm(
        pcmPeaks: pcm,
        durationMs: 10000,
        sensitivity: 0.70,
        minSpeechMs: 200,
        minSilenceMs: 300,
      );

      expect(segments.length, 2);
      // First segment: ~1000ms to ~3100ms
      expect(segments[0][0], closeTo(1000, 100));
      expect(segments[0][1], closeTo(3100, 100));
      // Second segment: ~6100ms to ~8600ms
      expect(segments[1][0], closeTo(6100, 100));
      expect(segments[1][1], closeTo(8600, 100));
    });

    test('getSpeechSummary formats human readable status', () {
      final summary = AudioVadService.getSpeechSummary([
        [1000, 3500],
        [5000, 8000],
      ]);
      expect(summary, contains('2 speech segments'));
      expect(summary, contains('5.5s dialogue'));
    });
  });

  group('AudioDuckingService VAD-Driven Project Ducking Tests', () {
    test('getForegroundSpeechIntervals uses VAD intervals when present on clip', () {
      final clip = Clip(
        id: 'clip_video_1',
        assetId: 'sample.mp4',
        name: 'Video 1',
        startTimeMs: 1000,
        durationMs: 10000,
        audioEffects: const AudioEffectsConfig(
          isVadDuckingEnabled: true,
          speechIntervalsMs: [
            [500, 2500], // 1.5s to 3.5s in project timeline
            [6000, 8000], // 7.0s to 9.0s in project timeline
          ],
        ),
      );

      final project = Project(
        id: 'proj_1',
        name: 'Test Project',
        tracks: [
          Track(
            id: 't_video',
            name: 'Video Track',
            type: TrackType.video,
            clips: [clip],
          ),
        ],
      );

      final intervals = AudioDuckingService.getForegroundSpeechIntervals(project);
      expect(intervals.length, 2);
      expect(intervals[0].startSec, closeTo(1.5, 0.05));
      expect(intervals[0].endSec, closeTo(3.5, 0.05));
      expect(intervals[1].startSec, closeTo(7.0, 0.05));
      expect(intervals[1].endSec, closeTo(9.0, 0.05));
    });

    test('calculateDuckingFactor ducks volume during speech and restores during conversational silence', () {
      final clip = Clip(
        id: 'clip_video_1',
        assetId: 'sample.mp4',
        name: 'Video 1',
        startTimeMs: 0,
        durationMs: 10000,
        audioEffects: const AudioEffectsConfig(
          isVadDuckingEnabled: true,
          speechIntervalsMs: [
            [2000, 4000], // Speech between 2.0s and 4.0s
          ],
        ),
      );

      const backgroundClip = Clip(
        id: 'bg_music',
        assetId: 'music.mp3',
        name: 'Background Music',
        startTimeMs: 0,
        durationMs: 10000,
        audioEffects: AudioEffectsConfig(
          isDuckingEnabled: true,
          duckingAttenuation: 0.30,
          duckingAttackMs: 50,
          duckingReleaseMs: 300,
        ),
      );

      final project = Project(
        id: 'proj_1',
        name: 'Test Project',
        tracks: [
          Track(
            id: 't_video',
            name: 'Video Track',
            type: TrackType.video,
            clips: [clip],
          ),
          const Track(
            id: 't_audio',
            name: 'Music Track',
            type: TrackType.audio,
            clips: [backgroundClip],
          ),
        ],
      );

      final musicTrack = project.tracks[1];

      // At 1000ms: silence (before speech) -> Volume 1.0 (no ducking)
      final factorBefore = AudioDuckingService.calculateDuckingFactor(
        project,
        musicTrack,
        1000,
        duckingAttenuation: 0.30,
      );
      expect(factorBefore, 1.0);

      // At 3000ms: active speech -> Ducked to 0.30 (-10dB)
      final factorDuring = AudioDuckingService.calculateDuckingFactor(
        project,
        musicTrack,
        3000,
        duckingAttenuation: 0.30,
      );
      expect(factorDuring, closeTo(0.30, 0.01));

      // At 6000ms: silence (after speech release ramp) -> Restored to 1.0
      final factorAfter = AudioDuckingService.calculateDuckingFactor(
        project,
        musicTrack,
        6000,
        duckingAttenuation: 0.30,
      );
      expect(factorAfter, 1.0);
    });
  });
}
