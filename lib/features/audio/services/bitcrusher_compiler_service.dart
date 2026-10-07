import '../models/bitcrusher_config.dart';

/// Compiles 8-bit chiptune bitcrushing and lo-fi audio DSP parameters into deterministic FFmpeg audio filter expressions.
class BitcrusherCompilerService {
  /// Compiles the complete FFmpeg audio filter chain for bitcrushing and decimation.
  /// Strictly includes true-peak brickwall ceiling limiter per AGENTS.md Rule 4.
  static String compileFilter(BitcrusherConfig config) {
    if (!config.isActive) return '';

    final filters = <String>[];

    // 1. Pre-gain drive overdrive
    if (config.drive > 0.05) {
      final driveGain = (1.0 + config.drive * 1.5).toStringAsFixed(2);
      filters.add('volume=$driveGain');
    }

    // 2. Frequency band shaping
    if (config.mode == BitcrusherMode.walkieTalkieRadio) {
      filters.add('highpass=f=450,lowpass=f=3400');
    } else {
      final nyquistCutoff = (config.sampleRateKhz * 480).clamp(1200, 18000).round();
      filters.add('lowpass=f=$nyquistCutoff');
    }

    // 3. Bit-depth quantization & decimation via acrusher
    final bits = config.bitDepth.clamp(2, 12);
    filters.add('acrusher=level_in=1:level_out=1:bits=$bits:mode=lin:aa=0.5');

    // 4. AGENTS.md Rule 4: Strict brickwall true-peak ceiling limiter
    filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');

    return filters.join(',');
  }

  /// Returns user-facing HUD badge text for the editor viewport.
  static String getBitcrusherBadge(BitcrusherConfig config) {
    if (!config.isActive) return '';
    return '👾 8-BIT: ${config.mode.displayName.toUpperCase()} (${config.sampleRateKhz.toStringAsFixed(1)}kHz / ${config.bitDepth}-BIT)';
  }
}
