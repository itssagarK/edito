import 'dart:math' as math;
import '../models/diamond_prism_config.dart';

/// Compiler service for generating FFmpeg video filtergraphs for optical
/// diamond glass prism refractions and chromatic dispersion effects.
class DiamondPrismCompilerService {
  const DiamondPrismCompilerService();

  /// Static convenience method for FFmpeg command builder
  static String compileFilter(
    DiamondPrismConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    return const DiamondPrismCompilerService().compile(
      config,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }

  /// Compiles FFmpeg video filter string for the given [DiamondPrismConfig].
  /// Returns empty string if disabled.
  String compile(
    DiamondPrismConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isEnabled || !config.isActive) return '';

    final filters = <String>[];

    // 1. Directional Chromatic Dispersion via RGB Channel Offsets
    final rad = config.refractionAngle * math.pi / 180.0;
    final maxShift = (config.dispersionStrength * 16.0).round().clamp(1, 24);
    final rh = (math.cos(rad) * maxShift).round();
    final rv = (math.sin(rad) * maxShift).round();
    final bh = -rh;
    final bv = -rv;
    filters.add('rgbashift=rh=$rh:rv=$rv:bh=$bh:bv=$bv');

    // 2. Specular Contrast & Spectral Saturation Boost
    final sat = config.spectralSaturation.clamp(0.5, 2.0).toStringAsFixed(2);
    final contrast = (1.0 + config.innerReflectionIntensity * 0.15).toStringAsFixed(2);
    filters.add('eq=saturation=$sat:contrast=$contrast');

    // 3. Facet Edge Sharpening & Specular Starburst Bloom
    final unsharp = (0.5 + config.innerReflectionIntensity * 1.0).toStringAsFixed(2);
    filters.add('unsharp=5:5:$unsharp:5:5:0.0');

    // 4. Subtle Optical Lens Flare Vignette
    if (config.innerReflectionIntensity > 0.4) {
      filters.add('vignette=angle=PI*0.35');
    }

    return filters.join(',');
  }

  /// Returns user-facing badge label for the active mode.
  String getPrismBadge(DiamondPrismConfig config) {
    if (!config.isEnabled) return '';
    return '💎 PRISM: ${config.mode.label.toUpperCase()} (${(config.dispersionStrength * 100).round()}%)';
  }
}
