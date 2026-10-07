import 'package:equatable/equatable.dart';

/// Preset bitcrushing, sample-rate reduction, and hardware lo-fi profiles.
enum BitcrusherMode {
  nesChiptune8Bit,
  gameBoyLofi,
  arcade16Bit,
  walkieTalkieRadio,
  extremeDecimator;

  String get displayName {
    switch (this) {
      case BitcrusherMode.nesChiptune8Bit:
        return 'NES 8-Bit Chiptune';
      case BitcrusherMode.gameBoyLofi:
        return 'Game Boy DMG Lo-Fi';
      case BitcrusherMode.arcade16Bit:
        return '16-Bit Arcade Punch';
      case BitcrusherMode.walkieTalkieRadio:
        return 'Walkie-Talkie Radio';
      case BitcrusherMode.extremeDecimator:
        return 'Extreme Decimator';
    }
  }

  String get description {
    switch (this) {
      case BitcrusherMode.nesChiptune8Bit:
        return 'Classic 8-bit Nintendo console crunchy square-wave grit & DAC quantize';
      case BitcrusherMode.gameBoyLofi:
        return 'Dot-matrix 4-bit crunchy portable lo-fi audio texture';
      case BitcrusherMode.arcade16Bit:
        return 'Sega Genesis & SNES arcade cabinet punchy 16-bit crunch';
      case BitcrusherMode.walkieTalkieRadio:
        return 'Severe military radio transmitter bandpass & downsampling';
      case BitcrusherMode.extremeDecimator:
        return 'Harsh digital starvation and radical 2-bit decimation glitch';
    }
  }
}

/// Configuration for 8-bit chiptune bitcrushing and sample rate decimation audio DSP.
class BitcrusherConfig extends Equatable {
  final bool isEnabled;
  final BitcrusherMode mode;
  final double sampleRateKhz; // 3.0 to 22.0 kHz (Nyquist downsample rate)
  final int bitDepth; // 2 to 12 bits (quantization resolution)
  final double drive; // 0.0 to 1.0 (pre-gain saturation overdrive)
  final double mix; // 0.0 to 1.0 (wet/dry blend ratio)

  const BitcrusherConfig({
    this.isEnabled = false,
    this.mode = BitcrusherMode.nesChiptune8Bit,
    this.sampleRateKhz = 8.0,
    this.bitDepth = 8,
    this.drive = 0.25,
    this.mix = 1.0,
  });

  bool get isActive => isEnabled && mix > 0.01;

  // Curated presets
  static const BitcrusherConfig retroNesConsole = BitcrusherConfig(
    isEnabled: true,
    mode: BitcrusherMode.nesChiptune8Bit,
    sampleRateKhz: 8.0,
    bitDepth: 8,
    drive: 0.25,
    mix: 1.0,
  );

  static const BitcrusherConfig dmgGameBoy = BitcrusherConfig(
    isEnabled: true,
    mode: BitcrusherMode.gameBoyLofi,
    sampleRateKhz: 5.5,
    bitDepth: 4,
    drive: 0.35,
    mix: 1.0,
  );

  static const BitcrusherConfig arcadeCabinet = BitcrusherConfig(
    isEnabled: true,
    mode: BitcrusherMode.arcade16Bit,
    sampleRateKhz: 16.0,
    bitDepth: 10,
    drive: 0.20,
    mix: 0.90,
  );

  static const BitcrusherConfig tacticalRadio = BitcrusherConfig(
    isEnabled: true,
    mode: BitcrusherMode.walkieTalkieRadio,
    sampleRateKhz: 4.0,
    bitDepth: 6,
    drive: 0.40,
    mix: 1.0,
  );

  static const BitcrusherConfig bitStarvedGlitch = BitcrusherConfig(
    isEnabled: true,
    mode: BitcrusherMode.extremeDecimator,
    sampleRateKhz: 3.0,
    bitDepth: 2,
    drive: 0.60,
    mix: 1.0,
  );

  BitcrusherConfig copyWith({
    bool? isEnabled,
    BitcrusherMode? mode,
    double? sampleRateKhz,
    int? bitDepth,
    double? drive,
    double? mix,
  }) {
    return BitcrusherConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      sampleRateKhz: sampleRateKhz ?? this.sampleRateKhz,
      bitDepth: bitDepth ?? this.bitDepth,
      drive: drive ?? this.drive,
      mix: mix ?? this.mix,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'sampleRateKhz': sampleRateKhz,
      'bitDepth': bitDepth,
      'drive': drive,
      'mix': mix,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory BitcrusherConfig.fromMap(Map<String, dynamic> map) {
    return BitcrusherConfig(
      isEnabled: map['isEnabled'] as bool? ?? false,
      mode: BitcrusherMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => BitcrusherMode.nesChiptune8Bit,
      ),
      sampleRateKhz: (map['sampleRateKhz'] as num?)?.toDouble() ?? 8.0,
      bitDepth: (map['bitDepth'] as num?)?.toInt() ?? 8,
      drive: (map['drive'] as num?)?.toDouble() ?? 0.25,
      mix: (map['mix'] as num?)?.toDouble() ?? 1.0,
    );
  }

  factory BitcrusherConfig.fromJson(Map<String, dynamic> json) =>
      BitcrusherConfig.fromMap(json);

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        sampleRateKhz,
        bitDepth,
        drive,
        mix,
      ];
}
