import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/smart_cutout_config.dart';
import '../../services/smart_cutout_compiler_service.dart';

class SmartCutoutPreviewWrapper extends StatelessWidget {
  final SmartCutoutConfig config;
  final Widget child;

  const SmartCutoutPreviewWrapper({
    super.key,
    required this.config,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isEnabled || config.type == CutoutType.none) {
      return child;
    }

    Widget content = child;

    // Apply Skia matrix for ambient neon lighting
    final matrix = SmartCutoutCompilerService.generatePreviewMatrix(config);
    content = ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix),
      child: content,
    );

    // Apply Inversion if requested
    if (config.isInverted) {
      content = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1,   0,
        ]),
        child: content,
      );
    }

    // Compose Background & Glowing Stroke Outline
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.passthrough,
          children: [
            // 1. Background Layer
            if (config.backgroundMode == CutoutBackgroundMode.blur)
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: config.backgroundBlur.clamp(0.0, 30.0),
                    sigmaY: config.backgroundBlur.clamp(0.0, 30.0),
                  ),
                  child: child,
                ),
              )
            else if (config.backgroundMode == CutoutBackgroundMode.solidColor)
              Positioned.fill(
                child: Container(
                  color: Color(config.backgroundColorValue),
                ),
              ),

            // 2. Foreground Cutout Subject
            content,

            // 3. Glowing Neon Stroke Aura Overlay
            if (config.strokeStyle != CutoutStrokeStyle.none)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _NeonCutoutStrokePainter(
                      config: config,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NeonCutoutStrokePainter extends CustomPainter {
  final SmartCutoutConfig config;

  _NeonCutoutStrokePainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor = Color(config.strokeColorValue);
    final rect = Rect.fromLTWH(
      size.width * 0.12,
      size.height * 0.08,
      size.width * 0.76,
      size.height * 0.84,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.22));

    if (config.strokeStyle == CutoutStrokeStyle.solidBorder) {
      final solidPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = config.strokeWidth.clamp(1.0, 20.0);
      canvas.drawRRect(rrect, solidPaint);
      return;
    }

    if (config.strokeStyle == CutoutStrokeStyle.dashedSticker) {
      final dashPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = config.strokeWidth.clamp(1.0, 15.0);
      canvas.drawRRect(rrect, dashPaint);
      return;
    }

    // Glowing Neon Aura (Multiple Gaussian Blur Passes)
    final glowPaint = Paint()
      ..color = strokeColor.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (config.strokeWidth + 4.0).clamp(2.0, 25.0)
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, config.glowSpread.clamp(2.0, 30.0));

    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (config.strokeWidth * 0.6).clamp(1.0, 10.0);

    final auraPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.strokeWidth.clamp(1.0, 20.0);

    // Draw ambient neon outer aura
    canvas.drawRRect(rrect, glowPaint);
    // Draw colored stroke
    canvas.drawRRect(rrect, auraPaint);
    // Draw bright inner neon core
    canvas.drawRRect(rrect, corePaint);
  }

  @override
  bool shouldRepaint(covariant _NeonCutoutStrokePainter oldDelegate) {
    return oldDelegate.config != config;
  }
}
