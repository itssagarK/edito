import '../models/image_overlay_config.dart';

class PipCompilerService {
  /// Compiles Picture-in-Picture window configuration into native FFmpeg video filter commands
  static String generateFFmpegOverlayFilter(
    ImageOverlayConfig config, {
    required int targetWidth,
    required int targetHeight,
  }) {
    if (!config.isEnabled) return '';

    final filters = <String>[];
    final pipWidth = (targetWidth * config.scale).round().clamp(120, targetWidth);
    final pipHeight = (pipWidth * 9 / 16).round().clamp(80, targetHeight);

    // Center coordinates to top-left pixel anchor
    final posX = ((targetWidth * config.positionX) - (pipWidth / 2)).round().clamp(0, targetWidth - pipWidth);
    final posY = ((targetHeight * config.positionY) - (pipHeight / 2)).round().clamp(0, targetHeight - pipHeight);

    // 1. Draw outer PiP background window
    final bgOpacity = config.opacity.clamp(0.1, 1.0);
    filters.add('drawbox=x=$posX:y=$posY:w=$pipWidth:h=$pipHeight:color=black@$bgOpacity:t=fill');

    // 2. Draw outer border stroke if configured
    if (config.borderWidth > 0) {
      final borderThickness = config.borderWidth.round().clamp(1, 20);
      final hexColor = config.borderColor.toRadixString(16).padLeft(8, '0');
      // Format RRGGBB
      final colorHex = hexColor.length == 8 ? hexColor.substring(2) : hexColor;
      filters.add('drawbox=x=$posX:y=$posY:w=$pipWidth:h=$pipHeight:color=0x$colorHex@$bgOpacity:t=$borderThickness');
    }

    // 3. Draw asset label inside PiP window if provided
    final label = config.assetLabel.trim();
    if (label.isNotEmpty) {
      final sanitizedLabel = label.replaceAll("'", "\\'").replaceAll(':', '\\:');
      final fontSize = (pipHeight * 0.18).round().clamp(10, 48);
      final labelY = posY + pipHeight - fontSize - 8;
      final labelX = posX + 10;
      filters.add("drawtext=text='$sanitizedLabel':x=$labelX:y=$labelY:fontsize=$fontSize:fontcolor=white:box=1:boxcolor=black@0.75:boxborderw=4");
    }

    return filters.join(',');
  }

  /// Generates the floating HUD status badge for active Picture-in-Picture
  static String getPipBadge(ImageOverlayConfig config) {
    if (!config.isEnabled) return '';

    switch (config.shape) {
      case PipShape.circle:
        return '🪟 PiP (CIRCLE WEBCAM)';
      case PipShape.rectangle:
        if (config.preset == PipPreset.sideBySideLeft || config.preset == PipPreset.sideBySideRight) {
          return '🪟 PiP (SPLIT 50/50)';
        }
        return '🪟 PiP (WINDOW)';
      case PipShape.roundedRect:
      case PipShape.squircle:
      case PipShape.diamond:
        return '🪟 PiP (${config.preset.label.split(' ').first.toUpperCase()})';
    }
  }
}
