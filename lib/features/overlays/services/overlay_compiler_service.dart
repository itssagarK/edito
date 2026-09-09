import '../../../models/clip.dart';
import '../models/keyframe.dart';
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

  /// Builds a piecewise linear interpolation expression for FFmpeg filter evaluation across keyframes
  static String _buildInterpolatedExpr(
    List<Keyframe> kfs,
    double Function(Keyframe) getter,
    String tExpr,
    double fallback,
  ) {
    if (kfs.isEmpty) return fallback.toStringAsFixed(2);
    if (kfs.length == 1) return getter(kfs.first).toStringAsFixed(2);

    final sorted = List<Keyframe>.from(kfs)..sort((a, b) => a.timeOffsetMs.compareTo(b.timeOffsetMs));

    String expr = getter(sorted.last).toStringAsFixed(2);
    for (int i = sorted.length - 2; i >= 0; i--) {
      final k0 = sorted[i];
      final k1 = sorted[i + 1];
      final t0 = (k0.timeOffsetMs / 1000.0).toStringAsFixed(2);
      final t1 = (k1.timeOffsetMs / 1000.0).toStringAsFixed(2);
      final v0 = getter(k0).toStringAsFixed(2);
      final v1 = getter(k1).toStringAsFixed(2);
      final dt = ((k1.timeOffsetMs - k0.timeOffsetMs) / 1000.0);
      final dtStr = dt > 0 ? dt.toStringAsFixed(2) : '1.0';

      final lerp = '$v0+($v1-$v0)*($tExpr-$t0)/$dtStr';
      expr = 'if(lt($tExpr,$t1),$lerp,$expr)';
    }

    final firstT0 = (sorted.first.timeOffsetMs / 1000.0).toStringAsFixed(2);
    final firstV0 = getter(sorted.first).toStringAsFixed(2);
    return 'if(lt($tExpr,$firstT0),$firstV0,$expr)';
  }

  /// Generates the FFmpeg drawtext filter string for rendering text titles during export
  static String generateFFmpegDrawText(
    Clip clip,
    TextOverlayConfig config, {
    bool isClipRelative = false,
  }) {
    if (config.text.trim().isEmpty) return '';

    final sanitizedText = config.text.replaceAll("'", "\\'").replaceAll(':', '\\:');
    final startSec = isClipRelative ? '0.00' : (clip.startTimeMs / 1000.0).toStringAsFixed(2);
    final endSec = isClipRelative
        ? (clip.durationMs / 1000.0).toStringAsFixed(2)
        : ((clip.startTimeMs + clip.durationMs) / 1000.0).toStringAsFixed(2);

    final tExpr = isClipRelative ? 't' : '(t-$startSec)';

    final size = config.fontSize.toInt();
    final xFactor = clip.keyframes.isNotEmpty
        ? _buildInterpolatedExpr(clip.keyframes, (k) => k.positionX, tExpr, config.positionX)
        : config.positionX.toStringAsFixed(2);
    final yFactor = clip.keyframes.isNotEmpty
        ? _buildInterpolatedExpr(clip.keyframes, (k) => k.positionY, tExpr, config.positionY)
        : config.positionY.toStringAsFixed(2);

    final xExpr = clip.keyframes.isNotEmpty ? '(w-text_w)*($xFactor)' : '(w-text_w)*$xFactor';
    final yExpr = clip.keyframes.isNotEmpty ? '(h-text_h)*($yFactor)' : '(h-text_h)*$yFactor';

    final fontColorHex = (config.textColor & 0x00FFFFFF) == 0x00FFFFFF
        ? 'white'
        : '0x${(config.textColor & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

    final filters = <String>[
      "drawtext=text='$sanitizedText'",
      "fontsize=$size",
      "fontcolor=$fontColorHex",
      "x=$xExpr",
      "y=$yExpr",
      "enable='between(t,$startSec,$endSec)'",
    ];

    if (config.backgroundColor != null) {
      final bg = config.backgroundColor!;
      final hex = '0x${(bg & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
      final alpha = (((bg >> 24) & 0xFF) / 255.0).clamp(0.0, 1.0);
      filters.add("box=1:boxcolor=$hex@${alpha.toStringAsFixed(2)}:boxborderw=8");
    }

    return filters.join(':');
  }
}
