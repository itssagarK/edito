import 'package:equatable/equatable.dart';

enum VfxType {
  none,
  filmGrain,
  rgbGlitch,
  lensBlur,
  vhsVintage,
  vignette,
  lightLeak,
  cameraShake,
  radialZoom,
}

extension VfxTypeExtension on VfxType {
  String get label {
    switch (this) {
      case VfxType.none:
        return 'None / Flat';
      case VfxType.filmGrain:
        return '35mm Film Grain';
      case VfxType.rgbGlitch:
        return 'RGB Split & Glitch';
      case VfxType.lensBlur:
        return 'Cinematic Lens Blur';
      case VfxType.vhsVintage:
        return 'Retro VHS Tape';
      case VfxType.vignette:
        return 'Cinematic Vignette';
      case VfxType.lightLeak:
        return 'Golden Light Leak';
      case VfxType.cameraShake:
        return 'Camera Shake';
      case VfxType.radialZoom:
        return 'Radial Zoom Rush';
    }
  }

  String get iconEmoji {
    switch (this) {
      case VfxType.none:
        return '🚫';
      case VfxType.filmGrain:
        return '🎞️';
      case VfxType.rgbGlitch:
        return '⚡';
      case VfxType.lensBlur:
        return '🌫️';
      case VfxType.vhsVintage:
        return '📼';
      case VfxType.vignette:
        return '🎬';
      case VfxType.lightLeak:
        return '☀️';
      case VfxType.cameraShake:
        return '📳';
      case VfxType.radialZoom:
        return '🚀';
    }
  }

  String get description {
    switch (this) {
      case VfxType.none:
        return 'No motion or visual effect applied';
      case VfxType.filmGrain:
        return 'Authentic 35mm analog emulsion grain texture';
      case VfxType.rgbGlitch:
        return 'Digital chromatic aberration and RGB channel displacement';
      case VfxType.lensBlur:
        return 'Soft optical depth-of-field Gaussian lens defocus';
      case VfxType.vhsVintage:
        return '80s analog camcorder CRT scanlines & tape warmth';
      case VfxType.vignette:
        return 'Darkened optical perimeter falloff focusing on subject';
      case VfxType.lightLeak:
        return 'Warm anamorphic golden hour sun flare pulses';
      case VfxType.cameraShake:
        return 'High-energy organic handheld camera tremor';
      case VfxType.radialZoom:
        return 'High-velocity action zoom blur radiating from center';
    }
  }
}

class VfxConfig extends Equatable {
  final VfxType type;
  final double intensity;        // 0.0 to 1.0 (default 0.50)
  final double speed;            // 0.1 to 3.0 (default 1.0)
  final double grainSize;        // 1.0 to 5.0 (default 2.0)
  final double rgbOffset;        // 1.0 to 30.0 pixels (default 8.0)
  final double blurRadius;       // 1.0 to 25.0 (default 8.0)
  final double vignetteRadius;   // 0.2 to 0.9 (default 0.55)
  final double vignetteSoftness; // 0.1 to 0.8 (default 0.45)
  final double shakeAmplitude;   // 2.0 to 30.0 pixels (default 10.0)
  final double colorWarmth;      // -1.0 to +1.0 (default 0.0)

  const VfxConfig({
    this.type = VfxType.none,
    this.intensity = 0.50,
    this.speed = 1.0,
    this.grainSize = 2.0,
    this.rgbOffset = 8.0,
    this.blurRadius = 8.0,
    this.vignetteRadius = 0.55,
    this.vignetteSoftness = 0.45,
    this.shakeAmplitude = 10.0,
    this.colorWarmth = 0.0,
  });

  bool get isActive => type != VfxType.none && intensity > 0.0;

  VfxConfig copyWith({
    VfxType? type,
    double? intensity,
    double? speed,
    double? grainSize,
    double? rgbOffset,
    double? blurRadius,
    double? vignetteRadius,
    double? vignetteSoftness,
    double? shakeAmplitude,
    double? colorWarmth,
  }) {
    return VfxConfig(
      type: type ?? this.type,
      intensity: intensity ?? this.intensity,
      speed: speed ?? this.speed,
      grainSize: grainSize ?? this.grainSize,
      rgbOffset: rgbOffset ?? this.rgbOffset,
      blurRadius: blurRadius ?? this.blurRadius,
      vignetteRadius: vignetteRadius ?? this.vignetteRadius,
      vignetteSoftness: vignetteSoftness ?? this.vignetteSoftness,
      shakeAmplitude: shakeAmplitude ?? this.shakeAmplitude,
      colorWarmth: colorWarmth ?? this.colorWarmth,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'intensity': intensity,
        'speed': speed,
        'grainSize': grainSize,
        'rgbOffset': rgbOffset,
        'blurRadius': blurRadius,
        'vignetteRadius': vignetteRadius,
        'vignetteSoftness': vignetteSoftness,
        'shakeAmplitude': shakeAmplitude,
        'colorWarmth': colorWarmth,
      };

  factory VfxConfig.fromJson(Map<String, dynamic> json) => VfxConfig(
        type: VfxType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => VfxType.none,
        ),
        intensity: (json['intensity'] as num?)?.toDouble() ?? 0.50,
        speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
        grainSize: (json['grainSize'] as num?)?.toDouble() ?? 2.0,
        rgbOffset: (json['rgbOffset'] as num?)?.toDouble() ?? 8.0,
        blurRadius: (json['blurRadius'] as num?)?.toDouble() ?? 8.0,
        vignetteRadius: (json['vignetteRadius'] as num?)?.toDouble() ?? 0.55,
        vignetteSoftness: (json['vignetteSoftness'] as num?)?.toDouble() ?? 0.45,
        shakeAmplitude: (json['shakeAmplitude'] as num?)?.toDouble() ?? 10.0,
        colorWarmth: (json['colorWarmth'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  List<Object?> get props => [
        type,
        intensity,
        speed,
        grainSize,
        rgbOffset,
        blurRadius,
        vignetteRadius,
        vignetteSoftness,
        shakeAmplitude,
        colorWarmth,
      ];
}
