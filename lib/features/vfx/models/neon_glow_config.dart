import 'package:equatable/equatable.dart';

/// Style profile for cyberpunk neon edge glows and holographic wireframe contours.
enum NeonGlowMode {
  cyberpunkNeon,
  hologramWireframe,
  rainbowEdges,
  matrixPhosphor,
  thermalContour;

  String get displayName {
    switch (this) {
      case NeonGlowMode.cyberpunkNeon:
        return 'Cyberpunk Neon Edges';
      case NeonGlowMode.hologramWireframe:
        return 'Holographic Wireframe';
      case NeonGlowMode.rainbowEdges:
        return 'Rainbow Chromatic Edges';
      case NeonGlowMode.matrixPhosphor:
        return 'Matrix Phosphor Green';
      case NeonGlowMode.thermalContour:
        return 'Thermal Heat Contour';
    }
  }

  String get description {
    switch (this) {
      case NeonGlowMode.cyberpunkNeon:
        return 'Electrifying neon silhouette outlines with intense chromatic edge bloom';
      case NeonGlowMode.hologramWireframe:
        return 'Futuristic sci-fi wireframe mesh with scanline raster lines';
      case NeonGlowMode.rainbowEdges:
        return 'Vivid multi-spectral rainbow gradient mapped across contrast boundaries';
      case NeonGlowMode.matrixPhosphor:
        return 'Monochromatic cybernetic green wireframe contour against deep contrast';
      case NeonGlowMode.thermalContour:
        return 'Infrared isoline contour edges highlighting subject temperature gradients';
    }
  }
}

/// Configuration for cyberpunk neon edge glow, wireframe, and holographic contours.
class NeonGlowConfig extends Equatable {
  final bool isEnabled;
  final NeonGlowMode mode;
  final String glowColorHex; // Hex color string (e.g. '#00E5FF')
  final double edgeThreshold; // 0.05 to 0.80 (Sobel edge detection sensitivity)
  final double glowRadius; // 1.0 to 20.0 px (bloom diffusion halo radius)
  final double glowIntensity; // 0.2 to 2.5 (neon luminance multiplier)
  final double mixWithSource; // 0.0 to 1.0 (blend with source video: 0=pure wireframe, 1=superimposed)
  final bool scanlines; // Holographic scanline raster lines

  const NeonGlowConfig({
    this.isEnabled = false,
    this.mode = NeonGlowMode.cyberpunkNeon,
    this.glowColorHex = '#00E5FF',
    this.edgeThreshold = 0.20,
    this.glowRadius = 6.0,
    this.glowIntensity = 1.2,
    this.mixWithSource = 0.60,
    this.scanlines = false,
  });

  bool get isActive => isEnabled && glowIntensity > 0.05;

  // Curated Presets
  static const NeonGlowConfig tokyoNeonCyan = NeonGlowConfig(
    isEnabled: true,
    mode: NeonGlowMode.cyberpunkNeon,
    glowColorHex: '#00E5FF',
    edgeThreshold: 0.18,
    glowRadius: 8.0,
    glowIntensity: 1.5,
    mixWithSource: 0.65,
    scanlines: false,
  );

  static const NeonGlowConfig hologramMeshBlue = NeonGlowConfig(
    isEnabled: true,
    mode: NeonGlowMode.hologramWireframe,
    glowColorHex: '#00B0FF',
    edgeThreshold: 0.22,
    glowRadius: 5.0,
    glowIntensity: 1.3,
    mixWithSource: 0.40,
    scanlines: true,
  );

  static const NeonGlowConfig synthwaveMagenta = NeonGlowConfig(
    isEnabled: true,
    mode: NeonGlowMode.cyberpunkNeon,
    glowColorHex: '#FF007F',
    edgeThreshold: 0.16,
    glowRadius: 10.0,
    glowIntensity: 1.6,
    mixWithSource: 0.70,
    scanlines: false,
  );

  static const NeonGlowConfig matrixWireframe = NeonGlowConfig(
    isEnabled: true,
    mode: NeonGlowMode.matrixPhosphor,
    glowColorHex: '#00FF66',
    edgeThreshold: 0.25,
    glowRadius: 4.0,
    glowIntensity: 1.4,
    mixWithSource: 0.25,
    scanlines: true,
  );

  static const NeonGlowConfig rainbowSpectrum = NeonGlowConfig(
    isEnabled: true,
    mode: NeonGlowMode.rainbowEdges,
    glowColorHex: '#FFD700',
    edgeThreshold: 0.20,
    glowRadius: 7.0,
    glowIntensity: 1.3,
    mixWithSource: 0.55,
    scanlines: false,
  );

  NeonGlowConfig copyWith({
    bool? isEnabled,
    NeonGlowMode? mode,
    String? glowColorHex,
    double? edgeThreshold,
    double? glowRadius,
    double? glowIntensity,
    double? mixWithSource,
    bool? scanlines,
  }) {
    return NeonGlowConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      glowColorHex: glowColorHex ?? this.glowColorHex,
      edgeThreshold: edgeThreshold ?? this.edgeThreshold,
      glowRadius: glowRadius ?? this.glowRadius,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      mixWithSource: mixWithSource ?? this.mixWithSource,
      scanlines: scanlines ?? this.scanlines,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'glowColorHex': glowColorHex,
      'edgeThreshold': edgeThreshold,
      'glowRadius': glowRadius,
      'glowIntensity': glowIntensity,
      'mixWithSource': mixWithSource,
      'scanlines': scanlines,
    };
  }

  factory NeonGlowConfig.fromJson(Map<String, dynamic> json) {
    return NeonGlowConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: NeonGlowMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => NeonGlowMode.cyberpunkNeon,
      ),
      glowColorHex: json['glowColorHex'] as String? ?? '#00E5FF',
      edgeThreshold: (json['edgeThreshold'] as num?)?.toDouble() ?? 0.20,
      glowRadius: (json['glowRadius'] as num?)?.toDouble() ?? 6.0,
      glowIntensity: (json['glowIntensity'] as num?)?.toDouble() ?? 1.2,
      mixWithSource: (json['mixWithSource'] as num?)?.toDouble() ?? 0.60,
      scanlines: json['scanlines'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        glowColorHex,
        edgeThreshold,
        glowRadius,
        glowIntensity,
        mixWithSource,
        scanlines,
      ];
}
