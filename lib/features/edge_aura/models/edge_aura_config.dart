import 'package:equatable/equatable.dart';

/// CapCut Pro Video Glow & Edge Aura Preset Styles
enum EdgeGlowStyle {
  none,
  cyberCyan,
  synthwavePink,
  solarGold,
  radioactiveGreen,
  plasmaPurple,
  infernoFlame,
  rgbGhost,
  custom,
}

/// Category grouping for style browsing tabs
enum EdgeAuraCategory {
  all,
  cyber,
  energy,
  custom,
}

extension EdgeAuraCategoryExt on EdgeAuraCategory {
  String get label {
    switch (this) {
      case EdgeAuraCategory.all:
        return 'All';
      case EdgeAuraCategory.cyber:
        return 'Cyber & Sci-Fi';
      case EdgeAuraCategory.energy:
        return 'Radiant Energy';
      case EdgeAuraCategory.custom:
        return 'Custom';
    }
  }
}

extension EdgeGlowStyleExt on EdgeGlowStyle {
  String get label {
    switch (this) {
      case EdgeGlowStyle.none:
        return 'None';
      case EdgeGlowStyle.cyberCyan:
        return 'Cyber Cyan';
      case EdgeGlowStyle.synthwavePink:
        return 'Synthwave Pink';
      case EdgeGlowStyle.solarGold:
        return 'Solar Gold';
      case EdgeGlowStyle.radioactiveGreen:
        return 'Radioactive';
      case EdgeGlowStyle.plasmaPurple:
        return 'Plasma Purple';
      case EdgeGlowStyle.infernoFlame:
        return 'Inferno Flame';
      case EdgeGlowStyle.rgbGhost:
        return 'RGB Ghost';
      case EdgeGlowStyle.custom:
        return 'Custom Aura';
    }
  }

  String get description {
    switch (this) {
      case EdgeGlowStyle.none:
        return 'Standard clean video without edge glow';
      case EdgeGlowStyle.cyberCyan:
        return 'High-voltage electric cyan silhouette aura';
      case EdgeGlowStyle.synthwavePink:
        return 'Retro 80s neon magenta laser contour bloom';
      case EdgeGlowStyle.solarGold:
        return 'Warm celestial golden halo with soft radiance';
      case EdgeGlowStyle.radioactiveGreen:
        return 'Toxic neon green electric energy perimeter';
      case EdgeGlowStyle.plasmaPurple:
        return 'Cosmic ultraviolet mystic dimensional aura';
      case EdgeGlowStyle.infernoFlame:
        return 'Blazing orange-red thermal ember outline';
      case EdgeGlowStyle.rgbGhost:
        return 'Chromatic aberration RGB fringe edge contour';
      case EdgeGlowStyle.custom:
        return 'Fully user-configurable color, radius, and threshold';
    }
  }

  EdgeAuraCategory get category {
    switch (this) {
      case EdgeGlowStyle.cyberCyan:
      case EdgeGlowStyle.plasmaPurple:
      case EdgeGlowStyle.rgbGhost:
        return EdgeAuraCategory.cyber;
      case EdgeGlowStyle.synthwavePink:
      case EdgeGlowStyle.solarGold:
      case EdgeGlowStyle.radioactiveGreen:
      case EdgeGlowStyle.infernoFlame:
        return EdgeAuraCategory.energy;
      case EdgeGlowStyle.custom:
        return EdgeAuraCategory.custom;
      case EdgeGlowStyle.none:
        return EdgeAuraCategory.all;
    }
  }

  int get defaultColorValue {
    switch (this) {
      case EdgeGlowStyle.cyberCyan:
        return 0xFF00F0FF; // Electric Cyan
      case EdgeGlowStyle.synthwavePink:
        return 0xFFFF007F; // Hot Neon Pink
      case EdgeGlowStyle.solarGold:
        return 0xFFFFD700; // Radiant Gold
      case EdgeGlowStyle.radioactiveGreen:
        return 0xFF39FF14; // Radioactive Neon Green
      case EdgeGlowStyle.plasmaPurple:
        return 0xFFBD00FF; // Ultraviolet Plasma
      case EdgeGlowStyle.infernoFlame:
        return 0xFFFF3D00; // Flame Orange Red
      case EdgeGlowStyle.rgbGhost:
        return 0xFF00FFCC; // Chromatic base
      case EdgeGlowStyle.custom:
      case EdgeGlowStyle.none:
        return 0xFF00F0FF;
    }
  }

  double get defaultIntensity {
    switch (this) {
      case EdgeGlowStyle.none:
        return 0.0;
      case EdgeGlowStyle.rgbGhost:
        return 1.25;
      case EdgeGlowStyle.solarGold:
        return 0.9;
      default:
        return 1.0;
    }
  }

  double get defaultRadius {
    switch (this) {
      case EdgeGlowStyle.solarGold:
        return 22.0;
      case EdgeGlowStyle.infernoFlame:
        return 18.0;
      case EdgeGlowStyle.rgbGhost:
        return 8.0;
      default:
        return 15.0;
    }
  }

  double get defaultThreshold {
    switch (this) {
      case EdgeGlowStyle.solarGold:
        return 0.20;
      case EdgeGlowStyle.rgbGhost:
        return 0.15;
      default:
        return 0.25;
    }
  }

  double get defaultPulseSpeed {
    switch (this) {
      case EdgeGlowStyle.radioactiveGreen:
        return 1.5;
      case EdgeGlowStyle.infernoFlame:
        return 1.0;
      default:
        return 0.0;
    }
  }
}

/// Blending mode for edge aura compositing
enum GlowBlendMode {
  screen,
  addition,
  overlay,
}

extension GlowBlendModeExt on GlowBlendMode {
  String get label {
    switch (this) {
      case GlowBlendMode.screen:
        return 'Screen (Soft)';
      case GlowBlendMode.addition:
        return 'Add (Intense)';
      case GlowBlendMode.overlay:
        return 'Overlay (Punchy)';
    }
  }

  String get ffmpegBlendMode {
    switch (this) {
      case GlowBlendMode.screen:
        return 'screen';
      case GlowBlendMode.addition:
        return 'addition';
      case GlowBlendMode.overlay:
        return 'overlay';
    }
  }
}

/// CapCut Pro AI Video Glow & Edge Aura Studio Configuration
class EdgeAuraConfig extends Equatable {
  final bool isEnabled;
  final EdgeGlowStyle style;
  final double intensity; // 0.0 to 2.0
  final double radius; // 1.0 to 50.0 px
  final double threshold; // 0.05 to 0.95 edge detection sensitivity
  final double pulseSpeed; // 0.0 to 5.0 Hz (0.0 = static)
  final int colorValue; // ARGB 32-bit hex
  final GlowBlendMode blendMode;
  final bool preserveSubject;

  const EdgeAuraConfig({
    this.isEnabled = false,
    this.style = EdgeGlowStyle.none,
    this.intensity = 1.0,
    this.radius = 15.0,
    this.threshold = 0.25,
    this.pulseSpeed = 0.0,
    this.colorValue = 0xFF00F0FF,
    this.blendMode = GlowBlendMode.screen,
    this.preserveSubject = true,
  });

  /// Factory preset constructor for one-tap styling
  factory EdgeAuraConfig.preset(EdgeGlowStyle style) {
    if (style == EdgeGlowStyle.none) {
      return const EdgeAuraConfig();
    }

    return EdgeAuraConfig(
      isEnabled: true,
      style: style,
      intensity: style.defaultIntensity,
      radius: style.defaultRadius,
      threshold: style.defaultThreshold,
      pulseSpeed: style.defaultPulseSpeed,
      colorValue: style.defaultColorValue,
      blendMode: style == EdgeGlowStyle.synthwavePink
          ? GlowBlendMode.addition
          : GlowBlendMode.screen,
      preserveSubject: true,
    );
  }

  /// HUD overlay status badge
  String get badge {
    if (!isEnabled || style == EdgeGlowStyle.none) return '';
    return 'AURA: ${style.label.toUpperCase()}';
  }

  EdgeAuraConfig copyWith({
    bool? isEnabled,
    EdgeGlowStyle? style,
    double? intensity,
    double? radius,
    double? threshold,
    double? pulseSpeed,
    int? colorValue,
    GlowBlendMode? blendMode,
    bool? preserveSubject,
  }) {
    return EdgeAuraConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      style: style ?? this.style,
      intensity: intensity ?? this.intensity,
      radius: radius ?? this.radius,
      threshold: threshold ?? this.threshold,
      pulseSpeed: pulseSpeed ?? this.pulseSpeed,
      colorValue: colorValue ?? this.colorValue,
      blendMode: blendMode ?? this.blendMode,
      preserveSubject: preserveSubject ?? this.preserveSubject,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'style': style.index,
      'intensity': intensity,
      'radius': radius,
      'threshold': threshold,
      'pulseSpeed': pulseSpeed,
      'colorValue': colorValue,
      'blendMode': blendMode.index,
      'preserveSubject': preserveSubject,
    };
  }

  factory EdgeAuraConfig.fromJson(Map<String, dynamic> json) {
    final styleIndex = (json['style'] as int? ?? 0).clamp(0, EdgeGlowStyle.values.length - 1).toInt();
    final blendIndex = (json['blendMode'] as int? ?? 0).clamp(0, GlowBlendMode.values.length - 1).toInt();

    return EdgeAuraConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      style: EdgeGlowStyle.values[styleIndex],
      intensity: (json['intensity'] as num? ?? 1.0).toDouble(),
      radius: (json['radius'] as num? ?? 15.0).toDouble(),
      threshold: (json['threshold'] as num? ?? 0.25).toDouble(),
      pulseSpeed: (json['pulseSpeed'] as num? ?? 0.0).toDouble(),
      colorValue: json['colorValue'] as int? ?? 0xFF00F0FF,
      blendMode: GlowBlendMode.values[blendIndex],
      preserveSubject: json['preserveSubject'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        style,
        intensity,
        radius,
        threshold,
        pulseSpeed,
        colorValue,
        blendMode,
        preserveSubject,
      ];
}
