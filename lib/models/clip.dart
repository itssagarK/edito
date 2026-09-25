import 'package:equatable/equatable.dart';
import '../features/audio/models/audio_effects_config.dart';
import '../features/borders/models/video_border_config.dart';
import '../features/character_zoom/models/character_zoom_config.dart';
import '../features/chroma/models/chroma_key_config.dart';
import '../features/color_grading/models/color_grading_config.dart';
import '../features/hd_converter/models/hd_converter_config.dart';
import '../features/header_footer/models/header_footer_config.dart';
import '../features/highlight/models/character_highlight_config.dart';
import '../features/image_editor/models/image_overlay_config.dart';
import '../features/enhancement/models/video_enhancement_config.dart';
import '../features/overlays/models/keyframe.dart';
import '../features/overlays/models/text_overlay_config.dart';
import '../features/blending/models/blend_mode_config.dart';
import '../features/masking/models/mask_config.dart';
import '../features/smoothing/models/video_smoother_config.dart';
import '../features/speed/models/speed_curve_preset.dart';
import '../features/transitions/models/transition_type.dart';
import '../features/vfx/models/vfx_config.dart';
import '../features/beats/models/beat_detection_config.dart';
import '../features/cutout/models/smart_cutout_config.dart';
import '../features/speed/models/auto_velocity_config.dart';
import '../features/captions/models/kinetic_captions_config.dart';
import '../features/tracking/models/motion_tracking_config.dart';
import '../features/retouch/models/face_retouch_config.dart';
import '../features/parallax_3d/models/parallax_3d_config.dart';
import '../features/stabilization/models/stabilization_config.dart';
import '../features/vocal_isolation/models/vocal_isolation_config.dart';
import '../features/color_match/models/color_match_config.dart';
import '../features/relight/models/relight_config.dart';
import '../features/denoise/models/denoise_config.dart';

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
  final ChromaKeyConfig chromaKey;
  final ImageOverlayConfig imageOverlay;
  final CharacterHighlightConfig characterHighlight;
  final CharacterZoomConfig characterZoom;
  final VideoBorderConfig border;
  final HeaderFooterConfig headerFooter;
  final HdConverterConfig hdConverter;
  final MaskConfig mask;
  final BlendModeConfig blendMode;
  final List<Keyframe> keyframes;
  final bool isReversed;
  final bool isFreezeFrame;
  final int? freezeSourceMs;
  final VfxConfig vfx;
  final BeatDetectionConfig beatConfig;
  final SmartCutoutConfig smartCutout;
  final AutoVelocityConfig autoVelocity;
  final KineticCaptionsConfig kineticCaptions;
  final MotionTrackingConfig motionTracking;
  final FaceRetouchConfig retouch;
  final Parallax3DConfig parallax3d;
  final StabilizationConfig stabilization;
  final VocalIsolationConfig vocalIsolation;
  final ColorMatchConfig colorMatch;
  final RelightConfig relight;
  final DenoiseConfig denoise;

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
    this.chromaKey = const ChromaKeyConfig(),
    this.imageOverlay = const ImageOverlayConfig(),
    this.characterHighlight = const CharacterHighlightConfig(),
    this.characterZoom = const CharacterZoomConfig(),
    this.border = const VideoBorderConfig(),
    this.headerFooter = const HeaderFooterConfig(),
    this.hdConverter = const HdConverterConfig(),
    this.mask = const MaskConfig(),
    this.blendMode = const BlendModeConfig(),
    this.keyframes = const [],
    this.isReversed = false,
    this.isFreezeFrame = false,
    this.freezeSourceMs,
    this.vfx = const VfxConfig(),
    this.beatConfig = const BeatDetectionConfig(),
    this.smartCutout = const SmartCutoutConfig(),
    this.autoVelocity = const AutoVelocityConfig(),
    this.kineticCaptions = const KineticCaptionsConfig(),
    this.motionTracking = const MotionTrackingConfig(),
    this.retouch = const FaceRetouchConfig(),
    this.parallax3d = const Parallax3DConfig(),
    this.stabilization = const StabilizationConfig(),
    this.vocalIsolation = const VocalIsolationConfig(),
    this.colorMatch = const ColorMatchConfig(),
    this.relight = const RelightConfig(),
    this.denoise = const DenoiseConfig(),
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
    ChromaKeyConfig? chromaKey,
    ImageOverlayConfig? imageOverlay,
    CharacterHighlightConfig? characterHighlight,
    CharacterZoomConfig? characterZoom,
    VideoBorderConfig? border,
    HeaderFooterConfig? headerFooter,
    HdConverterConfig? hdConverter,
    MaskConfig? mask,
    BlendModeConfig? blendMode,
    List<Keyframe>? keyframes,
    bool? isReversed,
    bool? isFreezeFrame,
    int? freezeSourceMs,
    VfxConfig? vfx,
    BeatDetectionConfig? beatConfig,
    SmartCutoutConfig? smartCutout,
    AutoVelocityConfig? autoVelocity,
    KineticCaptionsConfig? kineticCaptions,
    MotionTrackingConfig? motionTracking,
    FaceRetouchConfig? retouch,
    Parallax3DConfig? parallax3d,
    StabilizationConfig? stabilization,
    VocalIsolationConfig? vocalIsolation,
    ColorMatchConfig? colorMatch,
    RelightConfig? relight,
    DenoiseConfig? denoise,
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
      chromaKey: chromaKey ?? this.chromaKey,
      imageOverlay: imageOverlay ?? this.imageOverlay,
      characterHighlight: characterHighlight ?? this.characterHighlight,
      characterZoom: characterZoom ?? this.characterZoom,
      border: border ?? this.border,
      headerFooter: headerFooter ?? this.headerFooter,
      hdConverter: hdConverter ?? this.hdConverter,
      mask: mask ?? this.mask,
      blendMode: blendMode ?? this.blendMode,
      keyframes: keyframes ?? this.keyframes,
      isReversed: isReversed ?? this.isReversed,
      isFreezeFrame: isFreezeFrame ?? this.isFreezeFrame,
      freezeSourceMs: freezeSourceMs ?? this.freezeSourceMs,
      vfx: vfx ?? this.vfx,
      beatConfig: beatConfig ?? this.beatConfig,
      smartCutout: smartCutout ?? this.smartCutout,
      autoVelocity: autoVelocity ?? this.autoVelocity,
      kineticCaptions: kineticCaptions ?? this.kineticCaptions,
      motionTracking: motionTracking ?? this.motionTracking,
      retouch: retouch ?? this.retouch,
      parallax3d: parallax3d ?? this.parallax3d,
      stabilization: stabilization ?? this.stabilization,
      vocalIsolation: vocalIsolation ?? this.vocalIsolation,
      colorMatch: colorMatch ?? this.colorMatch,
      relight: relight ?? this.relight,
      denoise: denoise ?? this.denoise,
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
        'chromaKey': chromaKey.toJson(),
        'imageOverlay': imageOverlay.toJson(),
        'characterHighlight': characterHighlight.toJson(),
        'characterZoom': characterZoom.toJson(),
        'border': border.toJson(),
        'headerFooter': headerFooter.toJson(),
        'hdConverter': hdConverter.toJson(),
        'mask': mask.toJson(),
        'blendMode': blendMode.toJson(),
        'keyframes': keyframes.map((k) => k.toJson()).toList(),
        'isReversed': isReversed,
        'isFreezeFrame': isFreezeFrame,
        'freezeSourceMs': freezeSourceMs,
        'vfx': vfx.toJson(),
        'beatConfig': beatConfig.toJson(),
        'smartCutout': smartCutout.toJson(),
        'autoVelocity': autoVelocity.toJson(),
        'kineticCaptions': kineticCaptions.toJson(),
        'motionTracking': motionTracking.toJson(),
        'retouch': retouch.toJson(),
        'parallax3d': parallax3d.toJson(),
        'stabilization': stabilization.toJson(),
        'vocalIsolation': vocalIsolation.toJson(),
        'colorMatch': colorMatch.toJson(),
        'relight': relight.toJson(),
        'denoise': denoise.toJson(),
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
        chromaKey: json['chromaKey'] != null
            ? ChromaKeyConfig.fromJson(json['chromaKey'] as Map<String, dynamic>)
            : const ChromaKeyConfig(),
        imageOverlay: json['imageOverlay'] != null
            ? ImageOverlayConfig.fromJson(json['imageOverlay'] as Map<String, dynamic>)
            : const ImageOverlayConfig(),
        characterHighlight: json['characterHighlight'] != null
            ? CharacterHighlightConfig.fromJson(
                json['characterHighlight'] as Map<String, dynamic>)
            : const CharacterHighlightConfig(),
        characterZoom: json['characterZoom'] != null
            ? CharacterZoomConfig.fromJson(
                json['characterZoom'] as Map<String, dynamic>)
            : const CharacterZoomConfig(),
        border: json['border'] != null
            ? VideoBorderConfig.fromJson(json['border'] as Map<String, dynamic>)
            : const VideoBorderConfig(),
        headerFooter: json['headerFooter'] != null
            ? HeaderFooterConfig.fromJson(json['headerFooter'] as Map<String, dynamic>)
            : const HeaderFooterConfig(),
        hdConverter: json['hdConverter'] != null
            ? HdConverterConfig.fromJson(json['hdConverter'] as Map<String, dynamic>)
            : const HdConverterConfig(),
        mask: json['mask'] != null
            ? MaskConfig.fromJson(json['mask'] as Map<String, dynamic>)
            : const MaskConfig(),
        blendMode: json['blendMode'] != null
            ? BlendModeConfig.fromJson(json['blendMode'] as Map<String, dynamic>)
            : const BlendModeConfig(),
        keyframes: (json['keyframes'] as List<dynamic>?)
                ?.map((k) => Keyframe.fromJson(k as Map<String, dynamic>))
                .toList() ??
            const [],
        isReversed: json['isReversed'] as bool? ?? false,
        isFreezeFrame: json['isFreezeFrame'] as bool? ?? false,
        freezeSourceMs: json['freezeSourceMs'] as int?,
        vfx: json['vfx'] != null
            ? VfxConfig.fromJson(json['vfx'] as Map<String, dynamic>)
            : const VfxConfig(),
        beatConfig: json['beatConfig'] != null
            ? BeatDetectionConfig.fromJson(json['beatConfig'] as Map<String, dynamic>)
            : const BeatDetectionConfig(),
        smartCutout: json['smartCutout'] != null
            ? SmartCutoutConfig.fromJson(json['smartCutout'] as Map<String, dynamic>)
            : const SmartCutoutConfig(),
        autoVelocity: json['autoVelocity'] != null
            ? AutoVelocityConfig.fromJson(json['autoVelocity'] as Map<String, dynamic>)
            : const AutoVelocityConfig(),
        kineticCaptions: json['kineticCaptions'] != null
            ? KineticCaptionsConfig.fromJson(json['kineticCaptions'] as Map<String, dynamic>)
            : const KineticCaptionsConfig(),
        motionTracking: json['motionTracking'] != null
            ? MotionTrackingConfig.fromJson(json['motionTracking'] as Map<String, dynamic>)
            : const MotionTrackingConfig(),
        retouch: json['retouch'] != null
            ? FaceRetouchConfig.fromJson(json['retouch'] as Map<String, dynamic>)
            : const FaceRetouchConfig(),
        parallax3d: json['parallax3d'] != null
            ? Parallax3DConfig.fromJson(json['parallax3d'] as Map<String, dynamic>)
            : const Parallax3DConfig(),
        stabilization: json['stabilization'] != null
            ? StabilizationConfig.fromJson(json['stabilization'] as Map<String, dynamic>)
            : const StabilizationConfig(),
        vocalIsolation: json['vocalIsolation'] != null
            ? VocalIsolationConfig.fromJson(json['vocalIsolation'] as Map<String, dynamic>)
            : const VocalIsolationConfig(),
        colorMatch: json['colorMatch'] != null
            ? ColorMatchConfig.fromJson(json['colorMatch'] as Map<String, dynamic>)
            : const ColorMatchConfig(),
        relight: json['relight'] != null
            ? RelightConfig.fromJson(json['relight'] as Map<String, dynamic>)
            : const RelightConfig(),
        denoise: json['denoise'] != null
            ? DenoiseConfig.fromJson(json['denoise'] as Map<String, dynamic>)
            : const DenoiseConfig(),
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
        chromaKey,
        imageOverlay,
        characterHighlight,
        characterZoom,
        border,
        headerFooter,
        hdConverter,
        mask,
        blendMode,
        keyframes,
        isReversed,
        isFreezeFrame,
        freezeSourceMs,
        vfx,
        beatConfig,
        smartCutout,
        autoVelocity,
        kineticCaptions,
        motionTracking,
        retouch,
        parallax3d,
        stabilization,
        vocalIsolation,
        colorMatch,
        relight,
        denoise,
      ];
}
