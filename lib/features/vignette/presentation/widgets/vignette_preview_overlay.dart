import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/vignette_config.dart';

/// Interactive Skia viewport overlay rendering real-time cinematic vignette and spotlight.
class VignettePreviewOverlay extends StatelessWidget {
  final VignetteConfig config;
  final bool showReticle;
  final ValueChanged<Offset>? onCenterChanged;

  const VignettePreviewOverlay({
    super.key,
    required this.config,
    this.showReticle = false,
    this.onCenterChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.hasActiveVignette && !showReticle) {
      return const SizedBox.shrink();
    }

    Widget content = CustomPaint(
      painter: _VignettePainter(
        config: config,
        showReticle: showReticle,
      ),
      size: Size.infinite,
    );

    if (showReticle && onCenterChanged != null) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          final size = renderBox.size;
          if (size.width <= 0 || size.height <= 0) return;

          final localPos = details.localPosition;
          // Map local coordinate to [-0.8, 0.8] normalized offset
          final normX = ((localPos.dx / size.width) - 0.5) * 2.0;
          final normY = ((localPos.dy / size.height) - 0.5) * 2.0;

          onCenterChanged!(Offset(
            normX.clamp(-0.8, 0.8),
            normY.clamp(-0.8, 0.8),
          ));
        },
        child: content,
      );
    }

    return IgnorePointer(child: content);
  }
}

class _VignettePainter extends CustomPainter {
  final VignetteConfig config;
  final bool showReticle;

  const _VignettePainter({
    required this.config,
    required this.showReticle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final focalCenter = Offset(
      size.width * (0.5 + (config.centerX * 0.5)),
      size.height * (0.5 + (config.centerY * 0.5)),
    );

    if (config.hasActiveVignette) {
      final maxDim = math.max(size.width, size.height);
      final double innerStop = (config.radius * 0.65).clamp(0.05, 0.85);
      final double outerRadius = maxDim * 0.85;

      final double alpha = config.intensity.abs().clamp(0.0, 1.0);
      final Color tintColor = config.tint.color;

      final gradient = RadialGradient(
        center: Alignment(
          config.centerX.clamp(-0.8, 0.8),
          config.centerY.clamp(-0.8, 0.8),
        ),
        radius: (outerRadius / maxDim) * (1.0 + (1.0 - config.feather) * 0.3),
        stops: [
          0.0,
          innerStop,
          (innerStop + (1.0 - innerStop) * 0.5).clamp(innerStop, 0.95),
          1.0,
        ],
        colors: [
          tintColor.withOpacity(0.0),
          tintColor.withOpacity(0.0),
          tintColor.withOpacity(alpha * 0.55),
          tintColor.withOpacity(alpha * 0.95),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..blendMode = config.intensity < 0 ? BlendMode.screen : BlendMode.multiply;

      canvas.save();

      // Apply elliptical deformation for roundness
      if (config.roundness != 0.0) {
        canvas.translate(focalCenter.dx, focalCenter.dy);
        if (config.roundness < 0) {
          // Horizontal anamorphic widescreen oval
          final sx = 1.0 + config.roundness.abs() * 0.65;
          canvas.scale(sx, 1.0);
        } else {
          // Vertical portrait oval
          final sy = 1.0 + config.roundness * 0.65;
          canvas.scale(1.0, sy);
        }
        canvas.translate(-focalCenter.dx, -focalCenter.dy);
      }

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      canvas.restore();
    }

    // Render interactive focal center crosshair reticle when in targeting mode
    if (showReticle) {
      _drawReticle(canvas, focalCenter);
    }
  }

  void _drawReticle(Canvas canvas, Offset center) {
    final ringPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final glowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw reticle ring & glow
    canvas.drawCircle(center, 22.0, glowPaint);
    canvas.drawCircle(center, 22.0, ringPaint);
    canvas.drawCircle(center, 4.0, dotPaint);

    // Crosshair ticks
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(center.dx - 32, center.dy), Offset(center.dx - 24, center.dy), linePaint);
    canvas.drawLine(Offset(center.dx + 24, center.dy), Offset(center.dx + 32, center.dy), linePaint);
    canvas.drawLine(Offset(center.dx, center.dy - 32), Offset(center.dx, center.dy - 24), linePaint);
    canvas.drawLine(Offset(center.dx, center.dy + 24), Offset(center.dx, center.dy + 32), linePaint);
  }

  @override
  bool shouldRepaint(covariant _VignettePainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.showReticle != showReticle;
  }
}
