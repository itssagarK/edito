import 'package:equatable/equatable.dart';

/// CapCut Pro AI Vocal Isolation & Separation Modes
enum VocalIsolationMode {
  none,
  isolateVocals,
  removeVocals,
  voiceBoost,
  musicBoost,
  custom,
}

extension VocalIsolationModeExtension on VocalIsolationMode {
  String get label {
    switch (this) {
      case VocalIsolationMode.none:
        return 'Off';
      case VocalIsolationMode.isolateVocals:
        return 'Keep Vocals';
      case VocalIsolationMode.removeVocals:
        return 'Remove Vocals';
      case VocalIsolationMode.voiceBoost:
        return 'Voice Boost';
      case VocalIsolationMode.musicBoost:
        return 'Music Boost';
      case VocalIsolationMode.custom:
        return 'Custom Mix';
    }
  }

  String get description {
    switch (this) {
      case VocalIsolationMode.none:
        return 'Original mixed soundtrack audio';
      case VocalIsolationMode.isolateVocals:
        return 'Extracts clear dialogue and vocals while attenuating background music and noise';
      case VocalIsolationMode.removeVocals:
        return 'Suppresses pan-centered lead singing and dialogue to create an instrumental track';
      case VocalIsolationMode.voiceBoost:
        return 'Enhances vocal speech presence (+6dB) with dynamic speech formant amplification';
      case VocalIsolationMode.musicBoost:
        return 'Attenuates vocals (-10dB) to emphasize background instrumentation and beats';
      case VocalIsolationMode.custom:
        return 'Granular manual control over vocal gain, accompaniment balance, and noise gate';
    }
  }

  double get defaultVocalGain {
    switch (this) {
      case VocalIsolationMode.none:
        return 0.0;
      case VocalIsolationMode.isolateVocals:
        return 3.0;
      case VocalIsolationMode.removeVocals:
        return -24.0;
      case VocalIsolationMode.voiceBoost:
        return 6.0;
      case VocalIsolationMode.musicBoost:
        return -12.0;
      case VocalIsolationMode.custom:
        return 0.0;
    }
  }

  double get defaultInstrumentalGain {
    switch (this) {
      case VocalIsolationMode.none:
        return 0.0;
      case VocalIsolationMode.isolateVocals:
        return -24.0;
      case VocalIsolationMode.removeVocals:
        return 0.0;
      case VocalIsolationMode.voiceBoost:
        return -6.0;
      case VocalIsolationMode.musicBoost:
        return 3.0;
      case VocalIsolationMode.custom:
        return 0.0;
    }
  }
}

/// Vocal Separation Audio Engine
enum IsolationEngine {
  centerChannelPhase,
  spectralFormantFilter,
  adaptiveDenoiseGate,
}

extension IsolationEngineExtension on IsolationEngine {
  String get label {
    switch (this) {
      case IsolationEngine.centerChannelPhase:
        return 'M/S Phase Cancellation';
      case IsolationEngine.spectralFormantFilter:
        return 'Speech Formant Filter';
      case IsolationEngine.adaptiveDenoiseGate:
        return 'Spectral Noise Gate';
    }
  }

  String get description {
    switch (this) {
      case IsolationEngine.centerChannelPhase:
        return 'Mid/Side channel separation eliminating or extracting center pan vocals';
      case IsolationEngine.spectralFormantFilter:
        return 'Parametric speech fundamental bandpass and vowel formant extraction';
      case IsolationEngine.adaptiveDenoiseGate:
        return 'Dynamic expansion gating suppressing quiet background room noise';
    }
  }
}

/// CapCut Pro AI Vocal Isolation & Audio Stem Splitter Configuration
class VocalIsolationConfig extends Equatable {
  final bool isEnabled;
  final VocalIsolationMode mode;
  final IsolationEngine engine;
  final double vocalGain; // -24.0 to +12.0 dB
  final double instrumentalGain; // -24.0 to +12.0 dB
  final double speechClarity; // 0.0 to 1.0 (treble harmonic presence)
  final double noiseThreshold; // -60.0 to -10.0 dB
  final double stereoWidth; // 0.0 to 2.0 (0.0 = mono, 1.0 = natural, 2.0 = wide)
  final bool brickwallLimiter; // True-peak ceiling safeguard to eliminate digital clipping

  const VocalIsolationConfig({
    this.isEnabled = false,
    this.mode = VocalIsolationMode.none,
    this.engine = IsolationEngine.centerChannelPhase,
    this.vocalGain = 0.0,
    this.instrumentalGain = 0.0,
    this.speechClarity = 0.75,
    this.noiseThreshold = -36.0,
    this.stereoWidth = 1.0,
    this.brickwallLimiter = true,
  });

  /// Factory helper for initializing preset configurations
  static VocalIsolationConfig fromMode(VocalIsolationMode mode) {
    if (mode == VocalIsolationMode.none) {
      return const VocalIsolationConfig();
    }
    return VocalIsolationConfig(
      isEnabled: true,
      mode: mode,
      vocalGain: mode.defaultVocalGain,
      instrumentalGain: mode.defaultInstrumentalGain,
    );
  }

  VocalIsolationConfig copyWith({
    bool? isEnabled,
    VocalIsolationMode? mode,
    IsolationEngine? engine,
    double? vocalGain,
    double? instrumentalGain,
    double? speechClarity,
    double? noiseThreshold,
    double? stereoWidth,
    bool? brickwallLimiter,
  }) {
    return VocalIsolationConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      engine: engine ?? this.engine,
      vocalGain: vocalGain ?? this.vocalGain,
      instrumentalGain: instrumentalGain ?? this.instrumentalGain,
      speechClarity: speechClarity ?? this.speechClarity,
      noiseThreshold: noiseThreshold ?? this.noiseThreshold,
      stereoWidth: stereoWidth ?? this.stereoWidth,
      brickwallLimiter: brickwallLimiter ?? this.brickwallLimiter,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.index,
      'engine': engine.index,
      'vocalGain': vocalGain,
      'instrumentalGain': instrumentalGain,
      'speechClarity': speechClarity,
      'noiseThreshold': noiseThreshold,
      'stereoWidth': stereoWidth,
      'brickwallLimiter': brickwallLimiter,
    };
  }

  factory VocalIsolationConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VocalIsolationConfig();

    return VocalIsolationConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: json['mode'] != null && json['mode'] is int
          ? VocalIsolationMode.values[(json['mode'] as int).clamp(0, VocalIsolationMode.values.length - 1)]
          : VocalIsolationMode.none,
      engine: json['engine'] != null && json['engine'] is int
          ? IsolationEngine.values[(json['engine'] as int).clamp(0, IsolationEngine.values.length - 1)]
          : IsolationEngine.centerChannelPhase,
      vocalGain: (json['vocalGain'] as num?)?.toDouble() ?? 0.0,
      instrumentalGain: (json['instrumentalGain'] as num?)?.toDouble() ?? 0.0,
      speechClarity: (json['speechClarity'] as num?)?.toDouble() ?? 0.75,
      noiseThreshold: (json['noiseThreshold'] as num?)?.toDouble() ?? -36.0,
      stereoWidth: (json['stereoWidth'] as num?)?.toDouble() ?? 1.0,
      brickwallLimiter: json['brickwallLimiter'] as bool? ?? true,
    );
  }

  String get badge {
    if (!isEnabled || mode == VocalIsolationMode.none) return '';
    final modeStr = mode.label.toUpperCase();
    final clarityPct = (speechClarity * 100).round();
    return '🎙️ VOCAL ISOLATION ($modeStr • $clarityPct% CLARITY)';
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        engine,
        vocalGain,
        instrumentalGain,
        speechClarity,
        noiseThreshold,
        stereoWidth,
        brickwallLimiter,
      ];
}
