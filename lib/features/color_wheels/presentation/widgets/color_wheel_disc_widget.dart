import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/wheel_channel_value.dart';

/// Interactive circular color wheel disc widget with hue ring, saturation disc, draggable puck, and luminance slider.
class ColorWheelDiscWidget extends StatelessWidget {
  final String label;
  final String? subtitle;
  final WheelChannelValue value;
  final Color accentColor;
  final ValueChanged<WheelChannelValue> onChanged;
  final double size;
  final bool isCompact;

  const ColorWheelDiscWidget({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.accentColor,
    required this.onChanged,
    this.size = 140.0,
    this.isCompact = false,
  });

  void _handlePan(Offset localPos, Size discSize) {
    final center = Offset(discSize.width / 2, discSize.height / 2);
    final delta = localPos - center;
    final maxRadius = (discSize.width / 2) - 4.0;
    final distance = delta.distance;

    final normSat = (distance / maxRadius).clamp(0.0, 1.0);

    // Compute angle 0 to 360 degrees
    var angle = math.atan2(delta.dy, delta.dx) * (180.0 / math.pi);
    if (angle < 0) angle += 360.0;

    final newValue = WheelChannelValue.fromHsl(
      angle: angle,
      saturation: normSat,
      luminance: value.luminance,
    );
    onChanged(newValue);
  }

  void _resetWheel() {
    onChanged(value.copyWith(
      angle: 0.0,
      saturation: 0.0,
      red: 0.0,
      green: 0.0,
      blue: 0.0,
    ));
  }

  void _resetLuminance() {
    onChanged(value.copyWith(luminance: 0.0));
  }

  @override
  Widget build(BuildContext context) {
    final discDimension = isCompact ? 100.0 : size;

    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: !value.isDefault ? accentColor.withOpacity(0.5) : AppColors.border,
          width: !value.isDefault ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Label & Accent Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
              Flexible(
                child: Text(
                  label,
                  style: isCompact
                      ? AppTypography.caption.copyWith(fontWeight: FontWeight.bold)
                      : AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (subtitle != null && !isCompact) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: isCompact ? 6 : 10),

          // Main Wheel and Pedestal Slider Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Color Wheel Disc
              GestureDetector(
                onDoubleTap: _resetWheel,
                onPanStart: (d) => _handlePan(d.localPosition, Size(discDimension, discDimension)),
                onPanUpdate: (d) => _handlePan(d.localPosition, Size(discDimension, discDimension)),
                child: SizedBox(
                  width: discDimension,
                  height: discDimension,
                  child: CustomPaint(
                    size: Size(discDimension, discDimension),
                    painter: _ColorWheelPainter(
                      value: value,
                      accentColor: accentColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 8 : 14),

              // Vertical Luminance Pedestal Slider
              _buildLuminanceSlider(height: discDimension),
            ],
          ),

          SizedBox(height: isCompact ? 6 : 8),

          // Readout Values: Saturation & Luminance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'S: ${(value.saturation * 100).toInt()}%',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: value.saturation > 0.01 ? accentColor : AppColors.textSecondary,
                  fontWeight: value.saturation > 0.01 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                'Y: ${(value.luminance * 100).toInt()}%',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: value.luminance.abs() > 0.01 ? accentColor : AppColors.textSecondary,
                  fontWeight: value.luminance.abs() > 0.01 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLuminanceSlider({required double height}) {
    return Column(
      children: [
        GestureDetector(
          onDoubleTap: _resetLuminance,
          child: SizedBox(
            height: height,
            width: 24,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                  activeTrackColor: accentColor,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: value.luminance,
                  min: -1.0,
                  max: 1.0,
                  onChanged: (val) {
                    onChanged(value.copyWith(luminance: val));
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final WheelChannelValue value;
  final Color accentColor;

  const _ColorWheelPainter({
    required this.value,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Draw outer hue sweep gradient
    final sweepGradient = SweepGradient(
      colors: const [
        Color(0xFFFF0000), // Red
        Color(0xFFFFFF00), // Yellow
        Color(0xFF00FF00), // Green
        Color(0xFF00FFFF), // Cyan
        Color(0xFF0000FF), // Blue
        Color(0xFFFF00FF), // Magenta
        Color(0xFFFF0000), // Red
      ],
      stops: const [0.0, 0.166, 0.333, 0.5, 0.666, 0.833, 1.0],
    );

    final huePaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, huePaint);

    // 2. Overlay radial saturation gradient (center neutral white -> transparent edge)
    final satGradient = RadialGradient(
      colors: [
        const Color(0xFF2D3436).withOpacity(0.96),
        const Color(0xFF2D3436).withOpacity(0.40),
        Colors.transparent,
      ],
      stops: const [0.0, 0.65, 1.0],
    );
    final satPaint = Paint()
      ..shader = satGradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, satPaint);

    // 3. Subtle center neutral reticle
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 4.0, centerPaint);
    canvas.drawLine(Offset(center.dx - 6, center.dy), Offset(center.dx + 6, center.dy), centerPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 6), Offset(center.dx, center.dy + 6), centerPaint);

    // 4. Outer border ring
    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, borderPaint);

    // 5. Draggable control puck indicator
    final rad = value.angle * (math.pi / 180.0);
    final puckDistance = value.saturation * radius;
    final puckPos = Offset(
      center.dx + math.cos(rad) * puckDistance,
      center.dy + math.sin(rad) * puckDistance,
    );

    final puckOuterGlow = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(puckPos, 7.0, puckOuterGlow);

    final puckRing = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(puckPos, 6.0, puckRing);

    final puckFill = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(puckPos, 3.5, puckFill);
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.accentColor != accentColor;
  }
}
