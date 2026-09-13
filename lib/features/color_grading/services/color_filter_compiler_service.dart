import 'dart:math' as math;
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

    // Vignette is rendered via radial gradient overlay, not color matrix.
    // Only engage GPU ColorFiltered matrix pass if true color grading is active.
    final hasColorAdjustments = config.exposure != 0.0 ||
        config.contrast != 1.0 ||
        config.saturation != 1.0 ||
        config.brightness != 0.0 ||
        config.temperature != 0.0 ||
        config.tint != 0.0 ||
        config.highlights != 0.0 ||
        config.shadows != 0.0 ||
        config.whites != 0.0 ||
        config.blacks != 0.0 ||
        config.fade != 0.0 ||
        config.clarity != 1.0 ||
        config.sharpness != 1.0 ||
        config.activeLut != LutPreset.none ||
        config.lift.isActive ||
        config.gamma.isActive ||
        config.gain.isActive ||
        config.offset.isActive ||
        config.hsl.values.any((h) => h.hue != 0.0 || h.saturation != 0.0 || h.luminance != 0.0) ||
        ColorGradingConfig.isCurveCustomized(config.masterCurve);

    return !hasColorAdjustments;
  }

  /// Compiles ColorGradingConfig into a mathematically accurate 4x5 ColorFilter matrix for instant Flutter GPU rendering.
  static List<double> compileColorMatrix(
    ColorGradingConfig config, {
    ChromaKeyConfig? chromaKey,
    VideoEnhancementConfig? enhancement,
  }) {
    // Fast path: if un-graded, return pure identity matrix immediately
    if (isIdentity(config, chromaKey: chromaKey, enhancement: enhancement)) {
      return identityMatrix;
    }

    final contrast = config.contrast * config.clarity;
    final saturation = config.saturation;
    // Exposure math: 0.15 EV scale factor + brightness + fade lift
    final fadeOffset = config.fade * 24.0;
    final brightnessOffset = (config.brightness + (config.exposure * 0.15)) * 128.0 + fadeOffset;

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
      case LutPreset.arriAlexa:
        lutR = 8.0 * config.lutIntensity;
        lutG = 4.0 * config.lutIntensity;
        lutB = 2.0 * config.lutIntensity;
        lutContrast = 1.0 - (0.05 * config.lutIntensity);
        break;
      case LutPreset.fujiVelvia:
        lutR = 12.0 * config.lutIntensity;
        lutG = 14.0 * config.lutIntensity;
        lutB = -4.0 * config.lutIntensity;
        lutSat = 1.0 + (0.22 * config.lutIntensity);
        lutContrast = 1.0 + (0.18 * config.lutIntensity);
        break;
      case LutPreset.bleachBypass:
        lutSat = 1.0 - (0.50 * config.lutIntensity);
        lutContrast = 1.0 + (0.38 * config.lutIntensity);
        lutR = 6.0 * config.lutIntensity;
        lutG = 6.0 * config.lutIntensity;
        lutB = 8.0 * config.lutIntensity;
        break;
      case LutPreset.matrixEmerald:
        lutR = -14.0 * config.lutIntensity;
        lutG = 22.0 * config.lutIntensity;
        lutB = -6.0 * config.lutIntensity;
        lutContrast = 1.0 + (0.22 * config.lutIntensity);
        break;
      case LutPreset.fujiEterna:
        lutR = 2.0 * config.lutIntensity;
        lutG = 4.0 * config.lutIntensity;
        lutB = 6.0 * config.lutIntensity;
        lutSat = 1.0 - (0.15 * config.lutIntensity);
        lutContrast = 1.0 - (0.12 * config.lutIntensity);
        break;
      case LutPreset.cleanCommercial:
        lutSat = 1.0 + (0.15 * config.lutIntensity);
        lutContrast = 1.0 + (0.12 * config.lutIntensity);
        lutR = 4.0 * config.lutIntensity;
        lutG = 2.0 * config.lutIntensity;
        lutB = 6.0 * config.lutIntensity;
        break;
      case LutPreset.vintage70s:
        lutR = 22.0 * config.lutIntensity;
        lutG = 10.0 * config.lutIntensity;
        lutB = -16.0 * config.lutIntensity;
        lutSat = 1.0 - (0.08 * config.lutIntensity);
        break;
    }

    // 3-Way Color Wheels math: Lift (Shadows), Gamma (Midtones), Gain (Highlights), Offset
    final wheelR = _calcWheelRGB(config.lift, isRed: true) * 0.5 +
        _calcWheelRGB(config.gamma, isRed: true) * 0.7 +
        _calcWheelRGB(config.gain, isRed: true) * 0.8 +
        _calcWheelRGB(config.offset, isRed: true) * 1.0;
    final wheelG = _calcWheelRGB(config.lift, isGreen: true) * 0.5 +
        _calcWheelRGB(config.gamma, isGreen: true) * 0.7 +
        _calcWheelRGB(config.gain, isGreen: true) * 0.8 +
        _calcWheelRGB(config.offset, isGreen: true) * 1.0;
    final wheelB = _calcWheelRGB(config.lift, isBlue: true) * 0.5 +
        _calcWheelRGB(config.gamma, isBlue: true) * 0.7 +
        _calcWheelRGB(config.gain, isBlue: true) * 0.8 +
        _calcWheelRGB(config.offset, isBlue: true) * 1.0;

    // 8K AI Enhancement detail boost
    final enhanceBoost = (enhancement != null && enhancement.hasActiveEnhancements)
        ? (enhancement.is8kUpscaleEnabled ? 0.12 : (enhancement.clarity - 1.0) * 0.15)
        : 0.0;

    final finalContrast = (contrast * lutContrast + enhanceBoost).clamp(0.4, 2.5);
    final effectiveSat = (saturation * lutSat).clamp(0.0, 3.0);
    final effInvSat = 1.0 - effectiveSat;

    // Contrast offset: centers contrast scaling around midpoint 128
    final contrastOffset = (1.0 - finalContrast) * 128.0;

    // Whites & Blacks adjustments
    final whitesOffset = config.whites * 32.0;
    final blacksOffset = config.blacks * 32.0;

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
    final totalROffset = brightnessOffset + contrastOffset + rTemp + rTint + lutR + wheelR + whitesOffset + blacksOffset;

    // Row 1 (Green output)
    final m10 = finalContrast * rLum * chromaGScale;
    final m11 = finalContrast * (gLum + effectiveSat) * chromaGScale;
    final m12 = finalContrast * bLum * chromaGScale;
    final totalGOffset = brightnessOffset + contrastOffset + gTint + lutG + chromaGOffset + wheelG + whitesOffset + blacksOffset;

    // Row 2 (Blue output)
    final m20 = finalContrast * rLum * chromaBScale;
    final m21 = finalContrast * gLum * chromaBScale;
    final m22 = finalContrast * (bLum + effectiveSat) * chromaBScale;
    final totalBOffset = brightnessOffset + contrastOffset + bTemp + bTint + lutB + chromaBOffset + wheelB + whitesOffset + blacksOffset;

    return [
      m00, m01, m02, 0.0, totalROffset,
      m10, m11, m12, 0.0, totalGOffset,
      m20, m21, m22, 0.0, totalBOffset,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  static double _calcWheelRGB(ColorWheelValue wheel, {bool isRed = false, bool isGreen = false, bool isBlue = false}) {
    if (!wheel.isActive) return 0.0;
    final rad = wheel.angle * (math.pi / 180.0);
    final sat = wheel.saturation.clamp(0.0, 1.0);
    final lum = wheel.luminance * 25.0;

    double colorShift = 0.0;
    if (isRed) {
      colorShift = math.cos(rad) * sat * 35.0;
    } else if (isGreen) {
      colorShift = math.cos(rad - (2.0 * math.pi / 3.0)) * sat * 35.0;
    } else if (isBlue) {
      colorShift = math.cos(rad - (4.0 * math.pi / 3.0)) * sat * 35.0;
    }
    return colorShift + lum;
  }

  /// Compiles ColorGradingConfig into an FFmpeg video filter chain
  static String generateFFmpegFilter(ColorGradingConfig config) {
    final filters = <String>[];

    // 1. Equalizer Filter (Contrast, Brightness, Saturation)
    final contrast = (config.contrast * config.clarity).toStringAsFixed(2);
    final brightness = (config.brightness + (config.exposure * 0.15) + (config.fade * 0.08)).toStringAsFixed(2);
    final saturation = config.saturation.toStringAsFixed(2);

    if (config.contrast != 1.0 || config.brightness != 0.0 || config.exposure != 0.0 || config.saturation != 1.0 || config.fade != 0.0 || config.clarity != 1.0) {
      filters.add('eq=contrast=$contrast:brightness=$brightness:saturation=$saturation');
    }

    // 2. 3-Way Color Balance (Lift, Gamma, Gain, Temperature, Tint)
    final hasWheels = config.lift.isActive || config.gamma.isActive || config.gain.isActive || config.offset.isActive;
    if (config.temperature != 0.0 || config.tint != 0.0 || hasWheels) {
      // Shadows (Lift)
      final rs = (_calcWheelRGB(config.lift, isRed: true) / 35.0 * 0.3).clamp(-1.0, 1.0).toStringAsFixed(2);
      final gs = (_calcWheelRGB(config.lift, isGreen: true) / 35.0 * 0.3).clamp(-1.0, 1.0).toStringAsFixed(2);
      final bs = (_calcWheelRGB(config.lift, isBlue: true) / 35.0 * 0.3).clamp(-1.0, 1.0).toStringAsFixed(2);

      // Midtones (Gamma + Temp/Tint)
      final rTemp = ((config.temperature / 100.0) * 0.25);
      final bTemp = ((-config.temperature / 100.0) * 0.25);
      final gTint = ((-config.tint / 100.0) * 0.20);
      final rm = (rTemp + _calcWheelRGB(config.gamma, isRed: true) / 35.0 * 0.3 + _calcWheelRGB(config.offset, isRed: true) / 35.0 * 0.2).clamp(-1.0, 1.0).toStringAsFixed(2);
      final gm = (gTint + _calcWheelRGB(config.gamma, isGreen: true) / 35.0 * 0.3 + _calcWheelRGB(config.offset, isGreen: true) / 35.0 * 0.2).clamp(-1.0, 1.0).toStringAsFixed(2);
      final bm = (bTemp + _calcWheelRGB(config.gamma, isBlue: true) / 35.0 * 0.3 + _calcWheelRGB(config.offset, isBlue: true) / 35.0 * 0.2).clamp(-1.0, 1.0).toStringAsFixed(2);

      // Highlights (Gain)
      final rh = (_calcWheelRGB(config.gain, isRed: true) / 35.0 * 0.3).clamp(-1.0, 1.0).toStringAsFixed(2);
      final gh = (_calcWheelRGB(config.gain, isGreen: true) / 35.0 * 0.3).clamp(-1.0, 1.0).toStringAsFixed(2);
      final bh = (_calcWheelRGB(config.gain, isBlue: true) / 35.0 * 0.3).clamp(-1.0, 1.0).toStringAsFixed(2);

      filters.add('colorbalance=rs=$rs:gs=$gs:bs=$bs:rm=$rm:gm=$gm:bm=$bm:rh=$rh:gh=$gh:bh=$bh');
    }

    // 3. Pro Cinematic LUT Presets
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
      case LutPreset.arriAlexa:
        filters.add('curves=r=\'0/0.04 0.5/0.51 1/0.96\':g=\'0/0.03 0.5/0.50 1/0.97\':b=\'0/0.02 0.5/0.49 1/0.98\'');
        break;
      case LutPreset.fujiVelvia:
        filters.add('eq=saturation=1.20,curves=g=\'0/0 0.5/0.55 1/1\':b=\'0/0 0.5/0.48 1/0.96\'');
        break;
      case LutPreset.bleachBypass:
        filters.add('hue=s=0.5,eq=contrast=1.35');
        break;
      case LutPreset.matrixEmerald:
        filters.add('colorbalance=rm=-0.12:gm=0.18:bm=-0.08,curves=all=\'0/0 0.5/0.45 1/1\'');
        break;
      case LutPreset.fujiEterna:
        filters.add('curves=all=\'0/0.06 0.5/0.48 1/0.94\',hue=s=0.88');
        break;
      case LutPreset.cleanCommercial:
        filters.add('eq=contrast=1.12:saturation=1.14:brightness=0.01');
        break;
      case LutPreset.vintage70s:
        filters.add('curves=r=\'0/0.08 1/0.92\':b=\'0/0.02 1/0.85\',colorbalance=rm=0.10:bm=-0.15');
        break;
    }

    // 4. Filmic Lifted Fade Curves
    if (config.fade > 0.0) {
      final lift = (config.fade * 0.12).toStringAsFixed(2);
      filters.add('curves=all=\'0/$lift 1/1\'');
    }

    // 5. Vignette
    if (config.vignette > 0.0) {
      final angle = (config.vignette * (math.pi / 3.0)).toStringAsFixed(2);
      filters.add('vignette=angle=$angle');
    }

    return filters.join(',');
  }
}
