import '../models/light_leak_config.dart';

/// Compiles Light Leak and Rainbow Prism VFX parameters into deterministic FFmpeg video filter expressions.
class LightLeakCompilerService {
  /// Compiles the complete FFmpeg video filter string for the light leak effect.
  static String compileFilter(LightLeakConfig config) {
    if (!config.isActive) return '';

    final intensity = config.intensity.clamp(0.0, 1.0);
    final saturation = config.saturation.clamp(0.5, 2.0);

    switch (config.profile) {
      case LightLeakProfile.warmSunsetFlare:
        final brightness = (0.05 * intensity).toStringAsFixed(3);
        final rr = (1.0 + 0.22 * intensity).toStringAsFixed(2);
        final gg = (1.0 + 0.09 * intensity).toStringAsFixed(2);
        final bb = (1.0 - 0.16 * intensity).clamp(0.5, 1.0).toStringAsFixed(2);
        return 'eq=brightness=$brightness:contrast=1.08:saturation=${saturation.toStringAsFixed(2)},'
            'colorchannelmixer=rr=$rr:rg=0.05:rb=0:gr=0.04:gg=$gg:gb=0:br=0.02:bg=0:bb=$bb';

      case LightLeakProfile.rainbowPrism:
        final brightness = (0.045 * intensity).toStringAsFixed(3);
        final effSat = (saturation * 1.15).clamp(0.5, 2.0).toStringAsFixed(2);
        return 'eq=brightness=$brightness:contrast=1.05:saturation=$effSat,'
            'colorchannelmixer=rr=1.08:rg=0.04:rb=0.02:gr=0.02:gg=1.06:gb=0.05:br=0.05:bg=0.03:bb=1.12';

      case LightLeakProfile.vintage35mmBurn:
        final brightness = (0.075 * intensity).toStringAsFixed(3);
        final rr = (1.0 + 0.32 * intensity).toStringAsFixed(2);
        final gg = (1.0 + 0.06 * intensity).toStringAsFixed(2);
        final bb = (1.0 - 0.26 * intensity).clamp(0.4, 1.0).toStringAsFixed(2);
        return 'eq=brightness=$brightness:contrast=1.14:saturation=${saturation.toStringAsFixed(2)},'
            'colorchannelmixer=rr=$rr:rg=0.08:rb=0:gr=0.04:gg=$gg:gb=0:br=0:bg=0:bb=$bb';

      case LightLeakProfile.anamorphicCyanLeak:
        final brightness = (0.04 * intensity).toStringAsFixed(3);
        final rr = (1.0 - 0.18 * intensity).clamp(0.5, 1.0).toStringAsFixed(2);
        final gg = (1.0 + 0.14 * intensity).toStringAsFixed(2);
        final bb = (1.0 + 0.25 * intensity).toStringAsFixed(2);
        return 'eq=brightness=$brightness:contrast=1.06:saturation=${saturation.toStringAsFixed(2)},'
            'colorchannelmixer=rr=$rr:rg=0:rb=0.04:gr=0.02:gg=$gg:gb=0.08:br=0.04:bg=0.10:bb=$bb';

      case LightLeakProfile.subtleAmbientGlow:
        final brightness = (0.03 * intensity).toStringAsFixed(3);
        return 'eq=brightness=$brightness:contrast=1.03:saturation=${saturation.toStringAsFixed(2)},'
            'colorchannelmixer=rr=1.04:gg=1.03:bb=1.01';
    }
  }

  /// Returns user-facing HUD badge text for the editor viewport.
  static String getLightLeakBadge(LightLeakConfig config) {
    if (!config.isActive) return '';
    final pct = (config.intensity * 100).round();
    return '☀️ LEAK: ${config.profile.displayName.toUpperCase()} ($pct%)';
  }
}
