import 'package:equatable/equatable.dart';

/// Musical rhythmic note divisions for micro-buffer stutter chopping.
enum StutterDivision {
  quarter,
  eighth,
  sixteenth,
  thirtySecond,
  triplet;

  String get displayName {
    switch (this) {
      case StutterDivision.quarter:
        return '1/4 Beat';
      case StutterDivision.eighth:
        return '1/8 Note';
      case StutterDivision.sixteenth:
        return '1/16 Fast Glitch';
      case StutterDivision.thirtySecond:
        return '1/32 Drill';
      case StutterDivision.triplet:
        return '1/8T Triplet';
    }
  }

  String get label {
    switch (this) {
      case StutterDivision.quarter:
        return '1/4';
      case StutterDivision.eighth:
        return '1/8';
      case StutterDivision.sixteenth:
        return '1/16';
      case StutterDivision.thirtySecond:
        return '1/32';
      case StutterDivision.triplet:
        return '1/8T';
    }
  }

  /// Multiplier relative to one beat (1.0 = 1 beat, 0.5 = 1/8 note, etc.)
  double get beatFraction {
    switch (this) {
      case StutterDivision.quarter:
        return 1.0;
      case StutterDivision.eighth:
        return 0.5;
      case StutterDivision.sixteenth:
        return 0.25;
      case StutterDivision.thirtySecond:
        return 0.125;
      case StutterDivision.triplet:
        return 0.333333;
    }
  }
}

/// Dynamic playback modes for buffer slice repetition and glitch rolls.
enum AudioStutterMode {
  straight,
  accelerando,
  pitchDrop,
  reverseEcho,
  granularCloud;

  String get displayName {
    switch (this) {
      case AudioStutterMode.straight:
        return 'Straight Beat Roll';
      case AudioStutterMode.accelerando:
        return 'Accelerando Drill Ramp';
      case AudioStutterMode.pitchDrop:
        return 'Tape Stop Pitch Drop';
      case AudioStutterMode.reverseEcho:
        return 'Ping-Pong Alternating';
      case AudioStutterMode.granularCloud:
        return 'Granular Glitch Cloud';
    }
  }

  String get description {
    switch (this) {
      case AudioStutterMode.straight:
        return 'Constant tempo micro-buffer slice repeating in sync with the musical grid';
      case AudioStutterMode.accelerando:
        return 'Rapidly shrinking buffer slices creating an intense machine-gun EDM build-up';
      case AudioStutterMode.pitchDrop:
        return 'Simulates vinyl turntable motor brake or analog tape decelerating during repeats';
      case AudioStutterMode.reverseEcho:
        return 'Alternating forward and backward buffer reflections creating ping-pong space';
      case AudioStutterMode.granularCloud:
        return 'Micro-grain randomized burst scattering stutter fragments across the stereo field';
    }
  }
}

/// Configuration for rhythmic audio stutter and glitch buffer beat repeater.
class AudioStutterConfig extends Equatable {
  final bool isEnabled;
  final StutterDivision division;
  final AudioStutterMode mode;
  final int repeats; // 1 to 8 repeated bursts
  final double bpm; // 60.0 to 200.0 BPM musical tempo sync
  final double gateWidth; // 0.1 to 1.0 duty cycle / gate width
  final double pitchDropSemitones; // 0.0 to 12.0 semitones pitch drop depth
  final double mix; // 0.0 to 1.0 wet stutter signal level

  const AudioStutterConfig({
    this.isEnabled = false,
    this.division = StutterDivision.eighth,
    this.mode = AudioStutterMode.straight,
    this.repeats = 4,
    this.bpm = 120.0,
    this.gateWidth = 0.75,
    this.pitchDropSemitones = 4.0,
    this.mix = 0.85,
  });

  bool get isActive => isEnabled && repeats >= 1 && mix > 0.05;

  /// Calculates duration of one stutter slice in milliseconds based on BPM and division.
  double get sliceDurationMs {
    final beatMs = (60.0 / bpm.clamp(40.0, 300.0)) * 1000.0;
    return beatMs * division.beatFraction;
  }

  AudioStutterConfig copyWith({
    bool? isEnabled,
    StutterDivision? division,
    AudioStutterMode? mode,
    int? repeats,
    double? bpm,
    double? gateWidth,
    double? pitchDropSemitones,
    double? mix,
  }) {
    return AudioStutterConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      division: division ?? this.division,
      mode: mode ?? this.mode,
      repeats: repeats ?? this.repeats,
      bpm: bpm ?? this.bpm,
      gateWidth: gateWidth ?? this.gateWidth,
      pitchDropSemitones: pitchDropSemitones ?? this.pitchDropSemitones,
      mix: mix ?? this.mix,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'division': division.name,
      'mode': mode.name,
      'repeats': repeats,
      'bpm': bpm,
      'gateWidth': gateWidth,
      'pitchDropSemitones': pitchDropSemitones,
      'mix': mix,
    };
  }

  factory AudioStutterConfig.fromJson(Map<String, dynamic> json) {
    StutterDivision parsedDivision = StutterDivision.eighth;
    if (json['division'] != null) {
      try {
        parsedDivision = StutterDivision.values.byName(json['division'] as String);
      } catch (_) {
        parsedDivision = StutterDivision.eighth;
      }
    }

    AudioStutterMode parsedMode = AudioStutterMode.straight;
    if (json['mode'] != null) {
      try {
        parsedMode = AudioStutterMode.values.byName(json['mode'] as String);
      } catch (_) {
        parsedMode = AudioStutterMode.straight;
      }
    }

    return AudioStutterConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      division: parsedDivision,
      mode: parsedMode,
      repeats: (json['repeats'] as num?)?.toInt() ?? 4,
      bpm: (json['bpm'] as num?)?.toDouble() ?? 120.0,
      gateWidth: (json['gateWidth'] as num?)?.toDouble() ?? 0.75,
      pitchDropSemitones: (json['pitchDropSemitones'] as num?)?.toDouble() ?? 4.0,
      mix: (json['mix'] as num?)?.toDouble() ?? 0.85,
    );
  }

  // Curated presets
  static const AudioStutterConfig eighthBeatRoll = AudioStutterConfig(
    isEnabled: true,
    division: StutterDivision.eighth,
    mode: AudioStutterMode.straight,
    repeats: 4,
    bpm: 120.0,
    gateWidth: 0.80,
    pitchDropSemitones: 0.0,
    mix: 0.85,
  );

  static const AudioStutterConfig sixteenthGlitch = AudioStutterConfig(
    isEnabled: true,
    division: StutterDivision.sixteenth,
    mode: AudioStutterMode.straight,
    repeats: 6,
    bpm: 128.0,
    gateWidth: 0.70,
    pitchDropSemitones: 0.0,
    mix: 0.90,
  );

  static const AudioStutterConfig pitchDropBrake = AudioStutterConfig(
    isEnabled: true,
    division: StutterDivision.eighth,
    mode: AudioStutterMode.pitchDrop,
    repeats: 4,
    bpm: 120.0,
    gateWidth: 0.85,
    pitchDropSemitones: 6.0,
    mix: 0.95,
  );

  static const AudioStutterConfig machineGunDrill = AudioStutterConfig(
    isEnabled: true,
    division: StutterDivision.thirtySecond,
    mode: AudioStutterMode.accelerando,
    repeats: 8,
    bpm: 140.0,
    gateWidth: 0.90,
    pitchDropSemitones: 0.0,
    mix: 1.0,
  );

  static const AudioStutterConfig granularCloud = AudioStutterConfig(
    isEnabled: true,
    division: StutterDivision.sixteenth,
    mode: AudioStutterMode.granularCloud,
    repeats: 5,
    bpm: 110.0,
    gateWidth: 0.60,
    pitchDropSemitones: 2.0,
    mix: 0.75,
  );

  @override
  List<Object?> get props => [
        isEnabled,
        division,
        mode,
        repeats,
        bpm,
        gateWidth,
        pitchDropSemitones,
        mix,
      ];
}
