import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../models/stabilization_config.dart';

/// CapCut Pro AI Video Stabilization & Gyro Flow Compiler Service
class StabilizationCompilerService {
  /// Compiles stabilization settings into deterministic FFmpeg video filter commands
  static List<String> generateFFmpegFilters(
    StabilizationConfig config, {
    required int targetWidth,
    required int targetHeight,
  }) {
    if (!config.isEnabled || config.level == StabilizationLevel.none) {
      return const [];
    }

    final filters = <String>[];

    // 1. Motion search block radius scaled with smoothing strength
    final rx = (16 + (config.smoothingStrength * 48)).round().clamp(8, 64);
    final ry = (16 + (config.smoothingStrength * 48)).round().clamp(8, 64);
    final edgeStr = config.edgeMode == EdgePaddingMode.mirrorEdge ? 'mirror' : 'blank';
    final blockSize = config.algorithm == StabilizationAlgorithm.opticalDeshake ? 16 : 32;

    filters.add('deshake=x=-1:y=-1:w=-1:h=-1:rx=$rx:ry=$ry:edge=$edgeStr:blocksize=$blockSize');

    // 2. Adaptive Zoom Crop to eliminate shaky borders and fill canvas
    if (config.edgeMode == EdgePaddingMode.adaptiveCrop && config.cropMargin > 0.0) {
      final margin = config.cropMargin.clamp(0.01, 0.25);
      // Ensure even dimensions for standard codecs
      int cropW = (targetWidth * (1.0 - (margin * 2))).round();
      int cropH = (targetHeight * (1.0 - (margin * 2))).round();
      if (cropW % 2 != 0) cropW--;
      if (cropH % 2 != 0) cropH--;
      cropW = cropW.clamp(120, targetWidth);
      cropH = cropH.clamp(80, targetHeight);

      filters.add('crop=$cropW:$cropH:(in_w-$cropW)/2:(in_h-$cropH)/2');
      filters.add('scale=$targetWidth:$targetHeight:flags=lanczos');
    }

    return filters;
  }

  /// Calculates Skia Matrix4 transform for live viewport preview
  static Matrix4 computePreviewTransform(
    StabilizationConfig config,
    double progress, {
    bool rawPeek = false,
  }) {
    if (!config.isEnabled || config.level == StabilizationLevel.none || rawPeek) {
      return Matrix4.identity();
    }

    // Zoom scale to compensate for edge margin crop
    final zoomScale = (1.0 / (1.0 - (config.cropMargin.clamp(0.0, 0.25) * 1.5))).clamp(1.0, 1.45);

    // Counter-motion dampening simulation
    final angle = math.sin(progress * 2 * math.pi * 3) * (0.015 * (1.0 - config.rollDampening));
    final dx = math.cos(progress * 2 * math.pi * 2) * (12.0 * (1.0 - config.pitchYawDampening));
    final dy = math.sin(progress * 2 * math.pi * 2) * (8.0 * (1.0 - config.pitchYawDampening));

    final matrix = Matrix4.identity();
    matrix.scale(zoomScale, zoomScale, 1.0);
    matrix.translate(dx, dy, 0.0);
    matrix.rotateZ(angle);

    return matrix;
  }

  /// Generates the floating HUD status badge for active Stabilization
  static String getStabilizationBadge(StabilizationConfig config) {
    if (!config.isEnabled || config.level == StabilizationLevel.none) {
      return '';
    }

    final levelStr = config.level.label.toUpperCase();
    final cropPercent = (config.cropMargin * 100).round();
    final algoStr = config.algorithm == StabilizationAlgorithm.gyroFlow ? 'GYRO' : 'DESHAKE';

    return '🎯 STABILIZED ($levelStr • $cropPercent% CROP • $algoStr)';
  }
}
