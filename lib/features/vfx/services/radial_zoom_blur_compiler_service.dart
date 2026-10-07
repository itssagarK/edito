import 'dart:math' as math;
import '../models/radial_zoom_blur_config.dart';

/// Compiles anamorphic radial zoom blur and angular rotational vortex parameters
/// into deterministic FFmpeg video filter chains.
class RadialZoomBlurCompilerService {
  const RadialZoomBlurCompilerService();

  /// Compiles the complete FFmpeg video filter string for radial zoom blur.
  static String compileFilter(
    RadialZoomBlurConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return '';

    final filters = <String>[];
    final blur = config.blurAmount.clamp(0.05, 1.0);
    final cx = config.centerX.clamp(0.0, 1.0).toStringAsFixed(2);
    final cy = config.centerY.clamp(0.0, 1.0).toStringAsFixed(2);

    switch (config.mode) {
      case RadialZoomBlurMode.actionImpactZoom:
        final radius = (blur * 7.0).clamp(1.0, 14.0).round();
        final k1 = (blur * 0.16).toStringAsFixed(3);
        final k2 = (blur * 0.06).toStringAsFixed(3);
        filters.add('boxblur=luma_radius=$radius:luma_power=2');
        filters.add('lenscorrection=cx=$cx:cy=$cy:k1=$k1:k2=$k2');
        filters.add('eq=contrast=1.12:saturation=1.08');
        break;

      case RadialZoomBlurMode.hyperspaceWarp:
        final radius = (blur * 9.0).clamp(2.0, 18.0).round();
        final k1 = (blur * 0.24).toStringAsFixed(3);
        final k2 = (blur * 0.09).toStringAsFixed(3);
        filters.add('boxblur=luma_radius=$radius:luma_power=2');
        filters.add('lenscorrection=cx=$cx:cy=$cy:k1=$k1:k2=$k2');
        filters.add('unsharp=7:7:1.4:5:5:0.8');
        filters.add('eq=contrast=1.18:brightness=0.03:saturation=1.15');
        break;

      case RadialZoomBlurMode.anamorphicVortex:
        final lumaRad = (blur * 6.0).clamp(1.0, 12.0).round();
        final chromaRad = (blur * 8.0).clamp(1.0, 16.0).round();
        final shift = (blur * 6.0).clamp(1.0, 10.0).round();
        filters.add('boxblur=luma_radius=$lumaRad:chroma_radius=$chromaRad');
        filters.add('rgbashift=rh=$shift:bh=-$shift:edge=smear');
        if (config.rotationSpin.abs() > 0.5) {
          final rad = (config.rotationSpin * math.pi / 180.0).toStringAsFixed(4);
          filters.add('rotate=$rad:fillcolor=none:ow=iw:oh=ih');
        }
        filters.add('lenscorrection=cx=$cx:cy=$cy:k1=${(blur * 0.14).toStringAsFixed(3)}');
        break;

      case RadialZoomBlurMode.subtleFocusPunch:
        final radius = (blur * 4.0).clamp(1.0, 8.0).round();
        filters.add('boxblur=luma_radius=$radius:luma_power=1');
        filters.add('lenscorrection=cx=$cx:cy=$cy:k1=${(blur * 0.08).toStringAsFixed(3)}');
        filters.add('eq=contrast=1.06:saturation=1.04');
        break;

      case RadialZoomBlurMode.dizzySpin:
        final radius = (blur * 7.0).clamp(1.0, 14.0).round();
        final spin = config.rotationSpin.abs() > 0.5 ? config.rotationSpin : 25.0;
        final spinRad = (spin * math.pi / 180.0).toStringAsFixed(4);
        filters.add('boxblur=luma_radius=$radius:luma_power=2');
        filters.add("rotate='$spinRad*sin(2*PI*0.5*t)':fillcolor=none:ow=iw:oh=ih");
        filters.add('eq=contrast=1.10:saturation=1.06');
        break;
    }

    if (config.isPulsing) {
      final pulseAmp = (blur * 0.12).toStringAsFixed(3);
      filters.add("eq=contrast='1.0+$pulseAmp*sin(4*PI*t)':brightness='$pulseAmp*0.5*sin(4*PI*t)'");
    }

    return filters.join(',');
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getRadialZoomBlurBadge(RadialZoomBlurConfig config) {
    if (!config.isActive) return '';
    final percent = (config.blurAmount * 100).round();
    return '🌀 RADIAL ZOOM: ${config.mode.label.toUpperCase()} ($percent% BLUR)';
  }
}
