import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/color_grading_config.dart';

class ColorScopesWidget extends StatelessWidget {
  final ColorGradingConfig config;

  const ColorScopesWidget({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Grid lines (0%, 50%, 100% IRE)
            Positioned.fill(
              child: CustomPaint(
                painter: _ScopeGridPainter(),
              ),
            ),
            // Real-time calculated RGB scope waveform
            Positioned.fill(
              child: CustomPaint(
                painter: _RgbWaveformPainter(config: config),
              ),
            ),
            // Header label
            Positioned(
              top: 3,
              left: 6,
              child: Text(
                'RGB SCOPES • 0-100 IRE',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.textMuted.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0;

    // 100 IRE (top ceiling)
    canvas.drawLine(Offset(0, 4), Offset(size.width, 4), gridPaint);
    // 50 IRE (midline)
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), gridPaint);
    // 0 IRE (bottom floor)
    canvas.drawLine(Offset(0, size.height - 4), Offset(size.width, size.height - 4), gridPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RgbWaveformPainter extends CustomPainter {
  final ColorGradingConfig config;

  const _RgbWaveformPainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    if (width <= 0 || height <= 0) return;

    // Calculate parameter shifts on curve
    final exposureShift = config.exposure * 0.15;
    final contrastMult = config.contrast * config.clarity;
    final tempShift = (config.temperature / 100.0) * 0.15;
    final tintShift = (config.tint / 100.0) * 0.12;

    final redPaint = Paint()
      ..color = const Color(0xFFFF2A2A).withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final greenPaint = Paint()
      ..color = const Color(0xFF00FF66).withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final bluePaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rPath = Path();
    final gPath = Path();
    final bPath = Path();

    const steps = 32;
    for (int i = 0; i <= steps; i++) {
      final xNorm = i / steps;
      final x = xNorm * width;

      // Base luminance ramp
      double yBase = xNorm;

      // Apply contrast centering at 0.5
      yBase = 0.5 + (yBase - 0.5) * contrastMult + config.brightness * 0.2 + exposureShift;

      // Highlights & Shadows compression
      if (xNorm < 0.4) {
        yBase += config.shadows * 0.15 * (1.0 - (xNorm / 0.4));
        yBase += config.fade * 0.10;
        yBase += config.blacks * 0.10;
      } else if (xNorm > 0.6) {
        yBase += config.highlights * 0.15 * ((xNorm - 0.6) / 0.4);
        yBase += config.whites * 0.10;
      }

      // Add small undulating waveform noise
      final wave = 0.03 * math.sin(xNorm * 18.0);

      // Red channel curve
      final rVal = (yBase + wave + tempShift + (tintShift * 0.5)).clamp(0.02, 0.98);
      final rY = height - (rVal * (height - 8) + 4);

      // Green channel curve
      final gVal = (yBase + wave - tintShift).clamp(0.02, 0.98);
      final gY = height - (gVal * (height - 8) + 4);

      // Blue channel curve
      final bVal = (yBase + wave - tempShift + (tintShift * 0.5)).clamp(0.02, 0.98);
      final bY = height - (bVal * (height - 8) + 4);

      if (i == 0) {
        rPath.moveTo(x, rY);
        gPath.moveTo(x, gY);
        bPath.moveTo(x, bY);
      } else {
        rPath.lineTo(x, rY);
        gPath.lineTo(x, gY);
        bPath.lineTo(x, bY);
      }
    }

    canvas.drawPath(rPath, redPaint);
    canvas.drawPath(gPath, greenPaint);
    canvas.drawPath(bPath, bluePaint);
  }

  @override
  bool shouldRepaint(covariant _RgbWaveformPainter oldDelegate) =>
      oldDelegate.config != config;
}
