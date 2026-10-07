import '../models/night_vision_config.dart';

/// Compiles Night Vision and Thermal Infrared Scope VFX parameters into deterministic FFmpeg video filter expressions.
class NightVisionCompilerService {
  /// Compiles the complete FFmpeg video filter string for night vision and thermal effects.
  static String compileFilter(NightVisionConfig config) {
    if (!config.isActive) return '';

    final filters = <String>[];
    final gain = config.gain.clamp(0.5, 3.0);

    switch (config.mode) {
      case NightVisionMode.phosphorGreen:
        final greenLuma = (1.20 * gain).clamp(0.5, 3.5).toStringAsFixed(2);
        filters.add('format=gray,colorchannelmixer=gr=0.15:gg=$greenLuma:gb=0.25,eq=contrast=1.35:brightness=0.08');
        if (config.noise > 0.05) {
          final noiseVal = (config.noise * 30).clamp(5, 50).round();
          filters.add('noise=alls=$noiseVal:allf=t+u');
        }
        break;

      case NightVisionMode.thermalFlirIronbow:
        filters.add(
          "curves=all='0/0 0.25/0.15 0.5/0.5 0.75/0.85 1/1':"
          "r='0/0.1 0.35/0.85 0.7/0.95 1/1':"
          "g='0/0 0.45/0.15 0.75/0.75 1/1':"
          "b='0/0.4 0.25/0.7 0.6/0.05 1/0.9'",
        );
        if (config.noise > 0.05) {
          final noiseVal = (config.noise * 20).clamp(3, 30).round();
          filters.add('noise=alls=$noiseVal:allf=t+u');
        }
        break;

      case NightVisionMode.thermalRainbow:
        filters.add(
          "curves=r='0/0 0.3/0 0.7/0.9 1/1':"
          "g='0/0 0.35/0.8 0.75/0.8 1/0.1':"
          "b='0/0.7 0.35/0.7 0.65/0 1/0'",
        );
        if (config.noise > 0.05) {
          final noiseVal = (config.noise * 20).clamp(3, 30).round();
          filters.add('noise=alls=$noiseVal:allf=t+u');
        }
        break;

      case NightVisionMode.whiteHot:
        final contrast = (1.30 * gain).clamp(0.8, 3.0).toStringAsFixed(2);
        filters.add('format=gray,eq=contrast=$contrast:brightness=0.05');
        if (config.noise > 0.05) {
          final noiseVal = (config.noise * 25).clamp(5, 40).round();
          filters.add('noise=alls=$noiseVal:allf=t+u');
        }
        break;

      case NightVisionMode.blackHot:
        final contrast = (1.30 * gain).clamp(0.8, 3.0).toStringAsFixed(2);
        filters.add('format=gray,negate,eq=contrast=$contrast:brightness=0.05');
        if (config.noise > 0.05) {
          final noiseVal = (config.noise * 25).clamp(5, 40).round();
          filters.add('noise=alls=$noiseVal:allf=t+u');
        }
        break;
    }

    if (config.vignette > 0.05) {
      final angle = (0.75 + (1.0 - config.vignette) * 0.45).clamp(0.70, 1.20).toStringAsFixed(2);
      filters.add('vignette=angle=$angle');
    }

    return filters.join(',');
  }

  /// Returns user-facing HUD badge text for the editor viewport.
  static String getNightVisionBadge(NightVisionConfig config) {
    if (!config.isActive) return '';
    final icon = config.mode == NightVisionMode.phosphorGreen ? '🎖️ NVG' : '🌡️ THERMAL';
    return '$icon: ${config.mode.displayName.toUpperCase()}';
  }
}
