import 'package:equatable/equatable.dart';

/// CapCut Pro Video Stabilization Level
enum StabilizationLevel {
  none,
  minimalCrop,
  recommended,
  mostStable,
  custom,
}

extension StabilizationLevelExtension on StabilizationLevel {
  String get label {
    switch (this) {
      case StabilizationLevel.none:
        return 'Off';
      case StabilizationLevel.minimalCrop:
        return 'Minimal Crop';
      case StabilizationLevel.recommended:
        return 'Recommended';
      case StabilizationLevel.mostStable:
        return 'Most Stable';
      case StabilizationLevel.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case StabilizationLevel.none:
        return 'No camera motion dampening applied';
      case StabilizationLevel.minimalCrop:
        return 'Preserves maximum field of view (~4% crop) for mild hand tremors';
      case StabilizationLevel.recommended:
        return 'Balanced tripod simulation (~10% crop) for walking and vlogs';
      case StabilizationLevel.mostStable:
        return 'Heavy gimbal dampening (~18% crop) for running, action, and sports';
      case StabilizationLevel.custom:
        return 'Manual control over smoothing radius, dampening axes, and crop margin';
    }
  }

  double get defaultSmoothing {
    switch (this) {
      case StabilizationLevel.none:
        return 0.0;
      case StabilizationLevel.minimalCrop:
        return 0.35;
      case StabilizationLevel.recommended:
        return 0.65;
      case StabilizationLevel.mostStable:
        return 0.90;
      case StabilizationLevel.custom:
        return 0.60;
    }
  }

  double get defaultCropMargin {
    switch (this) {
      case StabilizationLevel.none:
        return 0.0;
      case StabilizationLevel.minimalCrop:
        return 0.04;
      case StabilizationLevel.recommended:
        return 0.10;
      case StabilizationLevel.mostStable:
        return 0.18;
      case StabilizationLevel.custom:
        return 0.10;
    }
  }
}

/// Gyro Flow & Motion Estimation Algorithm
enum StabilizationAlgorithm {
  gyroFlow,
  opticalDeshake,
  warpPerspective,
}

extension StabilizationAlgorithmExtension on StabilizationAlgorithm {
  String get label {
    switch (this) {
      case StabilizationAlgorithm.gyroFlow:
        return 'Gyro Flow';
      case StabilizationAlgorithm.opticalDeshake:
        return 'Optical Deshake';
      case StabilizationAlgorithm.warpPerspective:
        return 'Warp Stabilizer';
    }
  }

  String get description {
    switch (this) {
      case StabilizationAlgorithm.gyroFlow:
        return 'Multi-axis rotational gyro velocity smoothing';
      case StabilizationAlgorithm.opticalDeshake:
        return 'Translational and rotational block vector correlation';
      case StabilizationAlgorithm.warpPerspective:
        return 'Sub-region perspective warp with rolling shutter correction';
    }
  }
}

/// Boundary Edge Treatment Mode
enum EdgePaddingMode {
  adaptiveCrop,
  mirrorEdge,
  blurredMargin,
}

extension EdgePaddingModeExtension on EdgePaddingMode {
  String get label {
    switch (this) {
      case EdgePaddingMode.adaptiveCrop:
        return 'Adaptive Zoom Crop';
      case EdgePaddingMode.mirrorEdge:
        return 'Reflective Mirror Edges';
      case EdgePaddingMode.blurredMargin:
        return 'Blurred Boundary Fill';
    }
  }
}

/// CapCut Pro AI Video Stabilization Configuration Model
class StabilizationConfig extends Equatable {
  final bool isEnabled;
  final StabilizationLevel level;
  final StabilizationAlgorithm algorithm;
  final EdgePaddingMode edgeMode;
  final double smoothingStrength; // 0.0 to 1.0 (temporal dampening factor)
  final double cropMargin; // 0.0 to 0.30 (zoom margin to eliminate missing edges)
  final double pitchYawDampening; // 0.0 to 1.0 (vertical and horizontal wobble dampening)
  final double rollDampening; // 0.0 to 1.0 (rotational horizon stabilization)
  final bool rollingShutterCorrection; // Compensates for CMOS sensor rolling shutter jello
  final bool isAnalyzing; // True while optical flow motion vectors are being analyzed

  const StabilizationConfig({
    this.isEnabled = false,
    this.level = StabilizationLevel.none,
    this.algorithm = StabilizationAlgorithm.gyroFlow,
    this.edgeMode = EdgePaddingMode.adaptiveCrop,
    this.smoothingStrength = 0.65,
    this.cropMargin = 0.10,
    this.pitchYawDampening = 0.75,
    this.rollDampening = 0.85,
    this.rollingShutterCorrection = true,
    this.isAnalyzing = false,
  });

  /// Factory helper for instantiating preset levels
  static StabilizationConfig fromLevel(StabilizationLevel level) {
    if (level == StabilizationLevel.none) {
      return const StabilizationConfig();
    }
    return StabilizationConfig(
      isEnabled: true,
      level: level,
      smoothingStrength: level.defaultSmoothing,
      cropMargin: level.defaultCropMargin,
    );
  }

  StabilizationConfig copyWith({
    bool? isEnabled,
    StabilizationLevel? level,
    StabilizationAlgorithm? algorithm,
    EdgePaddingMode? edgeMode,
    double? smoothingStrength,
    double? cropMargin,
    double? pitchYawDampening,
    double? rollDampening,
    bool? rollingShutterCorrection,
    bool? isAnalyzing,
  }) {
    return StabilizationConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      level: level ?? this.level,
      algorithm: algorithm ?? this.algorithm,
      edgeMode: edgeMode ?? this.edgeMode,
      smoothingStrength: smoothingStrength ?? this.smoothingStrength,
      cropMargin: cropMargin ?? this.cropMargin,
      pitchYawDampening: pitchYawDampening ?? this.pitchYawDampening,
      rollDampening: rollDampening ?? this.rollDampening,
      rollingShutterCorrection: rollingShutterCorrection ?? this.rollingShutterCorrection,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'level': level.index,
      'algorithm': algorithm.index,
      'edgeMode': edgeMode.index,
      'smoothingStrength': smoothingStrength,
      'cropMargin': cropMargin,
      'pitchYawDampening': pitchYawDampening,
      'rollDampening': rollDampening,
      'rollingShutterCorrection': rollingShutterCorrection,
      'isAnalyzing': isAnalyzing,
    };
  }

  factory StabilizationConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StabilizationConfig();

    return StabilizationConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      level: json['level'] != null && json['level'] is int
          ? StabilizationLevel.values[(json['level'] as int).clamp(0, StabilizationLevel.values.length - 1)]
          : StabilizationLevel.none,
      algorithm: json['algorithm'] != null && json['algorithm'] is int
          ? StabilizationAlgorithm.values[(json['algorithm'] as int).clamp(0, StabilizationAlgorithm.values.length - 1)]
          : StabilizationAlgorithm.gyroFlow,
      edgeMode: json['edgeMode'] != null && json['edgeMode'] is int
          ? EdgePaddingMode.values[(json['edgeMode'] as int).clamp(0, EdgePaddingMode.values.length - 1)]
          : EdgePaddingMode.adaptiveCrop,
      smoothingStrength: (json['smoothingStrength'] as num?)?.toDouble() ?? 0.65,
      cropMargin: (json['cropMargin'] as num?)?.toDouble() ?? 0.10,
      pitchYawDampening: (json['pitchYawDampening'] as num?)?.toDouble() ?? 0.75,
      rollDampening: (json['rollDampening'] as num?)?.toDouble() ?? 0.85,
      rollingShutterCorrection: json['rollingShutterCorrection'] as bool? ?? true,
      isAnalyzing: json['isAnalyzing'] as bool? ?? false,
    );
  }

  String get badge {
    if (!isEnabled || level == StabilizationLevel.none) return '';
    final levelStr = level.label.toUpperCase();
    final cropPercent = (cropMargin * 100).round();
    final algoStr = algorithm == StabilizationAlgorithm.gyroFlow ? 'GYRO' : 'DESHAKE';
    return '🎯 STABILIZED ($levelStr • $cropPercent% CROP • $algoStr)';
  }

  @override
  List<Object?> get props => [
        isEnabled,
        level,
        algorithm,
        edgeMode,
        smoothingStrength,
        cropMargin,
        pitchYawDampening,
        rollDampening,
        rollingShutterCorrection,
        isAnalyzing,
      ];
}
