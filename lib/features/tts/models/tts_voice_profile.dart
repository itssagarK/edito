import 'package:equatable/equatable.dart';

enum VoiceCategory {
  viralShorts('Shorts & Reels Viral'),
  documentary('Deep Documentary'),
  storytelling('Engaging Narrative'),
  mindfulChill('ASMR & Calm'),
  cinematic('Cinematic Trailer'),
  futuristic('Sci-Fi & Robot');

  final String label;
  const VoiceCategory(this.label);
}

enum TTSVoiceProfile {
  narratorAdam(
    id: 'adam_doc',
    displayName: 'Adam (Narrator)',
    category: VoiceCategory.documentary,
    gender: 'Male',
    avatarEmoji: '🎙️',
    description: 'Deep, authoritative baritone for documentaries, essays, and reviews.',
    fundamentalHz: 110,
    f1Hz: 500,
    f2Hz: 1500,
    f3Hz: 2500,
    defaultPitch: -1.0,
  ),
  storytellerEmma(
    id: 'emma_story',
    displayName: 'Emma (Storyteller)',
    category: VoiceCategory.storytelling,
    gender: 'Female',
    avatarEmoji: '🌟',
    description: 'Warm, expressive, melodic tone for audiobooks and storytelling.',
    fundamentalHz: 215,
    f1Hz: 650,
    f2Hz: 1800,
    f3Hz: 2800,
    defaultPitch: 0.5,
  ),
  viralMax(
    id: 'max_viral',
    displayName: 'Max (TikTok / Shorts)',
    category: VoiceCategory.viralShorts,
    gender: 'Male',
    avatarEmoji: '⚡',
    description: 'Fast-paced, high-energy viral creator voice for reels and shorts.',
    fundamentalHz: 140,
    f1Hz: 550,
    f2Hz: 1650,
    f3Hz: 2650,
    defaultPitch: 1.0,
  ),
  calmLily(
    id: 'lily_calm',
    displayName: 'Lily (Calm / ASMR)',
    category: VoiceCategory.mindfulChill,
    gender: 'Female',
    avatarEmoji: '🧘',
    description: 'Soft, gentle, breathy voice for meditation, wellness, and aesthetic vlogs.',
    fundamentalHz: 230,
    f1Hz: 700,
    f2Hz: 2000,
    f3Hz: 3000,
    defaultPitch: 0.0,
  ),
  trailerTitan(
    id: 'titan_trailer',
    displayName: 'Titan (Movie Trailer)',
    category: VoiceCategory.cinematic,
    gender: 'Male',
    avatarEmoji: '🎬',
    description: 'Ultra-low chest resonance voice for blockbuster movie trailers.',
    fundamentalHz: 85,
    f1Hz: 400,
    f2Hz: 1300,
    f3Hz: 2200,
    defaultPitch: -3.0,
  ),
  cyberRobot(
    id: 'cyber_bot',
    displayName: 'Cyber-9 (Robotic)',
    category: VoiceCategory.futuristic,
    gender: 'Neutral',
    avatarEmoji: '🤖',
    description: 'Vintage 80s vocoder synthesized digital droid voice.',
    fundamentalHz: 175,
    f1Hz: 600,
    f2Hz: 1200,
    f3Hz: 2400,
    defaultPitch: 0.0,
  );

  final String id;
  final String displayName;
  final VoiceCategory category;
  final String gender;
  final String avatarEmoji;
  final String description;
  final int fundamentalHz;
  final int f1Hz;
  final int f2Hz;
  final int f3Hz;
  final double defaultPitch;

  const TTSVoiceProfile({
    required this.id,
    required this.displayName,
    required this.category,
    required this.gender,
    required this.avatarEmoji,
    required this.description,
    required this.fundamentalHz,
    required this.f1Hz,
    required this.f2Hz,
    required this.f3Hz,
    required this.defaultPitch,
  });
}

class TTSConfig extends Equatable {
  final TTSVoiceProfile voice;
  final String scriptText;
  final double speechRate;           // 0.5 to 2.0 (default 1.0)
  final double pitchShift;           // -6.0 to +6.0 semitones
  final double volumeBoost;          // 0.5 to 2.0 (default 1.0)
  final bool autoGenerateCaptions;   // Automatically inject synchronized subtitles

  const TTSConfig({
    this.voice = TTSVoiceProfile.narratorAdam,
    this.scriptText = 'Welcome back to another video. Today we are exploring the future of editing.',
    this.speechRate = 1.0,
    this.pitchShift = 0.0,
    this.volumeBoost = 1.0,
    this.autoGenerateCaptions = true,
  });

  TTSConfig copyWith({
    TTSVoiceProfile? voice,
    String? scriptText,
    double? speechRate,
    double? pitchShift,
    double? volumeBoost,
    bool? autoGenerateCaptions,
  }) {
    return TTSConfig(
      voice: voice ?? this.voice,
      scriptText: scriptText ?? this.scriptText,
      speechRate: speechRate ?? this.speechRate,
      pitchShift: pitchShift ?? this.pitchShift,
      volumeBoost: volumeBoost ?? this.volumeBoost,
      autoGenerateCaptions: autoGenerateCaptions ?? this.autoGenerateCaptions,
    );
  }

  Map<String, dynamic> toJson() => {
        'voice': voice.name,
        'scriptText': scriptText,
        'speechRate': speechRate,
        'pitchShift': pitchShift,
        'volumeBoost': volumeBoost,
        'autoGenerateCaptions': autoGenerateCaptions,
      };

  factory TTSConfig.fromJson(Map<String, dynamic> json) => TTSConfig(
        voice: TTSVoiceProfile.values.firstWhere(
          (v) => v.name == json['voice'],
          orElse: () => TTSVoiceProfile.narratorAdam,
        ),
        scriptText: json['scriptText'] as String? ?? '',
        speechRate: (json['speechRate'] as num?)?.toDouble() ?? 1.0,
        pitchShift: (json['pitchShift'] as num?)?.toDouble() ?? 0.0,
        volumeBoost: (json['volumeBoost'] as num?)?.toDouble() ?? 1.0,
        autoGenerateCaptions: json['autoGenerateCaptions'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [
        voice,
        scriptText,
        speechRate,
        pitchShift,
        volumeBoost,
        autoGenerateCaptions,
      ];
}
