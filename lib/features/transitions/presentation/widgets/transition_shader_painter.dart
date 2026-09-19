import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/transition_type.dart';

/// Skia-based GPU compositor painter that simulates and renders 18 cinematic
/// transitions with sub-millisecond latency for live preview.
class TransitionShaderPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final TransitionType type;
  final TransitionEasing easing;
  final Color sceneAColor;
  final Color sceneBColor;
  final String labelA;
  final String labelB;

  TransitionShaderPainter({
    required this.progress,
    required this.type,
    this.easing = TransitionEasing.easeInOut,
    this.sceneAColor = const Color(0xFF1E293B), // Slate Dark
    this.sceneBColor = const Color(0xFF0F766E), // Deep Teal
    this.labelA = 'CLIP A',
    this.labelB = 'CLIP B',
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final curvedProgress = easing.curve.transform(progress.clamp(0.0, 1.0));
    final rect = Offset.zero & size;

    canvas.save();
    canvas.clipRect(rect);

    switch (type) {
      case TransitionType.none:
        _paintSolidScene(canvas, size, progress < 0.5 ? sceneAColor : sceneBColor, progress < 0.5 ? labelA : labelB);
        break;

      case TransitionType.crossDissolve:
        _paintCrossDissolve(canvas, size, curvedProgress);
        break;

      case TransitionType.fadeBlack:
        _paintFadeColor(canvas, size, curvedProgress, Colors.black);
        break;

      case TransitionType.fadeWhite:
        _paintFadeColor(canvas, size, curvedProgress, Colors.white);
        break;

      case TransitionType.wipeLeft:
        _paintWipe(canvas, size, curvedProgress, isLeft: true);
        break;

      case TransitionType.wipeRight:
        _paintWipe(canvas, size, curvedProgress, isLeft: false);
        break;

      case TransitionType.slideUp:
        _paintSlide(canvas, size, curvedProgress, isUp: true);
        break;

      case TransitionType.slideDown:
        _paintSlide(canvas, size, curvedProgress, isUp: false);
        break;

      case TransitionType.zoomIn:
        _paintCircleZoom(canvas, size, curvedProgress);
        break;

      case TransitionType.whipPanLeft:
        _paintWhipPan(canvas, size, curvedProgress, isLeft: true);
        break;

      case TransitionType.whipPanRight:
        _paintWhipPan(canvas, size, curvedProgress, isLeft: false);
        break;

      case TransitionType.glitchDisplace:
        _paintGlitchDisplace(canvas, size, curvedProgress);
        break;

      case TransitionType.filmBurn:
        _paintFilmBurn(canvas, size, curvedProgress);
        break;

      case TransitionType.spinClockwise:
        _paintSpin(canvas, size, curvedProgress, clockwise: true);
        break;

      case TransitionType.spinCounterClockwise:
        _paintSpin(canvas, size, curvedProgress, clockwise: false);
        break;

      case TransitionType.directionalWarp:
        _paintDirectionalWarp(canvas, size, curvedProgress);
        break;

      case TransitionType.pixelateDissolve:
        _paintPixelateDissolve(canvas, size, curvedProgress);
        break;

      case TransitionType.lensFlash:
        _paintLensFlash(canvas, size, curvedProgress);
        break;
    }

    canvas.restore();
  }

  void _paintSolidScene(Canvas canvas, Size size, Color color, String label) {
    final paint = Paint()..color = color;
    canvas.drawRect(Offset.zero & size, paint);
    _drawSceneDecorations(canvas, size, label);
  }

  void _paintCrossDissolve(Canvas canvas, Size size, double t) {
    // Draw Scene A
    _paintSolidScene(canvas, size, sceneAColor, labelA);
    // Draw Scene B with opacity t
    canvas.saveLayer(Offset.zero & size, Paint()..color = Colors.white.withOpacity(t));
    _paintSolidScene(canvas, size, sceneBColor, labelB);
    canvas.restore();
  }

  void _paintFadeColor(Canvas canvas, Size size, double t, Color fadeColor) {
    if (t < 0.5) {
      final fadeProgress = t * 2.0;
      _paintSolidScene(canvas, size, sceneAColor, labelA);
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = fadeColor.withOpacity(fadeProgress),
      );
    } else {
      final fadeProgress = (1.0 - t) * 2.0;
      _paintSolidScene(canvas, size, sceneBColor, labelB);
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = fadeColor.withOpacity(fadeProgress),
      );
    }
  }

  void _paintWipe(Canvas canvas, Size size, double t, {required bool isLeft}) {
    _paintSolidScene(canvas, size, sceneAColor, labelA);

    final cutX = isLeft ? size.width * (1.0 - t) : 0.0;
    final wipeWidth = isLeft ? size.width * t : size.width * t;

    final clipRect = Rect.fromLTWH(cutX, 0, wipeWidth, size.height);
    canvas.save();
    canvas.clipRect(clipRect);
    _paintSolidScene(canvas, size, sceneBColor, labelB);
    canvas.restore();

    // Draw bright divider line at wipe boundary
    final dividerX = isLeft ? cutX : wipeWidth;
    canvas.drawLine(
      Offset(dividerX, 0),
      Offset(dividerX, size.height),
      Paint()
        ..color = AppColors.accent.withOpacity(0.8)
        ..strokeWidth = 2.0,
    );
  }

  void _paintSlide(Canvas canvas, Size size, double t, {required bool isUp}) {
    final offsetAY = isUp ? -size.height * t : size.height * t;
    final offsetBY = isUp ? size.height * (1.0 - t) : -size.height * (1.0 - t);

    // Scene A sliding out
    canvas.save();
    canvas.translate(0, offsetAY);
    _paintSolidScene(canvas, size, sceneAColor, labelA);
    canvas.restore();

    // Scene B sliding in
    canvas.save();
    canvas.translate(0, offsetBY);
    _paintSolidScene(canvas, size, sceneBColor, labelB);
    canvas.restore();
  }

  void _paintCircleZoom(Canvas canvas, Size size, double t) {
    _paintSolidScene(canvas, size, sceneAColor, labelA);

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final currentRadius = maxRadius * t;

    final path = Path()..addOval(Rect.fromCircle(center: center, radius: currentRadius));

    canvas.save();
    canvas.clipPath(path);
    _paintSolidScene(canvas, size, sceneBColor, labelB);
    canvas.restore();

    // Edge glowing ring
    if (t > 0.05 && t < 0.95) {
      canvas.drawCircle(
        center,
        currentRadius,
        Paint()
          ..color = AppColors.primaryLight.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }
  }

  void _paintWhipPan(Canvas canvas, Size size, double t, {required bool isLeft}) {
    final direction = isLeft ? -1.0 : 1.0;
    final offset = direction * size.width * t;

    // Velocity peak around 0.5
    final velocityBlur = math.sin(t * math.pi) * 20.0;

    // Motion streaks on background
    canvas.save();
    canvas.translate(offset, 0);
    _paintSolidScene(canvas, size, sceneAColor, labelA);
    canvas.restore();

    canvas.save();
    canvas.translate(offset - (direction * size.width), 0);
    _paintSolidScene(canvas, size, sceneBColor, labelB);
    canvas.restore();

    // Directional Motion Blur Streaks Overlay
    if (velocityBlur > 2.0) {
      final blurPaint = Paint()
        ..color = Colors.white.withOpacity(math.min(0.35, velocityBlur / 40.0))
        ..strokeWidth = 3.0;

      final rng = math.Random(42);
      for (int i = 0; i < 8; i++) {
        final y = rng.nextDouble() * size.height;
        final startX = rng.nextDouble() * size.width * 0.2;
        final streakLen = size.width * 0.6;
        canvas.drawLine(Offset(startX, y), Offset(startX + streakLen, y), blurPaint);
      }
    }
  }

  void _paintGlitchDisplace(Canvas canvas, Size size, double t) {
    if (t < 0.5) {
      _paintSolidScene(canvas, size, sceneAColor, labelA);
    } else {
      _paintSolidScene(canvas, size, sceneBColor, labelB);
    }

    final glitchIntensity = math.sin(t * math.pi);
    if (glitchIntensity > 0.1) {
      final rng = math.Random((t * 100).toInt());

      // Chromatic aberration slices
      for (int i = 0; i < 6; i++) {
        final sliceY = rng.nextDouble() * size.height;
        final sliceHeight = 8.0 + rng.nextDouble() * 24.0;
        final shiftX = (rng.nextDouble() - 0.5) * 40.0 * glitchIntensity;

        final sliceRect = Rect.fromLTWH(0, sliceY, size.width, sliceHeight);

        // Red channel shift
        canvas.save();
        canvas.clipRect(sliceRect);
        canvas.translate(shiftX, 0);
        canvas.drawRect(
          sliceRect,
          Paint()..color = const Color(0xFFFF0055).withOpacity(0.35 * glitchIntensity),
        );
        canvas.restore();

        // Cyan channel shift
        canvas.save();
        canvas.clipRect(sliceRect);
        canvas.translate(-shiftX * 0.8, 0);
        canvas.drawRect(
          sliceRect,
          Paint()..color = const Color(0xFF00FFFF).withOpacity(0.35 * glitchIntensity),
        );
        canvas.restore();
      }

      // Horizontal scanline noise bars
      final scanlinePaint = Paint()
        ..color = Colors.white.withOpacity(0.25 * glitchIntensity)
        ..strokeWidth = 1.0;
      for (double y = 0; y < size.height; y += 6) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
      }
    }
  }

  void _paintFilmBurn(Canvas canvas, Size size, double t) {
    // Cross-fade scenes
    _paintCrossDissolve(canvas, size, t);

    // Warm organic 35mm film burn flare overlay
    final burnPeak = math.sin(t * math.pi);
    if (burnPeak > 0.05) {
      final center = Offset(size.width * 0.6, size.height * 0.4);
      final radius = size.width * (0.4 + burnPeak * 0.8);

      final gradient = RadialGradient(
        center: const Alignment(0.2, -0.2),
        radius: 0.9,
        colors: [
          const Color(0xFFFFF7ED).withOpacity(math.min(1.0, burnPeak * 0.95)), // White-hot core
          const Color(0xFFFFB703).withOpacity(math.min(0.9, burnPeak * 0.85)), // Amber gold
          const Color(0xFFFB8500).withOpacity(math.min(0.8, burnPeak * 0.70)), // Deep fiery orange
          const Color(0xFFDC2626).withOpacity(math.min(0.6, burnPeak * 0.40)), // Crimson edge
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.55, 0.80, 1.0],
      );

      final burnPaint = Paint()..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawRect(Offset.zero & size, burnPaint);

      // Overexposure flash at apex
      if (burnPeak > 0.7) {
        final flashAlpha = (burnPeak - 0.7) / 0.3 * 0.6;
        canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white.withOpacity(flashAlpha));
      }
    }
  }

  void _paintSpin(Canvas canvas, Size size, double t, {required bool clockwise}) {
    final angle = (clockwise ? 1.0 : -1.0) * math.pi * t;
    final scale = 1.0 - math.sin(t * math.pi) * 0.35; // Perspective pinch

    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.rotate(angle);
    canvas.translate(-center.dx, -center.dy);

    if (t < 0.5) {
      _paintSolidScene(canvas, size, sceneAColor, labelA);
    } else {
      _paintSolidScene(canvas, size, sceneBColor, labelB);
    }
    canvas.restore();
  }

  void _paintDirectionalWarp(Canvas canvas, Size size, double t) {
    _paintCrossDissolve(canvas, size, t);

    final warpIntensity = math.sin(t * math.pi);
    if (warpIntensity > 0.1) {
      final center = Offset(size.width / 2, size.height / 2);

      // Radial warp light rays
      final rayPaint = Paint()
        ..color = AppColors.accent.withOpacity(0.3 * warpIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      const numRays = 16;
      for (int i = 0; i < numRays; i++) {
        final rad = (i / numRays) * 2 * math.pi;
        final inner = center + Offset(math.cos(rad) * 20.0, math.sin(rad) * 20.0);
        final outer = center + Offset(math.cos(rad) * size.width * 0.8, math.sin(rad) * size.width * 0.8);
        canvas.drawLine(inner, outer, rayPaint);
      }

      // Radial zoom rings
      for (double r = 40; r < size.width * 0.7; r += 50) {
        canvas.drawCircle(
          center,
          r * (1.0 + t * 0.5),
          Paint()
            ..color = Colors.white.withOpacity(0.15 * warpIntensity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _paintPixelateDissolve(Canvas canvas, Size size, double t) {
    // Determine cell size: maximum at apex t=0.5
    final factor = math.sin(t * math.pi);
    final cellSize = math.max(4.0, factor * 28.0);

    if (t < 0.5) {
      _paintSolidScene(canvas, size, sceneAColor, labelA);
    } else {
      _paintSolidScene(canvas, size, sceneBColor, labelB);
    }

    if (factor > 0.05) {
      final blockPaint = Paint()..style = PaintingStyle.fill;
      final rng = math.Random(1337);

      for (double x = 0; x < size.width; x += cellSize) {
        for (double y = 0; y < size.height; y += cellSize) {
          final blockT = (rng.nextDouble() + t) / 2.0;
          final color = blockT > 0.5 ? sceneBColor : sceneAColor;
          blockPaint.color = color.withOpacity(0.75 * factor);

          canvas.drawRect(Rect.fromLTWH(x, y, cellSize - 1.0, cellSize - 1.0), blockPaint);
        }
      }
    }
  }

  void _paintLensFlash(Canvas canvas, Size size, double t) {
    _paintCrossDissolve(canvas, size, t);

    final flashIntensity = math.sin(t * math.pi);
    if (flashIntensity > 0.1) {
      // Horizontal anamorphic streak flare across frame center
      final center = Offset(size.width / 2, size.height / 2);
      final streakRect = Rect.fromCenter(
        center: center,
        width: size.width * 1.5,
        height: size.height * (0.05 + flashIntensity * 0.15),
      );

      final streakGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF67E8F9).withOpacity(0.8 * flashIntensity), // Cyan flare
          Colors.white.withOpacity(0.95 * flashIntensity),           // Pure white core
          const Color(0xFF38BDF8).withOpacity(0.8 * flashIntensity), // Sky blue
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      );

      canvas.drawRect(
        streakRect,
        Paint()..shader = streakGradient.createShader(streakRect),
      );

      // Spherical central core glow
      canvas.drawCircle(
        center,
        size.height * 0.3 * flashIntensity,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withOpacity(0.9 * flashIntensity),
              const Color(0xFF38BDF8).withOpacity(0.5 * flashIntensity),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: size.height * 0.3 * flashIntensity)),
      );
    }
  }

  void _drawSceneDecorations(Canvas canvas, Size size, String label) {
    // Grid pattern
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Label text
    final textSpan = TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.85),
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant TransitionShaderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.type != type ||
        oldDelegate.easing != easing ||
        oldDelegate.sceneAColor != sceneAColor ||
        oldDelegate.sceneBColor != sceneBColor;
  }
}
