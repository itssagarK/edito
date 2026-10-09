import 'package:equatable/equatable.dart';

/// Modes of liquid water caustics and underwater wave refractions.
enum WaterCausticsMode {
  tropicalPool,
  abyssalDeep,
  emeraldLagoon,
  bioluminescentReef,
  sunkenGold,
}

extension WaterCausticsModeExtension on WaterCausticsMode {
  String get label {
    switch (this) {
      case WaterCausticsMode.tropicalPool:
        return 'Tropical Pool';
      case WaterCausticsMode.abyssalDeep:
        return 'Abyssal Deep';
      case WaterCausticsMode.emeraldLagoon:
        return 'Emerald Lagoon';
      case WaterCausticsMode.bioluminescentReef:
        return 'Bioluminescent';
      case WaterCausticsMode.sunkenGold:
        return 'Sunken Gold';
    }
  }

  String get description {
    switch (this) {
      case WaterCausticsMode.tropicalPool:
        return 'Crystal-clear pool with shimmering cyan sunlit caustic rays';
      case WaterCausticsMode.abyssalDeep:
        return 'Deep oceanic navy twilight with slow undulating trench refractions';
      case WaterCausticsMode.emeraldLagoon:
        return 'Lush jungle cenote with warm emerald-cyan aquatic light webs';
      case WaterCausticsMode.bioluminescentReef:
        return 'Vibrant neon cyan and purple glowing marine twilight caustics';
      case WaterCausticsMode.sunkenGold:
        return 'Warm amber sunbeams illuminating shallow shimmering sandbars';
    }
  }

  String get iconAsset {
    switch (this) {
      case WaterCausticsMode.tropicalPool:
        return 'water_drop';
      case WaterCausticsMode.abyssalDeep:
        return 'waves';
      case WaterCausticsMode.emeraldLagoon:
        return 'pool';
      case WaterCausticsMode.bioluminescentReef:
        return 'flare';
      case WaterCausticsMode.sunkenGold:
        return 'wb_sunny';
    }
  }
}

/// Configuration for liquid water caustics and underwater refractive waves.
class WaterCausticsConfig extends Equatable {
  final bool isEnabled;
  final WaterCausticsMode mode;
  final double intensity; // 0.0 to 1.0 (overall visibility of caustic light web)
  final double scale; // 0.5 to 3.0 (cell density of the voronoi caustic mesh)
  final double speed; // 0.2 to 3.0 (animation ripple frequency)
  final double refractionWarp; // 0.0 to 1.0 (underwater optical distortion)
  final double chromaticDispersion; // 0.0 to 1.0 (edge prismatic rainbow fringing)
  final double tintDepth; // 0.0 to 1.0 (aquatic color absorption grading)

  const WaterCausticsConfig({
    this.isEnabled = false,
    this.mode = WaterCausticsMode.tropicalPool,
    this.intensity = 0.6,
    this.scale = 1.2,
    this.speed = 1.0,
    this.refractionWarp = 0.4,
    this.chromaticDispersion = 0.35,
    this.tintDepth = 0.45,
  });

  bool get isActive => isEnabled && intensity > 0.0;

  /// Default disabled configuration.
  static const WaterCausticsConfig defaultDisabled = WaterCausticsConfig();

  // Curated 5 cinematic presets
  static const WaterCausticsConfig presetTropicalLagoon = WaterCausticsConfig(
    isEnabled: true,
    mode: WaterCausticsMode.tropicalPool,
    intensity: 0.70,
    scale: 1.1,
    speed: 1.2,
    refractionWarp: 0.40,
    chromaticDispersion: 0.30,
    tintDepth: 0.45,
  );

  static const WaterCausticsConfig presetAbyssalTrench = WaterCausticsConfig(
    isEnabled: true,
    mode: WaterCausticsMode.abyssalDeep,
    intensity: 0.55,
    scale: 1.6,
    speed: 0.6,
    refractionWarp: 0.60,
    chromaticDispersion: 0.45,
    tintDepth: 0.75,
  );

  static const WaterCausticsConfig presetEmeraldCenote = WaterCausticsConfig(
    isEnabled: true,
    mode: WaterCausticsMode.emeraldLagoon,
    intensity: 0.65,
    scale: 1.2,
    speed: 0.9,
    refractionWarp: 0.35,
    chromaticDispersion: 0.25,
    tintDepth: 0.60,
  );

  static const WaterCausticsConfig presetBioluminescentNight = WaterCausticsConfig(
    isEnabled: true,
    mode: WaterCausticsMode.bioluminescentReef,
    intensity: 0.80,
    scale: 1.4,
    speed: 1.5,
    refractionWarp: 0.50,
    chromaticDispersion: 0.60,
    tintDepth: 0.70,
  );

  static const WaterCausticsConfig presetShallowSunlight = WaterCausticsConfig(
    isEnabled: true,
    mode: WaterCausticsMode.sunkenGold,
    intensity: 0.50,
    scale: 0.9,
    speed: 1.1,
    refractionWarp: 0.25,
    chromaticDispersion: 0.20,
    tintDepth: 0.35,
  );

  WaterCausticsConfig copyWith({
    bool? isEnabled,
    WaterCausticsMode? mode,
    double? intensity,
    double? scale,
    double? speed,
    double? refractionWarp,
    double? chromaticDispersion,
    double? tintDepth,
  }) {
    return WaterCausticsConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      intensity: intensity ?? this.intensity,
      scale: scale ?? this.scale,
      speed: speed ?? this.speed,
      refractionWarp: refractionWarp ?? this.refractionWarp,
      chromaticDispersion: chromaticDispersion ?? this.chromaticDispersion,
      tintDepth: tintDepth ?? this.tintDepth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'intensity': intensity,
      'scale': scale,
      'speed': speed,
      'refractionWarp': refractionWarp,
      'chromaticDispersion': chromaticDispersion,
      'tintDepth': tintDepth,
    };
  }

  factory WaterCausticsConfig.fromJson(Map<String, dynamic> json) {
    return WaterCausticsConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: WaterCausticsMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => WaterCausticsMode.tropicalPool,
      ),
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.6,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.2,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      refractionWarp: (json['refractionWarp'] as num?)?.toDouble() ?? 0.4,
      chromaticDispersion: (json['chromaticDispersion'] as num?)?.toDouble() ?? 0.35,
      tintDepth: (json['tintDepth'] as num?)?.toDouble() ?? 0.45,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        intensity,
        scale,
        speed,
        refractionWarp,
        chromaticDispersion,
        tintDepth,
      ];
}
