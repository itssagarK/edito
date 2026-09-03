import 'dart:math';
import '../models/audio_effects_config.dart';

class AIVoiceEnhancerService {
  /// Generates the FFmpeg audio filter chain for voice enhancement, loudness boost & modulation
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

      // De-noise filter (FFmpeg afftdn speech model)
      final noiseReductionDb = (config.denoiseIntensity * 25.0).toStringAsFixed(1);
      filters.add('afftdn=nr=$noiseReductionDb:nf=-45');

      // Low-pass filter (cuts high-pitch hiss above 12kHz)
      filters.add('lowpass=f=12000');
    }

    // 2. Custom Vocal EQ: Bass Resonance & Treble Air
    if (config.bassEnhance != 1.0) {
      final bassDb = (config.bassEnhance - 1.0) * 8.0;
      filters.add('equalizer=f=120:width_type=o:width=1.2:g=${bassDb.toStringAsFixed(1)}');
    }
    if (config.trebleCrisp != 1.0) {
      final trebleDb = (config.trebleCrisp - 1.0) * 8.0;
      filters.add('equalizer=f=5000:width_type=o:width=1.4:g=${trebleDb.toStringAsFixed(1)}');
    }

    // 3. Voice Modulation Presets
    switch (config.modulationPreset) {
      case VoiceModulationPreset.studioBroadcast:
        filters.add('equalizer=f=120:width_type=o:width=1.2:g=3.5');
        filters.add('equalizer=f=3500:width_type=o:width=1.5:g=4.5');
        filters.add('compand=attacks=0.01:decays=0.1:points=-80/-80|-22/-10|0/-0.5');
        break;

      case VoiceModulationPreset.deepNarrator:
        const factor = 0.88;
        filters.add('asetrate=44100*$factor,atempo=${(1.0 / factor).toStringAsFixed(3)}');
        filters.add('equalizer=f=100:width_type=o:width=1.2:g=6.0');
        break;

      case VoiceModulationPreset.crystalClear:
        filters.add('highpass=f=120');
        filters.add('equalizer=f=4500:width_type=o:width=1.5:g=6.5');
        break;

      case VoiceModulationPreset.radioWalkie:
        filters.add('highpass=f=420,lowpass=f=3300');
        filters.add('volume=1.35');
        break;

      case VoiceModulationPreset.sciFiRobot:
        filters.add('flanger=delay=8:depth=4:regen=60:width=85:speed=0.6');
        break;

      case VoiceModulationPreset.customPitch:
        if (config.pitchShiftSemitones != 0.0) {
          final pitchRatio = pow(2.0, config.pitchShiftSemitones / 12.0).toDouble();
          final clampedRatio = pitchRatio.clamp(0.5, 2.0);
          filters.add('asetrate=44100*${clampedRatio.toStringAsFixed(3)},atempo=${(1.0 / clampedRatio).toStringAsFixed(3)}');
        }
        break;

      case VoiceModulationPreset.natural:
        break;
    }

    // 4. Loud & Clear Voice Booster (Gain Boost + Dynamic Limiter)
    if (config.isLoudVoiceEnabled) {
      final boost = config.voiceBoost.clamp(1.0, 3.0);
      filters.add('volume=${boost.toStringAsFixed(2)}');
      filters.add('compand=attacks=0.02:decays=0.15:points=-80/-80|-24/-12|0/-0.5');
    }

    // 5. Fade In Envelope
    if (config.fadeInMs > 0) {
      final fadeInSec = (config.fadeInMs / 1000.0).toStringAsFixed(2);
      filters.add('afade=t=in:st=0:d=$fadeInSec');
    }

    // 6. Base Volume Multiplier
    if (baseVolume != 1.0) {
      filters.add('volume=${baseVolume.toStringAsFixed(2)}');
    }

    return filters.join(',');
  }

  /// Evaluates estimated speech clarity score (0% to 100%)
  static int calculateClarityScore(AudioEffectsConfig config) {
    int score = 50;
    if (config.isVoiceEnhancerEnabled) {
      score += (config.denoiseIntensity * 25).round();
      score += ((config.voiceClarityGain / 2.0) * 20).round();
    }
    if (config.isLoudVoiceEnabled) {
      score += 5;
    }
    if (config.modulationPreset == VoiceModulationPreset.studioBroadcast ||
        config.modulationPreset == VoiceModulationPreset.crystalClear) {
      score += 10;
    }
    return score.clamp(0, 99);
  }
}
