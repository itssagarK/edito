import 'package:equatable/equatable.dart';

/// CapCut Pro 3D Camera Movement & Parallax Motion Styles
enum Parallax3DStyle {
  none,
  classicZoomIn,
  dollyZoomOut,
  orbitalLeft,
  orbitalRight,
  vertigoDolly,
  elasticBounce,
  craneGlider,
}

extension Parallax3DStyleExtension on Parallax3DStyle {
  String get label {
    switch (this) {
      case Parallax3DStyle.none:
        return 'None';
      case Parallax3DStyle.classicZoomIn:
        return 'Classic 3D Push';
      case Parallax3DStyle.dollyZoomOut:
        return '3D Dolly Reveal';
      case Parallax3DStyle.orbitalLeft:
        return 'Orbital Arc Left';
      case Parallax3DStyle.orbitalRight:
        return 'Orbital Arc Right';
      case Parallax3DStyle.vertigoDolly:
        return 'Vertigo (Hitchcock)';
      case Parallax3DStyle.elasticBounce:
        return 'Rhythm Elastic Snap';
      case Parallax3DStyle.craneGlider:
        return 'Cinematic Crane Glide';
    }
  }

  String get description {
    switch (this) {
      case Parallax3DStyle.none:
        return 'No 3D camera parallax motion';
      case Parallax3DStyle.classicZoomIn:
        return '3D camera push-in dolly with subject depth pop & background expansion';
      case Parallax3DStyle.dollyZoomOut:
        return 'Smooth reverse pull dolly revealing wider cinematic environment';
      case Parallax3DStyle.orbitalLeft:
        return 'Orbital arc sweep leftward with multi-plane counter-displacement';
      case Parallax3DStyle.orbitalRight:
        return 'Orbital arc sweep rightward with multi-plane counter-displacement';
      case Parallax3DStyle.vertigoDolly:
        return 'Foreground stays locked while background dramatically warps perspective';
      case Parallax3DStyle.elasticBounce:
        return 'Dynamic punch-in snap with organic spring oscillation for beat drops';
      case Parallax3DStyle.craneGlider:
        return 'Top-down sweeping crane swoop swooping diagonally into subject';
    }
  }

  String get iconAsset {
    switch (this) {
      case Parallax3DStyle.none:
        return 'block';
      case Parallax3DStyle.classicZoomIn:
        return 'zoom_in';
      case Parallax3DStyle.dollyZoomOut:
        return 'zoom_out';
      case Parallax3DStyle.orbitalLeft:
        return 'rotate_left';
      case Parallax3DStyle.orbitalRight:
        return 'rotate_right';
      case Parallax3DStyle.vertigoDolly:
        return 'camera';
      case Parallax3DStyle.elasticBounce:
        return 'speed';
      case Parallax3DStyle.craneGlider:
        return 'flight';
    }
  }
}

/// Optical Depth Focal Plane
enum FocalPlane {
  foreground,
  midground,
  background,
}

extension FocalPlaneExtension on FocalPlane {
  String get label {
    switch (this) {
      case FocalPlane.foreground:
        return 'Foreground Subject';
      case FocalPlane.midground:
        return 'Midground Balance';
      case FocalPlane.background:
        return 'Background Horizon';
    }
  }
}

/// Dynamic Motion Acceleration & Easing Curve
enum MotionDynamicsCurve {
  smoothCubic,
  elasticSnap,
  linear,
  cinematicSlow,
}

extension MotionDynamicsCurveExtension on MotionDynamicsCurve {
  String get label {
    switch (this) {
      case MotionDynamicsCurve.smoothCubic:
        return 'Smooth Ease (Cubic)';
      case MotionDynamicsCurve.elasticSnap:
        return 'Elastic Snap (Spring)';
      case MotionDynamicsCurve.linear:
        return 'Constant (Linear)';
      case MotionDynamicsCurve.cinematicSlow:
        return 'Cinematic Tension (Slow)';
    }
  }
}

/// CapCut Pro 3D Zoom & Parallax Motion Configuration
class Parallax3DConfig extends Equatable {
  final bool isEnabled;
  final Parallax3DStyle style;
  final double intensity; // 0.0 to 1.0 (travel distance & displacement)
  final double depthScale; // 1.0 to 2.5 (maximum zoom amplitude)
  final double perspectiveTilt; // 0.0 to 1.0 (3D pitch & yaw rotation)
  final double depthBlur; // 0.0 to 1.0 (optical lens defocus blur)
  final FocalPlane focalPlane;
  final MotionDynamicsCurve dynamicsCurve;

  const Parallax3DConfig({
    this.isEnabled = false,
    this.style = Parallax3DStyle.none,
    this.intensity = 0.65,
    this.depthScale = 1.35,
    this.perspectiveTilt = 0.40,
    this.depthBlur = 0.25,
    this.focalPlane = FocalPlane.foreground,
    this.dynamicsCurve = MotionDynamicsCurve.smoothCubic,
  });

  /// Viewport Floating HUD Badge
  String get badge {
    if (!isEnabled || style == Parallax3DStyle.none) return '';
    return '🏔️ 3D ZOOM (${style.label.toUpperCase()})';
  }

  Parallax3DConfig copyWith({
    bool? isEnabled,
    Parallax3DStyle? style,
    double? intensity,
    double? depthScale,
    double? perspectiveTilt,
    double? depthBlur,
    FocalPlane? focalPlane,
    MotionDynamicsCurve? dynamicsCurve,
  }) {
    return Parallax3DConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      style: style ?? this.style,
      intensity: intensity ?? this.intensity,
      depthScale: depthScale ?? this.depthScale,
      perspectiveTilt: perspectiveTilt ?? this.perspectiveTilt,
      depthBlur: depthBlur ?? this.depthBlur,
      focalPlane: focalPlane ?? this.focalPlane,
      dynamicsCurve: dynamicsCurve ?? this.dynamicsCurve,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'style': style.name,
        'intensity': intensity,
        'depthScale': depthScale,
        'perspectiveTilt': perspectiveTilt,
        'depthBlur': depthBlur,
        'focalPlane': focalPlane.name,
        'dynamicsCurve': dynamicsCurve.name,
      };

  factory Parallax3DConfig.fromJson(Map<String, dynamic> json) {
    return Parallax3DConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      style: json['style'] != null
          ? Parallax3DStyle.values.firstWhere(
              (e) => e.name == json['style'],
              orElse: () => Parallax3DStyle.none,
            )
          : Parallax3DStyle.none,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.65,
      depthScale: (json['depthScale'] as num?)?.toDouble() ?? 1.35,
      perspectiveTilt: (json['perspectiveTilt'] as num?)?.toDouble() ?? 0.40,
      depthBlur: (json['depthBlur'] as num?)?.toDouble() ?? 0.25,
      focalPlane: json['focalPlane'] != null
          ? FocalPlane.values.firstWhere(
              (e) => e.name == json['focalPlane'],
              orElse: () => FocalPlane.foreground,
            )
          : FocalPlane.foreground,
      dynamicsCurve: json['dynamicsCurve'] != null
          ? MotionDynamicsCurve.values.firstWhere(
              (e) => e.name == json['dynamicsCurve'],
              orElse: () => MotionDynamicsCurve.smoothCubic,
            )
          : MotionDynamicsCurve.smoothCubic,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        style,
        intensity,
        depthScale,
        perspectiveTilt,
        depthBlur,
        focalPlane,
        dynamicsCurve,
      ];
}
