import '../models/solarize_invert_config.dart';

/// Compiles photographic solarization and color inversion parameters into deterministic FFmpeg filtergraphs.
class SolarizeInvertCompilerService {
  /// Compiles the complete FFmpeg video filter for tone curve solarization and color inversion.
  static String compileFilter(
    SolarizeInvertConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return '';

    final filters = <String>[];
    final threshInt = (config.threshold * 255).clamp(10, 245).round();

    switch (config.mode) {
      case SolarizeInvertMode.negativeInvert:
        filters.add('lutrgb=r=negval:g=negval:b=negval');
        break;

      case SolarizeInvertMode.sabattier:
        filters.add(
          "lutrgb=r='if(gt(val,$threshInt),255-val,val)':"
          "g='if(gt(val,$threshInt),255-val,val)':"
          "b='if(gt(val,$threshInt),255-val,val)'",
        );
        break;

      case SolarizeInvertMode.psychedelic:
        final hue = config.tintHue.clamp(0.0, 360.0).round();
        final sat = config.saturationBoost.clamp(1.0, 3.0).toStringAsFixed(2);
        filters.add(
          "lutrgb=r='if(gt(val,$threshInt),255-val,val)':"
          "g='if(gt(val,$threshInt),255-val,val)':"
          "b='if(gt(val,$threshInt),255-val,val)'",
        );
        filters.add('hue=h=$hue:s=$sat');
        break;

      case SolarizeInvertMode.thermalHeat:
        filters.add("curves=r='0/0 0.5/1 1/0.8':g='0/0 0.5/0.2 1/0':b='0/1 0.5/0.2 1/0'");
        if (config.saturationBoost > 1.05) {
          final sat = config.saturationBoost.clamp(1.0, 2.5).toStringAsFixed(2);
          filters.add('eq=saturation=$sat:contrast=1.20');
        }
        break;

      case SolarizeInvertMode.crossProcess:
        filters.add("curves=r='0/0 0.5/0.85 1/1':b='0/0.2 0.5/0.1 1/0.8':g='0/0 0.5/0.65 1/0.95'");
        if (config.saturationBoost > 1.05) {
          final sat = config.saturationBoost.clamp(1.0, 2.5).toStringAsFixed(2);
          filters.add('eq=saturation=$sat');
        }
        break;
    }

    if (config.intensity < 0.95 && filters.isNotEmpty) {
      // Scale tone impact slightly when intensity is reduced
      final contrast = (0.8 + (config.intensity * 0.4)).clamp(0.8, 1.2).toStringAsFixed(2);
      filters.add('eq=contrast=$contrast');
    }

    return filters.join(',');
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getSolarizeInvertBadge(SolarizeInvertConfig config) {
    if (!config.isActive) return '';
    return '🔥 SOLARIZE: ${config.mode.displayName.toUpperCase()} (${(config.intensity * 100).round()}% MIX)';
  }
}
