import 'package:equatable/equatable.dart';

/// Preset digital corruption and video datamoshing glitch profiles.
enum DatamoshProfile {
  keyframeDropMosh,
  rgbDisplacementGlitch,
  macroblockCompression,
  vhsTrackingLoss,
  cyberCorruptDecay;

  String get displayName {
    switch (this) {
      case DatamoshProfile.keyframeDropMosh:
        return 'Keyframe Dropout Mosh';
      case DatamoshProfile.rgbDisplacementGlitch:
        return 'RGB Spectral Displacement';
      case DatamoshProfile.macroblockCompression:
        return 'Macroblock Compression';
      case DatamoshProfile.vhsTrackingLoss:
        return 'VHS Head Tracking Loss';
      case DatamoshProfile.cyberCorruptDecay:
        return 'Cyber Bit-Corruption Decay';
    }
  }

  String get description {
    switch (this) {
      case DatamoshProfile.keyframeDropMosh:
        return 'Simulates missing I-frame keyframes causing previous pixel vectors to melt and smear';
      case DatamoshProfile.rgbDisplacementGlitch:
        return 'Horizontal chromatic channel shifts, split color fringes, and scanline tears';
      case DatamoshProfile.macroblockCompression:
        return 'Blocky DCT pixel quantization and severe low-bitrate compression artifacts';
      case DatamoshProfile.vhsTrackingLoss:
        return 'Skewed horizontal sync tearing, magnetic fuzz, and head-switching static';
      case DatamoshProfile.cyberCorruptDecay:
        return 'Violent digital noise bursts, bit-flip corruption, and buffer overflow smears';
    }
  }
}

/// Configuration for datamoshing, digital compression artifacts, and RGB glitch VFX.
class DatamoshGlitchConfig extends Equatable {
  final bool isEnabled;
  final DatamoshProfile profile;
  final double intensity; // 0.0 to 1.0 (magnitude of displacement / corruption)
  final double frequency; // 0.2 to 3.0 (burst rate per second)
  final double blockSize; // 4.0 to 32.0 (pixel macroblock quantization size)
  final bool preserveColor; // Preserve chroma channels or allow color smears

  const DatamoshGlitchConfig({
    this.isEnabled = false,
    this.profile = DatamoshProfile.keyframeDropMosh,
    this.intensity = 0.65,
    this.frequency = 1.0,
    this.blockSize = 16.0,
    this.preserveColor = false,
  });

  bool get isActive => isEnabled && intensity > 0.01;

  // Curated presets
  static const DatamoshGlitchConfig classicDatamosh = DatamoshGlitchConfig(
    isEnabled: true,
    profile: DatamoshProfile.keyframeDropMosh,
    intensity: 0.70,
    frequency: 1.0,
    blockSize: 16.0,
    preserveColor: false,
  );

  static const DatamoshGlitchConfig cyberpunkGlitch = DatamoshGlitchConfig(
    isEnabled: true,
    profile: DatamoshProfile.rgbDisplacementGlitch,
    intensity: 0.65,
    frequency: 1.4,
    blockSize: 8.0,
    preserveColor: true,
  );

  static const DatamoshGlitchConfig extremeCompression = DatamoshGlitchConfig(
    isEnabled: true,
    profile: DatamoshProfile.macroblockCompression,
    intensity: 0.80,
    frequency: 0.8,
    blockSize: 24.0,
    preserveColor: false,
  );

  static const DatamoshGlitchConfig vhsTapeTear = DatamoshGlitchConfig(
    isEnabled: true,
    profile: DatamoshProfile.vhsTrackingLoss,
    intensity: 0.60,
    frequency: 1.2,
    blockSize: 12.0,
    preserveColor: true,
  );

  static const DatamoshGlitchConfig fatalDataDecay = DatamoshGlitchConfig(
    isEnabled: true,
    profile: DatamoshProfile.cyberCorruptDecay,
    intensity: 0.90,
    frequency: 2.0,
    blockSize: 16.0,
    preserveColor: false,
  );

  DatamoshGlitchConfig copyWith({
    bool? isEnabled,
    DatamoshProfile? profile,
    double? intensity,
    double? frequency,
    double? blockSize,
    bool? preserveColor,
  }) {
    return DatamoshGlitchConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      profile: profile ?? this.profile,
      intensity: intensity ?? this.intensity,
      frequency: frequency ?? this.frequency,
      blockSize: blockSize ?? this.blockSize,
      preserveColor: preserveColor ?? this.preserveColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'profile': profile.name,
      'intensity': intensity,
      'frequency': frequency,
      'blockSize': blockSize,
      'preserveColor': preserveColor,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory DatamoshGlitchConfig.fromMap(Map<String, dynamic> map) {
    return DatamoshGlitchConfig(
      isEnabled: map['isEnabled'] as bool? ?? false,
      profile: DatamoshProfile.values.firstWhere(
        (e) => e.name == map['profile'],
        orElse: () => DatamoshProfile.keyframeDropMosh,
      ),
      intensity: (map['intensity'] as num?)?.toDouble() ?? 0.65,
      frequency: (map['frequency'] as num?)?.toDouble() ?? 1.0,
      blockSize: (map['blockSize'] as num?)?.toDouble() ?? 16.0,
      preserveColor: map['preserveColor'] as bool? ?? false,
    );
  }

  factory DatamoshGlitchConfig.fromJson(Map<String, dynamic> json) =>
      DatamoshGlitchConfig.fromMap(json);

  @override
  List<Object?> get props => [
        isEnabled,
        profile,
        intensity,
        frequency,
        blockSize,
        preserveColor,
      ];
}
