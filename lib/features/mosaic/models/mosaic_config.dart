import 'dart:math' as math;
import 'package:equatable/equatable.dart';

enum MosaicType {
  none,
  pixelMosaic,
  gaussianBlur,
  hexagonalCrystal,
  frostedGlass,
}

extension MosaicTypeExtension on MosaicType {
  String get label {
    switch (this) {
      case MosaicType.none:
        return 'None (Off)';
      case MosaicType.pixelMosaic:
        return 'Pixel Mosaic Grid';
      case MosaicType.gaussianBlur:
        return 'Gaussian Privacy Blur';
      case MosaicType.hexagonalCrystal:
        return 'Hexagonal Crystal';
      case MosaicType.frostedGlass:
        return 'Frosted Glass';
    }
  }

  String get description {
    switch (this) {
      case MosaicType.none:
        return 'No mosaic or blur applied';
      case MosaicType.pixelMosaic:
        return 'Retro 8-bit digital pixelation blocks';
      case MosaicType.gaussianBlur:
        return 'Silky-smooth heavy privacy defocus';
      case MosaicType.hexagonalCrystal:
        return 'Faceted geometric crystal honeycomb';
      case MosaicType.frostedGlass:
        return 'Soft matte diffused glass blur';
    }
  }
}

enum MosaicShape {
  rectangle,
  ellipse,
  bannerStrip,
  fullFrame,
}

extension MosaicShapeExtension on MosaicShape {
  String get label {
    switch (this) {
      case MosaicShape.rectangle:
        return 'Rectangle Box';
      case MosaicShape.ellipse:
        return 'Ellipse / Face';
      case MosaicShape.bannerStrip:
        return 'Banner Strip';
      case MosaicShape.fullFrame:
        return 'Full Frame';
    }
  }
}

enum MosaicPreset {
  none,
  faceCensor,
  licensePlate,
  confidentialDoc,
  retroPixelArt,
  frostedGlassBackdrop,
}

extension MosaicPresetExtension on MosaicPreset {
  String get label {
    switch (this) {
      case MosaicPreset.none:
        return 'Custom';
      case MosaicPreset.faceCensor:
        return 'Face Censor';
      case MosaicPreset.licensePlate:
        return 'License Plate';
      case MosaicPreset.confidentialDoc:
        return 'Confidential Doc';
      case MosaicPreset.retroPixelArt:
        return 'Retro Pixel Art';
      case MosaicPreset.frostedGlassBackdrop:
        return 'Frosted Backdrop';
    }
  }

  MosaicConfig createConfig() {
    switch (this) {
      case MosaicPreset.none:
        return const MosaicConfig();
      case MosaicPreset.faceCensor:
        return const MosaicConfig(
          isEnabled: true,
          type: MosaicType.pixelMosaic,
          shape: MosaicShape.ellipse,
          centerX: 0.5,
          centerY: 0.35,
          width: 0.30,
          height: 0.35,
          pixelSize: 18.0,
          feather: 0.25,
          opacity: 1.0,
        );
      case MosaicPreset.licensePlate:
        return const MosaicConfig(
          isEnabled: true,
          type: MosaicType.gaussianBlur,
          shape: MosaicShape.bannerStrip,
          centerX: 0.5,
          centerY: 0.75,
          width: 0.45,
          height: 0.15,
          blurRadius: 28.0,
          roundness: 0.3,
          feather: 0.15,
          opacity: 1.0,
        );
      case MosaicPreset.confidentialDoc:
        return const MosaicConfig(
          isEnabled: true,
          type: MosaicType.pixelMosaic,
          shape: MosaicShape.rectangle,
          centerX: 0.5,
          centerY: 0.5,
          width: 0.60,
          height: 0.20,
          pixelSize: 24.0,
          roundness: 0.1,
          feather: 0.05,
          opacity: 1.0,
        );
      case MosaicPreset.retroPixelArt:
        return const MosaicConfig(
          isEnabled: true,
          type: MosaicType.pixelMosaic,
          shape: MosaicShape.fullFrame,
          centerX: 0.5,
          centerY: 0.5,
          width: 1.0,
          height: 1.0,
          pixelSize: 32.0,
          feather: 0.0,
          opacity: 0.90,
        );
      case MosaicPreset.frostedGlassBackdrop:
        return const MosaicConfig(
          isEnabled: true,
          type: MosaicType.frostedGlass,
          shape: MosaicShape.fullFrame,
          centerX: 0.5,
          centerY: 0.5,
          width: 1.0,
          height: 1.0,
          blurRadius: 35.0,
          opacity: 0.85,
        );
    }
  }
}

class MosaicConfig extends Equatable {
  final bool isEnabled;
  final MosaicType type;
  final MosaicShape shape;
  final double centerX; // Normalized 0.0 - 1.0 (0.5 is center)
  final double centerY; // Normalized 0.0 - 1.0 (0.5 is center)
  final double width; // Normalized relative width (0.05 - 1.0)
  final double height; // Normalized relative height (0.05 - 1.0)
  final double pixelSize; // Pixel mosaic block size (4.0 to 64.0 px)
  final double blurRadius; // Gaussian / frosted blur radius (2.0 to 60.0 px)
  final double rotation; // Degrees 0.0 - 360.0
  final double feather; // Edge softness falloff 0.0 - 1.0
  final double roundness; // Corner radius for rectangle 0.0 - 1.0
  final double opacity; // Master alpha 0.0 - 1.0
  final bool inverted; // If true, blur everywhere OUTSIDE the defined region

  const MosaicConfig({
    this.isEnabled = false,
    this.type = MosaicType.none,
    this.shape = MosaicShape.rectangle,
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.width = 0.35,
    this.height = 0.25,
    this.pixelSize = 16.0,
    this.blurRadius = 24.0,
    this.rotation = 0.0,
    this.feather = 0.1,
    this.roundness = 0.2,
    this.opacity = 1.0,
    this.inverted = false,
  });

  bool get isActive => isEnabled && type != MosaicType.none && opacity > 0.001;

  MosaicConfig copyWith({
    bool? isEnabled,
    MosaicType? type,
    MosaicShape? shape,
    double? centerX,
    double? centerY,
    double? width,
    double? height,
    double? pixelSize,
    double? blurRadius,
    double? rotation,
    double? feather,
    double? roundness,
    double? opacity,
    bool? inverted,
  }) {
    return MosaicConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      type: type ?? this.type,
      shape: shape ?? this.shape,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      width: width ?? this.width,
      height: height ?? this.height,
      pixelSize: pixelSize ?? this.pixelSize,
      blurRadius: blurRadius ?? this.blurRadius,
      rotation: rotation ?? this.rotation,
      feather: feather ?? this.feather,
      roundness: roundness ?? this.roundness,
      opacity: opacity ?? this.opacity,
      inverted: inverted ?? this.inverted,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'type': type.name,
        'shape': shape.name,
        'centerX': centerX,
        'centerY': centerY,
        'width': width,
        'height': height,
        'pixelSize': pixelSize,
        'blurRadius': blurRadius,
        'rotation': rotation,
        'feather': feather,
        'roundness': roundness,
        'opacity': opacity,
        'inverted': inverted,
      };

  factory MosaicConfig.fromJson(Map<String, dynamic> json) {
    return MosaicConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      type: MosaicType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MosaicType.none,
      ),
      shape: MosaicShape.values.firstWhere(
        (e) => e.name == json['shape'],
        orElse: () => MosaicShape.rectangle,
      ),
      centerX: (json['centerX'] as num?)?.toDouble() ?? 0.5,
      centerY: (json['centerY'] as num?)?.toDouble() ?? 0.5,
      width: (json['width'] as num?)?.toDouble() ?? 0.35,
      height: (json['height'] as num?)?.toDouble() ?? 0.25,
      pixelSize: (json['pixelSize'] as num?)?.toDouble() ?? 16.0,
      blurRadius: (json['blurRadius'] as num?)?.toDouble() ?? 24.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      feather: (json['feather'] as num?)?.toDouble() ?? 0.1,
      roundness: (json['roundness'] as num?)?.toDouble() ?? 0.2,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      inverted: json['inverted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        type,
        shape,
        centerX,
        centerY,
        width,
        height,
        pixelSize,
        blurRadius,
        rotation,
        feather,
        roundness,
        opacity,
        inverted,
      ];
}
