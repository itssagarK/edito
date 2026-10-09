import 'dart:math' as math;
import '../models/multiband_compressor_config.dart';

/// Compiler service for generating FFmpeg audio filtergraphs for 3-band studio
/// audio master compression.
///
/// Strictly enforces AGENTS.md Rule 4 true-peak brickwall ceiling limiter:
/// `alimiter=limit=0.95:attack=5:release=50:asc=1`
class MultibandCompressorCompilerService {
  const MultibandCompressorCompilerService();

  /// Static convenience method for FFmpeg command builder
  static String compileFilter(MultibandCompressorConfig config) {
    return const MultibandCompressorCompilerService().compile(config);
  }

  /// Compiles FFmpeg audio filter string for the given [MultibandCompressorConfig].
  /// Returns empty string if disabled.
  String compile(MultibandCompressorConfig config) {
    if (!config.isEnabled || !config.isActive) return '';

    final filters = <String>[];

    // 1. Low Band Contouring (< crossoverLowHz)
    final lowGain = config.lowGainDb.toStringAsFixed(1);
    final xLow = config.crossoverLowHz.round();
    filters.add('bass=g=$lowGain:f=$xLow');

    // 2. Mid Band Parametric Contouring (crossoverLowHz to crossoverHighHz)
    final midCenter = math.sqrt(config.crossoverLowHz * config.crossoverHighHz).round();
    final midGain = config.midGainDb.toStringAsFixed(1);
    filters.add('equalizer=f=$midCenter:width_type=o:w=1.8:g=$midGain');

    // 3. High Band Air Shelf (> crossoverHighHz)
    final highGain = config.highGainDb.toStringAsFixed(1);
    final xHigh = config.crossoverHighHz.round();
    filters.add('treble=g=$highGain:f=$xHigh');

    // 4. Multi-Band Dynamic RMS Master Compression
    final effThresh = ((config.lowThresholdDb + config.midThresholdDb * 1.5 + config.highThresholdDb) / 3.5)
        .clamp(-40.0, 0.0)
        .toStringAsFixed(1);
    final effRatio = ((config.lowRatio + config.midRatio * 1.2 + config.highRatio) / 3.2)
        .clamp(1.0, 20.0)
        .toStringAsFixed(1);
    final attack = config.attackMs.clamp(1.0, 100.0).toStringAsFixed(1);
    final release = config.releaseMs.clamp(20.0, 1000.0).toStringAsFixed(1);
    final makeup = config.masterGainDb.toStringAsFixed(1);

    filters.add(
      'acompressor=threshold=${effThresh}dB:ratio=${effRatio}:attack=$attack:release=$release:makeup=${makeup}dB:knee=2.8:detection=rms',
    );

    // 5. AGENTS.md Rule 4 MANDATORY true-peak brickwall ceiling limiter
    filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');

    return filters.join(',');
  }

  /// Returns user-facing badge label for the active mode.
  String getCompressorBadge(MultibandCompressorConfig config) {
    if (!config.isEnabled) return '';
    return '🎛️ MULTIBAND: ${config.mode.label.toUpperCase()} (${config.masterGainDb >= 0 ? '+' : ''}${config.masterGainDb.toStringAsFixed(1)} dB)';
  }
}
