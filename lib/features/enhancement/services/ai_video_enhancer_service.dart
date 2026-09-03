import '../models/video_enhancement_config.dart';

class AIVideoEnhancerService {
  /// Generates the FFmpeg video filter chain for 8K upscaling and AI enhancements
  static List<String> generateFFmpegFilters(VideoEnhancementConfig config, {int targetWidth = 1920, int targetHeight = 1080}) {
    final filters = <String>[];

    // 1. AI Denoising (prior to upscaling so artifacts are not amplified)
    if (config.deNoise > 0.0) {
      final luma = (config.deNoise * 6.0).toStringAsFixed(1);
      final chroma = (config.deNoise * 4.5).toStringAsFixed(1);
      filters.add('hqdn3d=$luma:$chroma:$luma:$chroma');
    }

    // 2. 8K Ultra HD Upscaling
    if (config.is8kUpscaleEnabled) {
      // High-order Lanczos 8K scaling
      filters.add('scale=7680:4320:flags=lanczos:force_original_aspect_ratio=decrease,pad=7680:4320:(ow-iw)/2:(oh-ih)/2');
    }

    // 3. AI Super-Resolution & Sharpening
    if (config.isAiSuperResolutionEnabled || config.sharpness != 1.0) {
      final amount = (config.sharpness * 1.25).clamp(0.0, 2.5).toStringAsFixed(2);
      filters.add('unsharp=5:5:$amount:5:5:0.0');
    }

    // 4. HDR Tone Mapping, Clarity, and Color Pop
    if (config.isHdrToneMapping || config.clarity != 1.0 || config.isColorPop) {
      final contrast = config.isHdrToneMapping ? 1.15 : (config.clarity != 1.0 ? config.clarity : 1.0);
      final saturation = config.isColorPop ? 1.30 : (config.isHdrToneMapping ? 1.12 : 1.0);
      final brightness = config.isHdrToneMapping ? 0.02 : 0.0;
      filters.add('eq=contrast=${contrast.toStringAsFixed(2)}:saturation=${saturation.toStringAsFixed(2)}:brightness=${brightness.toStringAsFixed(2)}');
    }

    return filters;
  }

  /// Returns resolution badge label
  static String getResolutionLabel(VideoEnhancementConfig config) {
    if (config.is8kUpscaleEnabled) {
      return '8K UHD (7680x4320)';
    }
    if (config.isAiSuperResolutionEnabled) {
      return 'DETAIL ENHANCED';
    }
    if (config.isHdrToneMapping) {
      return 'HDR ENHANCED';
    }
    return '1080p Standard';
  }
}
