import 'package:equatable/equatable.dart';
import '../features/audio/models/audio_effects_config.dart';

class Clip extends Equatable {
  final String id;
  final String assetId;
  final String trackId;
  final int startTimeMs;    // Position in timeline
  final int durationMs;     // Active duration in timeline
  final int sourceInMs;     // Trim start in source media
  final int sourceOutMs;    // Trim end in source media
  final double volume;      // 0.0 to 2.0 (1.0 = normal)
  final double speed;       // 0.1 to 10.0 (1.0 = normal)
  final bool isMuted;
  final AudioEffectsConfig audioEffects;

  const Clip({
    required this.id,
    required this.assetId,
    required this.trackId,
    required this.startTimeMs,
    required this.durationMs,
    required this.sourceInMs,
    required this.sourceOutMs,
    this.volume = 1.0,
    this.speed = 1.0,
    this.isMuted = false,
    this.audioEffects = const AudioEffectsConfig(),
  });

  Clip copyWith({
    String? id,
    String? assetId,
    String? trackId,
    int? startTimeMs,
    int? durationMs,
    int? sourceInMs,
    int? sourceOutMs,
    double? volume,
    double? speed,
    bool? isMuted,
    AudioEffectsConfig? audioEffects,
  }) {
    return Clip(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      trackId: trackId ?? this.trackId,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      durationMs: durationMs ?? this.durationMs,
      sourceInMs: sourceInMs ?? this.sourceInMs,
      sourceOutMs: sourceOutMs ?? this.sourceOutMs,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      isMuted: isMuted ?? this.isMuted,
      audioEffects: audioEffects ?? this.audioEffects,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetId': assetId,
        'trackId': trackId,
        'startTimeMs': startTimeMs,
        'durationMs': durationMs,
        'sourceInMs': sourceInMs,
        'sourceOutMs': sourceOutMs,
        'volume': volume,
        'speed': speed,
        'isMuted': isMuted,
        'audioEffects': audioEffects.toJson(),
      };

  factory Clip.fromJson(Map<String, dynamic> json) => Clip(
        id: json['id'] as String,
        assetId: json['assetId'] as String,
        trackId: json['trackId'] as String,
        startTimeMs: json['startTimeMs'] as int,
        durationMs: json['durationMs'] as int,
        sourceInMs: json['sourceInMs'] as int,
        sourceOutMs: json['sourceOutMs'] as int,
        volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
        speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
        isMuted: json['isMuted'] as bool? ?? false,
        audioEffects: json['audioEffects'] != null
            ? AudioEffectsConfig.fromJson(json['audioEffects'] as Map<String, dynamic>)
            : const AudioEffectsConfig(),
      );

  @override
  List<Object?> get props => [
        id,
        assetId,
        trackId,
        startTimeMs,
        durationMs,
        sourceInMs,
        sourceOutMs,
        volume,
        speed,
        isMuted,
        audioEffects,
      ];
}
