import '../models/tape_cassette_config.dart';

class TapeCassetteCompilerService {
  /// Compiles deterministic FFmpeg audio filters for analog tape cassette wow, flutter, and warmth
  /// STRICT COMPLIANCE: Every audio graph includes true-peak brickwall limiter (AGENTS.md Rule 4)
  static List<String> generateFFmpegFilters(TapeCassetteConfig config) {
    if (!config.isActive) return [];

    final filters = <String>[];

    // 1. Slow reel pitch drift (Wow ~0.3 - 2.0 Hz)
    if (config.wowDepth > 0.02) {
      final wowDepthCoeff = (config.wowDepth * 0.12).clamp(0.005, 0.35).toStringAsFixed(3);
      final wowRate = config.wowRateHz.clamp(0.2, 2.5).toStringAsFixed(2);
      filters.add('vibrato=f=$wowRate:d=$wowDepthCoeff');
    }

    // 2. Rapid capstan mechanical vibration (Flutter ~5.0 - 20.0 Hz)
    if (config.flutterDepth > 0.02) {
      final flutterDepthCoeff = (config.flutterDepth * 0.06).clamp(0.004, 0.20).toStringAsFixed(3);
      final flutterRate = config.flutterRateHz.clamp(5.0, 25.0).toStringAsFixed(1);
      filters.add('vibrato=f=$flutterRate:d=$flutterDepthCoeff');
    }

    // 3. Analog tape head low-end resonance bump
    if (config.tapeWarmth > 0.05) {
      final bassGain = (config.tapeWarmth * 3.5).clamp(0.5, 6.0).toStringAsFixed(1);
      filters.add('equalizer=f=85:width_type=o:width=1.5:g=$bassGain');

      // High-frequency magnetic tape head roll-off
      final cutoffHz = (14500 - config.tapeWarmth * 5500).round().clamp(6000, 18000);
      filters.add('lowpass=f=$cutoffHz');
    }

    // 4. True-peak brickwall ceiling limiter (AGENTS.md Rule 4 Safeguard)
    filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');

    return filters;
  }

  /// HUD status badge for active tape cassette
  static String getTapeBadge(TapeCassetteConfig config) {
    if (!config.isActive) return '';
    return '📼 TAPE (${config.era.label} • ${(config.wowDepth * 100).toInt()}% WOW)';
  }
}
