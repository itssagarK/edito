import '../models/crt_scanline_config.dart';

class CrtScanlineCompilerService {
  /// Compiles deterministic FFmpeg filters for retro CRT cathode-ray scanlines and phosphor glow
  static List<String> generateFFmpegFilters(CrtScanlineConfig config) {
    if (!config.isActive) return [];

    final filters = <String>[];

    // 1. Phosphor matrix color grading tint
    final tintFilter = config.phosphorTint.ffmpegMatrixFilter;
    if (tintFilter.isNotEmpty) {
      filters.add(tintFilter);
    }

    // 2. Chromatic RGB subpixel shadow displacement
    if (config.rgbShadowOffset > 0.5) {
      final shift = config.rgbShadowOffset.round().clamp(1, 15);
      filters.add('rgbashift=rh=$shift:bh=-$shift');
    }

    // 3. Raster cathode-ray horizontal scanlines
    final pitch = config.scanlinePitch.round().clamp(2, 20);
    final opacity = config.scanlineOpacity.clamp(0.05, 0.95).toStringAsFixed(2);
    filters.add('drawgrid=w=iw:h=$pitch:t=1:c=black@$opacity');

    // 4. CRT Curvature / barrel corner vignette falloff
    if (config.screenCurvature > 0.05) {
      final angle = (0.35 + config.screenCurvature * 0.45).clamp(0.2, 0.9).toStringAsFixed(2);
      filters.add('vignette=angle=$angle');
    }

    // 5. Analog cathode noise / TV snow grain
    if (config.analogNoise > 0.02) {
      final noiseLevel = (config.analogNoise * 50).round().clamp(2, 35);
      filters.add('noise=alls=$noiseLevel:allf=t');
    }

    return filters;
  }

  /// HUD status badge for active CRT scanlines
  static String getCrtBadge(CrtScanlineConfig config) {
    if (!config.isActive) return '';
    final tintName = config.phosphorTint != CrtPhosphorTint.none
        ? ' • ${config.phosphorTint.label}'
        : '';
    return '📺 CRT SCANLINES (${config.scanlinePitch.toStringAsFixed(1)}px$tintName)';
  }
}
