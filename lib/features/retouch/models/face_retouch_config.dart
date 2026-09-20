import 'package:equatable/equatable.dart';

/// CapCut Pro Skin Tone Palette & Complexion Tint
enum SkinToneStyle {
  natural,
  porcelain,
  warmPeach,
  goldenHoney,
  bronzeSun,
  cinemaSoft,
}

extension SkinToneStyleExtension on SkinToneStyle {
  String get label {
    switch (this) {
      case SkinToneStyle.natural:
        return 'Natural True';
      case SkinToneStyle.porcelain:
        return 'Porcelain Ivory';
      case SkinToneStyle.warmPeach:
        return 'Warm Peach';
      case SkinToneStyle.goldenHoney:
        return 'Golden Honey';
      case SkinToneStyle.bronzeSun:
        return 'Bronze Sun';
      case SkinToneStyle.cinemaSoft:
        return 'Cinema Pastel';
    }
  }

  String get description {
    switch (this) {
      case SkinToneStyle.natural:
        return 'Balanced true-to-life skin pigment';
      case SkinToneStyle.porcelain:
        return 'Fair alabaster luminous ivory complexion';
      case SkinToneStyle.warmPeach:
        return 'Soft peachy-pink radiant rosy undertones';
      case SkinToneStyle.goldenHoney:
        return 'Sunlit golden warmth with rich highlights';
      case SkinToneStyle.bronzeSun:
        return 'Deep radiant sun-kissed bronzed glow';
      case SkinToneStyle.cinemaSoft:
        return 'Desaturated filmic soft pastel complexion';
    }
  }

  int get previewColor {
    switch (this) {
      case SkinToneStyle.natural:
        return 0xFFF5D6BA;
      case SkinToneStyle.porcelain:
        return 0xFFFFF0E5;
      case SkinToneStyle.warmPeach:
        return 0xFFFFD7C2;
      case SkinToneStyle.goldenHoney:
        return 0xFFF7CF97;
      case SkinToneStyle.bronzeSun:
        return 0xFFD89F6B;
      case SkinToneStyle.cinemaSoft:
        return 0xFFE8D5C8;
    }
  }
}

/// CapCut Pro Curated Retouching & Beauty Presets
enum RetouchPreset {
  none,
  naturalGlow,
  porcelainFlawless,
  goldenHour,
  cinemaClean,
  glamourPortrait,
  blemishEraser,
  subtleFresh,
}

extension RetouchPresetExtension on RetouchPreset {
  String get label {
    switch (this) {
      case RetouchPreset.none:
        return 'None (Raw)';
      case RetouchPreset.naturalGlow:
        return '🌟 Natural Glow';
      case RetouchPreset.porcelainFlawless:
        return '💎 Porcelain Flawless';
      case RetouchPreset.goldenHour:
        return '☀️ Golden Hour';
      case RetouchPreset.cinemaClean:
        return '🎬 Cinema Clean';
      case RetouchPreset.glamourPortrait:
        return '📸 Glamour Portrait';
      case RetouchPreset.blemishEraser:
        return '✨ Blemish Eraser';
      case RetouchPreset.subtleFresh:
        return '🌿 Subtle Fresh';
    }
  }
}

/// CapCut Pro AI Face & Body Retouching Domain Configuration
class FaceRetouchConfig extends Equatable {
  final bool isEnabled;

  // 1. Skin & Complexion
  final double skinSmooth; // 0.0 to 1.0 (bilateral edge-preserving blur)
  final double skinRadiance; // 0.0 to 1.0 (complexion luminance boost)
  final SkinToneStyle skinTone;

  // 2. Facial Features
  final double eyeBrighten; // 0.0 to 1.0 (iris reflection & sclera whitening)
  final double teethWhiten; // 0.0 to 1.0 (yellow-cast neutralization)
  final double darkCircles; // 0.0 to 1.0 (under-eye shadow concealer)
  final double faceSlimming; // 0.0 to 1.0 (jawline contouring squeeze)

  // 3. Body & Silhouette
  final double waistSlimming; // 0.0 to 1.0 (subtle torso slimming)
  final double legLengthening; // 0.0 to 1.0 (vertical perspective stretch)

  // 4. Preset Tracking
  final RetouchPreset activePreset;

  const FaceRetouchConfig({
    this.isEnabled = false,
    this.skinSmooth = 0.0,
    this.skinRadiance = 0.0,
    this.skinTone = SkinToneStyle.natural,
    this.eyeBrighten = 0.0,
    this.teethWhiten = 0.0,
    this.darkCircles = 0.0,
    this.faceSlimming = 0.0,
    this.waistSlimming = 0.0,
    this.legLengthening = 0.0,
    this.activePreset = RetouchPreset.none,
  });

  /// Factory preset configurations matching CapCut Pro's beauty engine
  static FaceRetouchConfig getPresetConfig(RetouchPreset preset) {
    switch (preset) {
      case RetouchPreset.none:
        return const FaceRetouchConfig();
      case RetouchPreset.naturalGlow:
        return const FaceRetouchConfig(
          isEnabled: true,
          skinSmooth: 0.45,
          skinRadiance: 0.35,
          skinTone: SkinToneStyle.natural,
          eyeBrighten: 0.30,
          teethWhiten: 0.25,
          darkCircles: 0.30,
          activePreset: RetouchPreset.naturalGlow,
        );
      case RetouchPreset.porcelainFlawless:
        return const FaceRetouchConfig(
          isEnabled: true,
          skinSmooth: 0.75,
          skinRadiance: 0.50,
          skinTone: SkinToneStyle.porcelain,
          eyeBrighten: 0.45,
          teethWhiten: 0.40,
          darkCircles: 0.55,
          faceSlimming: 0.20,
          activePreset: RetouchPreset.porcelainFlawless,
        );
      case RetouchPreset.goldenHour:
        return const FaceRetouchConfig(
          isEnabled: true,
          skinSmooth: 0.50,
          skinRadiance: 0.45,
          skinTone: SkinToneStyle.goldenHoney,
          eyeBrighten: 0.35,
          teethWhiten: 0.30,
          darkCircles: 0.40,
          activePreset: RetouchPreset.goldenHour,
        );
      case RetouchPreset.cinemaClean:
        return const FaceRetouchConfig(
          isEnabled: true,
          skinSmooth: 0.35,
          skinRadiance: 0.20,
          skinTone: SkinToneStyle.cinemaSoft,
          eyeBrighten: 0.25,
          teethWhiten: 0.20,
          darkCircles: 0.25,
          activePreset: RetouchPreset.cinemaClean,
        );
      case RetouchPreset.glamourPortrait:
        return const FaceRetouchConfig(
          isEnabled: true,
          skinSmooth: 0.80,
          skinRadiance: 0.60,
          skinTone: SkinToneStyle.warmPeach,
          eyeBrighten: 0.55,
          teethWhiten: 0.50,
          darkCircles: 0.65,
          faceSlimming: 0.30,
          waistSlimming: 0.20,
          activePreset: RetouchPreset.glamourPortrait,
        );
      case RetouchPreset.blemishEraser:
        return const FaceRetouchConfig(
          isEnabled: true,
          skinSmooth: 0.65,
          skinRadiance: 0.30,
          skinTone: SkinToneStyle.natural,
          darkCircles: 0.50,
          activePreset: RetouchPreset.blemishEraser,
        );
      case RetouchPreset.subtleFresh:
        return const FaceRetouchConfig(
          isEnabled: true,
          skinSmooth: 0.28,
          skinRadiance: 0.22,
          skinTone: SkinToneStyle.natural,
          eyeBrighten: 0.20,
          teethWhiten: 0.15,
          activePreset: RetouchPreset.subtleFresh,
        );
    }
  }

  FaceRetouchConfig copyWith({
    bool? isEnabled,
    double? skinSmooth,
    double? skinRadiance,
    SkinToneStyle? skinTone,
    double? eyeBrighten,
    double? teethWhiten,
    double? darkCircles,
    double? faceSlimming,
    double? waistSlimming,
    double? legLengthening,
    RetouchPreset? activePreset,
  }) {
    return FaceRetouchConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      skinSmooth: skinSmooth ?? this.skinSmooth,
      skinRadiance: skinRadiance ?? this.skinRadiance,
      skinTone: skinTone ?? this.skinTone,
      eyeBrighten: eyeBrighten ?? this.eyeBrighten,
      teethWhiten: teethWhiten ?? this.teethWhiten,
      darkCircles: darkCircles ?? this.darkCircles,
      faceSlimming: faceSlimming ?? this.faceSlimming,
      waistSlimming: waistSlimming ?? this.waistSlimming,
      legLengthening: legLengthening ?? this.legLengthening,
      activePreset: activePreset ?? this.activePreset,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'skinSmooth': skinSmooth,
        'skinRadiance': skinRadiance,
        'skinTone': skinTone.name,
        'eyeBrighten': eyeBrighten,
        'teethWhiten': teethWhiten,
        'darkCircles': darkCircles,
        'faceSlimming': faceSlimming,
        'waistSlimming': waistSlimming,
        'legLengthening': legLengthening,
        'activePreset': activePreset.name,
      };

  factory FaceRetouchConfig.fromJson(Map<String, dynamic> json) => FaceRetouchConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        skinSmooth: (json['skinSmooth'] as num?)?.toDouble() ?? 0.0,
        skinRadiance: (json['skinRadiance'] as num?)?.toDouble() ?? 0.0,
        skinTone: SkinToneStyle.values.firstWhere(
          (e) => e.name == json['skinTone'],
          orElse: () => SkinToneStyle.natural,
        ),
        eyeBrighten: (json['eyeBrighten'] as num?)?.toDouble() ?? 0.0,
        teethWhiten: (json['teethWhiten'] as num?)?.toDouble() ?? 0.0,
        darkCircles: (json['darkCircles'] as num?)?.toDouble() ?? 0.0,
        faceSlimming: (json['faceSlimming'] as num?)?.toDouble() ?? 0.0,
        waistSlimming: (json['waistSlimming'] as num?)?.toDouble() ?? 0.0,
        legLengthening: (json['legLengthening'] as num?)?.toDouble() ?? 0.0,
        activePreset: RetouchPreset.values.firstWhere(
          (e) => e.name == json['activePreset'],
          orElse: () => RetouchPreset.none,
        ),
      );

  /// Viewport floating status badge
  String get badge {
    if (!isEnabled) return '';
    if (activePreset != RetouchPreset.none) {
      final name = activePreset.name
          .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
          .toUpperCase();
      return '✨ RETOUCH ($name)';
    }
    final smoothPct = (skinSmooth * 100).round();
    return '✨ RETOUCH ($smoothPct%)';
  }

  @override
  List<Object?> get props => [
        isEnabled,
        skinSmooth,
        skinRadiance,
        skinTone,
        eyeBrighten,
        teethWhiten,
        darkCircles,
        faceSlimming,
        waistSlimming,
        legLengthening,
        activePreset,
      ];
}
