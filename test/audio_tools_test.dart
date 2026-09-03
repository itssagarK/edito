import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/audio/models/audio_effects_config.dart';
import 'package:edito/features/audio/services/ai_voice_enhancer_service.dart';
import 'package:edito/features/audio/services/audio_ducking_service.dart';

void main() {
  group('Audio Tools & AI Voice Enhancer Tests', () {
    test('AudioEffectsConfig JSON serialization roundtrip', () {
      const config = AudioEffectsConfig(
        isVoiceEnhancerEnabled: true,
        denoiseIntensity: 0.85,
        voiceClarityGain: 1.4,
        fadeInMs: 1500,
        fadeOutMs: 2000,
        isDuckingEnabled: true,
        duckingAttenuation: 0.25,
      );

      final json = config.toJson();
      final restored = AudioEffectsConfig.fromJson(json);

      expect(restored.isVoiceEnhancerEnabled, isTrue);
      expect(restored.denoiseIntensity, equals(0.85));
      expect(restored.voiceClarityGain, equals(1.4));
      expect(restored.fadeInMs, equals(1500));
      expect(restored.fadeOutMs, equals(2000));
      expect(restored.isDuckingEnabled, isTrue);
      expect(restored.duckingAttenuation, equals(0.25));
    });

    test('AIVoiceEnhancerService generates correct FFmpeg filter chain', () {
      const config = AudioEffectsConfig(
        isVoiceEnhancerEnabled: true,
        denoiseIntensity: 0.80,
        voiceClarityGain: 1.5,
        fadeInMs: 1000,
      );

      final filterStr = AIVoiceEnhancerService.generateFFmpegFilter(config, baseVolume: 1.25);

      expect(filterStr, contains('highpass=f=80'));
      expect(filterStr, contains('equalizer=f=3200'));
      expect(filterStr, contains('afftdn=nr=20.0:nf=-45'));
      expect(filterStr, contains('lowpass=f=12000'));
      expect(filterStr, contains('afade=t=in:st=0:d=1.00'));
      expect(filterStr, contains('volume=1.25'));
    });

    test('AIVoiceEnhancerService supports Loud Voice Booster and Voice Modulation', () {
      const config = AudioEffectsConfig(
        isLoudVoiceEnabled: true,
        voiceBoost: 1.8,
        modulationPreset: VoiceModulationPreset.studioBroadcast,
      );

      final filterStr = AIVoiceEnhancerService.generateFFmpegFilter(config);

      expect(filterStr, contains('volume=1.80'));
      expect(filterStr, contains('compand=attacks=0.02:decays=0.15'));
      expect(filterStr, contains('equalizer=f=120:width_type=o:width=1.2:g=3.5'));
    });

    test('AudioDuckingService attenuates background music when dialogue track is active', () {
      final now = DateTime.now();

      // Video Clip with Dialogue from 1000ms to 5000ms
      const speechClip = Clip(
        id: 'c_speech',
        assetId: 'a_speech',
        trackId: 't_video',
        startTimeMs: 1000,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      // Music Clip on background audio track from 0 to 10000ms
      const musicClip = Clip(
        id: 'c_music',
        assetId: 'a_music',
        trackId: 't_music',
        startTimeMs: 0,
        durationMs: 10000,
        sourceInMs: 0,
        sourceOutMs: 10000,
        audioEffects: AudioEffectsConfig(
          isDuckingEnabled: true,
          duckingAttenuation: 0.30,
        ),
      );

      final videoTrack = const Track(
        id: 't_video',
        name: 'Dialogue Track',
        type: TrackType.video,
        order: 0,
        clips: [speechClip],
      );

      final musicTrack = const Track(
        id: 't_music',
        name: 'Music Track',
        type: TrackType.audio,
        order: 1,
        clips: [musicClip],
      );

      final project = Project(
        id: 'p_duck',
        title: 'Ducking Test',
        createdAt: now,
        updatedAt: now,
        durationMs: 10000,
        tracks: [videoTrack, musicTrack],
      );

      // At timestamp 500ms (before speech starts): full volume 1.0
      final factorBefore = AudioDuckingService.calculateDuckingFactor(project, musicTrack, 500);
      expect(factorBefore, equals(1.0));

      // At timestamp 2500ms (during speech): ducked volume 0.3
      final factorDuring = AudioDuckingService.calculateDuckingFactor(project, musicTrack, 2500, duckingAttenuation: 0.3);
      expect(factorDuring, equals(0.3));

      // At timestamp 6000ms (after speech ends): full volume 1.0
      final factorAfter = AudioDuckingService.calculateDuckingFactor(project, musicTrack, 6000);
      expect(factorAfter, equals(1.0));
    });
  });
}
