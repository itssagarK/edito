import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/color_grading_config.dart';

class ColorWheelWidget extends StatelessWidget {
  final String label;
  final ColorWheelValue value;
  final ValueChanged<ColorWheelValue> onChanged;
  final Color accentColor;

  const ColorWheelWidget({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.accentColor = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with Label, Reset, and Values
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(label, style: AppTypography.titleMedium.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                Text(
                  '${value.angle.round()}° • ${(value.saturation * 100).round()}%',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(width: 4),
                if (value.isActive)
                  InkWell(
                    onTap: () => onChanged(const ColorWheelValue()),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text('Reset', style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Interactive Chromatic Disc
        Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final radius = constraints.maxWidth / 2;
                final center = Offset(radius, radius);

                // Calculate puck position from angle and saturation
                final rad = value.angle * (math.pi / 180.0);
                final puckDist = value.saturation.clamp(0.0, 1.0) * (radius - 12);
                final puckX = center.dx + puckDist * math.cos(rad);
                final puckY = center.dy + puckDist * math.sin(rad);

                return GestureDetector(
                  onPanDown: (details) => _handleGesture(details.localPosition, center, radius),
                  onPanUpdate: (details) => _handleGesture(details.localPosition, center, radius),
                  child: CustomPaint(
                    painter: _ColorWheelDiscPainter(
                      puckPosition: Offset(puckX, puckY),
                      isActive: value.isActive,
                      accentColor: accentColor,
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Luminance Slider (-1.0 to +1.0)
        Row(
          children: [
            const Icon(Icons.brightness_medium, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: value.luminance,
                  min: -1.0,
                  max: 1.0,
                  activeColor: accentColor,
                  inactiveColor: AppColors.surfaceElevated,
                  onChanged: (luma) {
                    onChanged(value.copyWith(luminance: luma));
                  },
                ),
              ),
            ),
            SizedBox(
              width: 32,
              child: Text(
                '${(value.luminance * 100).round()}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleGesture(Offset localPos, Offset center, double radius) {
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final maxDist = radius - 12;

    double sat = (dist / maxDist).clamp(0.0, 1.0);
    double deg = (math.atan2(dy, dx) * (180.0 / math.pi));
    if (deg < 0) deg += 360.0;

    // Small dead-zone near center snaps to 0 saturation
    if (dist < 4.0) {
      sat = 0.0;
    }

    onChanged(value.copyWith(angle: deg, saturation: sat));
  }
}

class _ColorWheelDiscPainter extends CustomPainter {
  final Offset puckPosition;
  final bool isActive;
  final Color accentColor;

  const _ColorWheelDiscPainter({
    required this.puckPosition,
    required this.isActive,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw Sweep Gradient Hue Disc
    final sweepGradient = SweepGradient(
      colors: const [
        Color(0xFFFF0000), // Red 0°
        Color(0xFFFFFF00), // Yellow 60°
        Color(0xFF00FF00), // Green 120°
        Color(0xFF00FFFF), // Cyan 180°
        Color(0xFF0000FF), // Blue 240°
        Color(0xFFFF00FF), // Magenta 300°
        Color(0xFFFF0000), // Red 360°
      ],
    );

    final discPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, discPaint);

    // 2. Radial white saturation desaturation overlay at center
    final satGradient = RadialGradient(
      colors: [
        Colors.grey.shade800,
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    );
    final satPaint = Paint()
      ..shader = satGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, satPaint);

    // 3. Outer border ring
    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 2, borderPaint);

    // 4. Center Crosshair
    final crossPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx - 6, center.dy), Offset(center.dx + 6, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 6), Offset(center.dx, center.dy + 6), crossPaint);

    // 5. Puck Indicator
    final puckBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final puckFill = Paint()
      ..color = isActive ? accentColor : Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(puckPosition, 7, puckFill);
    canvas.drawCircle(puckPosition, 7, puckBorder);
  }

  @override
  bool shouldRepaint(covariant _ColorWheelDiscPainter oldDelegate) =>
      oldDelegate.puckPosition != puckPosition ||
      oldDelegate.isActive != isActive ||
      oldDelegate.accentColor != accentColor;
}
