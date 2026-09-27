import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/edge_aura_config.dart';

/// CapCut Pro AI Video Glow & Edge Aura Studio Compiler Service
class EdgeAuraCompilerService {
  /// Builds a real-time GPU hardware-accelerated Skia aura overlay for the viewport
  static Widget buildAuraOverlay(EdgeAuraConfig config, Size viewportSize) {
    if (!config.isEnabled || config.style == EdgeGlowStyle.none || config.intensity <= 0.0) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        size: viewportSize,
        painter: EdgeAuraPainter(config: config),
      ),
    );
  }

  /// Generates deterministic FFmpeg video filter chains for export compilation
  static List<String> generateFFmpegFilters(EdgeAuraConfig config) {
    if (!config.isEnabled || config.style == EdgeGlowStyle.none || config.intensity <= 0.0) {
      return const [];
    }

    final filters = <String>[];
    final intensity = config.intensity.clamp(0.0, 2.0);

    // Extract color channels (0.0 to 1.0)
    final r = (((config.colorValue >> 16) & 0xFF) / 255.0);
    final g = (((config.colorValue >> 8) & 0xFF) / 255.0);
    final b = ((config.colorValue & 0xFF) / 255.0);

    // 1. Edge detection parameters based on sensitivity threshold
    final low = (config.threshold * 0.45).clamp(0.02, 0.40).toStringAsFixed(3);
    final high = (config.threshold * 1.40).clamp(0.08, 0.85).toStringAsFixed(3);

    // Filter 1: Edge detection with colormix mode for silhouette contour overlay
    filters.add('edgedetect=low=$low:high=$high:mode=colormix');

    // 2. Chromatic tinting matching the glow aura color
    final rh = ((r - 0.40) * 0.55 * (intensity * 0.75)).clamp(-1.0, 1.0);
    final gh = ((g - 0.40) * 0.55 * (intensity * 0.75)).clamp(-1.0, 1.0);
    final bh = ((b - 0.40) * 0.55 * (intensity * 0.75)).clamp(-1.0, 1.0);

    final rm = ((r - 0.50) * 0.25 * (intensity * 0.50)).clamp(-1.0, 1.0);
    final gm = ((g - 0.50) * 0.25 * (intensity * 0.50)).clamp(-1.0, 1.0);
    final bm = ((b - 0.50) * 0.25 * (intensity * 0.50)).clamp(-1.0, 1.0);

    final cbParts = <String>[];
    if (rh.abs() > 0.005) cbParts.add('rh=${rh.toStringAsFixed(3)}');
    if (gh.abs() > 0.005) cbParts.add('gh=${gh.toStringAsFixed(3)}');
    if (bh.abs() > 0.005) cbParts.add('bh=${bh.toStringAsFixed(3)}');
    if (rm.abs() > 0.005) cbParts.add('rm=${rm.toStringAsFixed(3)}');
    if (gm.abs() > 0.005) cbParts.add('gm=${gm.toStringAsFixed(3)}');
    if (bm.abs() > 0.005) cbParts.add('bm=${bm.toStringAsFixed(3)}');

    if (cbParts.isNotEmpty) {
      filters.add('colorbalance=${cbParts.join(":")}');
    }

    // 3. Chromatic RGB Ghost split
    if (config.style == EdgeGlowStyle.rgbGhost) {
      filters.add('rgbashift=rh=6:bv=-6');
    }

    // 4. Bloom radiance and contrast enhancement
    final contrast = (1.0 + (0.15 * intensity)).clamp(1.0, 1.35).toStringAsFixed(3);
    final baseBrightness = (0.04 * intensity).clamp(0.0, 0.12);

    if (config.pulseSpeed > 0.0) {
      // Dynamic breathing expression with frame-accurate timestamp evaluation
      final pulseAmp = (0.04 * intensity).clamp(0.01, 0.08).toStringAsFixed(3);
      final freq = (2.0 * math.pi * config.pulseSpeed).toStringAsFixed(3);
      filters.add(
        "eq=contrast=$contrast:brightness='${baseBrightness.toStringAsFixed(3)}+$pulseAmp*sin($freq*t)':eval=frame",
      );
    } else {
      filters.add('eq=contrast=$contrast:brightness=${baseBrightness.toStringAsFixed(3)}');
    }

    return filters;
  }
}

/// Skia GPU hardware-accelerated CustomPainter that renders glowing aura contours
class EdgeAuraPainter extends CustomPainter {
  final EdgeAuraConfig config;

  const EdgeAuraPainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final primaryColor = Color(config.colorValue);
    final intensity = config.intensity.clamp(0.0, 2.0);
    final alphaMultiplier = (intensity * 0.45).clamp(0.0, 0.90);

    final auraPaint = Paint()
      ..blendMode = config.blendMode == GlowBlendMode.addition
          ? BlendMode.plus
          : config.blendMode == GlowBlendMode.overlay
              ? BlendMode.overlay
              : BlendMode.screen
      ..isAntiAlias = true;

    final rect = Offset.zero & size;
    final center = rect.center;
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2.0;

    // 1. Soft ambient aura vignette radiating from perimeter inward
    final ambientGradient = RadialGradient(
      center: Alignment.center,
      radius: 0.95,
      colors: [
        Colors.transparent,
        primaryColor.withOpacity(alphaMultiplier * 0.15),
        primaryColor.withOpacity(alphaMultiplier * 0.45),
      ],
      stops: const [0.65, 0.88, 1.0],
    );

    auraPaint.shader = ambientGradient.createShader(rect);
    canvas.drawRect(rect, auraPaint);

    // 2. High-contrast edge contour border stroke simulating neon wireframe
    final strokeWidth = (config.radius * 0.35).clamp(2.0, 16.0);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = primaryColor.withOpacity(alphaMultiplier * 0.60)
      ..blendMode = BlendMode.screen
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, config.radius * 0.4);

    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth,
        strokeWidth,
        size.width - (strokeWidth * 2),
        size.height - (strokeWidth * 2),
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(innerRect, borderPaint);

    // 3. Chromatic fringe for RGB Ghost
    if (config.style == EdgeGlowStyle.rgbGhost) {
      final cyanPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.8
        ..color = const Color(0xFF00FFFF).withOpacity(alphaMultiplier * 0.5)
        ..blendMode = BlendMode.screen;
      final magentaPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.8
        ..color = const Color(0xFFFF00FF).withOpacity(alphaMultiplier * 0.5)
        ..blendMode = BlendMode.screen;

      canvas.drawRRect(innerRect.shift(const Offset(-3, 0)), cyanPaint);
      canvas.drawRRect(innerRect.shift(const Offset(3, 0)), magentaPaint);
    }
  }

  @override
  bool shouldRepaint(covariant EdgeAuraPainter oldDelegate) {
    return oldDelegate.config != config;
  }
}
