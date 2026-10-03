import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/audio/models/audio_effects_config.dart';
import 'package:edito/features/audio/services/ai_voice_enhancer_service.dart';

void main() {
  group('Neural Noise Removal (RNNoise BSD-3) Config Tests', () {
    test('Default AudioEffectsConfig enables neural denoiser with safe defaults', () {
      const config = AudioEffectsConfig();
      expect(config.isNeuralDenoiseEnabled, isTrue);
      expect(config.neuralDenoiseStrength, 0.75);
      expect(config.isNoiseComparisonBypass, isFalse);
      expect(config.isVoiceEnhancerEnabled, isFalse);
    });

    test('copyWith properly updates neural noise parameters and bypass mode', () {
      const config = AudioEffectsConfig();
      final updated = config.copyWith(
        isNeuralDenoiseEnabled: true,
        neuralDenoiseStrength: 0.90,
        isNoiseComparisonBypass: true,
      );

      expect(updated.isNeuralDenoiseEnabled, isTrue);
      expect(updated.neuralDenoiseStrength, 0.90);
      expect(updated.isNoiseComparisonBypass, isTrue);
    });

    test('Backward compatibility: legacy JSON without neural fields loads safely', () {
      final legacyJson = <String, dynamic>{
        'denoiseIntensity': 0.5,
        'voiceClarityGain': 1.2,
        'vocalIsolationMode': 'cleanSpeech',
        'isVoiceEnhancerEnabled': true,
      };

      final parsed = AudioEffectsConfig.fromJson(legacyJson);
      expect(parsed.isNeuralDenoiseEnabled, isTrue);
      expect(parsed.neuralDenoiseStrength, 0.75);
      expect(parsed.isNoiseComparisonBypass, isFalse);
      expect(parsed.denoiseIntensity, 0.5);
      expect(parsed.voiceClarityGain, 1.2);
    });

    test('Full JSON round-trip serialization preserves neural noise settings', () {
      const original = AudioEffectsConfig(
        isNeuralDenoiseEnabled: true,
        neuralDenoiseStrength: 0.85,
        isNoiseComparisonBypass: false,
        isVoiceEnhancerEnabled: true,
      );

      final json = original.toJson();
      final deserialized = AudioEffectsConfig.fromJson(json);

      expect(deserialized.isNeuralDenoiseEnabled, isTrue);
      expect(deserialized.neuralDenoiseStrength, 0.85);
      expect(deserialized.isNoiseComparisonBypass, isFalse);
      expect(deserialized.isVoiceEnhancerEnabled, isTrue);
    });
  });

  group('AIVoiceEnhancerService FFmpeg Filter Generation Tests', () {
    test('Generates neural denoiser filter with brickwall limiter', () {
      const config = AudioEffectsConfig(
        isVoiceEnhancerEnabled: true,
        isNeuralDenoiseEnabled: true,
        neuralDenoiseStrength: 0.75, // 0.75 * 30 = 22.5 dB
        voiceClarityGain: 1.0,
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter, contains('highpass=f=80'));
      expect(filter, contains('afftdn=nr=22.5:nf=-45:tn=1'));
      expect(filter, contains('lowpass=f=12000'));
      expect(filter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
    });

    test('Bypasses filters during A/B comparison mode for instant comparison', () {
      const config = AudioEffectsConfig(
        isVoiceEnhancerEnabled: true,
        isNeuralDenoiseEnabled: true,
        neuralDenoiseStrength: 0.75,
        isNoiseComparisonBypass: true, // User holding A/B comparison button
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter.isEmpty, isTrue);
    });

    test('Falls back to standard FFT denoiser when neural denoiser is disabled', () {
      const config = AudioEffectsConfig(
        isVoiceEnhancerEnabled: true,
        isNeuralDenoiseEnabled: false,
        denoiseIntensity: 0.60, // 0.60 * 25 = 15.0 dB
        voiceClarityGain: 1.0,
      );

      final filter = AIVoiceEnhancerService.generateFFmpegFilter(config);
      expect(filter, contains('afftdn=nr=15.0:nf=-45'));
      expect(filter, isNot(contains(':tn=1')));
      expect(filter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
    });
  });
}
