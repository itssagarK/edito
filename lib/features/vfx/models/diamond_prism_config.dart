import 'package:equatable/equatable.dart';

/// Modes of diamond glass prism facet geometries and light dispersion.
enum DiamondPrismMode {
  brilliantCut,
  emeraldFacet,
  triangularPrism,
  kaleidoCrystal,
  spectralHeart,
}

extension DiamondPrismModeExtension on DiamondPrismMode {
  String get label {
    switch (this) {
      case DiamondPrismMode.brilliantCut:
        return 'Brilliant Cut';
      case DiamondPrismMode.emeraldFacet:
        return 'Emerald Facet';
      case DiamondPrismMode.triangularPrism:
        return 'Newton Prism';
      case DiamondPrismMode.kaleidoCrystal:
        return 'Cosmic Crystal';
      case DiamondPrismMode.spectralHeart:
        return 'Spectral Heart';
    }
  }

  String get description {
    switch (this) {
      case DiamondPrismMode.brilliantCut:
        return '8-fold radial octagonal diamond facet dispersion with brilliant glint starbursts';
      case DiamondPrismMode.emeraldFacet:
        return 'Rectangular step-cut crystal facets with parallel chromatic reflection planes';
      case DiamondPrismMode.triangularPrism:
        return 'Classic Newton triangular optical prism splitting white light into rainbow arc';
      case DiamondPrismMode.kaleidoCrystal:
        return '10-fold multifaceted crystal cluster with internal geometric light shards';
      case DiamondPrismMode.spectralHeart:
        return 'Curved facet geometry radiating warm romantic rainbow dispersion flares';
    }
  }

  String get iconAsset {
    switch (this) {
      case DiamondPrismMode.brilliantCut:
        return 'diamond';
      case DiamondPrismMode.emeraldFacet:
        return 'crop_square';
      case DiamondPrismMode.triangularPrism:
        return 'change_history';
      case DiamondPrismMode.kaleidoCrystal:
        return 'auto_awesome';
      case DiamondPrismMode.spectralHeart:
        return 'favorite';
    }
  }
}

/// Configuration for optical diamond glass prism and geometric refraction effects.
class DiamondPrismConfig extends Equatable {
  final bool isEnabled;
  final DiamondPrismMode mode;
  final int facetCount; // 3 to 12 (number of geometric facet divisions)
  final double dispersionStrength; // 0.0 to 1.0 (spectral rainbow chromatic separation)
  final double refractionAngle; // 0.0 to 360.0 (degrees of light beam incidence)
  final double innerReflectionIntensity; // 0.0 to 1.0 (specular glints & internal bounces)
  final double spectralSaturation; // 0.5 to 2.0 (vividness of chromatic spectrum)
  final double centerX; // 0.0 to 1.0 (normalized focal prism center X)
  final double centerY; // 0.0 to 1.0 (normalized focal prism center Y)
  final bool isRotating; // Dynamic rotational drift of prism facets

  const DiamondPrismConfig({
    this.isEnabled = false,
    this.mode = DiamondPrismMode.brilliantCut,
    this.facetCount = 8,
    this.dispersionStrength = 0.65,
    this.refractionAngle = 45.0,
    this.innerReflectionIntensity = 0.5,
    this.spectralSaturation = 1.3,
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.isRotating = false,
  });

  bool get isActive => isEnabled && dispersionStrength > 0.0;

  /// Default disabled configuration.
  static const DiamondPrismConfig defaultDisabled = DiamondPrismConfig();

  // Curated 5 optical presets
  static const DiamondPrismConfig presetBrilliantDiamond = DiamondPrismConfig(
    isEnabled: true,
    mode: DiamondPrismMode.brilliantCut,
    facetCount: 8,
    dispersionStrength: 0.75,
    refractionAngle: 30.0,
    innerReflectionIntensity: 0.70,
    spectralSaturation: 1.4,
    centerX: 0.5,
    centerY: 0.5,
    isRotating: true,
  );

  static const DiamondPrismConfig presetNewtonPrism = DiamondPrismConfig(
    isEnabled: true,
    mode: DiamondPrismMode.triangularPrism,
    facetCount: 3,
    dispersionStrength: 0.85,
    refractionAngle: 60.0,
    innerReflectionIntensity: 0.60,
    spectralSaturation: 1.6,
    centerX: 0.4,
    centerY: 0.4,
    isRotating: false,
  );

  static const DiamondPrismConfig presetEmeraldChamber = DiamondPrismConfig(
    isEnabled: true,
    mode: DiamondPrismMode.emeraldFacet,
    facetCount: 4,
    dispersionStrength: 0.50,
    refractionAngle: 0.0,
    innerReflectionIntensity: 0.45,
    spectralSaturation: 1.1,
    centerX: 0.5,
    centerY: 0.5,
    isRotating: false,
  );

  static const DiamondPrismConfig presetCosmicCrystal = DiamondPrismConfig(
    isEnabled: true,
    mode: DiamondPrismMode.kaleidoCrystal,
    facetCount: 10,
    dispersionStrength: 0.90,
    refractionAngle: 135.0,
    innerReflectionIntensity: 0.80,
    spectralSaturation: 1.8,
    centerX: 0.5,
    centerY: 0.5,
    isRotating: true,
  );

  static const DiamondPrismConfig presetSubtleGlassEdge = DiamondPrismConfig(
    isEnabled: true,
    mode: DiamondPrismMode.emeraldFacet,
    facetCount: 4,
    dispersionStrength: 0.30,
    refractionAngle: 15.0,
    innerReflectionIntensity: 0.25,
    spectralSaturation: 0.9,
    centerX: 0.5,
    centerY: 0.5,
    isRotating: false,
  );

  DiamondPrismConfig copyWith({
    bool? isEnabled,
    DiamondPrismMode? mode,
    int? facetCount,
    double? dispersionStrength,
    double? refractionAngle,
    double? innerReflectionIntensity,
    double? spectralSaturation,
    double? centerX,
    double? centerY,
    bool? isRotating,
  }) {
    return DiamondPrismConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      facetCount: facetCount ?? this.facetCount,
      dispersionStrength: dispersionStrength ?? this.dispersionStrength,
      refractionAngle: refractionAngle ?? this.refractionAngle,
      innerReflectionIntensity: innerReflectionIntensity ?? this.innerReflectionIntensity,
      spectralSaturation: spectralSaturation ?? this.spectralSaturation,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      isRotating: isRotating ?? this.isRotating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'facetCount': facetCount,
      'dispersionStrength': dispersionStrength,
      'refractionAngle': refractionAngle,
      'innerReflectionIntensity': innerReflectionIntensity,
      'spectralSaturation': spectralSaturation,
      'centerX': centerX,
      'centerY': centerY,
      'isRotating': isRotating,
    };
  }

  factory DiamondPrismConfig.fromJson(Map<String, dynamic> json) {
    return DiamondPrismConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: DiamondPrismMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => DiamondPrismMode.brilliantCut,
      ),
      facetCount: (json['facetCount'] as num?)?.toInt() ?? 8,
      dispersionStrength: (json['dispersionStrength'] as num?)?.toDouble() ?? 0.65,
      refractionAngle: (json['refractionAngle'] as num?)?.toDouble() ?? 45.0,
      innerReflectionIntensity: (json['innerReflectionIntensity'] as num?)?.toDouble() ?? 0.5,
      spectralSaturation: (json['spectralSaturation'] as num?)?.toDouble() ?? 1.3,
      centerX: (json['centerX'] as num?)?.toDouble() ?? 0.5,
      centerY: (json['centerY'] as num?)?.toDouble() ?? 0.5,
      isRotating: json['isRotating'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        facetCount,
        dispersionStrength,
        refractionAngle,
        innerReflectionIntensity,
        spectralSaturation,
        centerX,
        centerY,
        isRotating,
      ];
}
