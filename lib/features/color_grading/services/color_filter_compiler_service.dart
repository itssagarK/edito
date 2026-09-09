import 'package:flutter/material.dart';
import '../../chroma/models/chroma_key_config.dart';
import '../../enhancement/models/video_enhancement_config.dart';
import '../models/color_grading_config.dart';

class ColorFilterCompilerService {
  /// Pure mathematical 4x5 identity matrix for un-graded pristine rendering
  static const List<double> identityMatrix = [
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  /// Checks whether the clip configuration requires a GPU ColorFilter pass.
  /// If false, the viewport can render the hardware video texture directly without any shader pass.
  static bool isIdentity(
    ColorGradingConfig config, {
    ChromaKeyConfig? chromaKey,
    VideoEnhancementConfig? enhancement,
  }) {
    if (chromaKey != null && chromaKey.isEnabled) return false;
    if (enhancement != null && enhancement.hasActiveEnhancements) return false;
    return !config.isGraded;
  }

  /// Compiles ColorGradingConfig into a mathematically accurate 4x5 ColorFilter matrix for instant Flutter GPU rendering.
  /// Eliminates cross-channel color bleed so imported videos retain 100% true-to-life original colors.
  static List<double> compileColorMatrix(
    ColorGradingConfig config, {
    ChromaKeyConfig? chromaKey,
    VideoEnhancementConfig? enhancement,
  }) {
    // Fast path: if un-graded, return pure identity matrix immediately
    if (isIdentity(config, chromaKey: chromaKey, enhancement: enhancement)) {
      return identityMatrix;
    }

    final contrast = config.contrast;
    final saturation = config.saturation;
    final brightnessOffset = (config.brightness + (config.exposure * 0.15)) * 128.0;

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

    // 8K AI Enhancement detail boost
    final enhanceBoost = (enhancement != null && enhancement.hasActiveEnhancements)
        ? (enhancement.is8kUpscaleEnabled ? 0.12 : (enhancement.clarity - 1.0) * 0.15)
        : 0.0;

    final finalContrast = (contrast * lutContrast + enhanceBoost).clamp(0.4, 2.5);
    final effectiveSat = (saturation * lutSat).clamp(0.0, 3.0);
    final effInvSat = 1.0 - effectiveSat;

    // Contrast offset: centers contrast scaling around midpoint 128
    final contrastOffset = (1.0 - finalContrast) * 128.0;

    // Chroma Key color suppression
    double chromaGScale = 1.0;
    double chromaBScale = 1.0;
    double chromaGOffset = 0.0;
    double chromaBOffset = 0.0;

    if (chromaKey != null && chromaKey.isEnabled) {
      final keyVal = chromaKey.keyColorValue;
      final isGreen = ((keyVal >> 8) & 0xFF) > 120 && ((keyVal >> 16) & 0xFF) < 120;
      final isBlue = (keyVal & 0xFF) > 120 && ((keyVal >> 8) & 0xFF) < 120;

      if (isGreen) {
        chromaGScale = (1.0 - (chromaKey.similarity * 1.5)).clamp(0.08, 0.90);
        chromaGOffset = -35.0 * chromaKey.similarity;
      } else if (isBlue) {
        chromaBScale = (1.0 - (chromaKey.similarity * 1.5)).clamp(0.08, 0.90);
        chromaBOffset = -35.0 * chromaKey.similarity;
      }
    }

    // Luminance components
    final rLum = effInvSat * lr;
    final gLum = effInvSat * lg;
    final bLum = effInvSat * lb;

    // Row 0 (Red output)
    final m00 = finalContrast * (rLum + effectiveSat);
    final m01 = finalContrast * gLum;
    final m02 = finalContrast * bLum;
    final totalROffset = brightnessOffset + contrastOffset + rTemp + rTint + lutR;

    // Row 1 (Green output): Column 0 is rLum * chromaGScale, Column 1 is (gLum + effectiveSat) * chromaGScale
    final m10 = finalContrast * rLum * chromaGScale;
    final m11 = finalContrast * (gLum + effectiveSat) * chromaGScale;
    final m12 = finalContrast * bLum * chromaGScale;
    final totalGOffset = brightnessOffset + contrastOffset + gTint + lutG + chromaGOffset;

    // Row 2 (Blue output): Column 0 is rLum * chromaBScale, Column 2 is (bLum + effectiveSat) * chromaBScale
    final m20 = finalContrast * rLum * chromaBScale;
    final m21 = finalContrast * gLum * chromaBScale;
    final m22 = finalContrast * (bLum + effectiveSat) * chromaBScale;
    final totalBOffset = brightnessOffset + contrastOffset + bTemp + bTint + lutB + chromaBOffset;

    return [
      m00, m01, m02, 0.0, totalROffset,
      m10, m11, m12, 0.0, totalGOffset,
      m20, m21, m22, 0.0, totalBOffset,
      0.0, 0.0, 0.0, 1.0, 0.0,
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
