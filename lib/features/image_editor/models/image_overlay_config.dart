import 'package:equatable/equatable.dart';

class ImageOverlayConfig extends Equatable {
  final bool isEnabled;
  final String imagePath;
  final String assetLabel;
  final double positionX; // 0.0 to 1.0 (0.5 = centered)
  final double positionY; // 0.0 to 1.0 (0.5 = centered)
  final double scale;     // 0.2 to 3.0
  final double opacity;   // 0.0 to 1.0
  final double rotation;  // 0 to 360 degrees
  final bool isPiP;       // True if framed as a Picture-in-Picture window
  final double cornerRadius;
  final int borderColor;

  const ImageOverlayConfig({
    this.isEnabled = false,
    this.imagePath = '',
    this.assetLabel = '',
    this.positionX = 0.5,
    this.positionY = 0.5,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.rotation = 0.0,
    this.isPiP = false,
    this.cornerRadius = 8.0,
    this.borderColor = 0xFFFFFFFF,
  });

  ImageOverlayConfig copyWith({
    bool? isEnabled,
    String? imagePath,
    String? assetLabel,
    double? positionX,
    double? positionY,
    double? scale,
    double? opacity,
    double? rotation,
    bool? isPiP,
    double? cornerRadius,
    int? borderColor,
  }) {
    return ImageOverlayConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      imagePath: imagePath ?? this.imagePath,
      assetLabel: assetLabel ?? this.assetLabel,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
      isPiP: isPiP ?? this.isPiP,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'imagePath': imagePath,
        'assetLabel': assetLabel,
        'positionX': positionX,
        'positionY': positionY,
        'scale': scale,
        'opacity': opacity,
        'rotation': rotation,
        'isPiP': isPiP,
        'cornerRadius': cornerRadius,
        'borderColor': borderColor,
      };

  factory ImageOverlayConfig.fromJson(Map<String, dynamic> json) => ImageOverlayConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        imagePath: json['imagePath'] as String? ?? '',
        assetLabel: json['assetLabel'] as String? ?? '',
        positionX: (json['positionX'] as num?)?.toDouble() ?? 0.5,
        positionY: (json['positionY'] as num?)?.toDouble() ?? 0.5,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        isPiP: json['isPiP'] as bool? ?? false,
        cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 8.0,
        borderColor: (json['borderColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
      );

  @override
  List<Object?> get props => [
        isEnabled,
        imagePath,
        assetLabel,
        positionX,
        positionY,
        scale,
        opacity,
        rotation,
        isPiP,
        cornerRadius,
        borderColor,
      ];
}
