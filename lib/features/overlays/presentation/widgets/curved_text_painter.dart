import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/text_overlay_config.dart';

/// CapCut-grade Curved Text Painter
/// Mathematically deforms and rotates each glyph along an arc with precision tangent angles
class CurvedTextPainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final double curveAngle; // -180.0 to 180.0 degrees
  final double strokeWidth;
  final Color? strokeColor;
  final Color? glowColor;
  final double glowRadius;
  final double glowIntensity;
  final List<Shadow> shadows;

  CurvedTextPainter({
    required this.text,
    required this.style,
    required this.curveAngle,
    this.strokeWidth = 0.0,
    this.strokeColor,
    this.glowColor,
    this.glowRadius = 0.0,
    this.glowIntensity = 0.0,
    this.shadows = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty) return;

    final characters = text.characters.toList();
    if (characters.isEmpty) return;

    // Measure each character individually to compute arc spacing
    final charPainters = <TextPainter>[];
    double totalWidth = 0.0;
    double maxHeight = 0.0;

    for (final char in characters) {
      final tp = TextPainter(
        text: TextSpan(text: char, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      charPainters.add(tp);
      totalWidth += tp.width;
      if (tp.height > maxHeight) maxHeight = tp.height;
    }

    if (totalWidth <= 0) return;

    // Straight rendering fallback if curve is effectively 0
    if (curveAngle.abs() < 1.0) {
      double currentX = (size.width - totalWidth) / 2;
      final startY = (size.height - maxHeight) / 2;
      for (final tp in charPainters) {
        _paintGlyph(canvas, tp, currentX, startY);
        currentX += tp.width;
      }
      return;
    }

    // Arc Mathematics (Circular Arc & Tangent Deformation)
    final double arcAngleRad = (curveAngle.clamp(-180.0, 180.0)) * (math.pi / 180.0);
    final double radius = (totalWidth / arcAngleRad.abs()).clamp(10.0, 10000.0);
    final bool isConvex = curveAngle > 0; // Arching upwards

    final double centerX = size.width / 2;
    final double centerY = isConvex
        ? (size.height / 2) + radius - (maxHeight / 2)
        : (size.height / 2) - radius + (maxHeight / 2);

    double currentDist = -totalWidth / 2;

    for (final tp in charPainters) {
      final double charMidDist = currentDist + (tp.width / 2);
      final double charAngle = (charMidDist / totalWidth) * arcAngleRad;

      double glyphX;
      double glyphY;
      double tangentRotation;

      if (isConvex) {
        // Arching upwards
        glyphX = centerX + radius * math.sin(charAngle);
        glyphY = centerY - radius * math.cos(charAngle);
        tangentRotation = charAngle;
      } else {
        // Arching downwards (Smile curve)
        glyphX = centerX + radius * math.sin(charAngle);
        glyphY = centerY + radius * math.cos(charAngle);
        tangentRotation = -charAngle;
      }

      canvas.save();
      canvas.translate(glyphX, glyphY);
      canvas.rotate(tangentRotation);
      canvas.translate(-tp.width / 2, -tp.height / 2);

      _paintGlyph(canvas, tp, 0, 0);

      canvas.restore();
      currentDist += tp.width;
    }
  }

  void _paintGlyph(Canvas canvas, TextPainter fillPainter, double x, double y) {
    // 1. Outer Glow / Neon Halo
    if (glowColor != null && glowRadius > 0.0) {
      final glowPaint = Paint()
        ..color = glowColor!.withOpacity((glowIntensity * 0.8).clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);

      final glowTp = TextPainter(
        text: TextSpan(
          text: fillPainter.text!.toPlainText(),
          style: style.copyWith(
            foreground: glowPaint,
            shadows: [],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      glowTp.paint(canvas, Offset(x, y));
    }

    // 2. Stroke Outline Layer
    if (strokeWidth > 0.0 && strokeColor != null) {
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2
        ..strokeJoin = StrokeJoin.round
        ..color = strokeColor!;

      final strokeTp = TextPainter(
        text: TextSpan(
          text: fillPainter.text!.toPlainText(),
          style: style.copyWith(
            foreground: strokePaint,
            shadows: [],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      strokeTp.paint(canvas, Offset(x, y));
    }

    // 3. Foreground Fill with Shadows
    final fillWithShadows = TextPainter(
      text: TextSpan(
        text: fillPainter.text!.toPlainText(),
        style: style.copyWith(shadows: shadows),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    fillWithShadows.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant CurvedTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.style != style ||
        oldDelegate.curveAngle != curveAngle ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.glowRadius != glowRadius ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.shadows != shadows;
  }
}

/// Convenience Widget to render Curved & Glow Text with automatic sizing
class CurvedTextWidget extends StatelessWidget {
  final TextOverlayConfig config;
  final TextStyle baseStyle;
  final String displayText;

  const CurvedTextWidget({
    super.key,
    required this.config,
    required this.baseStyle,
    required this.displayText,
  });

  @override
  Widget build(BuildContext context) {
    // If no curve angle, use standard Flutter text rendering for maximum performance
    if (config.curveAngle.abs() < 1.0) {
      final shadows = <Shadow>[
        if (config.glowColor != null && config.glowRadius > 0.0)
          Shadow(
            color: Color(config.glowColor!).withOpacity(config.glowIntensity.clamp(0.0, 1.0)),
            blurRadius: config.glowRadius,
            offset: Offset.zero,
          ),
        if (config.shadowColor != null)
          Shadow(
            color: Color(config.shadowColor!),
            blurRadius: config.shadowBlur,
            offset: Offset(config.shadowOffsetX, config.shadowOffsetY),
          )
        else
          Shadow(
            color: Colors.black87,
            blurRadius: 4,
            offset: Offset(config.shadowOffsetX, config.shadowOffsetY),
          ),
      ];

      if (config.strokeWidth > 0.0 && config.strokeColor != null) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Stroke Layer
            Text(
              displayText,
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = config.strokeWidth * 2
                  ..strokeJoin = StrokeJoin.round
                  ..color = Color(config.strokeColor!),
              ),
            ),
            // Foreground Fill
            Text(
              displayText,
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(
                color: Color(config.textColor),
                shadows: shadows,
              ),
            ),
          ],
        );
      }

      return Text(
        displayText,
        textAlign: TextAlign.center,
        style: baseStyle.copyWith(
          color: Color(config.textColor),
          shadows: shadows,
        ),
      );
    }

    // Curved Text Arc Calculation Bounds
    final tp = TextPainter(
      text: TextSpan(text: displayText, style: baseStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final double width = tp.width + (config.boxPadding * 2) + 40.0;
    final double arcHeight = (width * 0.45).clamp(tp.height + 20.0, 240.0);

    final shadows = <Shadow>[
      if (config.shadowColor != null)
        Shadow(
          color: Color(config.shadowColor!),
          blurRadius: config.shadowBlur,
          offset: Offset(config.shadowOffsetX, config.shadowOffsetY),
        ),
    ];

    return SizedBox(
      width: width,
      height: arcHeight,
      child: CustomPaint(
        painter: CurvedTextPainter(
          text: displayText,
          style: baseStyle.copyWith(color: Color(config.textColor)),
          curveAngle: config.curveAngle,
          strokeWidth: config.strokeWidth,
          strokeColor: config.strokeColor != null ? Color(config.strokeColor!) : null,
          glowColor: config.glowColor != null ? Color(config.glowColor!) : null,
          glowRadius: config.glowRadius,
          glowIntensity: config.glowIntensity,
          shadows: shadows,
        ),
      ),
    );
  }
}
