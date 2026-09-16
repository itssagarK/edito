import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BeatMarkersOverlayPainter extends CustomPainter {
  final List<int> beatTimestampsMs;
  final int clipDurationMs;
  final Color markerColor;

  const BeatMarkersOverlayPainter({
    required this.beatTimestampsMs,
    required this.clipDurationMs,
    this.markerColor = const Color(0xFFFFD700), // Golden Yellow
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (clipDurationMs <= 0 || beatTimestampsMs.isEmpty) return;

    final dotPaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = markerColor.withOpacity(0.40)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = markerColor.withOpacity(0.55)
      ..strokeWidth = 1.2;

    for (final beatMs in beatTimestampsMs) {
      if (beatMs < 0 || beatMs > clipDurationMs) continue;

      final normX = beatMs / clipDurationMs;
      final x = normX * size.width;

      // Vertical tick mark
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        linePaint,
      );

      // Top glowing circular bead marker
      canvas.drawCircle(Offset(x, 4), 4.5, glowPaint);
      canvas.drawCircle(Offset(x, 4), 2.5, dotPaint);

      // Bottom anchor bead marker
      canvas.drawCircle(Offset(x, size.height - 4), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BeatMarkersOverlayPainter oldDelegate) {
    return oldDelegate.beatTimestampsMs != beatTimestampsMs ||
        oldDelegate.clipDurationMs != clipDurationMs ||
        oldDelegate.markerColor != markerColor;
  }
}
