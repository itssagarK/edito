import 'package:equatable/equatable.dart';

/// Carrier waveform and spectral modulation modes for metallic ring modulation.
enum RingModulatorMode {
  dalekRobotic,
  alienVocoder,
  subHarmonicTremor,
  cyberBellBells,
  dualCarrierScifi;

  String get displayName {
    switch (this) {
      case RingModulatorMode.dalekRobotic:
        return 'Dalek Robotic Voice';
      case RingModulatorMode.alienVocoder:
        return 'Alien Metallic Vocoder';
      case RingModulatorMode.subHarmonicTremor:
        return 'Sub-Harmonic Tremor';
      case RingModulatorMode.cyberBellBells:
        return 'Cyber Inharmonic Chimes';
      case RingModulatorMode.dualCarrierScifi:
        return 'Dual Carrier Sci-Fi';
    }
  }

  String get description {
    switch (this) {
      case RingModulatorMode.dalekRobotic:
        return 'Iconic sci-fi Dalek voice synthesis multiplying speech with a 30Hz sinusoidal carrier';
      case RingModulatorMode.alienVocoder:
        return 'Mid-frequency carrier multiplication creating inharmonic futuristic alien robotic speech';
      case RingModulatorMode.subHarmonicTremor:
        return 'Ultra-low frequency amplitude modulation inducing guttural tremors and helicopter flutter';
      case RingModulatorMode.cyberBellBells:
        return 'High carrier frequencies producing metallic bell ringing and synthesized chimes';
      case RingModulatorMode.dualCarrierScifi:
        return 'Harmonically rich dual-carrier modulation producing evolving cosmic textures';
    }
  }
}

/// Configuration for metallic ring modulation, carrier oscillation, and robotic vocoder DSP.
class RingModulatorConfig extends Equatable {
  final bool isEnabled;
  final RingModulatorMode mode;
  final double carrierFreqHz; // 5.0 to 2000.0 Hz carrier oscillator frequency
  final double depth; // 0.10 to 1.0 modulation depth
  final double harmonicMix; // 0.0 to 1.0 second harmonic / overtone injection
  final double mix; // 0.0 to 1.0 dry/wet mix

  const RingModulatorConfig({
    this.isEnabled = false,
    this.mode = RingModulatorMode.dalekRobotic,
    this.carrierFreqHz = 30.0,
    this.depth = 0.85,
    this.harmonicMix = 0.20,
    this.mix = 0.80,
  });

  bool get isActive => isEnabled && mix > 0.02;

  RingModulatorConfig copyWith({
    bool? isEnabled,
    RingModulatorMode? mode,
    double? carrierFreqHz,
    double? depth,
    double? harmonicMix,
    double? mix,
  }) {
    return RingModulatorConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      carrierFreqHz: carrierFreqHz ?? this.carrierFreqHz,
      depth: depth ?? this.depth,
      harmonicMix: harmonicMix ?? this.harmonicMix,
      mix: mix ?? this.mix,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'carrierFreqHz': carrierFreqHz,
      'depth': depth,
      'harmonicMix': harmonicMix,
      'mix': mix,
    };
  }

  factory RingModulatorConfig.fromJson(Map<String, dynamic> json) {
    RingModulatorMode parsedMode = RingModulatorMode.dalekRobotic;
    if (json['mode'] != null) {
      try {
        parsedMode = RingModulatorMode.values.byName(json['mode'] as String);
      } catch (_) {
        parsedMode = RingModulatorMode.dalekRobotic;
      }
    }

    return RingModulatorConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: parsedMode,
      carrierFreqHz: (json['carrierFreqHz'] as num?)?.toDouble() ?? 30.0,
      depth: (json['depth'] as num?)?.toDouble() ?? 0.85,
      harmonicMix: (json['harmonicMix'] as num?)?.toDouble() ?? 0.20,
      mix: (json['mix'] as num?)?.toDouble() ?? 0.80,
    );
  }

  // Curated presets
  static const RingModulatorConfig dalekRobot = RingModulatorConfig(
    isEnabled: true,
    mode: RingModulatorMode.dalekRobotic,
    carrierFreqHz: 30.0,
    depth: 0.90,
    harmonicMix: 0.20,
    mix: 0.85,
  );

  static const RingModulatorConfig alienSpeech = RingModulatorConfig(
    isEnabled: true,
    mode: RingModulatorMode.alienVocoder,
    carrierFreqHz: 440.0,
    depth: 0.80,
    harmonicMix: 0.35,
    mix: 0.75,
  );

  static const RingModulatorConfig subTremor = RingModulatorConfig(
    isEnabled: true,
    mode: RingModulatorMode.subHarmonicTremor,
    carrierFreqHz: 12.0,
    depth: 0.95,
    harmonicMix: 0.10,
    mix: 0.80,
  );

  static const RingModulatorConfig cyberChime = RingModulatorConfig(
    isEnabled: true,
    mode: RingModulatorMode.cyberBellBells,
    carrierFreqHz: 880.0,
    depth: 0.85,
    harmonicMix: 0.50,
    mix: 0.70,
  );

  static const RingModulatorConfig spaceInterference = RingModulatorConfig(
    isEnabled: true,
    mode: RingModulatorMode.dualCarrierScifi,
    carrierFreqHz: 180.0,
    depth: 0.75,
    harmonicMix: 0.60,
    mix: 0.80,
  );

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        carrierFreqHz,
        depth,
        harmonicMix,
        mix,
      ];
}
