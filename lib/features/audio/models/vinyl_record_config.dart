import 'package:equatable/equatable.dart';

enum VinylRpm {
  rpm33,
  rpm45,
  rpm78;

  String get displayName {
    switch (this) {
      case VinylRpm.rpm33:
        return '33⅓ RPM (12" LP)';
      case VinylRpm.rpm45:
        return '45 RPM (7" Single)';
      case VinylRpm.rpm78:
        return '78 RPM (Shellac Gramophone)';
    }
  }

  double get rotationSpeed {
    switch (this) {
      case VinylRpm.rpm33:
        return 0.55;
      case VinylRpm.rpm45:
        return 0.75;
      case VinylRpm.rpm78:
        return 1.30;
    }
  }

  String get description {
    switch (this) {
      case VinylRpm.rpm33:
        return 'Warm balanced microgroove vinyl with smooth analog fidelity';
      case VinylRpm.rpm45:
        return 'Punchy high-dynamic radio single cut with vivid transients';
      case VinylRpm.rpm78:
        return 'Heavy acoustic surface grit and sharp bandpass characteristic of 1920s shellac';
    }
  }
}

class VinylRecordConfig extends Equatable {
  final bool isEnabled;
  final VinylRpm rpm;
  final double dustCrackle; // 0.0 to 1.0 (frequency & amplitude of dust pops)
  final double surfaceNoise; // 0.0 to 1.0 (continuous groove friction noise)
  final double needleWearTone; // 0.0 to 1.0 (phono cartridge warmth & roll-off)
  final bool needleDropCue;

  const VinylRecordConfig({
    this.isEnabled = false,
    this.rpm = VinylRpm.rpm33,
    this.dustCrackle = 0.50,
    this.surfaceNoise = 0.35,
    this.needleWearTone = 0.40,
    this.needleDropCue = true,
  });

  bool get isActive => isEnabled;

  // Built-in presets
  static const VinylRecordConfig classicLp33 = VinylRecordConfig(
    isEnabled: true,
    rpm: VinylRpm.rpm33,
    dustCrackle: 0.35,
    surfaceNoise: 0.25,
    needleWearTone: 0.35,
    needleDropCue: true,
  );

  static const VinylRecordConfig vintageSingle45 = VinylRecordConfig(
    isEnabled: true,
    rpm: VinylRpm.rpm45,
    dustCrackle: 0.50,
    surfaceNoise: 0.40,
    needleWearTone: 0.45,
    needleDropCue: true,
  );

  static const VinylRecordConfig antiqueGramophone78 = VinylRecordConfig(
    isEnabled: true,
    rpm: VinylRpm.rpm78,
    dustCrackle: 0.85,
    surfaceNoise: 0.75,
    needleWearTone: 0.80,
    needleDropCue: true,
  );

  static const VinylRecordConfig lofiWarmBeats = VinylRecordConfig(
    isEnabled: true,
    rpm: VinylRpm.rpm33,
    dustCrackle: 0.60,
    surfaceNoise: 0.50,
    needleWearTone: 0.65,
    needleDropCue: false,
  );

  static const VinylRecordConfig wornDustyVinyl = VinylRecordConfig(
    isEnabled: true,
    rpm: VinylRpm.rpm33,
    dustCrackle: 0.80,
    surfaceNoise: 0.65,
    needleWearTone: 0.55,
    needleDropCue: true,
  );

  VinylRecordConfig copyWith({
    bool? isEnabled,
    VinylRpm? rpm,
    double? dustCrackle,
    double? surfaceNoise,
    double? needleWearTone,
    bool? needleDropCue,
  }) {
    return VinylRecordConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      rpm: rpm ?? this.rpm,
      dustCrackle: dustCrackle ?? this.dustCrackle,
      surfaceNoise: surfaceNoise ?? this.surfaceNoise,
      needleWearTone: needleWearTone ?? this.needleWearTone,
      needleDropCue: needleDropCue ?? this.needleDropCue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'rpm': rpm.name,
      'dustCrackle': dustCrackle,
      'surfaceNoise': surfaceNoise,
      'needleWearTone': needleWearTone,
      'needleDropCue': needleDropCue,
    };
  }

  factory VinylRecordConfig.fromJson(Map<String, dynamic> json) {
    VinylRpm parsedRpm = VinylRpm.rpm33;
    if (json['rpm'] != null) {
      for (final val in VinylRpm.values) {
        if (val.name == json['rpm']) {
          parsedRpm = val;
          break;
        }
      }
    }

    return VinylRecordConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      rpm: parsedRpm,
      dustCrackle: (json['dustCrackle'] as num?)?.toDouble() ?? 0.50,
      surfaceNoise: (json['surfaceNoise'] as num?)?.toDouble() ?? 0.35,
      needleWearTone: (json['needleWearTone'] as num?)?.toDouble() ?? 0.40,
      needleDropCue: json['needleDropCue'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        rpm,
        dustCrackle,
        surfaceNoise,
        needleWearTone,
        needleDropCue,
      ];
}
