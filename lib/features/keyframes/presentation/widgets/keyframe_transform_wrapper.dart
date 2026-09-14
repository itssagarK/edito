import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../models/clip.dart';
import '../../services/keyframe_evaluator_service.dart';

class KeyframeTransformWrapper extends StatelessWidget {
  final Clip clip;
  final int clipOffsetMs;
  final Widget child;

  const KeyframeTransformWrapper({
    super.key,
    required this.clip,
    required this.clipOffsetMs,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (clip.keyframes.isEmpty) return child;

    final values = KeyframeEvaluatorService.evaluateTransformAt(
      clip.keyframes,
      clipOffsetMs,
    );

    if (!values.isTransformed) return child;

    Widget content = child;

    // 1. Animated Opacity
    if (values.opacity < 0.999) {
      content = Opacity(
        opacity: values.opacity.clamp(0.0, 1.0),
        child: content,
      );
    }

    // 2. Animated Rotation
    if (values.rotation.abs() > 0.1) {
      content = Transform.rotate(
        angle: values.rotation * math.pi / 180.0,
        child: content,
      );
    }

    // 3. Animated Scale & Alignment
    if ((values.scale - 1.0).abs() > 0.005) {
      final double alignX = ((values.positionX - 0.5) * 2.0).clamp(-1.0, 1.0);
      final double alignY = ((values.positionY - 0.5) * 2.0).clamp(-1.0, 1.0);
      content = Transform.scale(
        scale: values.scale.clamp(0.1, 5.0),
        alignment: Alignment(alignX, alignY),
        child: content,
      );
    }

    // 4. Animated Position Translation
    if ((values.positionX - 0.5).abs() > 0.005 || (values.positionY - 0.5).abs() > 0.005) {
      content = FractionalTranslation(
        translation: Offset(values.positionX - 0.5, values.positionY - 0.5),
        child: content,
      );
    }

    return ClipRect(child: content);
  }
}
