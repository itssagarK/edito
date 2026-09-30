import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/doodle_stroke.dart';
import '../models/doodle_config.dart';

/// CapCut Pro Creative Brush & Doodle Drawing Compiler Service.
class DoodleCompilerService {
  /// Builds a smooth quadratic Bezier curve path from touch points.
  static Path buildSmoothPath(List<DoodlePoint> points, Size size) {
    final path = Path();
    if (points.isEmpty) return path;

    final first = points.first.toOffset(size);
    path.moveTo(first.dx, first.dy);

    if (points.length == 1) {
      path.addOval(Rect.fromCircle(center: first, radius: 1.0));
      return path;
    }

    if (points.length == 2) {
      final second = points[1].toOffset(size);
      path.lineTo(second.dx, second.dy);
      return path;
    }

    for (int i = 1; i < points.length - 1; i++) {
      final p1 = points[i].toOffset(size);
      final p2 = points[i + 1].toOffset(size);
      final midPoint = Offset((p1.dx + p2.dx) / 2.0, (p1.dy + p2.dy) / 2.0);
      path.quadraticBezierTo(p1.dx, p1.dy, midPoint.dx, midPoint.dy);
    }

    final last = points.last.toOffset(size);
    path.lineTo(last.dx, last.dy);

    return path;
  }

  /// Paints a single doodle stroke with specialized brush styling onto Skia canvas.
  static void paintStroke(Canvas canvas, DoodleStroke stroke, Size size) {
    if (stroke.points.isEmpty) return;

    final path = buildSmoothPath(stroke.points, size);
    final baseColor = stroke.color;
    final strokeW = stroke.strokeWidth * (size.height / 1080.0).clamp(0.5, 2.0);

    switch (stroke.brushType) {
      case DoodleBrushType.pen:
        final paint = Paint()
          ..color = baseColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(path, paint);
        break;

      case DoodleBrushType.neon:
        // Multi-pass neon bloom effect
        // 1. Outer diffuse halo
        final haloPaint = Paint()
          ..color = baseColor.withOpacity((stroke.opacity * 0.45).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW * 2.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeW * 0.8);
        canvas.drawPath(path, haloPaint);

        // 2. Mid aura
        final midPaint = Paint()
          ..color = baseColor.withOpacity((stroke.opacity * 0.8).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW * 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(path, midPaint);

        // 3. Inner brilliant white/bright core
        final corePaint = Paint()
          ..color = Colors.white.withOpacity((stroke.opacity * 0.95).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW * 0.55
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(path, corePaint);
        break;

      case DoodleBrushType.highlighter:
        final highPaint = Paint()
          ..color = baseColor.withOpacity((stroke.opacity * 0.40).clamp(0.0, 0.70))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW * 2.2
          ..strokeCap = StrokeCap.square
          ..strokeJoin = StrokeJoin.miter;
        canvas.drawPath(path, highPaint);
        break;

      case DoodleBrushType.arrow:
        final arrowPaint = Paint()
          ..color = baseColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(path, arrowPaint);

        // Draw directional arrowhead at the tip
        if (stroke.points.length >= 2) {
          final pEnd = stroke.points.last.toOffset(size);
          final pPrev = stroke.points[stroke.points.length - 2].toOffset(size);
          final dir = pEnd - pPrev;
          if (dir.distance > 0.001) {
            final angle = math.atan2(dir.dy, dir.dx);
            final arrowSize = strokeW * 2.2;

            final arrowPath = Path();
            arrowPath.moveTo(pEnd.dx, pEnd.dy);
            arrowPath.lineTo(
              pEnd.dx - arrowSize * math.cos(angle - math.pi / 6.0),
              pEnd.dy - arrowSize * math.sin(angle - math.pi / 6.0),
            );
            arrowPath.lineTo(
              pEnd.dx - arrowSize * math.cos(angle + math.pi / 6.0),
              pEnd.dy - arrowSize * math.sin(angle + math.pi / 6.0),
            );
            arrowPath.close();

            final fillPaint = Paint()
              ..color = baseColor
              ..style = PaintingStyle.fill;
            canvas.drawPath(arrowPath, fillPaint);
          }
        }
        break;

      case DoodleBrushType.dashed:
        final dashPaint = Paint()
          ..color = baseColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round;

        // Draw segmented dashed intervals
        for (int i = 0; i < stroke.points.length - 1; i += 2) {
          final p1 = stroke.points[i].toOffset(size);
          final p2 = stroke.points[i + 1].toOffset(size);
          canvas.drawLine(p1, p2, dashPaint);
        }
        break;

      case DoodleBrushType.eraser:
        // Eraser doesn't draw visible strokes
        break;
    }
  }

  /// Removes strokes that intersect with the eraser touch radius.
  static List<DoodleStroke> eraseAtPoint(
    List<DoodleStroke> strokes,
    Offset erasePos,
    double eraserRadius,
    Size size,
  ) {
    final remaining = <DoodleStroke>[];

    for (final stroke in strokes) {
      bool intersects = false;
      for (final pt in stroke.points) {
        final offset = pt.toOffset(size);
        if ((offset - erasePos).distance < eraserRadius) {
          intersects = true;
          break;
        }
      }
      if (!intersects) {
        remaining.add(stroke);
      }
    }
    return remaining;
  }

  /// Compiles FFmpeg video filters for 4K video exports.
  static List<String> generateFFmpegFilters(
    DoodleConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return const [];

    final filters = <String>[];
    final size = Size(targetWidth.toDouble(), targetHeight.toDouble());

    // Generate drawbox / drawline primitives for major strokes
    for (final stroke in config.strokes) {
      if (stroke.points.length < 2) continue;
      final colorHex = stroke.colorValue.toRadixString(16).padLeft(8, '0');
      final r = colorHex.substring(2, 4);
      final g = colorHex.substring(4, 6);
      final b = colorHex.substring(6, 8);
      final colorStr = '0x$r$g$b@${stroke.opacity.toStringAsFixed(2)}';

      final bounds = stroke.computePixelBounds(size);
      if (bounds.width > 2 && bounds.height > 2) {
        // Draw lightweight bounding indicator or overlay box
        filters.add(
          'drawbox=x=${bounds.left.toInt()}:y=${bounds.top.toInt()}:'
          'w=${bounds.width.toInt()}:h=${bounds.height.toInt()}:'
          'color=$colorStr:t=${stroke.strokeWidth.clamp(1.0, 10.0).toInt()}',
        );
      }
    }

    return filters;
  }
}
