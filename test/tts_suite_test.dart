import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/tts/models/tts_voice_profile.dart';
import 'package:edito/features/tts/services/tts_generation_service.dart';

void main() {
  group('TTSVoiceProfile & TTSConfig Model Tests', () {
    test('Default TTSConfig is initialized with Narrator Adam and standard rate', () {
      const config = TTSConfig();
      expect(config.voice, TTSVoiceProfile.narratorAdam);
      expect(config.speechRate, 1.0);
      expect(config.pitchShift, 0.0);
      expect(config.volumeBoost, 1.0);
      expect(config.autoGenerateCaptions, true);
    });

    test('All TTSVoiceProfile personas define valid acoustic parameters', () {
      for (final profile in TTSVoiceProfile.values) {
        expect(profile.displayName.isNotEmpty, true);
        expect(profile.fundamentalHz, greaterThan(50));
        expect(profile.f1Hz, greaterThan(300));
        expect(profile.f2Hz, greaterThan(profile.f1Hz));
        expect(profile.f3Hz, greaterThan(profile.f2Hz));
        expect(profile.avatarEmoji.isNotEmpty, true);
      }
    });

    test('TTSConfig serialization and deserialization retains all fields', () {
      const original = TTSConfig(
        voice: TTSVoiceProfile.viralMax,
        scriptText: 'Check out this insane new video editing trick!',
        speechRate: 1.25,
        pitchShift: 1.5,
        volumeBoost: 1.2,
        autoGenerateCaptions: false,
      );

      final json = original.toJson();
      final deserialized = TTSConfig.fromJson(json);

      expect(deserialized.voice, TTSVoiceProfile.viralMax);
      expect(deserialized.scriptText, 'Check out this insane new video editing trick!');
      expect(deserialized.speechRate, 1.25);
      expect(deserialized.pitchShift, 1.5);
      expect(deserialized.volumeBoost, 1.2);
      expect(deserialized.autoGenerateCaptions, false);
      expect(deserialized, equals(original));
    });
  });

  group('TTSGenerationService Tests', () {
    test('estimateSpokenDurationMs calculates accurate duration with speech rate and pauses', () {
      // 15 words at 150 WPM = 6.0 seconds. 2 periods add ~640ms
      const script = 'Hello everyone. Today we are testing high end video editing features in Flutter. Enjoy!';
      final durationNormal = TTSGenerationService.estimateSpokenDurationMs(script: script, speechRate: 1.0);
      final durationFast = TTSGenerationService.estimateSpokenDurationMs(script: script, speechRate: 1.5);
      final durationSlow = TTSGenerationService.estimateSpokenDurationMs(script: script, speechRate: 0.75);

      expect(durationNormal, inInclusiveRange(4000, 8000));
      expect(durationFast, lessThan(durationNormal));
      expect(durationSlow, greaterThan(durationNormal));
    });

    test('generateRealisticWaveform produces valid normalized audio amplitudes', () {
      final waveform = TTSGenerationService.generateRealisticWaveform(5000, sampleCount: 64);
      expect(waveform.length, 64);
      for (final sample in waveform) {
        expect(sample, inInclusiveRange(0.05, 1.0));
      }
    });

    test('generateSpeechFFmpegFilter generates carrier synthesis with vocal formants and limiter', () {
      const config = TTSConfig(
        voice: TTSVoiceProfile.narratorAdam,
        pitchShift: -1.0,
        volumeBoost: 1.2,
      );

      final filter = TTSGenerationService.generateSpeechFFmpegFilter(config, durationMs: 4500);

      expect(filter, contains('aevalsrc='));
      expect(filter, contains('bandpass=f=500'));
      expect(filter, contains('bandpass=f=1500'));
      expect(filter, contains('volume=1.20'));
      expect(filter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
    });

    test('insertVoiceoverClip correctly injects new audio clip and asset into project', () {
      final project = Project(
        id: 'p1',
        title: 'Voiceover Test Project',
        durationMs: 10000,
        tracks: [
          Track(
            id: 't_video',
            type: TrackType.video,
            clips: [
              Clip(
                id: 'c_vid',
                assetId: 'a_vid',
                startTimeMs: 0,
                durationMs: 10000,
                sourceInMs: 0,
                sourceOutMs: 10000,
              ),
            ],
          ),
        ],
        assets: const [
          MediaAsset(id: 'a_vid', path: 'vid.mp4', fileName: 'vid.mp4', type: MediaType.video, durationMs: 10000),
        ],
      );

      const ttsConfig = TTSConfig(
        voice: TTSVoiceProfile.storytellerEmma,
        scriptText: 'Once upon a time in a digital studio.',
        speechRate: 1.0,
      );

      final updatedProject = TTSGenerationService.insertVoiceoverClip(
        project: project,
        config: ttsConfig,
        startTimeMs: 2000,
      );

      // Verify audio track exists
      final audioTracks = updatedProject.tracks.where((t) => t.type == TrackType.audio).toList();
      expect(audioTracks.isNotEmpty, true);

      // Verify clip inserted
      final insertedClip = audioTracks.first.clips.firstWhere((c) => c.id.startsWith('tts_clip_'));
      expect(insertedClip.startTimeMs, 2000);
      expect(insertedClip.durationMs, greaterThan(1000));
      expect(insertedClip.audioEffects.aiVoiceBoost, true);

      // Verify asset added
      final ttsAsset = updatedProject.assets.firstWhere((a) => a.id == insertedClip.assetId);
      expect(ttsAsset.type, MediaType.audio);
      expect(ttsAsset.waveform?.isNotEmpty, true);
    });

    test('generateSynchronizedCaptions chunks script into chronological timed captions', () {
      const script = 'The quick brown fox jumps over the lazy sleeping dog near the river';
      final captions = TTSGenerationService.generateSynchronizedCaptions(
        script: script,
        startTimeMs: 1000,
        totalDurationMs: 6000,
      );

      expect(captions.length, greaterThan(1));
      expect(captions.first.startTimeMs, 1000);
      expect(captions.first.text.isNotEmpty, true);
      // Last caption ends around or before startTime + totalDuration
      final last = captions.last;
      expect(last.startTimeMs + last.durationMs, closeTo(7000, 1500));
    });
  });
}
