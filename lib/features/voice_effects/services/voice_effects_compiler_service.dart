import 'dart:math' as math;
import '../models/voice_effects_config.dart';

/// Compiler service for generating deterministic FFmpeg audio DSP filter chains
/// matching CapCut Pro's AI Voice Changer and Timbre Morphing studio.
class VoiceEffectsCompilerService {
  /// Generates deterministic FFmpeg audio filter strings for the given [VoiceEffectsConfig].
  ///
  /// Pitch shifting is achieved via synchronous sample-rate transposition (`asetrate`, `aresample`)
  /// combined with inverse tempo compensation (`atempo`), maintaining frame-accurate synchronization
  /// with the video track.
  ///
  /// In compliance with Rule 4 (Audio Limiter Safeguards), any audio modification terminates
  /// in a true-peak brickwall ceiling (`alimiter=limit=0.95:attack=5:release=50:asc=1`) to eliminate digital clipping.
  static List<String> generateFFmpegFilters(VoiceEffectsConfig config) {
    if (!config.isEnabled || config.character == VoiceEffectCharacter.none) {
      return const [];
    }

    final filters = <String>[];

    // 1. Pitch Transposition & Tempo Compensation
    if (config.pitchSemitones.abs() > 0.05) {
      final semitones = config.pitchSemitones.clamp(-12.0, 12.0);
      final pitchFactor = math.pow(2.0, semitones / 12.0).toDouble();
      final targetSampleRate = (44100.0 * pitchFactor).round().clamp(11025, 192000);
      
      filters.add('asetrate=$targetSampleRate:aresample=44100');

      // Compensate tempo so duration stays 100% synchronized with video
      final tempoCompensation = 1.0 / pitchFactor;
      if (tempoCompensation >= 0.5 && tempoCompensation <= 2.0) {
        filters.add('atempo=${tempoCompensation.toStringAsFixed(4)}');
      } else if (tempoCompensation < 0.5) {
        // atempo only supports 0.5 to 2.0 per instance; chain two filters
        final firstStage = 0.5;
        final secondStage = (tempoCompensation / 0.5).clamp(0.5, 2.0);
        filters.add('atempo=0.5,atempo=${secondStage.toStringAsFixed(4)}');
      } else {
        final firstStage = 2.0;
        final secondStage = (tempoCompensation / 2.0).clamp(0.5, 2.0);
        filters.add('atempo=2.0,atempo=${secondStage.toStringAsFixed(4)}');
      }
    }

    // 2. Highpass Filter (Low frequency rumble & mud cut)
    if (config.lowCutHz > 30.0) {
      filters.add('highpass=f=${config.lowCutHz.round()}');
    }

    // 3. Lowpass Filter (Treble rolloff / vintage telephony)
    if (config.highCutHz < 19000.0) {
      filters.add('lowpass=f=${config.highCutHz.round()}');
    }

    // 4. Timbre Formant Resonance (Vocal body equalizer peak)
    if (config.timbreResonance > 0.05) {
      final gainDb = (config.timbreResonance * 12.0).clamp(0.5, 12.0).toStringAsFixed(1);
      final centerFreq = config.character == VoiceEffectCharacter.deepMonster ? 350 : 2200;
      filters.add('equalizer=f=$centerFreq:t=q:w=2.0:g=$gainDb');
    }

    // 5. Vibrato & Pitch Modulation (Robot / Alien / Vinyl flutter)
    if (config.vibratoDepth > 0.05) {
      final depth = config.vibratoDepth.clamp(0.01, 1.0).toStringAsFixed(2);
      final rate = config.vibratoRate.clamp(0.5, 14.0).toStringAsFixed(1);
      filters.add('vibrato=f=$rate:d=$depth');
    }

    // 6. Distortion & Lo-Fi Bitcrush (Megaphone / Retro Radio)
    if (config.distortion > 0.05) {
      final bits = (16.0 - (config.distortion * 8.0)).round().clamp(6, 15);
      filters.add('acrusher=bits=$bits:mode=log:aa=1');
    }

    // 7. Cavernous Echo / Spatial Reverb
    if (config.echoDelayMs >= 20 && config.echoFeedback > 0.05) {
      final delayMs = config.echoDelayMs.clamp(20, 1000);
      final feedback = config.echoFeedback.clamp(0.05, 0.85).toStringAsFixed(2);
      filters.add('aecho=0.8:0.88:$delayMs:$feedback');
    }

    // 8. Rule 4 Compliance: True-Peak Brickwall Limiter
    // Prevents digital clipping from resonance, pitch shifting, or echo accumulation
    filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');

    return filters;
  }

  /// Compact HUD badge label for the preview viewport
  static String getBadgeLabel(VoiceEffectsConfig config) {
    if (!config.isEnabled || config.character == VoiceEffectCharacter.none) {
      return '';
    }
    if (config.character == VoiceEffectCharacter.custom) {
      final pitchStr = config.pitchSemitones >= 0
          ? '+${config.pitchSemitones.toStringAsFixed(1)}st'
          : '${config.pitchSemitones.toStringAsFixed(1)}st';
      return 'VOICE: $pitchStr';
    }
    return 'VOICE: ${config.character.label.toUpperCase()}';
  }
}
