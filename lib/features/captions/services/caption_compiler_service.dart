import '../models/caption_line.dart';

/// CapCut Pro Subtitle & Filtergraph Compiler Service
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
      final baseFontSize = (cap.style.fontSize * scale).round().clamp(12, 160);

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

      // Dynamic kinetic bounce sizing expression if kinetic is active
      if (cap.isKinetic && cap.highlightStyle == KaraokeHighlightStyle.scalePunch) {
        final tExpr = "(t-$startSec)";
        buffer.write("fontsize='$baseFontSize*(1+0.12*sin(mod($tExpr,0.4)/0.4*3.14159))':");
      } else {
        buffer.write('fontsize=$baseFontSize:');
      }

      buffer.write('fontcolor=0x$fontColorHex:');

      // Background box styling
      if (cap.style.backgroundColor != null) {
        final bgHex = cap.style.backgroundColor!.toRadixString(16).padLeft(8, '0');
        final bgRgb = bgHex.length == 8 ? bgHex.substring(2) : bgHex;
        final bgAlpha = cap.style.backgroundColor! >> 24 & 0xFF;
        final bgOpacity = (bgAlpha / 255.0).clamp(0.1, 1.0).toStringAsFixed(2);
        final boxBorder = (cap.style.boxPadding * scale).round().clamp(4, 30);
        buffer.write('box=1:boxcolor=0x$bgRgb@$bgOpacity:boxborderw=$boxBorder:');
      }

      // Border / Stroke styling
      if (cap.style.strokeWidth > 0.0) {
        final strokeW = (cap.style.strokeWidth * scale).round().clamp(1, 30);
        buffer.write('borderw=$strokeW:');
        if (cap.style.strokeColor != null) {
          final sHex = cap.style.strokeColor!.toRadixString(16).padLeft(8, '0');
          final sRgb = sHex.length == 8 ? sHex.substring(2) : sHex;
          buffer.write('bordercolor=0x$sRgb:');
        }
      }

      // Shadow styling
      if (cap.style.shadowColor != null && cap.style.shadowBlur > 0.0) {
        final shHex = cap.style.shadowColor!.toRadixString(16).padLeft(8, '0');
        final shRgb = shHex.length == 8 ? shHex.substring(2) : shHex;
        final shOffset = (cap.style.shadowBlur * 0.3 * scale).round().clamp(1, 10);
        buffer.write('shadowcolor=0x$shRgb:shadowx=$shOffset:shadowy=$shOffset:');
      }

      buffer.write("enable='between(t,$startSec,$endSec)'");
      filters.add(buffer.toString());
    }

    return filters;
  }

  /// Generates Advanced SubStation Alpha (.ass) format with {\k...} karaoke tags
  static String generateAssSubtitles(
    List<CaptionLine> captions, {
    String title = 'Edito Kinetic Subtitles',
    int playResX = 1920,
    int playResY = 1080,
  }) {
    final buffer = StringBuffer();

    // 1. Script Info Header
    buffer.writeln('[Script Info]');
    buffer.writeln('Title: $title');
    buffer.writeln('ScriptType: v4.00+');
    buffer.writeln('WrapStyle: 0');
    buffer.writeln('PlayResX: $playResX');
    buffer.writeln('PlayResY: $playResY');
    buffer.writeln('ScaledBorderAndShadow: yes');
    buffer.writeln();

    // 2. Styles Header
    buffer.writeln('[V4+ Styles]');
    buffer.writeln('Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding');

    // Convert ARGB to ASS colour &HAABBGGRR
    String toAssColor(int argb) {
      final a = (255 - ((argb >> 24) & 0xFF)).toRadixString(16).padLeft(2, '0').toUpperCase();
      final r = ((argb >> 16) & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
      final g = ((argb >> 8) & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
      final b = (argb & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
      return '&H$a$b$g$r';
    }

    final primaryColor = captions.isNotEmpty ? toAssColor(captions.first.highlightColor) : '&H0000FFFF';
    final secondaryColor = captions.isNotEmpty ? toAssColor(captions.first.inactiveColor) : '&H00FFFFFF';
    final fontName = captions.isNotEmpty ? captions.first.style.fontFamily : 'Anton';
    final fontSize = captions.isNotEmpty ? captions.first.style.fontSize.round() : 32;

    buffer.writeln('Style: Default,$fontName,$fontSize,$primaryColor,$secondaryColor,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,2,2,2,10,10,35,1');
    buffer.writeln();

    // 3. Dialogue Events
    buffer.writeln('[Events]');
    buffer.writeln('Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');

    String formatAssTime(int ms) {
      final totalSec = ms ~/ 1000;
      final centis = ((ms % 1000) ~/ 10).toString().padLeft(2, '0');
      final s = (totalSec % 60).toString().padLeft(2, '0');
      final m = ((totalSec ~/ 60) % 60).toString().padLeft(2, '0');
      final h = (totalSec ~/ 3600).toString();
      return '$h:$m:$s.$centis';
    }

    for (final cap in captions) {
      if (cap.text.trim().isEmpty) continue;
      final start = formatAssTime(cap.startTimeMs);
      final end = formatAssTime(cap.endTimeMs);

      // Build karaoke string with {\k<centiseconds>} per word
      final words = cap.effectiveWords;
      final textBuffer = StringBuffer();

      if (cap.isKinetic && words.isNotEmpty) {
        for (final w in words) {
          final centis = (w.durationMs / 10).round().clamp(1, 999);
          final wordStr = cap.style.isUppercase ? w.word.toUpperCase() : w.word;
          textBuffer.write('{\\k$centis}$wordStr ');
        }
      } else {
        textBuffer.write(cap.text);
      }

      buffer.writeln('Dialogue: 0,$start,$end,Default,,0,0,0,,${textBuffer.toString().trim()}');
    }

    return buffer.toString();
  }

  /// Generates the floating HUD status badge for active subtitles
  static String getCaptionsBadge(List<CaptionLine> captions) {
    if (captions.isEmpty) return '';
    final count = captions.length;
    final isKinetic = captions.any((c) => c.isKinetic);
    return isKinetic ? '⚡ KINETIC CAPTIONS ($count)' : '💬 SUBTITLES ($count)';
  }
}
