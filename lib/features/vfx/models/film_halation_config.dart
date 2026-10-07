import 'package:equatable/equatable.dart';

enum HalationHue {
  classicRed,   // Signature CineStill 800T / 35mm rem-jet red backscatter
  warmOrange,   // Kodak Vision3 500T warm ember glow
  magentaGlow,  // Fujicolor Eterna pastel magenta edge bleed
  goldenEmber,  // Vintage Kodachrome rich golden-amber halation
}

extension HalationHueExtension on HalationHue {
  String get label {
    switch (this) {
      case HalationHue.classicRed:
        return 'CineStill Neon Red';
      case HalationHue.warmOrange:
        return 'Vision3 Warm Orange';
      case HalationHue.magentaGlow:
        return 'Eterna Magenta Aura';
      case HalationHue.goldenEmber:
        return 'Kodachrome Amber';
    }
  }

  int get colorHex {
    switch (this) {
      case HalationHue.classicRed:
        return 0xFFFF1E27;
      case HalationHue.warmOrange:
        return 0xFFFF6B1A;
      case HalationHue.magentaGlow:
        return 0xFFFF0055;
      case HalationHue.goldenEmber:
        return 0xFFFF9E00;
    }
  }

  String get ffmpegMatrix {
    switch (this) {
      case HalationHue.classicRed:
        return 'colorchannelmixer=rr=1.4:rg=0.1:rb=0:gr=0:gg=0.8:gb=0:br=0:bg=0:bb=0.7';
      case HalationHue.warmOrange:
        return 'colorchannelmixer=rr=1.3:rg=0.4:rb=0:gr=0.1:gg=0.85:gb=0:br=0:bg=0:bb=0.6';
      case HalationHue.magentaGlow:
        return 'colorchannelmixer=rr=1.3:rg=0:rb=0.4:gr=0:gg=0.75:gb=0.1:br=0.2:bg=0:bb=0.9';
      case HalationHue.goldenEmber:
        return 'colorchannelmixer=rr=1.35:rg=0.6:rb=0:gr=0.2:gg=0.9:gb=0:br=0:bg=0:bb=0.5';
    }
  }
}

class FilmHalationConfig extends Equatable {
  final bool isEnabled;
  final HalationHue hue;
  final double threshold;      // 0.60 to 0.98 (specular highlight trigger, default 0.82)
  final double spreadRadius;   // 2.0 to 30.0 pixels (diffusion bloom radius, default 12.0)
  final double intensity;      // 0.0 to 1.0 (default 0.65)
  final double warmthBleed;    // 0.0 to 1.0 (secondary amber scatter, default 0.40)

  const FilmHalationConfig({
    this.isEnabled = false,
    this.hue = HalationHue.classicRed,
    this.threshold = 0.82,
    this.spreadRadius = 12.0,
    this.intensity = 0.65,
    this.warmthBleed = 0.40,
  });

  bool get isActive => isEnabled && intensity > 0.05;

  // Preset Configurations
  static const cineStill800T = FilmHalationConfig(
    isEnabled: true,
    hue: HalationHue.classicRed,
    threshold: 0.78,
    spreadRadius: 18.0,
    intensity: 0.85,
    warmthBleed: 0.50,
  );

  static const kodakVision3 = FilmHalationConfig(
    isEnabled: true,
    hue: HalationHue.warmOrange,
    threshold: 0.82,
    spreadRadius: 12.0,
    intensity: 0.60,
    warmthBleed: 0.45,
  );

  static const kodachrome64 = FilmHalationConfig(
    isEnabled: true,
    hue: HalationHue.goldenEmber,
    threshold: 0.80,
    spreadRadius: 10.0,
    intensity: 0.70,
    warmthBleed: 0.60,
  );

  static const fujicolorEterna = FilmHalationConfig(
    isEnabled: true,
    hue: HalationHue.magentaGlow,
    threshold: 0.84,
    spreadRadius: 14.0,
    intensity: 0.50,
    warmthBleed: 0.35,
  );

  static const subtle16mm = FilmHalationConfig(
    isEnabled: true,
    hue: HalationHue.classicRed,
    threshold: 0.88,
    spreadRadius: 8.0,
    intensity: 0.40,
    warmthBleed: 0.25,
  );

  FilmHalationConfig copyWith({
    bool? isEnabled,
    HalationHue? hue,
    double? threshold,
    double? spreadRadius,
    double? intensity,
    double? warmthBleed,
  }) {
    return FilmHalationConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      hue: hue ?? this.hue,
      threshold: threshold ?? this.threshold,
      spreadRadius: spreadRadius ?? this.spreadRadius,
      intensity: intensity ?? this.intensity,
      warmthBleed: warmthBleed ?? this.warmthBleed,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'hue': hue.name,
        'threshold': threshold,
        'spreadRadius': spreadRadius,
        'intensity': intensity,
        'warmthBleed': warmthBleed,
      };

  factory FilmHalationConfig.fromJson(Map<String, dynamic> json) => FilmHalationConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        hue: HalationHue.values.firstWhere(
          (e) => e.name == json['hue'],
          orElse: () => HalationHue.classicRed,
        ),
        threshold: (json['threshold'] as num?)?.toDouble() ?? 0.82,
        spreadRadius: (json['spreadRadius'] as num?)?.toDouble() ?? 12.0,
        intensity: (json['intensity'] as num?)?.toDouble() ?? 0.65,
        warmthBleed: (json['warmthBleed'] as num?)?.toDouble() ?? 0.40,
      );

  @override
  List<Object?> get props => [
        isEnabled,
        hue,
        threshold,
        spreadRadius,
        intensity,
        warmthBleed,
      ];
}
