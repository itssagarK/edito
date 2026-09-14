import 'dart:math' as math;
import 'package:equatable/equatable.dart';

enum MaskType {
  none,
  linear,
  radial,
  rectangle,
  filmStrip,
  star,
  heart,
}

enum MaskPreset {
  none,
  splitHorizontal,
  splitVertical,
  spotlightCircle,
  roundedCard,
  cinematicLetterbox,
  dreamyHeart,
  popStar,
}

class MaskConfig extends Equatable {
  final MaskType type;
  final double centerX; // Normalized 0.0 - 1.0 (0.5 is center)
  final double centerY; // Normalized 0.0 - 1.0 (0.5 is center)
  final double width; // Normalized relative width/radius (0.05 - 2.0)
  final double height; // Normalized relative height/radius (0.05 - 2.0)
  final double rotation; // Degrees 0.0 - 360.0
  final double feather; // Edge softness falloff 0.0 - 1.0 (0 = sharp, 1 = maximum blur)
  final double roundness; // Corner radius for rectangle 0.0 - 1.0 (0 = sharp corners, 1 = circular capsule)
  final bool inverted; // Invert mask (cutout vs spotlight)
  final double opacity; // Mask master alpha 0.0 - 1.0

  const MaskConfig({
    this.type = MaskType.none,
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.width = 0.6,
    this.height = 0.6,
    this.rotation = 0.0,
    this.feather = 0.0,
    this.roundness = 0.0,
    this.inverted = false,
    this.opacity = 1.0,
  });

  bool get isActive => type != MaskType.none;

  MaskConfig copyWith({
    MaskType? type,
    double? centerX,
    double? centerY,
    double? width,
    double? height,
    double? rotation,
    double? feather,
    double? roundness,
    bool? inverted,
    double? opacity,
  }) {
    return MaskConfig(
      type: type ?? this.type,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      feather: feather ?? this.feather,
      roundness: roundness ?? this.roundness,
      inverted: inverted ?? this.inverted,
      opacity: opacity ?? this.opacity,
    );
  }

  static MaskConfig fromPreset(MaskPreset preset) {
    switch (preset) {
      case MaskPreset.none:
        return const MaskConfig(type: MaskType.none);
      case MaskPreset.splitHorizontal:
        return const MaskConfig(
          type: MaskType.linear,
          centerX: 0.5,
          centerY: 0.5,
          rotation: 0.0,
          feather: 0.05,
        );
      case MaskPreset.splitVertical:
        return const MaskConfig(
          type: MaskType.linear,
          centerX: 0.5,
          centerY: 0.5,
          rotation: 90.0,
          feather: 0.05,
        );
      case MaskPreset.spotlightCircle:
        return const MaskConfig(
          type: MaskType.radial,
          centerX: 0.5,
          centerY: 0.5,
          width: 0.55,
          height: 0.55,
          feather: 0.30,
        );
      case MaskPreset.roundedCard:
        return const MaskConfig(
          type: MaskType.rectangle,
          centerX: 0.5,
          centerY: 0.5,
          width: 0.75,
          height: 0.75,
          roundness: 0.35,
          feather: 0.02,
        );
      case MaskPreset.cinematicLetterbox:
        return const MaskConfig(
          type: MaskType.rectangle,
          centerX: 0.5,
          centerY: 0.5,
          width: 1.0,
          height: 0.72,
          roundness: 0.0,
          feather: 0.0,
        );
      case MaskPreset.dreamyHeart:
        return const MaskConfig(
          type: MaskType.heart,
          centerX: 0.5,
          centerY: 0.5,
          width: 0.65,
          height: 0.65,
          feather: 0.15,
        );
      case MaskPreset.popStar:
        return const MaskConfig(
          type: MaskType.star,
          centerX: 0.5,
          centerY: 0.5,
          width: 0.65,
          height: 0.65,
          feather: 0.10,
        );
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'centerX': centerX,
        'centerY': centerY,
        'width': width,
        'height': height,
        'rotation': rotation,
        'feather': feather,
        'roundness': roundness,
        'inverted': inverted,
        'opacity': opacity,
      };

  factory MaskConfig.fromJson(Map<String, dynamic> json) => MaskConfig(
        type: MaskType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MaskType.none,
        ),
        centerX: (json['centerX'] as num?)?.toDouble() ?? 0.5,
        centerY: (json['centerY'] as num?)?.toDouble() ?? 0.5,
        width: (json['width'] as num?)?.toDouble() ?? 0.6,
        height: (json['height'] as num?)?.toDouble() ?? 0.6,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        feather: (json['feather'] as num?)?.toDouble() ?? 0.0,
        roundness: (json['roundness'] as num?)?.toDouble() ?? 0.0,
        inverted: json['inverted'] as bool? ?? false,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  List<Object?> get props => [
        type,
        centerX,
        centerY,
        width,
        height,
        rotation,
        feather,
        roundness,
        inverted,
        opacity,
      ];
}
