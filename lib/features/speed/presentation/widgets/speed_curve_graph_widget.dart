import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../color_grading/models/color_grading_config.dart';
import '../../models/speed_curve_preset.dart';

class SpeedCurveGraphWidget extends StatefulWidget {
  final SpeedCurveConfig config;
  final ValueChanged<List<CurvePoint>> onPointsChanged;

  const SpeedCurveGraphWidget({
    super.key,
    required this.config,
    required this.onPointsChanged,
  });

  @override
  State<SpeedCurveGraphWidget> createState() => _SpeedCurveGraphWidgetState();
}

class _SpeedCurveGraphWidgetState extends State<SpeedCurveGraphWidget> {
  int? _activePointIndex;

  static const double _minSpeed = 0.1;
  static const double _maxSpeed = 8.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight > 0 ? constraints.maxHeight : 160.0;

        return Column(
          children: [
            // Interactive Graph Canvas
            Expanded(
              child: GestureDetector(
                onPanStart: (details) => _handlePanStart(details.localPosition, width, height),
                onPanUpdate: (details) => _handlePanUpdate(details.localPosition, width, height),
                onPanEnd: (_) => setState(() => _activePointIndex = null),
                child: CustomPaint(
                  size: Size(width, height),
                  painter: _SpeedCurvePainter(
                    points: widget.config.curvePoints,
                    activePointIndex: _activePointIndex,
                    minSpeed: _minSpeed,
                    maxSpeed: _maxSpeed,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Controls below graph (Add Point, Delete Point, Reset)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.primaryLight,
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 14),
                      label: const Text('Add Point', style: TextStyle(fontSize: 11)),
                      onPressed: _handleAddPoint,
                    ),
                    const SizedBox(width: 8),
                    if (widget.config.curvePoints.length > 2)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          side: const BorderSide(color: AppColors.border),
                          foregroundColor: AppColors.accentWarm,
                        ),
                        icon: const Icon(Icons.remove_circle_outline, size: 14),
                        label: const Text('Remove Point', style: TextStyle(fontSize: 11)),
                        onPressed: _handleRemovePoint,
                      ),
                  ],
                ),
                Text(
                  '${widget.config.curvePoints.length} Key Points',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _handlePanStart(Offset localPos, double width, double height) {
    final points = widget.config.curvePoints;
    int? closestIdx;
    double minDistance = 32.0; // 32px touch radius

    for (int i = 0; i < points.length; i++) {
      final px = points[i].x * width;
      final py = height - ((points[i].y - _minSpeed) / (_maxSpeed - _minSpeed)) * height;
      final dist = (localPos - Offset(px, py)).distance;

      if (dist < minDistance) {
        minDistance = dist;
        closestIdx = i;
      }
    }

    setState(() => _activePointIndex = closestIdx);
  }

  void _handlePanUpdate(Offset localPos, double width, double height) {
    if (_activePointIndex == null) return;
    final idx = _activePointIndex!;
    final points = List<CurvePoint>.from(widget.config.curvePoints);

    // Compute new Y speed
    final normY = ((height - localPos.dy) / height).clamp(0.0, 1.0);
    final newSpeed = (_minSpeed + normY * (_maxSpeed - _minSpeed)).clamp(_minSpeed, _maxSpeed);

    // Compute new X time
    double newTime = (localPos.dx / width).clamp(0.0, 1.0);
    if (idx == 0) {
      newTime = 0.0; // First point locked at start
    } else if (idx == points.length - 1) {
      newTime = 1.0; // Last point locked at end
    } else {
      // Bound between predecessor and successor
      final prevX = points[idx - 1].x + 0.05;
      final nextX = points[idx + 1].x - 0.05;
      newTime = newTime.clamp(prevX, nextX);
    }

    final roundedSpeed = (newSpeed * 10).round() / 10.0;
    points[idx] = CurvePoint(newTime, roundedSpeed);
    widget.onPointsChanged(points);
  }

  void _handleAddPoint() {
    final points = List<CurvePoint>.from(widget.config.curvePoints);
    if (points.length >= 8) return; // Limit to 8 points for clarity

    // Find the largest gap between points
    int bestIdx = 0;
    double maxGap = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final gap = points[i + 1].x - points[i].x;
      if (gap > maxGap) {
        maxGap = gap;
        bestIdx = i;
      }
    }

    final midX = (points[bestIdx].x + points[bestIdx + 1].x) / 2.0;
    final midY = ((points[bestIdx].y + points[bestIdx + 1].y) / 2.0 * 10).round() / 10.0;

    points.insert(bestIdx + 1, CurvePoint(midX, midY));
    widget.onPointsChanged(points);
  }

  void _handleRemovePoint() {
    final points = List<CurvePoint>.from(widget.config.curvePoints);
    if (points.length <= 2) return; // Must keep start and end points

    // If an active point is selected and not an edge, remove it; else remove the middle point
    if (_activePointIndex != null && _activePointIndex! > 0 && _activePointIndex! < points.length - 1) {
      points.removeAt(_activePointIndex!);
      setState(() => _activePointIndex = null);
    } else {
      final midIdx = points.length ~/ 2;
      points.removeAt(midIdx);
    }

    widget.onPointsChanged(points);
  }
}

class _SpeedCurvePainter extends CustomPainter {
  final List<CurvePoint> points;
  final int? activePointIndex;
  final double minSpeed;
  final double maxSpeed;

  _SpeedCurvePainter({
    required this.points,
    required this.activePointIndex,
    required this.minSpeed,
    required this.maxSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      bgPaint,
    );

    // 1. Draw Grid Lines (0.5x, 1.0x baseline, 2.0x, 4.0x)
    _drawGridLines(canvas, size);

    if (points.length < 2) return;

    // 2. Build Smooth Curve Path
    final path = Path();
    final fillPath = Path();

    final screenPoints = points.map((p) {
      final x = p.x * size.width;
      final y = size.height - ((p.y - minSpeed) / (maxSpeed - minSpeed)) * size.height;
      return Offset(x, y);
    }).toList();

    path.moveTo(screenPoints.first.dx, screenPoints.first.dy);
    fillPath.moveTo(screenPoints.first.dx, size.height);
    fillPath.lineTo(screenPoints.first.dx, screenPoints.first.dy);

    for (int i = 0; i < screenPoints.length - 1; i++) {
      final p0 = i > 0 ? screenPoints[i - 1] : screenPoints[i];
      final p1 = screenPoints[i];
      final p2 = screenPoints[i + 1];
      final p3 = i < screenPoints.length - 2 ? screenPoints[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6.0;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6.0;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6.0;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6.0;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      fillPath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    fillPath.lineTo(screenPoints.last.dx, size.height);
    fillPath.close();

    // Draw Glowing Area Fill
    final areaGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primary.withOpacity(0.35),
        AppColors.primary.withOpacity(0.0),
      ],
    );
    final fillPaint = Paint()
      ..shader = areaGradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw Main Curve Line
    final linePaint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // 3. Draw Point Handles & Numeric Tooltips
    for (int i = 0; i < screenPoints.length; i++) {
      final pt = screenPoints[i];
      final isSelected = activePointIndex == i;

      // Outer halo
      final haloPaint = Paint()
        ..color = isSelected ? AppColors.accent.withOpacity(0.4) : AppColors.primary.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, isSelected ? 12.0 : 7.0, haloPaint);

      // Inner center node
      final nodePaint = Paint()
        ..color = isSelected ? AppColors.accent : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, isSelected ? 5.5 : 4.0, nodePaint);

      // Speed text badge above handle
      final tp = TextPainter(
        text: TextSpan(
          text: '${points[i].y}x',
          style: TextStyle(
            fontSize: isSelected ? 10 : 8,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.accent : Colors.white70,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        (pt.dx - tp.width / 2).clamp(4.0, size.width - tp.width - 4.0),
        (pt.dy - tp.height - 6).clamp(2.0, size.height - tp.height - 2.0),
      );
      tp.paint(canvas, textOffset);
    }
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.5)
      ..strokeWidth = 0.8;

    final baselinePaint = Paint()
      ..color = AppColors.accentGold.withOpacity(0.4)
      ..strokeWidth = 1.0;

    final speeds = [0.5, 1.0, 2.0, 4.0];
    for (final s in speeds) {
      final y = size.height - ((s - minSpeed) / (maxSpeed - minSpeed)) * size.height;
      final isBaseline = s == 1.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isBaseline ? baselinePaint : gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '${s}x',
          style: TextStyle(
            fontSize: 8,
            color: isBaseline ? AppColors.accentGold : AppColors.textMuted,
            fontWeight: isBaseline ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, y - 10));
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedCurvePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.activePointIndex != activePointIndex;
  }
}
