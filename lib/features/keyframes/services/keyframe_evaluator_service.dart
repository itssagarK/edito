import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import '../../overlays/models/keyframe.dart';

class TransformValues extends Equatable {
  final double positionX; // 0.0 to 1.0 (0.5 is center)
  final double positionY; // 0.0 to 1.0 (0.5 is center)
  final double scale; // 0.1 to 5.0 (1.0 is default)
  final double rotation; // -360.0 to +360.0 degrees
  final double opacity; // 0.0 to 1.0

  const TransformValues({
    this.positionX = 0.5,
    this.positionY = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
  });

  bool get isTransformed =>
      (positionX - 0.5).abs() > 0.001 ||
      (positionY - 0.5).abs() > 0.001 ||
      (scale - 1.0).abs() > 0.001 ||
      rotation.abs() > 0.1 ||
      opacity < 0.999;

  @override
  List<Object?> get props => [positionX, positionY, scale, rotation, opacity];
}

enum KeyframePreset {
  none,
  slowZoomIn,
  slowZoomOut,
  slideInFromLeft,
  spinAndPop,
  cinematicFade,
  dutchAngleRoll,
}

class KeyframeEvaluatorService {
  /// Evaluates smooth interpolated [TransformValues] at [offsetMs] based on active keyframes and easing curves.
  static TransformValues evaluateTransformAt(List<Keyframe> keyframes, int offsetMs) {
    if (keyframes.isEmpty) {
      return const TransformValues();
    }

    final kfs = List<Keyframe>.from(keyframes)..sort((a, b) => a.timeOffsetMs.compareTo(b.timeOffsetMs));

    if (offsetMs <= kfs.first.timeOffsetMs) {
      final k = kfs.first;
      return TransformValues(
        positionX: k.positionX,
        positionY: k.positionY,
        scale: k.scale,
        rotation: k.rotation,
        opacity: k.opacity,
      );
    }

    if (offsetMs >= kfs.last.timeOffsetMs) {
      final k = kfs.last;
      return TransformValues(
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
        final double dt = (k1.timeOffsetMs - k0.timeOffsetMs).toDouble();
        final double progress = dt > 0 ? (offsetMs - k0.timeOffsetMs) / dt : 1.0;
        final double easedT = k0.easing.evaluate(progress);

        return TransformValues(
          positionX: k0.positionX + ((k1.positionX - k0.positionX) * easedT),
          positionY: k0.positionY + ((k1.positionY - k0.positionY) * easedT),
          scale: k0.scale + ((k1.scale - k0.scale) * easedT),
          rotation: k0.rotation + ((k1.rotation - k0.rotation) * easedT),
          opacity: (k0.opacity + ((k1.opacity - k0.opacity) * easedT)).clamp(0.0, 1.0),
        );
      }
    }

    return const TransformValues();
  }

  /// Generates pre-configured one-tap dynamic animation keyframes for a clip of [durationMs].
  static List<Keyframe> generatePresetKeyframes(KeyframePreset preset, int durationMs) {
    final int dur = math.max(1000, durationMs);

    switch (preset) {
      case KeyframePreset.none:
        return [];

      case KeyframePreset.slowZoomIn:
        return [
          const Keyframe(timeOffsetMs: 0, scale: 1.0, easing: KeyframeEasing.easeInOut),
          Keyframe(timeOffsetMs: dur, scale: 1.25, easing: KeyframeEasing.easeInOut),
        ];

      case KeyframePreset.slowZoomOut:
        return [
          const Keyframe(timeOffsetMs: 0, scale: 1.25, easing: KeyframeEasing.easeInOut),
          Keyframe(timeOffsetMs: dur, scale: 1.0, easing: KeyframeEasing.easeInOut),
        ];

      case KeyframePreset.slideInFromLeft:
        final int inEnd = math.min(800, dur ~/ 3);
        return [
          const Keyframe(timeOffsetMs: 0, positionX: -0.2, easing: KeyframeEasing.easeOut),
          Keyframe(timeOffsetMs: inEnd, positionX: 0.5, easing: KeyframeEasing.easeOut),
          Keyframe(timeOffsetMs: dur, positionX: 0.5, easing: KeyframeEasing.easeOut),
        ];

      case KeyframePreset.spinAndPop:
        final int inEnd = math.min(900, dur ~/ 3);
        return [
          const Keyframe(timeOffsetMs: 0, scale: 0.2, rotation: -180.0, opacity: 0.0, easing: KeyframeEasing.bounce),
          Keyframe(timeOffsetMs: inEnd, scale: 1.0, rotation: 0.0, opacity: 1.0, easing: KeyframeEasing.easeInOut),
          Keyframe(timeOffsetMs: dur, scale: 1.0, rotation: 0.0, opacity: 1.0, easing: KeyframeEasing.easeInOut),
        ];

      case KeyframePreset.cinematicFade:
        final int fadeTime = math.min(600, dur ~/ 4);
        return [
          const Keyframe(timeOffsetMs: 0, opacity: 0.0, easing: KeyframeEasing.easeIn),
          Keyframe(timeOffsetMs: fadeTime, opacity: 1.0, easing: KeyframeEasing.linear),
          Keyframe(timeOffsetMs: dur - fadeTime, opacity: 1.0, easing: KeyframeEasing.easeOut),
          Keyframe(timeOffsetMs: dur, opacity: 0.0, easing: KeyframeEasing.easeOut),
        ];

      case KeyframePreset.dutchAngleRoll:
        return [
          const Keyframe(timeOffsetMs: 0, rotation: -6.0, scale: 1.08, easing: KeyframeEasing.easeInOut),
          Keyframe(timeOffsetMs: dur ~/ 2, rotation: 6.0, scale: 1.08, easing: KeyframeEasing.easeInOut),
          Keyframe(timeOffsetMs: dur, rotation: -6.0, scale: 1.08, easing: KeyframeEasing.easeInOut),
        ];
    }
  }

  /// Builds a piecewise linear time-dependent string expression for FFmpeg filter evaluation.
  static String buildInterpolatedFFmpegExpr(
    List<Keyframe> kfs,
    double Function(Keyframe) getter,
    String tExpr,
    double fallback,
  ) {
    if (kfs.isEmpty) return fallback.toStringAsFixed(3);
    if (kfs.length == 1) return getter(kfs.first).toStringAsFixed(3);

    final sorted = List<Keyframe>.from(kfs)..sort((a, b) => a.timeOffsetMs.compareTo(b.timeOffsetMs));

    String expr = getter(sorted.last).toStringAsFixed(3);
    for (int i = sorted.length - 2; i >= 0; i--) {
      final k0 = sorted[i];
      final k1 = sorted[i + 1];
      final t0 = (k0.timeOffsetMs / 1000.0).toStringAsFixed(3);
      final t1 = (k1.timeOffsetMs / 1000.0).toStringAsFixed(3);
      final v0 = getter(k0).toStringAsFixed(3);
      final v1 = getter(k1).toStringAsFixed(3);
      final dt = ((k1.timeOffsetMs - k0.timeOffsetMs) / 1000.0);
      final dtStr = dt > 0 ? dt.toStringAsFixed(3) : '1.0';

      final lerp = '$v0+($v1-$v0)*($tExpr-$t0)/$dtStr';
      expr = 'if(lt($tExpr,$t1),$lerp,$expr)';
    }

    final firstT0 = (sorted.first.timeOffsetMs / 1000.0).toStringAsFixed(3);
    final firstV0 = getter(sorted.first).toStringAsFixed(3);
    return 'if(lt($tExpr,$firstT0),$firstV0,$expr)';
  }

  /// Generates FFmpeg in-stream video filters for animated opacity, rotation, and scale transformations.
  static List<String> generateFFmpegTransformFilters(
    List<Keyframe> keyframes, {
    required int clipDurationMs,
    required int targetWidth,
    required int targetHeight,
  }) {
    if (keyframes.isEmpty) return [];

    final filters = <String>[];
    const tExpr = 't';

    // 1. Opacity Animation
    final hasAnimatedOpacity = keyframes.any((k) => (k.opacity - 1.0).abs() > 0.01);
    if (hasAnimatedOpacity) {
      final opacityExpr = buildInterpolatedFFmpegExpr(keyframes, (k) => k.opacity, tExpr, 1.0);
      filters.add('format=yuva420p');
      filters.add("colorchannelmixer=aa='$opacityExpr'");
    }

    // 2. Rotation Animation
    final hasAnimatedRotation = keyframes.any((k) => k.rotation.abs() > 0.1);
    if (hasAnimatedRotation) {
      final rotExpr = buildInterpolatedFFmpegExpr(keyframes, (k) => k.rotation * math.pi / 180.0, tExpr, 0.0);
      filters.add("rotate='$rotExpr':ow=rotw(iw):oh=roth(ih):c=none");
    }

    return filters;
  }
}
