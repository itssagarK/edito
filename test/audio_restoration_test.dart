import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/audio/models/audio_effects_config.dart';
import 'package:edito/features/audio/services/ai_voice_enhancer_service.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/export/models/export_preset.dart';

void main() {
  group('Cinematic Multi-Track Audio Restoration Studio Tests', () {
    test('DeHumMode, DeEsserMode, and RoomReverbPreset enums have valid labels and frequencies', () {
      expect(DeHumMode.off.label, equals('Off'));
      expect(DeHumMode.hz50EuropeAsia.label, contains('50 Hz'));
      expect(DeHumMode.hz60NorthAmerica.label, contains('60 Hz'));
      expect(DeHumMode.custom.label, contains('Custom'));

      expect(DeHumMode.hz50EuropeAsia.defaultFrequency, equals(50.0));
      expect(DeHumMode.hz60NorthAmerica.defaultFrequency, equals(60.0));

      expect(DeEsserMode.wideband.label, contains('Wideband'));
      expect(DeEsserMode.splitBandMale.targetFrequency, equals(5000.0));
      expect(DeEsserMode.splitBandFemale.targetFrequency, equals(7500.0));
      expect(DeEsserMode.crispMicrophone.targetFrequency, equals(9000.0));

      expect(RoomReverbPreset.studioVocalBooth.label, contains('Vocal Booth'));
      expect(RoomReverbPreset.cinematicCathedral.label, contains('Cathedral'));
      expect(RoomReverbPreset.tunnelEcho.label, contains('Echo Tunnel'));
    });

    test('AudioEffectsConfig.getDeHumConfig configures correct powerline parameters', () {
      final eu50 = AudioEffectsConfig.getDeHumConfig(DeHumMode.hz50EuropeAsia);
      expect(eu50.deHumMode, equals(DeHumMode.hz50EuropeAsia));
      expect(eu50.customHumFreq, equals(50.0));
      expect(eu50.deHumHarmonics, equals(3));
      expect(eu50.deHumGain, equals(-32.0));

      final us60 = AudioEffectsConfig.getDeHumConfig(DeHumMode.hz60NorthAmerica);
      expect(us60.deHumMode, equals(DeHumMode.hz60NorthAmerica));
      expect(us60.customHumFreq, equals(60.0));
      expect(us60.deHumHarmonics, equals(3));
    });

    test('AudioEffectsConfig.getReverbPreset configures accurate acoustic parameters', () {
      final booth = AudioEffectsConfig.getReverbPreset(RoomReverbPreset.studioVocalBooth);
      expect(booth.isReverbEnabled, isTrue);
      expect(booth.reverbPreset, equals(RoomReverbPreset.studioVocalBooth));
      expect(booth.reverbRoomSize, equals(0.12));
      expect(booth.reverbDamping, equals(0.85));
      expect(booth.reverbWetGain, equals(0.08));
      expect(booth.reverbDryGain, equals(0.95));

      final cathedral = AudioEffectsConfig.getReverbPreset(RoomReverbPreset.cinematicCathedral);
      expect(cathedral.isReverbEnabled, isTrue);
      expect(cathedral.reverbRoomSize, equals(0.85));
      expect(cathedral.reverbWetGain, equals(0.35));

      final dry = AudioEffectsConfig.getReverbPreset(RoomReverbPreset.none);
      expect(dry.isReverbEnabled, isFalse);
      expect(dry.reverbPreset, equals(RoomReverbPreset.none));
    });

    test('AudioEffectsConfig JSON serialization preserves all restoration and acoustic fields', () {
      const original = AudioEffectsConfig(
        deHumMode: DeHumMode.hz50EuropeAsia,
        deHumGain: -36.0,
        deHumHarmonics: 4,
        customHumFreq: 50.0,
        isWindDePlosiveEnabled: true,
        dePlosiveIntensity: 0.85,
        deEsserMode: DeEsserMode.splitBandFemale,
        deEsserIntensity: 0.70,
        deEsserFrequency: 7500.0,
        isReverbEnabled: true,
        reverbPreset: RoomReverbPreset.warmAuditorium,
        reverbRoomSize: 0.60,
        reverbDamping: 0.40,
        reverbWetGain: 0.25,
        reverbDryGain: 0.85,
        reverbWidth: 0.95,
      );

      final json = original.toJson();
      final restored = AudioEffectsConfig.fromJson(json);

      expect(restored.deHumMode, equals(DeHumMode.hz50EuropeAsia));
      expect(restored.deHumGain, equals(-36.0));
      expect(restored.deHumHarmonics, equals(4));
      expect(restored.isWindDePlosiveEnabled, isTrue);
      expect(restored.dePlosiveIntensity, equals(0.85));
      expect(restored.deEsserMode, equals(DeEsserMode.splitBandFemale));
      expect(restored.deEsserFrequency, equals(7500.0));
      expect(restored.isReverbEnabled, isTrue);
      expect(restored.reverbPreset, equals(RoomReverbPreset.warmAuditorium));
      expect(restored.reverbRoomSize, equals(0.60));
      expect(restored.reverbWetGain, equals(0.25));
    });

    test('AIVoiceEnhancerService generates cascading de-hum notch filters for 50Hz and harmonics', () {
      const config = AudioEffectsConfig(
        deHumMode: DeHumMode.hz50EuropeAsia,
        deHumHarmonics: 3,
        deHumGain: -30.0,
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter, contains('equalizer=f=50:width_type=q:width=14:g=-30.0'));
      expect(filter, contains('equalizer=f=100:width_type=q:width=14:g=-26.5'));
      expect(filter, contains('equalizer=f=150:width_type=q:width=14:g=-23.0'));
    });

    test('AIVoiceEnhancerService generates cascading de-hum notch filters for 60Hz and harmonics', () {
      const config = AudioEffectsConfig(
        deHumMode: DeHumMode.hz60NorthAmerica,
        deHumHarmonics: 2,
        deHumGain: -32.0,
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter, contains('equalizer=f=60:width_type=q:width=14:g=-32.0'));
      expect(filter, contains('equalizer=f=120:width_type=q:width=14:g=-28.5'));
    });

    test('AIVoiceEnhancerService generates wind and de-plosive sub-bass filter with dynamic compand', () {
      const config = AudioEffectsConfig(
        isWindDePlosiveEnabled: true,
        dePlosiveIntensity: 0.80,
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter, contains('highpass=f=75:p=2'));
      expect(filter, contains('compand=attacks=0.01:decays=0.08'));
    });

    test('AIVoiceEnhancerService generates frequency-targeted de-esser filter', () {
      const config = AudioEffectsConfig(
        deEsserMode: DeEsserMode.splitBandMale,
        deEsserIntensity: 0.75,
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter, contains('deesser=i=0.75:m=0.5:f=0.50:s=e'));
    });

    test('AIVoiceEnhancerService generates Freeverb room reverb filter with limiter safeguard', () {
      const config = AudioEffectsConfig(
        isReverbEnabled: true,
        reverbPreset: RoomReverbPreset.cinematicCathedral,
        reverbRoomSize: 0.85,
        reverbDamping: 0.30,
        reverbWetGain: 0.35,
        reverbDryGain: 0.75,
        reverbWidth: 1.0,
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter, contains('freeverb=roomsize=0.85:damping=0.30:wet=0.35:dry=0.75:width=1.00'));
      // AGENTS.md Rule 4: True-peak brickwall ceiling alimiter to eliminate digital clipping
      expect(filter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
    });

    test('AIVoiceEnhancerService formats descriptive HUD status badges', () {
      final reverbBadge = AIVoiceEnhancerService.getAudioBadge(
        const AudioEffectsConfig(
          isReverbEnabled: true,
          reverbPreset: RoomReverbPreset.cinematicCathedral,
        ),
      );
      expect(reverbBadge, contains('REVERB'));
      expect(reverbBadge, contains('CATHEDRAL'));

      final deHumBadge = AIVoiceEnhancerService.getAudioBadge(
        const AudioEffectsConfig(deHumMode: DeHumMode.hz50EuropeAsia),
      );
      expect(deHumBadge, equals('🧹 DE-HUM (50 Hz)'));

      final windBadge = AIVoiceEnhancerService.getAudioBadge(
        const AudioEffectsConfig(isWindDePlosiveEnabled: true),
      );
      expect(windBadge, contains('DE-PLOSIVE'));
    });

    test('FFmpegCommandBuilder integrates audio restoration and acoustic filters into export graph', () {
      final restoredClip = Clip(
        id: 'clip_restored_01',
        assetId: 'asset_01',
        trackId: 'track_v1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        audioEffects: const AudioEffectsConfig(
          deHumMode: DeHumMode.hz50EuropeAsia,
          isWindDePlosiveEnabled: true,
          isReverbEnabled: true,
          reverbPreset: RoomReverbPreset.intimateRoom,
          reverbRoomSize: 0.30,
          reverbDamping: 0.60,
          reverbWetGain: 0.15,
          reverbDryGain: 0.90,
        ),
      );

      final project = Project(
        id: 'proj_audio_test',
        name: 'Audio Restoration Project',
        tracks: [
          Track(
            id: 'track_v1',
            name: 'Video',
            type: TrackType.video,
            clips: [restoredClip],
          ),
        ],
      );

      const config = ExportConfiguration(
        outputPath: '/out/audio_render.mp4',
      );

      final cmd = FFmpegCommandBuilder.buildArguments(project, config);

      expect(cmd.any((arg) => arg.contains('equalizer=f=50')), isTrue);
      expect(cmd.any((arg) => arg.contains('highpass=f=75:p=2')), isTrue);
      expect(cmd.any((arg) => arg.contains('freeverb=roomsize=')), isTrue);
    });
  });
}
