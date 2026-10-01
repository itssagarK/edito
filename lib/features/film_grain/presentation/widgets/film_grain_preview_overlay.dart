import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/film_grain_type.dart';
import '../../models/film_grain_config.dart';
import '../../services/film_grain_compiler_service.dart';

/// Lightweight real-time preview overlay simulating organic film grain on Skia viewport.
class FilmGrainPreviewOverlay extends StatelessWidget {
  final FilmGrainConfig config;
  final int seed;

  const FilmGrainPreviewOverlay({
    super.key,
    required this.config,
    this.seed = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isActive) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _FilmGrainPainter(
            config: config,
            seed: seed,
          ),
        ),
      ),
    );
  }
}

class _FilmGrainPainter extends CustomPainter {
  final FilmGrainConfig config;
  final int seed;

  const _FilmGrainPainter({
    required this.config,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || !config.isActive) return;

    final random = math.Random(config.animate ? seed : 42);
    final count = (size.width * size.height * 0.00035 * config.intensity).toInt().clamp(40, 600);
    final dotRadius = (config.grainSize * 0.85).clamp(0.5, 3.0);

    final isMonochrome = (config.type == FilmGrainType.silverHalide || config.roughness <= 0.05);

    for (int i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      // Pseudo-random luminance noise sample
      final lumaSample = random.nextDouble();
      final lumaWeight = FilmGrainCompilerService.calculateLumaMask(
        lumaSample,
        shadowSuppression: config.shadowSuppression,
        highlightSuppression: config.highlightSuppression,
      );

      final alpha = (config.intensity * lumaWeight * 0.45).clamp(0.04, 0.45);
      final isBright = random.nextBool();

      Color dotColor;
      if (isMonochrome) {
        dotColor = isBright
            ? Colors.white.withOpacity(alpha)
            : Colors.black.withOpacity(alpha * 0.8);
      } else {
        // Subtle chromatic color drift for analog tape or color cinema stocks
        if (random.nextDouble() < config.roughness * 0.4) {
          final hue = random.nextDouble() * 360.0;
          dotColor = HSVColor.fromAHSV(alpha, hue, 0.6, isBright ? 0.9 : 0.2).toColor();
        } else {
          dotColor = isBright
              ? Colors.white.withOpacity(alpha)
              : Colors.black.withOpacity(alpha * 0.8);
        }
      }

      final paint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FilmGrainPainter oldDelegate) {
    return oldDelegate.config != config || (config.animate && oldDelegate.seed != seed);
  }
}
