import 'package:equatable/equatable.dart';

/// CapCut Pro AI Video Relight Mode
enum RelightMode {
  none,
  facialSpotlight,
  studioSoftbox,
  rimBacklight,
  ambientRingLight,
  goldenSunbeam,
  cyberNeonDual,
  vintageWarmTungsten,
  custom,
}

extension RelightModeExt on RelightMode {
  String get label {
    switch (this) {
      case RelightMode.none:
        return 'Off';
      case RelightMode.facialSpotlight:
        return 'Face Spotlight';
      case RelightMode.studioSoftbox:
        return 'Studio Softbox';
      case RelightMode.rimBacklight:
        return 'Rim Backlight';
      case RelightMode.ambientRingLight:
        return 'Ring Light';
      case RelightMode.goldenSunbeam:
        return 'Golden Sunbeam';
      case RelightMode.cyberNeonDual:
        return 'Cyber Neon Dual';
      case RelightMode.vintageWarmTungsten:
        return 'Warm Tungsten';
      case RelightMode.custom:
        return 'Custom Light';
    }
  }

  String get description {
    switch (this) {
      case RelightMode.none:
        return 'Original un-lit footage';
      case RelightMode.facialSpotlight:
        return 'Focused soft keylight illuminating the face with natural falloff';
      case RelightMode.studioSoftbox:
        return 'Broad diffused directional light simulating studio softbox';
      case RelightMode.rimBacklight:
        return 'Dramatic edge highlight creating subject separation from background';
      case RelightMode.ambientRingLight:
        return 'Beauty vlog style circular front illumination with soft fill';
      case RelightMode.goldenSunbeam:
        return 'Warm directional golden sunlight casting radiant beam across scene';
      case RelightMode.cyberNeonDual:
        return 'Futuristic dual-tone key (cyan) and rim (magenta) lighting';
      case RelightMode.vintageWarmTungsten:
        return 'Cozy 2700K incandescent amber glow with gentle shadows';
      case RelightMode.custom:
        return 'Fully customizable 2D light position, radius, and color spectrum';
    }
  }

  /// Default color value (32-bit ARGB)
  int get defaultColor {
    switch (this) {
      case RelightMode.none:
        return 0x00000000;
      case RelightMode.facialSpotlight:
        return 0xFFFFE8D6; // Soft warm white
      case RelightMode.studioSoftbox:
        return 0xFFFFF5EB; // Clean 5600K studio daylight
      case RelightMode.rimBacklight:
        return 0xFFE0F7FA; // Crisp cool rim
      case RelightMode.ambientRingLight:
        return 0xFFFFF0F5; // Beauty rose-tinted neutral
      case RelightMode.goldenSunbeam:
        return 0xFFFFB347; // Rich golden amber
      case RelightMode.cyberNeonDual:
        return 0xFF00CEC9; // Electric cyan key
      case RelightMode.vintageWarmTungsten:
        return 0xFFFF9F43; // Deep warm tungsten
      case RelightMode.custom:
        return 0xFFFFEAA7;
    }
  }

  /// Secondary color for dual-tone setups (e.g. cyber neon rim)
  int? get defaultSecondaryColor {
    switch (this) {
      case RelightMode.cyberNeonDual:
        return 0xFFFF007F; // Hot magenta rim
      default:
        return null;
    }
  }

  /// Default normalized X position (-1.0 to 1.0)
  double get defaultX {
    switch (this) {
      case RelightMode.studioSoftbox:
        return -0.45; // Key light slightly left
      case RelightMode.rimBacklight:
        return 0.55; // Rim light upper right
      case RelightMode.goldenSunbeam:
        return -0.60; // Sunbeam entering from upper left
      case RelightMode.cyberNeonDual:
        return -0.50; // Cyan key left
      default:
        return 0.0; // Centered
    }
  }

  /// Default normalized Y position (-1.0 to 1.0)
  double get defaultY {
    switch (this) {
      case RelightMode.rimBacklight:
        return -0.55; // Upper back
      case RelightMode.goldenSunbeam:
        return -0.65; // High sun angle
      case RelightMode.facialSpotlight:
      case RelightMode.studioSoftbox:
      case RelightMode.ambientRingLight:
        return -0.20; // Upper torso / face level
      default:
        return -0.20;
    }
  }
}

/// CapCut Pro AI Video Relight & Virtual Studio Lighting Configuration
class RelightConfig extends Equatable {
  final bool isEnabled;
  final RelightMode mode;
  final double intensity; // 0.0 to 1.0 (default: 0.70)
  final double lightX; // Normalized horizontal position (-1.0 to 1.0, default: 0.0)
  final double lightY; // Normalized vertical position (-1.0 to 1.0, default: -0.2)
  final double radius; // Light radius/spread (0.1 to 2.0, default: 0.70)
  final double softness; // Edge falloff feathering (0.1 to 1.0, default: 0.85)
  final int colorValue; // Primary light color (32-bit ARGB)
  final int? secondaryColorValue; // Secondary light color for dual setups
  final double distance; // Virtual 3D depth distance (0.0 to 1.0, default: 0.50)

  const RelightConfig({
    this.isEnabled = false,
    this.mode = RelightMode.none,
    this.intensity = 0.70,
    this.lightX = 0.0,
    this.lightY = -0.20,
    this.radius = 0.70,
    this.softness = 0.85,
    this.colorValue = 0xFFFFE8D6,
    this.secondaryColorValue,
    this.distance = 0.50,
  });

  /// Factory constructor to immediately create an active preset configuration
  factory RelightConfig.fromMode(RelightMode mode, {double intensity = 0.70}) {
    if (mode == RelightMode.none) {
      return const RelightConfig();
    }
    return RelightConfig(
      isEnabled: true,
      mode: mode,
      intensity: intensity,
      lightX: mode.defaultX,
      lightY: mode.defaultY,
      colorValue: mode.defaultColor,
      secondaryColorValue: mode.defaultSecondaryColor,
    );
  }

  /// Real-time HUD status badge text
  String get badge {
    if (!isEnabled || mode == RelightMode.none || intensity <= 0.0) return '';
    final percent = (intensity * 100).toInt();
    return 'RELIGHT: ${mode.label.toUpperCase()} $percent%';
  }

  RelightConfig copyWith({
    bool? isEnabled,
    RelightMode? mode,
    double? intensity,
    double? lightX,
    double? lightY,
    double? radius,
    double? softness,
    int? colorValue,
    int? secondaryColorValue,
    double? distance,
  }) {
    return RelightConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      intensity: intensity ?? this.intensity,
      lightX: lightX ?? this.lightX,
      lightY: lightY ?? this.lightY,
      radius: radius ?? this.radius,
      softness: softness ?? this.softness,
      colorValue: colorValue ?? this.colorValue,
      secondaryColorValue: secondaryColorValue ?? this.secondaryColorValue,
      distance: distance ?? this.distance,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'mode': mode.name,
        'intensity': intensity,
        'lightX': lightX,
        'lightY': lightY,
        'radius': radius,
        'softness': softness,
        'colorValue': colorValue,
        'secondaryColorValue': secondaryColorValue,
        'distance': distance,
      };

  factory RelightConfig.fromJson(Map<String, dynamic> json) {
    RelightMode modeVal = RelightMode.none;
    if (json['mode'] != null) {
      modeVal = RelightMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => RelightMode.none,
      );
    }

    return RelightConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: modeVal,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.70,
      lightX: (json['lightX'] as num?)?.toDouble() ?? 0.0,
      lightY: (json['lightY'] as num?)?.toDouble() ?? -0.20,
      radius: (json['radius'] as num?)?.toDouble() ?? 0.70,
      softness: (json['softness'] as num?)?.toDouble() ?? 0.85,
      colorValue: json['colorValue'] as int? ?? 0xFFFFE8D6,
      secondaryColorValue: json['secondaryColorValue'] as int?,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.50,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        intensity,
        lightX,
        lightY,
        radius,
        softness,
        colorValue,
        secondaryColorValue,
        distance,
      ];
}
