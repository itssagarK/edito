import 'package:equatable/equatable.dart';

/// Tone curve inversion and color inflection modes for photographic solarization.
enum SolarizeInvertMode {
  sabattier,
  negativeInvert,
  psychedelic,
  thermalHeat,
  crossProcess;

  String get displayName {
    switch (this) {
      case SolarizeInvertMode.sabattier:
        return 'Sabattier Solarization';
      case SolarizeInvertMode.negativeInvert:
        return 'Film Negative Invert';
      case SolarizeInvertMode.psychedelic:
        return 'Acid Trip Psychedelic';
      case SolarizeInvertMode.thermalHeat:
        return 'Thermal Infrared Heat';
      case SolarizeInvertMode.crossProcess:
        return 'Darkroom Cross-Process';
    }
  }

  String get description {
    switch (this) {
      case SolarizeInvertMode.sabattier:
        return 'Classic darkroom tone inflection where highlights above threshold invert into shadows';
      case SolarizeInvertMode.negativeInvert:
        return 'Total optical inversion reversing all brightness and color into photo negatives';
      case SolarizeInvertMode.psychedelic:
        return 'Vivid multi-phase hue solarization with saturated psychedelic neon chromaticism';
      case SolarizeInvertMode.thermalHeat:
        return 'FLIR thermal imaging false-color gradient mapping hot and cold luminance';
      case SolarizeInvertMode.crossProcess:
        return 'High-contrast chemical processing inversion inflecting shadows and midtones';
    }
  }
}

/// Configuration for thermal solarization, pseudo-solarization, and color inversion.
class SolarizeInvertConfig extends Equatable {
  final bool isEnabled;
  final SolarizeInvertMode mode;
  final double threshold; // 0.1 to 0.9 (luminance inflection point)
  final double intensity; // 0.0 to 1.0 (effect mix blend)
  final double saturationBoost; // 1.0 to 2.5 (vibrancy multiplier)
  final double tintHue; // 0.0 to 360.0 (hue rotation for psychedelic/thermal)

  const SolarizeInvertConfig({
    this.isEnabled = false,
    this.mode = SolarizeInvertMode.sabattier,
    this.threshold = 0.50,
    this.intensity = 0.85,
    this.saturationBoost = 1.40,
    this.tintHue = 180.0,
  });

  bool get isActive => isEnabled && intensity > 0.05;

  SolarizeInvertConfig copyWith({
    bool? isEnabled,
    SolarizeInvertMode? mode,
    double? threshold,
    double? intensity,
    double? saturationBoost,
    double? tintHue,
  }) {
    return SolarizeInvertConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      threshold: threshold ?? this.threshold,
      intensity: intensity ?? this.intensity,
      saturationBoost: saturationBoost ?? this.saturationBoost,
      tintHue: tintHue ?? this.tintHue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'threshold': threshold,
      'intensity': intensity,
      'saturationBoost': saturationBoost,
      'tintHue': tintHue,
    };
  }

  factory SolarizeInvertConfig.fromJson(Map<String, dynamic> json) {
    SolarizeInvertMode parsedMode = SolarizeInvertMode.sabattier;
    if (json['mode'] != null) {
      try {
        parsedMode = SolarizeInvertMode.values.byName(json['mode'] as String);
      } catch (_) {
        parsedMode = SolarizeInvertMode.sabattier;
      }
    }

    return SolarizeInvertConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: parsedMode,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.50,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.85,
      saturationBoost: (json['saturationBoost'] as num?)?.toDouble() ?? 1.40,
      tintHue: (json['tintHue'] as num?)?.toDouble() ?? 180.0,
    );
  }

  // Curated presets
  static const SolarizeInvertConfig sabattierSolarize = SolarizeInvertConfig(
    isEnabled: true,
    mode: SolarizeInvertMode.sabattier,
    threshold: 0.50,
    intensity: 0.90,
    saturationBoost: 1.35,
    tintHue: 180.0,
  );

  static const SolarizeInvertConfig negativeFilm = SolarizeInvertConfig(
    isEnabled: true,
    mode: SolarizeInvertMode.negativeInvert,
    threshold: 0.50,
    intensity: 1.0,
    saturationBoost: 1.10,
    tintHue: 0.0,
  );

  static const SolarizeInvertConfig acidTrip = SolarizeInvertConfig(
    isEnabled: true,
    mode: SolarizeInvertMode.psychedelic,
    threshold: 0.40,
    intensity: 0.95,
    saturationBoost: 2.20,
    tintHue: 280.0,
  );

  static const SolarizeInvertConfig thermalInfrared = SolarizeInvertConfig(
    isEnabled: true,
    mode: SolarizeInvertMode.thermalHeat,
    threshold: 0.30,
    intensity: 0.90,
    saturationBoost: 1.80,
    tintHue: 40.0,
  );

  static const SolarizeInvertConfig darkroomCross = SolarizeInvertConfig(
    isEnabled: true,
    mode: SolarizeInvertMode.crossProcess,
    threshold: 0.60,
    intensity: 0.75,
    saturationBoost: 1.50,
    tintHue: 120.0,
  );

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        threshold,
        intensity,
        saturationBoost,
        tintHue,
      ];
}
