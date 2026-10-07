import 'dart:math' as math;
import '../models/reverb_chamber_config.dart';

class ReverbCompilerService {
  /// Compiles deterministic FFmpeg audio filters for studio reverb chamber and acoustic depth
  /// STRICT COMPLIANCE: Every audio graph includes true-peak brickwall limiter (AGENTS.md Rule 4)
  static List<String> generateFFmpegFilters(ReverbChamberConfig config) {
    if (!config.isActive) return [];

    final filters = <String>[];

    // 1. Calculate multi-tap delay times and exponential decay coefficients
    final baseDelayMs = config.preDelayMs.clamp(5.0, 100.0);
    final decayScale = config.decayTimeMs.clamp(100, 5000);

    // Multi-tap early reflection delays in milliseconds
    final d1 = (baseDelayMs + decayScale * 0.04).round().clamp(10, 1000);
    final d2 = (baseDelayMs + decayScale * 0.09).round().clamp(20, 1500);
    final d3 = (baseDelayMs + decayScale * 0.18).round().clamp(30, 2000);
    final d4 = (baseDelayMs + decayScale * 0.30).round().clamp(40, 2500);

    // Reflection decay amplitudes (scaled by wet/dry mix)
    final wet = config.wetDryMix.clamp(0.05, 0.95);
    final c1 = (wet * 0.70).clamp(0.01, 0.85).toStringAsFixed(2);
    final c2 = (wet * 0.50).clamp(0.01, 0.75).toStringAsFixed(2);
    final c3 = (wet * 0.35).clamp(0.01, 0.60).toStringAsFixed(2);
    final c4 = (wet * 0.20).clamp(0.01, 0.50).toStringAsFixed(2);

    final outGain = (1.0 - (wet * 0.25)).clamp(0.5, 1.0).toStringAsFixed(2);

    // FFmpeg aecho filter for diffused acoustic reflections
    filters.add('aecho=in_gain=1.0:out_gain=$outGain:delays=$d1|$d2|$d3|$d4:decays=$c1|$c2|$c3|$c4');

    // 2. High-frequency absorption / damping filter
    if (config.damping > 0.15) {
      final dampingDb = (config.damping * 12.0).clamp(1.0, 15.0).toStringAsFixed(1);
      filters.add('equalizer=f=8000:width_type=h:width=2500:g=-$dampingDb');
    }

    // 3. Stereo width spatialization
    if (config.stereoWidth > 0.05) {
      final slev = (0.8 + config.stereoWidth * 0.7).clamp(0.5, 1.8).toStringAsFixed(2);
      filters.add('stereotools=slev=$slev');
    }

    // 4. True-peak brickwall ceiling limiter (AGENTS.md Rule 4 Safeguard)
    filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');

    return filters;
  }

  /// HUD status badge for active reverb chamber
  static String getReverbBadge(ReverbChamberConfig config) {
    if (!config.isActive) return '';
    return '🏛️ REVERB (${config.roomType.label} • ${(config.wetDryMix * 100).toInt()}% WET)';
  }
}
