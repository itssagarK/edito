import 'dart:math' as math;
import '../models/chromatic_aberration_config.dart';

/// Compiles RGB chromatic aberration parameters into deterministic FFmpeg filtergraphs.
class ChromaticAberrationCompilerService {
  /// Compiles the complete FFmpeg video filter for RGB channel displacement and optical dispersion.
  static String compileFilter(
    ChromaticAberrationConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return '';

    final filters = <String>[];
    final d = (config.shiftAmount * 24.0).clamp(1.0, 30.0);

    switch (config.mode) {
      case ChromaticAberrationMode.horizontalSplit:
        final shift = d.round();
        filters.add('rgbashift=rh=$shift:rv=0:bh=-$shift:bv=0:gh=0:gv=0:edge=smear');
        break;

      case ChromaticAberrationMode.prismaticAngle:
        final rad = config.angleDeg * (math.pi / 180.0);
        final dx = (d * math.cos(rad)).round();
        final dy = (d * math.sin(rad)).round();
        filters.add('rgbashift=rh=$dx:rv=$dy:bh=-$dx:bv=-$dy:gh=0:gv=0:edge=smear');
        break;

      case ChromaticAberrationMode.anaglyph3d:
        final d3d = (d * 1.25).clamp(2.0, 32.0).round();
        filters.add('rgbashift=rh=$d3d:rv=0:bh=-$d3d:bv=0:gh=0:gv=0:edge=smear');
        break;

      case ChromaticAberrationMode.hologramJitter:
        final dInt = d.round();
        final freq = config.jitterSpeed.clamp(0.5, 10.0).toStringAsFixed(1);
        filters.add("rgbashift=rh='$dInt*sin(2*PI*$freq*t)':bh='-$dInt*sin(2*PI*$freq*t)':edge=smear");
        break;

      case ChromaticAberrationMode.radialDispersion:
        final dRadialH = d.round();
        final dRadialV = (d * 0.6).round();
        filters.add('rgbashift=rh=$dRadialH:rv=$dRadialV:bh=-$dRadialH:bv=-$dRadialV:gh=0:gv=0:edge=smear');
        break;
    }

    if (config.colorMix > 0.85) {
      filters.add('eq=saturation=1.12:contrast=1.05');
    }

    return filters.join(',');
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getChromaticAberrationBadge(ChromaticAberrationConfig config) {
    if (!config.isActive) return '';
    return '⚡ CHROMATIC RGB: ${config.mode.displayName.toUpperCase()} (${(config.shiftAmount * 100).round()}% SHIFT)';
  }
}
