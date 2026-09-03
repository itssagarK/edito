import 'package:equatable/equatable.dart';

enum EnhanceModelPreset {
  standard,
  ultraCinema8k,
  crispPhoto,
  cleanDenoise,
  vibrantHdr,
}

extension EnhanceModelPresetExtension on EnhanceModelPreset {
  String get label {
    switch (this) {
      case EnhanceModelPreset.standard:
        return 'Standard 8K Neural';
      case EnhanceModelPreset.ultraCinema8k:
        return '8K Cinema Master';
      case EnhanceModelPreset.crispPhoto:
        return 'Ultra-Sharp Photo';
      case EnhanceModelPreset.cleanDenoise:
        return 'Clean AI Denoise';
      case EnhanceModelPreset.vibrantHdr:
        return 'Vibrant HDR Pop';
    }
  }

  String get description {
    switch (this) {
      case EnhanceModelPreset.standard:
        return 'Balanced 8K super-resolution upscaling';
      case EnhanceModelPreset.ultraCinema8k:
        return 'Maximum micro-contrast & edge synthesis for cinematic 8K UHD';
      case EnhanceModelPreset.crispPhoto:
        return 'High-fidelity edge sharpening & texture reconstruction for photos';
      case EnhanceModelPreset.cleanDenoise:
        return 'Deep artifact & grain reduction with edge preservation';
      case EnhanceModelPreset.vibrantHdr:
        return 'Dynamic range expansion with saturated color vibrancy';
    }
  }
}

class VideoEnhancementConfig extends Equatable {
  final bool is8kUpscaleEnabled;
  final bool isAiSuperResolutionEnabled;
  final double sharpness;          // 0.0 to 2.0 (1.0 = normal)
  final double deNoise;            // 0.0 to 1.0 (0.0 = off)
  final bool isHdrToneMapping;     // Dynamic range peak brightness expansion
  final double clarity;            // 0.0 to 2.0 (1.0 = normal)
  final bool isColorPop;           // High vibrancy color pop
  final EnhanceModelPreset modelPreset;

  const VideoEnhancementConfig({
    this.is8kUpscaleEnabled = false,
    this.isAiSuperResolutionEnabled = false,
    this.sharpness = 1.0,
    this.deNoise = 0.0,
    this.isHdrToneMapping = false,
    this.clarity = 1.0,
    this.isColorPop = false,
    this.modelPreset = EnhanceModelPreset.standard,
  });

  bool get hasActiveEnhancements =>
      is8kUpscaleEnabled ||
      isAiSuperResolutionEnabled ||
      sharpness != 1.0 ||
      deNoise > 0.0 ||
      isHdrToneMapping ||
      clarity != 1.0 ||
      isColorPop;

  VideoEnhancementConfig copyWith({
    bool? is8kUpscaleEnabled,
    bool? isAiSuperResolutionEnabled,
    double? sharpness,
    double? deNoise,
    bool? isHdrToneMapping,
    double? clarity,
    bool? isColorPop,
    EnhanceModelPreset? modelPreset,
  }) {
    return VideoEnhancementConfig(
      is8kUpscaleEnabled: is8kUpscaleEnabled ?? this.is8kUpscaleEnabled,
      isAiSuperResolutionEnabled: isAiSuperResolutionEnabled ?? this.isAiSuperResolutionEnabled,
      sharpness: sharpness ?? this.sharpness,
      deNoise: deNoise ?? this.deNoise,
      isHdrToneMapping: isHdrToneMapping ?? this.isHdrToneMapping,
      clarity: clarity ?? this.clarity,
      isColorPop: isColorPop ?? this.isColorPop,
      modelPreset: modelPreset ?? this.modelPreset,
    );
  }

  Map<String, dynamic> toJson() => {
        'is8kUpscaleEnabled': is8kUpscaleEnabled,
        'isAiSuperResolutionEnabled': isAiSuperResolutionEnabled,
        'sharpness': sharpness,
        'deNoise': deNoise,
        'isHdrToneMapping': isHdrToneMapping,
        'clarity': clarity,
        'isColorPop': isColorPop,
        'modelPreset': modelPreset.name,
      };

  factory VideoEnhancementConfig.fromJson(Map<String, dynamic> json) => VideoEnhancementConfig(
        is8kUpscaleEnabled: json['is8kUpscaleEnabled'] as bool? ?? false,
        isAiSuperResolutionEnabled: json['isAiSuperResolutionEnabled'] as bool? ?? false,
        sharpness: (json['sharpness'] as num?)?.toDouble() ?? 1.0,
        deNoise: (json['deNoise'] as num?)?.toDouble() ?? 0.0,
        isHdrToneMapping: json['isHdrToneMapping'] as bool? ?? false,
        clarity: (json['clarity'] as num?)?.toDouble() ?? 1.0,
        isColorPop: json['isColorPop'] as bool? ?? false,
        modelPreset: EnhanceModelPreset.values.firstWhere(
          (p) => p.name == json['modelPreset'],
          orElse: () => EnhanceModelPreset.standard,
        ),
      );

  @override
  List<Object?> get props => [
        is8kUpscaleEnabled,
        isAiSuperResolutionEnabled,
        sharpness,
        deNoise,
        isHdrToneMapping,
        clarity,
        isColorPop,
        modelPreset,
      ];
}
