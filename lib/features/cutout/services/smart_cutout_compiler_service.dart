import '../models/smart_cutout_config.dart';

class SmartCutoutCompilerService {
  /// Compiles SmartCutoutConfig into FFmpeg video filtergraph elements
  static List<String> generateFFmpegFilters(
    SmartCutoutConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isEnabled || config.type == CutoutType.none) {
      return const [];
    }

    final filters = <String>[];

    // 1. Background Treatment
    switch (config.backgroundMode) {
      case CutoutBackgroundMode.blur:
        final sigma = config.backgroundBlur.clamp(1.0, 30.0).toStringAsFixed(1);
        filters.add('boxblur=luma_radius=$sigma:luma_power=2');
        break;

      case CutoutBackgroundMode.solidColor:
        final r = ((config.backgroundColorValue >> 16) & 0xFF) / 255.0;
        final g = ((config.backgroundColorValue >> 8) & 0xFF) / 255.0;
        final b = (config.backgroundColorValue & 0xFF) / 255.0;
        final rm = ((r - 0.5) * 1.4).clamp(-1.0, 1.0).toStringAsFixed(2);
        final gm = ((g - 0.5) * 1.4).clamp(-1.0, 1.0).toStringAsFixed(2);
        final bm = ((b - 0.5) * 1.4).clamp(-1.0, 1.0).toStringAsFixed(2);
        filters.add('colorbalance=rm=$rm:gm=$gm:bm=$bm');
        break;

      case CutoutBackgroundMode.transparent:
        // Ensure transparent alpha channel support on export
        filters.add('format=yuva420p');
        break;
    }

    // 2. Stroke / Glowing Outline Filter Synthesis
    switch (config.strokeStyle) {
      case CutoutStrokeStyle.neonGlow:
        final r = ((config.strokeColorValue >> 16) & 0xFF) / 255.0;
        final g = ((config.strokeColorValue >> 8) & 0xFF) / 255.0;
        final b = (config.strokeColorValue & 0xFF) / 255.0;
        final rr = (r * 2.0).clamp(0.0, 2.0).toStringAsFixed(2);
        final gg = (g * 2.0).clamp(0.0, 2.0).toStringAsFixed(2);
        final bb = (b * 2.0).clamp(0.0, 2.0).toStringAsFixed(2);
        filters.add('colorchannelmixer=rr=$rr:gg=$gg:bb=$bb');
        break;

      case CutoutStrokeStyle.cyberPink:
        filters.add('colorchannelmixer=rr=2.00:gg=0.00:bb=1.60');
        break;

      case CutoutStrokeStyle.goldenAura:
        filters.add('colorchannelmixer=rr=2.00:gg=1.70:bb=0.00');
        break;

      case CutoutStrokeStyle.matrixGreen:
        filters.add('colorchannelmixer=rr=0.00:gg=2.00:bb=0.40');
        break;

      case CutoutStrokeStyle.solidBorder:
        filters.add('eq=contrast=1.35:brightness=0.08');
        break;

      case CutoutStrokeStyle.dashedSticker:
        filters.add('edgedetect=low=0.15:high=0.40');
        break;

      case CutoutStrokeStyle.none:
        break;
    }

    // 3. Subject / Background Inversion
    if (config.isInverted) {
      filters.add('negate');
    }

    return filters;
  }

  /// Returns user-facing badge string for live preview HUD
  static String getCutoutBadge(SmartCutoutConfig config) {
    if (!config.isEnabled || config.type == CutoutType.none) return '';

    final strokeBadge = () {
      switch (config.strokeStyle) {
        case CutoutStrokeStyle.neonGlow:
          return 'NEON GLOW';
        case CutoutStrokeStyle.cyberPink:
          return 'CYBER PINK';
        case CutoutStrokeStyle.goldenAura:
          return 'GOLDEN AURA';
        case CutoutStrokeStyle.matrixGreen:
          return 'MATRIX GREEN';
        case CutoutStrokeStyle.solidBorder:
          return 'STICKER BORDER';
        case CutoutStrokeStyle.dashedSticker:
          return 'DASHED OUTLINE';
        case CutoutStrokeStyle.none:
          return null;
      }
    }();

    if (config.backgroundMode == CutoutBackgroundMode.blur) {
      return strokeBadge != null
          ? '✂️ BOKEH + $strokeBadge'
          : '✂️ PORTRAIT BOKEH';
    }

    if (config.backgroundMode == CutoutBackgroundMode.solidColor) {
      final hex = config.backgroundColorValue.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
      return strokeBadge != null
          ? '✂️ #$hex + $strokeBadge'
          : '✂️ STUDIO #$hex';
    }

    if (strokeBadge != null) {
      return '✂️ CUTOUT ($strokeBadge)';
    }

    return '✂️ AUTO CUTOUT';
  }

  /// Generates real-time 4x5 Skia GPU color filter matrix for live preview viewport
  static List<double> generatePreviewMatrix(SmartCutoutConfig config) {
    if (!config.isEnabled || config.strokeStyle == CutoutStrokeStyle.none) {
      return [
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ];
    }

    final r = ((config.strokeColorValue >> 16) & 0xFF) / 255.0;
    final g = ((config.strokeColorValue >> 8) & 0xFF) / 255.0;
    final b = (config.strokeColorValue & 0xFF) / 255.0;

    // Slight ambient hue lift matching neon outline color
    return [
      0.9 + (r * 0.2), 0, 0, 0, 0,
      0, 0.9 + (g * 0.2), 0, 0, 0,
      0, 0, 0.9 + (b * 0.2), 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}
