import 'package:equatable/equatable.dart';

enum ThumbnailLayoutRatio {
  ratio16_9('16:9 (YouTube / Landscape)', 16 / 9),
  ratio9_16('9:16 (Shorts / Reels / TikTok)', 9 / 16),
  ratio1_1('1:1 (Square / Instagram)', 1 / 1),
  ratio4_5('4:5 (Portrait / Feed)', 4 / 5),
  ratio4_3('4:3 (Standard)', 4 / 3);

  final String label;
  final double aspectRatio;
  const ThumbnailLayoutRatio(this.label, this.aspectRatio);
}

enum ImageFilterPreset {
  normal('Natural'),
  vibrant('Vibrant Pop'),
  cinematic('Cinematic Teal'),
  cyberpunk('Cyber Neon'),
  sunset('Golden Hour'),
  noir('Noir B&W'),
  warmVintage('Vintage 70s');

  final String label;
  const ImageFilterPreset(this.label);
}

class ImageStickerBadge extends Equatable {
  final String id;
  final String label;
  final String emoji;
  final double positionX; // 0.0 to 1.0
  final double positionY; // 0.0 to 1.0
  final double scale;
  final int backgroundColor;
  final int textColor;

  const ImageStickerBadge({
    required this.id,
    required this.label,
    this.emoji = '',
    this.positionX = 0.8,
    this.positionY = 0.2,
    this.scale = 1.0,
    this.backgroundColor = 0xFFFF0055,
    this.textColor = 0xFFFFFFFF,
  });

  ImageStickerBadge copyWith({
    String? id,
    String? label,
    String? emoji,
    double? positionX,
    double? positionY,
    double? scale,
    int? backgroundColor,
    int? textColor,
  }) {
    return ImageStickerBadge(
      id: id ?? this.id,
      label: label ?? this.label,
      emoji: emoji ?? this.emoji,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      scale: scale ?? this.scale,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'emoji': emoji,
        'positionX': positionX,
        'positionY': positionY,
        'scale': scale,
        'backgroundColor': backgroundColor,
        'textColor': textColor,
      };

  factory ImageStickerBadge.fromJson(Map<String, dynamic> json) => ImageStickerBadge(
        id: json['id'] as String,
        label: json['label'] as String,
        emoji: json['emoji'] as String? ?? '',
        positionX: (json['positionX'] as num?)?.toDouble() ?? 0.8,
        positionY: (json['positionY'] as num?)?.toDouble() ?? 0.2,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        backgroundColor: (json['backgroundColor'] as num?)?.toInt() ?? 0xFFFF0055,
        textColor: (json['textColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
      );

  @override
  List<Object?> get props => [id, label, emoji, positionX, positionY, scale, backgroundColor, textColor];
}

class ImageTextHeadline extends Equatable {
  final String text;
  final double positionX; // 0.0 to 1.0
  final double positionY; // 0.0 to 1.0
  final double fontSize;
  final int textColor;
  final int? backgroundColor;
  final bool hasShadow;
  final bool isBold;

  const ImageTextHeadline({
    this.text = 'VIRAL TITLE',
    this.positionX = 0.5,
    this.positionY = 0.8,
    this.fontSize = 28.0,
    this.textColor = 0xFFFFEA00, // Vibrant Yellow
    this.backgroundColor = 0xCC000000, // Semi-transparent black box
    this.hasShadow = true,
    this.isBold = true,
  });

  ImageTextHeadline copyWith({
    String? text,
    double? positionX,
    double? positionY,
    double? fontSize,
    int? textColor,
    int? backgroundColor,
    bool? hasShadow,
    bool? isBold,
  }) {
    return ImageTextHeadline(
      text: text ?? this.text,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      hasShadow: hasShadow ?? this.hasShadow,
      isBold: isBold ?? this.isBold,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'positionX': positionX,
        'positionY': positionY,
        'fontSize': fontSize,
        'textColor': textColor,
        'backgroundColor': backgroundColor,
        'hasShadow': hasShadow,
        'isBold': isBold,
      };

  factory ImageTextHeadline.fromJson(Map<String, dynamic> json) => ImageTextHeadline(
        text: json['text'] as String? ?? 'VIRAL TITLE',
        positionX: (json['positionX'] as num?)?.toDouble() ?? 0.5,
        positionY: (json['positionY'] as num?)?.toDouble() ?? 0.8,
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 28.0,
        textColor: (json['textColor'] as num?)?.toInt() ?? 0xFFFFEA00,
        backgroundColor: (json['backgroundColor'] as num?)?.toInt(),
        hasShadow: json['hasShadow'] as bool? ?? true,
        isBold: json['isBold'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [text, positionX, positionY, fontSize, textColor, backgroundColor, hasShadow, isBold];
}

class ImageEditorConfig extends Equatable {
  final String? imagePath;
  final ThumbnailLayoutRatio layoutRatio;
  final ImageFilterPreset filterPreset;
  final double brightness; // -1.0 to 1.0 (0.0 = normal)
  final double contrast;   // 0.5 to 2.0 (1.0 = normal)
  final double saturation; // 0.0 to 2.0 (1.0 = normal)
  final double vignette;   // 0.0 to 1.0 (0.0 = off)
  final List<ImageTextHeadline> headlines;
  final List<ImageStickerBadge> badges;

  const ImageEditorConfig({
    this.imagePath,
    this.layoutRatio = ThumbnailLayoutRatio.ratio16_9,
    this.filterPreset = ImageFilterPreset.normal,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.vignette = 0.0,
    this.headlines = const [ImageTextHeadline()],
    this.badges = const [],
  });

  ImageEditorConfig copyWith({
    String? imagePath,
    ThumbnailLayoutRatio? layoutRatio,
    ImageFilterPreset? filterPreset,
    double? brightness,
    double? contrast,
    double? saturation,
    double? vignette,
    List<ImageTextHeadline>? headlines,
    List<ImageStickerBadge>? badges,
  }) {
    return ImageEditorConfig(
      imagePath: imagePath ?? this.imagePath,
      layoutRatio: layoutRatio ?? this.layoutRatio,
      filterPreset: filterPreset ?? this.filterPreset,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      vignette: vignette ?? this.vignette,
      headlines: headlines ?? this.headlines,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'layoutRatio': layoutRatio.name,
        'filterPreset': filterPreset.name,
        'brightness': brightness,
        'contrast': contrast,
        'saturation': saturation,
        'vignette': vignette,
        'headlines': headlines.map((h) => h.toJson()).toList(),
        'badges': badges.map((b) => b.toJson()).toList(),
      };

  factory ImageEditorConfig.fromJson(Map<String, dynamic> json) => ImageEditorConfig(
        imagePath: json['imagePath'] as String?,
        layoutRatio: ThumbnailLayoutRatio.values.firstWhere(
          (e) => e.name == json['layoutRatio'],
          orElse: () => ThumbnailLayoutRatio.ratio16_9,
        ),
        filterPreset: ImageFilterPreset.values.firstWhere(
          (e) => e.name == json['filterPreset'],
          orElse: () => ImageFilterPreset.normal,
        ),
        brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
        contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
        saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
        vignette: (json['vignette'] as num?)?.toDouble() ?? 0.0,
        headlines: (json['headlines'] as List<dynamic>?)
                ?.map((h) => ImageTextHeadline.fromJson(h as Map<String, dynamic>))
                .toList() ??
            const [ImageTextHeadline()],
        badges: (json['badges'] as List<dynamic>?)
                ?.map((b) => ImageStickerBadge.fromJson(b as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [
        imagePath,
        layoutRatio,
        filterPreset,
        brightness,
        contrast,
        saturation,
        vignette,
        headlines,
        badges,
      ];
}
