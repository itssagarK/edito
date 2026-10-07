import 'package:equatable/equatable.dart';

/// Preset optical dispersion and light bleed profiles.
enum LightLeakProfile {
  warmSunsetFlare,
  rainbowPrism,
  vintage35mmBurn,
  anamorphicCyanLeak,
  subtleAmbientGlow;

  String get displayName {
    switch (this) {
      case LightLeakProfile.warmSunsetFlare:
        return 'Warm Sunset Flare';
      case LightLeakProfile.rainbowPrism:
        return 'Rainbow Prism Dispersion';
      case LightLeakProfile.vintage35mmBurn:
        return 'Vintage 35mm Film Burn';
      case LightLeakProfile.anamorphicCyanLeak:
        return 'Anamorphic Cyan Beam';
      case LightLeakProfile.subtleAmbientGlow:
        return 'Subtle Ambient Glow';
    }
  }

  String get description {
    switch (this) {
      case LightLeakProfile.warmSunsetFlare:
        return 'Golden hour orange, amber, and magenta solar light bleeding';
      case LightLeakProfile.rainbowPrism:
        return 'Multi-color spectral chromatic dispersion across diagonal arcs';
      case LightLeakProfile.vintage35mmBurn:
        return 'Harsh amber/red edge exposure leak simulating canister damage';
      case LightLeakProfile.anamorphicCyanLeak:
        return 'Horizontal sci-fi cyan and cobalt optical flare streak';
      case LightLeakProfile.subtleAmbientGlow:
        return 'Soft organic pastel luminescence and gentle exposure breathing';
    }
  }
}

/// Screen placement origin for the primary light leak hotspot.
enum LightLeakPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  centerSweep;

  String get displayName {
    switch (this) {
      case LightLeakPosition.topLeft:
        return 'Top-Left Corner';
      case LightLeakPosition.topRight:
        return 'Top-Right Corner';
      case LightLeakPosition.bottomLeft:
        return 'Bottom-Left Corner';
      case LightLeakPosition.bottomRight:
        return 'Bottom-Right Corner';
      case LightLeakPosition.centerSweep:
        return 'Center Sweep';
    }
  }
}

/// Configuration for organic light leak and rainbow prism VFX.
class LightLeakConfig extends Equatable {
  final bool isEnabled;
  final LightLeakProfile profile;
  final LightLeakPosition position;
  final double intensity; // 0.0 to 1.0 (opacity / magnitude)
  final double speed; // 0.2 to 3.0 (animation & pulse speed multiplier)
  final double saturation; // 0.5 to 2.0 (color vibrancy)
  final double warmth; // -1.0 to 1.0 (cool cyan to warm amber tint shift)

  const LightLeakConfig({
    this.isEnabled = false,
    this.profile = LightLeakProfile.rainbowPrism,
    this.position = LightLeakPosition.topLeft,
    this.intensity = 0.60,
    this.speed = 1.0,
    this.saturation = 1.25,
    this.warmth = 0.2,
  });

  bool get isActive => isEnabled && intensity > 0.01;

  // Curated presets
  static const LightLeakConfig sunsetGoldenHour = LightLeakConfig(
    isEnabled: true,
    profile: LightLeakProfile.warmSunsetFlare,
    position: LightLeakPosition.topLeft,
    intensity: 0.65,
    speed: 0.9,
    saturation: 1.35,
    warmth: 0.6,
  );

  static const LightLeakConfig spectralPrism = LightLeakConfig(
    isEnabled: true,
    profile: LightLeakProfile.rainbowPrism,
    position: LightLeakPosition.centerSweep,
    intensity: 0.70,
    speed: 1.1,
    saturation: 1.50,
    warmth: 0.0,
  );

  static const LightLeakConfig kodakFilmBurn = LightLeakConfig(
    isEnabled: true,
    profile: LightLeakProfile.vintage35mmBurn,
    position: LightLeakPosition.topRight,
    intensity: 0.75,
    speed: 1.4,
    saturation: 1.40,
    warmth: 0.8,
  );

  static const LightLeakConfig cyberpunkCyanFlare = LightLeakConfig(
    isEnabled: true,
    profile: LightLeakProfile.anamorphicCyanLeak,
    position: LightLeakPosition.bottomLeft,
    intensity: 0.60,
    speed: 0.8,
    saturation: 1.30,
    warmth: -0.7,
  );

  static const LightLeakConfig dreamyPastelBreathing = LightLeakConfig(
    isEnabled: true,
    profile: LightLeakProfile.subtleAmbientGlow,
    position: LightLeakPosition.topLeft,
    intensity: 0.40,
    speed: 0.6,
    saturation: 1.10,
    warmth: 0.2,
  );

  LightLeakConfig copyWith({
    bool? isEnabled,
    LightLeakProfile? profile,
    LightLeakPosition? position,
    double? intensity,
    double? speed,
    double? saturation,
    double? warmth,
  }) {
    return LightLeakConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      profile: profile ?? this.profile,
      position: position ?? this.position,
      intensity: intensity ?? this.intensity,
      speed: speed ?? this.speed,
      saturation: saturation ?? this.saturation,
      warmth: warmth ?? this.warmth,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'profile': profile.name,
      'position': position.name,
      'intensity': intensity,
      'speed': speed,
      'saturation': saturation,
      'warmth': warmth,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory LightLeakConfig.fromMap(Map<String, dynamic> map) {
    return LightLeakConfig(
      isEnabled: map['isEnabled'] as bool? ?? false,
      profile: LightLeakProfile.values.firstWhere(
        (e) => e.name == map['profile'],
        orElse: () => LightLeakProfile.rainbowPrism,
      ),
      position: LightLeakPosition.values.firstWhere(
        (e) => e.name == map['position'],
        orElse: () => LightLeakPosition.topLeft,
      ),
      intensity: (map['intensity'] as num?)?.toDouble() ?? 0.60,
      speed: (map['speed'] as num?)?.toDouble() ?? 1.0,
      saturation: (map['saturation'] as num?)?.toDouble() ?? 1.25,
      warmth: (map['warmth'] as num?)?.toDouble() ?? 0.2,
    );
  }

  factory LightLeakConfig.fromJson(Map<String, dynamic> json) =>
      LightLeakConfig.fromMap(json);

  @override
  List<Object?> get props => [
        isEnabled,
        profile,
        position,
        intensity,
        speed,
        saturation,
        warmth,
      ];
}
