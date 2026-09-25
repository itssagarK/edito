import 'dart:math' as math;
import '../models/color_match_config.dart';

/// CapCut Pro AI Color Match & Tone Palette Transfer Compiler Service
class ColorMatchCompilerService {
  /// Pure mathematical 4x5 identity matrix
  static const List<double> identityMatrix = [
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  /// Rec. 709 Luminance constants
  static const double lr = 0.2126;
  static const double lg = 0.7152;
  static const double lb = 0.0722;

  /// Compiles a 4x5 Skia GPU ColorFilter matrix for instant 60fps viewport preview
  static List<double> calculateColorMatrix(ColorMatchConfig config) {
    if (!config.isEnabled || config.intensity <= 0.0) {
      return identityMatrix;
    }

    // Base matrix parameters
    double contrast = 1.0;
    double saturation = config.saturationMatch;
    double rOffset = 0.0;
    double gOffset = 0.0;
    double bOffset = 0.0;

    // Shadow / Mid / Highlight RGB shifts
    double rShadow = 0.0;
    double gShadow = 0.0;
    double bShadow = 0.0;
    double rHighlight = 0.0;
    double gHighlight = 0.0;
    double bHighlight = 0.0;

    final spread = config.colorSpread;
    final lumaWeight = config.luminanceWeight;

    if (config.mode == ColorMatchMode.timelineClip) {
      // Timeline Clip Matching: harmonize contrast, color temperature, and luminance
      contrast = 1.0 + (0.15 * lumaWeight);
      rOffset = 6.0 * spread;
      bOffset = -4.0 * spread;
      rShadow = -0.05 * spread;
      bShadow = 0.08 * spread;
      rHighlight = 0.12 * spread;
      bHighlight = -0.06 * spread;
    } else {
      switch (config.preset) {
        case ColorPalettePreset.hollywoodTealOrange:
          contrast = 1.0 + (0.22 * lumaWeight);
          bShadow = 0.35 * spread;
          gShadow = 0.10 * spread;
          rShadow = -0.20 * spread;
          rHighlight = 0.30 * spread;
          gHighlight = 0.05 * spread;
          bHighlight = -0.25 * spread;
          if (config.preserveSkinTones) {
            // Mitigate severe reddish skin push
            rHighlight *= 0.65;
            gHighlight += 0.04 * spread;
          }
          break;

        case ColorPalettePreset.moodyBleachBypass:
          contrast = 1.0 + (0.40 * lumaWeight);
          saturation = (0.45 * config.saturationMatch).clamp(0.0, 2.0);
          rOffset = -8.0 * lumaWeight;
          gOffset = -8.0 * lumaWeight;
          bOffset = -6.0 * lumaWeight;
          break;

        case ColorPalettePreset.kodachromeVintage:
          contrast = 1.0 + (0.12 * lumaWeight);
          rOffset = 18.0 * spread;
          gOffset = 8.0 * spread;
          bOffset = -14.0 * spread;
          rShadow = 0.08 * spread;
          bShadow = -0.15 * spread;
          rHighlight = 0.20 * spread;
          bHighlight = -0.18 * spread;
          break;

        case ColorPalettePreset.fujiClassicChrome:
          contrast = 1.0 + (0.10 * lumaWeight);
          saturation = (0.80 * config.saturationMatch).clamp(0.0, 2.0);
          gShadow = 0.15 * spread;
          bShadow = 0.08 * spread;
          rShadow = -0.10 * spread;
          rHighlight = 0.05 * spread;
          bHighlight = -0.05 * spread;
          break;

        case ColorPalettePreset.cyberpunkNeoTokyo:
          contrast = 1.0 + (0.32 * lumaWeight);
          saturation = (1.25 * config.saturationMatch).clamp(0.0, 2.0);
          bShadow = 0.45 * spread;
          rShadow = 0.12 * spread;
          gShadow = -0.25 * spread;
          rHighlight = 0.35 * spread;
          bHighlight = 0.25 * spread;
          gHighlight = -0.20 * spread;
          break;

        case ColorPalettePreset.goldenHourSunset:
          contrast = 1.0 + (0.14 * lumaWeight);
          saturation = (1.15 * config.saturationMatch).clamp(0.0, 2.0);
          rOffset = 24.0 * spread;
          gOffset = 12.0 * spread;
          bOffset = -22.0 * spread;
          rHighlight = 0.28 * spread;
          gHighlight = 0.12 * spread;
          bHighlight = -0.30 * spread;
          break;

        case ColorPalettePreset.cleanCommercial:
          contrast = 1.0 + (0.18 * lumaWeight);
          saturation = (1.20 * config.saturationMatch).clamp(0.0, 2.0);
          rOffset = 4.0 * lumaWeight;
          gOffset = 4.0 * lumaWeight;
          bOffset = 8.0 * lumaWeight;
          rHighlight = 0.05 * spread;
          bHighlight = 0.08 * spread;
          break;

        case ColorPalettePreset.monochromeMood:
          contrast = 1.0 + (0.35 * lumaWeight);
          saturation = 0.0;
          rOffset = 2.0 * lumaWeight;
          gOffset = 2.0 * lumaWeight;
          bOffset = 2.0 * lumaWeight;
          break;
      }
    }

    // Saturation matrix coefficients
    final invSat = 1.0 - saturation;
    final rR = invSat * lr + saturation;
    final rG = invSat * lg;
    final rB = invSat * lb;

    final gR = invSat * lr;
    final gG = invSat * lg + saturation;
    final gB = invSat * lb;

    final bR = invSat * lr;
    final bG = invSat * lg;
    final bB = invSat * lb + saturation;

    // Apply contrast and color balance matrix
    final cShift = (1.0 - contrast) * 128.0;

    // Raw computed 4x5 matrix
    final targetMatrix = <double>[
      (rR * contrast + rHighlight), rG * contrast, rB * contrast, 0.0, rOffset + cShift + (rShadow * 64.0),
      gR * contrast, (gG * contrast + gHighlight), gB * contrast, 0.0, gOffset + cShift + (gShadow * 64.0),
      bR * contrast, bG * contrast, (bB * contrast + bHighlight), 0.0, bOffset + cShift + (bShadow * 64.0),
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];

    // Lerp with identity matrix by master intensity
    final t = config.intensity.clamp(0.0, 1.0);
    final result = List<double>.filled(20, 0.0);
    for (int i = 0; i < 20; i++) {
      result[i] = identityMatrix[i] + (targetMatrix[i] - identityMatrix[i]) * t;
    }

    return result;
  }

  /// Compiles deterministic FFmpeg video filter commands for video rendering
  static List<String> generateFFmpegFilters(ColorMatchConfig config) {
    if (!config.isEnabled || config.intensity <= 0.0) {
      return const [];
    }

    final filters = <String>[];
    final intensity = config.intensity.clamp(0.0, 1.0);
    final spread = config.colorSpread * intensity;
    final luma = config.luminanceWeight * intensity;

    double contrast = 1.0;
    double saturation = 1.0 + (config.saturationMatch - 1.0) * intensity;
    double brightness = 0.0;

    // Color balance parameters (-1.0 to 1.0 range in FFmpeg colorbalance)
    double rs = 0.0, gs = 0.0, bs = 0.0;
    double rm = 0.0, gm = 0.0, bm = 0.0;
    double rh = 0.0, gh = 0.0, bh = 0.0;

    if (config.mode == ColorMatchMode.timelineClip) {
      contrast = 1.0 + (0.12 * luma);
      rs = -0.06 * spread;
      bs = 0.08 * spread;
      rm = 0.04 * spread;
      rh = 0.10 * spread;
      bh = -0.06 * spread;
    } else {
      switch (config.preset) {
        case ColorPalettePreset.hollywoodTealOrange:
          contrast = 1.0 + (0.18 * luma);
          bs = 0.30 * spread;
          gs = 0.08 * spread;
          rs = -0.18 * spread;
          rm = 0.12 * spread;
          rh = 0.28 * spread;
          gh = 0.05 * spread;
          bh = -0.24 * spread;
          if (config.preserveSkinTones) {
            rh *= 0.65;
            gh += 0.03 * spread;
          }
          break;

        case ColorPalettePreset.moodyBleachBypass:
          contrast = 1.0 + (0.35 * luma);
          saturation = (1.0 - (0.55 * intensity)).clamp(0.0, 2.0);
          brightness = -0.05 * luma;
          rs = -0.05 * spread;
          gs = -0.05 * spread;
          bs = -0.03 * spread;
          break;

        case ColorPalettePreset.kodachromeVintage:
          contrast = 1.0 + (0.10 * luma);
          rs = 0.08 * spread;
          bs = -0.12 * spread;
          rm = 0.15 * spread;
          gm = 0.06 * spread;
          bm = -0.10 * spread;
          rh = 0.18 * spread;
          bh = -0.16 * spread;
          break;

        case ColorPalettePreset.fujiClassicChrome:
          contrast = 1.0 + (0.08 * luma);
          saturation = (1.0 - (0.20 * intensity)).clamp(0.0, 2.0);
          gs = 0.12 * spread;
          bs = 0.06 * spread;
          rs = -0.08 * spread;
          rh = 0.04 * spread;
          bh = -0.04 * spread;
          break;

        case ColorPalettePreset.cyberpunkNeoTokyo:
          contrast = 1.0 + (0.28 * luma);
          saturation = (1.0 + (0.25 * intensity)).clamp(0.0, 2.0);
          bs = 0.38 * spread;
          rs = 0.10 * spread;
          gs = -0.20 * spread;
          rh = 0.30 * spread;
          bh = 0.22 * spread;
          gh = -0.18 * spread;
          break;

        case ColorPalettePreset.goldenHourSunset:
          contrast = 1.0 + (0.12 * luma);
          saturation = (1.0 + (0.15 * intensity)).clamp(0.0, 2.0);
          rs = 0.10 * spread;
          bs = -0.18 * spread;
          rm = 0.18 * spread;
          gm = 0.08 * spread;
          bm = -0.14 * spread;
          rh = 0.25 * spread;
          gh = 0.10 * spread;
          bh = -0.26 * spread;
          break;

        case ColorPalettePreset.cleanCommercial:
          contrast = 1.0 + (0.15 * luma);
          saturation = (1.0 + (0.18 * intensity)).clamp(0.0, 2.0);
          brightness = 0.03 * luma;
          rh = 0.05 * spread;
          bh = 0.07 * spread;
          break;

        case ColorPalettePreset.monochromeMood:
          contrast = 1.0 + (0.30 * luma);
          saturation = (1.0 - intensity).clamp(0.0, 1.0);
          break;
      }
    }

    // 1. Contrast, Brightness & Saturation filter
    final eqParts = <String>[];
    if ((contrast - 1.0).abs() > 0.001) {
      eqParts.add('contrast=${contrast.toStringAsFixed(3)}');
    }
    if (brightness.abs() > 0.001) {
      eqParts.add('brightness=${brightness.toStringAsFixed(3)}');
    }
    if ((saturation - 1.0).abs() > 0.001) {
      eqParts.add('saturation=${saturation.toStringAsFixed(3)}');
    }
    if (eqParts.isNotEmpty) {
      filters.add('eq=${eqParts.join(":")}');
    }

    // 2. Color balance 3-way shadow/midtone/highlight filter
    final cbParts = <String>[];
    if (rs.abs() > 0.005) cbParts.add('rs=${rs.clamp(-1.0, 1.0).toStringAsFixed(3)}');
    if (gs.abs() > 0.005) cbParts.add('gs=${gs.clamp(-1.0, 1.0).toStringAsFixed(3)}');
    if (bs.abs() > 0.005) cbParts.add('bs=${bs.clamp(-1.0, 1.0).toStringAsFixed(3)}');

    if (rm.abs() > 0.005) cbParts.add('rm=${rm.clamp(-1.0, 1.0).toStringAsFixed(3)}');
    if (gm.abs() > 0.005) cbParts.add('gm=${gm.clamp(-1.0, 1.0).toStringAsFixed(3)}');
    if (bm.abs() > 0.005) cbParts.add('bm=${bm.clamp(-1.0, 1.0).toStringAsFixed(3)}');

    if (rh.abs() > 0.005) cbParts.add('rh=${rh.clamp(-1.0, 1.0).toStringAsFixed(3)}');
    if (gh.abs() > 0.005) cbParts.add('gh=${gh.clamp(-1.0, 1.0).toStringAsFixed(3)}');
    if (bh.abs() > 0.005) cbParts.add('bh=${bh.clamp(-1.0, 1.0).toStringAsFixed(3)}');

    if (cbParts.isNotEmpty) {
      filters.add('colorbalance=${cbParts.join(":")}');
    }

    return filters;
  }
}
