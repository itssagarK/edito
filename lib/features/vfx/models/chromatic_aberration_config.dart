import 'package:equatable/equatable.dart';

/// Dispersion pattern mode for RGB chromatic aberration optical glitch.
enum ChromaticAberrationMode {
  horizontalSplit,
  radialDispersion,
  anaglyph3d,
  hologramJitter,
  prismaticAngle;

  String get displayName {
    switch (this) {
      case ChromaticAberrationMode.horizontalSplit:
        return 'Horizontal RGB Split';
      case ChromaticAberrationMode.radialDispersion:
        return 'Lens Prism Dispersion';
      case ChromaticAberrationMode.anaglyph3d:
        return 'Vintage 3D Anaglyph';
      case ChromaticAberrationMode.hologramJitter:
        return 'Hologram Glitch Jitter';
      case ChromaticAberrationMode.prismaticAngle:
        return 'Directional Angle Shift';
    }
  }

  String get description {
    switch (this) {
      case ChromaticAberrationMode.horizontalSplit:
        return 'Linear horizontal displacement separating Red and Blue color channels';
      case ChromaticAberrationMode.radialDispersion:
        return 'Spherical optical lens fringe separating colors more intensely at frame edges';
      case ChromaticAberrationMode.anaglyph3d:
        return 'Stereoscopic Red/Cyan color separation mimicking retro 3D glasses';
      case ChromaticAberrationMode.hologramJitter:
        return 'Dynamic pulsating oscillation simulating a fluctuating holographic transmission';
      case ChromaticAberrationMode.prismaticAngle:
        return 'Arbitrary angle chromatic displacement along diagonal trajectory';
    }
  }
}

/// Configuration for RGB chromatic aberration and holographic glitch displacement.
class ChromaticAberrationConfig extends Equatable {
  final bool isEnabled;
  final ChromaticAberrationMode mode;
  final double shiftAmount; // 0.0 to 1.0 (relative pixel offset, 0 to 30 px)
  final double angleDeg; // 0.0 to 360.0 degrees (displacement vector direction)
  final double falloff; // 0.1 to 1.0 (radial edge dispersion exponent)
  final double jitterSpeed; // 0.5 to 10.0 Hz (temporal oscillation frequency)
  final double colorMix; // 0.2 to 1.0 (color channel intensity blend)

  const ChromaticAberrationConfig({
    this.isEnabled = false,
    this.mode = ChromaticAberrationMode.horizontalSplit,
    this.shiftAmount = 0.35,
    this.angleDeg = 0.0,
    this.falloff = 0.50,
    this.jitterSpeed = 3.0,
    this.colorMix = 0.85,
  });

  bool get isActive => isEnabled && shiftAmount > 0.02;

  ChromaticAberrationConfig copyWith({
    bool? isEnabled,
    ChromaticAberrationMode? mode,
    double? shiftAmount,
    double? angleDeg,
    double? falloff,
    double? jitterSpeed,
    double? colorMix,
  }) {
    return ChromaticAberrationConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      shiftAmount: shiftAmount ?? this.shiftAmount,
      angleDeg: angleDeg ?? this.angleDeg,
      falloff: falloff ?? this.falloff,
      jitterSpeed: jitterSpeed ?? this.jitterSpeed,
      colorMix: colorMix ?? this.colorMix,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'shiftAmount': shiftAmount,
      'angleDeg': angleDeg,
      'falloff': falloff,
      'jitterSpeed': jitterSpeed,
      'colorMix': colorMix,
    };
  }

  factory ChromaticAberrationConfig.fromJson(Map<String, dynamic> json) {
    ChromaticAberrationMode parsedMode = ChromaticAberrationMode.horizontalSplit;
    if (json['mode'] != null) {
      try {
        parsedMode = ChromaticAberrationMode.values.byName(json['mode'] as String);
      } catch (_) {
        parsedMode = ChromaticAberrationMode.horizontalSplit;
      }
    }

    return ChromaticAberrationConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: parsedMode,
      shiftAmount: (json['shiftAmount'] as num?)?.toDouble() ?? 0.35,
      angleDeg: (json['angleDeg'] as num?)?.toDouble() ?? 0.0,
      falloff: (json['falloff'] as num?)?.toDouble() ?? 0.50,
      jitterSpeed: (json['jitterSpeed'] as num?)?.toDouble() ?? 3.0,
      colorMix: (json['colorMix'] as num?)?.toDouble() ?? 0.85,
    );
  }

  // Curated presets
  static const ChromaticAberrationConfig cyberGlitch = ChromaticAberrationConfig(
    isEnabled: true,
    mode: ChromaticAberrationMode.horizontalSplit,
    shiftAmount: 0.65,
    angleDeg: 0.0,
    falloff: 0.50,
    jitterSpeed: 5.0,
    colorMix: 0.95,
  );

  static const ChromaticAberrationConfig lensPrism = ChromaticAberrationConfig(
    isEnabled: true,
    mode: ChromaticAberrationMode.radialDispersion,
    shiftAmount: 0.40,
    angleDeg: 0.0,
    falloff: 0.70,
    jitterSpeed: 2.0,
    colorMix: 0.85,
  );

  static const ChromaticAberrationConfig vintageAnaglyph = ChromaticAberrationConfig(
    isEnabled: true,
    mode: ChromaticAberrationMode.anaglyph3d,
    shiftAmount: 0.50,
    angleDeg: 0.0,
    falloff: 0.50,
    jitterSpeed: 1.0,
    colorMix: 0.90,
  );

  static const ChromaticAberrationConfig hologramShift = ChromaticAberrationConfig(
    isEnabled: true,
    mode: ChromaticAberrationMode.hologramJitter,
    shiftAmount: 0.55,
    angleDeg: 45.0,
    falloff: 0.50,
    jitterSpeed: 4.0,
    colorMix: 0.90,
  );

  static const ChromaticAberrationConfig radialWarp = ChromaticAberrationConfig(
    isEnabled: true,
    mode: ChromaticAberrationMode.radialDispersion,
    shiftAmount: 0.85,
    angleDeg: 0.0,
    falloff: 0.35,
    jitterSpeed: 2.5,
    colorMix: 1.0,
  );

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        shiftAmount,
        angleDeg,
        falloff,
        jitterSpeed,
        colorMix,
      ];
}
