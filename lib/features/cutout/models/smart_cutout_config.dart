import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum CutoutType {
  none,
  autoPortrait,
  customSubject,
  chromaKey,
}

enum CutoutStrokeStyle {
  none,
  solidBorder,
  neonGlow,
  cyberPink,
  goldenAura,
  matrixGreen,
  dashedSticker,
}

enum CutoutBackgroundMode {
  transparent,
  blur,
  solidColor,
}

class SmartCutoutConfig extends Equatable {
  final bool isEnabled;
  final CutoutType type;
  final CutoutStrokeStyle strokeStyle;
  final int strokeColorValue; // ARGB, e.g. 0xFF00E5FF
  final double strokeWidth;    // 0.0 to 20.0 px
  final double glowSpread;     // 0.0 to 30.0 px
  final double edgeFeather;    // 0.0 to 1.0
  final bool isInverted;       // Invert subject & background
  final CutoutBackgroundMode backgroundMode;
  final double backgroundBlur; // 0.0 to 30.0 px
  final int backgroundColorValue; // ARGB, e.g. 0xFF121212

  const SmartCutoutConfig({
    this.isEnabled = false,
    this.type = CutoutType.autoPortrait,
    this.strokeStyle = CutoutStrokeStyle.none,
    this.strokeColorValue = 0xFF00E5FF, // Neon Cyan default
    this.strokeWidth = 4.0,
    this.glowSpread = 10.0,
    this.edgeFeather = 0.25,
    this.isInverted = false,
    this.backgroundMode = CutoutBackgroundMode.transparent,
    this.backgroundBlur = 12.0,
    this.backgroundColorValue = 0xFF121212,
  });

  Color get strokeColor => Color(strokeColorValue);
  Color get backgroundColor => Color(backgroundColorValue);

  // --- CapCut Signature Pro Presets ---

  static const SmartCutoutConfig presetNeonCyan = SmartCutoutConfig(
    isEnabled: true,
    type: CutoutType.autoPortrait,
    strokeStyle: CutoutStrokeStyle.neonGlow,
    strokeColorValue: 0xFF00E5FF,
    strokeWidth: 4.0,
    glowSpread: 14.0,
    edgeFeather: 0.2,
  );

  static const SmartCutoutConfig presetCyberPink = SmartCutoutConfig(
    isEnabled: true,
    type: CutoutType.autoPortrait,
    strokeStyle: CutoutStrokeStyle.cyberPink,
    strokeColorValue: 0xFFFF007F,
    strokeWidth: 4.5,
    glowSpread: 16.0,
    edgeFeather: 0.2,
  );

  static const SmartCutoutConfig presetGoldenAura = SmartCutoutConfig(
    isEnabled: true,
    type: CutoutType.autoPortrait,
    strokeStyle: CutoutStrokeStyle.goldenAura,
    strokeColorValue: 0xFFFFD700,
    strokeWidth: 4.0,
    glowSpread: 12.0,
    edgeFeather: 0.25,
  );

  static const SmartCutoutConfig presetMatrixGreen = SmartCutoutConfig(
    isEnabled: true,
    type: CutoutType.autoPortrait,
    strokeStyle: CutoutStrokeStyle.matrixGreen,
    strokeColorValue: 0xFF00FF66,
    strokeWidth: 4.0,
    glowSpread: 12.0,
    edgeFeather: 0.2,
  );

  static const SmartCutoutConfig presetWhiteSticker = SmartCutoutConfig(
    isEnabled: true,
    type: CutoutType.autoPortrait,
    strokeStyle: CutoutStrokeStyle.solidBorder,
    strokeColorValue: 0xFFFFFFFF,
    strokeWidth: 6.0,
    glowSpread: 0.0,
    edgeFeather: 0.1,
  );

  static const SmartCutoutConfig presetPortraitBokeh = SmartCutoutConfig(
    isEnabled: true,
    type: CutoutType.autoPortrait,
    strokeStyle: CutoutStrokeStyle.none,
    backgroundMode: CutoutBackgroundMode.blur,
    backgroundBlur: 16.0,
    edgeFeather: 0.35,
  );

  static const SmartCutoutConfig presetStudioDark = SmartCutoutConfig(
    isEnabled: true,
    type: CutoutType.autoPortrait,
    strokeStyle: CutoutStrokeStyle.none,
    backgroundMode: CutoutBackgroundMode.solidColor,
    backgroundColorValue: 0xFF141419,
    edgeFeather: 0.3,
  );

  SmartCutoutConfig copyWith({
    bool? isEnabled,
    CutoutType? type,
    CutoutStrokeStyle? strokeStyle,
    int? strokeColorValue,
    double? strokeWidth,
    double? glowSpread,
    double? edgeFeather,
    bool? isInverted,
    CutoutBackgroundMode? backgroundMode,
    double? backgroundBlur,
    int? backgroundColorValue,
  }) {
    return SmartCutoutConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      type: type ?? this.type,
      strokeStyle: strokeStyle ?? this.strokeStyle,
      strokeColorValue: strokeColorValue ?? this.strokeColorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      glowSpread: glowSpread ?? this.glowSpread,
      edgeFeather: edgeFeather ?? this.edgeFeather,
      isInverted: isInverted ?? this.isInverted,
      backgroundMode: backgroundMode ?? this.backgroundMode,
      backgroundBlur: backgroundBlur ?? this.backgroundBlur,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'type': type.name,
        'strokeStyle': strokeStyle.name,
        'strokeColorValue': strokeColorValue,
        'strokeWidth': strokeWidth,
        'glowSpread': glowSpread,
        'edgeFeather': edgeFeather,
        'isInverted': isInverted,
        'backgroundMode': backgroundMode.name,
        'backgroundBlur': backgroundBlur,
        'backgroundColorValue': backgroundColorValue,
      };

  factory SmartCutoutConfig.fromJson(Map<String, dynamic> json) => SmartCutoutConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        type: CutoutType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CutoutType.autoPortrait,
        ),
        strokeStyle: CutoutStrokeStyle.values.firstWhere(
          (e) => e.name == json['strokeStyle'],
          orElse: () => CutoutStrokeStyle.none,
        ),
        strokeColorValue: (json['strokeColorValue'] as num?)?.toInt() ?? 0xFF00E5FF,
        strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 4.0,
        glowSpread: (json['glowSpread'] as num?)?.toDouble() ?? 10.0,
        edgeFeather: (json['edgeFeather'] as num?)?.toDouble() ?? 0.25,
        isInverted: json['isInverted'] as bool? ?? false,
        backgroundMode: CutoutBackgroundMode.values.firstWhere(
          (e) => e.name == json['backgroundMode'],
          orElse: () => CutoutBackgroundMode.transparent,
        ),
        backgroundBlur: (json['backgroundBlur'] as num?)?.toDouble() ?? 12.0,
        backgroundColorValue: (json['backgroundColorValue'] as num?)?.toInt() ?? 0xFF121212,
      );

  @override
  List<Object?> get props => [
        isEnabled,
        type,
        strokeStyle,
        strokeColorValue,
        strokeWidth,
        glowSpread,
        edgeFeather,
        isInverted,
        backgroundMode,
        backgroundBlur,
        backgroundColorValue,
      ];
}
