import 'package:equatable/equatable.dart';

/// Night vision optic and thermal imaging modes.
enum NightVisionMode {
  phosphorGreen,
  thermalFlirIronbow,
  thermalRainbow,
  whiteHot,
  blackHot;

  String get displayName {
    switch (this) {
      case NightVisionMode.phosphorGreen:
        return 'Gen-3 Phosphor Green';
      case NightVisionMode.thermalFlirIronbow:
        return 'FLIR Thermal Ironbow';
      case NightVisionMode.thermalRainbow:
        return 'Thermal Rainbow Spectrum';
      case NightVisionMode.whiteHot:
        return 'Tactical White-Hot';
      case NightVisionMode.blackHot:
        return 'Tactical Black-Hot';
    }
  }

  String get description {
    switch (this) {
      case NightVisionMode.phosphorGreen:
        return 'High-gain military NVG monochrome green tube luminescence';
      case NightVisionMode.thermalFlirIronbow:
        return 'Standard false-color thermal heatmap: purple, orange, yellow, white';
      case NightVisionMode.thermalRainbow:
        return 'Multi-band thermal gradient: deep blue, cyan, green, yellow, red';
      case NightVisionMode.whiteHot:
        return 'Monochrome infrared where warmest heat sources radiate bright white';
      case NightVisionMode.blackHot:
        return 'Inverted monochrome infrared where warmest heat sources appear black';
    }
  }
}

/// Military optic reticle and targeting overlay.
enum NightVisionReticle {
  rangefinderOsd,
  militaryCrosshair,
  tacticalGrid,
  none;

  String get displayName {
    switch (this) {
      case NightVisionReticle.rangefinderOsd:
        return 'Military Rangefinder HUD';
      case NightVisionReticle.militaryCrosshair:
        return 'Mil-Dot Crosshair';
      case NightVisionReticle.tacticalGrid:
        return 'Tactical Targeting Grid';
      case NightVisionReticle.none:
        return 'Clean Scope (No Reticle)';
    }
  }
}

/// Configuration for military night vision and thermal infrared imaging VFX.
class NightVisionConfig extends Equatable {
  final bool isEnabled;
  final NightVisionMode mode;
  final NightVisionReticle reticle;
  final double gain; // 0.5 to 3.0 (luminance amplification multiplier)
  final double noise; // 0.0 to 1.0 (photocathode sensor noise grain)
  final double vignette; // 0.0 to 1.0 (circular ocular scope falloff)
  final bool scanlines; // CRT sensor scanlines

  const NightVisionConfig({
    this.isEnabled = false,
    this.mode = NightVisionMode.phosphorGreen,
    this.reticle = NightVisionReticle.rangefinderOsd,
    this.gain = 1.4,
    this.noise = 0.35,
    this.vignette = 0.65,
    this.scanlines = true,
  });

  bool get isActive => isEnabled;

  // Curated presets
  static const NightVisionConfig specOpsGreen = NightVisionConfig(
    isEnabled: true,
    mode: NightVisionMode.phosphorGreen,
    reticle: NightVisionReticle.rangefinderOsd,
    gain: 1.45,
    noise: 0.40,
    vignette: 0.70,
    scanlines: true,
  );

  static const NightVisionConfig predatorThermal = NightVisionConfig(
    isEnabled: true,
    mode: NightVisionMode.thermalRainbow,
    reticle: NightVisionReticle.tacticalGrid,
    gain: 1.30,
    noise: 0.20,
    vignette: 0.50,
    scanlines: false,
  );

  static const NightVisionConfig flirIronbowThermal = NightVisionConfig(
    isEnabled: true,
    mode: NightVisionMode.thermalFlirIronbow,
    reticle: NightVisionReticle.rangefinderOsd,
    gain: 1.25,
    noise: 0.15,
    vignette: 0.60,
    scanlines: false,
  );

  static const NightVisionConfig covertWhiteHot = NightVisionConfig(
    isEnabled: true,
    mode: NightVisionMode.whiteHot,
    reticle: NightVisionReticle.militaryCrosshair,
    gain: 1.50,
    noise: 0.30,
    vignette: 0.65,
    scanlines: true,
  );

  static const NightVisionConfig sniperBlackHot = NightVisionConfig(
    isEnabled: true,
    mode: NightVisionMode.blackHot,
    reticle: NightVisionReticle.militaryCrosshair,
    gain: 1.40,
    noise: 0.30,
    vignette: 0.75,
    scanlines: false,
  );

  NightVisionConfig copyWith({
    bool? isEnabled,
    NightVisionMode? mode,
    NightVisionReticle? reticle,
    double? gain,
    double? noise,
    double? vignette,
    bool? scanlines,
  }) {
    return NightVisionConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      reticle: reticle ?? this.reticle,
      gain: gain ?? this.gain,
      noise: noise ?? this.noise,
      vignette: vignette ?? this.vignette,
      scanlines: scanlines ?? this.scanlines,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'reticle': reticle.name,
      'gain': gain,
      'noise': noise,
      'vignette': vignette,
      'scanlines': scanlines,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory NightVisionConfig.fromMap(Map<String, dynamic> map) {
    return NightVisionConfig(
      isEnabled: map['isEnabled'] as bool? ?? false,
      mode: NightVisionMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => NightVisionMode.phosphorGreen,
      ),
      reticle: NightVisionReticle.values.firstWhere(
        (e) => e.name == map['reticle'],
        orElse: () => NightVisionReticle.rangefinderOsd,
      ),
      gain: (map['gain'] as num?)?.toDouble() ?? 1.4,
      noise: (map['noise'] as num?)?.toDouble() ?? 0.35,
      vignette: (map['vignette'] as num?)?.toDouble() ?? 0.65,
      scanlines: map['scanlines'] as bool? ?? true,
    );
  }

  factory NightVisionConfig.fromJson(Map<String, dynamic> json) =>
      NightVisionConfig.fromMap(json);

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        reticle,
        gain,
        noise,
        vignette,
        scanlines,
      ];
}
