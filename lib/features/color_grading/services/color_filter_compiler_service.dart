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
        config.hasActiveHsl ||
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

    // HSL 8-Channel Selective Color adjustments
    final hslAdj = _calcHslMatrixAdjustments(config.hsl);
    final hslM = hslAdj.matrix3x3;
    final hslOff = hslAdj.offsets;

    // Row 0 (Red output)
    final m00 = finalContrast * (rLum + effectiveSat) + hslM[0];
    final m01 = finalContrast * gLum + hslM[1];
    final m02 = finalContrast * bLum + hslM[2];
    final totalROffset = brightnessOffset + contrastOffset + rTemp + rTint + lutR + wheelR + whitesOffset + blacksOffset + hslOff[0];

    // Row 1 (Green output)
    final m10 = finalContrast * rLum * chromaGScale + hslM[3];
    final m11 = finalContrast * (gLum + effectiveSat) * chromaGScale + hslM[4];
    final m12 = finalContrast * bLum * chromaGScale + hslM[5];
    final totalGOffset = brightnessOffset + contrastOffset + gTint + lutG + chromaGOffset + wheelG + whitesOffset + blacksOffset + hslOff[1];

    // Row 2 (Blue output)
    final m20 = finalContrast * rLum * chromaBScale + hslM[6];
    final m21 = finalContrast * gLum * chromaBScale + hslM[7];
    final m22 = finalContrast * (bLum + effectiveSat) * chromaBScale + hslM[8];
    final totalBOffset = brightnessOffset + contrastOffset + bTemp + bTint + lutB + chromaBOffset + wheelB + whitesOffset + blacksOffset + hslOff[2];

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

    // 6. HSL 8-Channel Selective Color Qualifier
    final selectiveColor = _compileSelectiveColorFilter(config);
    if (selectiveColor != null) {
      filters.add(selectiveColor);
    }

    return filters.join(',');
  }

  /// Calculates GPU 4x5 ColorFilter matrix adjustments for 8-channel HSL shifts
  static ({List<double> matrix3x3, List<double> offsets}) _calcHslMatrixAdjustments(
    Map<String, HslShift> hsl,
  ) {
    if (hsl.isEmpty) {
      return (matrix3x3: const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], offsets: const [0.0, 0.0, 0.0]);
    }

    const lr = 0.2126;
    const lg = 0.7152;
    const lb = 0.0722;

    // Retrieve per-channel shifts
    final red = hsl['red'] ?? const HslShift();
    final orange = hsl['orange'] ?? const HslShift();
    final yellow = hsl['yellow'] ?? const HslShift();
    final green = hsl['green'] ?? const HslShift();
    final cyan = hsl['cyan'] ?? const HslShift();
    final blue = hsl['blue'] ?? const HslShift();
    final purple = hsl['purple'] ?? const HslShift();
    final magenta = hsl['magenta'] ?? const HslShift();

    // Column 0 (Red response)
    final s0 = (red.saturation + 0.35 * orange.saturation).clamp(-1.0, 1.5);
    final h0 = (red.hue + 0.35 * orange.hue).clamp(-180.0, 180.0);
    final l0 = (red.luminance + 0.35 * orange.luminance).clamp(-1.0, 1.0);

    // Column 1 (Green response)
    final s1 = (green.saturation + 0.40 * yellow.saturation + 0.35 * cyan.saturation).clamp(-1.0, 1.5);
    final h1 = (green.hue + 0.40 * yellow.hue + 0.35 * cyan.hue).clamp(-180.0, 180.0);
    final l1 = (green.luminance + 0.40 * yellow.luminance + 0.35 * cyan.luminance).clamp(-1.0, 1.0);

    // Column 2 (Blue response)
    final s2 = (blue.saturation + 0.35 * cyan.saturation + 0.35 * purple.saturation + 0.25 * magenta.saturation).clamp(-1.0, 1.5);
    final h2 = (blue.hue + 0.35 * cyan.hue + 0.35 * purple.hue + 0.25 * magenta.hue).clamp(-180.0, 180.0);
    final l2 = (blue.luminance + 0.35 * cyan.luminance + 0.35 * purple.luminance + 0.25 * magenta.luminance).clamp(-1.0, 1.0);

    // Saturation matrix deltas (pulling towards or pushing away from gray)
    double d00 = s0 * (1.0 - lr);
    double d10 = -s0 * lg;
    double d20 = -s0 * lb;

    double d01 = -s1 * lr;
    double d11 = s1 * (1.0 - lg);
    double d21 = -s1 * lb;

    double d02 = -s2 * lr;
    double d12 = -s2 * lg;
    double d22 = s2 * (1.0 - lb);

    // Hue shifts (rotates column into neighboring color components)
    if (h0.abs() > 0.1) {
      final sin0 = math.sin(h0 * (math.pi / 180.0)) * 0.40;
      d10 += sin0;
      d20 -= sin0 * 0.5;
    }
    if (h1.abs() > 0.1) {
      final sin1 = math.sin(h1 * (math.pi / 180.0)) * 0.40;
      d21 += sin1;
      d01 -= sin1 * 0.5;
    }
    if (h2.abs() > 0.1) {
      final sin2 = math.sin(h2 * (math.pi / 180.0)) * 0.40;
      d02 += sin2;
      d12 -= sin2 * 0.5;
    }

    // Luminance offsets
    final offR = l0 * 28.0;
    final offG = l1 * 28.0;
    final offB = l2 * 28.0;

    return (
      matrix3x3: [d00, d01, d02, d10, d11, d12, d20, d21, d22],
      offsets: [offR, offG, offB],
    );
  }

  /// Compiles 8-channel HSL adjustments into native FFmpeg selectivecolor filter
  static String? _compileSelectiveColorFilter(ColorGradingConfig config) {
    if (!config.hasActiveHsl) return null;

    final parts = <String>[];

    // Formats CMYK adjustment string for FFmpeg selectivecolor
    String formatSector(double s, double h, double l) {
      final c = (-s * 0.8).clamp(-1.0, 1.0);
      final m = (-h / 180.0).clamp(-1.0, 1.0);
      final y = (h / 180.0).clamp(-1.0, 1.0);
      final k = (-l).clamp(-1.0, 1.0);

      return '${c.toStringAsFixed(2)} ${m.toStringAsFixed(2)} ${y.toStringAsFixed(2)} ${k.toStringAsFixed(2)}';
    }

    final hsl = config.hsl;

    // 1. Reds (red + 0.4 orange)
    final redShift = hsl['red'];
    final orangeShift = hsl['orange'];
    if (redShift != null || orangeShift != null) {
      final s = (redShift?.saturation ?? 0.0) + (orangeShift?.saturation ?? 0.0) * 0.4;
      final h = (redShift?.hue ?? 0.0) + (orangeShift?.hue ?? 0.0) * 0.4;
      final l = (redShift?.luminance ?? 0.0) + (orangeShift?.luminance ?? 0.0) * 0.4;
      if (s.abs() > 0.01 || h.abs() > 0.5 || l.abs() > 0.01) {
        parts.add('reds=\'${formatSector(s, h, l)}\'');
      }
    }

    // 2. Yellows (yellow + 0.4 orange)
    final yellowShift = hsl['yellow'];
    if (yellowShift != null || orangeShift != null) {
      final s = (yellowShift?.saturation ?? 0.0) + (orangeShift?.saturation ?? 0.0) * 0.4;
      final h = (yellowShift?.hue ?? 0.0) + (orangeShift?.hue ?? 0.0) * 0.4;
      final l = (yellowShift?.luminance ?? 0.0) + (orangeShift?.luminance ?? 0.0) * 0.4;
      if (s.abs() > 0.01 || h.abs() > 0.5 || l.abs() > 0.01) {
        parts.add('yellows=\'${formatSector(s, h, l)}\'');
      }
    }

    // 3. Greens (green)
    final greenShift = hsl['green'];
    if (greenShift != null) {
      if (greenShift.saturation.abs() > 0.01 || greenShift.hue.abs() > 0.5 || greenShift.luminance.abs() > 0.01) {
        parts.add('greens=\'${formatSector(greenShift.saturation, greenShift.hue, greenShift.luminance)}\'');
      }
    }

    // 4. Cyans (cyan)
    final cyanShift = hsl['cyan'];
    if (cyanShift != null) {
      if (cyanShift.saturation.abs() > 0.01 || cyanShift.hue.abs() > 0.5 || cyanShift.luminance.abs() > 0.01) {
        parts.add('cyans=\'${formatSector(cyanShift.saturation, cyanShift.hue, cyanShift.luminance)}\'');
      }
    }

    // 5. Blues (blue + 0.4 purple)
    final blueShift = hsl['blue'];
    final purpleShift = hsl['purple'];
    if (blueShift != null || purpleShift != null) {
      final s = (blueShift?.saturation ?? 0.0) + (purpleShift?.saturation ?? 0.0) * 0.4;
      final h = (blueShift?.hue ?? 0.0) + (purpleShift?.hue ?? 0.0) * 0.4;
      final l = (blueShift?.luminance ?? 0.0) + (purpleShift?.luminance ?? 0.0) * 0.4;
      if (s.abs() > 0.01 || h.abs() > 0.5 || l.abs() > 0.01) {
        parts.add('blues=\'${formatSector(s, h, l)}\'');
      }
    }

    // 6. Magentas (magenta + 0.4 purple)
    final magentaShift = hsl['magenta'];
    if (magentaShift != null || purpleShift != null) {
      final s = (magentaShift?.saturation ?? 0.0) + (purpleShift?.saturation ?? 0.0) * 0.4;
      final h = (magentaShift?.hue ?? 0.0) + (purpleShift?.hue ?? 0.0) * 0.4;
      final l = (magentaShift?.luminance ?? 0.0) + (purpleShift?.luminance ?? 0.0) * 0.4;
      if (s.abs() > 0.01 || h.abs() > 0.5 || l.abs() > 0.01) {
        parts.add('magentas=\'${formatSector(s, h, l)}\'');
      }
    }

    if (parts.isEmpty) return null;
    return 'selectivecolor=${parts.join(':')}';
  }

  /// Generates a live HUD badge for active HSL Selective Color adjustments
  static String getHslBadge(ColorGradingConfig config) {
    if (!config.hasActiveHsl) return '';
    final activeCount = config.hsl.values
        .where((h) => h.hue != 0.0 || h.saturation != 0.0 || h.luminance != 0.0)
        .length;
    return '🎯 HSL (${activeCount}ch)';
  }
}
