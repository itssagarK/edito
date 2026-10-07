import 'package:equatable/equatable.dart';

enum FlareTint {
  cinemaBlue,      // Iconic Hollywood Panavision anamorphic blue streak
  goldenAmber,     // Vintage anamorphic sunset / golden hour flare
  neonMagenta,     // Cyberpunk / synthwave neon magenta streak
  iceWhite,        // Crisp modern clean anamorphic flare
  emeraldMatrix,   // Tactical Sci-Fi emerald green streak
}

extension FlareTintExtension on FlareTint {
  String get label {
    switch (this) {
      case FlareTint.cinemaBlue:
        return 'Cinema Anamorphic Blue';
      case FlareTint.goldenAmber:
        return 'Vintage Golden Amber';
      case FlareTint.neonMagenta:
        return 'Cyberpunk Neon Magenta';
      case FlareTint.iceWhite:
        return 'Crisp Modern Ice White';
      case FlareTint.emeraldMatrix:
        return 'Sci-Fi Emerald Matrix';
    }
  }

  int get colorHex {
    switch (this) {
      case FlareTint.cinemaBlue:
        return 0xFF00B4D8;
      case FlareTint.goldenAmber:
        return 0xFFFFB703;
      case FlareTint.neonMagenta:
        return 0xFFFF007F;
      case FlareTint.iceWhite:
        return 0xFFE0F7FA;
      case FlareTint.emeraldMatrix:
        return 0xFF00FF66;
    }
  }

  String get ffmpegMatrix {
    switch (this) {
      case FlareTint.cinemaBlue:
        return 'colorchannelmixer=rr=0.2:rg=0:rb=0:gr=0.3:gg=0.8:gb=0.2:br=0.1:bg=0.4:bb=1.3';
      case FlareTint.goldenAmber:
        return 'colorchannelmixer=rr=1.3:rg=0.6:rb=0:gr=0.2:gg=0.9:gb=0:br=0:bg=0:bb=0.2';
      case FlareTint.neonMagenta:
        return 'colorchannelmixer=rr=1.3:rg=0.1:rb=0.3:gr=0.1:gg=0.4:gb=0.2:br=0.5:bg=0.2:bb=1.2';
      case FlareTint.iceWhite:
        return 'colorchannelmixer=rr=1.0:rg=0:rb=0:gr=0:gg=1.0:gb=0:br=0:bg=0:bb=1.0';
      case FlareTint.emeraldMatrix:
        return 'colorchannelmixer=rr=0.1:rg=0:rb=0:gr=0.4:gg=1.3:gb=0.1:br=0:bg=0.2:bb=0.3';
    }
  }
}

class AnamorphicFlareConfig extends Equatable {
  final bool isEnabled;
  final FlareTint tint;
  final double streakLength;       // 1.0 to 10.0 (horizontal streak aspect multiplier, default 5.0)
  final double threshold;          // 0.60 to 0.98 (luminance trigger threshold, default 0.85)
  final int starburstSpikes;       // 0 (streak only), 4, 6, 8 points
  final double intensity;          // 0.0 to 1.0 (default 0.60)
  final double flareThickness;     // 1.0 to 8.0 (vertical bloom thickness, default 2.0)

  const AnamorphicFlareConfig({
    this.isEnabled = false,
    this.tint = FlareTint.cinemaBlue,
    this.streakLength = 5.0,
    this.threshold = 0.85,
    this.starburstSpikes = 0,
    this.intensity = 0.60,
    this.flareThickness = 2.0,
  });

  bool get isActive => isEnabled && intensity > 0.05;

  // Preset Configurations
  static const hollywoodBlue = AnamorphicFlareConfig(
    isEnabled: true,
    tint: FlareTint.cinemaBlue,
    streakLength: 6.5,
    threshold: 0.82,
    starburstSpikes: 0,
    intensity: 0.70,
    flareThickness: 2.0,
  );

  static const vintageGoldenHour = AnamorphicFlareConfig(
    isEnabled: true,
    tint: FlareTint.goldenAmber,
    streakLength: 4.5,
    threshold: 0.80,
    starburstSpikes: 4,
    intensity: 0.65,
    flareThickness: 3.0,
  );

  static const sciFiLaser = AnamorphicFlareConfig(
    isEnabled: true,
    tint: FlareTint.neonMagenta,
    streakLength: 8.5,
    threshold: 0.85,
    starburstSpikes: 6,
    intensity: 0.80,
    flareThickness: 1.8,
  );

  static const subtleCinema = AnamorphicFlareConfig(
    isEnabled: true,
    tint: FlareTint.cinemaBlue,
    streakLength: 3.5,
    threshold: 0.88,
    starburstSpikes: 0,
    intensity: 0.40,
    flareThickness: 1.5,
  );

  static const starburstGlint = AnamorphicFlareConfig(
    isEnabled: true,
    tint: FlareTint.iceWhite,
    streakLength: 2.5,
    threshold: 0.78,
    starburstSpikes: 8,
    intensity: 0.85,
    flareThickness: 2.5,
  );

  AnamorphicFlareConfig copyWith({
    bool? isEnabled,
    FlareTint? tint,
    double? streakLength,
    double? threshold,
    int? starburstSpikes,
    double? intensity,
    double? flareThickness,
  }) {
    return AnamorphicFlareConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      tint: tint ?? this.tint,
      streakLength: streakLength ?? this.streakLength,
      threshold: threshold ?? this.threshold,
      starburstSpikes: starburstSpikes ?? this.starburstSpikes,
      intensity: intensity ?? this.intensity,
      flareThickness: flareThickness ?? this.flareThickness,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'tint': tint.name,
        'streakLength': streakLength,
        'threshold': threshold,
        'starburstSpikes': starburstSpikes,
        'intensity': intensity,
        'flareThickness': flareThickness,
      };

  factory AnamorphicFlareConfig.fromJson(Map<String, dynamic> json) => AnamorphicFlareConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        tint: FlareTint.values.firstWhere(
          (e) => e.name == json['tint'],
          orElse: () => FlareTint.cinemaBlue,
        ),
        streakLength: (json['streakLength'] as num?)?.toDouble() ?? 5.0,
        threshold: (json['threshold'] as num?)?.toDouble() ?? 0.85,
        starburstSpikes: (json['starburstSpikes'] as num?)?.toInt() ?? 0,
        intensity: (json['intensity'] as num?)?.toDouble() ?? 0.60,
        flareThickness: (json['flareThickness'] as num?)?.toDouble() ?? 2.0,
      );

  @override
  List<Object?> get props => [
        isEnabled,
        tint,
        streakLength,
        threshold,
        starburstSpikes,
        intensity,
        flareThickness,
      ];
}
