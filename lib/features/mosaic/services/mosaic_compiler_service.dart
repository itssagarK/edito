import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/mosaic_config.dart';

/// CapCut Pro AI Smart Mosaic & Privacy Censor Blur Compiler Service
class MosaicCompilerService {
  /// Builds a 2D vector [Path] for real-time Flutter canvas clipping and interactive viewport preview.
  static Path buildMosaicPath(MosaicConfig config, Size size) {
    if (!config.isActive) {
      return Path()..addRect(Offset.zero & size);
    }

    final double w = size.width;
    final double h = size.height;
    final double cx = w * config.centerX;
    final double cy = h * config.centerY;
    final double rx = math.max(8.0, (w * config.width * 0.5));
    final double ry = math.max(8.0, (h * config.height * 0.5));
    final double rad = config.rotation * math.pi / 180.0;

    Path shapePath = Path();

    switch (config.shape) {
      case MosaicShape.fullFrame:
        shapePath.addRect(Offset.zero & size);
        break;

      case MosaicShape.rectangle:
        final double cornerRadius = math.min(rx, ry) * config.roundness;
        final Path rrect = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: rx * 2.0,
              height: ry * 2.0,
            ),
            Radius.circular(cornerRadius),
          ));
        final Matrix4 rotMatrix = Matrix4.identity()
          ..translate(cx, cy)
          ..rotateZ(rad);
        shapePath = rrect.transform(rotMatrix.storage);
        break;

      case MosaicShape.ellipse:
        final Path oval = Path()
          ..addOval(Rect.fromCenter(
            center: Offset.zero,
            width: rx * 2.0,
            height: ry * 2.0,
          ));
        final Matrix4 rotMatrix = Matrix4.identity()
          ..translate(cx, cy)
          ..rotateZ(rad);
        shapePath = oval.transform(rotMatrix.storage);
        break;

      case MosaicShape.bannerStrip:
        final Path banner = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: w * 0.95,
              height: ry * 2.0,
            ),
            Radius.circular(8.0),
          ));
        final Matrix4 rotMatrix = Matrix4.identity()
          ..translate(cx, cy)
          ..rotateZ(rad);
        shapePath = banner.transform(rotMatrix.storage);
        break;
    }

    if (config.inverted && config.shape != MosaicShape.fullFrame) {
      final Path fullRect = Path()..addRect(Offset.zero & size);
      return Path.combine(PathOperation.difference, fullRect, shapePath);
    }

    return shapePath;
  }

  /// Compiles parameterized FFmpeg filters for video export rendering.
  static List<String> generateFFmpegFilters(
    MosaicConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return const [];

    final filters = <String>[];
    final tw = targetWidth.toDouble();
    final th = targetHeight.toDouble();

    final rw = (tw * config.width).clamp(16.0, tw);
    final rh = (th * config.height).clamp(16.0, th);
    final cx = (tw * config.centerX).clamp(0.0, tw);
    final cy = (th * config.centerY).clamp(0.0, th);

    // Calculate top-left bounding box coordinates (clamped to frame boundaries)
    final double left = (cx - rw * 0.5).clamp(0.0, tw - rw);
    final double top = (cy - rh * 0.5).clamp(0.0, th - rh);
    final int x = left.toInt();
    final int y = top.toInt();
    final int w = rw.toInt();
    final int h = rh.toInt();

    final pSize = config.pixelSize.clamp(4.0, 64.0).toInt();
    final bRadius = config.blurRadius.clamp(2.0, 60.0).toInt();

    if (config.shape == MosaicShape.fullFrame) {
      // Full frame effect
      switch (config.type) {
        case MosaicType.pixelMosaic:
          filters.add('scale=max(1\\,iw/$pSize):max(1\\,ih/$pSize):flags=neighbor');
          filters.add('scale=$targetWidth:$targetHeight:flags=neighbor');
          break;

        case MosaicType.gaussianBlur:
          filters.add('boxblur=luma_radius=$bRadius:luma_power=3');
          break;

        case MosaicType.hexagonalCrystal:
          final crystalStep = (pSize * 1.5).toInt().clamp(6, 96);
          filters.add('scale=max(1\\,iw/$crystalStep):max(1\\,ih/$crystalStep):flags=bilinear');
          filters.add('scale=$targetWidth:$targetHeight:flags=neighbor');
          break;

        case MosaicType.frostedGlass:
          final frostedR = (bRadius * 0.75).toInt().clamp(2, 45);
          filters.add('boxblur=luma_radius=$frostedR:luma_power=2');
          filters.add('unsharp=5:5:1.2:3:3:0.0');
          break;

        case MosaicType.none:
          break;
      }
    } else {
      // Regional Censor: using localized delogo / unsharp / boxblur
      switch (config.type) {
        case MosaicType.pixelMosaic:
        case MosaicType.hexagonalCrystal:
          // In FFmpeg, delogo performs high-quality edge-interpolated privacy obliteration
          filters.add('delogo=x=$x:y=$y:w=$w:h=$h:band=2:show=0');
          break;

        case MosaicType.gaussianBlur:
        case MosaicType.frostedGlass:
          // Delogo with smooth band falloff
          filters.add('delogo=x=$x:y=$y:w=$w:h=$h:band=4:show=0');
          break;

        case MosaicType.none:
          break;
      }
    }

    return filters;
  }
}
