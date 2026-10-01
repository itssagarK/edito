import 'dart:ui';
import 'package:equatable/equatable.dart';

/// Cinematic color tints for vignette rim shading.
enum VignetteTint {
  carbonBlack,
  vintageSepia,
  midnightBlue,
  warmAmber,
  emeraldForest,
  frostWhite;

  String get label {
    switch (this) {
      case VignetteTint.carbonBlack:
        return 'Noir Black';
      case VignetteTint.vintageSepia:
        return 'Vintage Sepia';
      case VignetteTint.midnightBlue:
        return 'Midnight Blue';
      case VignetteTint.warmAmber:
        return 'Warm Amber';
      case VignetteTint.emeraldForest:
        return 'Emerald Forest';
      case VignetteTint.frostWhite:
        return 'Frost White';
    }
  }

  Color get color {
    switch (this) {
      case VignetteTint.carbonBlack:
        return const Color(0xFF000000);
      case VignetteTint.vintageSepia:
        return const Color(0xFF382012);
      case VignetteTint.midnightBlue:
        return const Color(0xFF0A192F);
      case VignetteTint.warmAmber:
        return const Color(0xFF3B1E08);
      case VignetteTint.emeraldForest:
        return const Color(0xFF0C2417);
      case VignetteTint.frostWhite:
        return const Color(0xFFFFFFFF);
    }
  }

  /// Normalized RGB components (0.0 to 1.0)
  List<double> get rgb {
    final c = color;
    return [c.red / 255.0, c.green / 255.0, c.blue / 255.0];
  }
}

/// Curated cinematic vignette & spotlight presets.
enum VignettePreset {
  neutralOff,
  cinematic35mm,
  vintageDrama,
  anamorphicWidescreen,
  dreamyHighKey,
  actionLock,
  goldenHour;

  String get label {
    switch (this) {
      case VignettePreset.neutralOff:
        return 'Off';
      case VignettePreset.cinematic35mm:
        return '35mm Film';
      case VignettePreset.vintageDrama:
        return 'Vintage Drama';
      case VignettePreset.anamorphicWidescreen:
        return 'Anamorphic';
      case VignettePreset.dreamyHighKey:
        return 'Dreamy Light';
      case VignettePreset.actionLock:
        return 'Action Lock';
      case VignettePreset.goldenHour:
        return 'Golden Hour';
    }
  }

  String get description {
    switch (this) {
      case VignettePreset.neutralOff:
        return 'No vignette shading applied';
      case VignettePreset.cinematic35mm:
        return 'Classic subtle edge darkening for authentic film look';
      case VignettePreset.vintageDrama:
        return 'Deep noir corner shadows with warm sepia undertone';
      case VignettePreset.anamorphicWidescreen:
        return '2.39:1 widescreen horizontal falloff mimicking anamorphic lenses';
      case VignettePreset.dreamyHighKey:
        return 'Radiant soft-white spotlight halo for angelic or dream sequences';
      case VignettePreset.actionLock:
        return 'Tight focal clearing region locking focus directly onto subject';
      case VignettePreset.goldenHour:
        return 'Rich warm amber corner vignette capturing magic hour aesthetics';
    }
  }
}

/// CapCut Pro Cinematic Spotlight & Atmospheric Vignette Configuration.
class VignetteConfig extends Equatable {
  final bool isEnabled;
  final double intensity; // -1.0 to 1.0 (positive: dark vignette, negative: white spotlight)
  final double radius; // 0.1 to 1.0 (inner clearing radius)
  final double feather; // 0.05 to 1.0 (softness of edge falloff)
  final double roundness; // -1.0 (horizontal anamorphic oval) to 1.0 (vertical portrait oval), 0.0 is circular
  final double centerX; // -0.8 to 0.8 (focal center horizontal offset from 0.0)
  final double centerY; // -0.8 to 0.8 (focal center vertical offset from 0.0)
  final VignetteTint tint;

  const VignetteConfig({
    this.isEnabled = false,
    this.intensity = 0.45,
    this.radius = 0.60,
    this.feather = 0.50,
    this.roundness = 0.0,
    this.centerX = 0.0,
    this.centerY = 0.0,
    this.tint = VignetteTint.carbonBlack,
  });

  /// Factory for constructing presets directly.
  factory VignetteConfig.fromPreset(VignettePreset preset) {
    switch (preset) {
      case VignettePreset.neutralOff:
        return const VignetteConfig(isEnabled: false, intensity: 0.0);

      case VignettePreset.cinematic35mm:
        return const VignetteConfig(
          isEnabled: true,
          intensity: 0.45,
          radius: 0.60,
          feather: 0.55,
          roundness: 0.0,
          centerX: 0.0,
          centerY: 0.0,
          tint: VignetteTint.carbonBlack,
        );

      case VignettePreset.vintageDrama:
        return const VignetteConfig(
          isEnabled: true,
          intensity: 0.75,
          radius: 0.45,
          feather: 0.40,
          roundness: 0.1,
          centerX: 0.0,
          centerY: 0.0,
          tint: VignetteTint.vintageSepia,
        );

      case VignettePreset.anamorphicWidescreen:
        return const VignetteConfig(
          isEnabled: true,
          intensity: 0.60,
          radius: 0.50,
          feather: 0.65,
          roundness: -0.5,
          centerX: 0.0,
          centerY: 0.0,
          tint: VignetteTint.carbonBlack,
        );

      case VignettePreset.dreamyHighKey:
        return const VignetteConfig(
          isEnabled: true,
          intensity: -0.50,
          radius: 0.65,
          feather: 0.80,
          roundness: 0.0,
          centerX: 0.0,
          centerY: 0.0,
          tint: VignetteTint.frostWhite,
        );

      case VignettePreset.actionLock:
        return const VignetteConfig(
          isEnabled: true,
          intensity: 0.70,
          radius: 0.35,
          feather: 0.30,
          roundness: 0.0,
          centerX: 0.0,
          centerY: 0.0,
          tint: VignetteTint.carbonBlack,
        );

      case VignettePreset.goldenHour:
        return const VignetteConfig(
          isEnabled: true,
          intensity: 0.48,
          radius: 0.55,
          feather: 0.50,
          roundness: 0.0,
          centerX: 0.0,
          centerY: 0.0,
          tint: VignetteTint.warmAmber,
        );
    }
  }

  /// Whether current parameters represent active shading.
  bool get hasActiveVignette => isEnabled && intensity.abs() > 0.01;

  VignetteConfig copyWith({
    bool? isEnabled,
    double? intensity,
    double? radius,
    double? feather,
    double? roundness,
    double? centerX,
    double? centerY,
    VignetteTint? tint,
  }) {
    return VignetteConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      intensity: intensity ?? this.intensity,
      radius: radius ?? this.radius,
      feather: feather ?? this.feather,
      roundness: roundness ?? this.roundness,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      tint: tint ?? this.tint,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'intensity': intensity,
      'radius': radius,
      'feather': feather,
      'roundness': roundness,
      'centerX': centerX,
      'centerY': centerY,
      'tint': tint.name,
    };
  }

  factory VignetteConfig.fromJson(Map<String, dynamic> json) {
    return VignetteConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.45,
      radius: (json['radius'] as num?)?.toDouble() ?? 0.60,
      feather: (json['feather'] as num?)?.toDouble() ?? 0.50,
      roundness: (json['roundness'] as num?)?.toDouble() ?? 0.0,
      centerX: (json['centerX'] as num?)?.toDouble() ?? 0.0,
      centerY: (json['centerY'] as num?)?.toDouble() ?? 0.0,
      tint: VignetteTint.values.firstWhere(
        (t) => t.name == json['tint'],
        orElse: () => VignetteTint.carbonBlack,
      ),
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        intensity,
        radius,
        feather,
        roundness,
        centerX,
        centerY,
        tint,
      ];
}
