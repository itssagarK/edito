import 'dart:math' as math;
import '../models/color_grading_config.dart';

/// Available preset modes for on-device AI Color & Tone Enhancement.
enum AiColorMode {
  smartAuto,
  vibrantPop,
  cinematicWarm,
  cleanCool,
  lowLightBoost,
}

extension AiColorModeExtension on AiColorMode {
  String get label {
    switch (this) {
      case AiColorMode.smartAuto:
        return '✨ Smart Auto';
      case AiColorMode.vibrantPop:
        return '🔥 Vivid Pop';
      case AiColorMode.cinematicWarm:
        return '🎬 Cinema Golden';
      case AiColorMode.cleanCool:
        return '❄️ Clean Crisp';
      case AiColorMode.lowLightBoost:
        return '🌙 Low-Light Boost';
    }
  }

  String get description {
    switch (this) {
      case AiColorMode.smartAuto:
        return 'Universal balance: auto exposure, dynamic contrast & natural white balance';
      case AiColorMode.vibrantPop:
        return 'High-retention social look: punchy saturation, deep blacks & crisp highlights';
      case AiColorMode.cinematicWarm:
        return 'Filmic movie tone: warm golden highlights, velvety shadows & filmic roll-off';
      case AiColorMode.cleanCool:
        return 'Crisp commercial look: neutral whites, clean clarity & modern cool tint';
      case AiColorMode.lowLightBoost:
        return 'Night/indoor recovery: lifted crushed shadows & exposure compensation';
    }
  }
}

/// 100% Offline, On-Device AI Computer Vision Color Intelligence Service.
///
/// Analyzes image/video frame tone distributions, white balance, dynamic range,
/// and color casts locally on device, generating optimal [ColorGradingConfig]
/// without requiring cloud APIs, neural network servers, or internet access.
class AiColorEnhancerService {
  /// Computes AI enhanced [ColorGradingConfig] based on mode and intensity (0.0 to 1.5).
  static ColorGradingConfig computeEnhancement({
    ColorGradingConfig? baseConfig,
    AiColorMode mode = AiColorMode.smartAuto,
    double intensity = 1.0,
    double? measuredMeanLuminance, // 0.0 (dark) to 1.0 (bright) if measured from frame
    double? measuredColorCastTemp, // -50 (cold blue) to +50 (warm orange)
  }) {
    final base = baseConfig ?? const ColorGradingConfig();
    final clampedIntensity = intensity.clamp(0.0, 1.5);

    // Baseline targets for each AI profile
    double targetExposure = 0.0;
    double targetContrast = 1.0;
    double targetSaturation = 1.0;
    double targetBrightness = 0.0;
    double targetTemperature = 0.0;
    double targetTint = 0.0;
    double targetHighlights = 0.0;
    double targetShadows = 0.0;
    double targetWhites = 0.0;
    double targetBlacks = 0.0;
    double targetClarity = 1.0;
    double targetSharpness = 1.0;

    switch (mode) {
      case AiColorMode.smartAuto:
        targetExposure = 0.16;
        targetContrast = 1.12;
        targetSaturation = 1.15;
        targetHighlights = -0.10;
        targetShadows = 0.18;
        targetWhites = 0.06;
        targetBlacks = -0.05;
        targetTemperature = 3.5;
        targetTint = -1.0;
        targetClarity = 1.10;
        targetSharpness = 1.12;
        break;

      case AiColorMode.vibrantPop:
        targetExposure = 0.10;
        targetContrast = 1.20;
        targetSaturation = 1.35;
        targetHighlights = -0.06;
        targetShadows = 0.12;
        targetWhites = 0.14;
        targetBlacks = -0.08;
        targetTemperature = 2.0;
        targetClarity = 1.22;
        targetSharpness = 1.20;
        break;

      case AiColorMode.cinematicWarm:
        targetExposure = 0.06;
        targetContrast = 1.16;
        targetSaturation = 1.08;
        targetHighlights = -0.16;
        targetShadows = 0.20;
        targetWhites = 0.02;
        targetBlacks = -0.06;
        targetTemperature = 12.0;
        targetTint = -4.0;
        targetClarity = 1.08;
        targetSharpness = 1.08;
        break;

      case AiColorMode.cleanCool:
        targetExposure = 0.12;
        targetContrast = 1.10;
        targetSaturation = 1.06;
        targetHighlights = 0.06;
        targetShadows = 0.08;
        targetWhites = 0.08;
        targetBlacks = -0.04;
        targetTemperature = -9.0;
        targetTint = 2.5;
        targetClarity = 1.15;
        targetSharpness = 1.15;
        break;

      case AiColorMode.lowLightBoost:
        targetExposure = 0.48;
        targetContrast = 1.08;
        targetSaturation = 1.12;
        targetBrightness = 0.08;
        targetHighlights = -0.22;
        targetShadows = 0.45;
        targetWhites = -0.06;
        targetBlacks = 0.10;
        targetTemperature = -2.0;
        targetClarity = 1.18;
        targetSharpness = 1.12;
        break;
    }

    // Adapt to measured luminance if available (adaptive exposure compensation)
    if (measuredMeanLuminance != null) {
      if (measuredMeanLuminance < 0.35) {
        // Underexposed footage: provide extra shadow and exposure lift
        final darkFactor = (0.35 - measuredMeanLuminance) / 0.35;
        targetExposure += (0.30 * darkFactor);
        targetShadows += (0.25 * darkFactor);
      } else if (measuredMeanLuminance > 0.70) {
        // Overexposed footage: tame highlights and pull back exposure
        final brightFactor = (measuredMeanLuminance - 0.70) / 0.30;
        targetExposure -= (0.20 * brightFactor);
        targetHighlights -= (0.20 * brightFactor);
      }
    }

    // Adapt to measured color cast if available (Gray World white balance compensation)
    if (measuredColorCastTemp != null) {
      // Counteract unwanted color temperature cast
      targetTemperature -= (measuredColorCastTemp * 0.6);
    }

    // Blend targets smoothly using intensity: Lerp(Base, Target, Intensity)
    return base.copyWith(
      exposure: _lerp(base.exposure, targetExposure, clampedIntensity),
      contrast: _lerp(base.contrast, targetContrast, clampedIntensity),
      saturation: _lerp(base.saturation, targetSaturation, clampedIntensity),
      brightness: _lerp(base.brightness, targetBrightness, clampedIntensity),
      temperature: _lerp(base.temperature, targetTemperature, clampedIntensity),
      tint: _lerp(base.tint, targetTint, clampedIntensity),
      highlights: _lerp(base.highlights, targetHighlights, clampedIntensity),
      shadows: _lerp(base.shadows, targetShadows, clampedIntensity),
      whites: _lerp(base.whites, targetWhites, clampedIntensity),
      blacks: _lerp(base.blacks, targetBlacks, clampedIntensity),
      clarity: _lerp(base.clarity, targetClarity, clampedIntensity),
      sharpness: _lerp(base.sharpness, targetSharpness, clampedIntensity),
    );
  }

  /// Estimates frame luminance and color temperature from RGB average values (0.0 to 1.0).
  ///
  /// Uses standard Rec.709 coefficients: Y = 0.2126*R + 0.7152*G + 0.0722*B
  static Map<String, double> estimateMetricsFromRgb({
    required double avgR,
    required double avgG,
    required double avgB,
  }) {
    final luminance = (0.2126 * avgR + 0.7152 * avgG + 0.0722 * avgB).clamp(0.0, 1.0);
    // Relative color cast: positive = warm orange/red, negative = cool blue
    final colorCast = ((avgR - avgB) * 100.0).clamp(-50.0, 50.0);

    return {
      'luminance': luminance,
      'colorCast': colorCast,
    };
  }

  static double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
}
