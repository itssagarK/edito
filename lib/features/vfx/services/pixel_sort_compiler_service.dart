import '../models/pixel_sort_config.dart';

/// Compiles algorithmic luminance pixel sorting parameters into deterministic FFmpeg filtergraphs.
class PixelSortCompilerService {
  /// Compiles the complete FFmpeg video filter for pixel sorting luminance streaks and data tears.
  static String compileFilter(
    PixelSortConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return '';

    final filters = <String>[];
    final streakPx = (config.streakLength * 50.0).clamp(3.0, 70.0).round();
    final threshInt = (config.threshold * 255).clamp(10, 245).round();

    int blurX = 0;
    int blurY = 0;

    switch (config.mode) {
      case PixelSortMode.verticalDown:
        blurX = 1;
        blurY = streakPx;
        break;

      case PixelSortMode.horizontalTear:
        blurX = streakPx;
        blurY = 1;
        break;

      case PixelSortMode.diagonalSlant:
        blurX = (streakPx * 0.7).round().clamp(2, 50);
        blurY = (streakPx * 0.7).round().clamp(2, 50);
        break;

      case PixelSortMode.radiantBurst:
        blurX = (streakPx * 0.5).round().clamp(2, 35);
        blurY = (streakPx * 0.5).round().clamp(2, 35);
        break;

      case PixelSortMode.thresholdBand:
        blurX = 1;
        blurY = (streakPx * 0.8).round().clamp(2, 50);
        break;
    }

    // Selective threshold streak blend: pixels above luminance threshold smear into sorted streaks
    filters.add(
      'split[ps_orig][ps_blur];'
      '[ps_blur]boxblur=lr=$blurX:lp=$blurY[ps_streaked];'
      "[ps_orig][ps_streaked]blend=all_expr='if(gt(Y,$threshInt),B,A)'",
    );

    if (config.intensity > 0.8) {
      filters.add('eq=saturation=1.14:contrast=1.06');
    }

    return filters.join(',');
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getPixelSortBadge(PixelSortConfig config) {
    if (!config.isActive) return '';
    return '⚡ PIXEL SORT: ${config.mode.displayName.toUpperCase()} (${(config.streakLength * 100).round()}% STREAK)';
  }
}
