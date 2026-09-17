import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/video_smoother_config.dart';

class MotionBlurPreviewWrapper extends StatelessWidget {
  final VideoSmootherConfig config;
  final Widget child;

  const MotionBlurPreviewWrapper({
    super.key,
    required this.config,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isMotionBlurEnabled &&
        config.effectiveInterpolationMode != MotionInterpolationMode.frameBlend) {
      return child;
    }

    final factor = (config.shutterAngle / 360.0).clamp(0.0, 1.0) * config.motionBlurIntensity;

    double sigmaX = 0.0;
    double sigmaY = 0.0;
    if (config.isMotionBlurEnabled) {
      switch (config.motionBlurDirection) {
        case MotionBlurDirection.omnidirectional:
          sigmaX = factor * 3.2;
          sigmaY = factor * 3.2;
          break;
        case MotionBlurDirection.horizontal:
          sigmaX = factor * 4.5;
          sigmaY = 0.0;
          break;
        case MotionBlurDirection.vertical:
          sigmaX = 0.0;
          sigmaY = factor * 4.5;
          break;
      }
    } else if (config.effectiveInterpolationMode == MotionInterpolationMode.frameBlend) {
      sigmaX = 1.2;
      sigmaY = 1.2;
    }

    final double ghostOpacity = (factor * 0.42).clamp(0.12, 0.48);

    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        if (sigmaX > 0.1 || sigmaY > 0.1)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: ghostOpacity,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: sigmaX,
                    sigmaY: sigmaY,
                    tileMode: TileMode.decal,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
