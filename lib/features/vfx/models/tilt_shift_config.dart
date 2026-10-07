import 'package:equatable/equatable.dart';

/// Focal geometry mode for tilt-shift miniature depth-of-field simulation.
enum TiltShiftMode {
  linearBar,
  radialCircle,
  miniatureModel,
  cinematicMacro;

  String get displayName {
    switch (this) {
      case TiltShiftMode.linearBar:
        return 'Linear Focal Strip';
      case TiltShiftMode.radialCircle:
        return 'Radial Focus Ellipse';
      case TiltShiftMode.miniatureModel:
        return 'Miniature Diorama';
      case TiltShiftMode.cinematicMacro:
        return 'Cinematic Macro DoF';
    }
  }

  String get description {
    switch (this) {
      case TiltShiftMode.linearBar:
        return 'Linear focal plane strip with progressive top & bottom blur falloff';
      case TiltShiftMode.radialCircle:
        return 'Circular spotlight focus area surrounded by omnidirectional blur';
      case TiltShiftMode.miniatureModel:
        return 'Exaggerated saturation, contrast, and narrow focus simulating a toy model';
      case TiltShiftMode.cinematicMacro:
        return 'Ultra-shallow depth of field highlighting micro-details with deep bokeh';
    }
  }
}

/// Configuration for tilt-shift diorama miniature depth-of-field simulation.
class TiltShiftConfig extends Equatable {
  final bool isEnabled;
  final TiltShiftMode mode;
  final double focusPosition; // 0.0 to 1.0 (Y position or center distance)
  final double focusBandwidth; // 0.05 to 0.80 (width of the sharp in-focus region)
  final double blurRadius; // 1.0 to 30.0 px (defocus blur intensity)
  final double feather; // 0.05 to 0.50 (gradient transition smoothness)
  final double saturationBoost; // 1.0 to 2.2 (toy diorama vivid color multiplier)
  final double angleDeg; // -90.0 to 90.0 degrees (focal plane tilt angle)

  const TiltShiftConfig({
    this.isEnabled = false,
    this.mode = TiltShiftMode.linearBar,
    this.focusPosition = 0.50,
    this.focusBandwidth = 0.25,
    this.blurRadius = 12.0,
    this.feather = 0.20,
    this.saturationBoost = 1.35,
    this.angleDeg = 0.0,
  });

  bool get isActive => isEnabled && blurRadius > 0.5;

  // Curated Presets
  static const TiltShiftConfig toyTownMiniature = TiltShiftConfig(
    isEnabled: true,
    mode: TiltShiftMode.miniatureModel,
    focusPosition: 0.52,
    focusBandwidth: 0.20,
    blurRadius: 16.0,
    feather: 0.18,
    saturationBoost: 1.55,
    angleDeg: 0.0,
  );

  static const TiltShiftConfig dioramaHorizontal = TiltShiftConfig(
    isEnabled: true,
    mode: TiltShiftMode.linearBar,
    focusPosition: 0.50,
    focusBandwidth: 0.28,
    blurRadius: 12.0,
    feather: 0.22,
    saturationBoost: 1.30,
    angleDeg: 0.0,
  );

  static const TiltShiftConfig portraitRadialFocus = TiltShiftConfig(
    isEnabled: true,
    mode: TiltShiftMode.radialCircle,
    focusPosition: 0.45,
    focusBandwidth: 0.35,
    blurRadius: 14.0,
    feather: 0.25,
    saturationBoost: 1.10,
    angleDeg: 0.0,
  );

  static const TiltShiftConfig macroShallowDof = TiltShiftConfig(
    isEnabled: true,
    mode: TiltShiftMode.cinematicMacro,
    focusPosition: 0.50,
    focusBandwidth: 0.15,
    blurRadius: 22.0,
    feather: 0.15,
    saturationBoost: 1.20,
    angleDeg: 0.0,
  );

  static const TiltShiftConfig architecturalTilt = TiltShiftConfig(
    isEnabled: true,
    mode: TiltShiftMode.linearBar,
    focusPosition: 0.40,
    focusBandwidth: 0.30,
    blurRadius: 10.0,
    feather: 0.20,
    saturationBoost: 1.15,
    angleDeg: 15.0,
  );

  TiltShiftConfig copyWith({
    bool? isEnabled,
    TiltShiftMode? mode,
    double? focusPosition,
    double? focusBandwidth,
    double? blurRadius,
    double? feather,
    double? saturationBoost,
    double? angleDeg,
  }) {
    return TiltShiftConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      focusPosition: focusPosition ?? this.focusPosition,
      focusBandwidth: focusBandwidth ?? this.focusBandwidth,
      blurRadius: blurRadius ?? this.blurRadius,
      feather: feather ?? this.feather,
      saturationBoost: saturationBoost ?? this.saturationBoost,
      angleDeg: angleDeg ?? this.angleDeg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'focusPosition': focusPosition,
      'focusBandwidth': focusBandwidth,
      'blurRadius': blurRadius,
      'feather': feather,
      'saturationBoost': saturationBoost,
      'angleDeg': angleDeg,
    };
  }

  factory TiltShiftConfig.fromJson(Map<String, dynamic> json) {
    return TiltShiftConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: TiltShiftMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => TiltShiftMode.linearBar,
      ),
      focusPosition: (json['focusPosition'] as num?)?.toDouble() ?? 0.50,
      focusBandwidth: (json['focusBandwidth'] as num?)?.toDouble() ?? 0.25,
      blurRadius: (json['blurRadius'] as num?)?.toDouble() ?? 12.0,
      feather: (json['feather'] as num?)?.toDouble() ?? 0.20,
      saturationBoost: (json['saturationBoost'] as num?)?.toDouble() ?? 1.35,
      angleDeg: (json['angleDeg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        focusPosition,
        focusBandwidth,
        blurRadius,
        feather,
        saturationBoost,
        angleDeg,
      ];
}
