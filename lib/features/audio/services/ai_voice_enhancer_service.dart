import '../models/audio_effects_config.dart';

class AIVoiceEnhancerService {
  /// Generates the FFmpeg audio filter chain for the given audio effects configuration
  static String generateFFmpegFilter(AudioEffectsConfig config, {double baseVolume = 1.0}) {
    final filters = <String>[];

    // 1. Voice Enhancement / De-noising
    if (config.isVoiceEnhancerEnabled) {
      // High-pass filter (cuts low rumble below 80Hz)
      filters.add('highpass=f=80');

      // Adaptive speech equalizer (clarity boost around 2.5kHz - 4kHz)
      if (config.voiceClarityGain != 1.0) {
        final gainDb = (config.voiceClarityGain - 1.0) * 8.0; // 0.0 -> -8dB, 2.0 -> +8dB
        filters.add('equalizer=f=3200:width_type=o:width=1.5:g=${gainDb.toStringAsFixed(1)}');
      }

      // De-noise filter (FFmpeg afftdn or arnndn speech model)
      final noiseReductionDb = (config.denoiseIntensity * 25.0).toStringAsFixed(1);
      filters.add('afftdn=nr=$noiseReductionDb:nf=-45');

      // Low-pass filter (cuts high-pitch hiss above 12kHz)
      filters.add('lowpass=f=12000');
    }

    // 2. Fade In Envelope
    if (config.fadeInMs > 0) {
      final fadeInSec = (config.fadeInMs / 1000.0).toStringAsFixed(2);
      filters.add('afade=t=in:st=0:d=$fadeInSec');
    }

    // 3. Fade Out Envelope (handled dynamically in export pipeline with duration)
    // 4. Volume Multiplier
    if (baseVolume != 1.0) {
      filters.add('volume=${baseVolume.toStringAsFixed(2)}');
    }

    return filters.join(',');
  }

  /// Evaluates estimated speech clarity score (0% to 100%)
  static int calculateClarityScore(AudioEffectsConfig config) {
    if (!config.isVoiceEnhancerEnabled) return 45; // Raw audio baseline
    final intensityFactor = (config.denoiseIntensity * 30).round();
    final gainFactor = ((config.voiceClarityGain / 2.0) * 25).round();
    return (45 + intensityFactor + gainFactor).clamp(0, 99);
  }
}
