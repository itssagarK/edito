import 'package:equatable/equatable.dart';

/// Chromatic and aesthetic styling modes for cascading digital code rain.
enum MatrixRainMode {
  classicPhosphorGreen,
  cyberpunkNeonPink,
  quantumCyanData,
  goldenAsciiGold,
  ghostMonochrome;

  String get displayName {
    switch (this) {
      case MatrixRainMode.classicPhosphorGreen:
        return 'Classic Phosphor Green';
      case MatrixRainMode.cyberpunkNeonPink:
        return 'Cyberpunk Neon Pink';
      case MatrixRainMode.quantumCyanData:
        return 'Quantum Cyan Stream';
      case MatrixRainMode.goldenAsciiGold:
        return 'Golden Hex Mainframe';
      case MatrixRainMode.ghostMonochrome:
        return 'Ghost Silver Terminal';
    }
  }

  String get description {
    switch (this) {
      case MatrixRainMode.classicPhosphorGreen:
        return 'Iconic Matrix terminal code rain with white leading heads and emerald phosphor trails';
      case MatrixRainMode.cyberpunkNeonPink:
        return 'Synthwave neon pink and hot magenta cyber code cascading through dark space';
      case MatrixRainMode.quantumCyanData:
        return 'Deep quantum computing data stream with electric cyan and sapphire blue binary rain';
      case MatrixRainMode.goldenAsciiGold:
        return 'High-roller liquid gold hexadecimal and financial ticker data cascades';
      case MatrixRainMode.ghostMonochrome:
        return 'Stark monochrome silver data fall with phantom translucent fading tails';
    }
  }
}

/// Configuration for matrix code rain, cyber glyph streams, and falling data overlays.
class MatrixRainConfig extends Equatable {
  final bool isEnabled;
  final MatrixRainMode mode;
  final double density; // 0.2 to 1.0 column frequency
  final double fallSpeed; // 0.5 to 3.0 animation velocity
  final double glyphGlow; // 0.2 to 1.0 bloom persistence
  final double opacity; // 0.1 to 1.0 layer transparency

  const MatrixRainConfig({
    this.isEnabled = false,
    this.mode = MatrixRainMode.classicPhosphorGreen,
    this.density = 0.65,
    this.fallSpeed = 1.20,
    this.glyphGlow = 0.80,
    this.opacity = 0.75,
  });

  bool get isActive => isEnabled && opacity > 0.05;

  MatrixRainConfig copyWith({
    bool? isEnabled,
    MatrixRainMode? mode,
    double? density,
    double? fallSpeed,
    double? glyphGlow,
    double? opacity,
  }) {
    return MatrixRainConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      density: density ?? this.density,
      fallSpeed: fallSpeed ?? this.fallSpeed,
      glyphGlow: glyphGlow ?? this.glyphGlow,
      opacity: opacity ?? this.opacity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'density': density,
      'fallSpeed': fallSpeed,
      'glyphGlow': glyphGlow,
      'opacity': opacity,
    };
  }

  factory MatrixRainConfig.fromJson(Map<String, dynamic> json) {
    MatrixRainMode parsedMode = MatrixRainMode.classicPhosphorGreen;
    if (json['mode'] != null) {
      try {
        parsedMode = MatrixRainMode.values.byName(json['mode'] as String);
      } catch (_) {
        parsedMode = MatrixRainMode.classicPhosphorGreen;
      }
    }

    return MatrixRainConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: parsedMode,
      density: (json['density'] as num?)?.toDouble() ?? 0.65,
      fallSpeed: (json['fallSpeed'] as num?)?.toDouble() ?? 1.20,
      glyphGlow: (json['glyphGlow'] as num?)?.toDouble() ?? 0.80,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.75,
    );
  }

  // Curated presets
  static const MatrixRainConfig matrixClassic = MatrixRainConfig(
    isEnabled: true,
    mode: MatrixRainMode.classicPhosphorGreen,
    density: 0.75,
    fallSpeed: 1.25,
    glyphGlow: 0.85,
    opacity: 0.80,
  );

  static const MatrixRainConfig neonCyber = MatrixRainConfig(
    isEnabled: true,
    mode: MatrixRainMode.cyberpunkNeonPink,
    density: 0.60,
    fallSpeed: 1.50,
    glyphGlow: 0.90,
    opacity: 0.75,
  );

  static const MatrixRainConfig quantumStream = MatrixRainConfig(
    isEnabled: true,
    mode: MatrixRainMode.quantumCyanData,
    density: 0.80,
    fallSpeed: 1.10,
    glyphGlow: 0.70,
    opacity: 0.85,
  );

  static const MatrixRainConfig goldenHex = MatrixRainConfig(
    isEnabled: true,
    mode: MatrixRainMode.goldenAsciiGold,
    density: 0.50,
    fallSpeed: 0.85,
    glyphGlow: 0.95,
    opacity: 0.70,
  );

  static const MatrixRainConfig ghostCode = MatrixRainConfig(
    isEnabled: true,
    mode: MatrixRainMode.ghostMonochrome,
    density: 0.65,
    fallSpeed: 1.80,
    glyphGlow: 0.60,
    opacity: 0.65,
  );

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        density,
        fallSpeed,
        glyphGlow,
        opacity,
      ];
}
