import '../models/vocal_isolation_config.dart';

/// CapCut Pro AI Vocal Isolation & Audio Stem Splitter Compiler Service
class VocalIsolationCompilerService {
  /// Compiles vocal isolation configuration into native FFmpeg audio filter commands
  static List<String> generateFFmpegFilters(VocalIsolationConfig config) {
    if (!config.isEnabled || config.mode == VocalIsolationMode.none) {
      return const [];
    }

    final filters = <String>[];

    switch (config.mode) {
      case VocalIsolationMode.none:
        return const [];

      case VocalIsolationMode.isolateVocals:
        // 1. Mid-Side phase channel focus (elevates center vocal channel, attenuates stereo sides)
        filters.add('stereotools=mlev=1.4:slev=0.25:mode=lr>ms');
        // 2. Human speech fundamental bandpass pass-through
        filters.add('highpass=f=220,lowpass=f=4200');
        // 3. Speech clarity & intelligibility formant boost
        final clarityGain = (config.speechClarity * 5.0).toStringAsFixed(1);
        filters.add('equalizer=f=2600:t=q:w=1.4:g=$clarityGain');
        // 4. Vocal gain adjustment if non-zero
        if (config.vocalGain.abs() > 0.1) {
          filters.add('volume=${config.vocalGain.toStringAsFixed(1)}dB');
        }
        // 5. Downward noise gate to eliminate ambient background bleed
        final noiseThreshold = config.noiseThreshold.clamp(-60.0, -10.0).toStringAsFixed(1);
        filters.add('agate=threshold=${noiseThreshold}dB:ratio=2.5:attack=10:release=120');
        // 6. True-peak brickwall ceiling per AGENTS.md rule 4
        filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');
        break;

      case VocalIsolationMode.removeVocals:
        // 1. Center-pan phase subtraction eliminating panned lead singing
        filters.add('pan=stereo|c0=c0-0.95*c1|c1=c1-0.95*c0');
        // 2. Vocal fundamental notch suppression
        filters.add('equalizer=f=1800:t=q:w=2.0:g=-14.0');
        // 3. Low-end rhythm bass and treble sheen restoration
        filters.add('equalizer=f=80:t=q:w=1.0:g=2.5,equalizer=f=11000:t=q:w=1.0:g=2.0');
        // 4. Instrumental gain adjustment if non-zero
        if (config.instrumentalGain.abs() > 0.1) {
          filters.add('volume=${config.instrumentalGain.toStringAsFixed(1)}dB');
        }
        // 5. Brickwall limiter safeguard
        filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');
        break;

      case VocalIsolationMode.voiceBoost:
        // Vocal clarity and dialogue presence boost
        filters.add('equalizer=f=1200:t=q:w=1.2:g=5.0,equalizer=f=2800:t=q:w=1.2:g=4.0');
        if (config.vocalGain.abs() > 0.1) {
          filters.add('volume=${config.vocalGain.toStringAsFixed(1)}dB');
        }
        filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');
        break;

      case VocalIsolationMode.musicBoost:
        // Vocal dip with rhythm accompaniment emphasis
        filters.add('equalizer=f=1500:t=q:w=1.8:g=-8.0,equalizer=f=100:t=q:w=1.0:g=3.0,equalizer=f=10000:t=q:w=1.0:g=2.5');
        if (config.instrumentalGain.abs() > 0.1) {
          filters.add('volume=${config.instrumentalGain.toStringAsFixed(1)}dB');
        }
        filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');
        break;

      case VocalIsolationMode.custom:
        if (config.vocalGain > config.instrumentalGain) {
          filters.add('stereotools=mlev=1.3:slev=0.5:mode=lr>ms');
          filters.add('equalizer=f=2400:t=q:w=1.5:g=${(config.speechClarity * 4.0).toStringAsFixed(1)}');
        } else if (config.instrumentalGain > config.vocalGain) {
          filters.add('pan=stereo|c0=c0-0.8*c1|c1=c1-0.8*c0');
        }
        if (config.vocalGain.abs() > 0.1) {
          filters.add('volume=${config.vocalGain.toStringAsFixed(1)}dB');
        }
        filters.add('agate=threshold=${config.noiseThreshold.toStringAsFixed(1)}dB:ratio=2.0:attack=10:release=120');
        filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');
        break;
    }

    return filters;
  }

  /// Generates the floating HUD status badge for active Vocal Isolation
  static String getVocalIsolationBadge(VocalIsolationConfig config) {
    return config.badge;
  }
}
