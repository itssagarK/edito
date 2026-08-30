import 'package:equatable/equatable.dart';

enum TextAnimationType {
  none,
  fadeIn,
  slideUp,
  typewriter,
  popScale,
  shimmer,
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
        return 'Pop & Scale In';
      case TextAnimationType.shimmer:
        return 'Golden Shimmer Glow';
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

  const TextOverlayConfig({
    this.text = 'Title Text',
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
  });

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
      };

  factory TextOverlayConfig.fromJson(Map<String, dynamic> json) => TextOverlayConfig(
        text: json['text'] as String? ?? 'Title Text',
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
      ];
}
