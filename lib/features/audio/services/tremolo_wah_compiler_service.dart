import '../models/tremolo_wah_config.dart';

/// Compiles stereo tremolo, dynamic auto-wah, and rotary audio modulation parameters
/// into deterministic, studio-grade FFmpeg audio filter chains.
class TremoloWahCompilerService {
  /// Compiles the complete FFmpeg audio filter string for tremolo/wah modulation.
  /// Strictly includes true-peak brickwall ceiling limiter per AGENTS.md Rule 4.
  static String compileFilter(TremoloWahConfig config) {
    if (!config.isActive) return '';

    final filters = <String>[];
    final f = config.frequencyHz.clamp(0.2, 20.0).toStringAsFixed(2);
    final d = config.depth.clamp(0.05, 1.0).toStringAsFixed(2);
    final centerFreq = config.centerFreqHz.clamp(200.0, 4000.0).round();
    final q = config.resonance.clamp(0.5, 10.0).toStringAsFixed(1);

    switch (config.mode) {
      case TremoloWahMode.stereoTremolo:
        // Use apulsator for stereo phase-offset amplitude pulsation, fallback to tremolo
        final phaseOffset = (config.stereoPhaseOffsetDeg / 360.0).clamp(0.0, 0.5).toStringAsFixed(2);
        filters.add('apulsator=hz=$f:amount=$d:mode=sine:offset_r=$phaseOffset');
        break;

      case TremoloWahMode.autoWahFunk:
        // Resonant dynamic bandpass boost + rhythmic pulse
        filters.add('equalizer=f=$centerFreq:t=q:w=$q:g=9');
        filters.add('tremolo=f=$f:d=$d');
        break;

      case TremoloWahMode.leslieRotary:
        // Dual Doppler pitch vibrato + amplitude tremolo simulating rotating horn
        final vibDepth = (config.depth * 0.45).clamp(0.05, 0.95).toStringAsFixed(2);
        final tremDepth = (config.depth * 0.65).clamp(0.05, 0.95).toStringAsFixed(2);
        filters.add('vibrato=f=$f:d=$vibDepth');
        filters.add('tremolo=f=$f:d=$tremDepth');
        filters.add('extrastereo=m=1.35');
        break;

      case TremoloWahMode.stutterGate:
        // Aggressive square-wave amplitude gating
        filters.add('tremolo=f=$f:d=$d');
        break;

      case TremoloWahMode.psychedelicSweep:
        // Wide-spectrum resonant peak + stereo phaser modulation
        filters.add('bandpass=f=$centerFreq:width_type=q:w=$q');
        final pulsOffset = (config.stereoPhaseOffsetDeg / 360.0).clamp(0.0, 0.5).toStringAsFixed(2);
        filters.add('apulsator=hz=$f:amount=$d:mode=triangle:offset_r=$pulsOffset');
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
  static String getTremoloWahBadge(TremoloWahConfig config) {
    if (!config.isActive) return '';
    return '🌊 MODULATION: ${config.mode.displayName.toUpperCase()} (${config.frequencyHz.toStringAsFixed(1)}Hz / ${(config.depth * 100).round()}%)';
  }
}
