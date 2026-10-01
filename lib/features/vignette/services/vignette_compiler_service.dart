import 'dart:math' as math;
import '../models/vignette_config.dart';

/// CapCut Pro Cinematic Vignette & Atmospheric Spotlight Compiler Service.
///
/// Ports the ByteDance/CapCut Pro shader falloff formulas (`dark_angle.frag`, `gles2_filter.frag`)
/// to compute real-time optical illumination gradients and compile hardware-accelerated
/// FFmpeg export filter chains.
class VignetteCompilerService {
  const VignetteCompilerService._();

  /// Computes the exact smoothstep radial falloff at normalized UV coordinates `(u, v) \in [0, 1]`.
  ///
  /// Incorporates focal center offset `(centerX, centerY)`, roundness aspect deformation,
  /// clearing radius, and cubic Hermite feathering identical to studio shaders.
  static double computeFalloffAt({
    required double u,
    required double v,
    required VignetteConfig config,
    double aspectRatio = 1.0,
  }) {
    if (!config.hasActiveVignette) return 0.0;

    // Map [0, 1] UV to [-1, 1] Cartesian plane centered on screen
    final normCenterX = config.centerX;
    final normCenterY = config.centerY;

    double dx = (u * 2.0 - 1.0) - normCenterX;
    double dy = (v * 2.0 - 1.0) - normCenterY;

    // Apply aspect ratio compensation
    if (aspectRatio > 1.0) {
      dx *= aspectRatio;
    } else if (aspectRatio < 1.0 && aspectRatio > 0.0) {
      dy /= aspectRatio;
    }

    // Apply roundness deformation:
    // Negative = horizontal anamorphic oval (stretch X)
    // Positive = vertical portrait oval (stretch Y)
    if (config.roundness < 0) {
      final deform = 1.0 + config.roundness.abs() * 0.75;
      dx /= deform;
    } else if (config.roundness > 0) {
      final deform = 1.0 + config.roundness * 0.75;
      dy /= deform;
    }

    final double dist = math.sqrt(dx * dx + dy * dy);

    // Inner clear radius and outer falloff threshold
    final double innerR = config.radius * 0.85;
    final double outerR = math.max(innerR + 0.01, innerR + config.feather * 0.95);

    if (dist <= innerR) {
      return 0.0;
    } else if (dist >= outerR) {
      return config.intensity.abs().clamp(0.0, 1.0);
    }

    // Cubic Hermite smoothstep interpolation: 3t^2 - 2t^3
    final double t = ((dist - innerR) / (outerR - innerR)).clamp(0.0, 1.0);
    final double smooth = t * t * (3.0 - 2.0 * t);

    return (smooth * config.intensity.abs()).clamp(0.0, 1.0);
  }

  /// Generates the hardware-accelerated FFmpeg export filter chain.
  ///
  /// Utilizes FFmpeg's native `vignette` filter with parameterized lens angle,
  /// optical center coordinates, aspect ratio, and directional mode (forward/backward).
  static List<String> generateFFmpegFilters(
    VignetteConfig config, {
    int width = 1920,
    int height = 1080,
  }) {
    if (!config.hasActiveVignette) return const [];

    final filters = <String>[];

    // Compute normalized optical center in range [0.0, 1.0]
    final normX = ((0.5 + (config.centerX * 0.5))).clamp(0.05, 0.95);
    final normY = ((0.5 + (config.centerY * 0.5))).clamp(0.05, 0.95);

    // Map radius and feather into FFmpeg's lens angle radians
    // FFmpeg default is PI/5 (~0.628). Smaller angle = deeper vignette.
    final baseAngle = math.pi * (0.2 + (1.0 - config.intensity.abs()) * 0.25);
    final angleFactor = (config.radius * 0.6 + config.feather * 0.4).clamp(0.15, 1.0);
    final angle = (baseAngle * angleFactor).clamp(0.15, math.pi / 2.1);

    // Mode: 'forward' for edge darkening; 'backward' for edge brightening (light spotlight)
    final mode = config.intensity < 0 ? 'backward' : 'forward';

    // Aspect deformation:
    // Roundness < 0 -> wider oval; Roundness > 0 -> taller oval
    final aspectVal = (1.0 - config.roundness * 0.4).clamp(0.4, 2.5);

    final vignetteFilter = 'vignette='
        'a=\'${angle.toStringAsFixed(4)}\':'
        'x0=\'w*${normX.toStringAsFixed(3)}\':'
        'y0=\'h*${normY.toStringAsFixed(3)}\':'
        'aspect=\'${aspectVal.toStringAsFixed(3)}\':'
        'mode=$mode:'
        'dither=1';

    filters.add(vignetteFilter);

    // If color tint is active (and not plain black or white), apply subtle color grading
    if (config.tint == VignetteTint.vintageSepia) {
      filters.add('colorchannelmixer=rr=1.04:rg=0.02:rb=-0.04:br=-0.08:bb=0.92');
    } else if (config.tint == VignetteTint.warmAmber) {
      filters.add('colorchannelmixer=rr=1.05:rg=0.03:rb=-0.06:br=-0.05:bg=0.02');
    } else if (config.tint == VignetteTint.midnightBlue) {
      filters.add('colorchannelmixer=rr=0.92:rg=-0.02:rb=0.06:br=0.05:bb=1.08');
    } else if (config.tint == VignetteTint.emeraldForest) {
      filters.add('colorchannelmixer=rr=0.94:rg=1.04:rb=0.92:br=-0.04:bg=0.05:bb=0.95');
    }

    return filters;
  }
}
