import '../models/face_retouch_config.dart';

/// CapCut Pro Face & Body Retouching Filtergraph Compiler Service
class FaceRetouchCompilerService {
  /// Generates deterministic FFmpeg filter chains for video export
  static List<String> generateFFmpegFilters(FaceRetouchConfig config) {
    if (!config.isEnabled) return const [];

    final filters = <String>[];

    // 1. Bilateral edge-preserving skin smoothing filter (smartblur)
    if (config.skinSmooth > 0.05) {
      // Radius: 1.5 to 5.0
      final radius = (1.5 + config.skinSmooth * 3.5).toStringAsFixed(1);
      // Strength: -0.4 to -1.2 (negative values in smartblur soften low-contrast textures)
      final strength = (-0.4 - config.skinSmooth * 0.8).toStringAsFixed(2);
      // Threshold: -2.0 to -7.0 (edge protection boundary)
      final threshold = (-2.0 - config.skinSmooth * 5.0).toStringAsFixed(1);

      filters.add('smartblur=lr=$radius:ls=$strength:lt=$threshold');

      // Unsharp mask to restore crispness to eye outlines and hair texture
      final unsharpAmt = (0.3 + config.skinSmooth * 0.6).toStringAsFixed(2);
      filters.add('unsharp=5:5:$unsharpAmt:3:3:$unsharpAmt');
    }

    // 2. Complexion Radiance, Contrast, and Saturation (eq)
    if (config.skinRadiance > 0.05 || config.eyeBrighten > 0.05) {
      final brightness = (config.skinRadiance * 0.06 + config.eyeBrighten * 0.03).clamp(0.0, 0.12).toStringAsFixed(3);
      final contrast = (1.0 + config.skinRadiance * 0.08).toStringAsFixed(3);
      final saturation = (1.0 + (config.skinRadiance * 0.05) - (config.teethWhiten * 0.03)).clamp(0.9, 1.2).toStringAsFixed(3);

      filters.add('eq=brightness=$brightness:contrast=$contrast:saturation=$saturation');
    }

    // 3. Skin Tone Palette Tinting (colorbalance)
    final toneFilter = _getSkinToneColorBalance(config.skinTone, config.skinRadiance);
    if (toneFilter.isNotEmpty) {
      filters.add(toneFilter);
    }

    // 4. Teeth Whitening & Eye Sclera Brightening (subtle yellow-cast neutralization in highlights)
    if (config.teethWhiten > 0.05) {
      final blueBoost = (config.teethWhiten * 0.08).toStringAsFixed(3);
      final redCut = (-config.teethWhiten * 0.04).toStringAsFixed(3);
      filters.add('colorbalance=rh=$redCut:bh=$blueBoost');
    }

    return filters;
  }

  static String _getSkinToneColorBalance(SkinToneStyle tone, double radiance) {
    final intensity = (0.5 + radiance * 0.5);
    switch (tone) {
      case SkinToneStyle.natural:
        return '';
      case SkinToneStyle.porcelain:
        final r = (0.03 * intensity).toStringAsFixed(3);
        final b = (0.05 * intensity).toStringAsFixed(3);
        return 'colorbalance=rm=$r:bm=$b:rh=$r:bh=$b';
      case SkinToneStyle.warmPeach:
        final r = (0.07 * intensity).toStringAsFixed(3);
        final g = (0.02 * intensity).toStringAsFixed(3);
        final b = (-0.02 * intensity).toStringAsFixed(3);
        return 'colorbalance=rm=$r:gm=$g:bm=$b';
      case SkinToneStyle.goldenHoney:
        final r = (0.09 * intensity).toStringAsFixed(3);
        final g = (0.05 * intensity).toStringAsFixed(3);
        final b = (-0.07 * intensity).toStringAsFixed(3);
        return 'colorbalance=rm=$r:gm=$g:bm=$b:rh=$r';
      case SkinToneStyle.bronzeSun:
        final r = (0.12 * intensity).toStringAsFixed(3);
        final g = (0.04 * intensity).toStringAsFixed(3);
        final b = (-0.09 * intensity).toStringAsFixed(3);
        return 'colorbalance=rm=$r:gm=$g:bm=$b:rs=$r';
      case SkinToneStyle.cinemaSoft:
        final r = (-0.03 * intensity).toStringAsFixed(3);
        final g = (0.01 * intensity).toStringAsFixed(3);
        final b = (0.03 * intensity).toStringAsFixed(3);
        return 'colorbalance=rm=$r:gm=$g:bm=$b';
    }
  }

  /// Generates a real-time Skia GPU 4x5 ColorMatrix for viewport preview
  static List<double> generateColorFilterMatrix(FaceRetouchConfig config) {
    if (!config.isEnabled) {
      // Identity 4x5 matrix
      return const [
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ];
    }

    // Radiance glow boost
    final rad = config.skinRadiance;
    final brightOffset = rad * 18.0; // 0 to 18 brightness
    final contrast = 1.0 + rad * 0.08;

    // Skin tone color adjustments
    double rMult = 1.0;
    double gMult = 1.0;
    double bMult = 1.0;

    switch (config.skinTone) {
      case SkinToneStyle.natural:
        break;
      case SkinToneStyle.porcelain:
        rMult = 1.02;
        gMult = 1.01;
        bMult = 1.05;
        break;
      case SkinToneStyle.warmPeach:
        rMult = 1.06;
        gMult = 1.02;
        bMult = 0.98;
        break;
      case SkinToneStyle.goldenHoney:
        rMult = 1.08;
        gMult = 1.04;
        bMult = 0.93;
        break;
      case SkinToneStyle.bronzeSun:
        rMult = 1.10;
        gMult = 1.03;
        bMult = 0.90;
        break;
      case SkinToneStyle.cinemaSoft:
        rMult = 0.97;
        gMult = 1.01;
        bMult = 1.03;
        break;
    }

    // Teeth whitening slight blue lift & yellow reduction
    if (config.teethWhiten > 0.0) {
      bMult += config.teethWhiten * 0.04;
    }

    return [
      contrast * rMult, 0, 0, 0, brightOffset,
      0, contrast * gMult, 0, 0, brightOffset,
      0, 0, contrast * bMult, 0, brightOffset,
      0, 0, 0, 1, 0,
    ];
  }

  /// Floating status badge
  static String getBadge(FaceRetouchConfig config) {
    return config.badge;
  }
}
