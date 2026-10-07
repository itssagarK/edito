import '../models/audio_stutter_config.dart';

/// Compiles rhythmic beat stutter, glitch buffer slicing, and tape brake deceleration
/// into deterministic, studio-grade FFmpeg audio filter chains.
class AudioStutterCompilerService {
  /// Compiles the complete FFmpeg audio filter for rhythmic audio stutter repetition.
  /// Strictly includes true-peak brickwall ceiling limiter per AGENTS.md Rule 4.
  static String compileFilter(AudioStutterConfig config) {
    if (!config.isActive) return '';

    final filters = <String>[];
    final sliceMs = config.sliceDurationMs.round().clamp(15, 2000);

    // Build delay and decay lists for rhythmic buffer repeats
    final delays = <int>[];
    final decays = <String>[];

    int cumulativeDelay = 0;
    for (int i = 1; i <= config.repeats; i++) {
      int stepDelay = sliceMs;

      if (config.mode == AudioStutterMode.accelerando) {
        // Accelerating drill: each step shrinks by factor
        stepDelay = (sliceMs * (1.0 - (i * 0.08))).round().clamp(15, 2000);
      }

      cumulativeDelay += stepDelay;
      delays.add(cumulativeDelay);

      double decay = (config.mix * (1.0 - (i * 0.04))).clamp(0.3, 0.95);
      if (config.mode == AudioStutterMode.straight) {
        decay = (config.mix * 0.9).clamp(0.4, 0.95);
      }
      decays.add(decay.toStringAsFixed(2));
    }

    final delayStr = delays.join('|');
    final decayStr = decays.join('|');
    final inGain = (1.0 - (config.mix * 0.3)).clamp(0.4, 1.0).toStringAsFixed(2);
    final outGain = (config.mix * 0.9).clamp(0.2, 0.95).toStringAsFixed(2);

    // 1. Rhythmic delay multi-tap buffer reflection
    filters.add('aecho=$inGain:$outGain:$delayStr:$decayStr');

    // 2. Mode-specific DSP processing
    switch (config.mode) {
      case AudioStutterMode.straight:
      case AudioStutterMode.accelerando:
        // Sharp duty-cycle gate chopping if gateWidth < 0.85
        if (config.gateWidth < 0.85) {
          final chopFreq = (1000.0 / sliceMs).clamp(0.5, 40.0).toStringAsFixed(1);
          final chopDepth = ((1.0 - config.gateWidth) * 0.9).clamp(0.2, 0.85).toStringAsFixed(2);
          filters.add('tremolo=f=$chopFreq:d=$chopDepth');
        }
        break;

      case AudioStutterMode.pitchDrop:
        // Turntable tape stop brake pitch deceleration
        final dropFreq = (1000.0 / (sliceMs * config.repeats)).clamp(0.2, 8.0).toStringAsFixed(2);
        final dropDepth = (config.pitchDropSemitones / 12.0).clamp(0.1, 0.95).toStringAsFixed(2);
        filters.add('vibrato=f=$dropFreq:d=$dropDepth');
        break;

      case AudioStutterMode.reverseEcho:
        // Ping-pong phased spatial reflections
        filters.add('aphaser=in_gain=0.8:out_gain=0.74:delay=3:decay=0.4:speed=0.5:type=t');
        break;

      case AudioStutterMode.granularCloud:
        // Micro-grain flanged glitch diffusion
        filters.add('flanger=delay=2.5:depth=3.5:regen=40:speed=0.8:phase=45');
        break;
    }

    // 3. AGENTS.md Rule 4: Mandatory true-peak brickwall ceiling limiter
    filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');

    return filters.join(',');
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getAudioStutterBadge(AudioStutterConfig config) {
    if (!config.isActive) return '';
    return '🎛️ STUTTER: ${config.mode.displayName.toUpperCase()} (${config.division.label} BEAT / ${config.repeats}X)';
  }
}
