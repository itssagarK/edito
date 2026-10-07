import '../models/datamosh_glitch_config.dart';

/// Compiles Datamosh Glitch and Video Compression Artifacts VFX parameters into deterministic FFmpeg video filter expressions.
class DatamoshGlitchCompilerService {
  /// Compiles the complete FFmpeg video filter string for datamoshing and glitch corruption.
  static String compileFilter(DatamoshGlitchConfig config) {
    if (!config.isActive) return '';

    final intensity = config.intensity.clamp(0.0, 1.0);

    switch (config.profile) {
      case DatamoshProfile.rgbDisplacementGlitch:
        final rh = (intensity * 24).round();
        final bv = (-intensity * 16).round();
        return 'rgbashift=rh=$rh:bv=$bv';

      case DatamoshProfile.macroblockCompression:
        final factor = (config.blockSize / 3.5).clamp(2.0, 8.0).round();
        return 'scale=iw/$factor:-1,scale=iw*$factor:-1:flags=neighbor';

      case DatamoshProfile.vhsTrackingLoss:
        final noiseVal = (intensity * 28).clamp(5, 50).round();
        return 'noise=alls=$noiseVal:allf=t+u,eq=contrast=1.12:saturation=1.22';

      case DatamoshProfile.keyframeDropMosh:
        final rh = (intensity * 18).round();
        final gh = (-intensity * 10).round();
        return 'rgbashift=rh=$rh:gh=$gh,eq=contrast=1.20:saturation=1.30';

      case DatamoshProfile.cyberCorruptDecay:
        final rh = (intensity * 32).round();
        final bh = (-intensity * 26).round();
        final noiseVal = (intensity * 22).clamp(4, 40).round();
        return 'rgbashift=rh=$rh:bh=$bh,noise=alls=$noiseVal:allf=t+u';
    }
  }

  /// Returns user-facing HUD badge text for the editor viewport.
  static String getDatamoshBadge(DatamoshGlitchConfig config) {
    if (!config.isActive) return '';
    final pct = (config.intensity * 100).round();
    return '⚡ DATAMOSH: ${config.profile.displayName.toUpperCase()} ($pct%)';
  }
}
