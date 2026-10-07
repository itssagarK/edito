import 'package:equatable/equatable.dart';

enum LensDistortionProfile {
  fisheyeActionCam,
  anamorphicBarrel,
  pincushionZoom,
  droneWideAngle,
  retroSpyglass;

  String get displayName {
    switch (this) {
      case LensDistortionProfile.fisheyeActionCam:
        return 'Action Cam Fisheye';
      case LensDistortionProfile.anamorphicBarrel:
        return 'Anamorphic Barrel';
      case LensDistortionProfile.pincushionZoom:
        return 'Telephoto Pincushion';
      case LensDistortionProfile.droneWideAngle:
        return 'Drone Ultra-Wide';
      case LensDistortionProfile.retroSpyglass:
        return 'Vintage Spyglass';
    }
  }

  String get description {
    switch (this) {
      case LensDistortionProfile.fisheyeActionCam:
        return '170° panoramic spherical curved curvature with high peripheral warp';
      case LensDistortionProfile.anamorphicBarrel:
        return 'Horizontal cinema anamorphic glass curvature with subtle edge bend';
      case LensDistortionProfile.pincushionZoom:
        return 'Inward pinching distortion typical of long focal-length telephoto lenses';
      case LensDistortionProfile.droneWideAngle:
        return 'Aero panoramic field of view with expanded perspective corners';
      case LensDistortionProfile.retroSpyglass:
        return 'Antique circular lens optical field with deep corner vignette';
    }
  }
}

class LensDistortionConfig extends Equatable {
  final bool isEnabled;
  final double distortion; // -1.0 to 1.0 (positive = barrel/fisheye, negative = pincushion)
  final double chromaticAberration; // 0.0 to 1.0 (RGB color fringing)
  final double vignetteFalloff; // 0.0 to 1.0 (corner darkening)
  final LensDistortionProfile profile;

  const LensDistortionConfig({
    this.isEnabled = false,
    this.distortion = 0.35,
    this.chromaticAberration = 0.20,
    this.vignetteFalloff = 0.30,
    this.profile = LensDistortionProfile.fisheyeActionCam,
  });

  bool get isActive => isEnabled;

  // Presets
  static const LensDistortionConfig actionGoPro = LensDistortionConfig(
    isEnabled: true,
    distortion: 0.55,
    chromaticAberration: 0.25,
    vignetteFalloff: 0.20,
    profile: LensDistortionProfile.fisheyeActionCam,
  );

  static const LensDistortionConfig skateVideoFisheye = LensDistortionConfig(
    isEnabled: true,
    distortion: 0.85,
    chromaticAberration: 0.50,
    vignetteFalloff: 0.65,
    profile: LensDistortionProfile.fisheyeActionCam,
  );

  static const LensDistortionConfig cinemaAnamorphic = LensDistortionConfig(
    isEnabled: true,
    distortion: 0.25,
    chromaticAberration: 0.15,
    vignetteFalloff: 0.35,
    profile: LensDistortionProfile.anamorphicBarrel,
  );

  static const LensDistortionConfig telephotoPincushion = LensDistortionConfig(
    isEnabled: true,
    distortion: -0.40,
    chromaticAberration: 0.10,
    vignetteFalloff: 0.15,
    profile: LensDistortionProfile.pincushionZoom,
  );

  static const LensDistortionConfig securityCCTV = LensDistortionConfig(
    isEnabled: true,
    distortion: 0.70,
    chromaticAberration: 0.35,
    vignetteFalloff: 0.55,
    profile: LensDistortionProfile.retroSpyglass,
  );

  LensDistortionConfig copyWith({
    bool? isEnabled,
    double? distortion,
    double? chromaticAberration,
    double? vignetteFalloff,
    LensDistortionProfile? profile,
  }) {
    return LensDistortionConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      distortion: distortion ?? this.distortion,
      chromaticAberration: chromaticAberration ?? this.chromaticAberration,
      vignetteFalloff: vignetteFalloff ?? this.vignetteFalloff,
      profile: profile ?? this.profile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'distortion': distortion,
      'chromaticAberration': chromaticAberration,
      'vignetteFalloff': vignetteFalloff,
      'profile': profile.name,
    };
  }

  factory LensDistortionConfig.fromJson(Map<String, dynamic> json) {
    LensDistortionProfile parsed = LensDistortionProfile.fisheyeActionCam;
    if (json['profile'] != null) {
      for (final val in LensDistortionProfile.values) {
        if (val.name == json['profile']) {
          parsed = val;
          break;
        }
      }
    }

    return LensDistortionConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      distortion: (json['distortion'] as num?)?.toDouble() ?? 0.35,
      chromaticAberration: (json['chromaticAberration'] as num?)?.toDouble() ?? 0.20,
      vignetteFalloff: (json['vignetteFalloff'] as num?)?.toDouble() ?? 0.30,
      profile: parsed,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        distortion,
        chromaticAberration,
        vignetteFalloff,
        profile,
      ];
}
