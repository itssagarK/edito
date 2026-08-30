import 'package:flutter/material.dart';
import '../models/color_grading_config.dart';

class ColorFilterCompilerService {
  /// Compiles ColorGradingConfig into a 4x5 ColorFilter matrix for instant Flutter GPU rendering
  static List<double> compileColorMatrix(ColorGradingConfig config) {
    // Base Identity Matrix
    // [ R, 0, 0, 0, rOffset,
    //   0, G, 0, 0, gOffset,
    //   0, 0, B, 0, bOffset,
    //   0, 0, 0, A, aOffset ]

    final contrast = config.contrast;
    final saturation = config.saturation;
    final brightnessOffset = (config.brightness + (config.exposure * 0.18)) * 128.0;

    // Temperature (Cool <-> Warm)
    final tempShift = (config.temperature / 100.0) * 30.0;
    final rTemp = tempShift > 0 ? tempShift : 0.0;
    final bTemp = tempShift < 0 ? -tempShift : 0.0;

    // Tint (Green <-> Magenta)
    final tintShift = (config.tint / 100.0) * 20.0;
    final gTint = tintShift < 0 ? -tintShift : 0.0;
    final rTint = tintShift > 0 ? tintShift * 0.7 : 0.0;
    final bTint = tintShift > 0 ? tintShift * 0.7 : 0.0;

    // Standard Rec.709 Luminance constants
    const lr = 0.2126;
    const lg = 0.7152;
    const lb = 0.0722;

    final invSat = 1.0 - saturation;
    final rSat = invSat * lr;
    final gSat = invSat * lg;
    final bSat = invSat * lb;

    // LUT Preset Color Shifts
    double lutR = 0.0;
    double lutG = 0.0;
    double lutB = 0.0;
    double lutContrast = 1.0;
    double lutSat = 1.0;

    switch (config.activeLut) {
      case LutPreset.none:
        break;
      case LutPreset.tealAndOrange:
        lutR = 14.0 * config.lutIntensity;
        lutG = -2.0 * config.lutIntensity;
        lutB = 16.0 * config.lutIntensity;
        lutContrast = 1.0 + (0.15 * config.lutIntensity);
        break;
      case LutPreset.vintageKodak:
        lutR = 18.0 * config.lutIntensity;
        lutG = 8.0 * config.lutIntensity;
        lutB = -12.0 * config.lutIntensity;
        lutContrast = 1.0 - (0.08 * config.lutIntensity);
        break;
      case LutPreset.moodyCyber:
        lutR = -8.0 * config.lutIntensity;
        lutG = -6.0 * config.lutIntensity;
        lutB = 24.0 * config.lutIntensity;
        lutContrast = 1.0 + (0.25 * config.lutIntensity);
        break;
      case LutPreset.goldenHour:
        lutR = 26.0 * config.lutIntensity;
        lutG = 12.0 * config.lutIntensity;
        lutB = -18.0 * config.lutIntensity;
        break;
      case LutPreset.noirBw:
        lutSat = 1.0 - config.lutIntensity;
        lutContrast = 1.0 + (0.35 * config.lutIntensity);
        break;
    }

    final finalContrast = contrast * lutContrast;
    final effectiveSat = saturation * lutSat;
    final effInvSat = 1.0 - effectiveSat;

    final mR = finalContrast * (effInvSat * lr + effectiveSat);
    final mG = finalContrast * (effInvSat * lg);
    final mB = finalContrast * (effInvSat * lb);

    final totalROffset = brightnessOffset + rTemp + rTint + lutR;
    final totalGOffset = brightnessOffset + gTint + lutG;
    final totalBOffset = brightnessOffset + bTemp + bTint + lutB;

    return [
      mR, mG, mB, 0, totalROffset,
      mR, finalContrast * (effInvSat * lg + effectiveSat), mB, 0, totalGOffset,
      mR, mG, finalContrast * (effInvSat * lb + effectiveSat), 0, totalBOffset,
      0, 0, 0, 1, 0,
    ];
  }

  /// Compiles ColorGradingConfig into an FFmpeg video filter chain
  static String generateFFmpegFilter(ColorGradingConfig config) {
    final filters = <String>[];

    // 1. Equalizer Filter (Contrast, Brightness, Saturation)
    final contrast = config.contrast.toStringAsFixed(2);
    final brightness = (config.brightness + (config.exposure * 0.15)).toStringAsFixed(2);
    final saturation = config.saturation.toStringAsFixed(2);

    if (config.contrast != 1.0 || config.brightness != 0.0 || config.exposure != 0.0 || config.saturation != 1.0) {
      filters.add('eq=contrast=$contrast:brightness=$brightness:saturation=$saturation');
    }

    // 2. Color Balance (Temperature and Tint)
    if (config.temperature != 0.0 || config.tint != 0.0) {
      final rShift = ((config.temperature / 100.0) * 0.25).clamp(-1.0, 1.0).toStringAsFixed(2);
      final bShift = ((-config.temperature / 100.0) * 0.25).clamp(-1.0, 1.0).toStringAsFixed(2);
      final gShift = ((-config.tint / 100.0) * 0.20).clamp(-1.0, 1.0).toStringAsFixed(2);

      filters.add('colorbalance=rm=$rShift:gm=$gShift:bm=$bShift');
    }

    // 3. LUT Presets (FFmpeg curves & color matrix)
    switch (config.activeLut) {
      case LutPreset.none:
        break;
      case LutPreset.tealAndOrange:
        filters.add('curves=r=\'0/0 0.5/0.55 1/1\':b=\'0/0.05 0.5/0.45 1/0.95\'');
        break;
      case LutPreset.vintageKodak:
        filters.add('curves=r=\'0/0.05 1/0.95\':g=\'0/0.02 1/0.98\':b=\'0/0.08 1/0.88\'');
        break;
      case LutPreset.moodyCyber:
        filters.add('curves=r=\'0/0 0.5/0.4 1/0.9\':b=\'0/0.08 0.5/0.58 1/1\'');
        break;
      case LutPreset.goldenHour:
        filters.add('colorbalance=rm=0.15:gm=0.08:bm=-0.12');
        break;
      case LutPreset.noirBw:
        filters.add('hue=s=0,curves=all=\'0/0 0.25/0.15 0.75/0.85 1/1\'');
        break;
    }

    // 4. Vignette
    if (config.vignette > 0.0) {
      final angle = (config.vignette * (3.14159 / 3.0)).toStringAsFixed(2);
      filters.add('vignette=angle=$angle');
    }

    return filters.join(',');
  }
}
