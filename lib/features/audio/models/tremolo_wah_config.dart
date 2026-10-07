import 'package:equatable/equatable.dart';

/// Modulation mode for tremolo amplitude pulsation and auto-wah frequency sweeping.
enum TremoloWahMode {
  stereoTremolo,
  autoWahFunk,
  leslieRotary,
  stutterGate,
  psychedelicSweep;

  String get displayName {
    switch (this) {
      case TremoloWahMode.stereoTremolo:
        return 'Stereo Tremolo LFO';
      case TremoloWahMode.autoWahFunk:
        return 'Auto-Wah Funk Envelope';
      case TremoloWahMode.leslieRotary:
        return 'Leslie Rotary Speaker';
      case TremoloWahMode.stutterGate:
        return 'Square-Wave Stutter Gate';
      case TremoloWahMode.psychedelicSweep:
        return 'Psychedelic Resonant Sweep';
    }
  }

  String get description {
    switch (this) {
      case TremoloWahMode.stereoTremolo:
        return 'Smooth sinusoidal amplitude pulsation across left & right stereo channels';
      case TremoloWahMode.autoWahFunk:
        return 'Dynamic resonant bandpass envelope sweep responding to audio harmonics';
      case TremoloWahMode.leslieRotary:
        return 'Rotating acoustic horn simulation with combined doppler vibrato and tremolo';
      case TremoloWahMode.stutterGate:
        return 'Sharp square-wave chopper gate producing rhythmic EDM and trap stutter drops';
      case TremoloWahMode.psychedelicSweep:
        return 'Hypnotic wide-spectrum resonant bandpass sweep for vintage rock textures';
    }
  }
}

/// LFO wave shape driving amplitude or filter cutoff modulation.
enum LfoWaveform {
  sine,
  triangle,
  square,
  sawtooth;

  String get displayName {
    switch (this) {
      case LfoWaveform.sine:
        return 'Sine (Smooth)';
      case LfoWaveform.triangle:
        return 'Triangle (Linear)';
      case LfoWaveform.square:
        return 'Square (Chopper)';
      case LfoWaveform.sawtooth:
        return 'Sawtooth (Ramp)';
    }
  }
}

/// Configuration for periodic stereo tremolo, dynamic auto-wah, and rotary audio modulation.
class TremoloWahConfig extends Equatable {
  final bool isEnabled;
  final TremoloWahMode mode;
  final LfoWaveform waveform;
  final double frequencyHz; // 0.2 to 20.0 Hz (LFO rate)
  final double depth; // 0.0 to 1.0 (modulation amount)
  final double resonance; // 0.5 to 10.0 (Wah Q-factor resonance peak)
  final double centerFreqHz; // 200 to 4000 Hz (Wah filter center band)
  final double stereoPhaseOffsetDeg; // 0 to 180 degrees (L/R phase offset)
  final double mix; // 0.0 to 1.0 (wet/dry balance)

  const TremoloWahConfig({
    this.isEnabled = false,
    this.mode = TremoloWahMode.stereoTremolo,
    this.waveform = LfoWaveform.sine,
    this.frequencyHz = 4.0,
    this.depth = 0.70,
    this.resonance = 3.0,
    this.centerFreqHz = 1000.0,
    this.stereoPhaseOffsetDeg = 90.0,
    this.mix = 1.0,
  });

  bool get isActive => isEnabled && depth > 0.01 && mix > 0.01;

  // Curated Presets
  static const TremoloWahConfig vintageSurfTremolo = TremoloWahConfig(
    isEnabled: true,
    mode: TremoloWahMode.stereoTremolo,
    waveform: LfoWaveform.sine,
    frequencyHz: 5.0,
    depth: 0.75,
    resonance: 1.0,
    centerFreqHz: 1000.0,
    stereoPhaseOffsetDeg: 0.0,
    mix: 1.0,
  );

  static const TremoloWahConfig funkyAutoWah = TremoloWahConfig(
    isEnabled: true,
    mode: TremoloWahMode.autoWahFunk,
    waveform: LfoWaveform.sine,
    frequencyHz: 2.5,
    depth: 0.85,
    resonance: 5.5,
    centerFreqHz: 1200.0,
    stereoPhaseOffsetDeg: 45.0,
    mix: 1.0,
  );

  static const TremoloWahConfig leslieOrganSpeaker = TremoloWahConfig(
    isEnabled: true,
    mode: TremoloWahMode.leslieRotary,
    waveform: LfoWaveform.sine,
    frequencyHz: 6.8,
    depth: 0.65,
    resonance: 2.2,
    centerFreqHz: 850.0,
    stereoPhaseOffsetDeg: 120.0,
    mix: 0.95,
  );

  static const TremoloWahConfig hardEdmStutter = TremoloWahConfig(
    isEnabled: true,
    mode: TremoloWahMode.stutterGate,
    waveform: LfoWaveform.square,
    frequencyHz: 8.0,
    depth: 1.0,
    resonance: 1.0,
    centerFreqHz: 1000.0,
    stereoPhaseOffsetDeg: 0.0,
    mix: 1.0,
  );

  static const TremoloWahConfig trippyPhaserSweep = TremoloWahConfig(
    isEnabled: true,
    mode: TremoloWahMode.psychedelicSweep,
    waveform: LfoWaveform.triangle,
    frequencyHz: 0.5,
    depth: 0.80,
    resonance: 4.5,
    centerFreqHz: 1800.0,
    stereoPhaseOffsetDeg: 90.0,
    mix: 0.90,
  );

  TremoloWahConfig copyWith({
    bool? isEnabled,
    TremoloWahMode? mode,
    LfoWaveform? waveform,
    double? frequencyHz,
    double? depth,
    double? resonance,
    double? centerFreqHz,
    double? stereoPhaseOffsetDeg,
    double? mix,
  }) {
    return TremoloWahConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      waveform: waveform ?? this.waveform,
      frequencyHz: frequencyHz ?? this.frequencyHz,
      depth: depth ?? this.depth,
      resonance: resonance ?? this.resonance,
      centerFreqHz: centerFreqHz ?? this.centerFreqHz,
      stereoPhaseOffsetDeg: stereoPhaseOffsetDeg ?? this.stereoPhaseOffsetDeg,
      mix: mix ?? this.mix,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'waveform': waveform.name,
      'frequencyHz': frequencyHz,
      'depth': depth,
      'resonance': resonance,
      'centerFreqHz': centerFreqHz,
      'stereoPhaseOffsetDeg': stereoPhaseOffsetDeg,
      'mix': mix,
    };
  }

  factory TremoloWahConfig.fromJson(Map<String, dynamic> json) {
    return TremoloWahConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: TremoloWahMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => TremoloWahMode.stereoTremolo,
      ),
      waveform: LfoWaveform.values.firstWhere(
        (e) => e.name == json['waveform'],
        orElse: () => LfoWaveform.sine,
      ),
      frequencyHz: (json['frequencyHz'] as num?)?.toDouble() ?? 4.0,
      depth: (json['depth'] as num?)?.toDouble() ?? 0.70,
      resonance: (json['resonance'] as num?)?.toDouble() ?? 3.0,
      centerFreqHz: (json['centerFreqHz'] as num?)?.toDouble() ?? 1000.0,
      stereoPhaseOffsetDeg: (json['stereoPhaseOffsetDeg'] as num?)?.toDouble() ?? 90.0,
      mix: (json['mix'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        waveform,
        frequencyHz,
        depth,
        resonance,
        centerFreqHz,
        stereoPhaseOffsetDeg,
        mix,
      ];
}
