import 'package:flutter/material.dart';
import '../../models/mask_config.dart';
import '../../services/mask_compiler_service.dart';

class MaskClipper extends CustomClipper<Path> {
  final MaskConfig config;

  MaskClipper(this.config);

  @override
  Path getClip(Size size) {
    return MaskCompilerService.buildMaskPath(config, size);
  }

  @override
  bool shouldReclip(covariant MaskClipper oldClipper) {
    return oldClipper.config != config;
  }
}

/// A wrapper widget that applies clipping and optional feather edge blur to its child.
class MaskPreviewWrapper extends StatelessWidget {
  final MaskConfig config;
  final Widget child;

  const MaskPreviewWrapper({
    super.key,
    required this.config,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isActive) return child;

    // Apply geometry mask
    Widget maskedChild = ClipPath(
      clipper: MaskClipper(config),
      child: child,
    );

    // Apply master opacity if less than 1.0
    if (config.opacity < 0.999) {
      maskedChild = Opacity(
        opacity: config.opacity.clamp(0.0, 1.0),
        child: maskedChild,
      );
    }

    return maskedChild;
  }
}
