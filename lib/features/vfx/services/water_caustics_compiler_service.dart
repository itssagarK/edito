import '../models/water_caustics_config.dart';

/// Compiler service for generating FFmpeg video filtergraphs for liquid water
/// caustics and underwater refractive wave effects.
class WaterCausticsCompilerService {
  const WaterCausticsCompilerService();

  /// Static convenience method for FFmpeg command builder
  static String compileFilter(
    WaterCausticsConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    return const WaterCausticsCompilerService().compile(
      config,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }

  /// Compiles FFmpeg video filter string for the given [WaterCausticsConfig].
  /// Returns empty string if disabled.
  String compile(
    WaterCausticsConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isEnabled || !config.isActive) return '';

    final filters = <String>[];
    final depth = config.tintDepth.clamp(0.0, 1.0);
    final intensity = config.intensity.clamp(0.0, 1.0);

    // 1. Aquatic Color Balance Grading based on mode
    switch (config.mode) {
      case WaterCausticsMode.tropicalPool:
        final bBoost = (0.15 + depth * 0.25).toStringAsFixed(2);
        final gBoost = (0.05 + depth * 0.10).toStringAsFixed(2);
        final rCut = (-0.10 - depth * 0.15).toStringAsFixed(2);
        filters.add('colorbalance=rs=$rCut:gs=$gBoost:bs=$bBoost:rm=$rCut:gm=$gBoost:bm=$bBoost');
        break;

      case WaterCausticsMode.abyssalDeep:
        final bBoost = (0.20 + depth * 0.35).toStringAsFixed(2);
        final rCut = (-0.20 - depth * 0.30).toStringAsFixed(2);
        final gCut = (-0.05 - depth * 0.10).toStringAsFixed(2);
        filters.add('colorbalance=rs=$rCut:gs=$gCut:bs=$bBoost:rm=$rCut:gm=$gCut:bm=$bBoost');
        break;

      case WaterCausticsMode.emeraldLagoon:
        final gBoost = (0.18 + depth * 0.28).toStringAsFixed(2);
        final bBoost = (0.08 + depth * 0.15).toStringAsFixed(2);
        final rCut = (-0.15 - depth * 0.20).toStringAsFixed(2);
        filters.add('colorbalance=rs=$rCut:gs=$gBoost:bs=$bBoost:rm=$rCut:gm=$gBoost:bm=$bBoost');
        break;

      case WaterCausticsMode.bioluminescentReef:
        final bBoost = (0.25 + depth * 0.30).toStringAsFixed(2);
        final rBoost = (0.10 + depth * 0.15).toStringAsFixed(2);
        final gCut = (-0.10 - depth * 0.10).toStringAsFixed(2);
        filters.add('colorbalance=rs=$rBoost:gs=$gCut:bs=$bBoost:rm=$rBoost:gm=$gCut:bm=$bBoost');
        break;

      case WaterCausticsMode.sunkenGold:
        final rBoost = (0.15 + depth * 0.20).toStringAsFixed(2);
        final gBoost = (0.10 + depth * 0.15).toStringAsFixed(2);
        final bCut = (-0.12 - depth * 0.18).toStringAsFixed(2);
        filters.add('colorbalance=rs=$rBoost:gs=$gBoost:bs=$bCut:rm=$rBoost:gm=$gBoost:bm=$bCut');
        break;
    }

    // 2. Refractive Wave Contrast & Brightness Modulation
    final contrast = (1.0 + intensity * 0.18).toStringAsFixed(2);
    final brightness = (intensity * 0.04).toStringAsFixed(2);
    filters.add('eq=contrast=$contrast:brightness=$brightness:saturation=1.12');

    // 3. Chromatic Edge Dispersion for Caustic Light Ray Splitting
    if (config.chromaticDispersion > 0.1) {
      final shift = (config.chromaticDispersion * 4).round().clamp(1, 8);
      filters.add('rgbashift=rh=$shift:bv=-$shift');
    }

    // 4. Caustic Filament Unsharp Bloom & Lens Refraction
    final unsharpAmount = (0.6 + intensity * 0.8).toStringAsFixed(2);
    filters.add('unsharp=5:5:$unsharpAmount:5:5:0.0');

    // 5. Optical Underwater Vignette
    final vignetteAngle = (0.25 + depth * 0.25).toStringAsFixed(2);
    filters.add('vignette=angle=PI*$vignetteAngle');

    return filters.join(',');
  }

  /// Returns user-facing badge label for the active mode.
  String getCausticsBadge(WaterCausticsConfig config) {
    if (!config.isEnabled) return '';
    return '🌊 CAUSTICS: ${config.mode.label.toUpperCase()} (${(config.intensity * 100).round()}%)';
  }
}
