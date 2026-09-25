import 'package:equatable/equatable.dart';

/// CapCut Pro AI Voice Changer Characters
enum VoiceEffectCharacter {
  none,
  chipmunk,
  deepMonster,
  robotVocoder,
  echoCave,
  heliumBalloon,
  retroRadio,
  vinylLofi,
  megaphone,
  synthAlien,
  custom,
}

extension VoiceEffectCharacterExtension on VoiceEffectCharacter {
  String get label {
    switch (this) {
      case VoiceEffectCharacter.none:
        return 'Original';
      case VoiceEffectCharacter.chipmunk:
        return 'Chipmunk';
      case VoiceEffectCharacter.deepMonster:
        return 'Deep Monster';
      case VoiceEffectCharacter.robotVocoder:
        return 'Robot Vocoder';
      case VoiceEffectCharacter.echoCave:
        return 'Cavern Echo';
      case VoiceEffectCharacter.heliumBalloon:
        return 'Helium Squeak';
      case VoiceEffectCharacter.retroRadio:
        return 'Retro Walkie';
      case VoiceEffectCharacter.vinylLofi:
        return 'Vinyl Lo-Fi';
      case VoiceEffectCharacter.megaphone:
        return 'Megaphone';
      case VoiceEffectCharacter.synthAlien:
        return 'Synth Alien';
      case VoiceEffectCharacter.custom:
        return 'Custom Timbre';
    }
  }

  String get description {
    switch (this) {
      case VoiceEffectCharacter.none:
        return 'Natural unaltered vocal timbre';
      case VoiceEffectCharacter.chipmunk:
        return 'High-pitched, energetic cartoon chirp (+8 semitones)';
      case VoiceEffectCharacter.deepMonster:
        return 'Rumbling cinematic demonic sub-bass (-8 semitones)';
      case VoiceEffectCharacter.robotVocoder:
        return 'Metallic cybernetic vocoder with robotic modulation';
      case VoiceEffectCharacter.echoCave:
        return 'Sprawling cavernous acoustic delay & multi-tap reflections';
      case VoiceEffectCharacter.heliumBalloon:
        return 'Ultra-high helium balloon vocal resonance (+12 semitones)';
      case VoiceEffectCharacter.retroRadio:
        return 'Narrow-band lo-fi vintage communication radio & walkie-talkie';
      case VoiceEffectCharacter.vinylLofi:
        return 'Warm nostalgic turntable vinyl tone with gentle pitch flutter';
      case VoiceEffectCharacter.megaphone:
        return 'Gritty bandpassed bullhorn loudspeaker projection';
      case VoiceEffectCharacter.synthAlien:
        return 'Cosmic sci-fi pitch vibrato & space modulation';
      case VoiceEffectCharacter.custom:
        return 'User-customized parametric pitch and timbre morphing';
    }
  }

  VoiceEffectCategory get category {
    switch (this) {
      case VoiceEffectCharacter.none:
        return VoiceEffectCategory.all;
      case VoiceEffectCharacter.chipmunk:
      case VoiceEffectCharacter.deepMonster:
      case VoiceEffectCharacter.heliumBalloon:
        return VoiceEffectCategory.characters;
      case VoiceEffectCharacter.robotVocoder:
      case VoiceEffectCharacter.synthAlien:
        return VoiceEffectCategory.characters;
      case VoiceEffectCharacter.retroRadio:
      case VoiceEffectCharacter.vinylLofi:
      case VoiceEffectCharacter.megaphone:
        return VoiceEffectCategory.retro;
      case VoiceEffectCharacter.echoCave:
        return VoiceEffectCategory.spatial;
      case VoiceEffectCharacter.custom:
        return VoiceEffectCategory.custom;
    }
  }
}

/// Character category filters for the CapCut Pro Voice Effects studio
enum VoiceEffectCategory {
  all,
  characters,
  retro,
  spatial,
  custom,
}

extension VoiceEffectCategoryExtension on VoiceEffectCategory {
  String get label {
    switch (this) {
      case VoiceEffectCategory.all:
        return 'All';
      case VoiceEffectCategory.characters:
        return 'Characters';
      case VoiceEffectCategory.retro:
        return 'Retro & Lo-Fi';
      case VoiceEffectCategory.spatial:
        return 'Spatial Reverb';
      case VoiceEffectCategory.custom:
        return 'Custom';
    }
  }
}

/// CapCut Pro AI Voice Changer & Audio Timbre Morphing Configuration
class VoiceEffectsConfig extends Equatable {
  final bool isEnabled;
  final VoiceEffectCharacter character;
  final double pitchSemitones;    // -12.0 to +12.0 semitones
  final double formantShift;      // 0.5 to 1.5x timbre formant scaling
  final double timbreResonance;   // 0.0 to 1.0 resonant frequency boost
  final double vibratoDepth;      // 0.0 to 1.0 pitch vibrato modulation depth
  final double vibratoRate;       // 0.5 to 14.0 Hz vibrato speed
  final int echoDelayMs;          // 0 to 1000 ms reflection delay
  final double echoFeedback;      // 0.0 to 0.85 reflection decay
  final double distortion;        // 0.0 to 1.0 saturation / lo-fi crunch
  final double mix;               // 0.0 (dry) to 1.0 (wet)
  final double lowCutHz;          // Highpass cut frequency
  final double highCutHz;         // Lowpass cut frequency

  const VoiceEffectsConfig({
    this.isEnabled = false,
    this.character = VoiceEffectCharacter.none,
    this.pitchSemitones = 0.0,
    this.formantShift = 1.0,
    this.timbreResonance = 0.0,
    this.vibratoDepth = 0.0,
    this.vibratoRate = 5.0,
    this.echoDelayMs = 0,
    this.echoFeedback = 0.0,
    this.distortion = 0.0,
    this.mix = 1.0,
    this.lowCutHz = 20.0,
    this.highCutHz = 20000.0,
  });

  /// Factory constructor to instantiate a curated CapCut Pro character preset
  factory VoiceEffectsConfig.preset(VoiceEffectCharacter character) {
    switch (character) {
      case VoiceEffectCharacter.none:
        return const VoiceEffectsConfig();
      case VoiceEffectCharacter.chipmunk:
        return const VoiceEffectsConfig(
          isEnabled: true,
          character: VoiceEffectCharacter.chipmunk,
          pitchSemitones: 8.0,
          formantShift: 1.35,
          mix: 1.0,
          highCutHz: 18000.0,
        );
      case VoiceEffectCharacter.deepMonster:
        return const VoiceEffectsConfig(
          isEnabled: true,
          character: VoiceEffectCharacter.deepMonster,
          pitchSemitones: -8.0,
          formantShift: 0.75,
          timbreResonance: 0.6,
          lowCutHz: 60.0,
          highCutHz: 4500.0,
          mix: 1.0,
        );
      case VoiceEffectCharacter.robotVocoder:
        return const VoiceEffectsConfig(
          isEnabled: true,
          character: VoiceEffectCharacter.robotVocoder,
          pitchSemitones: 0.0,
          timbreResonance: 0.8,
          vibratoDepth: 0.5,
          vibratoRate: 12.0,
          mix: 1.0,
        );
      case VoiceEffectCharacter.echoCave:
        return const VoiceEffectsConfig(
          isEnabled: true,
          character: VoiceEffectCharacter.echoCave,
          pitchSemitones: 0.0,
          echoDelayMs: 250,
          echoFeedback: 0.55,
          mix: 0.8,
        );
      case VoiceEffectCharacter.heliumBalloon:
        return const VoiceEffectsConfig(
          isEnabled: true,
          character: VoiceEffectCharacter.heliumBalloon,
          pitchSemitones: 12.0,
          formantShift: 1.5,
          mix: 1.0,
        );
      case VoiceEffectCharacter.retroRadio:
        return const VoiceEffectsConfig(
          isEnabled: true,
          character: VoiceEffectCharacter.retroRadio,
          pitchSemitones: 0.0,
          lowCutHz: 400.0,
          highCutHz: 3500.0,
          distortion: 0.45,
          mix: 1.0,
        );
      case VoiceEffectCharacter.vinylLofi:
        return const VoiceEffectsConfig(
          isEnabled: true,
          character: VoiceEffectCharacter.vinylLofi,
          pitchSemitones: -1.0,
          lowCutHz: 250.0,
          highCutHz: 5000.0,
          vibratoDepth: 0.15,
          vibratoRate: 1.5,
          mix: 0.9,
        );
      case VoiceEffectCharacter.megaphone:
        return const VoiceEffectsConfig(
          isEnabled: true,
          character: VoiceEffectCharacter.megaphone,
          pitchSemitones: 0.0,
          lowCutHz: 600.0,
          highCutHz: 4000.0,
          distortion: 0.6,
          mix: 1.0,
        );
      case VoiceEffectCharacter.synthAlien:
        return const VoiceEffectsConfig(
          isEnabled: true,
          character: VoiceEffectCharacter.synthAlien,
          pitchSemitones: 3.0,
          vibratoDepth: 0.85,
          vibratoRate: 8.5,
          echoDelayMs: 140,
          echoFeedback: 0.4,
          mix: 0.95,
        );
      case VoiceEffectCharacter.custom:
        return const VoiceEffectsConfig(
          isEnabled: true,
          character: VoiceEffectCharacter.custom,
        );
    }
  }

  VoiceEffectsConfig copyWith({
    bool? isEnabled,
    VoiceEffectCharacter? character,
    double? pitchSemitones,
    double? formantShift,
    double? timbreResonance,
    double? vibratoDepth,
    double? vibratoRate,
    int? echoDelayMs,
    double? echoFeedback,
    double? distortion,
    double? mix,
    double? lowCutHz,
    double? highCutHz,
  }) {
    return VoiceEffectsConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      character: character ?? this.character,
      pitchSemitones: pitchSemitones ?? this.pitchSemitones,
      formantShift: formantShift ?? this.formantShift,
      timbreResonance: timbreResonance ?? this.timbreResonance,
      vibratoDepth: vibratoDepth ?? this.vibratoDepth,
      vibratoRate: vibratoRate ?? this.vibratoRate,
      echoDelayMs: echoDelayMs ?? this.echoDelayMs,
      echoFeedback: echoFeedback ?? this.echoFeedback,
      distortion: distortion ?? this.distortion,
      mix: mix ?? this.mix,
      lowCutHz: lowCutHz ?? this.lowCutHz,
      highCutHz: highCutHz ?? this.highCutHz,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'character': character.index,
      'pitchSemitones': pitchSemitones,
      'formantShift': formantShift,
      'timbreResonance': timbreResonance,
      'vibratoDepth': vibratoDepth,
      'vibratoRate': vibratoRate,
      'echoDelayMs': echoDelayMs,
      'echoFeedback': echoFeedback,
      'distortion': distortion,
      'mix': mix,
      'lowCutHz': lowCutHz,
      'highCutHz': highCutHz,
    };
  }

  factory VoiceEffectsConfig.fromJson(Map<String, dynamic> json) {
    return VoiceEffectsConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      character: VoiceEffectCharacter.values[
        (json['character'] as int? ?? 0).clamp(0, VoiceEffectCharacter.values.length - 1)
      ],
      pitchSemitones: (json['pitchSemitones'] as num?)?.toDouble() ?? 0.0,
      formantShift: (json['formantShift'] as num?)?.toDouble() ?? 1.0,
      timbreResonance: (json['timbreResonance'] as num?)?.toDouble() ?? 0.0,
      vibratoDepth: (json['vibratoDepth'] as num?)?.toDouble() ?? 0.0,
      vibratoRate: (json['vibratoRate'] as num?)?.toDouble() ?? 5.0,
      echoDelayMs: json['echoDelayMs'] as int? ?? 0,
      echoFeedback: (json['echoFeedback'] as num?)?.toDouble() ?? 0.0,
      distortion: (json['distortion'] as num?)?.toDouble() ?? 0.0,
      mix: (json['mix'] as num?)?.toDouble() ?? 1.0,
      lowCutHz: (json['lowCutHz'] as num?)?.toDouble() ?? 20.0,
      highCutHz: (json['highCutHz'] as num?)?.toDouble() ?? 20000.0,
    );
  }

  /// Compact HUD status badge text
  String get badge {
    if (!isEnabled || character == VoiceEffectCharacter.none) {
      return '';
    }
    if (character == VoiceEffectCharacter.custom) {
      final pitchStr = pitchSemitones >= 0
          ? '+${pitchSemitones.toStringAsFixed(1)}st'
          : '${pitchSemitones.toStringAsFixed(1)}st';
      return 'VOICE: $pitchStr';
    }
    return 'VOICE: ${character.label.toUpperCase()}';
  }

  @override
  List<Object?> get props => [
    isEnabled,
    character,
    pitchSemitones,
    formantShift,
    timbreResonance,
    vibratoDepth,
    vibratoRate,
    echoDelayMs,
    echoFeedback,
    distortion,
    mix,
    lowCutHz,
    highCutHz,
  ];
}
