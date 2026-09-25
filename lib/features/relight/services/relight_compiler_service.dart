import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/relight_config.dart';

/// CapCut Pro AI Video Relight & Virtual Studio Lighting Compiler Service
class RelightCompilerService {
  /// Builds a real-time GPU hardware-accelerated Skia lighting overlay widget for the viewport
  static Widget buildLightingOverlay(RelightConfig config, Size viewportSize) {
    if (!config.isEnabled || config.mode == RelightMode.none || config.intensity <= 0.0) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        size: viewportSize,
        painter: RelightPainter(config: config),
      ),
    );
  }

  /// Compiles deterministic FFmpeg filter chains for video rendering
  static List<String> generateFFmpegFilters(RelightConfig config) {
    if (!config.isEnabled || config.mode == RelightMode.none || config.intensity <= 0.0) {
      return const [];
    }

    final filters = <String>[];
    final intensity = config.intensity.clamp(0.0, 1.0);

    // Extract primary light color channels (normalized 0.0 to 1.0)
    final r = (((config.colorValue >> 16) & 0xFF) / 255.0);
    final g = (((config.colorValue >> 8) & 0xFF) / 255.0);
    final b = ((config.colorValue & 0xFF) / 255.0);

    // 1. Exposure and contrast key-fill boost
    final contrast = 1.0 + (0.12 * intensity);
    final brightness = 0.04 * intensity;

    filters.add('eq=contrast=${contrast.toStringAsFixed(3)}:brightness=${brightness.toStringAsFixed(3)}');

    // 2. Chromatic lighting tint on highlights and midtones via colorbalance
    final rh = ((r - 0.45) * 0.40 * intensity).clamp(-1.0, 1.0);
    final gh = ((g - 0.45) * 0.40 * intensity).clamp(-1.0, 1.0);
    final bh = ((b - 0.45) * 0.40 * intensity).clamp(-1.0, 1.0);

    final rm = ((r - 0.5) * 0.15 * intensity).clamp(-1.0, 1.0);
    final gm = ((g - 0.5) * 0.15 * intensity).clamp(-1.0, 1.0);
    final bm = ((b - 0.5) * 0.15 * intensity).clamp(-1.0, 1.0);

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

    // 3. Falloff / rim lighting curve adjustments
    if (config.mode == RelightMode.rimBacklight) {
      filters.add("curves=all='0/0 0.5/0.45 0.9/0.95 1/1'");
    } else if (config.mode == RelightMode.goldenSunbeam) {
      filters.add("curves=red='0/0 0.5/0.58 1/1':blue='0/0 0.5/0.42 1/1'");
    }

    return filters;
  }
}

/// Skia GPU CustomPainter that composites virtual directional lighting
class RelightPainter extends CustomPainter {
  final RelightConfig config;

  const RelightPainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final primaryColor = Color(config.colorValue);
    final intensity = config.intensity.clamp(0.0, 1.0);
    final primaryOpacity = (intensity * 0.65).clamp(0.0, 1.0);

    // Convert normalized light position (-1.0 to 1.0) to canvas offset
    final lightCenterX = (config.lightX + 1.0) / 2.0 * size.width;
    final lightCenterY = (config.lightY + 1.0) / 2.0 * size.height;
    final center = Offset(lightCenterX, lightCenterY);

    final maxDim = math.max(size.width, size.height);
    final lightRadius = (config.radius * maxDim * 0.55).clamp(20.0, maxDim * 2.0);
    final softness = config.softness.clamp(0.1, 1.0);

    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..isAntiAlias = true;

    if (config.mode == RelightMode.goldenSunbeam) {
      // Angular directional sunlight beam
      final rect = Offset.zero & size;
      final start = Offset(lightCenterX - size.width * 0.3, lightCenterY - size.height * 0.3);
      final end = Offset(lightCenterX + size.width * 0.6, lightCenterY + size.height * 0.6);

      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withOpacity(primaryOpacity * 0.9),
          primaryColor.withOpacity(primaryOpacity * 0.4),
          primaryColor.withOpacity(0.0),
        ],
        stops: [0.0, 0.45 * softness, 1.0],
      ).createShader(rect);

      canvas.drawRect(rect, paint);
    } else {
      // Primary Radial Lighting (Spotlight, Softbox, Ring Light, etc.)
      paint.shader = RadialGradient(
        center: Alignment(config.lightX, config.lightY),
        radius: (config.radius * 0.65).clamp(0.1, 2.0),
        colors: [
          primaryColor.withOpacity(primaryOpacity),
          primaryColor.withOpacity(primaryOpacity * 0.45),
          primaryColor.withOpacity(primaryOpacity * 0.12),
          Colors.transparent,
        ],
        stops: [0.0, 0.35 * softness, 0.70 * softness, 1.0],
      ).createShader(Offset.zero & size);

      canvas.drawRect(Offset.zero & size, paint);

      // Secondary Rim Light for Dual Setup (e.g. Cyber Neon Dual)
      if (config.secondaryColorValue != null) {
        final secondaryColor = Color(config.secondaryColorValue!);
        final rimPaint = Paint()
          ..blendMode = BlendMode.screen
          ..isAntiAlias = true
          ..shader = RadialGradient(
            center: Alignment(-config.lightX, -config.lightY),
            radius: (config.radius * 0.55).clamp(0.1, 2.0),
            colors: [
              secondaryColor.withOpacity(primaryOpacity * 0.85),
              secondaryColor.withOpacity(primaryOpacity * 0.35),
              Colors.transparent,
            ],
            stops: [0.0, 0.40 * softness, 1.0],
          ).createShader(Offset.zero & size);

        canvas.drawRect(Offset.zero & size, rimPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RelightPainter oldDelegate) {
    return oldDelegate.config != config;
  }
}
