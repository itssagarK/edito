import 'package:equatable/equatable.dart';

/// Modes for Sub-Bass 808 saturation and harmonic low-end excitation.
enum SubBassExciterMode {
  club808Punch,
  cinematicSubRumble,
  analogWarmthDrive,
  phoneSpeakerExciter,
  heavyBassDrop,
}

extension SubBassExciterModeExtension on SubBassExciterMode {
  String get label {
    switch (this) {
      case SubBassExciterMode.club808Punch:
        return '808 Club Punch';
      case SubBassExciterMode.cinematicSubRumble:
        return 'Cinematic Rumble';
      case SubBassExciterMode.analogWarmthDrive:
        return 'Analog Tube Drive';
      case SubBassExciterMode.phoneSpeakerExciter:
        return 'Mobile Speaker Pop';
      case SubBassExciterMode.heavyBassDrop:
        return 'Seismic Bass Drop';
    }
  }

  String get description {
    switch (this) {
      case SubBassExciterMode.club808Punch:
        return 'Hard-hitting 808 sub-bass with punchy transient saturation';
      case SubBassExciterMode.cinematicSubRumble:
        return 'Deep 30-50 Hz seismic movie trailer rumble shaking subwoofers';
      case SubBassExciterMode.analogWarmthDrive:
        return 'Warm analog tape even-harmonic saturation rounding out low frequencies';
      case SubBassExciterMode.phoneSpeakerExciter:
        return 'Psychoacoustic 2nd/3rd harmonics making deep sub audible on small phone speakers';
      case SubBassExciterMode.heavyBassDrop:
        return 'Massive seismic low-end boost tailored for EDM and trap impacts';
    }
  }
}

/// Configuration for Sub-Bass 808 saturator and harmonic low-end exciter.
class SubBassExciterConfig extends Equatable {
  final bool isEnabled;
  final SubBassExciterMode mode;
  final double subFrequency; // 30.0 to 120.0 Hz center tuning
  final double subBoostDb; // 0.0 to 18.0 dB boost
  final double driveSaturation; // 0.0 to 1.0 harmonic drive
  final double harmonicsMix; // 0.0 to 1.0 psychoacoustic overtone mix
  final double lowPassCutoff; // 80.0 to 250.0 Hz lowpass filter

  bool get isActive => isEnabled;

  const SubBassExciterConfig({
    this.isEnabled = false,
    this.mode = SubBassExciterMode.club808Punch,
    this.subFrequency = 55.0,
    this.subBoostDb = 6.0,
    this.driveSaturation = 0.35,
    this.harmonicsMix = 0.5,
    this.lowPassCutoff = 140.0,
  });

  SubBassExciterConfig copyWith({
    bool? isEnabled,
    SubBassExciterMode? mode,
    double? subFrequency,
    double? subBoostDb,
    double? driveSaturation,
    double? harmonicsMix,
    double? lowPassCutoff,
  }) {
    return SubBassExciterConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      subFrequency: subFrequency ?? this.subFrequency,
      subBoostDb: subBoostDb ?? this.subBoostDb,
      driveSaturation: driveSaturation ?? this.driveSaturation,
      harmonicsMix: harmonicsMix ?? this.harmonicsMix,
      lowPassCutoff: lowPassCutoff ?? this.lowPassCutoff,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'subFrequency': subFrequency,
      'subBoostDb': subBoostDb,
      'driveSaturation': driveSaturation,
      'harmonicsMix': harmonicsMix,
      'lowPassCutoff': lowPassCutoff,
    };
  }

  factory SubBassExciterConfig.fromJson(Map<String, dynamic> json) {
    return SubBassExciterConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: SubBassExciterMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => SubBassExciterMode.club808Punch,
      ),
      subFrequency: (json['subFrequency'] as num?)?.toDouble() ?? 55.0,
      subBoostDb: (json['subBoostDb'] as num?)?.toDouble() ?? 6.0,
      driveSaturation:
          (json['driveSaturation'] as num?)?.toDouble() ?? 0.35,
      harmonicsMix: (json['harmonicsMix'] as num?)?.toDouble() ?? 0.5,
      lowPassCutoff: (json['lowPassCutoff'] as num?)?.toDouble() ?? 140.0,
    );
  }

  // Presets
  static const SubBassExciterConfig trap808Punch = SubBassExciterConfig(
    isEnabled: true,
    mode: SubBassExciterMode.club808Punch,
    subFrequency: 55.0,
    subBoostDb: 8.0,
    driveSaturation: 0.45,
    harmonicsMix: 0.6,
    lowPassCutoff: 150.0,
  );

  static const SubBassExciterConfig trailerSubDrop = SubBassExciterConfig(
    isEnabled: true,
    mode: SubBassExciterMode.cinematicSubRumble,
    subFrequency: 40.0,
    subBoostDb: 10.0,
    driveSaturation: 0.25,
    harmonicsMix: 0.4,
    lowPassCutoff: 100.0,
  );

  static const SubBassExciterConfig tapeWarmBass = SubBassExciterConfig(
    isEnabled: true,
    mode: SubBassExciterMode.analogWarmthDrive,
    subFrequency: 70.0,
    subBoostDb: 5.0,
    driveSaturation: 0.50,
    harmonicsMix: 0.7,
    lowPassCutoff: 180.0,
  );

  static const SubBassExciterConfig mobileMaxxBass = SubBassExciterConfig(
    isEnabled: true,
    mode: SubBassExciterMode.phoneSpeakerExciter,
    subFrequency: 60.0,
    subBoostDb: 4.0,
    driveSaturation: 0.30,
    harmonicsMix: 0.9,
    lowPassCutoff: 220.0,
  );

  static const SubBassExciterConfig dubstepSeismic = SubBassExciterConfig(
    isEnabled: true,
    mode: SubBassExciterMode.heavyBassDrop,
    subFrequency: 45.0,
    subBoostDb: 12.0,
    driveSaturation: 0.60,
    harmonicsMix: 0.65,
    lowPassCutoff: 130.0,
  );

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        subFrequency,
        subBoostDb,
        driveSaturation,
        harmonicsMix,
        lowPassCutoff,
      ];
}
