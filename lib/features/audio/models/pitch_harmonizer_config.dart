import 'package:equatable/equatable.dart';

/// Preset modes for vocal pitch transposition, interval harmonies, and timbre synthesis.
enum PitchHarmonizerMode {
  naturalSemitone,
  octaveDoubler,
  vocalHarmonizer,
  chipmunkHelium,
  deepMonsterSub,
  roboticRingMod;

  String get displayName {
    switch (this) {
      case PitchHarmonizerMode.naturalSemitone:
        return 'Musical Semitone Shift';
      case PitchHarmonizerMode.octaveDoubler:
        return 'Octave Doubler Stack';
      case PitchHarmonizerMode.vocalHarmonizer:
        return 'Dual-Voice Harmony';
      case PitchHarmonizerMode.chipmunkHelium:
        return 'Chipmunk Helium Vocal';
      case PitchHarmonizerMode.deepMonsterSub:
        return 'Deep Monster Sub-Bass';
      case PitchHarmonizerMode.roboticRingMod:
        return 'Cybernetic Ring Mod';
    }
  }

  String get description {
    switch (this) {
      case PitchHarmonizerMode.naturalSemitone:
        return 'Precise musical semitone and fine-cent pitch shift without changing playback speed';
      case PitchHarmonizerMode.octaveDoubler:
        return 'Multi-voice stack doubling vocals with sub-octave warmth or upper-octave sheen';
      case PitchHarmonizerMode.vocalHarmonizer:
        return 'Generates parallel third or fifth musical harmony voices for vocal choruses';
      case PitchHarmonizerMode.chipmunkHelium:
        return 'High-speed comic cartoon pitch upshift with compressed vocal tract formants';
      case PitchHarmonizerMode.deepMonsterSub:
        return 'Ominous cinematic pitch downshift with thunderous sub-bass body resonance';
      case PitchHarmonizerMode.roboticRingMod:
        return 'Metallic sci-fi droid vocal modulation synthesizing ring-modulated sidebands';
    }
  }
}

/// Musical harmonic intervals for dual-voice chord generation.
enum HarmonyInterval {
  unison,
  minorThird,
  majorThird,
  perfectFourth,
  perfectFifth,
  octaveDown,
  octaveUp;

  String get displayName {
    switch (this) {
      case HarmonyInterval.unison:
        return 'Unison (0 st)';
      case HarmonyInterval.minorThird:
        return 'Minor 3rd (+3 st)';
      case HarmonyInterval.majorThird:
        return 'Major 3rd (+4 st)';
      case HarmonyInterval.perfectFourth:
        return 'Perfect 4th (+5 st)';
      case HarmonyInterval.perfectFifth:
        return 'Perfect 5th (+7 st)';
      case HarmonyInterval.octaveDown:
        return 'Octave Down (-12 st)';
      case HarmonyInterval.octaveUp:
        return 'Octave Up (+12 st)';
    }
  }

  int get semitoneOffset {
    switch (this) {
      case HarmonyInterval.unison:
        return 0;
      case HarmonyInterval.minorThird:
        return 3;
      case HarmonyInterval.majorThird:
        return 4;
      case HarmonyInterval.perfectFourth:
        return 5;
      case HarmonyInterval.perfectFifth:
        return 7;
      case HarmonyInterval.octaveDown:
        return -12;
      case HarmonyInterval.octaveUp:
        return 12;
    }
  }
}

/// Configuration for vocal pitch shifting, interval harmonizing, and timbre synthesis.
class PitchHarmonizerConfig extends Equatable {
  final bool isEnabled;
  final PitchHarmonizerMode mode;
  final int semitones; // -12 to +12 semitones
  final int cents; // -50 to +50 cents (fine tuning)
  final HarmonyInterval harmonyInterval;
  final double harmonyMix; // 0.0 to 1.0 (harmony voice level)
  final bool formantPreserve; // Keep vocal timbre natural
  final double mix; // 0.0 to 1.0 (wet/dry balance)

  const PitchHarmonizerConfig({
    this.isEnabled = false,
    this.mode = PitchHarmonizerMode.naturalSemitone,
    this.semitones = 0,
    this.cents = 0,
    this.harmonyInterval = HarmonyInterval.perfectFifth,
    this.harmonyMix = 0.50,
    this.formantPreserve = true,
    this.mix = 1.0,
  });

  bool get isActive => isEnabled && (semitones != 0 || cents != 0 || mode != PitchHarmonizerMode.naturalSemitone);

  // Curated Presets
  static const PitchHarmonizerConfig leadVocalFifthHarmony = PitchHarmonizerConfig(
    isEnabled: true,
    mode: PitchHarmonizerMode.vocalHarmonizer,
    semitones: 0,
    cents: 0,
    harmonyInterval: HarmonyInterval.perfectFifth,
    harmonyMix: 0.65,
    formantPreserve: true,
    mix: 1.0,
  );

  static const PitchHarmonizerConfig deepSubOctaveDoubler = PitchHarmonizerConfig(
    isEnabled: true,
    mode: PitchHarmonizerMode.octaveDoubler,
    semitones: -12,
    cents: 0,
    harmonyInterval: HarmonyInterval.octaveDown,
    harmonyMix: 0.70,
    formantPreserve: true,
    mix: 1.0,
  );

  static const PitchHarmonizerConfig airyUpperOctave = PitchHarmonizerConfig(
    isEnabled: true,
    mode: PitchHarmonizerMode.octaveDoubler,
    semitones: 12,
    cents: 0,
    harmonyInterval: HarmonyInterval.octaveUp,
    harmonyMix: 0.50,
    formantPreserve: true,
    mix: 0.90,
  );

  static const PitchHarmonizerConfig demonGravePitch = PitchHarmonizerConfig(
    isEnabled: true,
    mode: PitchHarmonizerMode.deepMonsterSub,
    semitones: -8,
    cents: -15,
    harmonyInterval: HarmonyInterval.octaveDown,
    harmonyMix: 0.85,
    formantPreserve: false,
    mix: 1.0,
  );

  static const PitchHarmonizerConfig dalekRoboticMod = PitchHarmonizerConfig(
    isEnabled: true,
    mode: PitchHarmonizerMode.roboticRingMod,
    semitones: -3,
    cents: 0,
    harmonyInterval: HarmonyInterval.unison,
    harmonyMix: 0.90,
    formantPreserve: false,
    mix: 1.0,
  );

  PitchHarmonizerConfig copyWith({
    bool? isEnabled,
    PitchHarmonizerMode? mode,
    int? semitones,
    int? cents,
    HarmonyInterval? harmonyInterval,
    double? harmonyMix,
    bool? formantPreserve,
    double? mix,
  }) {
    return PitchHarmonizerConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      semitones: semitones ?? this.semitones,
      cents: cents ?? this.cents,
      harmonyInterval: harmonyInterval ?? this.harmonyInterval,
      harmonyMix: harmonyMix ?? this.harmonyMix,
      formantPreserve: formantPreserve ?? this.formantPreserve,
      mix: mix ?? this.mix,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'semitones': semitones,
      'cents': cents,
      'harmonyInterval': harmonyInterval.name,
      'harmonyMix': harmonyMix,
      'formantPreserve': formantPreserve,
      'mix': mix,
    };
  }

  factory PitchHarmonizerConfig.fromJson(Map<String, dynamic> json) {
    return PitchHarmonizerConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: PitchHarmonizerMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => PitchHarmonizerMode.naturalSemitone,
      ),
      semitones: json['semitones'] as int? ?? 0,
      cents: json['cents'] as int? ?? 0,
      harmonyInterval: HarmonyInterval.values.firstWhere(
        (e) => e.name == json['harmonyInterval'],
        orElse: () => HarmonyInterval.perfectFifth,
      ),
      harmonyMix: (json['harmonyMix'] as num?)?.toDouble() ?? 0.50,
      formantPreserve: json['formantPreserve'] as bool? ?? true,
      mix: (json['mix'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        semitones,
        cents,
        harmonyInterval,
        harmonyMix,
        formantPreserve,
        mix,
      ];
}
