import 'package:equatable/equatable.dart';

/// Modes of motion blur and temporal echo decay smearing.
enum EchoMotionMode {
  smoothMotionBlur,
  longExposureGhost,
  phantomEcho,
  lightTrailSmear,
  dreamySlowShutter,
}

extension EchoMotionModeExtension on EchoMotionMode {
  String get label {
    switch (this) {
      case EchoMotionMode.smoothMotionBlur:
        return 'Smooth Blur';
      case EchoMotionMode.longExposureGhost:
        return 'Long Exposure';
      case EchoMotionMode.phantomEcho:
        return 'Phantom Echo';
      case EchoMotionMode.lightTrailSmear:
        return 'Light Trails';
      case EchoMotionMode.dreamySlowShutter:
        return 'Slow Shutter';
    }
  }

  String get description {
    switch (this) {
      case EchoMotionMode.smoothMotionBlur:
        return 'Natural action motion blur simulating high camera shutter angle';
      case EchoMotionMode.longExposureGhost:
        return 'Luminous ghost trails lingering smoothly behind moving subjects';
      case EchoMotionMode.phantomEcho:
        return 'Discrete stepped temporal echo silhouettes drifting behind motion';
      case EchoMotionMode.lightTrailSmear:
        return 'Specular neon and highlight streaks smeared across dark scenes';
      case EchoMotionMode.dreamySlowShutter:
        return 'Cinematic step-printed slow shutter blur with dreamy frame blending';
    }
  }

  String get iconAsset {
    switch (this) {
      case EchoMotionMode.smoothMotionBlur:
        return 'blur_on';
      case EchoMotionMode.longExposureGhost:
        return 'auto_awesome_motion';
      case EchoMotionMode.phantomEcho:
        return 'layers';
      case EchoMotionMode.lightTrailSmear:
        return 'flare';
      case EchoMotionMode.dreamySlowShutter:
        return 'shutter_speed';
    }
  }
}

/// Configuration for motion blur and temporal echo decay trails.
class EchoMotionConfig extends Equatable {
  final bool isEnabled;
  final EchoMotionMode mode;
  final double decay; // 0.1 to 0.98 persistence decay factor
  final int trailCount; // 2 to 12 temporal ghost taps
  final double shutterAngle; // 45.0 to 360.0 degrees
  final double lumaThreshold; // 0.0 to 1.0 highlight threshold
  final double opacity; // 0.0 to 1.0 blend opacity

  bool get isActive => isEnabled;

  const EchoMotionConfig({
    this.isEnabled = false,
    this.mode = EchoMotionMode.smoothMotionBlur,
    this.decay = 0.65,
    this.trailCount = 5,
    this.shutterAngle = 180.0,
    this.lumaThreshold = 0.2,
    this.opacity = 0.85,
  });

  EchoMotionConfig copyWith({
    bool? isEnabled,
    EchoMotionMode? mode,
    double? decay,
    int? trailCount,
    double? shutterAngle,
    double? lumaThreshold,
    double? opacity,
  }) {
    return EchoMotionConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      decay: decay ?? this.decay,
      trailCount: trailCount ?? this.trailCount,
      shutterAngle: shutterAngle ?? this.shutterAngle,
      lumaThreshold: lumaThreshold ?? this.lumaThreshold,
      opacity: opacity ?? this.opacity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'decay': decay,
      'trailCount': trailCount,
      'shutterAngle': shutterAngle,
      'lumaThreshold': lumaThreshold,
      'opacity': opacity,
    };
  }

  factory EchoMotionConfig.fromJson(Map<String, dynamic> json) {
    return EchoMotionConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: EchoMotionMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => EchoMotionMode.smoothMotionBlur,
      ),
      decay: (json['decay'] as num?)?.toDouble() ?? 0.65,
      trailCount: (json['trailCount'] as num?)?.toInt() ?? 5,
      shutterAngle: (json['shutterAngle'] as num?)?.toDouble() ?? 180.0,
      lumaThreshold: (json['lumaThreshold'] as num?)?.toDouble() ?? 0.2,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.85,
    );
  }

  // Preset Configurations
  static const EchoMotionConfig naturalActionBlur = EchoMotionConfig(
    isEnabled: true,
    mode: EchoMotionMode.smoothMotionBlur,
    decay: 0.50,
    trailCount: 4,
    shutterAngle: 180.0,
    lumaThreshold: 0.1,
    opacity: 0.80,
  );

  static const EchoMotionConfig neonLightTrails = EchoMotionConfig(
    isEnabled: true,
    mode: EchoMotionMode.lightTrailSmear,
    decay: 0.85,
    trailCount: 8,
    shutterAngle: 270.0,
    lumaThreshold: 0.35,
    opacity: 0.95,
  );

  static const EchoMotionConfig spectralGhost = EchoMotionConfig(
    isEnabled: true,
    mode: EchoMotionMode.longExposureGhost,
    decay: 0.78,
    trailCount: 7,
    shutterAngle: 360.0,
    lumaThreshold: 0.15,
    opacity: 0.90,
  );

  static const EchoMotionConfig multiPhantomEcho = EchoMotionConfig(
    isEnabled: true,
    mode: EchoMotionMode.phantomEcho,
    decay: 0.60,
    trailCount: 6,
    shutterAngle: 220.0,
    lumaThreshold: 0.25,
    opacity: 0.85,
  );

  static const EchoMotionConfig vintageSlowShutter = EchoMotionConfig(
    isEnabled: true,
    mode: EchoMotionMode.dreamySlowShutter,
    decay: 0.72,
    trailCount: 5,
    shutterAngle: 300.0,
    lumaThreshold: 0.20,
    opacity: 0.88,
  );

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        decay,
        trailCount,
        shutterAngle,
        lumaThreshold,
        opacity,
      ];
}
