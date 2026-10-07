import 'package:equatable/equatable.dart';

/// Luminance transparency keying modes for silhouette and tonal extraction.
enum LumaKeyMode {
  darkSilhouette,
  brightSpecular,
  midtonesOnly,
  highContrastLuma,
  softThresholdGradient;

  String get displayName {
    switch (this) {
      case LumaKeyMode.darkSilhouette:
        return 'Dark Silhouette Key';
      case LumaKeyMode.brightSpecular:
        return 'Bright Specular / Sky Key';
      case LumaKeyMode.midtonesOnly:
        return 'Midtones Isolation Key';
      case LumaKeyMode.highContrastLuma:
        return 'High-Contrast Stencil';
      case LumaKeyMode.softThresholdGradient:
        return 'Soft Feathered Luma Key';
    }
  }

  String get description {
    switch (this) {
      case LumaKeyMode.darkSilhouette:
        return 'Extracts dark background regions, making black/deep shadows transparent';
      case LumaKeyMode.brightSpecular:
        return 'Extracts bright highlight regions, making whites and bright sky transparent';
      case LumaKeyMode.midtonesOnly:
        return 'Preserves midtone subject data while keying out both deep shadows and peaks';
      case LumaKeyMode.highContrastLuma:
        return 'Hard binary luminance thresholding creating stark graphic silhouette cutouts';
      case LumaKeyMode.softThresholdGradient:
        return 'Smooth feathered luminance ramp transparency for seamless organic blending';
    }
  }
}

/// Configuration for luma keying, silhouette extraction, and luminance transparency masks.
class LumaKeyConfig extends Equatable {
  final bool isEnabled;
  final LumaKeyMode mode;
  final double threshold; // 0.0 to 1.0 luminance cutoff
  final double tolerance; // 0.01 to 0.50 softness/feathering band
  final bool invert; // Invert keying transparency
  final double opacity; // 0.0 to 1.0 composite opacity

  const LumaKeyConfig({
    this.isEnabled = false,
    this.mode = LumaKeyMode.darkSilhouette,
    this.threshold = 0.20,
    this.tolerance = 0.10,
    this.invert = false,
    this.opacity = 1.0,
  });

  bool get isActive => isEnabled;

  LumaKeyConfig copyWith({
    bool? isEnabled,
    LumaKeyMode? mode,
    double? threshold,
    double? tolerance,
    bool? invert,
    double? opacity,
  }) {
    return LumaKeyConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      threshold: threshold ?? this.threshold,
      tolerance: tolerance ?? this.tolerance,
      invert: invert ?? this.invert,
      opacity: opacity ?? this.opacity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'threshold': threshold,
      'tolerance': tolerance,
      'invert': invert,
      'opacity': opacity,
    };
  }

  factory LumaKeyConfig.fromJson(Map<String, dynamic> json) {
    LumaKeyMode parsedMode = LumaKeyMode.darkSilhouette;
    if (json['mode'] != null) {
      try {
        parsedMode = LumaKeyMode.values.byName(json['mode'] as String);
      } catch (_) {
        parsedMode = LumaKeyMode.darkSilhouette;
      }
    }

    return LumaKeyConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: parsedMode,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.20,
      tolerance: (json['tolerance'] as num?)?.toDouble() ?? 0.10,
      invert: json['invert'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  // Curated presets
  static const LumaKeyConfig blackBackdropKey = LumaKeyConfig(
    isEnabled: true,
    mode: LumaKeyMode.darkSilhouette,
    threshold: 0.18,
    tolerance: 0.12,
    invert: false,
    opacity: 1.0,
  );

  static const LumaKeyConfig whiteSkyCutout = LumaKeyConfig(
    isEnabled: true,
    mode: LumaKeyMode.brightSpecular,
    threshold: 0.82,
    tolerance: 0.15,
    invert: false,
    opacity: 1.0,
  );

  static const LumaKeyConfig highContrastStencil = LumaKeyConfig(
    isEnabled: true,
    mode: LumaKeyMode.highContrastLuma,
    threshold: 0.50,
    tolerance: 0.03,
    invert: false,
    opacity: 1.0,
  );

  static const LumaKeyConfig shadowGhost = LumaKeyConfig(
    isEnabled: true,
    mode: LumaKeyMode.darkSilhouette,
    threshold: 0.35,
    tolerance: 0.25,
    invert: true,
    opacity: 0.85,
  );

  static const LumaKeyConfig midtonesBand = LumaKeyConfig(
    isEnabled: true,
    mode: LumaKeyMode.midtonesOnly,
    threshold: 0.50,
    tolerance: 0.28,
    invert: false,
    opacity: 1.0,
  );

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        threshold,
        tolerance,
        invert,
        opacity,
      ];
}
