import 'dart:math' as math;
import '../models/echo_motion_config.dart';

/// Compiler service for generating FFmpeg video filters for motion blur
/// and temporal echo decay smearing.
class EchoMotionCompilerService {
  const EchoMotionCompilerService();

  /// Static convenience method for FFmpeg command builder
  static String compileFilter(
    EchoMotionConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    return const EchoMotionCompilerService().compile(config);
  }

  /// Compiles FFmpeg video filter string for the given [EchoMotionConfig].
  /// Returns empty string if disabled.
  String compile(EchoMotionConfig config) {
    if (!config.isEnabled) return '';

    final frames = config.trailCount.clamp(2, 12);
    final decay = config.decay.clamp(0.1, 0.98);

    switch (config.mode) {
      case EchoMotionMode.smoothMotionBlur:
        // Exponential decay weights normalized for temporal frame averaging
        final weights = _generateDecayWeights(frames, decay);
        return 'tmix=frames=$frames:weights="$weights"';

      case EchoMotionMode.longExposureGhost:
        // High temporal decay lagfun for smooth persistent ghostly trails
        final lagDecay = (decay * 0.95).toStringAsFixed(2);
        final weights = _generateDecayWeights(frames, decay * 0.9);
        return 'lagfun=decay=$lagDecay:planes=7,tmix=frames=$frames:weights="$weights"';

      case EchoMotionMode.phantomEcho:
        // Discrete stepped ghost silhouettes with spaced decay weights
        final weights = _generateSteppedWeights(frames, decay);
        return 'tmix=frames=$frames:weights="$weights"';

      case EchoMotionMode.lightTrailSmear:
        // Specular highlight preservation using lighten blend and temporal lag
        final lagDecay = decay.toStringAsFixed(2);
        return 'lagfun=decay=$lagDecay:planes=7,tblend=all_mode=lighten';

      case EchoMotionMode.dreamySlowShutter:
        // Step-printed slow shutter simulation with temporal blending
        final weights = _generateDecayWeights(frames, decay * 0.85);
        return 'tblend=all_mode=average,tmix=frames=$frames:weights="$weights"';
    }
  }

  /// Generates normalized space-separated weights for FFmpeg tmix filter
  String _generateDecayWeights(int count, double decayFactor) {
    final weights = <double>[];
    for (int i = 0; i < count; i++) {
      // Exponential decay: w_i = decay^i
      weights.add(math.pow(decayFactor, i).toDouble());
    }
    return weights.map((w) => w.toStringAsFixed(3)).join(' ');
  }

  /// Generates stepped weights for phantom echo silhouettes
  String _generateSteppedWeights(int count, double decayFactor) {
    final weights = <double>[];
    for (int i = 0; i < count; i++) {
      // Emphasize alternating stepped frames
      final step = (i % 2 == 0) ? 1.0 : 0.4;
      weights.add((math.pow(decayFactor, i) * step).toDouble());
    }
    return weights.map((w) => w.toStringAsFixed(3)).join(' ');
  }

  /// Returns user-facing badge label for the active mode.
  String getBadgeLabel(EchoMotionConfig config) {
    if (!config.isEnabled) return '';
    return '🌀 ${config.mode.label.toUpperCase()}';
  }
}
