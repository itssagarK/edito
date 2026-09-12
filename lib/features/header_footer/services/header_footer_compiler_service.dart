import '../models/header_footer_config.dart';

class HeaderFooterCompilerService {
  /// Compiles HeaderFooterConfig into high-performance FFmpeg video filter commands
  static String generateFFmpegFilter(
    HeaderFooterConfig config, {
    required int clipDurationMs,
    required int targetWidth,
    required int targetHeight,
    int referenceHeight = 720,
  }) {
    if (!config.hasActiveOverlay) return '';

    final scale = targetHeight / referenceHeight;
    final filters = <String>[];

    // 1. Header Banner & Text
    if (config.isHeaderEnabled && config.headerText.trim().isNotEmpty) {
      final hHeight = (config.headerHeight * scale).round().clamp(16, 400);
      final bgHex = _toFFmpegColor(config.headerBackgroundColor);
      final bgAlpha = (((config.headerBackgroundColor >> 24) & 0xFF) / 255.0).clamp(0.0, 1.0);

      // Header background banner box
      filters.add('drawbox=x=0:y=0:w=$targetWidth:h=$hHeight:color=$bgHex@${bgAlpha.toStringAsFixed(2)}:t=fill');

      // Accent bottom line for header
      if (config.headerStyle == HeaderFooterStyle.neonAccent) {
        filters.add('drawbox=x=0:y=${hHeight - 3}:w=$targetWidth:h=3:color=0x00E5FF@0.90:t=fill');
      }

      // Header text
      final rawText = config.isHeaderUppercase ? config.headerText.toUpperCase() : config.headerText;
      final fullHeader = config.headerEmoji.isNotEmpty ? '${config.headerEmoji} $rawText' : rawText;
      final sanitizedHeader = fullHeader.replaceAll("'", "\\'").replaceAll(':', '\\:');
      final fontSize = (config.headerFontSize * scale).round().clamp(8, 300);
      final textColorHex = _toFFmpegColor(config.headerTextColor);

      String yPos = '(($hHeight-text_h)/2)';
      if (config.headerAnimation == HeaderFooterAnim.slideIn) {
        yPos = "if(lt(t,0.3),-$hHeight+(t/0.3)*($hHeight),($hHeight-text_h)/2)";
      }

      filters.add("drawtext=text='$sanitizedHeader':x=(w-text_w)/2:y='$yPos':fontsize=$fontSize:fontcolor=$textColorHex:shadowcolor=black@0.6:shadowx=1:shadowy=1");
    }

    // 2. Footer Banner & Text
    if (config.isFooterEnabled && config.footerText.trim().isNotEmpty) {
      final fHeight = (config.footerHeight * scale).round().clamp(16, 400);
      final bgHex = _toFFmpegColor(config.footerBackgroundColor);
      final bgAlpha = (((config.footerBackgroundColor >> 24) & 0xFF) / 255.0).clamp(0.0, 1.0);
      final yBox = targetHeight - fHeight;

      // Footer background banner box
      filters.add('drawbox=x=0:y=$yBox:w=$targetWidth:h=$fHeight:color=$bgHex@${bgAlpha.toStringAsFixed(2)}:t=fill');

      // Accent top line for footer
      if (config.footerStyle == HeaderFooterStyle.neonAccent) {
        filters.add('drawbox=x=0:y=$yBox:w=$targetWidth:h=3:color=0x00E5FF@0.90:t=fill');
      }

      // Footer text
      final rawText = config.isFooterUppercase ? config.footerText.toUpperCase() : config.footerText;
      final fullFooter = config.footerIcon.isNotEmpty ? '${config.footerIcon} $rawText' : rawText;
      final sanitizedFooter = fullFooter.replaceAll("'", "\\'").replaceAll(':', '\\:');
      final fontSize = (config.footerFontSize * scale).round().clamp(8, 250);
      final textColorHex = _toFFmpegColor(config.footerTextColor);

      String yPos = "h-$fHeight+(($fHeight-text_h)/2)";
      if (config.footerAnimation == HeaderFooterAnim.slideIn) {
        yPos = "if(lt(t,0.3),h-(t/0.3)*($fHeight),h-$fHeight+(($fHeight-text_h)/2))";
      }

      filters.add("drawtext=text='$sanitizedFooter':x=(w-text_w)/2:y='$yPos':fontsize=$fontSize:fontcolor=$textColorHex:shadowcolor=black@0.6:shadowx=1:shadowy=1");
    }

    return filters.join(',');
  }

  static String _toFFmpegColor(int argb) {
    final rgb = argb & 0x00FFFFFF;
    return '0x${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Formats HUD badge for realtime preview viewport
  static String getHeaderFooterBadge(HeaderFooterConfig config) {
    if (!config.hasActiveOverlay) return '';
    if (config.isHeaderEnabled && config.isFooterEnabled) {
      return '📌 HEADER & FOOTER ACTIVE';
    } else if (config.isHeaderEnabled) {
      return '📌 TOP HEADER ACTIVE';
    } else {
      return '📌 BOTTOM FOOTER ACTIVE';
    }
  }
}
