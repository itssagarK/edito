import 'package:equatable/equatable.dart';

enum CharacterHighlightMode {
  spotlight,
  neonAura,
  bwBackground,
  solidBgWash,
}

extension CharacterHighlightModeExtension on CharacterHighlightMode {
  String get label {
    switch (this) {
      case CharacterHighlightMode.spotlight:
        return 'Character Spotlight';
      case CharacterHighlightMode.neonAura:
        return 'Neon Aura Glow';
      case CharacterHighlightMode.bwBackground:
        return 'B&W Background Pop';
      case CharacterHighlightMode.solidBgWash:
        return 'Background Color Swap';
    }
  }

  String get description {
    switch (this) {
      case CharacterHighlightMode.spotlight:
        return 'Illuminates subject, dims and recolors background';
      case CharacterHighlightMode.neonAura:
        return 'Radiant neon aura around character with custom BG';
      case CharacterHighlightMode.bwBackground:
        return 'Monochrome background, character in vivid color';
      case CharacterHighlightMode.solidBgWash:
        return 'Replaces background with selected vibrant color';
    }
  }
}

class CharacterHighlightConfig extends Equatable {
  final bool isEnabled;
  final CharacterHighlightMode mode;
  final int highlightColor;          // 0xFF00FFCC (Cyan)
  final double highlightIntensity;   // 0.2 to 2.0 (1.0 default)
  final double spotlightRadius;      // 0.2 to 0.9 (0.55 default)
  final double feather;              // 0.1 to 1.0 (0.4 default)
  final int backgroundColor;         // 0xFF141419 (Dark Studio), 0xFF4A00E0 (Purple), etc.
  final double backgroundDimming;    // 0.0 to 1.0 (0.6 default)
  final double backgroundSaturation; // 0.0 to 1.0 (0.2 default)
  final double characterCenterX;     // 0.0 to 1.0 (0.5 center)
  final double characterCenterY;     // 0.0 to 1.0 (0.5 center)

  const CharacterHighlightConfig({
    this.isEnabled = false,
    this.mode = CharacterHighlightMode.spotlight,
    this.highlightColor = 0xFF00FFCC,
    this.highlightIntensity = 1.0,
    this.spotlightRadius = 0.55,
    this.feather = 0.40,
    this.backgroundColor = 0xFF141419,
    this.backgroundDimming = 0.60,
    this.backgroundSaturation = 0.20,
    this.characterCenterX = 0.5,
    this.characterCenterY = 0.5,
  });

  CharacterHighlightConfig copyWith({
    bool? isEnabled,
    CharacterHighlightMode? mode,
    int? highlightColor,
    double? highlightIntensity,
    double? spotlightRadius,
    double? feather,
    int? backgroundColor,
    double? backgroundDimming,
    double? backgroundSaturation,
    double? characterCenterX,
    double? characterCenterY,
  }) {
    return CharacterHighlightConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      highlightColor: highlightColor ?? this.highlightColor,
      highlightIntensity: highlightIntensity ?? this.highlightIntensity,
      spotlightRadius: spotlightRadius ?? this.spotlightRadius,
      feather: feather ?? this.feather,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundDimming: backgroundDimming ?? this.backgroundDimming,
      backgroundSaturation: backgroundSaturation ?? this.backgroundSaturation,
      characterCenterX: characterCenterX ?? this.characterCenterX,
      characterCenterY: characterCenterY ?? this.characterCenterY,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'mode': mode.name,
        'highlightColor': highlightColor,
        'highlightIntensity': highlightIntensity,
        'spotlightRadius': spotlightRadius,
        'feather': feather,
        'backgroundColor': backgroundColor,
        'backgroundDimming': backgroundDimming,
        'backgroundSaturation': backgroundSaturation,
        'characterCenterX': characterCenterX,
        'characterCenterY': characterCenterY,
      };

  factory CharacterHighlightConfig.fromJson(Map<String, dynamic> json) {
    return CharacterHighlightConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: CharacterHighlightMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => CharacterHighlightMode.spotlight,
      ),
      highlightColor: json['highlightColor'] as int? ?? 0xFF00FFCC,
      highlightIntensity: (json['highlightIntensity'] as num?)?.toDouble() ?? 1.0,
      spotlightRadius: (json['spotlightRadius'] as num?)?.toDouble() ?? 0.55,
      feather: (json['feather'] as num?)?.toDouble() ?? 0.40,
      backgroundColor: json['backgroundColor'] as int? ?? 0xFF141419,
      backgroundDimming: (json['backgroundDimming'] as num?)?.toDouble() ?? 0.60,
      backgroundSaturation: (json['backgroundSaturation'] as num?)?.toDouble() ?? 0.20,
      characterCenterX: (json['characterCenterX'] as num?)?.toDouble() ?? 0.5,
      characterCenterY: (json['characterCenterY'] as num?)?.toDouble() ?? 0.5,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        highlightColor,
        highlightIntensity,
        spotlightRadius,
        feather,
        backgroundColor,
        backgroundDimming,
        backgroundSaturation,
        characterCenterX,
        characterCenterY,
      ];
}
