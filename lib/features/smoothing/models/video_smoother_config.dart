import 'package:equatable/equatable.dart';

enum SmootherPreset {
  standard,
  gimbalSmooth,
  motion60fps,
  antiGlitch,
  extremeAction,
}

extension SmootherPresetExtension on SmootherPreset {
  String get label {
    switch (this) {
      case SmootherPreset.standard:
        return 'Standard Smooth';
      case SmootherPreset.gimbalSmooth:
        return 'Gimbal Stabilizer';
      case SmootherPreset.motion60fps:
        return '60 FPS Fluid Motion';
      case SmootherPreset.antiGlitch:
        return 'Anti-Glitch & De-Flutter';
      case SmootherPreset.extremeAction:
        return 'Action Sports Stabilizer';
    }
  }

  String get description {
    switch (this) {
      case SmootherPreset.standard:
        return 'Balanced anti-jitter and motion normalization';
      case SmootherPreset.gimbalSmooth:
        return 'Eliminates camera shake and walking bounce like a 3-axis gimbal';
      case SmootherPreset.motion60fps:
        return 'AI optical-flow frame rate interpolation for butter-smooth movement';
      case SmootherPreset.antiGlitch:
        return 'Removes stutter, dropped frames, and sensor light flutter';
      case SmootherPreset.extremeAction:
        return 'Heavy rotational and translational stabilization for high-speed action';
    }
  }
}

class VideoSmootherConfig extends Equatable {
  final bool isStabilizationEnabled;        // Anti-shake / camera flutter stabilizer
  final double stabilizationStrength;      // 0.1 to 1.0 (default 0.75)
  final bool isMotionSmoothingEnabled;     // 60 FPS Optical flow frame interpolation
  final int targetFps;                     // 30, 60, 120
  final bool isDeGlitchEnabled;            // Removes frame stutter, jitter & dropped frames
  final bool isDeFlickerEnabled;           // Removes LED and rolling shutter flicker
  final SmootherPreset preset;

  const VideoSmootherConfig({
    this.isStabilizationEnabled = false,
    this.stabilizationStrength = 0.75,
    this.isMotionSmoothingEnabled = false,
    this.targetFps = 60,
    this.isDeGlitchEnabled = false,
    this.isDeFlickerEnabled = false,
    this.preset = SmootherPreset.standard,
  });

  bool get hasActiveSmoothing =>
      isStabilizationEnabled ||
      isMotionSmoothingEnabled ||
      isDeGlitchEnabled ||
      isDeFlickerEnabled;

  VideoSmootherConfig copyWith({
    bool? isStabilizationEnabled,
    double? stabilizationStrength,
    bool? isMotionSmoothingEnabled,
    int? targetFps,
    bool? isDeGlitchEnabled,
    bool? isDeFlickerEnabled,
    SmootherPreset? preset,
  }) {
    return VideoSmootherConfig(
      isStabilizationEnabled: isStabilizationEnabled ?? this.isStabilizationEnabled,
      stabilizationStrength: stabilizationStrength ?? this.stabilizationStrength,
      isMotionSmoothingEnabled: isMotionSmoothingEnabled ?? this.isMotionSmoothingEnabled,
      targetFps: targetFps ?? this.targetFps,
      isDeGlitchEnabled: isDeGlitchEnabled ?? this.isDeGlitchEnabled,
      isDeFlickerEnabled: isDeFlickerEnabled ?? this.isDeFlickerEnabled,
      preset: preset ?? this.preset,
    );
  }

  Map<String, dynamic> toJson() => {
        'isStabilizationEnabled': isStabilizationEnabled,
        'stabilizationStrength': stabilizationStrength,
        'isMotionSmoothingEnabled': isMotionSmoothingEnabled,
        'targetFps': targetFps,
        'isDeGlitchEnabled': isDeGlitchEnabled,
        'isDeFlickerEnabled': isDeFlickerEnabled,
        'preset': preset.name,
      };

  factory VideoSmootherConfig.fromJson(Map<String, dynamic> json) => VideoSmootherConfig(
        isStabilizationEnabled: json['isStabilizationEnabled'] as bool? ?? false,
        stabilizationStrength: (json['stabilizationStrength'] as num?)?.toDouble() ?? 0.75,
        isMotionSmoothingEnabled: json['isMotionSmoothingEnabled'] as bool? ?? false,
        targetFps: (json['targetFps'] as num?)?.toInt() ?? 60,
        isDeGlitchEnabled: json['isDeGlitchEnabled'] as bool? ?? false,
        isDeFlickerEnabled: json['isDeFlickerEnabled'] as bool? ?? false,
        preset: SmootherPreset.values.firstWhere(
          (p) => p.name == json['preset'],
          orElse: () => SmootherPreset.standard,
        ),
      );

  @override
  List<Object?> get props => [
        isStabilizationEnabled,
        stabilizationStrength,
        isMotionSmoothingEnabled,
        targetFps,
        isDeGlitchEnabled,
        isDeFlickerEnabled,
        preset,
      ];
}
