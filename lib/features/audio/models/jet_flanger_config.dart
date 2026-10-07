import 'package:equatable/equatable.dart';

/// Flanger and phase cancellation comb-filter modulation modes.
enum JetFlangerMode {
  jetEngineFlyby,
  barberpolePhaser,
  metallicResonator,
  stereoSpreadFlanger,
  deepSpaceComb;

  String get displayName {
    switch (this) {
      case JetFlangerMode.jetEngineFlyby:
        return 'Jet Engine Flyby';
      case JetFlangerMode.barberpolePhaser:
        return 'Barberpole Phaser';
      case JetFlangerMode.metallicResonator:
        return 'Metallic Resonator';
      case JetFlangerMode.stereoSpreadFlanger:
        return 'Stereo Wide Flanger';
      case JetFlangerMode.deepSpaceComb:
        return 'Deep Space Comb';
    }
  }

  String get description {
    switch (this) {
      case JetFlangerMode.jetEngineFlyby:
        return 'Deep comb-filter resonant sweeping simulating an aircraft roaring overhead';
      case JetFlangerMode.barberpolePhaser:
        return 'Infinite ascending or descending audio notch filter cancellation illusion';
      case JetFlangerMode.metallicResonator:
        return 'Micro-delay comb resonance creating futuristic robotic and metallic ringing';
      case JetFlangerMode.stereoSpreadFlanger:
        return '180° out-of-phase L/R LFO modulation for three-dimensional stereo width';
      case JetFlangerMode.deepSpaceComb:
        return 'Hypnotic slow-evolving ambient comb filter sweeping with lush stereo depth';
    }
  }
}

/// Configuration for jet engine flanging, comb filtering, and barberpole phasing DSP.
class JetFlangerConfig extends Equatable {
  final bool isEnabled;
  final JetFlangerMode mode;
  final double sweepSpeedHz; // 0.05 to 5.0 Hz LFO modulation rate
  final double depthMs; // 1.0 to 15.0 ms delay time modulation depth
  final double feedback; // -0.90 to +0.90 resonance feedback
  final double stereoPhaseDeg; // 0° to 180° L/R phase divergence
  final double mix; // 0.0 to 1.0 dry/wet mix

  const JetFlangerConfig({
    this.isEnabled = false,
    this.mode = JetFlangerMode.jetEngineFlyby,
    this.sweepSpeedHz = 0.25,
    this.depthMs = 6.0,
    this.feedback = 0.70,
    this.stereoPhaseDeg = 90.0,
    this.mix = 0.75,
  });

  bool get isActive => isEnabled && mix > 0.01;

  JetFlangerConfig copyWith({
    bool? isEnabled,
    JetFlangerMode? mode,
    double? sweepSpeedHz,
    double? depthMs,
    double? feedback,
    double? stereoPhaseDeg,
    double? mix,
  }) {
    return JetFlangerConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      sweepSpeedHz: sweepSpeedHz ?? this.sweepSpeedHz,
      depthMs: depthMs ?? this.depthMs,
      feedback: feedback ?? this.feedback,
      stereoPhaseDeg: stereoPhaseDeg ?? this.stereoPhaseDeg,
      mix: mix ?? this.mix,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'sweepSpeedHz': sweepSpeedHz,
      'depthMs': depthMs,
      'feedback': feedback,
      'stereoPhaseDeg': stereoPhaseDeg,
      'mix': mix,
    };
  }

  factory JetFlangerConfig.fromJson(Map<String, dynamic> json) {
    JetFlangerMode parsedMode = JetFlangerMode.jetEngineFlyby;
    if (json['mode'] != null) {
      try {
        parsedMode = JetFlangerMode.values.byName(json['mode'] as String);
      } catch (_) {
        parsedMode = JetFlangerMode.jetEngineFlyby;
      }
    }

    return JetFlangerConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: parsedMode,
      sweepSpeedHz: (json['sweepSpeedHz'] as num?)?.toDouble() ?? 0.25,
      depthMs: (json['depthMs'] as num?)?.toDouble() ?? 6.0,
      feedback: (json['feedback'] as num?)?.toDouble() ?? 0.70,
      stereoPhaseDeg: (json['stereoPhaseDeg'] as num?)?.toDouble() ?? 90.0,
      mix: (json['mix'] as num?)?.toDouble() ?? 0.75,
    );
  }

  // Curated presets
  static const JetFlangerConfig jetFlyby = JetFlangerConfig(
    isEnabled: true,
    mode: JetFlangerMode.jetEngineFlyby,
    sweepSpeedHz: 0.20,
    depthMs: 8.5,
    feedback: 0.85,
    stereoPhaseDeg: 90.0,
    mix: 0.80,
  );

  static const JetFlangerConfig barberpole = JetFlangerConfig(
    isEnabled: true,
    mode: JetFlangerMode.barberpolePhaser,
    sweepSpeedHz: 0.50,
    depthMs: 4.5,
    feedback: 0.65,
    stereoPhaseDeg: 180.0,
    mix: 0.75,
  );

  static const JetFlangerConfig metallicRing = JetFlangerConfig(
    isEnabled: true,
    mode: JetFlangerMode.metallicResonator,
    sweepSpeedHz: 1.50,
    depthMs: 2.0,
    feedback: 0.88,
    stereoPhaseDeg: 45.0,
    mix: 0.85,
  );

  static const JetFlangerConfig stereoWide = JetFlangerConfig(
    isEnabled: true,
    mode: JetFlangerMode.stereoSpreadFlanger,
    sweepSpeedHz: 0.80,
    depthMs: 5.5,
    feedback: 0.50,
    stereoPhaseDeg: 180.0,
    mix: 0.70,
  );

  static const JetFlangerConfig deepSpaceHypnotic = JetFlangerConfig(
    isEnabled: true,
    mode: JetFlangerMode.deepSpaceComb,
    sweepSpeedHz: 0.10,
    depthMs: 11.0,
    feedback: 0.72,
    stereoPhaseDeg: 120.0,
    mix: 0.65,
  );

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        sweepSpeedHz,
        depthMs,
        feedback,
        stereoPhaseDeg,
        mix,
      ];
}
