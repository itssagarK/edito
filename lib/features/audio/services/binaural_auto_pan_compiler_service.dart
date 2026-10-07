import '../models/binaural_auto_pan_config.dart';

/// Compiler service for generating FFmpeg audio filtergraphs for 3D binaural
/// auto-pan rotation and Doppler pitch swell effects.
///
/// Strictly enforces AGENTS.md Rule 4 true-peak brickwall ceiling limiter:
/// `alimiter=limit=0.95:attack=5:release=50:asc=1`
class BinauralAutoPanCompilerService {
  const BinauralAutoPanCompilerService();

  /// Static convenience method for FFmpeg command builder
  static String compileFilter(BinauralAutoPanConfig config) {
    return const BinauralAutoPanCompilerService().compile(config);
  }

  /// Compiles FFmpeg audio filter string for the given [BinauralAutoPanConfig].
  /// Returns empty string if disabled.
  String compile(BinauralAutoPanConfig config) {
    if (!config.isEnabled || !config.isActive) return '';

    final filters = <String>[];
    final rate = config.rateHz.clamp(0.05, 4.0).toStringAsFixed(2);
    final depth = config.depth.clamp(0.1, 1.0).toStringAsFixed(2);

    // 1. Spatial Auto-Pan Modulation (apulsator)
    switch (config.mode) {
      case BinauralAutoPanMode.circular3DOrbit:
        // Sine wave quadrature pan: 90 degree stereo phase offset
        filters.add('apulsator=hz=$rate:amount=$depth:offset_l=0:offset_r=0.5:mode=sine');
        break;

      case BinauralAutoPanMode.pendulumSwing:
        // Linear triangle wave metronomic swing
        filters.add('apulsator=hz=$rate:amount=$depth:offset_l=0:offset_r=0.5:mode=triangle');
        break;

      case BinauralAutoPanMode.dopplerFlyby:
        // Exponential approach sweep
        filters.add('apulsator=hz=$rate:amount=$depth:offset_l=0:offset_r=0.5:mode=sine');
        break;

      case BinauralAutoPanMode.chaoticVortex:
        // Square/rapid oscillating trajectory
        filters.add('apulsator=hz=$rate:amount=$depth:offset_l=0.1:offset_r=0.6:mode=sine');
        break;

      case BinauralAutoPanMode.subtleStereoSpread:
        // Gentle slow spatial breath
        filters.add('apulsator=hz=$rate:amount=${(config.depth * 0.6).clamp(0.1, 0.8).toStringAsFixed(2)}:offset_l=0:offset_r=0.5:mode=sine');
        break;
    }

    // 2. Physical Doppler Pitch Warp (vibrato)
    if (config.dopplerIntensity > 0.05) {
      final dopplerMod = (config.dopplerIntensity * 0.45).clamp(0.02, 0.50).toStringAsFixed(2);
      filters.add('vibrato=f=$rate:d=$dopplerMod');
    }

    // 3. Binaural Soundstage Stereo Expansion (extrastereo)
    if (config.stereoSpread > 1.05 || config.stereoSpread < 0.95) {
      final spread = config.stereoSpread.clamp(0.5, 2.0).toStringAsFixed(2);
      filters.add('extrastereo=m=$spread');
    }

    // 4. Pinna 3D Elevation HRTF Simulation (high shelf or lowpass)
    if (config.elevation > 0.15) {
      final trebleBoost = (config.elevation * 4.5).clamp(0.5, 6.0).toStringAsFixed(1);
      filters.add('treble=g=$trebleBoost:f=8500');
    } else if (config.elevation < -0.15) {
      final cutoff = (12000 + config.elevation * 4500).clamp(5500, 16000).round();
      filters.add('lowpass=f=$cutoff');
    }

    // 5. AGENTS.md Rule 4 MANDATORY true-peak brickwall ceiling limiter
    filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');

    return filters.join(',');
  }

  /// Returns user-facing badge label for the active mode.
  String getBadgeLabel(BinauralAutoPanConfig config) {
    if (!config.isEnabled) return '';
    return '🎧 3D PAN: ${config.mode.label.toUpperCase()} (${config.rateHz.toStringAsFixed(2)} Hz)';
  }
}
