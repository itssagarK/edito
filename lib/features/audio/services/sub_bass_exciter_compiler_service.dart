import '../models/sub_bass_exciter_config.dart';

/// Compiler service for generating FFmpeg audio filters for Sub-Bass 808
/// saturation and psychoacoustic harmonic excitation.
///
/// Strictly enforces AGENTS.md Rule 4 true-peak brickwall ceiling limiter:
/// `alimiter=limit=0.95:attack=5:release=50:asc=1`
class SubBassExciterCompilerService {
  const SubBassExciterCompilerService();

  /// Static convenience method for FFmpeg command builder
  static String compileFilter(SubBassExciterConfig config) {
    return const SubBassExciterCompilerService().compile(config);
  }

  /// Compiles FFmpeg audio filter string for the given [SubBassExciterConfig].
  /// Returns empty string if disabled.
  String compile(SubBassExciterConfig config) {
    if (!config.isEnabled) return '';

    final freq = config.subFrequency.clamp(30.0, 120.0).toStringAsFixed(1);
    final boostDb = config.subBoostDb.clamp(0.0, 18.0).toStringAsFixed(1);
    final filters = <String>[];

    // 1. Fundamental sub-harmonic parametric boost
    filters.add('equalizer=f=$freq:width_type=h:width=35:g=$boostDb');

    // 2. Psychoacoustic harmonic overtone generation (2nd & 3rd harmonics)
    if (config.harmonicsMix > 0.15) {
      final h2Freq = (config.subFrequency * 2).clamp(60.0, 240.0).toStringAsFixed(1);
      final h2Boost = (config.subBoostDb * config.harmonicsMix * 0.65).clamp(0.0, 12.0).toStringAsFixed(1);
      filters.add('equalizer=f=$h2Freq:width_type=h:width=45:g=$h2Boost');

      // For phone speaker exciter mode, emphasize 3rd harmonic for mobile acoustic audibility
      if (config.mode == SubBassExciterMode.phoneSpeakerExciter) {
        final h3Freq = (config.subFrequency * 3).clamp(90.0, 360.0).toStringAsFixed(1);
        final h3Boost = (config.subBoostDb * config.harmonicsMix * 0.5).clamp(0.0, 9.0).toStringAsFixed(1);
        filters.add('equalizer=f=$h3Freq:width_type=h:width=50:g=$h3Boost');
      }
    }

    // 3. Analog drive and tube saturation
    if (config.driveSaturation > 0.15) {
      filters.add('asoftclip=type=atan:threshold=0.85');
    }

    // 4. Bass shelf warmth
    filters.add('bass=g=${(config.subBoostDb * 0.5).clamp(0.0, 8.0).toStringAsFixed(1)}:f=$freq');

    // 5. AGENTS.md Rule 4 MANDATORY true-peak brickwall ceiling limiter
    filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');

    return filters.join(',');
  }

  /// Returns user-facing badge label for the active mode.
  String getBadgeLabel(SubBassExciterConfig config) {
    if (!config.isEnabled) return '';
    return '🔊 ${config.mode.label.toUpperCase()}';
  }
}
