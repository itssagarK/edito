import '../models/neon_glow_config.dart';

/// Compiles cyberpunk neon edge detection, wireframe, and holographic contours
/// into deterministic, high-performance FFmpeg filter expressions.
class NeonGlowCompilerService {
  /// Compiles the complete FFmpeg video filter chain for neon edges and holographic contours.
  static String compileFilter(
    NeonGlowConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return '';

    final filters = <String>[];
    final lowThresh = (config.edgeThreshold * 0.4).clamp(0.05, 0.4).toStringAsFixed(2);
    final highThresh = config.edgeThreshold.clamp(0.1, 0.8).toStringAsFixed(2);
    final blurSigma = (config.glowRadius * 0.4).clamp(1.0, 8.0).round();

    // 1. Edge extraction with Sobel detection and bloom diffusion
    if (config.mixWithSource >= 0.95) {
      // Pure edge overlay on source
      filters.add('edgedetect=low=$lowThresh:high=$highThresh:mode=colormix');
    } else if (config.mixWithSource <= 0.10) {
      // Pure black wireframe silhouette
      filters.add('edgedetect=low=$lowThresh:high=$highThresh:mode=wires');
      filters.add(_getColorMixer(config));
    } else {
      // Composite: split, edge detect, blur halo, and addition blend back onto source
      filters.add(
        'split[ng_src][ng_edges];'
        '[ng_edges]edgedetect=low=$lowThresh:high=$highThresh:mode=wires,boxblur=lr=$blurSigma:lp=1[ng_halo];'
        '[ng_src][ng_halo]blend=all_mode=addition',
      );
    }

    // 2. Holographic scanline raster lines
    if (config.scanlines) {
      filters.add('drawgrid=width=10000:height=4:thickness=1:color=black@0.30');
    }

    return filters.join(',');
  }

  static String _getColorMixer(NeonGlowConfig config) {
    switch (config.mode) {
      case NeonGlowMode.cyberpunkNeon:
        return 'colorchannelmixer=rr=0.1:gg=0.9:bb=1.0';
      case NeonGlowMode.hologramWireframe:
        return 'colorchannelmixer=rr=0.0:gg=0.7:bb=1.0';
      case NeonGlowMode.matrixPhosphor:
        return 'colorchannelmixer=rr=0.0:gg=1.0:bb=0.2';
      case NeonGlowMode.thermalContour:
        return 'colorchannelmixer=rr=1.0:gg=0.4:bb=0.0';
      case NeonGlowMode.rainbowEdges:
        return 'colorchannelmixer=rr=0.9:gg=0.8:bb=0.2';
    }
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getNeonGlowBadge(NeonGlowConfig config) {
    if (!config.isActive) return '';
    return '⚡ NEON GLOW: ${config.mode.displayName.toUpperCase()} (${(config.glowIntensity * 100).round()}% LUM)';
  }
}
