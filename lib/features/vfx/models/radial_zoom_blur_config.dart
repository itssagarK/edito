import 'package:equatable/equatable.dart';

/// Modes of anamorphic radial zoom blur and angular rotational vortex motion.
enum RadialZoomBlurMode {
  hyperspaceWarp,
  actionImpactZoom,
  anamorphicVortex,
  subtleFocusPunch,
  dizzySpin,
}

extension RadialZoomBlurModeExtension on RadialZoomBlurMode {
  String get label {
    switch (this) {
      case RadialZoomBlurMode.hyperspaceWarp:
        return 'Hyperspace Warp';
      case RadialZoomBlurMode.actionImpactZoom:
        return 'Action Impact';
      case RadialZoomBlurMode.anamorphicVortex:
        return 'Anamorphic Vortex';
      case RadialZoomBlurMode.subtleFocusPunch:
        return 'Focus Punch';
      case RadialZoomBlurMode.dizzySpin:
        return 'Dizzy Spin';
    }
  }

  String get description {
    switch (this) {
      case RadialZoomBlurMode.hyperspaceWarp:
        return 'High-velocity cosmic starburst blur radiating from center focal point';
      case RadialZoomBlurMode.actionImpactZoom:
        return 'Explosive radial shockwave impulse emphasizing center target';
      case RadialZoomBlurMode.anamorphicVortex:
        return 'Cinematic spiral vortex with anamorphic horizontal streak flare';
      case RadialZoomBlurMode.subtleFocusPunch:
        return 'Gentle optical focus punch drawing immediate eye attention to center';
      case RadialZoomBlurMode.dizzySpin:
        return 'Continuous rotational centrifugal blur simulating disorienting spin';
    }
  }

  String get iconAsset {
    switch (this) {
      case RadialZoomBlurMode.hyperspaceWarp:
        return 'flare';
      case RadialZoomBlurMode.actionImpactZoom:
        return 'flash_on';
      case RadialZoomBlurMode.anamorphicVortex:
        return 'cyclone';
      case RadialZoomBlurMode.subtleFocusPunch:
        return 'center_focus_strong';
      case RadialZoomBlurMode.dizzySpin:
        return 'rotate_right';
    }
  }
}

/// Configuration for anamorphic radial zoom blur and rotational vortex.
class RadialZoomBlurConfig extends Equatable {
  final bool isEnabled;
  final RadialZoomBlurMode mode;
  final double blurAmount; // 0.0 to 1.0 (radial velocity intensity)
  final double centerX; // 0.0 to 1.0 (normalized horizontal focal center)
  final double centerY; // 0.0 to 1.0 (normalized vertical focal center)
  final double rotationSpin; // -90.0 to 90.0 degrees (angular spin twist)
  final int sampleQuality; // 3 to 12 (number of intermediate blur taps)
  final bool isPulsing; // dynamic rhythmic pulsation

  const RadialZoomBlurConfig({
    this.isEnabled = false,
    this.mode = RadialZoomBlurMode.actionImpactZoom,
    this.blurAmount = 0.4,
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.rotationSpin = 0.0,
    this.sampleQuality = 6,
    this.isPulsing = false,
  });

  bool get isActive => isEnabled && blurAmount > 0.0;

  /// Default disabled configuration.
  static const RadialZoomBlurConfig defaultDisabled = RadialZoomBlurConfig();

  // Curated 5 cinematic presets
  static const RadialZoomBlurConfig presetHyperspace = RadialZoomBlurConfig(
    isEnabled: true,
    mode: RadialZoomBlurMode.hyperspaceWarp,
    blurAmount: 0.75,
    centerX: 0.5,
    centerY: 0.5,
    rotationSpin: 0.0,
    sampleQuality: 8,
    isPulsing: true,
  );

  static const RadialZoomBlurConfig presetImpactSlam = RadialZoomBlurConfig(
    isEnabled: true,
    mode: RadialZoomBlurMode.actionImpactZoom,
    blurAmount: 0.6,
    centerX: 0.5,
    centerY: 0.5,
    rotationSpin: 0.0,
    sampleQuality: 6,
    isPulsing: false,
  );

  static const RadialZoomBlurConfig presetAnamorphicSpiral = RadialZoomBlurConfig(
    isEnabled: true,
    mode: RadialZoomBlurMode.anamorphicVortex,
    blurAmount: 0.5,
    centerX: 0.5,
    centerY: 0.5,
    rotationSpin: 18.0,
    sampleQuality: 7,
    isPulsing: false,
  );

  static const RadialZoomBlurConfig presetFocusPunch = RadialZoomBlurConfig(
    isEnabled: true,
    mode: RadialZoomBlurMode.subtleFocusPunch,
    blurAmount: 0.25,
    centerX: 0.5,
    centerY: 0.5,
    rotationSpin: 0.0,
    sampleQuality: 5,
    isPulsing: false,
  );

  static const RadialZoomBlurConfig presetDizzyWhirlwind = RadialZoomBlurConfig(
    isEnabled: true,
    mode: RadialZoomBlurMode.dizzySpin,
    blurAmount: 0.55,
    centerX: 0.5,
    centerY: 0.5,
    rotationSpin: 35.0,
    sampleQuality: 8,
    isPulsing: true,
  );

  RadialZoomBlurConfig copyWith({
    bool? isEnabled,
    RadialZoomBlurMode? mode,
    double? blurAmount,
    double? centerX,
    double? centerY,
    double? rotationSpin,
    int? sampleQuality,
    bool? isPulsing,
  }) {
    return RadialZoomBlurConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      blurAmount: blurAmount ?? this.blurAmount,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      rotationSpin: rotationSpin ?? this.rotationSpin,
      sampleQuality: sampleQuality ?? this.sampleQuality,
      isPulsing: isPulsing ?? this.isPulsing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'blurAmount': blurAmount,
      'centerX': centerX,
      'centerY': centerY,
      'rotationSpin': rotationSpin,
      'sampleQuality': sampleQuality,
      'isPulsing': isPulsing,
    };
  }

  factory RadialZoomBlurConfig.fromJson(Map<String, dynamic> json) {
    return RadialZoomBlurConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: RadialZoomBlurMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => RadialZoomBlurMode.actionImpactZoom,
      ),
      blurAmount: (json['blurAmount'] as num?)?.toDouble() ?? 0.4,
      centerX: (json['centerX'] as num?)?.toDouble() ?? 0.5,
      centerY: (json['centerY'] as num?)?.toDouble() ?? 0.5,
      rotationSpin: (json['rotationSpin'] as num?)?.toDouble() ?? 0.0,
      sampleQuality: (json['sampleQuality'] as num?)?.toInt() ?? 6,
      isPulsing: json['isPulsing'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        blurAmount,
        centerX,
        centerY,
        rotationSpin,
        sampleQuality,
        isPulsing,
      ];
}
