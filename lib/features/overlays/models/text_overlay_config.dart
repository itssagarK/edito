import 'package:equatable/equatable.dart';

enum TextAnimationType {
  none,
  fadeIn,
  slideUp,
  typewriter,
  popScale,
  bounce,
  shimmer,
  zoomIn,
  karaoke,
}

extension TextAnimationTypeExtension on TextAnimationType {
  String get label {
    switch (this) {
      case TextAnimationType.none:
        return 'None (Static)';
      case TextAnimationType.fadeIn:
        return 'Smooth Fade In';
      case TextAnimationType.slideUp:
        return 'Slide Up from Bottom';
      case TextAnimationType.typewriter:
        return 'Typewriter Machine';
      case TextAnimationType.popScale:
        return 'Pop & Scale In (TikTok)';
      case TextAnimationType.bounce:
        return 'Punchy Bounce';
      case TextAnimationType.shimmer:
        return 'Golden Shimmer Glow';
      case TextAnimationType.zoomIn:
        return 'Dramatic Zoom In';
      case TextAnimationType.karaoke:
        return 'Karaoke Word Pulse';
    }
  }
}

class TextOverlayConfig extends Equatable {
  final String text;
  final String fontFamily;
  final double fontSize;
  final int textColor;          // 0xFFFFFFFF
  final int? backgroundColor;    // 0x99000000
  final int? strokeColor;
  final double strokeWidth;
  final double positionX;        // 0.0 to 1.0 (0.5 = center)
  final double positionY;        // 0.0 to 1.0 (0.5 = center)
  final double scale;
  final double rotation;         // in degrees
  final double opacity;
  final TextAnimationType animationType;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isUppercase;
  final double letterSpacing;
  final int? shadowColor;
  final double shadowBlur;
  final double boxCornerRadius;
  final double boxPadding;

  const TextOverlayConfig({
    this.text = '',
    this.fontFamily = 'Inter',
    this.fontSize = 24.0,
    this.textColor = 0xFFFFFFFF,
    this.backgroundColor,
    this.strokeColor,
    this.strokeWidth = 0.0,
    this.positionX = 0.5,
    this.positionY = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.animationType = TextAnimationType.fadeIn,
    this.isBold = true,
    this.isItalic = false,
    this.isUnderline = false,
    this.isUppercase = false,
    this.letterSpacing = 0.0,
    this.shadowColor,
    this.shadowBlur = 4.0,
    this.boxCornerRadius = 6.0,
    this.boxPadding = 8.0,
  });

  bool get isEnabled => text.trim().isNotEmpty;

  TextOverlayConfig copyWith({
    String? text,
    String? fontFamily,
    double? fontSize,
    int? textColor,
    int? backgroundColor,
    int? strokeColor,
    double? strokeWidth,
    double? positionX,
    double? positionY,
    double? scale,
    double? rotation,
    double? opacity,
    TextAnimationType? animationType,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isUppercase,
    double? letterSpacing,
    int? shadowColor,
    double? shadowBlur,
    double? boxCornerRadius,
    double? boxPadding,
  }) {
    return TextOverlayConfig(
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      animationType: animationType ?? this.animationType,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isUppercase: isUppercase ?? this.isUppercase,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      boxCornerRadius: boxCornerRadius ?? this.boxCornerRadius,
      boxPadding: boxPadding ?? this.boxPadding,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'textColor': textColor,
        'backgroundColor': backgroundColor,
        'strokeColor': strokeColor,
        'strokeWidth': strokeWidth,
        'positionX': positionX,
        'positionY': positionY,
        'scale': scale,
        'rotation': rotation,
        'opacity': opacity,
        'animationType': animationType.name,
        'isBold': isBold,
        'isItalic': isItalic,
        'isUnderline': isUnderline,
        'isUppercase': isUppercase,
        'letterSpacing': letterSpacing,
        'shadowColor': shadowColor,
        'shadowBlur': shadowBlur,
        'boxCornerRadius': boxCornerRadius,
        'boxPadding': boxPadding,
      };

  factory TextOverlayConfig.fromJson(Map<String, dynamic> json) => TextOverlayConfig(
        text: json['text'] as String? ?? '',
        fontFamily: json['fontFamily'] as String? ?? 'Inter',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
        textColor: (json['textColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
        backgroundColor: (json['backgroundColor'] as num?)?.toInt(),
        strokeColor: (json['strokeColor'] as num?)?.toInt(),
        strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0.0,
        positionX: (json['positionX'] as num?)?.toDouble() ?? 0.5,
        positionY: (json['positionY'] as num?)?.toDouble() ?? 0.5,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        animationType: TextAnimationType.values.firstWhere(
          (e) => e.name == json['animationType'],
          orElse: () => TextAnimationType.none,
        ),
        isBold: json['isBold'] as bool? ?? true,
        isItalic: json['isItalic'] as bool? ?? false,
        isUnderline: json['isUnderline'] as bool? ?? false,
        isUppercase: json['isUppercase'] as bool? ?? false,
        letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
        shadowColor: (json['shadowColor'] as num?)?.toInt(),
        shadowBlur: (json['shadowBlur'] as num?)?.toDouble() ?? 4.0,
        boxCornerRadius: (json['boxCornerRadius'] as num?)?.toDouble() ?? 6.0,
        boxPadding: (json['boxPadding'] as num?)?.toDouble() ?? 8.0,
      );

  @override
  List<Object?> get props => [
        text,
        fontFamily,
        fontSize,
        textColor,
        backgroundColor,
        strokeColor,
        strokeWidth,
        positionX,
        positionY,
        scale,
        rotation,
        opacity,
        animationType,
        isBold,
        isItalic,
        isUnderline,
        isUppercase,
        letterSpacing,
        shadowColor,
        shadowBlur,
        boxCornerRadius,
        boxPadding,
      ];
}
