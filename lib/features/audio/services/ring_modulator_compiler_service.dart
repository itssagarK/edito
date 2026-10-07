import '../models/ring_modulator_config.dart';

/// Compiles metallic ring modulation, carrier oscillation, and robotic vocoder DSP
/// into deterministic, studio-grade FFmpeg audio filter chains.
class RingModulatorCompilerService {
  /// Compiles the complete FFmpeg audio filter string for ring modulation.
  /// Strictly includes true-peak brickwall ceiling limiter per AGENTS.md Rule 4.
  static String compileFilter(RingModulatorConfig config) {
    if (!config.isActive) return '';

    final filters = <String>[];
    final f = config.carrierFreqHz.clamp(5.0, 2000.0).toStringAsFixed(1);
    final d = config.depth.clamp(0.05, 1.0).toStringAsFixed(2);

    switch (config.mode) {
      case RingModulatorMode.dalekRobotic:
        // 30Hz sinusoidal amplitude modulation
        filters.add('tremolo=f=$f:d=$d');
        if (config.harmonicMix > 0.05) {
          final f2 = (config.carrierFreqHz * 2.0).clamp(10.0, 4000.0).toStringAsFixed(1);
          final d2 = (config.harmonicMix * 0.4).clamp(0.02, 0.40).toStringAsFixed(2);
          filters.add('tremolo=f=$f2:d=$d2');
        }
        break;

      case RingModulatorMode.alienVocoder:
        // High frequency carrier + resonance bandpass
        filters.add('equalizer=f=$f:t=q:w=2.0:g=6');
        filters.add('tremolo=f=$f:d=$d');
        break;

      case RingModulatorMode.subHarmonicTremor:
        // Ultra-low frequency pulse
        filters.add('tremolo=f=$f:d=$d');
        break;

      case RingModulatorMode.cyberBellBells:
        // Inharmonic bell modulation
        filters.add('tremolo=f=$f:d=$d');
        if (config.harmonicMix > 0.05) {
          final f3 = (config.carrierFreqHz * 1.414).clamp(10.0, 4000.0).toStringAsFixed(1); // Tritone carrier
          final d3 = (config.harmonicMix * 0.5).clamp(0.02, 0.50).toStringAsFixed(2);
          filters.add('tremolo=f=$f3:d=$d3');
        }
        break;

      case RingModulatorMode.dualCarrierScifi:
        // Dual carrier wave
        filters.add('tremolo=f=$f:d=$d');
        final fDual = (config.carrierFreqHz * 1.5).clamp(10.0, 4000.0).toStringAsFixed(1);
        final dDual = (config.depth * 0.6).clamp(0.05, 0.60).toStringAsFixed(2);
        filters.add('tremolo=f=$fDual:d=$dDual');
        break;
    }

    // Wet/dry balance attenuation
    if (config.mix < 0.99) {
      final vol = (0.65 + config.mix * 0.35).toStringAsFixed(2);
      filters.add('volume=$vol');
    }

    // AGENTS.md Rule 4: Mandatory true-peak brickwall ceiling limiter
    filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');

    return filters.join(',');
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getRingModulatorBadge(RingModulatorConfig config) {
    if (!config.isActive) return '';
    return '🔔 RING MOD: ${config.mode.displayName.toUpperCase()} (${config.carrierFreqHz.toStringAsFixed(0)} Hz)';
  }
}
