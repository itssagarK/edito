import 'package:equatable/equatable.dart';

/// Modes for ASCII Terminal and retro character matrix rendering.
enum AsciiArtMode {
  greenPhosphor,
  amberCathode,
  cyberpunkNeon,
  matrixColor,
  monochromePaper,
}

extension AsciiArtModeExtension on AsciiArtMode {
  String get label {
    switch (this) {
      case AsciiArtMode.greenPhosphor:
        return 'Phosphor Green';
      case AsciiArtMode.amberCathode:
        return 'Amber Cathode';
      case AsciiArtMode.cyberpunkNeon:
        return 'Cyberpunk Neon';
      case AsciiArtMode.matrixColor:
        return 'Full Color ANSI';
      case AsciiArtMode.monochromePaper:
        return 'Mono Printout';
    }
  }

  String get description {
    switch (this) {
      case AsciiArtMode.greenPhosphor:
        return 'Classic 1980s VT100 / Matrix terminal luminous green on pitch black';
      case AsciiArtMode.amberCathode:
        return 'Warm vintage amber CRT phosphor console styling';
      case AsciiArtMode.cyberpunkNeon:
        return 'Electric cyan and neon magenta duotone hacker terminal';
      case AsciiArtMode.matrixColor:
        return 'Full-color ANSI terminal preserving original video chroma per glyph';
      case AsciiArtMode.monochromePaper:
        return 'High-contrast monochrome paper printout rasterization';
    }
  }
}

/// Configuration for ASCII terminal matrix texturizer.
class AsciiArtConfig extends Equatable {
  final bool isEnabled;
  final AsciiArtMode mode;
  final double characterDensity; // 0.2 to 1.0 glyph detail level
  final int cellSize; // 4 to 20 pixel grid size per glyph
  final double contrast; // 0.5 to 2.5 contrast curve
  final double glyphGlow; // 0.0 to 1.0 phosphor bloom
  final bool isInverted; // invert luminance ramp

  bool get isActive => isEnabled;

  const AsciiArtConfig({
    this.isEnabled = false,
    this.mode = AsciiArtMode.greenPhosphor,
    this.characterDensity = 0.6,
    this.cellSize = 8,
    this.contrast = 1.3,
    this.glyphGlow = 0.4,
    this.isInverted = false,
  });

  AsciiArtConfig copyWith({
    bool? isEnabled,
    AsciiArtMode? mode,
    double? characterDensity,
    int? cellSize,
    double? contrast,
    double? glyphGlow,
    bool? isInverted,
  }) {
    return AsciiArtConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      characterDensity: characterDensity ?? this.characterDensity,
      cellSize: cellSize ?? this.cellSize,
      contrast: contrast ?? this.contrast,
      glyphGlow: glyphGlow ?? this.glyphGlow,
      isInverted: isInverted ?? this.isInverted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'characterDensity': characterDensity,
      'cellSize': cellSize,
      'contrast': contrast,
      'glyphGlow': glyphGlow,
      'isInverted': isInverted,
    };
  }

  factory AsciiArtConfig.fromJson(Map<String, dynamic> json) {
    return AsciiArtConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: AsciiArtMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => AsciiArtMode.greenPhosphor,
      ),
      characterDensity:
          (json['characterDensity'] as num?)?.toDouble() ?? 0.6,
      cellSize: (json['cellSize'] as num?)?.toInt() ?? 8,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.3,
      glyphGlow: (json['glyphGlow'] as num?)?.toDouble() ?? 0.4,
      isInverted: json['isInverted'] as bool? ?? false,
    );
  }

  // Presets
  static const AsciiArtConfig classicGreenTerminal = AsciiArtConfig(
    isEnabled: true,
    mode: AsciiArtMode.greenPhosphor,
    characterDensity: 0.7,
    cellSize: 8,
    contrast: 1.4,
    glyphGlow: 0.5,
    isInverted: false,
  );

  static const AsciiArtConfig vintageAmberCathode = AsciiArtConfig(
    isEnabled: true,
    mode: AsciiArtMode.amberCathode,
    characterDensity: 0.65,
    cellSize: 10,
    contrast: 1.3,
    glyphGlow: 0.4,
    isInverted: false,
  );

  static const AsciiArtConfig cyberpunkConsole = AsciiArtConfig(
    isEnabled: true,
    mode: AsciiArtMode.cyberpunkNeon,
    characterDensity: 0.8,
    cellSize: 6,
    contrast: 1.5,
    glyphGlow: 0.6,
    isInverted: false,
  );

  static const AsciiArtConfig colorAnsiMatrix = AsciiArtConfig(
    isEnabled: true,
    mode: AsciiArtMode.matrixColor,
    characterDensity: 0.6,
    cellSize: 8,
    contrast: 1.2,
    glyphGlow: 0.3,
    isInverted: false,
  );

  static const AsciiArtConfig monochromePrintout = AsciiArtConfig(
    isEnabled: true,
    mode: AsciiArtMode.monochromePaper,
    characterDensity: 0.75,
    cellSize: 8,
    contrast: 1.6,
    glyphGlow: 0.1,
    isInverted: true,
  );

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        characterDensity,
        cellSize,
        contrast,
        glyphGlow,
        isInverted,
      ];
}
