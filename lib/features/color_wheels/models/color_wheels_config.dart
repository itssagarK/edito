import 'package:equatable/equatable.dart';
import 'wheel_channel_value.dart';

enum ColorWheelsMode {
  primary, // Lift, Gamma, Gain, Offset with LumaMix
  log, // Shadow, Midtone, Highlight, Offset with Range Crossover Splitting
}

extension ColorWheelsModeExtension on ColorWheelsMode {
  String get label {
    switch (this) {
      case ColorWheelsMode.primary:
        return 'Primary Wheels';
      case ColorWheelsMode.log:
        return 'Log Wheels';
    }
  }

  String get description {
    switch (this) {
      case ColorWheelsMode.primary:
        return 'Lift, Gamma, Gain & Offset with LumaMix luminance preservation';
      case ColorWheelsMode.log:
        return 'Logarithmic Shadow, Midtone & Highlight wheels with range crossover splitting';
    }
  }
}

enum ColorWheelsPreset {
  none,
  blockbusterTealOrange,
  vintageKodakWarm,
  moodyCyberpunk,
  goldenHour,
  bleachBypass,
  cleanCommercial,
}

extension ColorWheelsPresetExtension on ColorWheelsPreset {
  String get label {
    switch (this) {
      case ColorWheelsPreset.none:
        return 'Neutral (Default)';
      case ColorWheelsPreset.blockbusterTealOrange:
        return 'Blockbuster Teal & Orange';
      case ColorWheelsPreset.vintageKodakWarm:
        return 'Vintage Kodak 500T';
      case ColorWheelsPreset.moodyCyberpunk:
        return 'Moody Cyberpunk Neon';
      case ColorWheelsPreset.goldenHour:
        return 'Golden Hour Sunset';
      case ColorWheelsPreset.bleachBypass:
        return 'Bleach Bypass Silver';
      case ColorWheelsPreset.cleanCommercial:
        return 'Commercial Clean Pop';
    }
  }

  String get description {
    switch (this) {
      case ColorWheelsPreset.none:
        return 'Reset wheels to pristine neutral state';
      case ColorWheelsPreset.blockbusterTealOrange:
        return 'Teal shadows & warm orange skin highlights';
      case ColorWheelsPreset.vintageKodakWarm:
        return 'Warm amber highlights & organic deep greens';
      case ColorWheelsPreset.moodyCyberpunk:
        return 'Electric cyan shadows & saturated magenta highlights';
      case ColorWheelsPreset.goldenHour:
        return 'Sunlit amber midtones & soft golden glow';
      case ColorWheelsPreset.bleachBypass:
        return 'High contrast, desaturated midtones & cold shadows';
      case ColorWheelsPreset.cleanCommercial:
        return 'Vibrant clean neutral contrast with elevated speculars';
    }
  }
}

/// CapCut Pro Primary Color Wheels Configuration (Lift, Gamma, Gain, Offset with LumaMix).
class PrimaryWheelConfig extends Equatable {
  final WheelChannelValue lift; // Shadows & Black Pedestal
  final WheelChannelValue gamma; // Midtones & Natural Subject Skin
  final WheelChannelValue gain; // Highlights & Specular Roll-off
  final WheelChannelValue offset; // Master Global Pedestal
  final double lumaMix; // Luminance preservation 0.0 to 1.0 (default 0.5)

  const PrimaryWheelConfig({
    this.lift = const WheelChannelValue(),
    this.gamma = const WheelChannelValue(),
    this.gain = const WheelChannelValue(),
    this.offset = const WheelChannelValue(),
    this.lumaMix = 0.50,
  });

  bool get isDefault =>
      lift.isDefault &&
      gamma.isDefault &&
      gain.isDefault &&
      offset.isDefault &&
      (lumaMix - 0.50).abs() < 0.001;

  PrimaryWheelConfig copyWith({
    WheelChannelValue? lift,
    WheelChannelValue? gamma,
    WheelChannelValue? gain,
    WheelChannelValue? offset,
    double? lumaMix,
  }) {
    return PrimaryWheelConfig(
      lift: lift ?? this.lift,
      gamma: gamma ?? this.gamma,
      gain: gain ?? this.gain,
      offset: offset ?? this.offset,
      lumaMix: lumaMix ?? this.lumaMix,
    );
  }

  Map<String, dynamic> toJson() => {
        'lift': lift.toJson(),
        'gamma': gamma.toJson(),
        'gain': gain.toJson(),
        'offset': offset.toJson(),
        'lumaMix': lumaMix,
      };

  factory PrimaryWheelConfig.fromJson(Map<String, dynamic> json) => PrimaryWheelConfig(
        lift: json['lift'] != null
            ? WheelChannelValue.fromJson(json['lift'] as Map<String, dynamic>)
            : const WheelChannelValue(),
        gamma: json['gamma'] != null
            ? WheelChannelValue.fromJson(json['gamma'] as Map<String, dynamic>)
            : const WheelChannelValue(),
        gain: json['gain'] != null
            ? WheelChannelValue.fromJson(json['gain'] as Map<String, dynamic>)
            : const WheelChannelValue(),
        offset: json['offset'] != null
            ? WheelChannelValue.fromJson(json['offset'] as Map<String, dynamic>)
            : const WheelChannelValue(),
        lumaMix: (json['lumaMix'] as num?)?.toDouble() ?? 0.50,
      );

  @override
  List<Object?> get props => [lift, gamma, gain, offset, lumaMix];
}

/// CapCut Pro Log Color Wheels Configuration (Shadow, Midtone, Highlight, Offset with Range Crossover Splitting).
class LogWheelConfig extends Equatable {
  final WheelChannelValue shadow; // Log Shadow wheel
  final WheelChannelValue midtone; // Log Midtone wheel
  final WheelChannelValue highlight; // Log Highlight wheel
  final WheelChannelValue offset; // Log Master Offset wheel
  final double lowRange; // RugDown in shader: Low-range crossover threshold (0.1 to 0.5, default 0.33)
  final double highRange; // RugUP in shader: High-range crossover threshold (0.5 to 0.9, default 0.66)

  const LogWheelConfig({
    this.shadow = const WheelChannelValue(),
    this.midtone = const WheelChannelValue(),
    this.highlight = const WheelChannelValue(),
    this.offset = const WheelChannelValue(),
    this.lowRange = 0.33,
    this.highRange = 0.66,
  });

  bool get isDefault =>
      shadow.isDefault &&
      midtone.isDefault &&
      highlight.isDefault &&
      offset.isDefault &&
      (lowRange - 0.33).abs() < 0.001 &&
      (highRange - 0.66).abs() < 0.001;

  LogWheelConfig copyWith({
    WheelChannelValue? shadow,
    WheelChannelValue? midtone,
    WheelChannelValue? highlight,
    WheelChannelValue? offset,
    double? lowRange,
    double? highRange,
  }) {
    return LogWheelConfig(
      shadow: shadow ?? this.shadow,
      midtone: midtone ?? this.midtone,
      highlight: highlight ?? this.highlight,
      offset: offset ?? this.offset,
      lowRange: lowRange ?? this.lowRange,
      highRange: highRange ?? this.highRange,
    );
  }

  Map<String, dynamic> toJson() => {
        'shadow': shadow.toJson(),
        'midtone': midtone.toJson(),
        'highlight': highlight.toJson(),
        'offset': offset.toJson(),
        'lowRange': lowRange,
        'highRange': highRange,
      };

  factory LogWheelConfig.fromJson(Map<String, dynamic> json) => LogWheelConfig(
        shadow: json['shadow'] != null
            ? WheelChannelValue.fromJson(json['shadow'] as Map<String, dynamic>)
            : const WheelChannelValue(),
        midtone: json['midtone'] != null
            ? WheelChannelValue.fromJson(json['midtone'] as Map<String, dynamic>)
            : const WheelChannelValue(),
        highlight: json['highlight'] != null
            ? WheelChannelValue.fromJson(json['highlight'] as Map<String, dynamic>)
            : const WheelChannelValue(),
        offset: json['offset'] != null
            ? WheelChannelValue.fromJson(json['offset'] as Map<String, dynamic>)
            : const WheelChannelValue(),
        lowRange: (json['lowRange'] as num?)?.toDouble() ?? 0.33,
        highRange: (json['highRange'] as num?)?.toDouble() ?? 0.66,
      );

  @override
  List<Object?> get props => [shadow, midtone, highlight, offset, lowRange, highRange];
}

/// CapCut Pro Unified Color Wheels Configuration.
/// Directly extracted and modeled from CapCut PrimaryWheel.zip and LogWheel.zip native architectures.
class ColorWheelsConfig extends Equatable {
  final bool isEnabled;
  final ColorWheelsMode mode;
  final PrimaryWheelConfig primary;
  final LogWheelConfig log;
  final double masterIntensity; // 0.0 to 1.0

  const ColorWheelsConfig({
    this.isEnabled = false,
    this.mode = ColorWheelsMode.primary,
    this.primary = const PrimaryWheelConfig(),
    this.log = const LogWheelConfig(),
    this.masterIntensity = 1.0,
  });

  /// True if color wheels grading is actively modifying color signals.
  bool get isActive {
    if (!isEnabled || masterIntensity < 0.001) return false;
    if (mode == ColorWheelsMode.primary) {
      return !primary.isDefault;
    } else {
      return !log.isDefault;
    }
  }

  factory ColorWheelsConfig.fromPreset(ColorWheelsPreset preset) {
    switch (preset) {
      case ColorWheelsPreset.none:
        return const ColorWheelsConfig();

      case ColorWheelsPreset.blockbusterTealOrange:
        return ColorWheelsConfig(
          isEnabled: true,
          mode: ColorWheelsMode.primary,
          masterIntensity: 1.0,
          primary: PrimaryWheelConfig(
            lift: WheelChannelValue.fromHsl(angle: 195.0, saturation: 0.35, luminance: -0.05), // Deep Cyan Shadows
            gamma: WheelChannelValue.fromHsl(angle: 35.0, saturation: 0.18, luminance: 0.02), // Warm Amber Midtones
            gain: WheelChannelValue.fromHsl(angle: 45.0, saturation: 0.30, luminance: 0.06), // Sunlit Highlights
            offset: const WheelChannelValue(),
            lumaMix: 0.60,
          ),
          log: LogWheelConfig(
            shadow: WheelChannelValue.fromHsl(angle: 195.0, saturation: 0.40, luminance: -0.06),
            midtone: WheelChannelValue.fromHsl(angle: 35.0, saturation: 0.20, luminance: 0.02),
            highlight: WheelChannelValue.fromHsl(angle: 45.0, saturation: 0.32, luminance: 0.05),
            offset: const WheelChannelValue(),
          ),
        );

      case ColorWheelsPreset.vintageKodakWarm:
        return ColorWheelsConfig(
          isEnabled: true,
          mode: ColorWheelsMode.primary,
          masterIntensity: 0.90,
          primary: PrimaryWheelConfig(
            lift: WheelChannelValue.fromHsl(angle: 140.0, saturation: 0.15, luminance: 0.04), // Organic Green Shadow Pedestal
            gamma: WheelChannelValue.fromHsl(angle: 40.0, saturation: 0.25, luminance: 0.03), // Warm Retro Mids
            gain: WheelChannelValue.fromHsl(angle: 50.0, saturation: 0.35, luminance: -0.02), // Golden Kodak 500T Roll-off
            offset: WheelChannelValue.fromHsl(angle: 45.0, saturation: 0.08, luminance: 0.02),
            lumaMix: 0.45,
          ),
        );

      case ColorWheelsPreset.moodyCyberpunk:
        return ColorWheelsConfig(
          isEnabled: true,
          mode: ColorWheelsMode.primary,
          masterIntensity: 1.0,
          primary: PrimaryWheelConfig(
            lift: WheelChannelValue.fromHsl(angle: 215.0, saturation: 0.45, luminance: -0.08), // Cold Neon Blue Shadows
            gamma: WheelChannelValue.fromHsl(angle: 285.0, saturation: 0.25, luminance: 0.0), // Purple Transition
            gain: WheelChannelValue.fromHsl(angle: 325.0, saturation: 0.45, luminance: 0.08), // Vivid Magenta Highlights
            offset: const WheelChannelValue(),
            lumaMix: 0.50,
          ),
        );

      case ColorWheelsPreset.goldenHour:
        return ColorWheelsConfig(
          isEnabled: true,
          mode: ColorWheelsMode.primary,
          masterIntensity: 0.95,
          primary: PrimaryWheelConfig(
            lift: WheelChannelValue.fromHsl(angle: 220.0, saturation: 0.12, luminance: -0.02),
            gamma: WheelChannelValue.fromHsl(angle: 35.0, saturation: 0.32, luminance: 0.04),
            gain: WheelChannelValue.fromHsl(angle: 42.0, saturation: 0.42, luminance: 0.10),
            offset: const WheelChannelValue(),
            lumaMix: 0.55,
          ),
        );

      case ColorWheelsPreset.bleachBypass:
        return ColorWheelsConfig(
          isEnabled: true,
          mode: ColorWheelsMode.log,
          masterIntensity: 1.0,
          log: LogWheelConfig(
            shadow: WheelChannelValue.fromHsl(angle: 200.0, saturation: 0.30, luminance: -0.12),
            midtone: WheelChannelValue.fromHsl(angle: 180.0, saturation: 0.08, luminance: 0.0),
            highlight: WheelChannelValue.fromHsl(angle: 60.0, saturation: 0.18, luminance: 0.10),
            offset: const WheelChannelValue(),
            lowRange: 0.28,
            highRange: 0.72,
          ),
        );

      case ColorWheelsPreset.cleanCommercial:
        return ColorWheelsConfig(
          isEnabled: true,
          mode: ColorWheelsMode.primary,
          masterIntensity: 0.85,
          primary: PrimaryWheelConfig(
            lift: WheelChannelValue.fromHsl(angle: 210.0, saturation: 0.08, luminance: -0.04),
            gamma: WheelChannelValue.fromHsl(angle: 45.0, saturation: 0.12, luminance: 0.02),
            gain: WheelChannelValue.fromHsl(angle: 50.0, saturation: 0.18, luminance: 0.05),
            offset: const WheelChannelValue(),
            lumaMix: 0.70,
          ),
        );
    }
  }

  ColorWheelsConfig copyWith({
    bool? isEnabled,
    ColorWheelsMode? mode,
    PrimaryWheelConfig? primary,
    LogWheelConfig? log,
    double? masterIntensity,
  }) {
    return ColorWheelsConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      primary: primary ?? this.primary,
      log: log ?? this.log,
      masterIntensity: masterIntensity ?? this.masterIntensity,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'mode': mode.name,
        'primary': primary.toJson(),
        'log': log.toJson(),
        'masterIntensity': masterIntensity,
      };

  factory ColorWheelsConfig.fromJson(Map<String, dynamic> json) => ColorWheelsConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        mode: json['mode'] != null
            ? ColorWheelsMode.values.firstWhere(
                (m) => m.name == json['mode'],
                orElse: () => ColorWheelsMode.primary,
              )
            : ColorWheelsMode.primary,
        primary: json['primary'] != null
            ? PrimaryWheelConfig.fromJson(json['primary'] as Map<String, dynamic>)
            : const PrimaryWheelConfig(),
        log: json['log'] != null
            ? LogWheelConfig.fromJson(json['log'] as Map<String, dynamic>)
            : const LogWheelConfig(),
        masterIntensity: (json['masterIntensity'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  List<Object?> get props => [isEnabled, mode, primary, log, masterIntensity];
}
