import '../models/denoise_config.dart';

/// CapCut Pro Video De-Noise & Low-Light Enhancement Compiler Service
class DenoiseCompilerService {
  /// Pure mathematical 4x5 identity matrix
  static const List<double> identityMatrix = [
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  /// Compiles deterministic FFmpeg filter chains for video denoising & low-light rendering
  static List<String> generateFFmpegFilters(DenoiseConfig config) {
    if (!config.isEnabled || config.level == DenoiseLevel.none) {
      return const [];
    }

    final filters = <String>[];

    // 1. Core Denoise DSP Filter Chain
    switch (config.algorithm) {
      case DenoiseAlgorithm.spatioTemporal3D:
        final sl = config.spatialLuma.clamp(0.0, 20.0).toStringAsFixed(1);
        final sc = config.spatialChroma.clamp(0.0, 20.0).toStringAsFixed(1);
        final tl = config.temporalLuma.clamp(0.0, 30.0).toStringAsFixed(1);
        final tc = config.temporalChroma.clamp(0.0, 30.0).toStringAsFixed(1);
        filters.add('hqdn3d=$sl:$sc:$tl:$tc');
        break;

      case DenoiseAlgorithm.adaptiveTemporal:
        // Multi-frame adaptive temporal averaging
        filters.add('atadenoise=0a=0.1:0b=0.08:1a=0.1:1b=0.08');
        break;

      case DenoiseAlgorithm.edgePreservingBilateral:
        // Pure spatial bilateral filtering
        final sl = config.spatialLuma.clamp(0.0, 20.0).toStringAsFixed(1);
        final sc = config.spatialChroma.clamp(0.0, 20.0).toStringAsFixed(1);
        filters.add('hqdn3d=$sl:$sc:0.0:0.0');
        break;
    }

    // 2. Micro-Edge Detail Recovery & Texture Sharpening
    if (config.detailSharpening > 0.0) {
      final amount = config.detailSharpening.clamp(0.0, 1.5).toStringAsFixed(2);
      filters.add('unsharp=5:5:$amount:5:5:0.0');
    }

    // 3. Low-Light Shadow & Contrast Enhancement
    if (config.lowLightBoost > 0.0) {
      final boost = config.lowLightBoost.clamp(0.0, 1.0);
      final contrast = 1.0 + (boost * 0.15);
      final brightness = boost * 0.08;
      filters.add('eq=contrast=${contrast.toStringAsFixed(3)}:brightness=${brightness.toStringAsFixed(3)}');
    }

    return filters;
  }

  /// Calculates a 4x5 ColorFilter matrix for viewport visual feedback
  static List<double> calculateColorMatrix(DenoiseConfig config) {
    if (!config.isEnabled || config.level == DenoiseLevel.none || config.lowLightBoost <= 0.0) {
      return identityMatrix;
    }

    final boost = config.lowLightBoost.clamp(0.0, 1.0);
    final contrast = 1.0 + (boost * 0.12);
    final brightnessOffset = boost * 18.0;
    final cShift = (1.0 - contrast) * 128.0;

    return [
      contrast, 0.0, 0.0, 0.0, brightnessOffset + cShift,
      0.0, contrast, 0.0, 0.0, brightnessOffset + cShift,
      0.0, 0.0, contrast, 0.0, brightnessOffset + cShift,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }
}
