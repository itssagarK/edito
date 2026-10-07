import '../models/tilt_shift_config.dart';

/// Compiles tilt-shift miniature depth-of-field parameters into deterministic FFmpeg filtergraphs.
class TiltShiftCompilerService {
  /// Compiles the complete FFmpeg video filter for tilt-shift selective focus and diorama color.
  static String compileFilter(
    TiltShiftConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return '';

    final filters = <String>[];

    // 1. Miniature diorama color saturation and contrast pop
    if (config.saturationBoost > 1.05) {
      final sat = config.saturationBoost.clamp(1.0, 2.5).toStringAsFixed(2);
      filters.add('eq=saturation=$sat:contrast=1.08');
    }

    final blurRadius = (config.blurRadius * 0.8).clamp(2.0, 28.0).round();
    final halfBand = (config.focusBandwidth / 2.0);
    final topBound = (config.focusPosition - halfBand).clamp(0.0, 1.0).toStringAsFixed(2);
    final bottomBound = (config.focusPosition + halfBand).clamp(0.0, 1.0).toStringAsFixed(2);

    switch (config.mode) {
      case TiltShiftMode.linearBar:
      case TiltShiftMode.miniatureModel:
      case TiltShiftMode.cinematicMacro:
        // Progressive selective blend: in-focus band remains sharp, top & bottom blurred
        filters.add(
          'split[ts_sharp][ts_blur];'
          '[ts_blur]boxblur=lr=$blurRadius:lp=2[ts_blurred];'
          '[ts_sharp][ts_blurred]blend=all_expr=\'if(between(Y/H,$topBound,$bottomBound),A,B)\'',
        );
        break;

      case TiltShiftMode.radialCircle:
        final radiusPx = (targetHeight * (config.focusBandwidth * 0.8)).clamp(50.0, targetHeight.toDouble()).round();
        filters.add(
          'split[ts_sharp][ts_blur];'
          '[ts_blur]boxblur=lr=$blurRadius:lp=2[ts_blurred];'
          '[ts_sharp][ts_blurred]blend=all_expr=\'if(lte(hypot(X-W/2,Y-H/2),$radiusPx),A,B)\'',
        );
        break;
    }

    return filters.join(',');
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getTiltShiftBadge(TiltShiftConfig config) {
    if (!config.isActive) return '';
    return '🔍 TILT-SHIFT: ${config.mode.displayName.toUpperCase()} (${(config.focusBandwidth * 100).round()}% BAND / ${config.blurRadius.round()}PX BLUR)';
  }
}
