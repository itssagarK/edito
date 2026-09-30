import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/face_reshape_config.dart';

/// CapCut Pro AI Face Reshape & 3D Feature Sculpting Compiler Service.
class FaceReshapeCompilerService {
  /// Calculates 2D normalized landmark anchor coordinates across facial zones for viewport HUD.
  static Map<String, Offset> calculateFacialLandmarks(
    FaceReshapeConfig config,
    Size size, {
    Offset faceCenter = const Offset(0.5, 0.48),
  }) {
    final double cx = size.width * faceCenter.dx;
    final double cy = size.height * faceCenter.dy;
    final double faceW = size.width * 0.38;
    final double faceH = size.height * 0.46;

    final double effIntensity = config.intensity.clamp(0.0, 1.0);

    // Apply sculpting offsets
    final double slimOffset = (config.faceSlimming * 0.15 + config.vFace * 0.20) * effIntensity;
    final double chinYOffset = (config.chinLength * 0.12 - config.pointyChin * 0.08) * effIntensity;
    final double jawNarrow = (config.jawbone * 0.15 + config.vFace * 0.12) * effIntensity;
    final double eyeSpan = (config.eyeDistance * 0.10) * effIntensity;
    final double eyeZoom = (config.eyeSize * 0.15) * effIntensity;
    final double eyeY = (config.eyePosition * 0.08) * effIntensity;
    final double noseW = (config.noseSize * 0.12) * effIntensity;
    final double noseY = (config.noseBridge * 0.08) * effIntensity;
    final double mouthY = (config.mouthPosition * 0.08) * effIntensity;
    final double mouthW = (config.mouthSize * 0.12 + config.lipEnhance * 0.08) * effIntensity;
    final double smileY = (config.smileCorners * 0.08) * effIntensity;

    return {
      'forehead': Offset(cx, cy - faceH * 0.42 + (config.forehead * 0.05 * effIntensity * size.height)),
      'templeLeft': Offset(cx - faceW * (0.42 - config.temple * 0.05 * effIntensity), cy - faceH * 0.32),
      'templeRight': Offset(cx + faceW * (0.42 - config.temple * 0.05 * effIntensity), cy - faceH * 0.32),
      'leftEye': Offset(cx - faceW * (0.24 + eyeSpan) - eyeZoom * 10, cy - faceH * 0.14 + eyeY * size.height),
      'rightEye': Offset(cx + faceW * (0.24 + eyeSpan) + eyeZoom * 10, cy - faceH * 0.14 + eyeY * size.height),
      'nose': Offset(cx, cy + faceH * 0.04 - noseY * size.height),
      'noseLeft': Offset(cx - faceW * (0.10 + noseW), cy + faceH * 0.08),
      'noseRight': Offset(cx + faceW * (0.10 + noseW), cy + faceH * 0.08),
      'cheekLeft': Offset(cx - faceW * (0.44 - slimOffset - config.cheekbone * 0.08 * effIntensity), cy + faceH * 0.08),
      'cheekRight': Offset(cx + faceW * (0.44 - slimOffset - config.cheekbone * 0.08 * effIntensity), cy + faceH * 0.08),
      'mouthCenter': Offset(cx, cy + faceH * 0.22 + mouthY * size.height),
      'mouthLeft': Offset(cx - faceW * (0.18 + mouthW), cy + faceH * 0.22 - smileY * size.height),
      'mouthRight': Offset(cx + faceW * (0.18 + mouthW), cy + faceH * 0.22 - smileY * size.height),
      'jawLeft': Offset(cx - faceW * (0.34 - jawNarrow), cy + faceH * 0.34),
      'jawRight': Offset(cx + faceW * (0.34 - jawNarrow), cy + faceH * 0.34),
      'chin': Offset(cx, cy + faceH * 0.46 + chinYOffset * size.height),
    };
  }

  /// Builds a continuous wireframe contour path of the sculpted face.
  static Path buildLandmarkContourPath(FaceReshapeConfig config, Size size) {
    final lm = calculateFacialLandmarks(config, size);
    final path = Path();

    // Outer jawline contour: templeLeft -> cheekLeft -> jawLeft -> chin -> jawRight -> cheekRight -> templeRight
    path.moveTo(lm['templeLeft']!.dx, lm['templeLeft']!.dy);
    path.quadraticBezierTo(lm['cheekLeft']!.dx, lm['cheekLeft']!.dy, lm['jawLeft']!.dx, lm['jawLeft']!.dy);
    path.quadraticBezierTo(lm['jawLeft']!.dx * 0.7 + lm['chin']!.dx * 0.3, lm['chin']!.dy * 0.95, lm['chin']!.dx, lm['chin']!.dy);
    path.quadraticBezierTo(lm['jawRight']!.dx * 0.7 + lm['chin']!.dx * 0.3, lm['chin']!.dy * 0.95, lm['jawRight']!.dx, lm['jawRight']!.dy);
    path.quadraticBezierTo(lm['cheekRight']!.dx, lm['cheekRight']!.dy, lm['templeRight']!.dx, lm['templeRight']!.dy);

    return path;
  }

  /// Compiles FFmpeg video filter chains for export rendering.
  static List<String> generateFFmpegFilters(
    FaceReshapeConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return const [];

    final filters = <String>[];
    final double intensity = config.intensity.clamp(0.0, 1.0);

    // Calculate barrel/pincushion lens distortion parameters
    // Positive slimming -> pincushion distortion (k1 < 0)
    final double combinedSlim = (config.faceSlimming * 0.08 + config.vFace * 0.10) * intensity;
    final double k1 = -combinedSlim.clamp(-0.15, 0.15);
    final double k2 = (k1 * 0.4);

    if (k1.abs() > 0.005) {
      filters.add('lenscorrection=cx=0.5:cy=0.5:k1=${k1.toStringAsFixed(4)}:k2=${k2.toStringAsFixed(4)}');
    }

    // Unsharp filter to restore texture definition around sculpted boundaries
    filters.add('unsharp=3:3:0.4:3:3:0.0');

    return filters;
  }
}
