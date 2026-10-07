import 'package:equatable/equatable.dart';

enum TapeCassetteEra {
  walkman1985,      // Classic 1980s personal portable cassette
  microcassette,    // Dictaphone lo-fi micro-tape warmth
  vhsHiFi,          // Analog VHS stereo hi-fi audio track
  masterReel15ips,  // Studio 15 IPS reel-to-reel saturation
  wornThriftTape,   // Warped, heat-damaged vintage thrift tape
}

extension TapeCassetteEraExtension on TapeCassetteEra {
  String get label {
    switch (this) {
      case TapeCassetteEra.walkman1985:
        return 'Walkman (1985)';
      case TapeCassetteEra.microcassette:
        return 'Microcassette Dictaphone';
      case TapeCassetteEra.vhsHiFi:
        return 'VHS Hi-Fi Audio (1992)';
      case TapeCassetteEra.masterReel15ips:
        return 'Studio Reel-to-Reel 15 IPS';
      case TapeCassetteEra.wornThriftTape:
        return 'Worn Thrift Cassette';
    }
  }

  String get iconEmoji {
    switch (this) {
      case TapeCassetteEra.walkman1985:
        return '📼';
      case TapeCassetteEra.microcassette:
        return '🎙️';
      case TapeCassetteEra.vhsHiFi:
        return '📺';
      case TapeCassetteEra.masterReel15ips:
        return '🎛️';
      case TapeCassetteEra.wornThriftTape:
        return '📻';
    }
  }
}

class TapeCassetteConfig extends Equatable {
  final bool isEnabled;
  final TapeCassetteEra era;
  final double wowDepth;         // 0.0 to 1.0 (slow reel pitch drift ~0.3-1.8Hz, default 0.35)
  final double wowRateHz;        // 0.2 to 2.0 Hz (default 0.8 Hz)
  final double flutterDepth;     // 0.0 to 1.0 (rapid capstan vibration ~5-20Hz, default 0.25)
  final double flutterRateHz;    // 5.0 to 20.0 Hz (default 9.0 Hz)
  final double tapeWarmth;       // 0.0 to 1.0 (head saturation & HF roll-off, default 0.50)
  final double hissLevel;        // 0.0 to 0.30 (analog noise floor, default 0.06)

  const TapeCassetteConfig({
    this.isEnabled = false,
    this.era = TapeCassetteEra.walkman1985,
    this.wowDepth = 0.35,
    this.wowRateHz = 0.8,
    this.flutterDepth = 0.25,
    this.flutterRateHz = 9.0,
    this.tapeWarmth = 0.50,
    this.hissLevel = 0.06,
  });

  bool get isActive => isEnabled && (wowDepth > 0.02 || flutterDepth > 0.02 || tapeWarmth > 0.05);

  // Preset Configurations
  static const walkman1985 = TapeCassetteConfig(
    isEnabled: true,
    era: TapeCassetteEra.walkman1985,
    wowDepth: 0.35,
    wowRateHz: 0.8,
    flutterDepth: 0.25,
    flutterRateHz: 9.0,
    tapeWarmth: 0.55,
    hissLevel: 0.08,
  );

  static const microcassette = TapeCassetteConfig(
    isEnabled: true,
    era: TapeCassetteEra.microcassette,
    wowDepth: 0.65,
    wowRateHz: 1.2,
    flutterDepth: 0.55,
    flutterRateHz: 14.0,
    tapeWarmth: 0.80,
    hissLevel: 0.16,
  );

  static const vhsHiFi = TapeCassetteConfig(
    isEnabled: true,
    era: TapeCassetteEra.vhsHiFi,
    wowDepth: 0.15,
    wowRateHz: 0.5,
    flutterDepth: 0.10,
    flutterRateHz: 7.0,
    tapeWarmth: 0.35,
    hissLevel: 0.04,
  );

  static const masterReel15ips = TapeCassetteConfig(
    isEnabled: true,
    era: TapeCassetteEra.masterReel15ips,
    wowDepth: 0.08,
    wowRateHz: 0.4,
    flutterDepth: 0.05,
    flutterRateHz: 6.0,
    tapeWarmth: 0.45,
    hissLevel: 0.02,
  );

  static const wornThriftTape = TapeCassetteConfig(
    isEnabled: true,
    era: TapeCassetteEra.wornThriftTape,
    wowDepth: 0.80,
    wowRateHz: 0.9,
    flutterDepth: 0.70,
    flutterRateHz: 12.0,
    tapeWarmth: 0.75,
    hissLevel: 0.20,
  );

  TapeCassetteConfig copyWith({
    bool? isEnabled,
    TapeCassetteEra? era,
    double? wowDepth,
    double? wowRateHz,
    double? flutterDepth,
    double? flutterRateHz,
    double? tapeWarmth,
    double? hissLevel,
  }) {
    return TapeCassetteConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      era: era ?? this.era,
      wowDepth: wowDepth ?? this.wowDepth,
      wowRateHz: wowRateHz ?? this.wowRateHz,
      flutterDepth: flutterDepth ?? this.flutterDepth,
      flutterRateHz: flutterRateHz ?? this.flutterRateHz,
      tapeWarmth: tapeWarmth ?? this.tapeWarmth,
      hissLevel: hissLevel ?? this.hissLevel,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'era': era.name,
        'wowDepth': wowDepth,
        'wowRateHz': wowRateHz,
        'flutterDepth': flutterDepth,
        'flutterRateHz': flutterRateHz,
        'tapeWarmth': tapeWarmth,
        'hissLevel': hissLevel,
      };

  factory TapeCassetteConfig.fromJson(Map<String, dynamic> json) => TapeCassetteConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        era: TapeCassetteEra.values.firstWhere(
          (e) => e.name == json['era'],
          orElse: () => TapeCassetteEra.walkman1985,
        ),
        wowDepth: (json['wowDepth'] as num?)?.toDouble() ?? 0.35,
        wowRateHz: (json['wowRateHz'] as num?)?.toDouble() ?? 0.8,
        flutterDepth: (json['flutterDepth'] as num?)?.toDouble() ?? 0.25,
        flutterRateHz: (json['flutterRateHz'] as num?)?.toDouble() ?? 9.0,
        tapeWarmth: (json['tapeWarmth'] as num?)?.toDouble() ?? 0.50,
        hissLevel: (json['hissLevel'] as num?)?.toDouble() ?? 0.06,
      );

  @override
  List<Object?> get props => [
        isEnabled,
        era,
        wowDepth,
        wowRateHz,
        flutterDepth,
        flutterRateHz,
        tapeWarmth,
        hissLevel,
      ];
}
