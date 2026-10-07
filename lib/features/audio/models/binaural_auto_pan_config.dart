import 'package:equatable/equatable.dart';

/// Modes of 3D binaural stereo auto-pan and Doppler pitch sweeping.
enum BinauralAutoPanMode {
  circular3DOrbit,
  pendulumSwing,
  dopplerFlyby,
  chaoticVortex,
  subtleStereoSpread,
}

extension BinauralAutoPanModeExtension on BinauralAutoPanMode {
  String get label {
    switch (this) {
      case BinauralAutoPanMode.circular3DOrbit:
        return '3D Orbit';
      case BinauralAutoPanMode.pendulumSwing:
        return 'Pendulum Swing';
      case BinauralAutoPanMode.dopplerFlyby:
        return 'Doppler Flyby';
      case BinauralAutoPanMode.chaoticVortex:
        return 'Chaotic Vortex';
      case BinauralAutoPanMode.subtleStereoSpread:
        return 'Subtle Spread';
    }
  }

  String get description {
    switch (this) {
      case BinauralAutoPanMode.circular3DOrbit:
        return 'Continuous 360° circular trajectory orbiting around the listener’s head';
      case BinauralAutoPanMode.pendulumSwing:
        return 'Wide Left-to-Right stereophonic pendulum oscillation';
      case BinauralAutoPanMode.dopplerFlyby:
        return 'Rapid acoustic approach and flyby with physical Doppler pitch shift';
      case BinauralAutoPanMode.chaoticVortex:
        return 'Erratic high-speed multi-axis spatial vortex rotation';
      case BinauralAutoPanMode.subtleStereoSpread:
        return 'Gentle binaural soundstage expansion with slow breathing motion';
    }
  }

  String get iconAsset {
    switch (this) {
      case BinauralAutoPanMode.circular3DOrbit:
        return 'surround_sound';
      case BinauralAutoPanMode.pendulumSwing:
        return 'compare_arrows';
      case BinauralAutoPanMode.dopplerFlyby:
        return 'air';
      case BinauralAutoPanMode.chaoticVortex:
        return 'cyclone';
      case BinauralAutoPanMode.subtleStereoSpread:
        return 'headphones';
    }
  }
}

/// Configuration for 3D binaural auto-pan rotation and Doppler swell effects.
class BinauralAutoPanConfig extends Equatable {
  final bool isEnabled;
  final BinauralAutoPanMode mode;
  final double rateHz; // 0.05 to 4.0 Hz (rotation speed)
  final double depth; // 0.0 to 1.0 (pan width / stereo depth)
  final double dopplerIntensity; // 0.0 to 1.0 (pitch modulation depth)
  final double elevation; // -1.0 to 1.0 (3D vertical elevation)
  final double stereoSpread; // 0.0 to 2.0 (binaural soundstage widening)

  const BinauralAutoPanConfig({
    this.isEnabled = false,
    this.mode = BinauralAutoPanMode.circular3DOrbit,
    this.rateHz = 0.35,
    this.depth = 0.85,
    this.dopplerIntensity = 0.25,
    this.elevation = 0.0,
    this.stereoSpread = 1.3,
  });

  bool get isActive => isEnabled && depth > 0.0;

  static const BinauralAutoPanConfig defaultDisabled = BinauralAutoPanConfig();

  // Curated 5 cinematic presets
  static const BinauralAutoPanConfig presetHeadphoneOrbit = BinauralAutoPanConfig(
    isEnabled: true,
    mode: BinauralAutoPanMode.circular3DOrbit,
    rateHz: 0.35,
    depth: 0.90,
    dopplerIntensity: 0.20,
    elevation: 0.0,
    stereoSpread: 1.4,
  );

  static const BinauralAutoPanConfig presetMetronomeSwing = BinauralAutoPanConfig(
    isEnabled: true,
    mode: BinauralAutoPanMode.pendulumSwing,
    rateHz: 0.60,
    depth: 0.85,
    dopplerIntensity: 0.10,
    elevation: 0.0,
    stereoSpread: 1.2,
  );

  static const BinauralAutoPanConfig presetJetDopplerPass = BinauralAutoPanConfig(
    isEnabled: true,
    mode: BinauralAutoPanMode.dopplerFlyby,
    rateHz: 0.25,
    depth: 1.0,
    dopplerIntensity: 0.70,
    elevation: 0.3,
    stereoSpread: 1.6,
  );

  static const BinauralAutoPanConfig presetCrazyVortex = BinauralAutoPanConfig(
    isEnabled: true,
    mode: BinauralAutoPanMode.chaoticVortex,
    rateHz: 1.20,
    depth: 0.95,
    dopplerIntensity: 0.50,
    elevation: 0.5,
    stereoSpread: 1.5,
  );

  static const BinauralAutoPanConfig presetAmbientSpatial = BinauralAutoPanConfig(
    isEnabled: true,
    mode: BinauralAutoPanMode.subtleStereoSpread,
    rateHz: 0.10,
    depth: 0.45,
    dopplerIntensity: 0.0,
    elevation: 0.0,
    stereoSpread: 1.3,
  );

  BinauralAutoPanConfig copyWith({
    bool? isEnabled,
    BinauralAutoPanMode? mode,
    double? rateHz,
    double? depth,
    double? dopplerIntensity,
    double? elevation,
    double? stereoSpread,
  }) {
    return BinauralAutoPanConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      rateHz: rateHz ?? this.rateHz,
      depth: depth ?? this.depth,
      dopplerIntensity: dopplerIntensity ?? this.dopplerIntensity,
      elevation: elevation ?? this.elevation,
      stereoSpread: stereoSpread ?? this.stereoSpread,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'rateHz': rateHz,
      'depth': depth,
      'dopplerIntensity': dopplerIntensity,
      'elevation': elevation,
      'stereoSpread': stereoSpread,
    };
  }

  factory BinauralAutoPanConfig.fromJson(Map<String, dynamic> json) {
    return BinauralAutoPanConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: BinauralAutoPanMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => BinauralAutoPanMode.circular3DOrbit,
      ),
      rateHz: (json['rateHz'] as num?)?.toDouble() ?? 0.35,
      depth: (json['depth'] as num?)?.toDouble() ?? 0.85,
      dopplerIntensity: (json['dopplerIntensity'] as num?)?.toDouble() ?? 0.25,
      elevation: (json['elevation'] as num?)?.toDouble() ?? 0.0,
      stereoSpread: (json['stereoSpread'] as num?)?.toDouble() ?? 1.3,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        rateHz,
        depth,
        dopplerIntensity,
        elevation,
        stereoSpread,
      ];
}
