import 'package:equatable/equatable.dart';

enum MotionInterpolationMode {
  none,
  frameBlend,
  opticalFlow,
}

extension MotionInterpolationModeExtension on MotionInterpolationMode {
  String get label {
    switch (this) {
      case MotionInterpolationMode.none:
        return 'Native Off';
      case MotionInterpolationMode.frameBlend:
        return 'Frame Blend (Linear)';
      case MotionInterpolationMode.opticalFlow:
        return 'Optical Flow (MCI)';
    }
  }

  String get description {
    switch (this) {
      case MotionInterpolationMode.none:
        return 'Maintains original recorded camera cadence';
      case MotionInterpolationMode.frameBlend:
        return 'Linear temporal crossfade between adjacent frames to reduce stutter';
      case MotionInterpolationMode.opticalFlow:
        return 'Bidirectional motion vector synthesis for buttery ultra-smooth slow motion';
    }
  }
}

enum MotionBlurDirection {
  omnidirectional,
  horizontal,
  vertical,
}

extension MotionBlurDirectionExtension on MotionBlurDirection {
  String get label {
    switch (this) {
      case MotionBlurDirection.omnidirectional:
        return 'Omnidirectional';
      case MotionBlurDirection.horizontal:
        return 'Horizontal Pan';
      case MotionBlurDirection.vertical:
        return 'Vertical Tilt';
    }
  }
}

enum SmootherPreset {
  standard,
  cinema180Shutter,
  action90Shutter,
  motion60fps,
  hyper120fps,
  dreamyStreak360,
  frameBlendNatural,
  gimbalSmooth,
  antiGlitch,
  extremeAction,
}

extension SmootherPresetExtension on SmootherPreset {
  String get label {
    switch (this) {
      case SmootherPreset.standard:
        return 'Standard Smooth';
      case SmootherPreset.cinema180Shutter:
        return '180° Cinema Shutter';
      case SmootherPreset.action90Shutter:
        return 'Action 90° Crisp';
      case SmootherPreset.motion60fps:
        return '60 FPS Optical Flow';
      case SmootherPreset.hyper120fps:
        return '120 FPS Buttery Flow';
      case SmootherPreset.dreamyStreak360:
        return '360° Velocity Streak';
      case SmootherPreset.frameBlendNatural:
        return 'Natural Frame Blend';
      case SmootherPreset.gimbalSmooth:
        return 'Gimbal Stabilizer';
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
      case SmootherPreset.cinema180Shutter:
        return 'Classic Hollywood 180° shutter angle natural velocity motion blur';
      case SmootherPreset.action90Shutter:
        return 'High shutter speed for razor-sharp action clarity';
      case SmootherPreset.motion60fps:
        return 'AI optical-flow frame rate interpolation for butter-smooth movement';
      case SmootherPreset.hyper120fps:
        return '120 FPS high-frame-rate slow motion with motion-compensated interpolation';
      case SmootherPreset.dreamyStreak360:
        return 'Artistic 360° maximum shutter angle speed trail and velocity streaks';
      case SmootherPreset.frameBlendNatural:
        return 'Smooth crossfade temporal blending between adjacent frames';
      case SmootherPreset.gimbalSmooth:
        return 'Eliminates camera shake and walking bounce like a 3-axis gimbal';
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
  final bool isMotionSmoothingEnabled;     // Backward-compatible optical flow flag
  final MotionInterpolationMode interpolationMode; // none, frameBlend, opticalFlow
  final int targetFps;                     // 30, 60, 120, 240
  final bool isMotionBlurEnabled;          // Velocity shutter angle motion blur
  final double shutterAngle;               // 0.0 to 360.0 degrees (default 180.0)
  final int motionBlurSamples;             // 2 to 16 samples (default 6)
  final double motionBlurIntensity;        // 0.0 to 1.0 (default 0.65)
  final MotionBlurDirection motionBlurDirection; // omnidirectional, horizontal, vertical
  final bool isDeGlitchEnabled;            // Removes frame stutter, jitter & dropped frames
  final bool isDeFlickerEnabled;           // Removes LED and rolling shutter flicker
  final SmootherPreset preset;

  const VideoSmootherConfig({
    this.isStabilizationEnabled = false,
    this.stabilizationStrength = 0.75,
    this.isMotionSmoothingEnabled = false,
    this.interpolationMode = MotionInterpolationMode.none,
    this.targetFps = 60,
    this.isMotionBlurEnabled = false,
    this.shutterAngle = 180.0,
    this.motionBlurSamples = 6,
    this.motionBlurIntensity = 0.65,
    this.motionBlurDirection = MotionBlurDirection.omnidirectional,
    this.isDeGlitchEnabled = false,
    this.isDeFlickerEnabled = false,
    this.preset = SmootherPreset.standard,
  });

  bool get hasActiveSmoothing =>
      isStabilizationEnabled ||
      isMotionSmoothingEnabled ||
      interpolationMode != MotionInterpolationMode.none ||
      isMotionBlurEnabled ||
      isDeGlitchEnabled ||
      isDeFlickerEnabled;

  /// Resolves the active effective interpolation engine
  MotionInterpolationMode get effectiveInterpolationMode {
    if (interpolationMode != MotionInterpolationMode.none) {
      return interpolationMode;
    }
    if (isMotionSmoothingEnabled) {
      return MotionInterpolationMode.opticalFlow;
    }
    return MotionInterpolationMode.none;
  }

  static VideoSmootherConfig getPresetConfig(SmootherPreset preset) {
    switch (preset) {
      case SmootherPreset.cinema180Shutter:
        return const VideoSmootherConfig(
          preset: SmootherPreset.cinema180Shutter,
          isMotionBlurEnabled: true,
          shutterAngle: 180.0,
          motionBlurSamples: 8,
          motionBlurIntensity: 0.70,
          motionBlurDirection: MotionBlurDirection.omnidirectional,
        );
      case SmootherPreset.action90Shutter:
        return const VideoSmootherConfig(
          preset: SmootherPreset.action90Shutter,
          isMotionBlurEnabled: true,
          shutterAngle: 90.0,
          motionBlurSamples: 4,
          motionBlurIntensity: 0.40,
          isStabilizationEnabled: true,
          stabilizationStrength: 0.65,
        );
      case SmootherPreset.motion60fps:
        return const VideoSmootherConfig(
          preset: SmootherPreset.motion60fps,
          isMotionSmoothingEnabled: true,
          interpolationMode: MotionInterpolationMode.opticalFlow,
          targetFps: 60,
        );
      case SmootherPreset.hyper120fps:
        return const VideoSmootherConfig(
          preset: SmootherPreset.hyper120fps,
          isMotionSmoothingEnabled: true,
          interpolationMode: MotionInterpolationMode.opticalFlow,
          targetFps: 120,
        );
      case SmootherPreset.dreamyStreak360:
        return const VideoSmootherConfig(
          preset: SmootherPreset.dreamyStreak360,
          isMotionBlurEnabled: true,
          shutterAngle: 360.0,
          motionBlurSamples: 12,
          motionBlurIntensity: 1.0,
          motionBlurDirection: MotionBlurDirection.horizontal,
        );
      case SmootherPreset.frameBlendNatural:
        return const VideoSmootherConfig(
          preset: SmootherPreset.frameBlendNatural,
          interpolationMode: MotionInterpolationMode.frameBlend,
          targetFps: 60,
        );
      case SmootherPreset.gimbalSmooth:
        return const VideoSmootherConfig(
          preset: SmootherPreset.gimbalSmooth,
          isStabilizationEnabled: true,
          stabilizationStrength: 0.85,
        );
      case SmootherPreset.antiGlitch:
        return const VideoSmootherConfig(
          preset: SmootherPreset.antiGlitch,
          isDeGlitchEnabled: true,
          isDeFlickerEnabled: true,
        );
      case SmootherPreset.extremeAction:
        return const VideoSmootherConfig(
          preset: SmootherPreset.extremeAction,
          isStabilizationEnabled: true,
          stabilizationStrength: 1.0,
          isMotionSmoothingEnabled: true,
          interpolationMode: MotionInterpolationMode.opticalFlow,
          targetFps: 60,
        );
      case SmootherPreset.standard:
        return const VideoSmootherConfig(
          preset: SmootherPreset.standard,
        );
    }
  }

  VideoSmootherConfig copyWith({
    bool? isStabilizationEnabled,
    double? stabilizationStrength,
    bool? isMotionSmoothingEnabled,
    MotionInterpolationMode? interpolationMode,
    int? targetFps,
    bool? isMotionBlurEnabled,
    double? shutterAngle,
    int? motionBlurSamples,
    double? motionBlurIntensity,
    MotionBlurDirection? motionBlurDirection,
    bool? isDeGlitchEnabled,
    bool? isDeFlickerEnabled,
    SmootherPreset? preset,
  }) {
    return VideoSmootherConfig(
      isStabilizationEnabled: isStabilizationEnabled ?? this.isStabilizationEnabled,
      stabilizationStrength: stabilizationStrength ?? this.stabilizationStrength,
      isMotionSmoothingEnabled: isMotionSmoothingEnabled ?? this.isMotionSmoothingEnabled,
      interpolationMode: interpolationMode ?? this.interpolationMode,
      targetFps: targetFps ?? this.targetFps,
      isMotionBlurEnabled: isMotionBlurEnabled ?? this.isMotionBlurEnabled,
      shutterAngle: shutterAngle ?? this.shutterAngle,
      motionBlurSamples: motionBlurSamples ?? this.motionBlurSamples,
      motionBlurIntensity: motionBlurIntensity ?? this.motionBlurIntensity,
      motionBlurDirection: motionBlurDirection ?? this.motionBlurDirection,
      isDeGlitchEnabled: isDeGlitchEnabled ?? this.isDeGlitchEnabled,
      isDeFlickerEnabled: isDeFlickerEnabled ?? this.isDeFlickerEnabled,
      preset: preset ?? this.preset,
    );
  }

  Map<String, dynamic> toJson() => {
        'isStabilizationEnabled': isStabilizationEnabled,
        'stabilizationStrength': stabilizationStrength,
        'isMotionSmoothingEnabled': isMotionSmoothingEnabled,
        'interpolationMode': interpolationMode.name,
        'targetFps': targetFps,
        'isMotionBlurEnabled': isMotionBlurEnabled,
        'shutterAngle': shutterAngle,
        'motionBlurSamples': motionBlurSamples,
        'motionBlurIntensity': motionBlurIntensity,
        'motionBlurDirection': motionBlurDirection.name,
        'isDeGlitchEnabled': isDeGlitchEnabled,
        'isDeFlickerEnabled': isDeFlickerEnabled,
        'preset': preset.name,
      };

  factory VideoSmootherConfig.fromJson(Map<String, dynamic> json) {
    final rawInterp = json['interpolationMode'];
    final legacySmooth = json['isMotionSmoothingEnabled'] as bool? ?? false;

    MotionInterpolationMode interp = MotionInterpolationMode.none;
    if (rawInterp != null) {
      interp = MotionInterpolationMode.values.firstWhere(
        (m) => m.name == rawInterp,
        orElse: () => MotionInterpolationMode.none,
      );
    } else if (legacySmooth) {
      interp = MotionInterpolationMode.opticalFlow;
    }

    final rawDir = json['motionBlurDirection'];
    final direction = MotionBlurDirection.values.firstWhere(
      (d) => d.name == rawDir,
      orElse: () => MotionBlurDirection.omnidirectional,
    );

    return VideoSmootherConfig(
      isStabilizationEnabled: json['isStabilizationEnabled'] as bool? ?? false,
      stabilizationStrength: (json['stabilizationStrength'] as num?)?.toDouble() ?? 0.75,
      isMotionSmoothingEnabled: legacySmooth,
      interpolationMode: interp,
      targetFps: (json['targetFps'] as num?)?.toInt() ?? 60,
      isMotionBlurEnabled: json['isMotionBlurEnabled'] as bool? ?? false,
      shutterAngle: (json['shutterAngle'] as num?)?.toDouble() ?? 180.0,
      motionBlurSamples: (json['motionBlurSamples'] as num?)?.toInt() ?? 6,
      motionBlurIntensity: (json['motionBlurIntensity'] as num?)?.toDouble() ?? 0.65,
      motionBlurDirection: direction,
      isDeGlitchEnabled: json['isDeGlitchEnabled'] as bool? ?? false,
      isDeFlickerEnabled: json['isDeFlickerEnabled'] as bool? ?? false,
      preset: SmootherPreset.values.firstWhere(
        (p) => p.name == json['preset'],
        orElse: () => SmootherPreset.standard,
      ),
    );
  }

  @override
  List<Object?> get props => [
        isStabilizationEnabled,
        stabilizationStrength,
        isMotionSmoothingEnabled,
        interpolationMode,
        targetFps,
        isMotionBlurEnabled,
        shutterAngle,
        motionBlurSamples,
        motionBlurIntensity,
        motionBlurDirection,
        isDeGlitchEnabled,
        isDeFlickerEnabled,
        preset,
      ];
}
