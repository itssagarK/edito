import 'package:equatable/equatable.dart';

enum LutPreset {
  none,
  tealAndOrange,
  vintageKodak,
  moodyCyber,
  goldenHour,
  noirBw,
  arriAlexa,
  fujiVelvia,
  bleachBypass,
  matrixEmerald,
  fujiEterna,
  cleanCommercial,
  vintage70s,
}

extension LutPresetExtension on LutPreset {
  String get label {
    switch (this) {
      case LutPreset.none:
        return 'Original (No LUT)';
      case LutPreset.tealAndOrange:
        return 'Teal & Orange (Blockbuster)';
      case LutPreset.vintageKodak:
        return 'Vintage Kodak 500T';
      case LutPreset.moodyCyber:
        return 'Moody Cyberpunk';
      case LutPreset.goldenHour:
        return 'Warm Golden Hour';
      case LutPreset.noirBw:
        return 'Cinematic Film Noir B&W';
      case LutPreset.arriAlexa:
        return 'Arri Alexa Log-C Look';
      case LutPreset.fujiVelvia:
        return 'Fuji Velvia 50 Vibrant';
      case LutPreset.bleachBypass:
        return 'Bleach Bypass Silver';
      case LutPreset.matrixEmerald:
        return 'Matrix Emerald Sci-Fi';
      case LutPreset.fujiEterna:
        return 'Fuji Eterna Soft Cine';
      case LutPreset.cleanCommercial:
        return 'Commercial Clean Pop';
      case LutPreset.vintage70s:
        return 'Vintage 1970s Analog';
    }
  }

  String get description {
    switch (this) {
      case LutPreset.none:
        return 'Neutral raw grade';
      case LutPreset.tealAndOrange:
        return 'Deep cyan shadows & warm skin tones';
      case LutPreset.vintageKodak:
        return 'Warm highlights & retro analog greens';
      case LutPreset.moodyCyber:
        return 'Cool neon blues & magenta accents';
      case LutPreset.goldenHour:
        return 'Sunset amber warmth & soft contrast';
      case LutPreset.noirBw:
        return 'High-contrast black & white silver tone';
      case LutPreset.arriAlexa:
        return 'High dynamic range cinema curve & filmic roll-off';
      case LutPreset.fujiVelvia:
        return 'Punchy landscapes with deep saturated emeralds & sky blues';
      case LutPreset.bleachBypass:
        return 'Desaturated gritty silver retention with crushed shadows';
      case LutPreset.matrixEmerald:
        return 'Stylized sci-fi green cast with high contrast blacks';
      case LutPreset.fujiEterna:
        return 'Soft muted highlights with velvety shadow transition';
      case LutPreset.cleanCommercial:
        return 'Punchy contrast, crisp whites, and vibrant commercial color';
      case LutPreset.vintage70s:
        return 'Warm sepia-tinted highlights and faded film blacks';
    }
  }
}

class ColorWheelValue extends Equatable {
  final double angle;      // 0.0 to 360.0 degrees
  final double saturation; // 0.0 to 1.0
  final double luminance;  // -1.0 to +1.0 (0.0 = neutral)

  const ColorWheelValue({
    this.angle = 0.0,
    this.saturation = 0.0,
    this.luminance = 0.0,
  });

  bool get isActive => saturation > 0.001 || luminance.abs() > 0.001;

  ColorWheelValue copyWith({
    double? angle,
    double? saturation,
    double? luminance,
  }) {
    return ColorWheelValue(
      angle: angle ?? this.angle,
      saturation: saturation ?? this.saturation,
      luminance: luminance ?? this.luminance,
    );
  }

  Map<String, dynamic> toJson() => {
        'angle': angle,
        'saturation': saturation,
        'luminance': luminance,
      };

  factory ColorWheelValue.fromJson(Map<String, dynamic> json) => ColorWheelValue(
        angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
        saturation: (json['saturation'] as num?)?.toDouble() ?? 0.0,
        luminance: (json['luminance'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  List<Object?> get props => [angle, saturation, luminance];
}

class HslShift extends Equatable {
  final double hue;        // -180.0 to +180.0 deg
  final double saturation; // -1.0 to +1.0
  final double luminance;  // -1.0 to +1.0

  const HslShift({
    this.hue = 0.0,
    this.saturation = 0.0,
    this.luminance = 0.0,
  });

  HslShift copyWith({
    double? hue,
    double? saturation,
    double? luminance,
  }) {
    return HslShift(
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      luminance: luminance ?? this.luminance,
    );
  }

  Map<String, dynamic> toJson() => {
        'hue': hue,
        'saturation': saturation,
        'luminance': luminance,
      };

  factory HslShift.fromJson(Map<String, dynamic> json) => HslShift(
        hue: (json['hue'] as num?)?.toDouble() ?? 0.0,
        saturation: (json['saturation'] as num?)?.toDouble() ?? 0.0,
        luminance: (json['luminance'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  List<Object?> get props => [hue, saturation, luminance];
}

class CurvePoint extends Equatable {
  final double x; // 0.0 to 1.0
  final double y; // 0.0 to 1.0

  const CurvePoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory CurvePoint.fromJson(Map<String, dynamic> json) => CurvePoint(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [x, y];
}

class ColorGradingConfig extends Equatable {
  final double exposure;          // -2.0 to +2.0 (EV)
  final double contrast;          // 0.5 to 1.5 (1.0 = normal)
  final double saturation;        // 0.0 to 2.0 (1.0 = normal)
  final double brightness;        // -1.0 to +1.0 (0.0 = normal)
  final double temperature;       // -100.0 (Cool) to +100.0 (Warm)
  final double tint;              // -100.0 (Green) to +100.0 (Magenta)
  final double highlights;        // -1.0 to +1.0
  final double shadows;           // -1.0 to +1.0
  final double whites;            // -1.0 to +1.0
  final double blacks;            // -1.0 to +1.0
  final double fade;              // 0.0 to 1.0 (filmic lifted blacks)
  final double clarity;           // 0.0 to 2.0 (midtone micro-contrast)
  final double sharpness;         // 0.0 to 2.0
  final double vignette;          // 0.0 to 1.0
  final LutPreset activeLut;
  final double lutIntensity;      // 0.0 to 1.0
  final ColorWheelValue lift;     // Shadows color wheel
  final ColorWheelValue gamma;    // Midtones color wheel
  final ColorWheelValue gain;     // Highlights color wheel
  final ColorWheelValue offset;   // Master offset color wheel
  final Map<String, HslShift> hsl; // Keys: red, orange, yellow, green, cyan, blue, purple, magenta
  final List<CurvePoint> masterCurve;

  const ColorGradingConfig({
    this.exposure = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.brightness = 0.0,
    this.temperature = 0.0,
    this.tint = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.whites = 0.0,
    this.blacks = 0.0,
    this.fade = 0.0,
    this.clarity = 1.0,
    this.sharpness = 1.0,
    this.vignette = 0.0,
    this.activeLut = LutPreset.none,
    this.lutIntensity = 1.0,
    this.lift = const ColorWheelValue(),
    this.gamma = const ColorWheelValue(),
    this.gain = const ColorWheelValue(),
    this.offset = const ColorWheelValue(),
    this.hsl = const {},
    this.masterCurve = const [CurvePoint(0.0, 0.0), CurvePoint(1.0, 1.0)],
  });

  bool get isGraded =>
      exposure != 0.0 ||
      contrast != 1.0 ||
      saturation != 1.0 ||
      brightness != 0.0 ||
      temperature != 0.0 ||
      tint != 0.0 ||
      highlights != 0.0 ||
      shadows != 0.0 ||
      whites != 0.0 ||
      blacks != 0.0 ||
      fade != 0.0 ||
      clarity != 1.0 ||
      sharpness != 1.0 ||
      vignette != 0.0 ||
      activeLut != LutPreset.none ||
      lift.isActive ||
      gamma.isActive ||
      gain.isActive ||
      offset.isActive ||
      hsl.values.any((h) => h.hue != 0.0 || h.saturation != 0.0 || h.luminance != 0.0) ||
      isCurveCustomized(masterCurve);

  static bool isCurveCustomized(List<CurvePoint> points) {
    if (points.isEmpty) return false;
    if (points.length != 2) return true;
    return points[0].x != 0.0 || points[0].y != 0.0 || points[1].x != 1.0 || points[1].y != 1.0;
  }

  ColorGradingConfig copyWith({
    double? exposure,
    double? contrast,
    double? saturation,
    double? brightness,
    double? temperature,
    double? tint,
    double? highlights,
    double? shadows,
    double? whites,
    double? blacks,
    double? fade,
    double? clarity,
    double? sharpness,
    double? vignette,
    LutPreset? activeLut,
    double? lutIntensity,
    ColorWheelValue? lift,
    ColorWheelValue? gamma,
    ColorWheelValue? gain,
    ColorWheelValue? offset,
    Map<String, HslShift>? hsl,
    List<CurvePoint>? masterCurve,
  }) {
    return ColorGradingConfig(
      exposure: exposure ?? this.exposure,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      brightness: brightness ?? this.brightness,
      temperature: temperature ?? this.temperature,
      tint: tint ?? this.tint,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      whites: whites ?? this.whites,
      blacks: blacks ?? this.blacks,
      fade: fade ?? this.fade,
      clarity: clarity ?? this.clarity,
      sharpness: sharpness ?? this.sharpness,
      vignette: vignette ?? this.vignette,
      activeLut: activeLut ?? this.activeLut,
      lutIntensity: lutIntensity ?? this.lutIntensity,
      lift: lift ?? this.lift,
      gamma: gamma ?? this.gamma,
      gain: gain ?? this.gain,
      offset: offset ?? this.offset,
      hsl: hsl ?? this.hsl,
      masterCurve: masterCurve ?? this.masterCurve,
    );
  }

  Map<String, dynamic> toJson() => {
        'exposure': exposure,
        'contrast': contrast,
        'saturation': saturation,
        'brightness': brightness,
        'temperature': temperature,
        'tint': tint,
        'highlights': highlights,
        'shadows': shadows,
        'whites': whites,
        'blacks': blacks,
        'fade': fade,
        'clarity': clarity,
        'sharpness': sharpness,
        'vignette': vignette,
        'activeLut': activeLut.name,
        'lutIntensity': lutIntensity,
        'lift': lift.toJson(),
        'gamma': gamma.toJson(),
        'gain': gain.toJson(),
        'offset': offset.toJson(),
        'hsl': hsl.map((k, v) => MapEntry(k, v.toJson())),
        'masterCurve': masterCurve.map((p) => p.toJson()).toList(),
      };

  factory ColorGradingConfig.fromJson(Map<String, dynamic> json) {
    final rawHsl = json['hsl'] as Map<String, dynamic>? ?? {};
    final hslMap = rawHsl.map((k, v) => MapEntry(k, HslShift.fromJson(v as Map<String, dynamic>)));

    final rawCurves = json['masterCurve'] as List<dynamic>? ?? [];
    final curveList = rawCurves.map((p) => CurvePoint.fromJson(p as Map<String, dynamic>)).toList();

    return ColorGradingConfig(
      exposure: (json['exposure'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      tint: (json['tint'] as num?)?.toDouble() ?? 0.0,
      highlights: (json['highlights'] as num?)?.toDouble() ?? 0.0,
      shadows: (json['shadows'] as num?)?.toDouble() ?? 0.0,
      whites: (json['whites'] as num?)?.toDouble() ?? 0.0,
      blacks: (json['blacks'] as num?)?.toDouble() ?? 0.0,
      fade: (json['fade'] as num?)?.toDouble() ?? 0.0,
      clarity: (json['clarity'] as num?)?.toDouble() ?? 1.0,
      sharpness: (json['sharpness'] as num?)?.toDouble() ?? 1.0,
      vignette: (json['vignette'] as num?)?.toDouble() ?? 0.0,
      activeLut: LutPreset.values.firstWhere(
        (e) => e.name == json['activeLut'],
        orElse: () => LutPreset.none,
      ),
      lutIntensity: (json['lutIntensity'] as num?)?.toDouble() ?? 1.0,
      lift: json['lift'] != null
          ? ColorWheelValue.fromJson(json['lift'] as Map<String, dynamic>)
          : const ColorWheelValue(),
      gamma: json['gamma'] != null
          ? ColorWheelValue.fromJson(json['gamma'] as Map<String, dynamic>)
          : const ColorWheelValue(),
      gain: json['gain'] != null
          ? ColorWheelValue.fromJson(json['gain'] as Map<String, dynamic>)
          : const ColorWheelValue(),
      offset: json['offset'] != null
          ? ColorWheelValue.fromJson(json['offset'] as Map<String, dynamic>)
          : const ColorWheelValue(),
      hsl: hslMap,
      masterCurve: curveList.isNotEmpty ? curveList : const [CurvePoint(0.0, 0.0), CurvePoint(1.0, 1.0)],
    );
  }

  @override
  List<Object?> get props => [
        exposure,
        contrast,
        saturation,
        brightness,
        temperature,
        tint,
        highlights,
        shadows,
        whites,
        blacks,
        fade,
        clarity,
        sharpness,
        vignette,
        activeLut,
        lutIntensity,
        lift,
        gamma,
        gain,
        offset,
        hsl,
        masterCurve,
      ];
}
