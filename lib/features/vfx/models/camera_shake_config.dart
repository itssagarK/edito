import 'package:equatable/equatable.dart';

enum CameraShakeType {
  handheld,
  earthquake,
  carBumpy,
  heartbeatPulse,
  impactTremor;

  String get displayName {
    switch (this) {
      case CameraShakeType.handheld:
        return 'Organic Handheld';
      case CameraShakeType.earthquake:
        return 'Earthquake Shock';
      case CameraShakeType.carBumpy:
        return 'Vehicle Offroad';
      case CameraShakeType.heartbeatPulse:
        return 'Heartbeat Pulse';
      case CameraShakeType.impactTremor:
        return 'Impact Thud Tremor';
    }
  }

  String get description {
    switch (this) {
      case CameraShakeType.handheld:
        return 'Natural documentary handheld camera breathing & drift';
      case CameraShakeType.earthquake:
        return 'High-amplitude violent ground shaking seismic tremor';
      case CameraShakeType.carBumpy:
        return 'Fast erratic mechanical vibration from rough road terrain';
      case CameraShakeType.heartbeatPulse:
        return 'Rhythmic throbbing thump shock for high-tension scenes';
      case CameraShakeType.impactTremor:
        return 'Sudden explosive shockwave decay following a punch or hit';
    }
  }
}

class CameraShakeConfig extends Equatable {
  final bool isEnabled;
  final double intensity; // 0.0 to 1.0 (magnitude)
  final double speed; // 0.2 to 3.0 (frequency multiplier)
  final double rotationShake; // 0.0 to 1.0 (subtle roll jitter)
  final CameraShakeType shakeType;
  final bool motionBlur;

  const CameraShakeConfig({
    this.isEnabled = false,
    this.intensity = 0.40,
    this.speed = 1.0,
    this.rotationShake = 0.25,
    this.shakeType = CameraShakeType.handheld,
    this.motionBlur = true,
  });

  bool get isActive => isEnabled && intensity > 0.01;

  // Built-in presets
  static const CameraShakeConfig gentleHandheld = CameraShakeConfig(
    isEnabled: true,
    intensity: 0.30,
    speed: 0.85,
    rotationShake: 0.15,
    shakeType: CameraShakeType.handheld,
    motionBlur: true,
  );

  static const CameraShakeConfig actionCamTremor = CameraShakeConfig(
    isEnabled: true,
    intensity: 0.65,
    speed: 1.40,
    rotationShake: 0.45,
    shakeType: CameraShakeType.handheld,
    motionBlur: true,
  );

  static const CameraShakeConfig earthquakeShock = CameraShakeConfig(
    isEnabled: true,
    intensity: 0.90,
    speed: 2.10,
    rotationShake: 0.70,
    shakeType: CameraShakeType.earthquake,
    motionBlur: true,
  );

  static const CameraShakeConfig carOffroad = CameraShakeConfig(
    isEnabled: true,
    intensity: 0.55,
    speed: 1.80,
    rotationShake: 0.35,
    shakeType: CameraShakeType.carBumpy,
    motionBlur: true,
  );

  static const CameraShakeConfig impactThud = CameraShakeConfig(
    isEnabled: true,
    intensity: 0.80,
    speed: 1.20,
    rotationShake: 0.50,
    shakeType: CameraShakeType.impactTremor,
    motionBlur: true,
  );

  CameraShakeConfig copyWith({
    bool? isEnabled,
    double? intensity,
    double? speed,
    double? rotationShake,
    CameraShakeType? shakeType,
    bool? motionBlur,
  }) {
    return CameraShakeConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      intensity: intensity ?? this.intensity,
      speed: speed ?? this.speed,
      rotationShake: rotationShake ?? this.rotationShake,
      shakeType: shakeType ?? this.shakeType,
      motionBlur: motionBlur ?? this.motionBlur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'intensity': intensity,
      'speed': speed,
      'rotationShake': rotationShake,
      'shakeType': shakeType.name,
      'motionBlur': motionBlur,
    };
  }

  factory CameraShakeConfig.fromJson(Map<String, dynamic> json) {
    CameraShakeType parsedType = CameraShakeType.handheld;
    if (json['shakeType'] != null) {
      for (final val in CameraShakeType.values) {
        if (val.name == json['shakeType']) {
          parsedType = val;
          break;
        }
      }
    }

    return CameraShakeConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.40,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      rotationShake: (json['rotationShake'] as num?)?.toDouble() ?? 0.25,
      shakeType: parsedType,
      motionBlur: json['motionBlur'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        intensity,
        speed,
        rotationShake,
        shakeType,
        motionBlur,
      ];
}
