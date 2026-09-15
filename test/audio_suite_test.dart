import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/audio/models/audio_effects_config.dart';
import 'package:edito/features/audio/services/ai_voice_enhancer_service.dart';
import 'package:edito/features/audio/services/audio_ducking_service.dart';
import 'package:edito/features/export/models/export_config.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';

void main() {
  group('AudioEffectsConfig Model Tests', () {
    test('Default AudioEffectsConfig has valid initial values', () {
      const config = AudioEffectsConfig();
      expect(config.isVoiceEnhancerEnabled, false);
      expect(config.vocalIsolationMode, VocalIsolationMode.none);
      expect(config.vocalIsolationIntensity, 0.80);
      expect(config.deEsserIntensity, 0.0);
      expect(config.isEqualizerEnabled, false);
      expect(config.equalizerPreset, EqualizerPreset.flat);
      expect(config.eqLowGain, 0.0);
      expect(config.eqMidGain, 0.0);
      expect(config.eqHighGain, 0.0);
      expect(config.highPassCutoff, 0.0);
      expect(config.lowPassCutoff, 22000.0);
      expect(config.isDuckingEnabled, false);
      expect(config.duckingAttenuation, 0.30);
      expect(config.duckingAttackMs, 50);
      expect(config.duckingReleaseMs, 300);
      expect(config.isLoudVoiceEnabled, false);
      expect(config.voiceBoost, 1.40);
    });

    test('AudioEffectsConfig serialization and deserialization retains all fields', () {
      const original = AudioEffectsConfig(
        isVoiceEnhancerEnabled: true,
        denoiseIntensity: 0.85,
        voiceClarityGain: 1.40,
        fadeInMs: 500,
        fadeOutMs: 800,
        isDuckingEnabled: true,
        duckingAttenuation: 0.20,
        duckingThresholdDb: -24.0,
        duckingAttackMs: 60,
        duckingReleaseMs: 450,
        vocalIsolationMode: VocalIsolationMode.isolateVocals,
        vocalIsolationIntensity: 0.90,
        deEsserIntensity: 0.65,
        isEqualizerEnabled: true,
        equalizerPreset: EqualizerPreset.podcastWarmth,
        eqLowGain: 4.5,
        eqLowFreq: 120.0,
        eqMidGain: 2.5,
        eqMidFreq: 3000.0,
        eqMidQ: 1.2,
        eqHighGain: 1.5,
        eqHighFreq: 10000.0,
        highPassCutoff: 80.0,
        lowPassCutoff: 20000.0,
        isLoudVoiceEnabled: true,
        voiceBoost: 1.60,
        modulationPreset: VoiceModulationPreset.studioBroadcast,
        pitchShiftSemitones: 2.0,
        bassEnhance: 1.2,
        trebleCrisp: 1.1,
      );

      final json = original.toJson();
      final deserialized = AudioEffectsConfig.fromJson(json);

      expect(deserialized.isVoiceEnhancerEnabled, true);
      expect(deserialized.vocalIsolationMode, VocalIsolationMode.isolateVocals);
      expect(deserialized.vocalIsolationIntensity, 0.90);
      expect(deserialized.deEsserIntensity, 0.65);
      expect(deserialized.isEqualizerEnabled, true);
      expect(deserialized.equalizerPreset, EqualizerPreset.podcastWarmth);
      expect(deserialized.eqLowGain, 4.5);
      expect(deserialized.eqMidGain, 2.5);
      expect(deserialized.eqHighGain, 1.5);
      expect(deserialized.highPassCutoff, 80.0);
      expect(deserialized.isDuckingEnabled, true);
      expect(deserialized.duckingAttenuation, 0.20);
      expect(deserialized.duckingAttackMs, 60);
      expect(deserialized.duckingReleaseMs, 450);
      expect(deserialized.isLoudVoiceEnabled, true);
      expect(deserialized.voiceBoost, 1.60);
      expect(deserialized.modulationPreset, VoiceModulationPreset.studioBroadcast);
      expect(deserialized, equals(original));
    });
  });

  group('AIVoiceEnhancerService Tests', () {
    test('Clean speech filterchain generates highpass, afftdn, clarity EQ, and lowpass', () {
      const config = AudioEffectsConfig(
        isVoiceEnhancerEnabled: true,
        denoiseIntensity: 0.70,
        voiceClarityGain: 1.25,
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter.contains('highpass=f=80'), isTrue);
      expect(filter.contains('afftdn=nr=17.5:nf=-45'), isTrue);
      expect(filter.contains('equalizer=f=3200'), isTrue);
      expect(filter.contains('lowpass=f=12000'), isTrue);
    });

    test('Vocal isolation mode isolateVocals compiles formant bandpass, heavy gating, and compressor', () {
      const config = AudioEffectsConfig(
        vocalIsolationMode: VocalIsolationMode.isolateVocals,
        vocalIsolationIntensity: 0.85,
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter.contains('highpass=f=95'), isTrue);
      expect(filter.contains('equalizer=f=2800'), isTrue);
      expect(filter.contains('equalizer=f=1200'), isTrue);
      expect(filter.contains('afftdn=nr=27.2:nf=-50'), isTrue);
      expect(filter.contains('compand=attacks=0.01:decays=0.1'), isTrue);
      expect(filter.contains('lowpass=f=8500'), isTrue);
    });

    test('Vocal isolation mode removeVocals compiles center channel stereotools cancellation', () {
      const config = AudioEffectsConfig(
        vocalIsolationMode: VocalIsolationMode.removeVocals,
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter.contains('stereotools=mlev=0.04:slev=1.35'), isTrue);
    });

    test('Sibilance De-Esser generates deesser filter', () {
      const config = AudioEffectsConfig(
        deEsserIntensity: 0.75,
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter.contains('deesser=i=0.75:m=0.5:f=0.5:s=o'), isTrue);
    });

    test('Parametric Equalizer generates HPF, 3-band biquad equalizers, and LPF', () {
      const config = AudioEffectsConfig(
        isEqualizerEnabled: true,
        highPassCutoff: 80.0,
        eqLowGain: 4.0,
        eqLowFreq: 110.0,
        eqMidGain: -3.0,
        eqMidFreq: 1500.0,
        eqMidQ: 1.5,
        eqHighGain: 5.5,
        eqHighFreq: 12000.0,
        lowPassCutoff: 18000.0,
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter.contains('highpass=f=80'), isTrue);
      expect(filter.contains('equalizer=f=110:width_type=q:width=0.7:g=+4.0'), isTrue);
      expect(filter.contains('equalizer=f=1500:width_type=q:width=1.50:g=-3.0'), isTrue);
      expect(filter.contains('equalizer=f=12000:width_type=q:width=0.7:g=+5.5'), isTrue);
      expect(filter.contains('lowpass=f=18000'), isTrue);
    });

    test('Loud Voice Booster generates gain boost, compressor, and true-peak alimiter ceiling', () {
      const config = AudioEffectsConfig(
        isLoudVoiceEnabled: true,
        voiceBoost: 1.50,
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter.contains('volume=1.50'), isTrue);
      expect(filter.contains('compand=attacks=0.02:decays=0.15'), isTrue);
      expect(filter.contains('alimiter=limit=0.95:attack=5:release=50:asc=1'), isTrue);
    });

    test('Generates accurate real-time HUD badges', () {
      const isolate = AudioEffectsConfig(vocalIsolationMode: VocalIsolationMode.isolateVocals, vocalIsolationIntensity: 0.80);
      expect(AIVoiceEnhancerService.getAudioBadge(isolate), contains('VOCAL ISOLATE (80%)'));

      const remove = AudioEffectsConfig(vocalIsolationMode: VocalIsolationMode.removeVocals);
      expect(AIVoiceEnhancerService.getAudioBadge(remove), contains('INSTRUMENTAL'));

      const eq = AudioEffectsConfig(isEqualizerEnabled: true, equalizerPreset: EqualizerPreset.podcastWarmth);
      expect(AIVoiceEnhancerService.getAudioBadge(eq), contains('EQ: PODCAST WARMTH'));

      const loud = AudioEffectsConfig(isLoudVoiceEnabled: true, voiceBoost: 1.50);
      expect(AIVoiceEnhancerService.getAudioBadge(loud), contains('LOUD BOOSTER (+5dB)'));
    });
  });

  group('AudioDuckingService Tests', () {
    test('Calculates foreground speech intervals and ducking factors with smooth ramps', () {
      const vAsset = MediaAsset(
        id: 'asset-speech',
        path: '/storage/speech.mp4',
        fileName: 'speech.mp4',
        type: MediaType.video,
        durationMs: 10000,
        hasAudio: true,
      );

      const aAsset = MediaAsset(
        id: 'asset-music',
        path: '/storage/music.mp3',
        fileName: 'music.mp3',
        type: MediaType.audio,
        durationMs: 10000,
        hasAudio: true,
      );

      const speechClip = Clip(
        id: 'clip-speech',
        assetId: 'asset-speech',
        trackId: 't-video',
        startTimeMs: 2000,
        durationMs: 4000, // 2s to 6s
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      const musicClip = Clip(
        id: 'clip-music',
        assetId: 'asset-music',
        trackId: 't-audio',
        startTimeMs: 0,
        durationMs: 10000,
        sourceInMs: 0,
        sourceOutMs: 10000,
        audioEffects: AudioEffectsConfig(isDuckingEnabled: true, duckingAttenuation: 0.30),
      );

      const videoTrack = Track(
        id: 't-video',
        name: 'Video Track',
        type: TrackType.video,
        clips: [speechClip],
      );

      const audioTrack = Track(
        id: 't-audio',
        name: 'Music Track',
        type: TrackType.audio,
        clips: [musicClip],
      );

      const project = Project(
        id: 'p-ducking',
        name: 'Ducking Test',
        durationMs: 10000,
        tracks: [videoTrack, audioTrack],
        assets: [vAsset, aAsset],
      );

      // Outside speech (at 1.0s) -> full volume 1.0
      expect(AudioDuckingService.calculateDuckingFactor(project, audioTrack, 1000), 1.0);

      // Deep inside speech (at 4.0s) -> ducked volume 0.30
      expect(AudioDuckingService.calculateDuckingFactor(project, audioTrack, 4000), 0.30);

      // Builds dynamic FFmpeg volume expression for background clip
      final filter = AudioDuckingService.buildDuckingVolumeFilter(
        project: project,
        backgroundClip: musicClip,
        baseVolume: 1.0,
      );

      expect(filter.contains('volume=eval=frame:volume='), isTrue);
      expect(filter.contains('between(t,2.00,6.00)'), isTrue);
      expect(filter.contains('0.30,1.00'), isTrue);
    });
  });

  group('FFmpeg Export Audio Pipeline Integration', () {
    test('Builds export command with dynamic ducking and parametric EQ', () {
      const vAsset = MediaAsset(
        id: 'asset-speech-exp',
        path: '/storage/voice.mp4',
        fileName: 'voice.mp4',
        type: MediaType.video,
        durationMs: 5000,
        hasAudio: true,
      );

      const aAsset = MediaAsset(
        id: 'asset-bg-music',
        path: '/storage/bg.mp3',
        fileName: 'bg.mp3',
        type: MediaType.audio,
        durationMs: 5000,
        hasAudio: true,
      );

      const speechClip = Clip(
        id: 'clip-vocal',
        assetId: 'asset-speech-exp',
        trackId: 't-speech',
        startTimeMs: 1000,
        durationMs: 3000,
        sourceInMs: 0,
        sourceOutMs: 3000,
        audioEffects: AudioEffectsConfig(
          isEqualizerEnabled: true,
          equalizerPreset: EqualizerPreset.vocalAir,
          eqHighGain: 5.0,
          eqHighFreq: 12000.0,
          vocalIsolationMode: VocalIsolationMode.isolateVocals,
          vocalIsolationIntensity: 0.80,
        ),
      );

      const musicClip = Clip(
        id: 'clip-bg',
        assetId: 'asset-bg-music',
        trackId: 't-music',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        audioEffects: AudioEffectsConfig(
          isDuckingEnabled: true,
          duckingAttenuation: 0.25,
        ),
      );

      const track1 = Track(id: 't-speech', name: 'Speech', type: TrackType.video, clips: [speechClip]);
      const track2 = Track(id: 't-music', name: 'Music', type: TrackType.audio, clips: [musicClip]);

      const project = Project(
        id: 'p-audio-export',
        name: 'Audio Export Test',
        durationMs: 5000,
        tracks: [track1, track2],
        assets: [vAsset, aAsset],
      );

      final cmd = FFmpegCommandBuilder.build(
        project: project,
        config: const ExportConfig(),
        outputPath: '/storage/audio_out.mp4',
      );

      // Must include vocal isolation filter
      expect(cmd.command.contains('afftdn='), isTrue);
      // Must include parametric EQ filter
      expect(cmd.command.contains('equalizer=f=12000'), isTrue);
      // Must include dynamic frame ducking filter
      expect(cmd.command.contains('volume=eval=frame'), isTrue);
      // Must include audio format harmonization
      expect(cmd.command.contains('aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo'), isTrue);
    });
  });
}
