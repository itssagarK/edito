import 'package:equatable/equatable.dart';

enum FreezeAccentStyle {
  none,
  monochrome,
  actionGrit,
  warmSunset,
  neonInvert,
}

extension FreezeAccentStyleExtension on FreezeAccentStyle {
  String get label {
    switch (this) {
      case FreezeAccentStyle.none:
        return 'Standard Freeze';
      case FreezeAccentStyle.monochrome:
        return 'B&W Dramatic';
      case FreezeAccentStyle.actionGrit:
        return 'High-Contrast Action';
      case FreezeAccentStyle.warmSunset:
        return 'Golden Sunset';
      case FreezeAccentStyle.neonInvert:
        return 'Cyber Neon Burst';
    }
  }

  String get description {
    switch (this) {
      case FreezeAccentStyle.none:
        return 'Clean motion hold with camera zoom';
      case FreezeAccentStyle.monochrome:
        return 'Black and white desaturation for intense moments';
      case FreezeAccentStyle.actionGrit:
        return 'Punchy contrast grit for athletic and combat climaxes';
      case FreezeAccentStyle.warmSunset:
        return 'Warm emotional glow accentuating the climax';
      case FreezeAccentStyle.neonInvert:
        return 'High-voltage chromatic pop for music beats';
    }
  }
}

class FreezeClimaxConfig extends Equatable {
  final int freezeDurationMs;       // 200ms to 5000ms (default 1500ms)
  final double zoomScale;           // 1.0 to 1.8 (default 1.25)
  final bool flashAccent;           // Shutter flash at cutpoint
  final FreezeAccentStyle accentStyle;
  final bool muteAudioDuringFreeze;

  const FreezeClimaxConfig({
    this.freezeDurationMs = 1500,
    this.zoomScale = 1.25,
    this.flashAccent = true,
    this.accentStyle = FreezeAccentStyle.actionGrit,
    this.muteAudioDuringFreeze = true,
  });

  FreezeClimaxConfig copyWith({
    int? freezeDurationMs,
    double? zoomScale,
    bool? flashAccent,
    FreezeAccentStyle? accentStyle,
    bool? muteAudioDuringFreeze,
  }) {
    return FreezeClimaxConfig(
      freezeDurationMs: freezeDurationMs ?? this.freezeDurationMs,
      zoomScale: zoomScale ?? this.zoomScale,
      flashAccent: flashAccent ?? this.flashAccent,
      accentStyle: accentStyle ?? this.accentStyle,
      muteAudioDuringFreeze: muteAudioDuringFreeze ?? this.muteAudioDuringFreeze,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'freezeDurationMs': freezeDurationMs,
      'zoomScale': zoomScale,
      'flashAccent': flashAccent,
      'accentStyle': accentStyle.name,
      'muteAudioDuringFreeze': muteAudioDuringFreeze,
    };
  }

  factory FreezeClimaxConfig.fromJson(Map<String, dynamic> json) {
    return FreezeClimaxConfig(
      freezeDurationMs: json['freezeDurationMs'] as int? ?? 1500,
      zoomScale: (json['zoomScale'] as num?)?.toDouble() ?? 1.25,
      flashAccent: json['flashAccent'] as bool? ?? true,
      accentStyle: FreezeAccentStyle.values.firstWhere(
        (e) => e.name == json['accentStyle'],
        orElse: () => FreezeAccentStyle.actionGrit,
      ),
      muteAudioDuringFreeze: json['muteAudioDuringFreeze'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        freezeDurationMs,
        zoomScale,
        flashAccent,
        accentStyle,
        muteAudioDuringFreeze,
      ];
}
