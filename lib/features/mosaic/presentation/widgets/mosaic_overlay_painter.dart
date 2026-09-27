import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/mosaic_config.dart';
import '../../services/mosaic_compiler_service.dart';

class MosaicOverlayPainter extends CustomPainter {
  final MosaicConfig config;
  final bool showHandles;

  const MosaicOverlayPainter({
    required this.config,
    this.showHandles = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!config.isActive) return;

    final path = MosaicCompilerService.buildMosaicPath(config, size);

    // Save canvas state before clipping
    canvas.save();
    canvas.clipPath(path);

    // Render simulated blur/mosaic effect fill inside clipped path
    final Rect bounds = path.getBounds();
    final double masterOpacity = config.opacity.clamp(0.0, 1.0);

    switch (config.type) {
      case MosaicType.pixelMosaic:
        _paintPixelGrid(canvas, bounds, masterOpacity);
        break;

      case MosaicType.gaussianBlur:
        _paintGaussianBlurSim(canvas, bounds, masterOpacity);
        break;

      case MosaicType.hexagonalCrystal:
        _paintHexagonalCrystal(canvas, bounds, masterOpacity);
        break;

      case MosaicType.frostedGlass:
        _paintFrostedGlass(canvas, bounds, masterOpacity);
        break;

      case MosaicType.none:
        break;
    }

    // Restore canvas after clipped drawing
    canvas.restore();

    // Draw interactive handles if enabled and not full frame
    if (showHandles && config.shape != MosaicShape.fullFrame) {
      _paintInteractiveOutline(canvas, size);
    }
  }

  void _paintPixelGrid(Canvas canvas, Rect bounds, double opacity) {
    final double step = math.max(6.0, config.pixelSize * 0.75);
    final paintEven = Paint()
      ..color = const Color(0xFF202020).withOpacity(0.85 * opacity)
      ..style = PaintingStyle.fill;
    final paintOdd = Paint()
      ..color = const Color(0xFF4A4A4A).withOpacity(0.85 * opacity)
      ..style = PaintingStyle.fill;
    final gridLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.12 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    int col = 0;
    for (double x = bounds.left; x < bounds.right; x += step) {
      int row = 0;
      for (double y = bounds.top; y < bounds.bottom; y += step) {
        final block = Rect.fromLTWH(
          x,
          y,
          math.min(step, bounds.right - x),
          math.min(step, bounds.bottom - y),
        );
        canvas.drawRect(block, (col + row) % 2 == 0 ? paintEven : paintOdd);
        canvas.drawRect(block, gridLinePaint);
        row++;
      }
      col++;
    }
  }

  void _paintGaussianBlurSim(Canvas canvas, Rect bounds, double opacity) {
    final paint = Paint()
      ..color = const Color(0xFF1E1E24).withOpacity(0.88 * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.blurRadius * 0.35);
    canvas.drawRect(bounds, paint);

    // Subtle milky privacy tint
    final tintPaint = Paint()
      ..color = Colors.white.withOpacity(0.10 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRect(bounds, tintPaint);
  }

  void _paintHexagonalCrystal(Canvas canvas, Rect bounds, double opacity) {
    final double hexSize = math.max(8.0, config.pixelSize);
    final hexPaint = Paint()
      ..color = const Color(0xFF182230).withOpacity(0.82 * opacity)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF00F0FF).withOpacity(0.25 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(bounds, hexPaint);

    for (double y = bounds.top; y < bounds.bottom + hexSize; y += hexSize * 1.5) {
      for (double x = bounds.left; x < bounds.right + hexSize; x += hexSize * 1.732) {
        final Path hex = Path();
        for (int i = 0; i < 6; i++) {
          final double angle = 2.0 * math.pi / 6.0 * i;
          final double hx = x + hexSize * math.cos(angle);
          final double hy = y + hexSize * math.sin(angle);
          if (i == 0) {
            hex.moveTo(hx, hy);
          } else {
            hex.lineTo(hx, hy);
          }
        }
        hex.close();
        canvas.drawPath(hex, borderPaint);
      }
    }
  }

  void _paintFrostedGlass(Canvas canvas, Rect bounds, double opacity) {
    final frostPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.22 * opacity),
          const Color(0xFF1E293B).withOpacity(0.75 * opacity),
          Colors.white.withOpacity(0.15 * opacity),
        ],
      ).createShader(bounds);
    canvas.drawRect(bounds, frostPaint);
  }

  void _paintInteractiveOutline(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w * config.centerX;
    final double cy = h * config.centerY;
    final double rx = math.max(8.0, (w * config.width * 0.5));
    final double ry = math.max(8.0, (h * config.height * 0.5));

    final Matrix4 rotMatrix = Matrix4.identity()
      ..translate(cx, cy)
      ..rotateZ(config.rotation * math.pi / 180.0);

    canvas.save();
    canvas.transform(rotMatrix.storage);

    final outlinePaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final Rect localRect = Rect.fromCenter(
      center: Offset.zero,
      width: rx * 2.0,
      height: ry * 2.0,
    );

    if (config.shape == MosaicShape.ellipse) {
      canvas.drawOval(localRect, outlinePaint);
    } else {
      final double cr = math.min(rx, ry) * config.roundness;
      canvas.drawRRect(
        RRect.fromRectAndRadius(localRect, Radius.circular(cr)),
        outlinePaint,
      );
    }

    // Center Anchor Crosshair
    final anchorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), anchorPaint);
    canvas.drawLine(const Offset(0, -6), const Offset(0, 6), anchorPaint);

    // Corner handle circles
    final handlePaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final corners = [
      Offset(-rx, -ry),
      Offset(rx, -ry),
      Offset(-rx, ry),
      Offset(rx, ry),
    ];

    for (final c in corners) {
      canvas.drawCircle(c, 5.0, handlePaint);
      canvas.drawCircle(c, 5.0, handleBorder);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MosaicOverlayPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.showHandles != showHandles;
  }
}
