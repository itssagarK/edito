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

enum DeHumMode {
  off,
  hz50EuropeAsia,
  hz60NorthAmerica,
  custom,
}

extension DeHumModeExtension on DeHumMode {
  String get label {
    switch (this) {
      case DeHumMode.off:
        return 'Off';
      case DeHumMode.hz50EuropeAsia:
        return '50 Hz (UK / EU / Asia / Africa)';
      case DeHumMode.hz60NorthAmerica:
        return '60 Hz (US / Canada / Americas)';
      case DeHumMode.custom:
        return 'Custom Ground Frequency';
    }
  }

  String get shortLabel {
    switch (this) {
      case DeHumMode.off:
        return 'Off';
      case DeHumMode.hz50EuropeAsia:
        return '50 Hz';
      case DeHumMode.hz60NorthAmerica:
        return '60 Hz';
      case DeHumMode.custom:
        return 'Custom';
    }
  }

  double get defaultFrequency {
    switch (this) {
      case DeHumMode.off:
      case DeHumMode.hz50EuropeAsia:
        return 50.0;
      case DeHumMode.hz60NorthAmerica:
        return 60.0;
      case DeHumMode.custom:
        return 50.0;
    }
  }
}

enum DeEsserMode {
  off,
  wideband,
  splitBandMale,
  splitBandFemale,
  crispMicrophone,
}

extension DeEsserModeExtension on DeEsserMode {
  String get label {
    switch (this) {
      case DeEsserMode.off:
        return 'Off';
      case DeEsserMode.wideband:
        return 'Wideband Natural (6.5 kHz)';
      case DeEsserMode.splitBandMale:
        return 'Male Dialogue (5.0 kHz)';
      case DeEsserMode.splitBandFemale:
        return 'Female Dialogue (7.5 kHz)';
      case DeEsserMode.crispMicrophone:
        return 'Condenser Splash (9.0 kHz)';
    }
  }

  double get targetFrequency {
    switch (this) {
      case DeEsserMode.off:
      case DeEsserMode.wideband:
        return 6500.0;
      case DeEsserMode.splitBandMale:
        return 5000.0;
      case DeEsserMode.splitBandFemale:
        return 7500.0;
      case DeEsserMode.crispMicrophone:
        return 9000.0;
    }
  }
}

enum RoomReverbPreset {
  none,
  studioVocalBooth,
  intimateRoom,
  warmAuditorium,
  cinematicCathedral,
  tunnelEcho,
  custom,
}

extension RoomReverbPresetExtension on RoomReverbPreset {
  String get label {
    switch (this) {
      case RoomReverbPreset.none:
        return 'Dry (Direct Sound)';
      case RoomReverbPreset.studioVocalBooth:
        return 'Vocal Booth';
      case RoomReverbPreset.intimateRoom:
        return 'Intimate Room';
      case RoomReverbPreset.warmAuditorium:
        return 'Warm Auditorium';
      case RoomReverbPreset.cinematicCathedral:
        return 'Cinematic Cathedral';
      case RoomReverbPreset.tunnelEcho:
        return 'Echo Tunnel';
      case RoomReverbPreset.custom:
        return 'Custom Space';
    }
  }

  String get description {
    switch (this) {
      case RoomReverbPreset.none:
        return 'Zero acoustic reflections';
      case RoomReverbPreset.studioVocalBooth:
        return 'Ultra-tight reflections, heavy acoustic damping';
      case RoomReverbPreset.intimateRoom:
        return 'Warm natural living room / studio reflections';
      case RoomReverbPreset.warmAuditorium:
        return 'Expansive theater acoustics with medium decay';
      case RoomReverbPreset.cinematicCathedral:
        return 'Lush, cavernous hall with long acoustic decay';
      case RoomReverbPreset.tunnelEcho:
        return 'Hard reflective concrete chamber';
      case RoomReverbPreset.custom:
        return 'Custom room size, damping, and wet/dry mix';
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
  final DeEsserMode deEsserMode;        // Mode with frequency targeting
  final double deEsserFrequency;        // 3000 to 10000 Hz (default 6500Hz)

  // Audio Restoration: De-Hum & Wind/Plosive Guard
  final DeHumMode deHumMode;
  final double deHumGain;               // -48.0 to -12.0 dB (default -32.0 dB)
  final int deHumHarmonics;             // 1 to 4 harmonics (default 3)
  final double customHumFreq;           // 40.0 to 120.0 Hz (default 50.0 Hz)
  final bool isWindDePlosiveEnabled;    // Sub-bass thump & wind noise guard
  final double dePlosiveIntensity;      // 0.0 to 1.0 (default 0.75)

  // Studio Room Reverb & Acoustic Simulation
  final bool isReverbEnabled;
  final RoomReverbPreset reverbPreset;
  final double reverbRoomSize;          // 0.0 to 1.0 (default 0.30)
  final double reverbDamping;           // 0.0 to 1.0 (default 0.50)
  final double reverbWetGain;           // 0.0 to 1.0 (default 0.15)
  final double reverbDryGain;           // 0.0 to 1.0 (default 0.90)
  final double reverbWidth;             // 0.0 to 1.0 (default 0.80)

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
    this.deEsserMode = DeEsserMode.off,
    this.deEsserFrequency = 6500.0,
    this.deHumMode = DeHumMode.off,
    this.deHumGain = -32.0,
    this.deHumHarmonics = 3,
    this.customHumFreq = 50.0,
    this.isWindDePlosiveEnabled = false,
    this.dePlosiveIntensity = 0.75,
    this.isReverbEnabled = false,
    this.reverbPreset = RoomReverbPreset.none,
    this.reverbRoomSize = 0.30,
    this.reverbDamping = 0.50,
    this.reverbWetGain = 0.15,
    this.reverbDryGain = 0.90,
    this.reverbWidth = 0.80,
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

  static AudioEffectsConfig getReverbPreset(RoomReverbPreset preset, {AudioEffectsConfig? base}) {
    final b = base ?? const AudioEffectsConfig();
    switch (preset) {
      case RoomReverbPreset.none:
        return b.copyWith(
          isReverbEnabled: false,
          reverbPreset: preset,
          reverbRoomSize: 0.10,
          reverbDamping: 0.80,
          reverbWetGain: 0.0,
          reverbDryGain: 1.0,
        );
      case RoomReverbPreset.studioVocalBooth:
        return b.copyWith(
          isReverbEnabled: true,
          reverbPreset: preset,
          reverbRoomSize: 0.12,
          reverbDamping: 0.85,
          reverbWetGain: 0.08,
          reverbDryGain: 0.95,
          reverbWidth: 0.70,
        );
      case RoomReverbPreset.intimateRoom:
        return b.copyWith(
          isReverbEnabled: true,
          reverbPreset: preset,
          reverbRoomSize: 0.28,
          reverbDamping: 0.65,
          reverbWetGain: 0.15,
          reverbDryGain: 0.90,
          reverbWidth: 0.80,
        );
      case RoomReverbPreset.warmAuditorium:
        return b.copyWith(
          isReverbEnabled: true,
          reverbPreset: preset,
          reverbRoomSize: 0.55,
          reverbDamping: 0.45,
          reverbWetGain: 0.22,
          reverbDryGain: 0.85,
          reverbWidth: 0.90,
        );
      case RoomReverbPreset.cinematicCathedral:
        return b.copyWith(
          isReverbEnabled: true,
          reverbPreset: preset,
          reverbRoomSize: 0.85,
          reverbDamping: 0.30,
          reverbWetGain: 0.35,
          reverbDryGain: 0.75,
          reverbWidth: 1.00,
        );
      case RoomReverbPreset.tunnelEcho:
        return b.copyWith(
          isReverbEnabled: true,
          reverbPreset: preset,
          reverbRoomSize: 0.75,
          reverbDamping: 0.10,
          reverbWetGain: 0.40,
          reverbDryGain: 0.70,
          reverbWidth: 1.00,
        );
      case RoomReverbPreset.custom:
        return b.copyWith(
          isReverbEnabled: true,
          reverbPreset: preset,
        );
    }
  }

  static AudioEffectsConfig getDeHumConfig(DeHumMode mode, {AudioEffectsConfig? base}) {
    final b = base ?? const AudioEffectsConfig();
    switch (mode) {
      case DeHumMode.off:
        return b.copyWith(deHumMode: mode);
      case DeHumMode.hz50EuropeAsia:
        return b.copyWith(
          deHumMode: mode,
          customHumFreq: 50.0,
          deHumHarmonics: 3,
          deHumGain: -32.0,
        );
      case DeHumMode.hz60NorthAmerica:
        return b.copyWith(
          deHumMode: mode,
          customHumFreq: 60.0,
          deHumHarmonics: 3,
          deHumGain: -32.0,
        );
      case DeHumMode.custom:
        return b.copyWith(deHumMode: mode);
    }
  }

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
    DeEsserMode? deEsserMode,
    double? deEsserFrequency,
    DeHumMode? deHumMode,
    double? deHumGain,
    int? deHumHarmonics,
    double? customHumFreq,
    bool? isWindDePlosiveEnabled,
    double? dePlosiveIntensity,
    bool? isReverbEnabled,
    RoomReverbPreset? reverbPreset,
    double? reverbRoomSize,
    double? reverbDamping,
    double? reverbWetGain,
    double? reverbDryGain,
    double? reverbWidth,
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
      deEsserMode: deEsserMode ?? this.deEsserMode,
      deEsserFrequency: deEsserFrequency ?? this.deEsserFrequency,
      deHumMode: deHumMode ?? this.deHumMode,
      deHumGain: deHumGain ?? this.deHumGain,
      deHumHarmonics: deHumHarmonics ?? this.deHumHarmonics,
      customHumFreq: customHumFreq ?? this.customHumFreq,
      isWindDePlosiveEnabled: isWindDePlosiveEnabled ?? this.isWindDePlosiveEnabled,
      dePlosiveIntensity: dePlosiveIntensity ?? this.dePlosiveIntensity,
      isReverbEnabled: isReverbEnabled ?? this.isReverbEnabled,
      reverbPreset: reverbPreset ?? this.reverbPreset,
      reverbRoomSize: reverbRoomSize ?? this.reverbRoomSize,
      reverbDamping: reverbDamping ?? this.reverbDamping,
      reverbWetGain: reverbWetGain ?? this.reverbWetGain,
      reverbDryGain: reverbDryGain ?? this.reverbDryGain,
      reverbWidth: reverbWidth ?? this.reverbWidth,
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
        'deEsserMode': deEsserMode.name,
        'deEsserFrequency': deEsserFrequency,
        'deHumMode': deHumMode.name,
        'deHumGain': deHumGain,
        'deHumHarmonics': deHumHarmonics,
        'customHumFreq': customHumFreq,
        'isWindDePlosiveEnabled': isWindDePlosiveEnabled,
        'dePlosiveIntensity': dePlosiveIntensity,
        'isReverbEnabled': isReverbEnabled,
        'reverbPreset': reverbPreset.name,
        'reverbRoomSize': reverbRoomSize,
        'reverbDamping': reverbDamping,
        'reverbWetGain': reverbWetGain,
        'reverbDryGain': reverbDryGain,
        'reverbWidth': reverbWidth,
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

  factory AudioEffectsConfig.fromJson(Map<String, dynamic> json) {
    final deEsserRaw = (json['deEsserIntensity'] as num?)?.toDouble() ?? 0.0;
    final deEsserMode = DeEsserMode.values.firstWhere(
      (m) => m.name == json['deEsserMode'],
      orElse: () => deEsserRaw > 0.0 ? DeEsserMode.wideband : DeEsserMode.off,
    );

    final deHumMode = DeHumMode.values.firstWhere(
      (m) => m.name == json['deHumMode'],
      orElse: () => DeHumMode.off,
    );

    final reverbPreset = RoomReverbPreset.values.firstWhere(
      (r) => r.name == json['reverbPreset'],
      orElse: () => RoomReverbPreset.none,
    );

    return AudioEffectsConfig(
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
      deEsserIntensity: deEsserRaw,
      deEsserMode: deEsserMode,
      deEsserFrequency: (json['deEsserFrequency'] as num?)?.toDouble() ?? 6500.0,
      deHumMode: deHumMode,
      deHumGain: (json['deHumGain'] as num?)?.toDouble() ?? -32.0,
      deHumHarmonics: (json['deHumHarmonics'] as num?)?.toInt() ?? 3,
      customHumFreq: (json['customHumFreq'] as num?)?.toDouble() ?? 50.0,
      isWindDePlosiveEnabled: json['isWindDePlosiveEnabled'] as bool? ?? false,
      dePlosiveIntensity: (json['dePlosiveIntensity'] as num?)?.toDouble() ?? 0.75,
      isReverbEnabled: json['isReverbEnabled'] as bool? ?? false,
      reverbPreset: reverbPreset,
      reverbRoomSize: (json['reverbRoomSize'] as num?)?.toDouble() ?? 0.30,
      reverbDamping: (json['reverbDamping'] as num?)?.toDouble() ?? 0.50,
      reverbWetGain: (json['reverbWetGain'] as num?)?.toDouble() ?? 0.15,
      reverbDryGain: (json['reverbDryGain'] as num?)?.toDouble() ?? 0.90,
      reverbWidth: (json['reverbWidth'] as num?)?.toDouble() ?? 0.80,
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
  }

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
        deEsserMode,
        deEsserFrequency,
        deHumMode,
        deHumGain,
        deHumHarmonics,
        customHumFreq,
        isWindDePlosiveEnabled,
        dePlosiveIntensity,
        isReverbEnabled,
        reverbPreset,
        reverbRoomSize,
        reverbDamping,
        reverbWetGain,
        reverbDryGain,
        reverbWidth,
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
