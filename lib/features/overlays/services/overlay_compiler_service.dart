import '../../../models/clip.dart';
import '../models/text_overlay_config.dart';

class OverlayCompilerService {
  /// Evaluates animated text overlay parameters at a specific millisecond offset
  static TextOverlayConfig evaluateOverlayAt(Clip clip, int offsetMs) {
    var config = clip.textOverlay;
    if (clip.keyframes.isEmpty) return config;

    // Linear Keyframe Interpolation
    final kfs = List.from(clip.keyframes)..sort((a, b) => a.timeOffsetMs.compareTo(b.timeOffsetMs));
    if (offsetMs <= kfs.first.timeOffsetMs) {
      final k = kfs.first;
      return config.copyWith(
        positionX: k.positionX,
        positionY: k.positionY,
        scale: k.scale,
        rotation: k.rotation,
        opacity: k.opacity,
      );
    }

    if (offsetMs >= kfs.last.timeOffsetMs) {
      final k = kfs.last;
      return config.copyWith(
        positionX: k.positionX,
        positionY: k.positionY,
        scale: k.scale,
        rotation: k.rotation,
        opacity: k.opacity,
      );
    }

    for (int i = 1; i < kfs.length; i++) {
      final k0 = kfs[i - 1];
      final k1 = kfs[i];
      if (offsetMs >= k0.timeOffsetMs && offsetMs <= k1.timeOffsetMs) {
        final t = (offsetMs - k0.timeOffsetMs) / (k1.timeOffsetMs - k0.timeOffsetMs);
        return config.copyWith(
          positionX: k0.positionX + (t * (k1.positionX - k0.positionX)),
          positionY: k0.positionY + (t * (k1.positionY - k0.positionY)),
          scale: k0.scale + (t * (k1.scale - k0.scale)),
          rotation: k0.rotation + (t * (k1.rotation - k0.rotation)),
          opacity: k0.opacity + (t * (k1.opacity - k0.opacity)),
        );
      }
    }

    return config;
  }

  /// Generates the FFmpeg drawtext filter string for rendering text titles during export
  static String generateFFmpegDrawText(Clip clip, TextOverlayConfig config) {
    if (config.text.trim().isEmpty) return '';

    final sanitizedText = config.text.replaceAll("'", "\\'").replaceAll(':', '\\:');
    final startSec = (clip.startTimeMs / 1000.0).toStringAsFixed(2);
    final endSec = ((clip.startTimeMs + clip.durationMs) / 1000.0).toStringAsFixed(2);

    final size = config.fontSize.toInt();
    final xExpr = '(w-text_w)*${config.positionX.toStringAsFixed(2)}';
    final yExpr = '(h-text_h)*${config.positionY.toStringAsFixed(2)}';

    final filters = <String>[
      "drawtext=text='$sanitizedText'",
      "fontsize=$size",
      "fontcolor=white",
      "x=$xExpr",
      "y=$yExpr",
      "enable='between(t,$startSec,$endSec)'",
    ];

    if (config.backgroundColor != null) {
      filters.add("box=1:boxcolor=black@0.5:boxborderw=8");
    }

    return filters.join(':');
  }
}
