import 'package:equatable/equatable.dart';

enum ProBlendMode {
  normal,
  screen,
  multiply,
  overlay,
  softLight,
  hardLight,
  colorDodge,
  colorBurn,
  darken,
  lighten,
  difference,
  exclusion,
}

enum BlendModeCategory {
  standard,
  lighten, // Removes black (great for light leaks, fire, smoke, dust)
  darken, // Removes white (great for paper textures, shadows, grunge)
  contrast, // Balances contrast (film look, deep punch)
  inversion, // Creative psychedelic & inversion effects
}

extension ProBlendModeExtension on ProBlendMode {
  String get label {
    switch (this) {
      case ProBlendMode.normal:
        return 'Normal';
      case ProBlendMode.screen:
        return 'Screen';
      case ProBlendMode.multiply:
        return 'Multiply';
      case ProBlendMode.overlay:
        return 'Overlay';
      case ProBlendMode.softLight:
        return 'Soft Light';
      case ProBlendMode.hardLight:
        return 'Hard Light';
      case ProBlendMode.colorDodge:
        return 'Color Dodge';
      case ProBlendMode.colorBurn:
        return 'Color Burn';
      case ProBlendMode.darken:
        return 'Darken';
      case ProBlendMode.lighten:
        return 'Lighten';
      case ProBlendMode.difference:
        return 'Difference';
      case ProBlendMode.exclusion:
        return 'Exclusion';
    }
  }

  BlendModeCategory get category {
    switch (this) {
      case ProBlendMode.normal:
        return BlendModeCategory.standard;
      case ProBlendMode.screen:
      case ProBlendMode.lighten:
      case ProBlendMode.colorDodge:
        return BlendModeCategory.lighten;
      case ProBlendMode.multiply:
      case ProBlendMode.darken:
      case ProBlendMode.colorBurn:
        return BlendModeCategory.darken;
      case ProBlendMode.overlay:
      case ProBlendMode.softLight:
      case ProBlendMode.hardLight:
        return BlendModeCategory.contrast;
      case ProBlendMode.difference:
      case ProBlendMode.exclusion:
        return BlendModeCategory.inversion;
    }
  }

  String get description {
    switch (this) {
      case ProBlendMode.normal:
        return 'Standard alpha layer stacking';
      case ProBlendMode.screen:
        return 'Hides black; perfect for light leaks, flares & dust';
      case ProBlendMode.multiply:
        return 'Hides white; ideal for film grain & paper textures';
      case ProBlendMode.overlay:
        return 'Rich cinematic contrast & vibrant highlights';
      case ProBlendMode.softLight:
        return 'Subtle, organic diffused lighting balance';
      case ProBlendMode.hardLight:
        return 'Intense dramatic lighting & high contrast punch';
      case ProBlendMode.colorDodge:
        return 'Super-charged neon energy, sci-fi magic & glow';
      case ProBlendMode.colorBurn:
        return 'Deep moody shadows & vintage burnt exposure';
      case ProBlendMode.darken:
        return 'Replaces pixels lighter than the underlying image';
      case ProBlendMode.lighten:
        return 'Replaces pixels darker than the underlying image';
      case ProBlendMode.difference:
        return 'Psychedelic color inversion & artistic negative';
      case ProBlendMode.exclusion:
        return 'Softened tonal inversion with gentle contrast';
    }
  }

  String get ffmpegModeName {
    switch (this) {
      case ProBlendMode.normal:
        return 'normal';
      case ProBlendMode.screen:
        return 'screen';
      case ProBlendMode.multiply:
        return 'multiply';
      case ProBlendMode.overlay:
        return 'overlay';
      case ProBlendMode.softLight:
        return 'softlight';
      case ProBlendMode.hardLight:
        return 'hardlight';
      case ProBlendMode.colorDodge:
        return 'dodge';
      case ProBlendMode.colorBurn:
        return 'burn';
      case ProBlendMode.darken:
        return 'darken';
      case ProBlendMode.lighten:
        return 'lighten';
      case ProBlendMode.difference:
        return 'difference';
      case ProBlendMode.exclusion:
        return 'exclusion';
    }
  }
}

enum BlendModePreset {
  none,
  lightLeak,
  shadowTexture,
  cinematicVibe,
  subtleGlow,
  magicEnergy,
  psychedelicX,
}

class BlendModeConfig extends Equatable {
  final ProBlendMode mode;
  final double opacity; // 0.0 to 1.0

  const BlendModeConfig({
    this.mode = ProBlendMode.normal,
    this.opacity = 1.0,
  });

  bool get isEnabled => mode != ProBlendMode.normal || opacity < 0.999;

  BlendModeConfig copyWith({
    ProBlendMode? mode,
    double? opacity,
  }) {
    return BlendModeConfig(
      mode: mode ?? this.mode,
      opacity: opacity ?? this.opacity,
    );
  }

  static BlendModeConfig fromPreset(BlendModePreset preset) {
    switch (preset) {
      case BlendModePreset.none:
        return const BlendModeConfig(mode: ProBlendMode.normal, opacity: 1.0);
      case BlendModePreset.lightLeak:
        return const BlendModeConfig(mode: ProBlendMode.screen, opacity: 0.85);
      case BlendModePreset.shadowTexture:
        return const BlendModeConfig(mode: ProBlendMode.multiply, opacity: 0.75);
      case BlendModePreset.cinematicVibe:
        return const BlendModeConfig(mode: ProBlendMode.overlay, opacity: 0.80);
      case BlendModePreset.subtleGlow:
        return const BlendModeConfig(mode: ProBlendMode.softLight, opacity: 0.90);
      case BlendModePreset.magicEnergy:
        return const BlendModeConfig(mode: ProBlendMode.colorDodge, opacity: 0.70);
      case BlendModePreset.psychedelicX:
        return const BlendModeConfig(mode: ProBlendMode.difference, opacity: 1.0);
    }
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'opacity': opacity,
      };

  factory BlendModeConfig.fromJson(Map<String, dynamic> json) => BlendModeConfig(
        mode: ProBlendMode.values.firstWhere(
          (e) => e.name == json['mode'],
          orElse: () => ProBlendMode.normal,
        ),
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  List<Object?> get props => [mode, opacity];
}
