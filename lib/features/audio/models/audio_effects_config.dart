import 'package:equatable/equatable.dart';

enum VoiceModulationPreset {
  natural,
  studioBroadcast,
  deepNarrator,
  crystalClear,
  radioWalkie,
  sciFiRobot,
  customPitch,
}

extension VoiceModulationPresetExtension on VoiceModulationPreset {
  String get label {
    switch (this) {
      case VoiceModulationPreset.natural:
        return 'Natural Clean';
      case VoiceModulationPreset.studioBroadcast:
        return 'Studio Broadcast';
      case VoiceModulationPreset.deepNarrator:
        return 'Deep Movie Narrator';
      case VoiceModulationPreset.crystalClear:
        return 'Crystal Clear Vocal';
      case VoiceModulationPreset.radioWalkie:
        return 'Retro Radio / Walkie';
      case VoiceModulationPreset.sciFiRobot:
        return 'Sci-Fi Robot Synth';
      case VoiceModulationPreset.customPitch:
        return 'Custom Pitch Shift';
    }
  }

  String get description {
    switch (this) {
      case VoiceModulationPreset.natural:
        return 'Unmodified natural vocal tone';
      case VoiceModulationPreset.studioBroadcast:
        return 'Warm, punchy, compressed podcast & studio sound';
      case VoiceModulationPreset.deepNarrator:
        return 'Deep resonant bass & cinematic low pitch';
      case VoiceModulationPreset.crystalClear:
        return 'High presence, bright airy treble & de-essed clarity';
      case VoiceModulationPreset.radioWalkie:
        return 'Narrow bandwidth vintage communication radio';
      case VoiceModulationPreset.sciFiRobot:
        return 'Robotic vocoder modulation with metallic resonance';
      case VoiceModulationPreset.customPitch:
        return 'Freely adjustable semitone pitch transposition';
    }
  }
}

class AudioEffectsConfig extends Equatable {
  final bool isVoiceEnhancerEnabled;
  final double denoiseIntensity;       // 0.0 to 1.0 (70% standard)
  final double voiceClarityGain;        // 0.0 to 2.0 (1.0 = standard)
  final int fadeInMs;                  // 0 to 5000ms
  final int fadeOutMs;                 // 0 to 5000ms
  final bool isDuckingEnabled;         // Auto duck background during foreground speech
  final double duckingAttenuation;     // 0.1 (-20dB) to 0.8 (-2dB), default 0.3 (-10dB)

  // Voice Modulation & Loud Voice Booster
  final bool isLoudVoiceEnabled;       // Master loudness punch & compression limiter
  final double voiceBoost;             // 1.0 to 3.0 (up to +15dB pre-amp gain)
  final VoiceModulationPreset modulationPreset;
  final double pitchShiftSemitones;    // -12.0 to +12.0 semitones
  final double bassEnhance;            // 0.0 to 2.0 (vocal body)
  final double trebleCrisp;            // 0.0 to 2.0 (vocal air & brightness)

  const AudioEffectsConfig({
    this.isVoiceEnhancerEnabled = false,
    this.denoiseIntensity = 0.70,
    this.voiceClarityGain = 1.20,
    this.fadeInMs = 0,
    this.fadeOutMs = 0,
    this.isDuckingEnabled = false,
    this.duckingAttenuation = 0.30,
    this.isLoudVoiceEnabled = false,
    this.voiceBoost = 1.40,
    this.modulationPreset = VoiceModulationPreset.natural,
    this.pitchShiftSemitones = 0.0,
    this.bassEnhance = 1.0,
    this.trebleCrisp = 1.0,
  });

  AudioEffectsConfig copyWith({
    bool? isVoiceEnhancerEnabled,
    double? denoiseIntensity,
    double? voiceClarityGain,
    int? fadeInMs,
    int? fadeOutMs,
    bool? isDuckingEnabled,
    double? duckingAttenuation,
    bool? isLoudVoiceEnabled,
    double? voiceBoost,
    VoiceModulationPreset? modulationPreset,
    double? pitchShiftSemitones,
    double? bassEnhance,
    double? trebleCrisp,
  }) {
    return AudioEffectsConfig(
      isVoiceEnhancerEnabled: isVoiceEnhancerEnabled ?? this.isVoiceEnhancerEnabled,
      denoiseIntensity: denoiseIntensity ?? this.denoiseIntensity,
      voiceClarityGain: voiceClarityGain ?? this.voiceClarityGain,
      fadeInMs: fadeInMs ?? this.fadeInMs,
      fadeOutMs: fadeOutMs ?? this.fadeOutMs,
      isDuckingEnabled: isDuckingEnabled ?? this.isDuckingEnabled,
      duckingAttenuation: duckingAttenuation ?? this.duckingAttenuation,
      isLoudVoiceEnabled: isLoudVoiceEnabled ?? this.isLoudVoiceEnabled,
      voiceBoost: voiceBoost ?? this.voiceBoost,
      modulationPreset: modulationPreset ?? this.modulationPreset,
      pitchShiftSemitones: pitchShiftSemitones ?? this.pitchShiftSemitones,
      bassEnhance: bassEnhance ?? this.bassEnhance,
      trebleCrisp: trebleCrisp ?? this.trebleCrisp,
    );
  }

  Map<String, dynamic> toJson() => {
        'isVoiceEnhancerEnabled': isVoiceEnhancerEnabled,
        'denoiseIntensity': denoiseIntensity,
        'voiceClarityGain': voiceClarityGain,
        'fadeInMs': fadeInMs,
        'fadeOutMs': fadeOutMs,
        'isDuckingEnabled': isDuckingEnabled,
        'duckingAttenuation': duckingAttenuation,
        'isLoudVoiceEnabled': isLoudVoiceEnabled,
        'voiceBoost': voiceBoost,
        'modulationPreset': modulationPreset.name,
        'pitchShiftSemitones': pitchShiftSemitones,
        'bassEnhance': bassEnhance,
        'trebleCrisp': trebleCrisp,
      };

  factory AudioEffectsConfig.fromJson(Map<String, dynamic> json) => AudioEffectsConfig(
        isVoiceEnhancerEnabled: json['isVoiceEnhancerEnabled'] as bool? ?? false,
        denoiseIntensity: (json['denoiseIntensity'] as num?)?.toDouble() ?? 0.70,
        voiceClarityGain: (json['voiceClarityGain'] as num?)?.toDouble() ?? 1.20,
        fadeInMs: (json['fadeInMs'] as num?)?.toInt() ?? 0,
        fadeOutMs: (json['fadeOutMs'] as num?)?.toInt() ?? 0,
        isDuckingEnabled: json['isDuckingEnabled'] as bool? ?? false,
        duckingAttenuation: (json['duckingAttenuation'] as num?)?.toDouble() ?? 0.30,
        isLoudVoiceEnabled: json['isLoudVoiceEnabled'] as bool? ?? false,
        voiceBoost: (json['voiceBoost'] as num?)?.toDouble() ?? 1.40,
        modulationPreset: VoiceModulationPreset.values.firstWhere(
          (p) => p.name == json['modulationPreset'],
          orElse: () => VoiceModulationPreset.natural,
        ),
        pitchShiftSemitones: (json['pitchShiftSemitones'] as num?)?.toDouble() ?? 0.0,
        bassEnhance: (json['bassEnhance'] as num?)?.toDouble() ?? 1.0,
        trebleCrisp: (json['trebleCrisp'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  List<Object?> get props => [
        isVoiceEnhancerEnabled,
        denoiseIntensity,
        voiceClarityGain,
        fadeInMs,
        fadeOutMs,
        isDuckingEnabled,
        duckingAttenuation,
        isLoudVoiceEnabled,
        voiceBoost,
        modulationPreset,
        pitchShiftSemitones,
        bassEnhance,
        trebleCrisp,
      ];
}
