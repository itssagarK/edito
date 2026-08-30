import 'dart:math';
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final Color color;
  final int seed;

  const WaveformPainter({
    required this.color,
    this.seed = 42,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.55)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final barSpacing = 4.0;
    final barCount = (size.width / barSpacing).floor();
    final random = Random(seed);

    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * barSpacing;
      // Simulated audio waveform envelope with natural speech/music rhythm
      final amplitudeFactor = (0.2 + (random.nextDouble() * 0.75)) *
          (sin(i * 0.15).abs() * 0.6 + 0.4);
      final barHeight = (size.height * 0.75 * amplitudeFactor).clamp(3.0, size.height * 0.85);

      final top = centerY - (barHeight / 2);
      final bottom = centerY + (barHeight / 2);

      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.seed != seed;
  }
}
