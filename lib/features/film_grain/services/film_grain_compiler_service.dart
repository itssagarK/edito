import 'dart:math' as math;
import '../models/film_grain_type.dart';
import '../models/film_grain_config.dart';

/// CapCut Pro Cinematic Film Grain & Texture Particles Compiler Service.
class FilmGrainCompilerService {
  /// Computes dynamic photographic luminance masking weight from CapCut Pro's native
  /// `gles2_filter.frag` shader, protecting peak highlights and crushed shadows.
  static double calculateLumaMask(
    double luma, {
    double shadowSuppression = 0.20,
    double highlightSuppression = 0.30,
  }) {
    final oriGray = (luma * 2.0 - 1.0).clamp(-1.0, 1.0);
    final absOriGray = oriGray.abs();
    final absOriGray2 = absOriGray * absOriGray;
    final absOriGray3 = absOriGray2 * absOriGray;

    const strength = 0.49019608;
    double mask;

    if (oriGray >= 0.0) {
      // Highlights compression
      final suppressionFactor = (highlightSuppression / 0.30).clamp(0.0, 3.0);
      mask = (absOriGray3 * 0.5 + absOriGray2 * 0.5) * (strength - 0.03921569) * suppressionFactor;
    } else {
      // Shadows compression
      final suppressionFactor = (shadowSuppression / 0.20).clamp(0.0, 3.0);
      mask = (absOriGray2 * 0.4 + absOriGray * 0.6) * strength * suppressionFactor;
    }

    return (strength - mask).clamp(0.0, 1.0);
  }

  /// Pseudo-random 1D hash function from CapCut Pro's `noise.frag` shader.
  static double hash13(double x, double y, double z) {
    var pX = (x * 0.1031) % 1.0;
    var pY = (y * 0.1031) % 1.0;
    var pZ = (z * 0.1031) % 1.0;
    if (pX < 0) pX += 1.0;
    if (pY < 0) pY += 1.0;
    if (pZ < 0) pZ += 1.0;

    final dotVal = pX * (pY + 33.33) + pY * (pZ + 33.33) + pZ * (pX + 33.33);
    final dotMod = dotVal % 1.0;

    final res = ((pX + pY) * pZ + dotMod) % 1.0;
    return res < 0 ? res + 1.0 : res;
  }

  /// Compiles hardware-accelerated FFmpeg `noise` filter parameters for 4K video exports.
  static List<String> generateFFmpegFilters(FilmGrainConfig config) {
    if (!config.isActive) return const [];

    // Scale intensity and grain size into FFmpeg 0..100 noise scale
    final baseStrength = config.intensity * 35.0 * (config.grainSize / 1.0);
    final lumaStrength = baseStrength.clamp(1.0, 80.0).toInt();

    final chromaStrength = (config.type == FilmGrainType.silverHalide)
        ? 0
        : (lumaStrength * config.roughness * 0.6).clamp(0.0, 60.0).toInt();

    final flags = config.animate ? 't+u' : 'u';

    final filter = 'noise='
        'c0s=$lumaStrength:c0f=$flags:'
        'c1s=$chromaStrength:c1f=$flags:'
        'c2s=$chromaStrength:c2f=$flags';

    return [filter];
  }
}
