import 'dart:math';
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final Color color;
  final int seed;
  final List<double>? pcmPeaks;

  const WaveformPainter({
    required this.color,
    this.seed = 42,
    this.pcmPeaks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.65)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final barSpacing = 4.0;
    final barCount = (size.width / barSpacing).floor();
    if (barCount <= 0) return;

    final centerY = size.height / 2;

    // 1. If real PCM peaks are provided, render deterministic sample amplitudes
    if (pcmPeaks != null && pcmPeaks!.isNotEmpty) {
      final peaks = pcmPeaks!;
      for (int i = 0; i < barCount; i++) {
        final x = i * barSpacing;
        final peakIndex = ((i / barCount) * peaks.length).floor().clamp(0, peaks.length - 1);
        final peakVal = peaks[peakIndex].clamp(0.05, 1.0);
        final barHeight = (size.height * 0.85 * peakVal).clamp(3.0, size.height * 0.90);

        final top = centerY - (barHeight / 2);
        final bottom = centerY + (barHeight / 2);
        canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
      }
      return;
    }

    // 2. Otherwise render naturalistic pseudo-deterministic waveform envelope
    final random = Random(seed);
    for (int i = 0; i < barCount; i++) {
      final x = i * barSpacing;
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
    return oldDelegate.color != color || oldDelegate.seed != seed || oldDelegate.pcmPeaks != pcmPeaks;
  }
}
