import 'package:equatable/equatable.dart';

enum VideoLayoutRatio {
  ratio16_9('16:9 YouTube / TV', 16 / 9, 1920, 1080),
  ratio9_16('9:16 Shorts / Reels / TikTok', 9 / 16, 1080, 1920),
  ratio1_1('1:1 Square Feed', 1 / 1, 1080, 1080),
  ratio4_5('4:5 Portrait Feed', 4 / 5, 1080, 1350),
  ratio4_3('4:3 Classic TV / iPad', 4 / 3, 1440, 1080),
  ratio3_4('3:4 Vertical Tablet', 3 / 4, 1080, 1440),
  ratio21_9('21:9 Ultra-Wide Cinema', 21 / 9, 2560, 1080),
  ratio239_1('2.39:1 Cinemascope', 2.39, 2560, 1072);

  final String label;
  final double aspectRatio;
  final int defaultWidth;
  final int defaultHeight;
  const VideoLayoutRatio(this.label, this.aspectRatio, this.defaultWidth, this.defaultHeight);
}

enum LayoutBackgroundMode {
  blur('Gaussian Video Blur'),
  solidColor('Solid Color Frame'),
  gradient('Aesthetic Gradient');

  final String label;
  const LayoutBackgroundMode(this.label);
}

enum LayoutFillMode {
  fit('Fit (Letterbox)'),
  fill('Fill (Crop to Canvas)');

  final String label;
  const LayoutFillMode(this.label);
}

enum AutoReframeMode {
  fitWithBlur('Clone Blur Fill'),
  smartCrop('Smart Crop (Pan & Scan)'),
  solidPillarbox('Solid Color Frame'),
  gradientCanvas('Cinematic Gradient');

  final String label;
  const AutoReframeMode(this.label);
}

enum GradientCanvasPreset {
  midnight('Midnight Neon', [0xFF0F2027, 0xFF203A43, 0xFF2C5364]),
  sunset('Vibrant Sunset', [0xFFFF512F, 0xFFDD2476, 0xFF4A00E0]),
  cyberpunk('Cyberpunk Glow', [0xFF8A2387, 0xFFE94057, 0xFFF27121]),
  studioCharcoal('Studio Charcoal', [0xFF232526, 0xFF414345]),
  electricViolet('Electric Violet', [0xFF4A00E0, 0xFF8E2DE2]);

  final String label;
  final List<int> colors;
  const GradientCanvasPreset(this.label, this.colors);
}

class VideoLayoutConfig extends Equatable {
  final VideoLayoutRatio ratio;
  final AutoReframeMode reframeMode;
  final LayoutBackgroundMode backgroundMode;
  final LayoutFillMode fillMode;
  final int backgroundColor;
  final GradientCanvasPreset gradientPreset;
  final double framePadding;     // 0 to 40 px padding around video
  final double cornerRadius;     // 0 to 32 px rounded corners
  final double blurIntensity;    // 5 to 50 for background blur
  final double focalPointX;      // -1.0 (left) to 1.0 (right) for smart crop pan & scan
  final double focalPointY;      // -1.0 (top) to 1.0 (bottom) for smart crop tilt

  const VideoLayoutConfig({
    this.ratio = VideoLayoutRatio.ratio16_9,
    this.reframeMode = AutoReframeMode.fitWithBlur,
    this.backgroundMode = LayoutBackgroundMode.blur,
    this.fillMode = LayoutFillMode.fit,
    this.backgroundColor = 0xFF000000,
    this.gradientPreset = GradientCanvasPreset.midnight,
    this.framePadding = 0.0,
    this.cornerRadius = 0.0,
    this.blurIntensity = 22.0,
    this.focalPointX = 0.0,
    this.focalPointY = 0.0,
  });

  bool get isBlurFill =>
      reframeMode == AutoReframeMode.fitWithBlur ||
      (reframeMode == AutoReframeMode.solidPillarbox && backgroundMode == LayoutBackgroundMode.blur);

  bool get isSmartCrop =>
      reframeMode == AutoReframeMode.smartCrop || fillMode == LayoutFillMode.fill;

  VideoLayoutConfig copyWith({
    VideoLayoutRatio? ratio,
    AutoReframeMode? reframeMode,
    LayoutBackgroundMode? backgroundMode,
    LayoutFillMode? fillMode,
    int? backgroundColor,
    GradientCanvasPreset? gradientPreset,
    double? framePadding,
    double? cornerRadius,
    double? blurIntensity,
    double? focalPointX,
    double? focalPointY,
  }) {
    return VideoLayoutConfig(
      ratio: ratio ?? this.ratio,
      reframeMode: reframeMode ?? this.reframeMode,
      backgroundMode: backgroundMode ?? this.backgroundMode,
      fillMode: fillMode ?? this.fillMode,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradientPreset: gradientPreset ?? this.gradientPreset,
      framePadding: framePadding ?? this.framePadding,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      blurIntensity: blurIntensity ?? this.blurIntensity,
      focalPointX: focalPointX ?? this.focalPointX,
      focalPointY: focalPointY ?? this.focalPointY,
    );
  }

  Map<String, dynamic> toJson() => {
        'ratio': ratio.name,
        'reframeMode': reframeMode.name,
        'backgroundMode': backgroundMode.name,
        'fillMode': fillMode.name,
        'backgroundColor': backgroundColor,
        'gradientPreset': gradientPreset.name,
        'framePadding': framePadding,
        'cornerRadius': cornerRadius,
        'blurIntensity': blurIntensity,
        'focalPointX': focalPointX,
        'focalPointY': focalPointY,
      };

  factory VideoLayoutConfig.fromJson(Map<String, dynamic> json) {
    // Determine reframe mode with fallback to legacy background/fill modes
    AutoReframeMode resolvedReframeMode = AutoReframeMode.fitWithBlur;
    if (json['reframeMode'] != null) {
      resolvedReframeMode = AutoReframeMode.values.firstWhere(
        (e) => e.name == json['reframeMode'],
        orElse: () => AutoReframeMode.fitWithBlur,
      );
    } else if (json['fillMode'] == 'fill') {
      resolvedReframeMode = AutoReframeMode.smartCrop;
    } else if (json['backgroundMode'] == 'solidColor') {
      resolvedReframeMode = AutoReframeMode.solidPillarbox;
    } else if (json['backgroundMode'] == 'gradient') {
      resolvedReframeMode = AutoReframeMode.gradientCanvas;
    }

    return VideoLayoutConfig(
      ratio: VideoLayoutRatio.values.firstWhere(
        (e) => e.name == json['ratio'],
        orElse: () => VideoLayoutRatio.ratio16_9,
      ),
      reframeMode: resolvedReframeMode,
      backgroundMode: LayoutBackgroundMode.values.firstWhere(
        (e) => e.name == json['backgroundMode'],
        orElse: () => LayoutBackgroundMode.blur,
      ),
      fillMode: LayoutFillMode.values.firstWhere(
        (e) => e.name == json['fillMode'],
        orElse: () => LayoutFillMode.fit,
      ),
      backgroundColor: (json['backgroundColor'] as num?)?.toInt() ?? 0xFF000000,
      gradientPreset: GradientCanvasPreset.values.firstWhere(
        (e) => e.name == json['gradientPreset'],
        orElse: () => GradientCanvasPreset.midnight,
      ),
      framePadding: (json['framePadding'] as num?)?.toDouble() ?? 0.0,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
      blurIntensity: (json['blurIntensity'] as num?)?.toDouble() ?? 22.0,
      focalPointX: (json['focalPointX'] as num?)?.toDouble() ?? 0.0,
      focalPointY: (json['focalPointY'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        ratio,
        reframeMode,
        backgroundMode,
        fillMode,
        backgroundColor,
        gradientPreset,
        framePadding,
        cornerRadius,
        blurIntensity,
        focalPointX,
        focalPointY,
      ];
}
