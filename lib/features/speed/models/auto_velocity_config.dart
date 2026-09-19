import 'package:equatable/equatable.dart';

enum AutoVelocityStyle {
  classic,
  phonkTrap,
  hyperDrift,
  stutterBpm,
  lofiChill,
}

extension AutoVelocityStyleExtension on AutoVelocityStyle {
  String get label {
    switch (this) {
      case AutoVelocityStyle.classic:
        return 'Classic Velocity';
      case AutoVelocityStyle.phonkTrap:
        return 'Phonk & Trap Rush';
      case AutoVelocityStyle.hyperDrift:
        return 'Hyper-Drift Slow-Mo';
      case AutoVelocityStyle.stutterBpm:
        return 'Stutter BPM 1/2 Beat';
      case AutoVelocityStyle.lofiChill:
        return 'Lofi Chill Ebb & Flow';
    }
  }

  String get description {
    switch (this) {
      case AutoVelocityStyle.classic:
        return 'Alternating smooth slow-mo buildup into sharp velocity surge on each beat';
      case AutoVelocityStyle.phonkTrap:
        return 'Aggressive 6x speed bursts with white exposure flashes and camera micro-zooms';
      case AutoVelocityStyle.hyperDrift:
        return 'Liquid optical flow slow-mo (0.25x) snapped to 3x beat acceleration';
      case AutoVelocityStyle.stutterBpm:
        return 'Rapid rhythmic double-bursts synchronized to half-beat subdivisions';
      case AutoVelocityStyle.lofiChill:
        return 'Mellow organic ebb and flow (0.7x to 1.5x) with gentle pulse';
    }
  }
}

enum VelocityInterval {
  everyBeat,  // 1/1
  halfBeat,   // 1/2
  doubleBeat, // 2/1
}

class AutoVelocityConfig extends Equatable {
  final bool isEnabled;
  final AutoVelocityStyle style;
  final VelocityInterval interval;
  final double slowSpeed;         // 0.1x to 0.9x
  final double fastSpeed;         // 1.5x to 8.0x
  final bool enableSmoothSlowMo;  // Optical flow frame interpolation
  final bool enableFlashPulse;    // White exposure burst on beat drop
  final double flashIntensity;    // 0.0 to 1.0
  final bool enableMicroZoom;     // Camera punch-in shockwave on beat drop
  final double microZoomFactor;   // 1.02 to 1.25
  final bool enableRgbGlitch;     // Chromatic aberration on peak velocity

  const AutoVelocityConfig({
    this.isEnabled = false,
    this.style = AutoVelocityStyle.classic,
    this.interval = VelocityInterval.everyBeat,
    this.slowSpeed = 0.35,
    this.fastSpeed = 3.5,
    this.enableSmoothSlowMo = true,
    this.enableFlashPulse = true,
    this.flashIntensity = 0.70,
    this.enableMicroZoom = true,
    this.microZoomFactor = 1.08,
    this.enableRgbGlitch = false,
  });

  // --- CapCut Signature Auto-Velocity Presets ---

  static const AutoVelocityConfig presetClassic = AutoVelocityConfig(
    isEnabled: true,
    style: AutoVelocityStyle.classic,
    interval: VelocityInterval.everyBeat,
    slowSpeed: 0.35,
    fastSpeed: 3.5,
    enableSmoothSlowMo: true,
    enableFlashPulse: true,
    flashIntensity: 0.60,
    enableMicroZoom: true,
    microZoomFactor: 1.08,
  );

  static const AutoVelocityConfig presetPhonkTrap = AutoVelocityConfig(
    isEnabled: true,
    style: AutoVelocityStyle.phonkTrap,
    interval: VelocityInterval.everyBeat,
    slowSpeed: 0.20,
    fastSpeed: 6.0,
    enableSmoothSlowMo: true,
    enableFlashPulse: true,
    flashIntensity: 0.90,
    enableMicroZoom: true,
    microZoomFactor: 1.15,
    enableRgbGlitch: true,
  );

  static const AutoVelocityConfig presetHyperDrift = AutoVelocityConfig(
    isEnabled: true,
    style: AutoVelocityStyle.hyperDrift,
    interval: VelocityInterval.everyBeat,
    slowSpeed: 0.25,
    fastSpeed: 3.0,
    enableSmoothSlowMo: true,
    enableFlashPulse: false,
    flashIntensity: 0.0,
    enableMicroZoom: true,
    microZoomFactor: 1.06,
  );

  static const AutoVelocityConfig presetStutterBpm = AutoVelocityConfig(
    isEnabled: true,
    style: AutoVelocityStyle.stutterBpm,
    interval: VelocityInterval.halfBeat,
    slowSpeed: 0.40,
    fastSpeed: 4.5,
    enableSmoothSlowMo: false,
    enableFlashPulse: true,
    flashIntensity: 0.75,
    enableMicroZoom: true,
    microZoomFactor: 1.10,
  );

  static const AutoVelocityConfig presetLofiChill = AutoVelocityConfig(
    isEnabled: true,
    style: AutoVelocityStyle.lofiChill,
    interval: VelocityInterval.everyBeat,
    slowSpeed: 0.70,
    fastSpeed: 1.50,
    enableSmoothSlowMo: true,
    enableFlashPulse: false,
    flashIntensity: 0.0,
    enableMicroZoom: false,
    microZoomFactor: 1.0,
  );

  AutoVelocityConfig copyWith({
    bool? isEnabled,
    AutoVelocityStyle? style,
    VelocityInterval? interval,
    double? slowSpeed,
    double? fastSpeed,
    bool? enableSmoothSlowMo,
    bool? enableFlashPulse,
    double? flashIntensity,
    bool? enableMicroZoom,
    double? microZoomFactor,
    bool? enableRgbGlitch,
  }) {
    return AutoVelocityConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      style: style ?? this.style,
      interval: interval ?? this.interval,
      slowSpeed: slowSpeed ?? this.slowSpeed,
      fastSpeed: fastSpeed ?? this.fastSpeed,
      enableSmoothSlowMo: enableSmoothSlowMo ?? this.enableSmoothSlowMo,
      enableFlashPulse: enableFlashPulse ?? this.enableFlashPulse,
      flashIntensity: flashIntensity ?? this.flashIntensity,
      enableMicroZoom: enableMicroZoom ?? this.enableMicroZoom,
      microZoomFactor: microZoomFactor ?? this.microZoomFactor,
      enableRgbGlitch: enableRgbGlitch ?? this.enableRgbGlitch,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'style': style.name,
        'interval': interval.name,
        'slowSpeed': slowSpeed,
        'fastSpeed': fastSpeed,
        'enableSmoothSlowMo': enableSmoothSlowMo,
        'enableFlashPulse': enableFlashPulse,
        'flashIntensity': flashIntensity,
        'enableMicroZoom': enableMicroZoom,
        'microZoomFactor': microZoomFactor,
        'enableRgbGlitch': enableRgbGlitch,
      };

  factory AutoVelocityConfig.fromJson(Map<String, dynamic> json) => AutoVelocityConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        style: AutoVelocityStyle.values.firstWhere(
          (e) => e.name == json['style'],
          orElse: () => AutoVelocityStyle.classic,
        ),
        interval: VelocityInterval.values.firstWhere(
          (e) => e.name == json['interval'],
          orElse: () => VelocityInterval.everyBeat,
        ),
        slowSpeed: (json['slowSpeed'] as num?)?.toDouble() ?? 0.35,
        fastSpeed: (json['fastSpeed'] as num?)?.toDouble() ?? 3.5,
        enableSmoothSlowMo: json['enableSmoothSlowMo'] as bool? ?? true,
        enableFlashPulse: json['enableFlashPulse'] as bool? ?? true,
        flashIntensity: (json['flashIntensity'] as num?)?.toDouble() ?? 0.70,
        enableMicroZoom: json['enableMicroZoom'] as bool? ?? true,
        microZoomFactor: (json['microZoomFactor'] as num?)?.toDouble() ?? 1.08,
        enableRgbGlitch: json['enableRgbGlitch'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        isEnabled,
        style,
        interval,
        slowSpeed,
        fastSpeed,
        enableSmoothSlowMo,
        enableFlashPulse,
        flashIntensity,
        enableMicroZoom,
        microZoomFactor,
        enableRgbGlitch,
      ];
}
