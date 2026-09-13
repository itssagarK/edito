import '../models/hd_converter_config.dart';

class HdConverterService {
  /// Compiles HdConverterConfig into high-performance FFmpeg video filter commands
  static List<String> generateFFmpegFilters(
    HdConverterConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isEnabled) return [];

    final filters = <String>[];
    final res = config.targetResolution;

    // 1. De-noise & Deblock (clean artifacts before scaling so macroblocks aren't magnified)
    if (config.deblocking) {
      filters.add('deblock=filter=medium:block=4');
    }

    if (config.denoiseStrength > 0.0) {
      final luma = (config.denoiseStrength * 6.0).toStringAsFixed(1);
      final chroma = (config.denoiseStrength * 4.5).toStringAsFixed(1);
      filters.add('hqdn3d=$luma:$chroma:$luma:$chroma');
    }

    // 2. High-Precision Resolution Scale & Pad
    final algFlag = config.algorithm.ffmpegFlag;
    final outW = res.width;
    final outH = res.height;
    filters.add('scale=$outW:$outH:flags=$algFlag:force_original_aspect_ratio=decrease,pad=$outW:$outH:(ow-iw)/2:(oh-ih)/2');

    // 3. Detail Synthesis & Edge Sharpening
    if (config.sharpness != 1.0 || config.detailClarity != 1.0) {
      final amount = ((config.sharpness * config.detailClarity - 1.0) * 1.5 + 1.0)
          .clamp(0.2, 3.0)
          .toStringAsFixed(2);
      filters.add('unsharp=5:5:$amount:5:5:0.0');
    }

    // 4. Dynamic HDR Color Range Expansion
    if (config.hdrColorExpand) {
      filters.add('eq=contrast=1.12:saturation=1.15:brightness=0.01');
    }

    return filters;
  }

  /// Formats HUD badge for realtime preview viewport
  static String getHdBadge(HdConverterConfig config) {
    if (!config.isEnabled) return '';
    return '💎 ${config.targetResolution.label.toUpperCase()} CONVERTED';
  }
}
