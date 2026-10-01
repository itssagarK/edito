import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/curve_point.dart';
import '../../models/channel_curve.dart';
import '../../services/curves_compiler_service.dart';

/// Interactive 2D Cartesian coordinate grid for manipulating RGB / Luma curves.
class CurveGridEditorWidget extends StatefulWidget {
  final ChannelCurve curve;
  final ValueChanged<ChannelCurve> onCurveChanged;
  final double size;

  const CurveGridEditorWidget({
    super.key,
    required this.curve,
    required this.onCurveChanged,
    this.size = 260.0,
  });

  @override
  State<CurveGridEditorWidget> createState() => _CurveGridEditorWidgetState();
}

class _CurveGridEditorWidgetState extends State<CurveGridEditorWidget> {
  int? _activePointIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Coordinate readout header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.curve.channel.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.curve.channel.label,
                    style: AppTypography.caption.copyWith(
                      color: widget.curve.channel.accentColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (_activePointIndex != null &&
                  _activePointIndex! < widget.curve.points.length)
                Text(
                  'IN: ${(widget.curve.points[_activePointIndex!].x * 100).toInt()}%  OUT: ${(widget.curve.points[_activePointIndex!].y * 100).toInt()}%',
                  style: AppTypography.timecode.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Text(
                  'TAP TO ADD / DRAG TO SHAPE',
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),

        // 2D Curve Editor Grid Box
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: const Color(0xFF14171F),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: GestureDetector(
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: (_) => setState(() {}),
              onDoubleTapDown: _handleDoubleTapDown,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CurveGridPainter(
                  curve: widget.curve,
                  activePointIndex: _activePointIndex,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handlePanStart(DragStartDetails details) {
    final localPos = details.localPosition;
    final normX = (localPos.dx / widget.size).clamp(0.0, 1.0);
    final normY = (1.0 - (localPos.dy / widget.size)).clamp(0.0, 1.0);

    // Check if near an existing control point (hit radius 24 px)
    const hitRadiusNorm = 24.0 / 260.0;
    int nearestIdx = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < widget.curve.points.length; i++) {
      final p = widget.curve.points[i];
      final dist = math.sqrt(math.pow(p.x - normX, 2) + math.pow(p.y - normY, 2));
      if (dist < minDistance) {
        minDistance = dist;
        nearestIdx = i;
      }
    }

    if (nearestIdx != -1 && minDistance <= hitRadiusNorm) {
      // Select existing point
      setState(() => _activePointIndex = nearestIdx);
    } else {
      // Insert new control point
      if (widget.curve.points.length < 8) {
        final newPt = CurvePoint(x: normX, y: normY);
        final updatedCurve = widget.curve.withPointAdded(newPt);
        final newIndex = updatedCurve.points.indexWhere(
          (p) => (p.x - normX).abs() < 1e-4 && (p.y - normY).abs() < 1e-4,
        );
        setState(() => _activePointIndex = newIndex != -1 ? newIndex : null);
        widget.onCurveChanged(updatedCurve);
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_activePointIndex == null) return;
    if (_activePointIndex! >= widget.curve.points.length) return;

    final localPos = details.localPosition;
    final normX = (localPos.dx / widget.size).clamp(0.0, 1.0);
    final normY = (1.0 - (localPos.dy / widget.size)).clamp(0.0, 1.0);

    final idx = _activePointIndex!;
    final updatedPoint = CurvePoint(
      x: (idx == 0) ? 0.0 : (idx == widget.curve.points.length - 1 ? 1.0 : normX),
      y: normY,
    );

    final updatedCurve = widget.curve.withPointUpdated(idx, updatedPoint);
    widget.onCurveChanged(updatedCurve);
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    final localPos = details.localPosition;
    final normX = (localPos.dx / widget.size).clamp(0.0, 1.0);
    final normY = (1.0 - (localPos.dy / widget.size)).clamp(0.0, 1.0);

    const hitRadiusNorm = 24.0 / 260.0;
    for (int i = 1; i < widget.curve.points.length - 1; i++) {
      final p = widget.curve.points[i];
      final dist = math.sqrt(math.pow(p.x - normX, 2) + math.pow(p.y - normY, 2));
      if (dist <= hitRadiusNorm) {
        final updated = widget.curve.withPointRemovedAt(i);
        setState(() => _activePointIndex = null);
        widget.onCurveChanged(updated);
        return;
      }
    }
  }
}

class _CurveGridPainter extends CustomPainter {
  final ChannelCurve curve;
  final int? activePointIndex;

  const _CurveGridPainter({
    required this.curve,
    required this.activePointIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw 4x4 Grid Divisions (25%, 50%, 75%)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i < 4; i++) {
      final x = w * (i / 4.0);
      final y = h * (i / 4.0);
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. Draw Neutral Identity Diagonal Guide (y = x)
    final diagonalPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, h), Offset(w, 0), diagonalPaint);

    // 3. Draw Spline Curve Path
    final curveColor = curve.channel.accentColor;
    final curvePath = Path();

    // Sample along width for continuous smooth curve
    const steps = 80;
    for (int step = 0; step <= steps; step++) {
      final normX = step / steps.toDouble();
      final normY = CurvesCompilerService.evaluateCurve(curve, normX);
      final px = normX * w;
      final py = (1.0 - normY) * h;

      if (step == 0) {
        curvePath.moveTo(px, py);
      } else {
        curvePath.lineTo(px, py);
      }
    }

    // Outer soft glow
    final glowPaint = Paint()
      ..color = curveColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(curvePath, glowPaint);

    // Crisp foreground curve stroke
    final mainCurvePaint = Paint()
      ..color = curveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(curvePath, mainCurvePaint);

    // 4. Draw Interactive Control Point Pucks
    for (int i = 0; i < curve.points.length; i++) {
      final p = curve.points[i];
      final px = p.x * w;
      final py = (1.0 - p.y) * h;
      final isSelected = (i == activePointIndex);

      if (isSelected) {
        // Selected highlight halo
        final haloPaint = Paint()
          ..color = curveColor.withOpacity(0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(px, py), 12.0, haloPaint);
      }

      // Outer ring
      final outerPuck = Paint()
        ..color = isSelected ? Colors.white : curveColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), isSelected ? 6.5 : 5.0, outerPuck);

      // Inner core
      final innerCore = Paint()
        ..color = isSelected ? curveColor : Colors.black
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), isSelected ? 3.5 : 2.5, innerCore);
    }
  }

  @override
  bool shouldRepaint(covariant _CurveGridPainter oldDelegate) {
    return oldDelegate.curve != curve ||
        oldDelegate.activePointIndex != activePointIndex;
  }
}
