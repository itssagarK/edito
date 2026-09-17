import '../models/caption_line.dart';

class CaptionCompilerService {
  /// Compiles a list of timed kinetic captions into FFmpeg drawtext filter chains
  static List<String> generateFFmpegDrawTextFilters(
    List<CaptionLine> captions, {
    required int targetWidth,
    required int targetHeight,
  }) {
    if (captions.isEmpty) return [];

    final filters = <String>[];
    final scale = targetHeight / 720.0;

    for (final cap in captions) {
      if (cap.text.trim().isEmpty) continue;

      final startSec = (cap.startTimeMs / 1000.0).toStringAsFixed(2);
      final endSec = (cap.endTimeMs / 1000.0).toStringAsFixed(2);
      final fontSize = (cap.style.fontSize * scale).round().clamp(12, 120);

      final sanitizedText = cap.text
          .replaceAll("'", "\\'")
          .replaceAll(':', '\\:')
          .replaceAll('%', '\\%');

      final posX = (cap.style.positionX * targetWidth).round();
      final posY = (cap.style.positionY * targetHeight).round();

      final hexColor = cap.style.textColor.toRadixString(16).padLeft(8, '0');
      final fontColorHex = hexColor.length == 8 ? hexColor.substring(2) : hexColor;

      final buffer = StringBuffer();
      buffer.write("drawtext=text='$sanitizedText':");
      buffer.write('x=$posX-(text_w/2):y=$posY-(text_h/2):');
      buffer.write('fontsize=$fontSize:fontcolor=0x$fontColorHex:');

      if (cap.style.backgroundColor != null) {
        final bgHex = cap.style.backgroundColor!.toRadixString(16).padLeft(8, '0');
        final bgRgb = bgHex.length == 8 ? bgHex.substring(2) : bgHex;
        final bgAlpha = cap.style.backgroundColor! >> 24 & 0xFF;
        final bgOpacity = (bgAlpha / 255.0).clamp(0.1, 1.0).toStringAsFixed(2);
        final boxBorder = (cap.style.boxPadding * scale).round().clamp(4, 30);
        buffer.write('box=1:boxcolor=0x$bgRgb@$bgOpacity:boxborderw=$boxBorder:');
      }

      buffer.write("enable='between(t,$startSec,$endSec)'");
      filters.add(buffer.toString());
    }

    return filters;
  }

  /// Generates the floating HUD status badge for active subtitles
  static String getCaptionsBadge(List<CaptionLine> captions) {
    if (captions.isEmpty) return '';
    final count = captions.length;
    final isKinetic = captions.any((c) => c.isKinetic);
    return isKinetic ? '⚡ KINETIC CAPTIONS ($count)' : '💬 SUBTITLES ($count)';
  }
}
