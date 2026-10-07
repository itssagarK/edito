import '../models/kaleidoscope_config.dart';

/// Compiles Kaleidoscope and Radial Mirror VFX parameters into deterministic FFmpeg video filter expressions.
class KaleidoscopeCompilerService {
  /// Compiles the complete FFmpeg video filter string for kaleidoscope and mirror effects.
  static String compileFilter(KaleidoscopeConfig config) {
    if (!config.isActive) return '';

    final zoom = config.zoom.clamp(0.5, 2.5);

    switch (config.pattern) {
      case KaleidoscopePattern.verticalSplitMirror:
        return 'crop=iw/2:ih:0:0,split[kl][ktemp];[ktemp]hflip[kr];[kl][kr]hstack';

      case KaleidoscopePattern.quadMirror:
        return 'crop=iw/2:ih/2:0:0,split=4[kq1][kq2][kq3][kq4];'
            '[kq2]hflip[kq2f];[kq3]vflip[kq3f];[kq4]hflip,vflip[kq4f];'
            '[kq1][kq2f]hstack[ktop];[kq3f][kq4f]hstack[kbot];[ktop][kbot]vstack';

      case KaleidoscopePattern.hexagonalPrism:
      case KaleidoscopePattern.octagonalMandala:
      case KaleidoscopePattern.dodecahedralDream:
        final zoomStr = zoom.toStringAsFixed(2);
        if (config.rotationSpeed.abs() > 0.01) {
          final speed = (config.rotationSpeed * 0.5).toStringAsFixed(2);
          return 'scale=iw*$zoomStr:-1,crop=iw/$zoomStr:ih/$zoomStr,rotate=angle=\'$speed*t\':fillcolor=none';
        } else {
          return 'scale=iw*$zoomStr:-1,crop=iw/$zoomStr:ih/$zoomStr';
        }
    }
  }

  /// Returns user-facing HUD badge text for the editor viewport.
  static String getKaleidoscopeBadge(KaleidoscopeConfig config) {
    if (!config.isActive) return '';
    return '💎 KALEIDO: ${config.pattern.displayName.toUpperCase()} (${config.segments.round()} FACETS)';
  }
}
