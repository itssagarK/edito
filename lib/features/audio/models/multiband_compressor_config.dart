import 'package:equatable/equatable.dart';

/// Modes of 3-band studio audio master compression.
enum MultibandCompressorMode {
  transparentMaster,
  punchyClub808,
  vocalPresenceRadio,
  warmTapeSaturate,
  heavyGlueMix,
}

extension MultibandCompressorModeExtension on MultibandCompressorMode {
  String get label {
    switch (this) {
      case MultibandCompressorMode.transparentMaster:
        return 'Transparent Master';
      case MultibandCompressorMode.punchyClub808:
        return 'Punchy Club 808';
      case MultibandCompressorMode.vocalPresenceRadio:
        return 'Vocal Radio';
      case MultibandCompressorMode.warmTapeSaturate:
        return 'Warm Tape Glue';
      case MultibandCompressorMode.heavyGlueMix:
        return 'Heavy Master Glue';
    }
  }

  String get description {
    switch (this) {
      case MultibandCompressorMode.transparentMaster:
        return 'Clean dynamic gluing across Low, Mid, and High bands preserving natural transients';
      case MultibandCompressorMode.punchyClub808:
        return 'Aggressive low-end control with tight sub punch and open, airy high frequencies';
      case MultibandCompressorMode.vocalPresenceRadio:
        return 'Focused mid-range compression giving dialog and vocals clear upfront broadcast presence';
      case MultibandCompressorMode.warmTapeSaturate:
        return 'Gentle analog multi-band warmth with smooth musical tape-style saturation';
      case MultibandCompressorMode.heavyGlueMix:
        return 'Intense multi-band compression for maximum loudness, punch, and commercial cohesion';
    }
  }

  String get iconAsset {
    switch (this) {
      case MultibandCompressorMode.transparentMaster:
        return 'tune';
      case MultibandCompressorMode.punchyClub808:
        return 'speaker';
      case MultibandCompressorMode.vocalPresenceRadio:
        return 'mic';
      case MultibandCompressorMode.warmTapeSaturate:
        return 'album';
      case MultibandCompressorMode.heavyGlueMix:
        return 'compress';
    }
  }
}

/// Configuration for 3-band studio audio master compression and dynamic control.
class MultibandCompressorConfig extends Equatable {
  final bool isEnabled;
  final MultibandCompressorMode mode;

  // Low Band (< crossoverLowHz)
  final double lowThresholdDb; // -40.0 to 0.0 dB
  final double lowRatio; // 1.0 to 20.0
  final double lowGainDb; // -12.0 to 12.0 dB

  // Mid Band (crossoverLowHz to crossoverHighHz)
  final double midThresholdDb; // -40.0 to 0.0 dB
  final double midRatio; // 1.0 to 20.0
  final double midGainDb; // -12.0 to 12.0 dB

  // High Band (> crossoverHighHz)
  final double highThresholdDb; // -40.0 to 0.0 dB
  final double highRatio; // 1.0 to 20.0
  final double highGainDb; // -12.0 to 12.0 dB

  // Crossover Frequencies
  final double crossoverLowHz; // 80.0 to 400.0 Hz
  final double crossoverHighHz; // 2000.0 to 8000.0 Hz

  // Master Dynamics
  final double masterGainDb; // -12.0 to 12.0 dB
  final double attackMs; // 1.0 to 100.0 ms
  final double releaseMs; // 20.0 to 1000.0 ms

  const MultibandCompressorConfig({
    this.isEnabled = false,
    this.mode = MultibandCompressorMode.transparentMaster,
    this.lowThresholdDb = -18.0,
    this.lowRatio = 3.0,
    this.lowGainDb = 1.5,
    this.midThresholdDb = -20.0,
    this.midRatio = 2.5,
    this.midGainDb = 0.5,
    this.highThresholdDb = -24.0,
    this.highRatio = 3.5,
    this.highGainDb = 2.0,
    this.crossoverLowHz = 250.0,
    this.crossoverHighHz = 4000.0,
    this.masterGainDb = 0.0,
    this.attackMs = 15.0,
    this.releaseMs = 150.0,
  });

  bool get isActive => isEnabled;

  /// Default disabled configuration.
  static const MultibandCompressorConfig defaultDisabled = MultibandCompressorConfig();

  // Curated 5 studio mastering presets
  static const MultibandCompressorConfig presetTransparentMaster = MultibandCompressorConfig(
    isEnabled: true,
    mode: MultibandCompressorMode.transparentMaster,
    lowThresholdDb: -18.0,
    lowRatio: 2.5,
    lowGainDb: 1.0,
    midThresholdDb: -20.0,
    midRatio: 2.0,
    midGainDb: 0.5,
    highThresholdDb: -22.0,
    highRatio: 2.5,
    highGainDb: 1.5,
    crossoverLowHz: 250.0,
    crossoverHighHz: 4000.0,
    masterGainDb: 0.0,
    attackMs: 20.0,
    releaseMs: 180.0,
  );

  static const MultibandCompressorConfig presetPunchyClub808 = MultibandCompressorConfig(
    isEnabled: true,
    mode: MultibandCompressorMode.punchyClub808,
    lowThresholdDb: -22.0,
    lowRatio: 5.0,
    lowGainDb: 3.5,
    midThresholdDb: -18.0,
    midRatio: 2.5,
    midGainDb: 0.0,
    highThresholdDb: -24.0,
    highRatio: 3.5,
    highGainDb: 2.0,
    crossoverLowHz: 200.0,
    crossoverHighHz: 3500.0,
    masterGainDb: 1.0,
    attackMs: 10.0,
    releaseMs: 120.0,
  );

  static const MultibandCompressorConfig presetVocalPresence = MultibandCompressorConfig(
    isEnabled: true,
    mode: MultibandCompressorMode.vocalPresenceRadio,
    lowThresholdDb: -16.0,
    lowRatio: 2.0,
    lowGainDb: -0.5,
    midThresholdDb: -24.0,
    midRatio: 4.0,
    midGainDb: 2.5,
    highThresholdDb: -26.0,
    highRatio: 5.0,
    highGainDb: 1.5,
    crossoverLowHz: 300.0,
    crossoverHighHz: 4500.0,
    masterGainDb: 0.5,
    attackMs: 12.0,
    releaseMs: 140.0,
  );

  static const MultibandCompressorConfig presetWarmTapeSaturate = MultibandCompressorConfig(
    isEnabled: true,
    mode: MultibandCompressorMode.warmTapeSaturate,
    lowThresholdDb: -15.0,
    lowRatio: 2.0,
    lowGainDb: 2.0,
    midThresholdDb: -16.0,
    midRatio: 1.8,
    midGainDb: 1.0,
    highThresholdDb: -18.0,
    highRatio: 2.0,
    highGainDb: 0.5,
    crossoverLowHz: 220.0,
    crossoverHighHz: 3800.0,
    masterGainDb: 0.0,
    attackMs: 25.0,
    releaseMs: 220.0,
  );

  static const MultibandCompressorConfig presetHeavyGlueMix = MultibandCompressorConfig(
    isEnabled: true,
    mode: MultibandCompressorMode.heavyGlueMix,
    lowThresholdDb: -24.0,
    lowRatio: 6.0,
    lowGainDb: 2.0,
    midThresholdDb: -26.0,
    midRatio: 5.0,
    midGainDb: 1.5,
    highThresholdDb: -28.0,
    highRatio: 6.0,
    highGainDb: 2.5,
    crossoverLowHz: 250.0,
    crossoverHighHz: 4000.0,
    masterGainDb: 1.5,
    attackMs: 8.0,
    releaseMs: 90.0,
  );

  MultibandCompressorConfig copyWith({
    bool? isEnabled,
    MultibandCompressorMode? mode,
    double? lowThresholdDb,
    double? lowRatio,
    double? lowGainDb,
    double? midThresholdDb,
    double? midRatio,
    double? midGainDb,
    double? highThresholdDb,
    double? highRatio,
    double? highGainDb,
    double? crossoverLowHz,
    double? crossoverHighHz,
    double? masterGainDb,
    double? attackMs,
    double? releaseMs,
  }) {
    return MultibandCompressorConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      lowThresholdDb: lowThresholdDb ?? this.lowThresholdDb,
      lowRatio: lowRatio ?? this.lowRatio,
      lowGainDb: lowGainDb ?? this.lowGainDb,
      midThresholdDb: midThresholdDb ?? this.midThresholdDb,
      midRatio: midRatio ?? this.midRatio,
      midGainDb: midGainDb ?? this.midGainDb,
      highThresholdDb: highThresholdDb ?? this.highThresholdDb,
      highRatio: highRatio ?? this.highRatio,
      highGainDb: highGainDb ?? this.highGainDb,
      crossoverLowHz: crossoverLowHz ?? this.crossoverLowHz,
      crossoverHighHz: crossoverHighHz ?? this.crossoverHighHz,
      masterGainDb: masterGainDb ?? this.masterGainDb,
      attackMs: attackMs ?? this.attackMs,
      releaseMs: releaseMs ?? this.releaseMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'lowThresholdDb': lowThresholdDb,
      'lowRatio': lowRatio,
      'lowGainDb': lowGainDb,
      'midThresholdDb': midThresholdDb,
      'midRatio': midRatio,
      'midGainDb': midGainDb,
      'highThresholdDb': highThresholdDb,
      'highRatio': highRatio,
      'highGainDb': highGainDb,
      'crossoverLowHz': crossoverLowHz,
      'crossoverHighHz': crossoverHighHz,
      'masterGainDb': masterGainDb,
      'attackMs': attackMs,
      'releaseMs': releaseMs,
    };
  }

  factory MultibandCompressorConfig.fromJson(Map<String, dynamic> json) {
    return MultibandCompressorConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: MultibandCompressorMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => MultibandCompressorMode.transparentMaster,
      ),
      lowThresholdDb: (json['lowThresholdDb'] as num?)?.toDouble() ?? -18.0,
      lowRatio: (json['lowRatio'] as num?)?.toDouble() ?? 3.0,
      lowGainDb: (json['lowGainDb'] as num?)?.toDouble() ?? 1.5,
      midThresholdDb: (json['midThresholdDb'] as num?)?.toDouble() ?? -20.0,
      midRatio: (json['midRatio'] as num?)?.toDouble() ?? 2.5,
      midGainDb: (json['midGainDb'] as num?)?.toDouble() ?? 0.5,
      highThresholdDb: (json['highThresholdDb'] as num?)?.toDouble() ?? -24.0,
      highRatio: (json['highRatio'] as num?)?.toDouble() ?? 3.5,
      highGainDb: (json['highGainDb'] as num?)?.toDouble() ?? 2.0,
      crossoverLowHz: (json['crossoverLowHz'] as num?)?.toDouble() ?? 250.0,
      crossoverHighHz: (json['crossoverHighHz'] as num?)?.toDouble() ?? 4000.0,
      masterGainDb: (json['masterGainDb'] as num?)?.toDouble() ?? 0.0,
      attackMs: (json['attackMs'] as num?)?.toDouble() ?? 15.0,
      releaseMs: (json['releaseMs'] as num?)?.toDouble() ?? 150.0,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        lowThresholdDb,
        lowRatio,
        lowGainDb,
        midThresholdDb,
        midRatio,
        midGainDb,
        highThresholdDb,
        highRatio,
        highGainDb,
        crossoverLowHz,
        crossoverHighHz,
        masterGainDb,
        attackMs,
        releaseMs,
      ];
}
