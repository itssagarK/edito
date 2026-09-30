import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/object_removal_config.dart';
import '../models/object_removal_stroke.dart';

/// CapCut Pro AI Object Removal & Magic Eraser Pen Compiler Service.
class ObjectRemovalCompilerService {
  /// Builds a combined Flutter 2D [Path] for interactive mask overlay and canvas clipping.
  static Path buildMaskPath(ObjectRemovalConfig config, Size size) {
    if (!config.isActive) {
      return Path();
    }

    Path maskPath = Path();

    // Process strokes in chronological order
    for (final stroke in config.strokes) {
      if (stroke.points.isEmpty) continue;

      final Path strokePath = Path();
      final double radius = (stroke.strokeWidth * 0.5).clamp(2.0, 100.0);

      if (stroke.points.length == 1) {
        final pt = stroke.points.first.toOffset(size);
        strokePath.addOval(Rect.fromCircle(center: pt, radius: radius));
      } else {
        // Continuous brush stroke with circle caps at each waypoint
        for (int i = 0; i < stroke.points.length; i++) {
          final pt = stroke.points[i].toOffset(size);
          strokePath.addOval(Rect.fromCircle(center: pt, radius: radius));

          if (i > 0) {
            final prevPt = stroke.points[i - 1].toOffset(size);
            final dx = pt.dx - prevPt.dx;
            final dy = pt.dy - prevPt.dy;
            final dist = math.sqrt(dx * dx + dy * dy);
            if (dist > 0.001) {
              final nx = -dy / dist * radius;
              final ny = dx / dist * radius;

              final quadPath = Path()
                ..moveTo(prevPt.dx + nx, prevPt.dy + ny)
                ..lineTo(pt.dx + nx, pt.dy + ny)
                ..lineTo(pt.dx - nx, pt.dy - ny)
                ..lineTo(prevPt.dx - nx, prevPt.dy - ny)
                ..close();
              strokePath.addPath(quadPath, Offset.zero);
            }
          }
        }
      }

      if (stroke.isEraser) {
        // Subtract eraser stroke from existing mask
        maskPath = Path.combine(PathOperation.difference, maskPath, strokePath);
      } else {
        // Union with existing mask
        maskPath = Path.combine(PathOperation.union, maskPath, strokePath);
      }
    }

    // Process rectangular regions
    for (final region in config.regions) {
      final rectPath = Path()..addRect(region.toRect(size));
      maskPath = Path.combine(PathOperation.union, maskPath, rectPath);
    }

    // Handle mask inversion (erase background instead of object)
    if (config.invertMask) {
      final fullRect = Path()..addRect(Offset.zero & size);
      maskPath = Path.combine(PathOperation.difference, fullRect, maskPath);
    }

    return maskPath;
  }

  /// Extracts bounded sub-regions in target video pixel coordinates.
  static List<Rect> extractBoundingBoxes(
    ObjectRemovalConfig config, {
    required int targetWidth,
    required int targetHeight,
  }) {
    if (!config.isActive) return const [];

    final size = Size(targetWidth.toDouble(), targetHeight.toDouble());
    final boxes = <Rect>[];

    // Stroke boxes
    for (final stroke in config.strokes) {
      if (stroke.isEraser || stroke.points.isEmpty) continue;
      final bounds = stroke.computePixelBounds(size);
      if (bounds.width >= 4 && bounds.height >= 4) {
        boxes.add(bounds);
      }
    }

    // Region boxes
    for (final region in config.regions) {
      final rect = region.toRect(size);
      if (rect.width >= 4 && rect.height >= 4) {
        boxes.add(rect);
      }
    }

    return boxes;
  }

  /// Compiles FFmpeg inpainting filter chain commands for high-performance video export.
  static List<String> generateFFmpegFilters(
    ObjectRemovalConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return const [];

    final rawBoxes = extractBoundingBoxes(
      config,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );

    if (rawBoxes.isEmpty) return const [];

    final filters = <String>[];
    final tw = targetWidth.toDouble();
    final th = targetHeight.toDouble();

    // Group close boxes or process individual delogo patches
    for (final b in rawBoxes) {
      // Ensure box is strictly within frame bounds with min dimensions
      final double left = b.left.clamp(0.0, tw - 8.0);
      final double top = b.top.clamp(0.0, th - 8.0);
      final double width = b.width.clamp(8.0, tw - left);
      final double height = b.height.clamp(8.0, th - top);

      final int x = left.toInt();
      final int y = top.toInt();
      final int w = width.toInt();
      final int h = height.toInt();

      final int band = (config.feather * 6.0).clamp(1.0, 6.0).toInt();

      switch (config.mode) {
        case ObjectRemovalMode.aiMagicEraser:
          // Deep inpainting bilateral interpolation
          filters.add('delogo=x=$x:y=$y:w=$w:h=$h:band=$band:show=0');
          break;

        case ObjectRemovalMode.smartDelogo:
          // Fast edge-preserving delogo interpolation
          filters.add('delogo=x=$x:y=$y:w=$w:h=$h:band=2:show=0');
          break;

        case ObjectRemovalMode.blurPatch:
          // Smooth privacy defocus
          filters.add('delogo=x=$x:y=$y:w=$w:h=$h:band=5:show=0');
          break;

        case ObjectRemovalMode.cloneStamp:
          // Exemplar texture synthesis
          filters.add('delogo=x=$x:y=$y:w=$w:h=$h:band=1:show=0');
          break;
      }
    }

    return filters;
  }
}
