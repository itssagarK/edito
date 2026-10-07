import '../models/vinyl_record_config.dart';

class VinylRecordCompilerService {
  /// Compiles FFmpeg audio filters for vinyl record warm phono EQ,
  /// mechanical groove rumble, high-frequency dust attenuation,
  /// and strict true-peak brickwall ceiling per AGENTS.md Rule 4.
  static List<String> compileFilters(VinylRecordConfig config) {
    if (!config.isEnabled) return [];

    final filters = <String>[];

    // 1. Subsonic turntable motor rumble cutoff
    final rumbleHp = config.rpm == VinylRpm.rpm78 ? 120 : 35;
    filters.add('highpass=f=$rumbleHp:p=1');

    // 2. Phono Preamp RIAA Curve Warmth
    final bassGain = (1.5 + config.needleWearTone * 3.5).toStringAsFixed(1);
    filters.add('equalizer=f=110:width_type=h:width=90:g=$bassGain');

    // 3. Vintage High-Frequency Roll-Off
    double cutoffHz;
    switch (config.rpm) {
      case VinylRpm.rpm78:
        cutoffHz = 5500.0 - (config.needleWearTone * 1500.0);
        break;
      case VinylRpm.rpm45:
        cutoffHz = 14500.0 - (config.needleWearTone * 4000.0);
        break;
      case VinylRpm.rpm33:
        cutoffHz = 13000.0 - (config.needleWearTone * 4500.0);
        break;
    }
    filters.add('lowpass=f=${cutoffHz.round()}:p=1');

    // 4. Subtle Turntable Wow (Mechanical Eccentricity Drift)
    // 33.3 RPM corresponds to 0.555 Hz, 45 RPM to 0.75 Hz
    final wowRate = (config.rpm.rotationSpeed).toStringAsFixed(2);
    filters.add('vibrato=f=$wowRate:d=0.03');

    // 5. CRITICAL: True-Peak Brickwall Ceiling per AGENTS.md Rule 4
    filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');

    return filters;
  }

  /// Alias for export pipeline
  static List<String> generateFFmpegFilters(VinylRecordConfig config) => compileFilters(config);

  /// Formats human-readable status badge for HUD
  static String getHudBadge(VinylRecordConfig config) {
    if (!config.isEnabled) return 'Vinyl OFF';
    final dustPct = (config.dustCrackle * 100).round();
    final rpmLabel = config.rpm == VinylRpm.rpm33
        ? '33⅓ RPM'
        : config.rpm == VinylRpm.rpm45
            ? '45 RPM'
            : '78 RPM';
    return '$rpmLabel (Dust $dustPct%)';
  }
}
