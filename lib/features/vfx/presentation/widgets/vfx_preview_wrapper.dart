import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/vfx_config.dart';

class VfxPreviewWrapper extends StatelessWidget {
  final VfxConfig config;
  final Widget child;
  final int playheadPositionMs;

  const VfxPreviewWrapper({
    super.key,
    required this.config,
    required this.child,
    this.playheadPositionMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isActive) {
      return child;
    }

    Widget content = child;

    // 1. Optical Lens Blur / Radial Zoom
    if (config.type == VfxType.lensBlur) {
      final sigma = (config.blurRadius * config.intensity * 0.5).clamp(0.1, 15.0);
      content = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: content,
      );
    } else if (config.type == VfxType.radialZoom) {
      final sigma = (config.blurRadius * config.intensity * 0.3).clamp(0.1, 8.0);
      content = Transform.scale(
        scale: 1.0 + (config.intensity * 0.04),
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: content,
        ),
      );
    }

    // 2. Camera Shake / Tremor
    if (config.type == VfxType.cameraShake) {
      final t = (playheadPositionMs / 50.0) * config.speed;
      final amp = config.shakeAmplitude * config.intensity * 0.5;
      final dx = math.sin(t * 1.8) * amp;
      final dy = math.cos(t * 1.4) * amp;
      content = Transform.translate(
        offset: Offset(dx, dy),
        child: content,
      );
    }

    // 3. Visual FX Overlays
    return Stack(
      fit: StackFit.passthrough,
      children: [
        content,

        // 35mm Analog Film Grain Overlay
        if (config.type == VfxType.filmGrain)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FilmGrainPainter(
                  intensity: config.intensity,
                  seed: (playheadPositionMs ~/ 60),
                ),
              ),
            ),
          ),

        // RGB Glitch / Chromatic Aberration Overlay
        if (config.type == VfxType.rgbGlitch)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _RgbGlitchPainter(
                  intensity: config.intensity,
                  rgbOffset: config.rgbOffset,
                  seed: (playheadPositionMs ~/ 80),
                ),
              ),
            ),
          ),

        // Retro VHS Scanlines & CRT Overlay
        if (config.type == VfxType.vhsVintage)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _VhsScanlinePainter(
                  intensity: config.intensity,
                  playheadMs: playheadPositionMs,
                ),
              ),
            ),
          ),

        // Cinematic Optical Vignette
        if (config.type == VfxType.vignette)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: config.vignetteRadius.clamp(0.2, 0.9),
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity((config.intensity * 0.85).clamp(0.0, 0.95)),
                    ],
                    stops: [
                      (1.0 - config.vignetteSoftness).clamp(0.1, 0.8),
                      1.0,
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Golden Hour Light Leak Pulse
        if (config.type == VfxType.lightLeak)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF9900).withOpacity(config.intensity * 0.35),
                      const Color(0xFFFF3366).withOpacity(config.intensity * 0.20),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 0.85],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilmGrainPainter extends CustomPainter {
  final double intensity;
  final int seed;

  _FilmGrainPainter({required this.intensity, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(seed);
    final count = (size.width * size.height * 0.0008 * intensity).toInt().clamp(50, 400);
    final paint = Paint()
      ..color = Colors.white.withOpacity(intensity * 0.18)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rand.nextDouble() * 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FilmGrainPainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.intensity != intensity;
  }
}

class _RgbGlitchPainter extends CustomPainter {
  final double intensity;
  final double rgbOffset;
  final int seed;

  _RgbGlitchPainter({
    required this.intensity,
    required this.rgbOffset,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(seed);
    final offset = rgbOffset * intensity;

    // Red fringe line pulses
    final redPaint = Paint()
      ..color = const Color(0xFFFF0055).withOpacity(intensity * 0.28)
      ..style = PaintingStyle.fill;

    // Cyan fringe line pulses
    final cyanPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(intensity * 0.28)
      ..style = PaintingStyle.fill;

    final glitchBands = (rand.nextInt(3) + 1);
    for (int i = 0; i < glitchBands; i++) {
      final y = rand.nextDouble() * size.height;
      final h = rand.nextDouble() * 18.0 + 4.0;
      canvas.drawRect(Rect.fromLTWH(offset, y, size.width - offset, h), redPaint);
      canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width - offset, h), cyanPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RgbGlitchPainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.intensity != intensity;
  }
}

class _VhsScanlinePainter extends CustomPainter {
  final double intensity;
  final int playheadMs;

  _VhsScanlinePainter({required this.intensity, required this.playheadMs});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(intensity * 0.35)
      ..strokeWidth = 1.0;

    const spacing = 4.0;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Analog warm sepia/amber tint
    final tintPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(intensity * 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tintPaint);
  }

  @override
  bool shouldRepaint(covariant _VhsScanlinePainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}
