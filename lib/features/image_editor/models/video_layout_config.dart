import 'package:equatable/equatable.dart';

enum VideoLayoutRatio {
  ratio16_9('16:9 YouTube / TV', 16 / 9, 1920, 1080),
  ratio9_16('9:16 Reels / Shorts / TikTok', 9 / 16, 1080, 1920),
  ratio1_1('1:1 Square Feed', 1 / 1, 1080, 1080),
  ratio4_5('4:5 Portrait Feed', 4 / 5, 1080, 1350),
  ratio21_9('21:9 Ultra-Wide Cinema', 21 / 9, 2560, 1080);

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

class VideoLayoutConfig extends Equatable {
  final VideoLayoutRatio ratio;
  final LayoutBackgroundMode backgroundMode;
  final LayoutFillMode fillMode;
  final int backgroundColor;
  final double framePadding; // 0 to 40 px padding around video
  final double cornerRadius; // 0 to 32 px rounded corners
  final double blurIntensity; // 5 to 50 for background blur

  const VideoLayoutConfig({
    this.ratio = VideoLayoutRatio.ratio16_9,
    this.backgroundMode = LayoutBackgroundMode.blur,
    this.fillMode = LayoutFillMode.fit,
    this.backgroundColor = 0xFF000000,
    this.framePadding = 0.0,
    this.cornerRadius = 0.0,
    this.blurIntensity = 20.0,
  });

  VideoLayoutConfig copyWith({
    VideoLayoutRatio? ratio,
    LayoutBackgroundMode? backgroundMode,
    LayoutFillMode? fillMode,
    int? backgroundColor,
    double? framePadding,
    double? cornerRadius,
    double? blurIntensity,
  }) {
    return VideoLayoutConfig(
      ratio: ratio ?? this.ratio,
      backgroundMode: backgroundMode ?? this.backgroundMode,
      fillMode: fillMode ?? this.fillMode,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      framePadding: framePadding ?? this.framePadding,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      blurIntensity: blurIntensity ?? this.blurIntensity,
    );
  }

  Map<String, dynamic> toJson() => {
        'ratio': ratio.name,
        'backgroundMode': backgroundMode.name,
        'fillMode': fillMode.name,
        'backgroundColor': backgroundColor,
        'framePadding': framePadding,
        'cornerRadius': cornerRadius,
        'blurIntensity': blurIntensity,
      };

  factory VideoLayoutConfig.fromJson(Map<String, dynamic> json) => VideoLayoutConfig(
        ratio: VideoLayoutRatio.values.firstWhere(
          (e) => e.name == json['ratio'],
          orElse: () => VideoLayoutRatio.ratio16_9,
        ),
        backgroundMode: LayoutBackgroundMode.values.firstWhere(
          (e) => e.name == json['backgroundMode'],
          orElse: () => LayoutBackgroundMode.blur,
        ),
        fillMode: LayoutFillMode.values.firstWhere(
          (e) => e.name == json['fillMode'],
          orElse: () => LayoutFillMode.fit,
        ),
        backgroundColor: (json['backgroundColor'] as num?)?.toInt() ?? 0xFF000000,
        framePadding: (json['framePadding'] as num?)?.toDouble() ?? 0.0,
        cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
        blurIntensity: (json['blurIntensity'] as num?)?.toDouble() ?? 20.0,
      );

  @override
  List<Object?> get props => [
        ratio,
        backgroundMode,
        fillMode,
        backgroundColor,
        framePadding,
        cornerRadius,
        blurIntensity,
      ];
}
