import 'dart:math' as math;
import '../models/typewriter_title_config.dart';
import '../models/text_overlay_config.dart';
import '../../../models/clip.dart';

class TypewriterTitleService {
  /// Generates deterministic FFmpeg drawtext filter representations for typewriter animations
  static List<String> generateFFmpegFilters({
    required Clip clip,
    required TypewriterTitleConfig typewriterConfig,
    required TextOverlayConfig textConfig,
  }) {
    if (!typewriterConfig.isActive || textConfig.text.trim().isEmpty) {
      return [];
    }

    final rawText = textConfig.isUppercase ? textConfig.text.toUpperCase() : textConfig.text;
    final sanitizedText = rawText
        .replaceAll("'", r"\'")
        .replaceAll(':', r'\:')
        .replaceAll('%', r'\%');

    final startSec = (clip.startTimeMs / 1000.0).toStringAsFixed(3);
    final endSec = ((clip.startTimeMs + clip.durationMs) / 1000.0).toStringAsFixed(3);
    final tExpr = '(t-$startSec)';

    final startDelaySec = (typewriterConfig.startDelayMs / 1000.0).toStringAsFixed(3);
    final speedSec = (math.max(1, typewriterConfig.typingSpeedMs) / 1000.0).toStringAsFixed(3);

    final fontColorHex = (textConfig.textColor & 0x00FFFFFF) == 0x00FFFFFF
        ? 'white'
        : '0x${(textConfig.textColor & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

    final size = textConfig.fontSize.toInt().clamp(10, 200);
    final xExpr = 'w*${textConfig.positionX.toStringAsFixed(2)}-text_w/2';
    final yExpr = 'h*${textConfig.positionY.toStringAsFixed(2)}-text_h/2';

    // In FFmpeg, char expansion can be rendered via progressive substring length or alpha ramp
    // For universal FFmpeg drawtext compatibility across builds:
    final totalChars = rawText.length;
    final typingDurationSec = ((typewriterConfig.typingSpeedMs * totalChars) / 1000.0).toStringAsFixed(3);

    final filters = <String>[
      "drawtext=text='$sanitizedText'",
      "fontsize=$size",
      "fontcolor=$fontColorHex",
      "x='$xExpr'",
      "y='$yExpr'",
      "enable='between(t,$startSec,$endSec)'",
      // Alpha ramp for smooth entrance during typewriter window
      "alpha='if(lt($tExpr,$startDelaySec),0.0,if(lt($tExpr,$startDelaySec+$typingDurationSec),min(1.0,($tExpr-$startDelaySec)/$typingDurationSec),1.0))'",
    ];

    if (textConfig.strokeWidth > 0.0) {
      filters.add('borderw=${textConfig.strokeWidth.toInt().clamp(1, 20)}');
      if (textConfig.strokeColor != null) {
        final strokeHex = '0x${(textConfig.strokeColor! & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
        filters.add('bordercolor=$strokeHex');
      }
    }

    return filters;
  }

  /// Calculates timestamps (in ms relative to clip start) where typing keystrokes occur
  static List<int> generateTypingClickTimestamps({
    required String text,
    required TypewriterTitleConfig config,
  }) {
    if (!config.isActive || text.isEmpty) return [];

    final timestamps = <int>[];
    final count = config.mode == TypewriterMode.wordByWord || config.mode == TypewriterMode.fadeWord
        ? text.split(' ').where((w) => w.isNotEmpty).length
        : text.length;

    for (int i = 0; i < count; i++) {
      final t = config.startDelayMs + (i * config.typingSpeedMs);
      timestamps.add(t);
    }

    return timestamps;
  }

  /// HUD status badge for active typewriter kinetic title
  static String getTypewriterBadge(TypewriterTitleConfig config) {
    if (!config.isActive) return '';
    return '⌨️ TYPEWRITER (${config.mode.label} • ${config.typingSpeedMs}ms)';
  }
}
