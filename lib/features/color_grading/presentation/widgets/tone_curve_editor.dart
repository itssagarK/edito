import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/color_grading_config.dart';

class ToneCurveEditor extends StatefulWidget {
  final List<CurvePoint> points;
  final Function(List<CurvePoint>) onPointsChanged;

  const ToneCurveEditor({
    super.key,
    required this.points,
    required this.onPointsChanged,
  });

  @override
  State<ToneCurveEditor> createState() => _ToneCurveEditorState();
}

class _ToneCurveEditorState extends State<ToneCurveEditor> {
  int _selectedPointIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Curve Canvas Box
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: GestureDetector(
              onPanDown: (details) {
                _handlePan(details.localPosition, 240);
              },
              onPanUpdate: (details) {
                _handlePan(details.localPosition, 240);
              },
              child: CustomPaint(
                painter: _CurveCanvasPainter(
                  points: widget.points,
                  selectedPointIndex: _selectedPointIndex,
                ),
              ),
            ),
          ),
        ),

        // Reset Curves Button
        TextButton.icon(
          onPressed: () {
            widget.onPointsChanged(const [CurvePoint(0.0, 0.0), CurvePoint(1.0, 1.0)]);
          },
          icon: const Icon(Icons.refresh, size: 16, color: AppColors.textMuted),
          label: const Text('Reset Curve to Linear', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
      ],
    );
  }

  void _handlePan(Offset localPos, double size) {
    final normX = (localPos.dx / size).clamp(0.0, 1.0);
    final normY = (1.0 - (localPos.dy / size)).clamp(0.0, 1.0);

    // If only default 2 endpoints exist, allow inserting midpoint
    var currentPoints = List<CurvePoint>.from(widget.points);
    if (currentPoints.length == 2 && normX > 0.1 && normX < 0.9) {
      currentPoints.insert(1, CurvePoint(normX, normY));
      _selectedPointIndex = 1;
    } else {
      // Find closest point to update
      int closestIdx = 0;
      double minDistance = 999.0;
      for (int i = 0; i < currentPoints.length; i++) {
        final dist = (currentPoints[i].x - normX).abs();
        if (dist < minDistance) {
          minDistance = dist;
          closestIdx = i;
        }
      }
      _selectedPointIndex = closestIdx;
      currentPoints[closestIdx] = CurvePoint(
        closestIdx == 0 ? 0.0 : (closestIdx == currentPoints.length - 1 ? 1.0 : normX),
        normY,
      );
    }

    currentPoints.sort((a, b) => a.x.compareTo(b.x));
    widget.onPointsChanged(currentPoints);
  }
}

class _CurveCanvasPainter extends CustomPainter {
  final List<CurvePoint> points;
  final int selectedPointIndex;

  const _CurveCanvasPainter({
    required this.points,
    required this.selectedPointIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.4)
      ..strokeWidth = 1.0;

    final refPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.0;

    // Draw 4x4 Grid
    for (int i = 1; i <= 3; i++) {
      final pos = size.width * (i / 4.0);
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), gridPaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), gridPaint);
    }

    // Diagonal reference line
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), refPaint);

    // Draw Spline Curve
    final curvePaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (points.isNotEmpty) {
      final start = _toOffset(points.first, size);
      path.moveTo(start.dx, start.dy);

      for (int i = 1; i < points.length; i++) {
        final prev = _toOffset(points[i - 1], size);
        final curr = _toOffset(points[i], size);
        final midX = (prev.dx + curr.dx) / 2;
        path.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
      }
      canvas.drawPath(path, curvePaint);
    }

    // Draw Control Points
    for (int i = 0; i < points.length; i++) {
      final pt = _toOffset(points[i], size);
      final isSelected = i == selectedPointIndex;

      final ptFillPaint = Paint()
        ..color = isSelected ? AppColors.accent : Colors.white;

      final ptBorderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(pt, isSelected ? 6.0 : 4.5, ptFillPaint);
      canvas.drawCircle(pt, isSelected ? 6.0 : 4.5, ptBorderPaint);
    }
  }

  Offset _toOffset(CurvePoint p, Size size) {
    return Offset(p.x * size.width, (1.0 - p.y) * size.height);
  }

  @override
  bool shouldRepaint(covariant _CurveCanvasPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.selectedPointIndex != selectedPointIndex;
  }
}
