import 'package:equatable/equatable.dart';

enum HdResolution {
  hd720p,
  fhd1080p,
  qhd1440p,
  uhd4k,
  uhd8k,
}

extension HdResolutionExtension on HdResolution {
  int get width {
    switch (this) {
      case HdResolution.hd720p: return 1280;
      case HdResolution.fhd1080p: return 1920;
      case HdResolution.qhd1440p: return 2560;
      case HdResolution.uhd4k: return 3840;
      case HdResolution.uhd8k: return 7680;
    }
  }

  int get height {
    switch (this) {
      case HdResolution.hd720p: return 720;
      case HdResolution.fhd1080p: return 1080;
      case HdResolution.qhd1440p: return 1440;
      case HdResolution.uhd4k: return 2160;
      case HdResolution.uhd8k: return 4320;
    }
  }

  String get label {
    switch (this) {
      case HdResolution.hd720p: return '720p HD';
      case HdResolution.fhd1080p: return '1080p Full HD';
      case HdResolution.qhd1440p: return '1440p 2K QHD';
      case HdResolution.uhd4k: return '4K Ultra HD';
      case HdResolution.uhd8k: return '8K Cinema UHD';
    }
  }

  String get bitrateLabel {
    switch (this) {
      case HdResolution.hd720p: return '6 Mbps';
      case HdResolution.fhd1080p: return '14 Mbps';
      case HdResolution.qhd1440p: return '24 Mbps';
      case HdResolution.uhd4k: return '50 Mbps';
      case HdResolution.uhd8k: return '95 Mbps';
    }
  }

  String get shortTag {
    switch (this) {
      case HdResolution.hd720p: return '720p';
      case HdResolution.fhd1080p: return '1080p';
      case HdResolution.qhd1440p: return '2K';
      case HdResolution.uhd4k: return '4K';
      case HdResolution.uhd8k: return '8K';
    }
  }
}

enum HdScalingAlgorithm {
  lanczos3,
  bicubicSpline,
  superResolution,
  bilinearFast,
}

extension HdScalingAlgorithmExtension on HdScalingAlgorithm {
  String get label {
    switch (this) {
      case HdScalingAlgorithm.lanczos3: return 'Lanczos 3-Lobe Sinc';
      case HdScalingAlgorithm.bicubicSpline: return 'Bicubic Spline';
      case HdScalingAlgorithm.superResolution: return 'Super-Res Synthesizer';
      case HdScalingAlgorithm.bilinearFast: return 'Bilinear Fast';
    }
  }

  String get description {
    switch (this) {
      case HdScalingAlgorithm.lanczos3: return 'High-precision anti-aliased sinc interpolation';
      case HdScalingAlgorithm.bicubicSpline: return 'Smooth gradient & natural portrait skin tone preservation';
      case HdScalingAlgorithm.superResolution: return 'High-frequency edge recovery & micro-texture synthesis';
      case HdScalingAlgorithm.bilinearFast: return 'Lightweight standard linear scaling';
    }
  }

  String get ffmpegFlag {
    switch (this) {
      case HdScalingAlgorithm.lanczos3: return 'lanczos';
      case HdScalingAlgorithm.bicubicSpline: return 'bicubic';
      case HdScalingAlgorithm.superResolution: return 'lanczos+accurate_rnd';
      case HdScalingAlgorithm.bilinearFast: return 'bilinear';
    }
  }
}

enum HdConverterPreset {
  sdTo1080pFhd,
  to4kCinema,
  portraitClean,
  socialVideoRestore,
  extreme8k,
}

extension HdConverterPresetExtension on HdConverterPreset {
  String get label {
    switch (this) {
      case HdConverterPreset.sdTo1080pFhd: return '✨ SD ➡️ 1080p Full HD';
      case HdConverterPreset.to4kCinema: return '🎬 720p/1080p ➡️ 4K Cinema';
      case HdConverterPreset.portraitClean: return '👤 Portrait & Face Restore';
      case HdConverterPreset.socialVideoRestore: return '📱 Social Video De-Noise & HD';
      case HdConverterPreset.extreme8k: return '⚡ 8K Cinema Master';
    }
  }

  String get description {
    switch (this) {
      case HdConverterPreset.sdTo1080pFhd: return 'Convert fuzzy SD/480p videos to crisp 1080p Full HD';
      case HdConverterPreset.to4kCinema: return 'Upscale to pristine 4K UHD with micro-contrast edge synthesis';
      case HdConverterPreset.portraitClean: return 'Gentle compression cleaning with natural facial textures';
      case HdConverterPreset.socialVideoRestore: return 'Remove MPEG macroblocks & noise from TikTok/Reels downloads';
      case HdConverterPreset.extreme8k: return 'Ultimate 8K UHD resolution scaling for high-end displays';
    }
  }

  HdConverterConfig createConfig() {
    switch (this) {
      case HdConverterPreset.sdTo1080pFhd:
        return const HdConverterConfig(
          isEnabled: true,
          targetResolution: HdResolution.fhd1080p,
          algorithm: HdScalingAlgorithm.lanczos3,
          detailClarity: 1.25,
          denoiseStrength: 0.20,
          deblocking: true,
          sharpness: 1.20,
          hdrColorExpand: false,
        );

      case HdConverterPreset.to4kCinema:
        return const HdConverterConfig(
          isEnabled: true,
          targetResolution: HdResolution.uhd4k,
          algorithm: HdScalingAlgorithm.superResolution,
          detailClarity: 1.45,
          denoiseStrength: 0.15,
          deblocking: true,
          sharpness: 1.35,
          hdrColorExpand: true,
        );

      case HdConverterPreset.portraitClean:
        return const HdConverterConfig(
          isEnabled: true,
          targetResolution: HdResolution.fhd1080p,
          algorithm: HdScalingAlgorithm.bicubicSpline,
          detailClarity: 1.10,
          denoiseStrength: 0.35,
          deblocking: true,
          sharpness: 1.05,
          hdrColorExpand: false,
        );

      case HdConverterPreset.socialVideoRestore:
        return const HdConverterConfig(
          isEnabled: true,
          targetResolution: HdResolution.fhd1080p,
          algorithm: HdScalingAlgorithm.lanczos3,
          detailClarity: 1.30,
          denoiseStrength: 0.45,
          deblocking: true,
          sharpness: 1.25,
          hdrColorExpand: true,
        );

      case HdConverterPreset.extreme8k:
        return const HdConverterConfig(
          isEnabled: true,
          targetResolution: HdResolution.uhd8k,
          algorithm: HdScalingAlgorithm.superResolution,
          detailClarity: 1.60,
          denoiseStrength: 0.15,
          deblocking: true,
          sharpness: 1.50,
          hdrColorExpand: true,
        );
    }
  }
}

class HdConverterConfig extends Equatable {
  final bool isEnabled;
  final HdResolution targetResolution;
  final HdScalingAlgorithm algorithm;
  final double detailClarity;    // 0.5 to 2.0 (1.0 = normal)
  final double denoiseStrength;  // 0.0 to 1.0 (0.0 = off)
  final bool deblocking;         // MPEG / social macroblock removal
  final bool hdrColorExpand;     // Dynamic range peak contrast expansion
  final double sharpness;        // 0.5 to 2.0 (1.0 = normal)

  const HdConverterConfig({
    this.isEnabled = false,
    this.targetResolution = HdResolution.fhd1080p,
    this.algorithm = HdScalingAlgorithm.lanczos3,
    this.detailClarity = 1.0,
    this.denoiseStrength = 0.0,
    this.deblocking = false,
    this.hdrColorExpand = false,
    this.sharpness = 1.0,
  });

  bool get hasActiveConversion =>
      isEnabled &&
      (targetResolution != HdResolution.fhd1080p ||
          detailClarity != 1.0 ||
          denoiseStrength > 0.0 ||
          deblocking ||
          hdrColorExpand ||
          sharpness != 1.0);

  HdConverterConfig copyWith({
    bool? isEnabled,
    HdResolution? targetResolution,
    HdScalingAlgorithm? algorithm,
    double? detailClarity,
    double? denoiseStrength,
    bool? deblocking,
    bool? hdrColorExpand,
    double? sharpness,
  }) {
    return HdConverterConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      targetResolution: targetResolution ?? this.targetResolution,
      algorithm: algorithm ?? this.algorithm,
      detailClarity: detailClarity ?? this.detailClarity,
      denoiseStrength: denoiseStrength ?? this.denoiseStrength,
      deblocking: deblocking ?? this.deblocking,
      hdrColorExpand: hdrColorExpand ?? this.hdrColorExpand,
      sharpness: sharpness ?? this.sharpness,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'targetResolution': targetResolution.name,
        'algorithm': algorithm.name,
        'detailClarity': detailClarity,
        'denoiseStrength': denoiseStrength,
        'deblocking': deblocking,
        'hdrColorExpand': hdrColorExpand,
        'sharpness': sharpness,
      };

  factory HdConverterConfig.fromJson(Map<String, dynamic> json) {
    return HdConverterConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      targetResolution: HdResolution.values.firstWhere(
        (e) => e.name == json['targetResolution'],
        orElse: () => HdResolution.fhd1080p,
      ),
      algorithm: HdScalingAlgorithm.values.firstWhere(
        (e) => e.name == json['algorithm'],
        orElse: () => HdScalingAlgorithm.lanczos3,
      ),
      detailClarity: (json['detailClarity'] as num?)?.toDouble() ?? 1.0,
      denoiseStrength: (json['denoiseStrength'] as num?)?.toDouble() ?? 0.0,
      deblocking: json['deblocking'] as bool? ?? false,
      hdrColorExpand: json['hdrColorExpand'] as bool? ?? false,
      sharpness: (json['sharpness'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        targetResolution,
        algorithm,
        detailClarity,
        denoiseStrength,
        deblocking,
        hdrColorExpand,
        sharpness,
      ];
}
