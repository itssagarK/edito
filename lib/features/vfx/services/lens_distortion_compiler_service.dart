import '../models/lens_distortion_config.dart';

class LensDistortionCompilerService {
  /// Compiles FFmpeg video filters for lens distortion, chromatic fringing,
  /// and optical vignette falloff.
  static String? compileFilter(LensDistortionConfig config) {
    if (!config.isEnabled) return null;

    final filters = <String>[];

    // 1. Geometric lens distortion (barrel / fisheye / pincushion)
    if (config.distortion.abs() > 0.02) {
      // In FFmpeg lenscorrection:
      // Negative k1 produces barrel/fisheye expansion
      // Positive k1 produces pincushion pinching
      final k1 = (-config.distortion * 0.42).toStringAsFixed(3);
      final k2 = (-config.distortion * 0.18).toStringAsFixed(3);
      filters.add('lenscorrection=cx=0.5:cy=0.5:k1=$k1:k2=$k2');
    }

    // 2. Chromatic aberration color fringing
    if (config.chromaticAberration > 0.05) {
      final redShift = (1.0 + config.chromaticAberration * 0.06).toStringAsFixed(3);
      final blueShift = (1.0 - config.chromaticAberration * 0.04).toStringAsFixed(3);
      filters.add('colorchannelmixer=rr=$redShift:gg=1.0:bb=$blueShift');
    }

    // 3. Optical corner vignette falloff
    if (config.vignetteFalloff > 0.05) {
      final vigFactor = (config.vignetteFalloff * 0.75).toStringAsFixed(2);
      filters.add("vignette=PI*$vigFactor/4");
    }

    if (filters.isEmpty) return null;
    return filters.join(',');
  }

  /// Generates filter list for FFmpeg export pipeline
  static List<String> generateFFmpegFilters(LensDistortionConfig config) {
    final filter = compileFilter(config);
    if (filter == null || filter.isEmpty) return [];
    return [filter];
  }

  /// Formats human-readable status badge for HUD
  static String getHudBadge(LensDistortionConfig config) {
    if (!config.isEnabled) return 'Distortion OFF';
    final sign = config.distortion >= 0 ? '+' : '';
    final pct = (config.distortion * 100).round();
    return '${config.profile.displayName} ($sign$pct%)';
  }
}
