import 'package:equatable/equatable.dart';

/// Preset kaleidoscopic symmetry and reflection patterns.
enum KaleidoscopePattern {
  hexagonalPrism,
  quadMirror,
  octagonalMandala,
  dodecahedralDream,
  verticalSplitMirror;

  String get displayName {
    switch (this) {
      case KaleidoscopePattern.hexagonalPrism:
        return '6-Facet Hexagonal Prism';
      case KaleidoscopePattern.quadMirror:
        return '4-Way Quad Mirror';
      case KaleidoscopePattern.octagonalMandala:
        return '8-Facet Sacred Mandala';
      case KaleidoscopePattern.dodecahedralDream:
        return '12-Facet Dodecahedron';
      case KaleidoscopePattern.verticalSplitMirror:
        return '2-Way Vertical Mirror';
    }
  }

  String get description {
    switch (this) {
      case KaleidoscopePattern.hexagonalPrism:
        return 'Classic 6-fold radial prism kaleidoscope symmetry';
      case KaleidoscopePattern.quadMirror:
        return '4-quadrant Cartesian mirror reflection across center';
      case KaleidoscopePattern.octagonalMandala:
        return '8-fold sacred geometry mandala radial reflection';
      case KaleidoscopePattern.dodecahedralDream:
        return '12-fold ultra-dense intricate radial crystal kaleidoscope';
      case KaleidoscopePattern.verticalSplitMirror:
        return 'Dual-wing symmetric split screen reflection';
    }
  }
}

/// Configuration for radial kaleidoscope and geometric mirror VFX.
class KaleidoscopeConfig extends Equatable {
  final bool isEnabled;
  final KaleidoscopePattern pattern;
  final double segments; // 2.0 to 12.0 (number of radial sectors)
  final double rotationSpeed; // -2.0 to 2.0 (continuous rotation drift speed)
  final double zoom; // 0.5 to 2.5 (facet zoom multiplier)
  final double centerX; // -0.5 to 0.5 (pivot center horizontal offset)
  final double centerY; // -0.5 to 0.5 (pivot center vertical offset)

  const KaleidoscopeConfig({
    this.isEnabled = false,
    this.pattern = KaleidoscopePattern.hexagonalPrism,
    this.segments = 6.0,
    this.rotationSpeed = 0.5,
    this.zoom = 1.0,
    this.centerX = 0.0,
    this.centerY = 0.0,
  });

  bool get isActive => isEnabled;

  // Curated presets
  static const KaleidoscopeConfig classicHexagon = KaleidoscopeConfig(
    isEnabled: true,
    pattern: KaleidoscopePattern.hexagonalPrism,
    segments: 6.0,
    rotationSpeed: 0.5,
    zoom: 1.0,
  );

  static const KaleidoscopeConfig sacredMandala = KaleidoscopeConfig(
    isEnabled: true,
    pattern: KaleidoscopePattern.octagonalMandala,
    segments: 8.0,
    rotationSpeed: 0.35,
    zoom: 1.2,
  );

  static const KaleidoscopeConfig quadRetroMirror = KaleidoscopeConfig(
    isEnabled: true,
    pattern: KaleidoscopePattern.quadMirror,
    segments: 4.0,
    rotationSpeed: 0.0,
    zoom: 1.0,
  );

  static const KaleidoscopeConfig cosmicCrystal = KaleidoscopeConfig(
    isEnabled: true,
    pattern: KaleidoscopePattern.dodecahedralDream,
    segments: 12.0,
    rotationSpeed: 0.75,
    zoom: 1.35,
  );

  static const KaleidoscopeConfig twinSymmetry = KaleidoscopeConfig(
    isEnabled: true,
    pattern: KaleidoscopePattern.verticalSplitMirror,
    segments: 2.0,
    rotationSpeed: 0.0,
    zoom: 1.0,
  );

  KaleidoscopeConfig copyWith({
    bool? isEnabled,
    KaleidoscopePattern? pattern,
    double? segments,
    double? rotationSpeed,
    double? zoom,
    double? centerX,
    double? centerY,
  }) {
    return KaleidoscopeConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      pattern: pattern ?? this.pattern,
      segments: segments ?? this.segments,
      rotationSpeed: rotationSpeed ?? this.rotationSpeed,
      zoom: zoom ?? this.zoom,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'pattern': pattern.name,
      'segments': segments,
      'rotationSpeed': rotationSpeed,
      'zoom': zoom,
      'centerX': centerX,
      'centerY': centerY,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory KaleidoscopeConfig.fromMap(Map<String, dynamic> map) {
    return KaleidoscopeConfig(
      isEnabled: map['isEnabled'] as bool? ?? false,
      pattern: KaleidoscopePattern.values.firstWhere(
        (e) => e.name == map['pattern'],
        orElse: () => KaleidoscopePattern.hexagonalPrism,
      ),
      segments: (map['segments'] as num?)?.toDouble() ?? 6.0,
      rotationSpeed: (map['rotationSpeed'] as num?)?.toDouble() ?? 0.5,
      zoom: (map['zoom'] as num?)?.toDouble() ?? 1.0,
      centerX: (map['centerX'] as num?)?.toDouble() ?? 0.0,
      centerY: (map['centerY'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory KaleidoscopeConfig.fromJson(Map<String, dynamic> json) =>
      KaleidoscopeConfig.fromMap(json);

  @override
  List<Object?> get props => [
        isEnabled,
        pattern,
        segments,
        rotationSpeed,
        zoom,
        centerX,
        centerY,
      ];
}
