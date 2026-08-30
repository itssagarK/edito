import 'package:equatable/equatable.dart';

class AudioEffectsConfig extends Equatable {
  final bool isVoiceEnhancerEnabled;
  final double denoiseIntensity;       // 0.0 to 1.0 (70% standard)
  final double voiceClarityGain;        // 0.0 to 2.0 (1.0 = standard)
  final int fadeInMs;                  // 0 to 5000ms
  final int fadeOutMs;                 // 0 to 5000ms
  final bool isDuckingEnabled;         // Auto duck background during foreground speech
  final double duckingAttenuation;     // 0.1 (-20dB) to 0.8 (-2dB), default 0.3 (-10dB)

  const AudioEffectsConfig({
    this.isVoiceEnhancerEnabled = false,
    this.denoiseIntensity = 0.70,
    this.voiceClarityGain = 1.20,
    this.fadeInMs = 0,
    this.fadeOutMs = 0,
    this.isDuckingEnabled = false,
    this.duckingAttenuation = 0.30,
  });

  AudioEffectsConfig copyWith({
    bool? isVoiceEnhancerEnabled,
    double? denoiseIntensity,
    double? voiceClarityGain,
    int? fadeInMs,
    int? fadeOutMs,
    bool? isDuckingEnabled,
    double? duckingAttenuation,
  }) {
    return AudioEffectsConfig(
      isVoiceEnhancerEnabled: isVoiceEnhancerEnabled ?? this.isVoiceEnhancerEnabled,
      denoiseIntensity: denoiseIntensity ?? this.denoiseIntensity,
      voiceClarityGain: voiceClarityGain ?? this.voiceClarityGain,
      fadeInMs: fadeInMs ?? this.fadeInMs,
      fadeOutMs: fadeOutMs ?? this.fadeOutMs,
      isDuckingEnabled: isDuckingEnabled ?? this.isDuckingEnabled,
      duckingAttenuation: duckingAttenuation ?? this.duckingAttenuation,
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
      };

  factory AudioEffectsConfig.fromJson(Map<String, dynamic> json) => AudioEffectsConfig(
        isVoiceEnhancerEnabled: json['isVoiceEnhancerEnabled'] as bool? ?? false,
        denoiseIntensity: (json['denoiseIntensity'] as num?)?.toDouble() ?? 0.70,
        voiceClarityGain: (json['voiceClarityGain'] as num?)?.toDouble() ?? 1.20,
        fadeInMs: (json['fadeInMs'] as num?)?.toInt() ?? 0,
        fadeOutMs: (json['fadeOutMs'] as num?)?.toInt() ?? 0,
        isDuckingEnabled: json['isDuckingEnabled'] as bool? ?? false,
        duckingAttenuation: (json['duckingAttenuation'] as num?)?.toDouble() ?? 0.30,
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
      ];
}
