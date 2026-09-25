import 'package:equatable/equatable.dart';

/// CapCut Pro AI Color Match & Tone Palette Transfer Mode
enum ColorMatchMode {
  preset,
  timelineClip,
  custom,
}

extension ColorMatchModeExt on ColorMatchMode {
  String get label {
    switch (this) {
      case ColorMatchMode.preset:
        return 'Preset Palette';
      case ColorMatchMode.timelineClip:
        return 'Timeline Clip';
      case ColorMatchMode.custom:
        return 'Custom Match';
    }
  }
}

/// CapCut Pro Industry-Standard Cinematic Palette Presets
enum ColorPalettePreset {
  hollywoodTealOrange,
  moodyBleachBypass,
  kodachromeVintage,
  fujiClassicChrome,
  cyberpunkNeoTokyo,
  goldenHourSunset,
  cleanCommercial,
  monochromeMood,
}

extension ColorPalettePresetExt on ColorPalettePreset {
  String get label {
    switch (this) {
      case ColorPalettePreset.hollywoodTealOrange:
        return 'Teal & Orange';
      case ColorPalettePreset.moodyBleachBypass:
        return 'Bleach Bypass';
      case ColorPalettePreset.kodachromeVintage:
        return 'Kodachrome 64';
      case ColorPalettePreset.fujiClassicChrome:
        return 'Classic Chrome';
      case ColorPalettePreset.cyberpunkNeoTokyo:
        return 'Cyberpunk Neon';
      case ColorPalettePreset.goldenHourSunset:
        return 'Golden Hour';
      case ColorPalettePreset.cleanCommercial:
        return 'Commercial Pop';
      case ColorPalettePreset.monochromeMood:
        return 'Noir Film';
    }
  }

  String get description {
    switch (this) {
      case ColorPalettePreset.hollywoodTealOrange:
        return 'Blockbuster cine grade with cyan shadows & golden skin tones';
      case ColorPalettePreset.moodyBleachBypass:
        return 'High-contrast silver retention with desaturated gritty tone';
      case ColorPalettePreset.kodachromeVintage:
        return 'Analog 1970s warmth with rich sky blues and nostalgic reds';
      case ColorPalettePreset.fujiClassicChrome:
        return 'Subtle documentary realism with soft shadows and muted tones';
      case ColorPalettePreset.cyberpunkNeoTokyo:
        return 'Electric aesthetic with indigo shadows & magenta highlights';
      case ColorPalettePreset.goldenHourSunset:
        return 'Warm amber sunset glow with lifted shadows & honey tones';
      case ColorPalettePreset.cleanCommercial:
        return 'Crisp high-key contrast with pure whites and vibrant pop';
      case ColorPalettePreset.monochromeMood:
        return 'Fine-art silver tonal scale with punchy blacks & high clarity';
    }
  }

  /// 3 preview gradient swatches [Shadows, Midtones, Highlights]
  List<int> get previewColors {
    switch (this) {
      case ColorPalettePreset.hollywoodTealOrange:
        return [0xFF0B3C49, 0xFF726E60, 0xFFE08D3C];
      case ColorPalettePreset.moodyBleachBypass:
        return [0xFF1F2421, 0xFF656D67, 0xFFC9D1C8];
      case ColorPalettePreset.kodachromeVintage:
        return [0xFF3A2E1E, 0xFFB37D4E, 0xFFE8C882];
      case ColorPalettePreset.fujiClassicChrome:
        return [0xFF23302B, 0xFF6F7D75, 0xFFC2BAAE];
      case ColorPalettePreset.cyberpunkNeoTokyo:
        return [0xFF13093A, 0xFF00ADB5, 0xFFFF007F];
      case ColorPalettePreset.goldenHourSunset:
        return [0xFF361500, 0xFFB85D19, 0xFFFFB347];
      case ColorPalettePreset.cleanCommercial:
        return [0xFF1A1C20, 0xFF5C9EAD, 0xFFE9F1F7];
      case ColorPalettePreset.monochromeMood:
        return [0xFF111111, 0xFF777777, 0xFFEEEEEE];
    }
  }
}

/// CapCut Pro AI Color Match & Tone Palette Transfer Configuration
class ColorMatchConfig extends Equatable {
  final bool isEnabled;
  final ColorMatchMode mode;
  final ColorPalettePreset preset;
  final String? referenceClipId;
  final String? referenceClipName;
  final double intensity; // 0.0 to 1.0 (default: 0.85)
  final double luminanceWeight; // 0.0 to 1.0 (default: 0.80)
  final double colorSpread; // 0.0 to 1.0 (default: 0.75)
  final double saturationMatch; // 0.0 to 2.0 (default: 1.0)
  final bool preserveSkinTones; // Protect facial gamut from severe tint

  const ColorMatchConfig({
    this.isEnabled = false,
    this.mode = ColorMatchMode.preset,
    this.preset = ColorPalettePreset.hollywoodTealOrange,
    this.referenceClipId,
    this.referenceClipName,
    this.intensity = 0.85,
    this.luminanceWeight = 0.80,
    this.colorSpread = 0.75,
    this.saturationMatch = 1.0,
    this.preserveSkinTones = true,
  });

  /// Factory constructor to immediately create an active preset configuration
  factory ColorMatchConfig.fromPreset(ColorPalettePreset preset, {double intensity = 0.85}) {
    return ColorMatchConfig(
      isEnabled: true,
      mode: ColorMatchMode.preset,
      preset: preset,
      intensity: intensity,
    );
  }

  /// Factory constructor to match from a timeline clip
  factory ColorMatchConfig.fromClip({
    required String clipId,
    required String clipName,
    double intensity = 0.85,
  }) {
    return ColorMatchConfig(
      isEnabled: true,
      mode: ColorMatchMode.timelineClip,
      referenceClipId: clipId,
      referenceClipName: clipName,
      intensity: intensity,
    );
  }

  /// Real-time HUD status badge text
  String get badge {
    if (!isEnabled || intensity <= 0.0) return '';
    final percent = (intensity * 100).toInt();
    if (mode == ColorMatchMode.timelineClip) {
      final name = referenceClipName != null && referenceClipName!.isNotEmpty
          ? referenceClipName!
          : 'CLIP';
      return 'MATCH: $name $percent%';
    }
    return 'COLOR MATCH: ${preset.label.toUpperCase()} $percent%';
  }

  ColorMatchConfig copyWith({
    bool? isEnabled,
    ColorMatchMode? mode,
    ColorPalettePreset? preset,
    String? referenceClipId,
    String? referenceClipName,
    double? intensity,
    double? luminanceWeight,
    double? colorSpread,
    double? saturationMatch,
    bool? preserveSkinTones,
  }) {
    return ColorMatchConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      preset: preset ?? this.preset,
      referenceClipId: referenceClipId ?? this.referenceClipId,
      referenceClipName: referenceClipName ?? this.referenceClipName,
      intensity: intensity ?? this.intensity,
      luminanceWeight: luminanceWeight ?? this.luminanceWeight,
      colorSpread: colorSpread ?? this.colorSpread,
      saturationMatch: saturationMatch ?? this.saturationMatch,
      preserveSkinTones: preserveSkinTones ?? this.preserveSkinTones,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'mode': mode.name,
        'preset': preset.name,
        'referenceClipId': referenceClipId,
        'referenceClipName': referenceClipName,
        'intensity': intensity,
        'luminanceWeight': luminanceWeight,
        'colorSpread': colorSpread,
        'saturationMatch': saturationMatch,
        'preserveSkinTones': preserveSkinTones,
      };

  factory ColorMatchConfig.fromJson(Map<String, dynamic> json) {
    ColorMatchMode modeVal = ColorMatchMode.preset;
    if (json['mode'] != null) {
      modeVal = ColorMatchMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => ColorMatchMode.preset,
      );
    }

    ColorPalettePreset presetVal = ColorPalettePreset.hollywoodTealOrange;
    if (json['preset'] != null) {
      presetVal = ColorPalettePreset.values.firstWhere(
        (p) => p.name == json['preset'],
        orElse: () => ColorPalettePreset.hollywoodTealOrange,
      );
    }

    return ColorMatchConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: modeVal,
      preset: presetVal,
      referenceClipId: json['referenceClipId'] as String?,
      referenceClipName: json['referenceClipName'] as String?,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.85,
      luminanceWeight: (json['luminanceWeight'] as num?)?.toDouble() ?? 0.80,
      colorSpread: (json['colorSpread'] as num?)?.toDouble() ?? 0.75,
      saturationMatch: (json['saturationMatch'] as num?)?.toDouble() ?? 1.0,
      preserveSkinTones: json['preserveSkinTones'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        preset,
        referenceClipId,
        referenceClipName,
        intensity,
        luminanceWeight,
        colorSpread,
        saturationMatch,
        preserveSkinTones,
      ];
}
