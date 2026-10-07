import 'dart:math' as math;
import '../models/pitch_harmonizer_config.dart';

/// Compiles vocal pitch transposition, interval harmony stacking, and robot modulation
/// into deterministic, studio-grade FFmpeg audio filter chains.
class PitchHarmonizerCompilerService {
  /// Compiles the complete FFmpeg audio filter for pitch shifting and harmonizing.
  /// Strictly includes true-peak brickwall ceiling limiter per AGENTS.md Rule 4.
  static String compileFilter(PitchHarmonizerConfig config) {
    if (!config.isActive) return '';

    final filters = <String>[];
    final totalShift = config.semitones + (config.cents / 100.0);
    final ratio = math.pow(2.0, totalShift / 12.0).toDouble();
    final sampleRate = (48000 * ratio).round().clamp(12000, 96000);
    final tempoComp = (1.0 / ratio).clamp(0.5, 2.0).toStringAsFixed(4);

    switch (config.mode) {
      case PitchHarmonizerMode.naturalSemitone:
      case PitchHarmonizerMode.chipmunkHelium:
      case PitchHarmonizerMode.deepMonsterSub:
        // Precise pitch shift without tempo alteration
        filters.add('asetrate=$sampleRate,atempo=$tempoComp');
        if (config.mode == PitchHarmonizerMode.deepMonsterSub) {
          filters.add('bass=g=6:f=120');
        } else if (config.mode == PitchHarmonizerMode.chipmunkHelium) {
          filters.add('treble=g=5:f=3500');
        }
        break;

      case PitchHarmonizerMode.octaveDoubler:
      case PitchHarmonizerMode.vocalHarmonizer:
        // Multi-voice harmony stack
        final harmShift = config.harmonyInterval.semitoneOffset;
        final harmRatio = math.pow(2.0, harmShift / 12.0).toDouble();
        final harmRate = (48000 * harmRatio).round().clamp(12000, 96000);
        final harmTempo = (1.0 / harmRatio).clamp(0.5, 2.0).toStringAsFixed(4);
        final harmVol = config.harmonyMix.clamp(0.1, 1.0).toStringAsFixed(2);

        filters.add(
          'split[ph_lead][ph_harm];'
          '[ph_harm]asetrate=$harmRate,atempo=$harmTempo,volume=$harmVol[harm_v];'
          '[ph_lead][harm_v]amix=inputs=2:dropout_transition=0',
        );
        break;

      case PitchHarmonizerMode.roboticRingMod:
        // Pitch shift + robotic metallic flanger ring mod
        filters.add('asetrate=$sampleRate,atempo=$tempoComp');
        filters.add('flanger=delay=2:depth=5:regen=70:speed=0.5:phase=90');
        break;
    }

    // Apply wet/dry mix attenuation if needed
    if (config.mix < 0.99) {
      final vol = (0.7 + config.mix * 0.3).toStringAsFixed(2);
      filters.add('volume=$vol');
    }

    // AGENTS.md Rule 4: Mandatory true-peak brickwall ceiling limiter
    filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');

    return filters.join(',');
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getPitchHarmonizerBadge(PitchHarmonizerConfig config) {
    if (!config.isActive) return '';
    final sign = config.semitones >= 0 ? '+' : '';
    return '🎵 HARMONIZER: ${config.mode.displayName.toUpperCase()} ($sign${config.semitones} ST / ${config.harmonyInterval.displayName.split(' ').first})';
  }
}
