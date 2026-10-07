import 'package:equatable/equatable.dart';

enum ReverbRoomType {
  studioBooth,   // Tight, dry reflections, ~250ms decay
  smallRoom,     // Warm living room acoustics, ~650ms decay
  vocalHall,     // Spacious, silky vocal ballad hall, ~1600ms decay
  cathedral,     // Majestic, cavernous sacred stone sanctuary, ~3500ms decay
  cyberCavern,   // Dark, resonant subterranean cavern, ~2800ms decay
  plateReverb,   // Bright vintage 1970s EMT steel plate, ~1200ms decay
  stadium,       // Colossal open-air arena echo, ~2200ms decay
}

extension ReverbRoomTypeExtension on ReverbRoomType {
  String get label {
    switch (this) {
      case ReverbRoomType.studioBooth:
        return 'Studio Vocal Booth';
      case ReverbRoomType.smallRoom:
        return 'Warm Living Room';
      case ReverbRoomType.vocalHall:
        return 'Concert Hall';
      case ReverbRoomType.cathedral:
        return 'Gothic Cathedral';
      case ReverbRoomType.cyberCavern:
        return 'Cyber Cavern';
      case ReverbRoomType.plateReverb:
        return 'Vintage EMT Plate';
      case ReverbRoomType.stadium:
        return 'Open Stadium';
    }
  }

  String get iconEmoji {
    switch (this) {
      case ReverbRoomType.studioBooth:
        return '🎙️';
      case ReverbRoomType.smallRoom:
        return '🏠';
      case ReverbRoomType.vocalHall:
        return '🏛️';
      case ReverbRoomType.cathedral:
        return '⛪';
      case ReverbRoomType.cyberCavern:
        return '🌌';
      case ReverbRoomType.plateReverb:
        return '💿';
      case ReverbRoomType.stadium:
        return '🏟️';
    }
  }

  int get defaultDecayMs {
    switch (this) {
      case ReverbRoomType.studioBooth:
        return 280;
      case ReverbRoomType.smallRoom:
        return 650;
      case ReverbRoomType.vocalHall:
        return 1600;
      case ReverbRoomType.cathedral:
        return 3400;
      case ReverbRoomType.cyberCavern:
        return 2600;
      case ReverbRoomType.plateReverb:
        return 1200;
      case ReverbRoomType.stadium:
        return 2200;
    }
  }

  double get defaultDamping {
    switch (this) {
      case ReverbRoomType.studioBooth:
        return 0.70;
      case ReverbRoomType.smallRoom:
        return 0.55;
      case ReverbRoomType.vocalHall:
        return 0.40;
      case ReverbRoomType.cathedral:
        return 0.25;
      case ReverbRoomType.cyberCavern:
        return 0.45;
      case ReverbRoomType.plateReverb:
        return 0.15; // Bright steel
      case ReverbRoomType.stadium:
        return 0.35;
    }
  }
}

class ReverbChamberConfig extends Equatable {
  final bool isEnabled;
  final ReverbRoomType roomType;
  final double wetDryMix;        // 0.0 (100% dry) to 1.0 (100% wet), default 0.35
  final int decayTimeMs;         // 100 to 5000 ms
  final double damping;          // 0.0 (bright metallic) to 1.0 (dark warm wool), default 0.40
  final double stereoWidth;      // 0.0 (mono) to 1.0 (wide stereo 180°), default 0.70
  final double preDelayMs;       // 0 to 100 ms, default 20

  const ReverbChamberConfig({
    this.isEnabled = false,
    this.roomType = ReverbRoomType.vocalHall,
    this.wetDryMix = 0.35,
    this.decayTimeMs = 1600,
    this.damping = 0.40,
    this.stereoWidth = 0.70,
    this.preDelayMs = 20.0,
  });

  bool get isActive => isEnabled && wetDryMix > 0.02;

  // Preset Configurations
  static const studioBooth = ReverbChamberConfig(
    isEnabled: true,
    roomType: ReverbRoomType.studioBooth,
    wetDryMix: 0.22,
    decayTimeMs: 280,
    damping: 0.70,
    stereoWidth: 0.45,
    preDelayMs: 10.0,
  );

  static const smallRoom = ReverbChamberConfig(
    isEnabled: true,
    roomType: ReverbRoomType.smallRoom,
    wetDryMix: 0.30,
    decayTimeMs: 650,
    damping: 0.55,
    stereoWidth: 0.60,
    preDelayMs: 15.0,
  );

  static const vocalHall = ReverbChamberConfig(
    isEnabled: true,
    roomType: ReverbRoomType.vocalHall,
    wetDryMix: 0.38,
    decayTimeMs: 1600,
    damping: 0.40,
    stereoWidth: 0.80,
    preDelayMs: 25.0,
  );

  static const cathedral = ReverbChamberConfig(
    isEnabled: true,
    roomType: ReverbRoomType.cathedral,
    wetDryMix: 0.55,
    decayTimeMs: 3400,
    damping: 0.25,
    stereoWidth: 0.95,
    preDelayMs: 45.0,
  );

  static const cyberCavern = ReverbChamberConfig(
    isEnabled: true,
    roomType: ReverbRoomType.cyberCavern,
    wetDryMix: 0.48,
    decayTimeMs: 2600,
    damping: 0.45,
    stereoWidth: 0.85,
    preDelayMs: 35.0,
  );

  static const plateReverb = ReverbChamberConfig(
    isEnabled: true,
    roomType: ReverbRoomType.plateReverb,
    wetDryMix: 0.35,
    decayTimeMs: 1200,
    damping: 0.15,
    stereoWidth: 0.75,
    preDelayMs: 12.0,
  );

  static const stadium = ReverbChamberConfig(
    isEnabled: true,
    roomType: ReverbRoomType.stadium,
    wetDryMix: 0.42,
    decayTimeMs: 2200,
    damping: 0.35,
    stereoWidth: 0.90,
    preDelayMs: 50.0,
  );

  ReverbChamberConfig copyWith({
    bool? isEnabled,
    ReverbRoomType? roomType,
    double? wetDryMix,
    int? decayTimeMs,
    double? damping,
    double? stereoWidth,
    double? preDelayMs,
  }) {
    return ReverbChamberConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      roomType: roomType ?? this.roomType,
      wetDryMix: wetDryMix ?? this.wetDryMix,
      decayTimeMs: decayTimeMs ?? this.decayTimeMs,
      damping: damping ?? this.damping,
      stereoWidth: stereoWidth ?? this.stereoWidth,
      preDelayMs: preDelayMs ?? this.preDelayMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'roomType': roomType.name,
        'wetDryMix': wetDryMix,
        'decayTimeMs': decayTimeMs,
        'damping': damping,
        'stereoWidth': stereoWidth,
        'preDelayMs': preDelayMs,
      };

  factory ReverbChamberConfig.fromJson(Map<String, dynamic> json) => ReverbChamberConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        roomType: ReverbRoomType.values.firstWhere(
          (e) => e.name == json['roomType'],
          orElse: () => ReverbRoomType.vocalHall,
        ),
        wetDryMix: (json['wetDryMix'] as num?)?.toDouble() ?? 0.35,
        decayTimeMs: (json['decayTimeMs'] as num?)?.toInt() ?? 1600,
        damping: (json['damping'] as num?)?.toDouble() ?? 0.40,
        stereoWidth: (json['stereoWidth'] as num?)?.toDouble() ?? 0.70,
        preDelayMs: (json['preDelayMs'] as num?)?.toDouble() ?? 20.0,
      );

  @override
  List<Object?> get props => [
        isEnabled,
        roomType,
        wetDryMix,
        decayTimeMs,
        damping,
        stereoWidth,
        preDelayMs,
      ];
}
