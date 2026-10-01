import 'package:equatable/equatable.dart';
import 'film_grain_type.dart';

/// Curated film stock and grain aesthetic presets.
enum FilmGrainPreset {
  neutralOff,
  kodakVision3,
  fujiSuperia,
  super8Nostalgia,
  noirArchival,
  vhsCamcorder,
  cinematicSubtle;

  String get label {
    switch (this) {
      case FilmGrainPreset.neutralOff:
        return 'Off';
      case FilmGrainPreset.kodakVision3:
        return 'Kodak 500T';
      case FilmGrainPreset.fujiSuperia:
        return 'Fuji 16mm';
      case FilmGrainPreset.super8Nostalgia:
        return 'Super 8';
      case FilmGrainPreset.noirArchival:
        return 'Noir B&W';
      case FilmGrainPreset.vhsCamcorder:
        return 'VHS Tape';
      case FilmGrainPreset.cinematicSubtle:
        return 'Subtle 35mm';
    }
  }

  String get description {
    switch (this) {
      case FilmGrainPreset.neutralOff:
        return 'No grain or particle texture applied';
      case FilmGrainPreset.kodakVision3:
        return 'Iconic Hollywood 35mm motion picture negative grain';
      case FilmGrainPreset.fujiSuperia:
        return 'Textured indie cinema 16mm emulsion with rich character';
      case FilmGrainPreset.super8Nostalgia:
        return 'Heavy, nostalgic home-movie grain with vintage warmth';
      case FilmGrainPreset.noirArchival:
        return 'High-contrast monochrome silver halide crystal structure';
      case FilmGrainPreset.vhsCamcorder:
        return 'Analog magnetic tape noise and chromatic color drift';
      case FilmGrainPreset.cinematicSubtle:
        return 'Whisper-soft 35mm grain to eliminate digital video banding';
    }
  }
}

/// CapCut Pro Cinematic Film Grain & Texture Particles Configuration.
class FilmGrainConfig extends Equatable {
  final bool isEnabled;
  final FilmGrainType type;
  final double intensity; // 0.0 to 1.0 (default: 0.35)
  final double grainSize; // 0.5 to 3.0 (default: 1.0)
  final double roughness; // 0.0 to 1.0 (chroma vs luma noise ratio, default: 0.25)
  final double shadowSuppression; // 0.0 to 1.0 (protects deep blacks, default: 0.20)
  final double highlightSuppression; // 0.0 to 1.0 (protects clean whites, default: 0.30)
  final bool animate; // Frame-to-frame temporal noise animation

  const FilmGrainConfig({
    this.isEnabled = false,
    this.type = FilmGrainType.celluloid35mm,
    this.intensity = 0.35,
    this.grainSize = 1.0,
    this.roughness = 0.25,
    this.shadowSuppression = 0.20,
    this.highlightSuppression = 0.30,
    this.animate = true,
  });

  /// Factory for constructing presets directly.
  factory FilmGrainConfig.fromPreset(FilmGrainPreset preset) {
    switch (preset) {
      case FilmGrainPreset.neutralOff:
        return const FilmGrainConfig(isEnabled: false, intensity: 0.0);

      case FilmGrainPreset.kodakVision3:
        return const FilmGrainConfig(
          isEnabled: true,
          type: FilmGrainType.celluloid35mm,
          intensity: 0.38,
          grainSize: 1.0,
          roughness: 0.20,
          shadowSuppression: 0.25,
          highlightSuppression: 0.35,
          animate: true,
        );

      case FilmGrainPreset.fujiSuperia:
        return const FilmGrainConfig(
          isEnabled: true,
          type: FilmGrainType.celluloid16mm,
          intensity: 0.52,
          grainSize: 1.4,
          roughness: 0.35,
          shadowSuppression: 0.15,
          highlightSuppression: 0.25,
          animate: true,
        );

      case FilmGrainPreset.super8Nostalgia:
        return const FilmGrainConfig(
          isEnabled: true,
          type: FilmGrainType.super8,
          intensity: 0.68,
          grainSize: 2.0,
          roughness: 0.45,
          shadowSuppression: 0.10,
          highlightSuppression: 0.15,
          animate: true,
        );

      case FilmGrainPreset.noirArchival:
        return const FilmGrainConfig(
          isEnabled: true,
          type: FilmGrainType.silverHalide,
          intensity: 0.60,
          grainSize: 1.2,
          roughness: 0.0, // Pure monochrome luma grain
          shadowSuppression: 0.20,
          highlightSuppression: 0.20,
          animate: true,
        );

      case FilmGrainPreset.vhsCamcorder:
        return const FilmGrainConfig(
          isEnabled: true,
          type: FilmGrainType.analogTape,
          intensity: 0.48,
          grainSize: 1.8,
          roughness: 0.70, // Heavy chromatic noise
          shadowSuppression: 0.05,
          highlightSuppression: 0.10,
          animate: true,
        );

      case FilmGrainPreset.cinematicSubtle:
        return const FilmGrainConfig(
          isEnabled: true,
          type: FilmGrainType.celluloid35mm,
          intensity: 0.18,
          grainSize: 0.8,
          roughness: 0.15,
          shadowSuppression: 0.35,
          highlightSuppression: 0.40,
          animate: true,
        );
    }
  }

  /// Whether film grain is actively visible.
  bool get isActive => isEnabled && intensity > 0.001;

  FilmGrainConfig copyWith({
    bool? isEnabled,
    FilmGrainType? type,
    double? intensity,
    double? grainSize,
    double? roughness,
    double? shadowSuppression,
    double? highlightSuppression,
    bool? animate,
  }) {
    return FilmGrainConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      type: type ?? this.type,
      intensity: (intensity ?? this.intensity).clamp(0.0, 1.0),
      grainSize: (grainSize ?? this.grainSize).clamp(0.5, 3.0),
      roughness: (roughness ?? this.roughness).clamp(0.0, 1.0),
      shadowSuppression: (shadowSuppression ?? this.shadowSuppression).clamp(0.0, 1.0),
      highlightSuppression: (highlightSuppression ?? this.highlightSuppression).clamp(0.0, 1.0),
      animate: animate ?? this.animate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'type': type.name,
      'intensity': double.parse(intensity.toStringAsFixed(2)),
      'grainSize': double.parse(grainSize.toStringAsFixed(2)),
      'roughness': double.parse(roughness.toStringAsFixed(2)),
      'shadowSuppression': double.parse(shadowSuppression.toStringAsFixed(2)),
      'highlightSuppression': double.parse(highlightSuppression.toStringAsFixed(2)),
      'animate': animate,
    };
  }

  factory FilmGrainConfig.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'celluloid35mm';
    final parsedType = FilmGrainType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => FilmGrainType.celluloid35mm,
    );

    return FilmGrainConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      type: parsedType,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.35,
      grainSize: (json['grainSize'] as num?)?.toDouble() ?? 1.0,
      roughness: (json['roughness'] as num?)?.toDouble() ?? 0.25,
      shadowSuppression: (json['shadowSuppression'] as num?)?.toDouble() ?? 0.20,
      highlightSuppression: (json['highlightSuppression'] as num?)?.toDouble() ?? 0.30,
      animate: json['animate'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        type,
        intensity,
        grainSize,
        roughness,
        shadowSuppression,
        highlightSuppression,
        animate,
      ];
}
