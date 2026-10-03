import '../models/video_transform_config.dart';

/// Compiles [VideoTransformConfig] into deterministic FFmpeg video filter expressions.
///
/// Ensures 1:1 mathematical parity between viewport preview canvas transforms
/// (Matrix4 rotation, scale, FractionalTranslation) and the exported video stream.
class VideoTransformCompilerService {
  /// Generates the complete list of FFmpeg filters for rotation, flip, scale, and spatial canvas placement.
  static List<String> generateFFmpegFilters(
    VideoTransformConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return [];

    final filters = <String>[];

    // 1. 90-degree step rotations
    if (config.rotationDegrees == 90) {
      filters.add('transpose=1');
    } else if (config.rotationDegrees == 180) {
      filters.add('hflip,vflip');
    } else if (config.rotationDegrees == 270) {
      filters.add('transpose=2');
    }

    // 2. Horizontal & vertical mirror flips
    if (config.isFlippedHorizontal) {
      filters.add('hflip');
    }
    if (config.isFlippedVertical) {
      filters.add('vflip');
    }

    // 3. Spatial scale zoom & on-canvas translation
    final bool hasScale = (config.scale - 1.0).abs() > 0.005;
    final bool hasPosition = (config.positionX - 0.5).abs() > 0.005 || (config.positionY - 0.5).abs() > 0.005;

    if (hasScale || hasPosition) {
      final double s = config.scale.clamp(0.1, 5.0);
      final double px = config.positionX.clamp(0.0, 1.0);
      final double py = config.positionY.clamp(0.0, 1.0);

      if (s >= 1.0) {
        // Zoom-in / punch crop centered on user-defined (positionX, positionY)
        final sStr = s.toStringAsFixed(3);
        final dxStr = (px - 0.5).toStringAsFixed(3);
        final dyStr = (py - 0.5).toStringAsFixed(3);

        filters.add(
          "crop=w='min(iw,iw/$sStr)':h='min(ih,ih/$sStr)':"
          "x='max(0,min(iw-ow,(iw-ow)/2 - ($dxStr*iw)))':"
          "y='max(0,min(ih-oh,(ih-oh)/2 - ($dyStr*ih)))'",
        );
        filters.add('scale=$targetWidth:$targetHeight:flags=lanczos');
      } else {
        // Zoom-out: shrink and pad onto target canvas with alpha/black letterbox
        final scaledW = ((targetWidth * s).round() ~/ 2) * 2;
        final scaledH = ((targetHeight * s).round() ~/ 2) * 2;
        final offsetX = ((px - 0.5) * targetWidth).round();
        final offsetY = ((py - 0.5) * targetHeight).round();

        filters.add('scale=$scaledW:$scaledH:flags=lanczos');
        filters.add(
          "pad=$targetWidth:$targetHeight:"
          "x='max(0,min(ow-iw,(ow-iw)/2 + ($offsetX)))':"
          "y='max(0,min(oh-ih,(oh-ih)/2 + ($offsetY)))':"
          "color=black@0",
        );
      }
    }

    return filters;
  }
}
