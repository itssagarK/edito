import 'package:equatable/equatable.dart';

enum PipShape {
  rectangle,
  roundedRect,
  circle,
  diamond,
  squircle,
}

extension PipShapeExtension on PipShape {
  String get label {
    switch (this) {
      case PipShape.rectangle:
        return 'Sharp Window';
      case PipShape.roundedRect:
        return 'Rounded Window';
      case PipShape.circle:
        return 'Circle Webcam';
      case PipShape.diamond:
        return 'Diamond';
      case PipShape.squircle:
        return 'Squircle (iOS)';
    }
  }
}

enum PipPreset {
  custom,
  bottomRightWebcam,
  bottomLeft,
  topRight,
  topLeftGaming,
  sideBySideLeft,
  sideBySideRight,
  circleWebcam,
  centerFloating,
}

extension PipPresetExtension on PipPreset {
  String get label {
    switch (this) {
      case PipPreset.custom:
        return 'Custom Freeform';
      case PipPreset.bottomRightWebcam:
        return 'Webcam (Bottom-Right)';
      case PipPreset.bottomLeft:
        return 'Bottom-Left';
      case PipPreset.topRight:
        return 'Top-Right';
      case PipPreset.topLeftGaming:
        return 'Gaming HUD (Top-Left)';
      case PipPreset.sideBySideLeft:
        return 'Split Left (50%)';
      case PipPreset.sideBySideRight:
        return 'Split Right (50%)';
      case PipPreset.circleWebcam:
        return 'Circle Portrait';
      case PipPreset.centerFloating:
        return 'Center Floating';
    }
  }
}

class ImageOverlayConfig extends Equatable {
  final bool isEnabled;
  final String mediaPath; // Video or image overlay path
  final String assetLabel;
  final PipShape shape;
  final PipPreset preset;
  final double positionX; // 0.0 to 1.0 (0.5 = centered)
  final double positionY; // 0.0 to 1.0 (0.5 = centered)
  final double scale;     // 0.15 to 2.0 (0.32 = standard PiP)
  final double opacity;   // 0.0 to 1.0
  final double rotation;  // 0 to 360 degrees
  final bool isPiP;       // True if framed as a Picture-in-Picture window
  final double cornerRadius;
  final double borderWidth;
  final int borderColor;
  final bool hasShadow;
  final double shadowBlur;
  final int shadowColor;

  const ImageOverlayConfig({
    this.isEnabled = false,
    this.mediaPath = '',
    this.assetLabel = '',
    this.shape = PipShape.roundedRect,
    this.preset = PipPreset.bottomRightWebcam,
    this.positionX = 0.80,
    this.positionY = 0.80,
    this.scale = 0.32,
    this.opacity = 1.0,
    this.rotation = 0.0,
    this.isPiP = true,
    this.cornerRadius = 14.0,
    this.borderWidth = 2.5,
    this.borderColor = 0xFFFFFFFF,
    this.hasShadow = true,
    this.shadowBlur = 10.0,
    this.shadowColor = 0x99000000,
  });

  /// Backward-compatibility getter for imagePath
  String get imagePath => mediaPath;

  static ImageOverlayConfig getPresetConfig(
    PipPreset preset, {
    String? mediaPath,
    String? assetLabel,
  }) {
    switch (preset) {
      case PipPreset.bottomRightWebcam:
        return ImageOverlayConfig(
          isEnabled: true,
          preset: preset,
          mediaPath: mediaPath ?? '',
          assetLabel: assetLabel ?? 'Webcam',
          shape: PipShape.roundedRect,
          positionX: 0.80,
          positionY: 0.80,
          scale: 0.32,
          cornerRadius: 16.0,
          borderWidth: 2.5,
        );
      case PipPreset.bottomLeft:
        return ImageOverlayConfig(
          isEnabled: true,
          preset: preset,
          mediaPath: mediaPath ?? '',
          assetLabel: assetLabel ?? 'PiP Left',
          shape: PipShape.roundedRect,
          positionX: 0.20,
          positionY: 0.80,
          scale: 0.32,
          cornerRadius: 16.0,
          borderWidth: 2.5,
        );
      case PipPreset.topRight:
        return ImageOverlayConfig(
          isEnabled: true,
          preset: preset,
          mediaPath: mediaPath ?? '',
          assetLabel: assetLabel ?? 'PiP Top Right',
          shape: PipShape.roundedRect,
          positionX: 0.80,
          positionY: 0.20,
          scale: 0.32,
          cornerRadius: 16.0,
          borderWidth: 2.5,
        );
      case PipPreset.topLeftGaming:
        return ImageOverlayConfig(
          isEnabled: true,
          preset: preset,
          mediaPath: mediaPath ?? '',
          assetLabel: assetLabel ?? 'Gaming HUD',
          shape: PipShape.roundedRect,
          positionX: 0.20,
          positionY: 0.20,
          scale: 0.32,
          cornerRadius: 16.0,
          borderWidth: 2.5,
        );
      case PipPreset.circleWebcam:
        return ImageOverlayConfig(
          isEnabled: true,
          preset: preset,
          mediaPath: mediaPath ?? '',
          assetLabel: assetLabel ?? 'Circle Webcam',
          shape: PipShape.circle,
          positionX: 0.80,
          positionY: 0.80,
          scale: 0.30,
          cornerRadius: 999.0,
          borderWidth: 3.0,
        );
      case PipPreset.sideBySideLeft:
        return ImageOverlayConfig(
          isEnabled: true,
          preset: preset,
          mediaPath: mediaPath ?? '',
          assetLabel: assetLabel ?? 'Split Left',
          shape: PipShape.rectangle,
          positionX: 0.25,
          positionY: 0.50,
          scale: 0.50,
          cornerRadius: 0.0,
          borderWidth: 1.5,
        );
      case PipPreset.sideBySideRight:
        return ImageOverlayConfig(
          isEnabled: true,
          preset: preset,
          mediaPath: mediaPath ?? '',
          assetLabel: assetLabel ?? 'Split Right',
          shape: PipShape.rectangle,
          positionX: 0.75,
          positionY: 0.50,
          scale: 0.50,
          cornerRadius: 0.0,
          borderWidth: 1.5,
        );
      case PipPreset.centerFloating:
        return ImageOverlayConfig(
          isEnabled: true,
          preset: preset,
          mediaPath: mediaPath ?? '',
          assetLabel: assetLabel ?? 'Center Floating',
          shape: PipShape.squircle,
          positionX: 0.50,
          positionY: 0.50,
          scale: 0.45,
          cornerRadius: 20.0,
          borderWidth: 2.5,
        );
      case PipPreset.custom:
        return ImageOverlayConfig(
          isEnabled: true,
          preset: preset,
          mediaPath: mediaPath ?? '',
          assetLabel: assetLabel ?? 'Custom PiP',
        );
    }
  }

  ImageOverlayConfig copyWith({
    bool? isEnabled,
    String? mediaPath,
    String? imagePath,
    String? assetLabel,
    PipShape? shape,
    PipPreset? preset,
    double? positionX,
    double? positionY,
    double? scale,
    double? opacity,
    double? rotation,
    bool? isPiP,
    double? cornerRadius,
    double? borderWidth,
    int? borderColor,
    bool? hasShadow,
    double? shadowBlur,
    int? shadowColor,
  }) {
    return ImageOverlayConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mediaPath: mediaPath ?? imagePath ?? this.mediaPath,
      assetLabel: assetLabel ?? this.assetLabel,
      shape: shape ?? this.shape,
      preset: preset ?? this.preset,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
      isPiP: isPiP ?? this.isPiP,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      hasShadow: hasShadow ?? this.hasShadow,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'mediaPath': mediaPath,
        'imagePath': mediaPath, // legacy support
        'assetLabel': assetLabel,
        'shape': shape.name,
        'preset': preset.name,
        'positionX': positionX,
        'positionY': positionY,
        'scale': scale,
        'opacity': opacity,
        'rotation': rotation,
        'isPiP': isPiP,
        'cornerRadius': cornerRadius,
        'borderWidth': borderWidth,
        'borderColor': borderColor,
        'hasShadow': hasShadow,
        'shadowBlur': shadowBlur,
        'shadowColor': shadowColor,
      };

  factory ImageOverlayConfig.fromJson(Map<String, dynamic> json) {
    final rawPath = json['mediaPath'] as String? ?? json['imagePath'] as String? ?? '';
    final rawShape = json['shape'];
    final shape = PipShape.values.firstWhere(
      (s) => s.name == rawShape,
      orElse: () => PipShape.roundedRect,
    );

    final rawPreset = json['preset'];
    final preset = PipPreset.values.firstWhere(
      (p) => p.name == rawPreset,
      orElse: () => PipPreset.bottomRightWebcam,
    );

    return ImageOverlayConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mediaPath: rawPath,
      assetLabel: json['assetLabel'] as String? ?? '',
      shape: shape,
      preset: preset,
      positionX: (json['positionX'] as num?)?.toDouble() ?? 0.80,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 0.80,
      scale: (json['scale'] as num?)?.toDouble() ?? 0.32,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      isPiP: json['isPiP'] as bool? ?? true,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 14.0,
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 2.5,
      borderColor: (json['borderColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
      hasShadow: json['hasShadow'] as bool? ?? true,
      shadowBlur: (json['shadowBlur'] as num?)?.toDouble() ?? 10.0,
      shadowColor: (json['shadowColor'] as num?)?.toInt() ?? 0x99000000,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mediaPath,
        assetLabel,
        shape,
        preset,
        positionX,
        positionY,
        scale,
        opacity,
        rotation,
        isPiP,
        cornerRadius,
        borderWidth,
        borderColor,
        hasShadow,
        shadowBlur,
        shadowColor,
      ];
}
