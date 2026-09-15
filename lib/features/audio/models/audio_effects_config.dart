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

enum VocalIsolationMode {
  none,
  cleanSpeech,
  isolateVocals,
  removeVocals,
}

extension VocalIsolationModeExtension on VocalIsolationMode {
  String get label {
    switch (this) {
      case VocalIsolationMode.none:
        return 'Standard Pass';
      case VocalIsolationMode.cleanSpeech:
        return 'Clean Speech';
      case VocalIsolationMode.isolateVocals:
        return 'Isolate Vocals';
      case VocalIsolationMode.removeVocals:
        return 'Instrumental (Remove Vocals)';
    }
  }

  String get description {
    switch (this) {
      case VocalIsolationMode.none:
        return 'No isolation filter applied';
      case VocalIsolationMode.cleanSpeech:
        return 'Speech presence enhancement with background noise reduction';
      case VocalIsolationMode.isolateVocals:
        return 'Aggressive formant bandpass & multi-band vocal gate';
      case VocalIsolationMode.removeVocals:
        return 'Cancels centered vocal frequencies for karaoke / background music';
    }
  }
}

enum EqualizerPreset {
  flat,
  podcastWarmth,
  bassBoost,
  trebleSparkle,
  vocalAir,
  telephone,
  deMuddy,
  custom,
}

extension EqualizerPresetExtension on EqualizerPreset {
  String get label {
    switch (this) {
      case EqualizerPreset.flat:
        return 'Flat / Reset';
      case EqualizerPreset.podcastWarmth:
        return 'Podcast Warmth';
      case EqualizerPreset.bassBoost:
        return 'Deep Bass';
      case EqualizerPreset.trebleSparkle:
        return 'Treble Sparkle';
      case EqualizerPreset.vocalAir:
        return 'Vocal Air';
      case EqualizerPreset.telephone:
        return 'Lo-Fi Telephone';
      case EqualizerPreset.deMuddy:
        return 'De-Muddy Boxiness';
      case EqualizerPreset.custom:
        return 'Custom Curve';
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
  final double duckingAttenuation;     // 0.03 (-30dB) to 0.50 (-6dB), default 0.30 (-10dB)
  final double duckingThresholdDb;     // -40.0 to -10.0 dB
  final int duckingAttackMs;           // 10 to 300 ms
  final int duckingReleaseMs;          // 50 to 1500 ms

  // Vocal Isolation & De-Esser
  final VocalIsolationMode vocalIsolationMode;
  final double vocalIsolationIntensity; // 0.0 to 1.0 (default 0.80)
  final double deEsserIntensity;        // 0.0 to 1.0 (0.0 = off)

  // Parametric Equalizer Suite
  final bool isEqualizerEnabled;
  final EqualizerPreset equalizerPreset;
  final double eqLowGain;              // -15.0 to +15.0 dB
  final double eqLowFreq;              // 30 to 400 Hz (default 100Hz)
  final double eqMidGain;              // -15.0 to +15.0 dB
  final double eqMidFreq;              // 400 to 5000 Hz (default 2500Hz)
  final double eqMidQ;                 // 0.5 to 3.0 (default 1.0)
  final double eqHighGain;             // -15.0 to +15.0 dB
  final double eqHighFreq;             // 5000 to 18000 Hz (default 10000Hz)
  final double highPassCutoff;         // 0 to 300 Hz (0 = off)
  final double lowPassCutoff;          // 4000 to 22000 Hz (22000 = off)

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
    this.duckingThresholdDb = -20.0,
    this.duckingAttackMs = 50,
    this.duckingReleaseMs = 300,
    this.vocalIsolationMode = VocalIsolationMode.none,
    this.vocalIsolationIntensity = 0.80,
    this.deEsserIntensity = 0.0,
    this.isEqualizerEnabled = false,
    this.equalizerPreset = EqualizerPreset.flat,
    this.eqLowGain = 0.0,
    this.eqLowFreq = 100.0,
    this.eqMidGain = 0.0,
    this.eqMidFreq = 2500.0,
    this.eqMidQ = 1.0,
    this.eqHighGain = 0.0,
    this.eqHighFreq = 10000.0,
    this.highPassCutoff = 0.0,
    this.lowPassCutoff = 22000.0,
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
    double? duckingThresholdDb,
    int? duckingAttackMs,
    int? duckingReleaseMs,
    VocalIsolationMode? vocalIsolationMode,
    double? vocalIsolationIntensity,
    double? deEsserIntensity,
    bool? isEqualizerEnabled,
    EqualizerPreset? equalizerPreset,
    double? eqLowGain,
    double? eqLowFreq,
    double? eqMidGain,
    double? eqMidFreq,
    double? eqMidQ,
    double? eqHighGain,
    double? eqHighFreq,
    double? highPassCutoff,
    double? lowPassCutoff,
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
      duckingThresholdDb: duckingThresholdDb ?? this.duckingThresholdDb,
      duckingAttackMs: duckingAttackMs ?? this.duckingAttackMs,
      duckingReleaseMs: duckingReleaseMs ?? this.duckingReleaseMs,
      vocalIsolationMode: vocalIsolationMode ?? this.vocalIsolationMode,
      vocalIsolationIntensity: vocalIsolationIntensity ?? this.vocalIsolationIntensity,
      deEsserIntensity: deEsserIntensity ?? this.deEsserIntensity,
      isEqualizerEnabled: isEqualizerEnabled ?? this.isEqualizerEnabled,
      equalizerPreset: equalizerPreset ?? this.equalizerPreset,
      eqLowGain: eqLowGain ?? this.eqLowGain,
      eqLowFreq: eqLowFreq ?? this.eqLowFreq,
      eqMidGain: eqMidGain ?? this.eqMidGain,
      eqMidFreq: eqMidFreq ?? this.eqMidFreq,
      eqMidQ: eqMidQ ?? this.eqMidQ,
      eqHighGain: eqHighGain ?? this.eqHighGain,
      eqHighFreq: eqHighFreq ?? this.eqHighFreq,
      highPassCutoff: highPassCutoff ?? this.highPassCutoff,
      lowPassCutoff: lowPassCutoff ?? this.lowPassCutoff,
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
        'duckingThresholdDb': duckingThresholdDb,
        'duckingAttackMs': duckingAttackMs,
        'duckingReleaseMs': duckingReleaseMs,
        'vocalIsolationMode': vocalIsolationMode.name,
        'vocalIsolationIntensity': vocalIsolationIntensity,
        'deEsserIntensity': deEsserIntensity,
        'isEqualizerEnabled': isEqualizerEnabled,
        'equalizerPreset': equalizerPreset.name,
        'eqLowGain': eqLowGain,
        'eqLowFreq': eqLowFreq,
        'eqMidGain': eqMidGain,
        'eqMidFreq': eqMidFreq,
        'eqMidQ': eqMidQ,
        'eqHighGain': eqHighGain,
        'eqHighFreq': eqHighFreq,
        'highPassCutoff': highPassCutoff,
        'lowPassCutoff': lowPassCutoff,
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
        duckingThresholdDb: (json['duckingThresholdDb'] as num?)?.toDouble() ?? -20.0,
        duckingAttackMs: (json['duckingAttackMs'] as num?)?.toInt() ?? 50,
        duckingReleaseMs: (json['duckingReleaseMs'] as num?)?.toInt() ?? 300,
        vocalIsolationMode: VocalIsolationMode.values.firstWhere(
          (m) => m.name == json['vocalIsolationMode'],
          orElse: () => VocalIsolationMode.none,
        ),
        vocalIsolationIntensity: (json['vocalIsolationIntensity'] as num?)?.toDouble() ?? 0.80,
        deEsserIntensity: (json['deEsserIntensity'] as num?)?.toDouble() ?? 0.0,
        isEqualizerEnabled: json['isEqualizerEnabled'] as bool? ?? false,
        equalizerPreset: EqualizerPreset.values.firstWhere(
          (e) => e.name == json['equalizerPreset'],
          orElse: () => EqualizerPreset.flat,
        ),
        eqLowGain: (json['eqLowGain'] as num?)?.toDouble() ?? 0.0,
        eqLowFreq: (json['eqLowFreq'] as num?)?.toDouble() ?? 100.0,
        eqMidGain: (json['eqMidGain'] as num?)?.toDouble() ?? 0.0,
        eqMidFreq: (json['eqMidFreq'] as num?)?.toDouble() ?? 2500.0,
        eqMidQ: (json['eqMidQ'] as num?)?.toDouble() ?? 1.0,
        eqHighGain: (json['eqHighGain'] as num?)?.toDouble() ?? 0.0,
        eqHighFreq: (json['eqHighFreq'] as num?)?.toDouble() ?? 10000.0,
        highPassCutoff: (json['highPassCutoff'] as num?)?.toDouble() ?? 0.0,
        lowPassCutoff: (json['lowPassCutoff'] as num?)?.toDouble() ?? 22000.0,
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
        duckingThresholdDb,
        duckingAttackMs,
        duckingReleaseMs,
        vocalIsolationMode,
        vocalIsolationIntensity,
        deEsserIntensity,
        isEqualizerEnabled,
        equalizerPreset,
        eqLowGain,
        eqLowFreq,
        eqMidGain,
        eqMidFreq,
        eqMidQ,
        eqHighGain,
        eqHighFreq,
        highPassCutoff,
        lowPassCutoff,
        isLoudVoiceEnabled,
        voiceBoost,
        modulationPreset,
        pitchShiftSemitones,
        bassEnhance,
        trebleCrisp,
      ];
}
