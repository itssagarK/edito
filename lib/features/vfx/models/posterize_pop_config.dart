import 'package:equatable/equatable.dart';

/// Artistic stylization and tonal quantization modes for posterization and pop art.
enum PosterizePopMode {
  warholPopArt,
  comicBookInk,
  cyberpunkDuotone,
  retro8BitPoster,
  monochromeNoir;

  String get displayName {
    switch (this) {
      case PosterizePopMode.warholPopArt:
        return 'Warhol Pop Art (Silk-Screen)';
      case PosterizePopMode.comicBookInk:
        return 'Comic Book Inked Shading';
      case PosterizePopMode.cyberpunkDuotone:
        return 'Cyberpunk Duotone (Cyan/Pink)';
      case PosterizePopMode.retro8BitPoster:
        return 'Retro 8-Bit Computer Poster';
      case PosterizePopMode.monochromeNoir:
        return 'Stark Film Noir Monochrome';
    }
  }

  String get description {
    switch (this) {
      case PosterizePopMode.warholPopArt:
        return 'Andy Warhol silk-screen print aesthetic with hyper-saturated chromatic color blocking';
      case PosterizePopMode.comicBookInk:
        return 'Graphic novel inked shading with bold black contours and stepped tonal cell shading';
      case PosterizePopMode.cyberpunkDuotone:
        return 'Dual-tone split mapping midtones and highlights into neon cyan and hot magenta';
      case PosterizePopMode.retro8BitPoster:
        return 'Stepped quantization reducing continuous gradients into retro indexed arcade color levels';
      case PosterizePopMode.monochromeNoir:
        return 'High-contrast black-and-white tonal reduction with deep shadows and specular whites';
    }
  }
}

/// Configuration for threshold posterization, pop art chromas, and comic ink contours.
class PosterizePopConfig extends Equatable {
  final bool isEnabled;
  final PosterizePopMode mode;
  final int colorLevels; // 2 to 16 quantization steps per channel
  final double outlineStrength; // 0.0 to 1.0 ink outline intensity
  final double saturationBoost; // 1.0 to 2.5 color vibrancy pop
  final double contrast; // 1.0 to 2.0 tonal contrast

  const PosterizePopConfig({
    this.isEnabled = false,
    this.mode = PosterizePopMode.warholPopArt,
    this.colorLevels = 4,
    this.outlineStrength = 0.40,
    this.saturationBoost = 1.50,
    this.contrast = 1.25,
  });

  bool get isActive => isEnabled && colorLevels >= 2;

  PosterizePopConfig copyWith({
    bool? isEnabled,
    PosterizePopMode? mode,
    int? colorLevels,
    double? outlineStrength,
    double? saturationBoost,
    double? contrast,
  }) {
    return PosterizePopConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      colorLevels: colorLevels ?? this.colorLevels,
      outlineStrength: outlineStrength ?? this.outlineStrength,
      saturationBoost: saturationBoost ?? this.saturationBoost,
      contrast: contrast ?? this.contrast,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'colorLevels': colorLevels,
      'outlineStrength': outlineStrength,
      'saturationBoost': saturationBoost,
      'contrast': contrast,
    };
  }

  factory PosterizePopConfig.fromJson(Map<String, dynamic> json) {
    PosterizePopMode parsedMode = PosterizePopMode.warholPopArt;
    if (json['mode'] != null) {
      try {
        parsedMode = PosterizePopMode.values.byName(json['mode'] as String);
      } catch (_) {
        parsedMode = PosterizePopMode.warholPopArt;
      }
    }

    return PosterizePopConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: parsedMode,
      colorLevels: (json['colorLevels'] as num?)?.toInt() ?? 4,
      outlineStrength: (json['outlineStrength'] as num?)?.toDouble() ?? 0.40,
      saturationBoost: (json['saturationBoost'] as num?)?.toDouble() ?? 1.50,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.25,
    );
  }

  // Curated presets
  static const PosterizePopConfig warholPop = PosterizePopConfig(
    isEnabled: true,
    mode: PosterizePopMode.warholPopArt,
    colorLevels: 4,
    outlineStrength: 0.50,
    saturationBoost: 1.80,
    contrast: 1.30,
  );

  static const PosterizePopConfig comicBook = PosterizePopConfig(
    isEnabled: true,
    mode: PosterizePopMode.comicBookInk,
    colorLevels: 3,
    outlineStrength: 0.85,
    saturationBoost: 1.20,
    contrast: 1.50,
  );

  static const PosterizePopConfig cyberDuotone = PosterizePopConfig(
    isEnabled: true,
    mode: PosterizePopMode.cyberpunkDuotone,
    colorLevels: 4,
    outlineStrength: 0.40,
    saturationBoost: 1.90,
    contrast: 1.35,
  );

  static const PosterizePopConfig retro8Bit = PosterizePopConfig(
    isEnabled: true,
    mode: PosterizePopMode.retro8BitPoster,
    colorLevels: 8,
    outlineStrength: 0.0,
    saturationBoost: 1.30,
    contrast: 1.20,
  );

  static const PosterizePopConfig noirMonochrome = PosterizePopConfig(
    isEnabled: true,
    mode: PosterizePopMode.monochromeNoir,
    colorLevels: 3,
    outlineStrength: 0.70,
    saturationBoost: 1.0,
    contrast: 1.60,
  );

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        colorLevels,
        outlineStrength,
        saturationBoost,
        contrast,
      ];
}
