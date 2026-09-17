import 'dart:math';
import '../models/audio_effects_config.dart';

class AIVoiceEnhancerService {
  /// Generates the FFmpeg audio filter chain for voice enhancement, parametric EQ, de-hum, de-esser, reverb & modulation
  static String generateFFmpegFilter(
    AudioEffectsConfig config, {
    double baseVolume = 1.0,
    int? clipDurationMs,
  }) {
    final filters = <String>[];

    // 1. Powerline Ground De-Hum Notch Filter Engine (50Hz / 60Hz + Harmonics)
    if (config.deHumMode != DeHumMode.off) {
      final double fundamental = config.deHumMode == DeHumMode.hz50EuropeAsia
          ? 50.0
          : (config.deHumMode == DeHumMode.hz60NorthAmerica ? 60.0 : config.customHumFreq.clamp(40.0, 120.0));
      final int harmonics = config.deHumHarmonics.clamp(1, 4);

      for (int h = 1; h <= harmonics; h++) {
        final notchFreq = (fundamental * h).round();
        // Harmonics attenuate slightly less aggressively than fundamental
        final notchGain = (config.deHumGain + (h - 1) * 3.5).clamp(-48.0, -10.0);
        filters.add('equalizer=f=$notchFreq:width_type=q:width=14:g=${notchGain.toStringAsFixed(1)}');
      }
    }

    // 2. Wind & Plosive Sub-Bass Guard (P-pop & low-frequency wind rumble suppression)
    if (config.isWindDePlosiveEnabled) {
      filters.add('highpass=f=75:p=2');
      final ratio = (config.dePlosiveIntensity * 2.0).clamp(1.0, 3.0);
      filters.add('compand=attacks=0.01:decays=0.08:points=-80/-80|-30/-22|0/-${ratio.toStringAsFixed(1)}');
    }

    // 3. Vocal Isolation & Noise Suppression Engine
    switch (config.vocalIsolationMode) {
      case VocalIsolationMode.isolateVocals:
        // Multi-band formant bandpass & aggressive neural noise gating
        filters.add('highpass=f=95');
        filters.add('equalizer=f=2800:width_type=q:width=1.2:g=4.5');
        filters.add('equalizer=f=1200:width_type=q:width=1.0:g=3.0');
        final nrDb = (config.vocalIsolationIntensity * 32.0).toStringAsFixed(1);
        filters.add('afftdn=nr=$nrDb:nf=-50');
        filters.add('compand=attacks=0.01:decays=0.1:points=-80/-80|-32/-16|0/-1');
        filters.add('lowpass=f=8500');
        break;

      case VocalIsolationMode.removeVocals:
        // Center channel cancellation: cancels mono center dialogue while retaining stereo instrumental ambience
        filters.add('stereotools=mlev=0.04:slev=1.35');
        break;

      case VocalIsolationMode.cleanSpeech:
      case VocalIsolationMode.none:
        if (config.isVoiceEnhancerEnabled || config.vocalIsolationMode == VocalIsolationMode.cleanSpeech) {
          filters.add('highpass=f=80');
          if (config.voiceClarityGain != 1.0) {
            final gainDb = (config.voiceClarityGain - 1.0) * 8.0;
            filters.add('equalizer=f=3200:width_type=o:width=1.5:g=${gainDb.toStringAsFixed(1)}');
          }
          final noiseReductionDb = (config.denoiseIntensity * 25.0).toStringAsFixed(1);
          filters.add('afftdn=nr=$noiseReductionDb:nf=-45');
          filters.add('lowpass=f=12000');
        }
        break;
    }

    // 4. Targeted Sibilance De-Esser (Frequency-tuned sibilance compression)
    if (config.deEsserMode != DeEsserMode.off || config.deEsserIntensity > 0.0) {
      if (config.deEsserMode == DeEsserMode.off) {
        final intensity = config.deEsserIntensity.clamp(0.1, 1.0);
        filters.add('deesser=i=${intensity.toStringAsFixed(2)}:m=0.5:f=0.5:s=o');
      } else {
        final double intensity = config.deEsserIntensity > 0.0 ? config.deEsserIntensity.clamp(0.1, 1.0) : 0.65;
        final double freq = config.deEsserMode != DeEsserMode.wideband
            ? config.deEsserMode.targetFrequency
            : config.deEsserFrequency.clamp(3000.0, 10000.0);
        final double freqNormalized = (freq / 10000.0).clamp(0.1, 1.0);
        filters.add('deesser=i=${intensity.toStringAsFixed(2)}:m=0.5:f=${freqNormalized.toStringAsFixed(2)}:s=e');
      }
    }

    // 5. Parametric Equalizer Suite (HPF + Low Shelf + Mid Bell + High Shelf + LPF)
    if (config.isEqualizerEnabled) {
      // High-Pass Filter (Low cut)
      if (config.highPassCutoff > 20.0) {
        filters.add('highpass=f=${config.highPassCutoff.toInt()}');
      }

      // Low Shelf / Bass Band
      if (config.eqLowGain.abs() > 0.05) {
        final gainStr = config.eqLowGain > 0 ? '+${config.eqLowGain.toStringAsFixed(1)}' : config.eqLowGain.toStringAsFixed(1);
        filters.add('equalizer=f=${config.eqLowFreq.toInt()}:width_type=q:width=0.7:g=$gainStr');
      }

      // Mid Bell / Presence Band
      if (config.eqMidGain.abs() > 0.05) {
        final gainStr = config.eqMidGain > 0 ? '+${config.eqMidGain.toStringAsFixed(1)}' : config.eqMidGain.toStringAsFixed(1);
        filters.add('equalizer=f=${config.eqMidFreq.toInt()}:width_type=q:width=${config.eqMidQ.toStringAsFixed(2)}:g=$gainStr');
      }

      // High Shelf / Air Band
      if (config.eqHighGain.abs() > 0.05) {
        final gainStr = config.eqHighGain > 0 ? '+${config.eqHighGain.toStringAsFixed(1)}' : config.eqHighGain.toStringAsFixed(1);
        filters.add('equalizer=f=${config.eqHighFreq.toInt()}:width_type=q:width=0.7:g=$gainStr');
      }

      // Low-Pass Filter (High cut)
      if (config.lowPassCutoff < 20000.0) {
        filters.add('lowpass=f=${config.lowPassCutoff.toInt()}');
      }
    } else {
      // Legacy Vocal EQ: Bass Resonance & Treble Air
      if (config.bassEnhance != 1.0) {
        final bassDb = (config.bassEnhance - 1.0) * 8.0;
        filters.add('equalizer=f=120:width_type=o:width=1.2:g=${bassDb.toStringAsFixed(1)}');
      }
      if (config.trebleCrisp != 1.0) {
        final trebleDb = (config.trebleCrisp - 1.0) * 8.0;
        filters.add('equalizer=f=5000:width_type=o:width=1.4:g=${trebleDb.toStringAsFixed(1)}');
      }
    }

    // 6. Studio Room Reverb & Acoustic Simulation (Freeverb)
    if (config.isReverbEnabled && config.reverbPreset != RoomReverbPreset.none) {
      final roomSize = config.reverbRoomSize.clamp(0.01, 1.0).toStringAsFixed(2);
      final damping = config.reverbDamping.clamp(0.0, 1.0).toStringAsFixed(2);
      final wet = config.reverbWetGain.clamp(0.01, 1.0).toStringAsFixed(2);
      final dry = config.reverbDryGain.clamp(0.0, 1.0).toStringAsFixed(2);
      final width = config.reverbWidth.clamp(0.0, 1.0).toStringAsFixed(2);
      filters.add('freeverb=roomsize=$roomSize:damping=$damping:wet=$wet:dry=$dry:width=$width');
      // Limiter safeguard against reverberant constructive interference clipping
      filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');
    }

    // 7. Voice Modulation Presets
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

    // 8. Loud & Clear Voice Booster (Gain Boost + Dynamic Compressor & True-Peak Limiter)
    if (config.isLoudVoiceEnabled) {
      final boost = config.voiceBoost.clamp(1.0, 3.0);
      filters.add('volume=${boost.toStringAsFixed(2)}');
      filters.add('compand=attacks=0.02:decays=0.15:points=-80/-80|-24/-12|0/-0.5');
      filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');
    }

    // 9. Volume Envelopes (Fade In & Fade Out)
    if (config.fadeInMs > 0) {
      final fadeInSec = (config.fadeInMs / 1000.0).toStringAsFixed(2);
      filters.add('afade=t=in:st=0:d=$fadeInSec');
    }
    if (config.fadeOutMs > 0 && clipDurationMs != null && clipDurationMs > config.fadeOutMs) {
      final fadeOutSec = (config.fadeOutMs / 1000.0).toStringAsFixed(2);
      final startFadeSec = ((clipDurationMs - config.fadeOutMs) / 1000.0).toStringAsFixed(2);
      filters.add('afade=t=out:st=$startFadeSec:d=$fadeOutSec');
    }

    // 10. Base Volume Multiplier
    if (baseVolume != 1.0) {
      filters.add('volume=${baseVolume.toStringAsFixed(2)}');
    }

    return filters.join(',');
  }

  /// Evaluates estimated speech clarity score (0% to 100%)
  static int calculateClarityScore(AudioEffectsConfig config) {
    int score = 50;
    if (config.vocalIsolationMode == VocalIsolationMode.isolateVocals) {
      score += (config.vocalIsolationIntensity * 40).round();
    } else if (config.vocalIsolationMode == VocalIsolationMode.cleanSpeech || config.isVoiceEnhancerEnabled) {
      score += (config.denoiseIntensity * 25).round();
      score += ((config.voiceClarityGain / 2.0) * 20).round();
    }
    if (config.deHumMode != DeHumMode.off) {
      score += 8;
    }
    if (config.isWindDePlosiveEnabled) {
      score += 6;
    }
    if (config.deEsserMode != DeEsserMode.off || config.deEsserIntensity > 0.0) {
      score += 6;
    }
    if (config.isEqualizerEnabled) {
      score += 5;
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

  /// Returns a concise HUD badge descriptor for real-time viewport display
  static String getAudioBadge(AudioEffectsConfig config) {
    if (config.isReverbEnabled && config.reverbPreset != RoomReverbPreset.none) {
      return '🏛️ REVERB (${config.reverbPreset.label.toUpperCase()})';
    }
    if (config.deHumMode != DeHumMode.off) {
      return '🧹 DE-HUM (${config.deHumMode.shortLabel})';
    }
    if (config.vocalIsolationMode == VocalIsolationMode.isolateVocals) {
      return '🎙️ VOCAL ISOLATE (${(config.vocalIsolationIntensity * 100).toInt()}%)';
    }
    if (config.vocalIsolationMode == VocalIsolationMode.removeVocals) {
      return '🎵 INSTRUMENTAL (VOCAL REMOVED)';
    }
    if (config.isEqualizerEnabled) {
      return '🎚️ EQ: ${config.equalizerPreset.label.toUpperCase()}';
    }
    if (config.isVoiceEnhancerEnabled || config.vocalIsolationMode == VocalIsolationMode.cleanSpeech) {
      return '✨ AI SPEECH CLEAN (${calculateClarityScore(config)}%)';
    }
    if (config.deEsserMode != DeEsserMode.off || config.deEsserIntensity > 0.0) {
      return '🎙️ DE-ESSER (${(config.deEsserFrequency / 1000).toStringAsFixed(1)}kHz)';
    }
    if (config.isWindDePlosiveEnabled) {
      return '🌬️ DE-PLOSIVE ACTIVE';
    }
    if (config.isLoudVoiceEnabled) {
      final db = ((config.voiceBoost - 1.0) * 10).toInt();
      return '🔥 LOUD BOOSTER (+${db}dB)';
    }
    if (config.modulationPreset != VoiceModulationPreset.natural) {
      return '🎙️ ${config.modulationPreset.label.toUpperCase()}';
    }
    if (config.isDuckingEnabled) {
      return '🦆 AUTO-DUCKING (${(config.duckingAttenuation * 100).toInt()}%)';
    }
    return '';
  }
}
