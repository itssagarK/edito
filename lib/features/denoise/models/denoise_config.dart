import 'package:equatable/equatable.dart';

/// CapCut Pro Video De-Noise & Grain Reduction Level
enum DenoiseLevel {
  none,
  mild,
  balanced,
  lowLightNight,
  ultraClean,
  custom,
}

extension DenoiseLevelExt on DenoiseLevel {
  String get label {
    switch (this) {
      case DenoiseLevel.none:
        return 'Off';
      case DenoiseLevel.mild:
        return 'Mild Clean';
      case DenoiseLevel.balanced:
        return 'Balanced';
      case DenoiseLevel.lowLightNight:
        return 'Low-Light Night';
      case DenoiseLevel.ultraClean:
        return 'Ultra Clean';
      case DenoiseLevel.custom:
        return 'Custom Tuning';
    }
  }

  String get description {
    switch (this) {
      case DenoiseLevel.none:
        return 'Pristine raw sensor grain with no filtering';
      case DenoiseLevel.mild:
        return 'Subtle chroma grain suppression with 100% texture preservation';
      case DenoiseLevel.balanced:
        return 'Recommended 3D spatio-temporal denoise for smartphone footage';
      case DenoiseLevel.lowLightNight:
        return 'Deep grain suppression for high-ISO indoor and night scenes';
      case DenoiseLevel.ultraClean:
        return 'Maximum temporal artifact and compression block elimination';
      case DenoiseLevel.custom:
        return 'Fully manual spatial and temporal luma/chroma thresholds';
    }
  }

  double get defaultSpatialLuma {
    switch (this) {
      case DenoiseLevel.mild:
        return 2.0;
      case DenoiseLevel.balanced:
        return 4.0;
      case DenoiseLevel.lowLightNight:
        return 7.5;
      case DenoiseLevel.ultraClean:
        return 12.0;
      default:
        return 0.0;
    }
  }

  double get defaultSpatialChroma {
    switch (this) {
      case DenoiseLevel.mild:
        return 3.0;
      case DenoiseLevel.balanced:
        return 4.5;
      case DenoiseLevel.lowLightNight:
        return 8.0;
      case DenoiseLevel.ultraClean:
        return 14.0;
      default:
        return 0.0;
    }
  }

  double get defaultTemporalLuma {
    switch (this) {
      case DenoiseLevel.mild:
        return 3.0;
      case DenoiseLevel.balanced:
        return 6.0;
      case DenoiseLevel.lowLightNight:
        return 10.0;
      case DenoiseLevel.ultraClean:
        return 16.0;
      default:
        return 0.0;
    }
  }

  double get defaultTemporalChroma {
    switch (this) {
      case DenoiseLevel.mild:
        return 2.5;
      case DenoiseLevel.balanced:
        return 5.0;
      case DenoiseLevel.lowLightNight:
        return 8.5;
      case DenoiseLevel.ultraClean:
        return 14.0;
      default:
        return 0.0;
    }
  }
}

/// Denoise DSP Algorithm Selection
enum DenoiseAlgorithm {
  spatioTemporal3D,
  adaptiveTemporal,
  edgePreservingBilateral,
}

extension DenoiseAlgorithmExt on DenoiseAlgorithm {
  String get label {
    switch (this) {
      case DenoiseAlgorithm.spatioTemporal3D:
        return '3D Spatio-Temporal (hqdn3d)';
      case DenoiseAlgorithm.adaptiveTemporal:
        return 'Adaptive Temporal (atadenoise)';
      case DenoiseAlgorithm.edgePreservingBilateral:
        return 'Bilateral Edge Preservation';
    }
  }

  String get shortLabel {
    switch (this) {
      case DenoiseAlgorithm.spatioTemporal3D:
        return '3D HQ';
      case DenoiseAlgorithm.adaptiveTemporal:
        return 'Adaptive';
      case DenoiseAlgorithm.edgePreservingBilateral:
        return 'Bilateral';
    }
  }
}

/// CapCut Pro Video De-Noise & Low-Light Enhancement Configuration
class DenoiseConfig extends Equatable {
  final bool isEnabled;
  final DenoiseLevel level;
  final DenoiseAlgorithm algorithm;
  final double spatialLuma; // 0.0 to 20.0 (default: 4.0)
  final double spatialChroma; // 0.0 to 20.0 (default: 4.5)
  final double temporalLuma; // 0.0 to 30.0 (default: 6.0)
  final double temporalChroma; // 0.0 to 30.0 (default: 5.0)
  final double detailSharpening; // 0.0 to 1.5 (default: 0.35)
  final double lowLightBoost; // 0.0 to 1.0 (default: 0.0)

  const DenoiseConfig({
    this.isEnabled = false,
    this.level = DenoiseLevel.none,
    this.algorithm = DenoiseAlgorithm.spatioTemporal3D,
    this.spatialLuma = 4.0,
    this.spatialChroma = 4.5,
    this.temporalLuma = 6.0,
    this.temporalChroma = 5.0,
    this.detailSharpening = 0.35,
    this.lowLightBoost = 0.0,
  });

  /// Factory constructor to immediately create a preset level
  factory DenoiseConfig.fromLevel(DenoiseLevel level, {double lowLightBoost = 0.0}) {
    if (level == DenoiseLevel.none) {
      return const DenoiseConfig();
    }
    return DenoiseConfig(
      isEnabled: true,
      level: level,
      spatialLuma: level.defaultSpatialLuma,
      spatialChroma: level.defaultSpatialChroma,
      temporalLuma: level.defaultTemporalLuma,
      temporalChroma: level.defaultTemporalChroma,
      lowLightBoost: lowLightBoost,
    );
  }

  /// Real-time HUD status badge text
  String get badge {
    if (!isEnabled || level == DenoiseLevel.none) return '';
    return 'DENOISE: ${level.label.toUpperCase()}';
  }

  DenoiseConfig copyWith({
    bool? isEnabled,
    DenoiseLevel? level,
    DenoiseAlgorithm? algorithm,
    double? spatialLuma,
    double? spatialChroma,
    double? temporalLuma,
    double? temporalChroma,
    double? detailSharpening,
    double? lowLightBoost,
  }) {
    return DenoiseConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      level: level ?? this.level,
      algorithm: algorithm ?? this.algorithm,
      spatialLuma: spatialLuma ?? this.spatialLuma,
      spatialChroma: spatialChroma ?? this.spatialChroma,
      temporalLuma: temporalLuma ?? this.temporalLuma,
      temporalChroma: temporalChroma ?? this.temporalChroma,
      detailSharpening: detailSharpening ?? this.detailSharpening,
      lowLightBoost: lowLightBoost ?? this.lowLightBoost,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'level': level.name,
        'algorithm': algorithm.name,
        'spatialLuma': spatialLuma,
        'spatialChroma': spatialChroma,
        'temporalLuma': temporalLuma,
        'temporalChroma': temporalChroma,
        'detailSharpening': detailSharpening,
        'lowLightBoost': lowLightBoost,
      };

  factory DenoiseConfig.fromJson(Map<String, dynamic> json) {
    DenoiseLevel levelVal = DenoiseLevel.none;
    if (json['level'] != null) {
      levelVal = DenoiseLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => DenoiseLevel.none,
      );
    }

    DenoiseAlgorithm algoVal = DenoiseAlgorithm.spatioTemporal3D;
    if (json['algorithm'] != null) {
      algoVal = DenoiseAlgorithm.values.firstWhere(
        (a) => a.name == json['algorithm'],
        orElse: () => DenoiseAlgorithm.spatioTemporal3D,
      );
    }

    return DenoiseConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      level: levelVal,
      algorithm: algoVal,
      spatialLuma: (json['spatialLuma'] as num?)?.toDouble() ?? 4.0,
      spatialChroma: (json['spatialChroma'] as num?)?.toDouble() ?? 4.5,
      temporalLuma: (json['temporalLuma'] as num?)?.toDouble() ?? 6.0,
      temporalChroma: (json['temporalChroma'] as num?)?.toDouble() ?? 5.0,
      detailSharpening: (json['detailSharpening'] as num?)?.toDouble() ?? 0.35,
      lowLightBoost: (json['lowLightBoost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        level,
        algorithm,
        spatialLuma,
        spatialChroma,
        temporalLuma,
        temporalChroma,
        detailSharpening,
        lowLightBoost,
      ];
}
