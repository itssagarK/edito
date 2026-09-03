import 'package:equatable/equatable.dart';
import '../features/audio/models/audio_effects_config.dart';
import '../features/color_grading/models/color_grading_config.dart';
import '../features/enhancement/models/video_enhancement_config.dart';
import '../features/overlays/models/keyframe.dart';
import '../features/overlays/models/text_overlay_config.dart';
import '../features/smoothing/models/video_smoother_config.dart';
import '../features/speed/models/speed_curve_preset.dart';
import '../features/transitions/models/transition_type.dart';

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
  final ColorGradingConfig colorGrading;
  final TransitionConfig transitionIn;
  final TransitionConfig transitionOut;
  final SpeedCurveConfig speedCurve;
  final TextOverlayConfig textOverlay;
  final VideoEnhancementConfig enhancement;
  final VideoSmootherConfig smoother;
  final List<Keyframe> keyframes;

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
    this.colorGrading = const ColorGradingConfig(),
    this.transitionIn = const TransitionConfig(),
    this.transitionOut = const TransitionConfig(),
    this.speedCurve = const SpeedCurveConfig(),
    this.textOverlay = const TextOverlayConfig(),
    this.enhancement = const VideoEnhancementConfig(),
    this.smoother = const VideoSmootherConfig(),
    this.keyframes = const [],
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
    ColorGradingConfig? colorGrading,
    TransitionConfig? transitionIn,
    TransitionConfig? transitionOut,
    SpeedCurveConfig? speedCurve,
    TextOverlayConfig? textOverlay,
    VideoEnhancementConfig? enhancement,
    VideoSmootherConfig? smoother,
    List<Keyframe>? keyframes,
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
      colorGrading: colorGrading ?? this.colorGrading,
      transitionIn: transitionIn ?? this.transitionIn,
      transitionOut: transitionOut ?? this.transitionOut,
      speedCurve: speedCurve ?? this.speedCurve,
      textOverlay: textOverlay ?? this.textOverlay,
      enhancement: enhancement ?? this.enhancement,
      smoother: smoother ?? this.smoother,
      keyframes: keyframes ?? this.keyframes,
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
        'colorGrading': colorGrading.toJson(),
        'transitionIn': transitionIn.toJson(),
        'transitionOut': transitionOut.toJson(),
        'speedCurve': speedCurve.toJson(),
        'textOverlay': textOverlay.toJson(),
        'enhancement': enhancement.toJson(),
        'smoother': smoother.toJson(),
        'keyframes': keyframes.map((k) => k.toJson()).toList(),
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
        colorGrading: json['colorGrading'] != null
            ? ColorGradingConfig.fromJson(json['colorGrading'] as Map<String, dynamic>)
            : const ColorGradingConfig(),
        transitionIn: json['transitionIn'] != null
            ? TransitionConfig.fromJson(json['transitionIn'] as Map<String, dynamic>)
            : const TransitionConfig(),
        transitionOut: json['transitionOut'] != null
            ? TransitionConfig.fromJson(json['transitionOut'] as Map<String, dynamic>)
            : const TransitionConfig(),
        speedCurve: json['speedCurve'] != null
            ? SpeedCurveConfig.fromJson(json['speedCurve'] as Map<String, dynamic>)
            : const SpeedCurveConfig(),
        textOverlay: json['textOverlay'] != null
            ? TextOverlayConfig.fromJson(json['textOverlay'] as Map<String, dynamic>)
            : const TextOverlayConfig(),
        enhancement: json['enhancement'] != null
            ? VideoEnhancementConfig.fromJson(json['enhancement'] as Map<String, dynamic>)
            : const VideoEnhancementConfig(),
        smoother: json['smoother'] != null
            ? VideoSmootherConfig.fromJson(json['smoother'] as Map<String, dynamic>)
            : const VideoSmootherConfig(),
        keyframes: (json['keyframes'] as List<dynamic>?)
                ?.map((k) => Keyframe.fromJson(k as Map<String, dynamic>))
                .toList() ??
            const [],
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
        colorGrading,
        transitionIn,
        transitionOut,
        speedCurve,
        textOverlay,
        enhancement,
        smoother,
        keyframes,
      ];
}
