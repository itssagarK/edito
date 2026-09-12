import '../models/video_border_config.dart';

class VideoBorderCompilerService {
  /// Compiles VideoBorderConfig into high-performance FFmpeg video filter commands
  static String generateFFmpegFilter(
    VideoBorderConfig config, {
    required int targetWidth,
    required int targetHeight,
    int referenceHeight = 720,
  }) {
    if (!config.isEnabled || config.borderWidth <= 0) return '';

    final scale = targetHeight / referenceHeight;
    final strokeW = (config.borderWidth * scale).round().clamp(1, 200);

    final primaryHex = _toFFmpegColor(config.borderColor);
    final alpha = config.borderOpacity.clamp(0.0, 1.0);

    switch (config.style) {
      case VideoBorderStyle.solid:
        return 'drawbox=x=0:y=0:w=$targetWidth:h=$targetHeight:color=$primaryHex@${alpha.toStringAsFixed(2)}:t=$strokeW';

      case VideoBorderStyle.neonGlow:
        final glowColor = config.secondaryColor != null
            ? _toFFmpegColor(config.secondaryColor!)
            : primaryHex;
        final innerW = (strokeW * 0.4).round().clamp(1, 100);
        final outerW = strokeW;
        return 'drawbox=x=0:y=0:w=$targetWidth:h=$targetHeight:color=$glowColor@${(alpha * 0.45).toStringAsFixed(2)}:t=$outerW,'
            'drawbox=x=0:y=0:w=$targetWidth:h=$targetHeight:color=$primaryHex@${alpha.toStringAsFixed(2)}:t=$innerW';

      case VideoBorderStyle.gradient:
        final secColor = config.secondaryColor != null
            ? _toFFmpegColor(config.secondaryColor!)
            : '0xFFD700';
        final halfW = (strokeW / 2).round().clamp(1, 100);
        return 'drawbox=x=0:y=0:w=$targetWidth:h=$targetHeight:color=$primaryHex@${alpha.toStringAsFixed(2)}:t=$strokeW,'
            'drawbox=x=$halfW:y=$halfW:w=${targetWidth - 2 * halfW}:h=${targetHeight - 2 * halfW}:color=$secColor@${alpha.toStringAsFixed(2)}:t=$halfW';

      case VideoBorderStyle.filmStrip:
        final barH = (strokeW * 1.5).round().clamp(4, 250);
        return 'drawbox=x=0:y=0:w=$targetWidth:h=$barH:color=$primaryHex@${alpha.toStringAsFixed(2)}:t=fill,'
            'drawbox=x=0:y=${targetHeight - barH}:w=$targetWidth:h=$barH:color=$primaryHex@${alpha.toStringAsFixed(2)}:t=fill,'
            'drawbox=x=0:y=0:w=$strokeW:h=$targetHeight:color=$primaryHex@${alpha.toStringAsFixed(2)}:t=$strokeW';

      case VideoBorderStyle.polaroid:
        final bottomMargin = (strokeW * 2.5).round().clamp(10, 300);
        return 'drawbox=x=0:y=0:w=$targetWidth:h=$targetHeight:color=$primaryHex@${alpha.toStringAsFixed(2)}:t=$strokeW,'
            'drawbox=x=0:y=${targetHeight - bottomMargin}:w=$targetWidth:h=$bottomMargin:color=$primaryHex@${alpha.toStringAsFixed(2)}:t=fill';

      case VideoBorderStyle.vignetteFrame:
        final barH = (strokeW * 1.8).round().clamp(6, 250);
        return 'drawbox=x=0:y=0:w=$targetWidth:h=$barH:color=black@0.95:t=fill,'
            'drawbox=x=0:y=${targetHeight - barH}:w=$targetWidth:h=$barH:color=black@0.95:t=fill';

      case VideoBorderStyle.roundedCard:
      case VideoBorderStyle.retroTv:
        return 'drawbox=x=0:y=0:w=$targetWidth:h=$targetHeight:color=$primaryHex@${alpha.toStringAsFixed(2)}:t=$strokeW';
    }
  }

  static String _toFFmpegColor(int argb) {
    final rgb = argb & 0x00FFFFFF;
    return '0x${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Formats HUD badge for realtime preview viewport
  static String getBorderBadge(VideoBorderConfig config) {
    if (!config.isEnabled) return '';
    return '🖼️ BORDER (${config.style.name.toUpperCase()} ${config.borderWidth.round()}PX)';
  }
}
