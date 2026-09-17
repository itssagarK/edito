import 'package:equatable/equatable.dart';

enum VideoBorderStyle {
  solid,
  neonGlow,
  gradient,
  roundedCard,
  filmStrip,
  polaroid,
  vignetteFrame,
  retroTv,
}

extension VideoBorderStyleExtension on VideoBorderStyle {
  String get label {
    switch (this) {
      case VideoBorderStyle.solid:
        return 'Solid Frame';
      case VideoBorderStyle.neonGlow:
        return 'Neon Aura Glow';
      case VideoBorderStyle.gradient:
        return 'Aesthetic Gradient';
      case VideoBorderStyle.roundedCard:
        return 'Floating Card (Rounded)';
      case VideoBorderStyle.filmStrip:
        return '35mm Film Strip';
      case VideoBorderStyle.polaroid:
        return 'Vintage Polaroid';
      case VideoBorderStyle.vignetteFrame:
        return 'Cinematic Letterbox';
      case VideoBorderStyle.retroTv:
        return 'Retro TV Bezel';
    }
  }

  String get description {
    switch (this) {
      case VideoBorderStyle.solid:
        return 'Clean, high-precision solid edge border';
      case VideoBorderStyle.neonGlow:
        return 'Vibrant glowing radiant border for short-form clips';
      case VideoBorderStyle.gradient:
        return 'Two-tone smooth gradient border framing';
      case VideoBorderStyle.roundedCard:
        return 'Modern floating card with rounded corner curvature';
      case VideoBorderStyle.filmStrip:
        return 'Classic 35mm motion picture cinema film borders';
      case VideoBorderStyle.polaroid:
        return 'Retro instant photograph frame with bottom signature margin';
      case VideoBorderStyle.vignetteFrame:
        return 'Deep widescreen letterbox with edge shadow';
      case VideoBorderStyle.retroTv:
        return 'Curved CRT television frame with glass bezel';
    }
  }
}

enum BorderPreset {
  cleanWhite,
  cyberpunkNeon,
  goldLuxury,
  crimsonPunch,
  gradientSunset,
  filmStrip35mm,
  retroTvBezel,
  roundedCard,
  polaroid,
}

extension BorderPresetExtension on BorderPreset {
  String get label {
    switch (this) {
      case BorderPreset.cleanWhite:
        return '⬜ Clean White';
      case BorderPreset.cyberpunkNeon:
        return '⚡ Cyberpunk Neon';
      case BorderPreset.goldLuxury:
        return '👑 Gold Luxury';
      case BorderPreset.crimsonPunch:
        return '🔴 Crimson Punch';
      case BorderPreset.gradientSunset:
        return '🌅 Sunset Gradient';
      case BorderPreset.filmStrip35mm:
        return '🎞️ 35mm Film';
      case BorderPreset.retroTvBezel:
        return '📺 Retro TV';
      case BorderPreset.roundedCard:
        return '📱 Rounded Card';
      case BorderPreset.polaroid:
        return '📷 Polaroid Photo';
    }
  }

  VideoBorderConfig createConfig() {
    switch (this) {
      case BorderPreset.cleanWhite:
        return const VideoBorderConfig(
          isEnabled: true,
          style: VideoBorderStyle.solid,
          borderWidth: 8.0,
          borderColor: 0xFFFFFFFF,
          cornerRadius: 0.0,
          borderOpacity: 1.0,
        );
      case BorderPreset.cyberpunkNeon:
        return const VideoBorderConfig(
          isEnabled: true,
          style: VideoBorderStyle.neonGlow,
          borderWidth: 10.0,
          borderColor: 0xFF00E5FF,
          secondaryColor: 0xFFFF007F,
          cornerRadius: 16.0,
          glowIntensity: 0.8,
          borderOpacity: 1.0,
        );
      case BorderPreset.goldLuxury:
        return const VideoBorderConfig(
          isEnabled: true,
          style: VideoBorderStyle.gradient,
          borderWidth: 10.0,
          borderColor: 0xFFFFD700,
          secondaryColor: 0xFFFF8C00,
          cornerRadius: 8.0,
          borderOpacity: 1.0,
        );
      case BorderPreset.crimsonPunch:
        return const VideoBorderConfig(
          isEnabled: true,
          style: VideoBorderStyle.solid,
          borderWidth: 12.0,
          borderColor: 0xFFFF2A2A,
          cornerRadius: 4.0,
          borderOpacity: 1.0,
        );
      case BorderPreset.gradientSunset:
        return const VideoBorderConfig(
          isEnabled: true,
          style: VideoBorderStyle.gradient,
          borderWidth: 14.0,
          borderColor: 0xFFFF512F,
          secondaryColor: 0xFFDD2476,
          cornerRadius: 12.0,
          borderOpacity: 1.0,
        );
      case BorderPreset.filmStrip35mm:
        return const VideoBorderConfig(
          isEnabled: true,
          style: VideoBorderStyle.filmStrip,
          borderWidth: 18.0,
          borderColor: 0xFF141414,
          cornerRadius: 0.0,
          borderOpacity: 1.0,
        );
      case BorderPreset.retroTvBezel:
        return const VideoBorderConfig(
          isEnabled: true,
          style: VideoBorderStyle.retroTv,
          borderWidth: 16.0,
          borderColor: 0xFF2A2A36,
          cornerRadius: 24.0,
          borderOpacity: 1.0,
        );
      case BorderPreset.roundedCard:
        return const VideoBorderConfig(
          isEnabled: true,
          style: VideoBorderStyle.roundedCard,
          borderWidth: 6.0,
          borderColor: 0xFF6C5CE7,
          cornerRadius: 28.0,
          borderOpacity: 0.9,
        );
      case BorderPreset.polaroid:
        return const VideoBorderConfig(
          isEnabled: true,
          style: VideoBorderStyle.polaroid,
          borderWidth: 14.0,
          borderColor: 0xFFFAFAFA,
          cornerRadius: 4.0,
          borderOpacity: 1.0,
        );
    }
  }
}

class VideoBorderConfig extends Equatable {
  final bool isEnabled;
  final VideoBorderStyle style;
  final double borderWidth;       // 2.0 to 48.0 px
  final int borderColor;          // ARGB color (e.g. 0xFFFFFFFF)
  final int? secondaryColor;      // For gradients (e.g. 0xFF00FFCC)
  final double cornerRadius;      // 0.0 to 48.0 px
  final double borderOpacity;     // 0.1 to 1.0
  final double glowIntensity;     // 0.0 to 1.0
  final double padding;           // 0.0 to 32.0 px inner margin

  const VideoBorderConfig({
    this.isEnabled = false,
    this.style = VideoBorderStyle.solid,
    this.borderWidth = 8.0,
    this.borderColor = 0xFFFFFFFF,
    this.secondaryColor,
    this.cornerRadius = 0.0,
    this.borderOpacity = 1.0,
    this.glowIntensity = 0.5,
    this.padding = 0.0,
  });

  // Compatibility aliases
  int get primaryColor => borderColor;
  double get borderRadius => cornerRadius;
  double get opacity => borderOpacity;

  VideoBorderConfig copyWith({
    bool? isEnabled,
    VideoBorderStyle? style,
    double? borderWidth,
    int? borderColor,
    int? secondaryColor,
    double? cornerRadius,
    double? borderOpacity,
    double? glowIntensity,
    double? padding,
  }) {
    return VideoBorderConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      style: style ?? this.style,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      borderOpacity: borderOpacity ?? this.borderOpacity,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      padding: padding ?? this.padding,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'style': style.name,
        'borderWidth': borderWidth,
        'borderColor': borderColor,
        'secondaryColor': secondaryColor,
        'cornerRadius': cornerRadius,
        'borderOpacity': borderOpacity,
        'glowIntensity': glowIntensity,
        'padding': padding,
      };

  factory VideoBorderConfig.fromJson(Map<String, dynamic> json) => VideoBorderConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        style: VideoBorderStyle.values.firstWhere(
          (e) => e.name == json['style'],
          orElse: () => VideoBorderStyle.solid,
        ),
        borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 8.0,
        borderColor: (json['borderColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
        secondaryColor: (json['secondaryColor'] as num?)?.toInt(),
        cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
        borderOpacity: (json['borderOpacity'] as num?)?.toDouble() ?? 1.0,
        glowIntensity: (json['glowIntensity'] as num?)?.toDouble() ?? 0.5,
        padding: (json['padding'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  List<Object?> get props => [
        isEnabled,
        style,
        borderWidth,
        borderColor,
        secondaryColor,
        cornerRadius,
        borderOpacity,
        glowIntensity,
        padding,
      ];
}
