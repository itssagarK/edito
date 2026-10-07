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
import '../features/voice_effects/models/voice_effects_config.dart';
import '../features/edge_aura/models/edge_aura_config.dart';
import '../features/mosaic/models/mosaic_config.dart';
import '../features/object_removal/models/object_removal_config.dart';
import '../features/face_reshape/models/face_reshape_config.dart';
import '../features/color_wheels/models/color_wheels_config.dart';
import '../features/doodle/models/doodle_config.dart';
import '../features/curves/models/curves_config.dart';
import '../features/film_grain/models/film_grain_config.dart';
import '../features/vignette/models/vignette_config.dart';
import '../features/transform/models/video_transform_config.dart';
import '../features/image_editor/models/ken_burns_config.dart';
import '../features/audio/models/audio_fade_config.dart';
import '../features/vfx/models/impact_flash_config.dart';
import '../features/speed/models/speed_ease_config.dart';
import '../features/audio/models/spatial_audio_pan_config.dart';
import '../features/overlays/models/typewriter_title_config.dart';
import '../features/vfx/models/crt_scanline_config.dart';
import '../features/audio/models/reverb_chamber_config.dart';
import '../features/vfx/models/anamorphic_flare_config.dart';
import '../features/vfx/models/film_halation_config.dart';
import '../features/audio/models/tape_cassette_config.dart';
import '../features/vfx/models/camera_shake_config.dart';
import '../features/vfx/models/lens_distortion_config.dart';
import '../features/audio/models/vinyl_record_config.dart';
import '../features/vfx/models/light_leak_config.dart';
import '../features/vfx/models/night_vision_config.dart';
import '../features/audio/models/bitcrusher_config.dart';
import '../features/vfx/models/kaleidoscope_config.dart';
import '../features/vfx/models/datamosh_glitch_config.dart';
import '../features/audio/models/tremolo_wah_config.dart';
import '../features/vfx/models/tilt_shift_config.dart';
import '../features/vfx/models/neon_glow_config.dart';
import '../features/audio/models/pitch_harmonizer_config.dart';
import '../features/vfx/models/chromatic_aberration_config.dart';
import '../features/vfx/models/solarize_invert_config.dart';
import '../features/audio/models/audio_stutter_config.dart';
import '../features/vfx/models/pixel_sort_config.dart';
import '../features/vfx/models/posterize_pop_config.dart';
import '../features/audio/models/jet_flanger_config.dart';
import '../features/vfx/models/luma_key_config.dart';
import '../features/vfx/models/matrix_rain_config.dart';
import '../features/audio/models/ring_modulator_config.dart';

class Clip extends Equatable {
  final String id;
  final String assetId;
  final String trackId;
  final String sourcePath;
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
  final VoiceEffectsConfig voiceEffects;
  final EdgeAuraConfig edgeAura;
  final MosaicConfig mosaic;
  final ObjectRemovalConfig objectRemoval;
  final FaceReshapeConfig faceReshape;
  final ColorWheelsConfig colorWheels;
  final DoodleConfig doodle;
  final CurvesConfig curves;
  final FilmGrainConfig filmGrain;
  final VignetteConfig vignette;
  final VideoTransformConfig transform;
  final KenBurnsConfig kenBurns;
  final AudioFadeConfig audioFade;
  final ImpactFlashConfig impactFlash;
  final SpeedEaseConfig speedEase;
  final SpatialAudioPanConfig spatialPan;
  final TypewriterTitleConfig typewriterTitle;
  final CrtScanlineConfig crtScanline;
  final ReverbChamberConfig reverb;
  final AnamorphicFlareConfig anamorphicFlare;
  final FilmHalationConfig filmHalation;
  final TapeCassetteConfig tapeCassette;
  final CameraShakeConfig cameraShake;
  final LensDistortionConfig lensDistortion;
  final VinylRecordConfig vinylRecord;
  final LightLeakConfig lightLeak;
  final NightVisionConfig nightVision;
  final BitcrusherConfig bitcrusher;
  final KaleidoscopeConfig kaleidoscope;
  final DatamoshGlitchConfig datamoshGlitch;
  final TremoloWahConfig tremoloWah;
  final TiltShiftConfig tiltShift;
  final NeonGlowConfig neonGlow;
  final PitchHarmonizerConfig pitchHarmonizer;
  final ChromaticAberrationConfig chromaticAberration;
  final SolarizeInvertConfig solarizeInvert;
  final AudioStutterConfig audioStutter;
  final PixelSortConfig pixelSort;
  final PosterizePopConfig posterizePop;
  final JetFlangerConfig jetFlanger;
  final LumaKeyConfig lumaKey;
  final MatrixRainConfig matrixRain;
  final RingModulatorConfig ringModulator;

  const Clip({
    required this.id,
    required this.assetId,
    required this.trackId,
    this.sourcePath = '',
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
    this.voiceEffects = const VoiceEffectsConfig(),
    this.edgeAura = const EdgeAuraConfig(),
    this.mosaic = const MosaicConfig(),
    this.objectRemoval = const ObjectRemovalConfig(),
    this.faceReshape = const FaceReshapeConfig(),
    this.colorWheels = const ColorWheelsConfig(),
    this.doodle = const DoodleConfig(),
    this.curves = const CurvesConfig(),
    this.filmGrain = const FilmGrainConfig(),
    this.vignette = const VignetteConfig(),
    this.transform = const VideoTransformConfig(),
    this.kenBurns = const KenBurnsConfig(),
    this.audioFade = const AudioFadeConfig(),
    this.impactFlash = const ImpactFlashConfig(),
    this.speedEase = const SpeedEaseConfig(),
    this.spatialPan = const SpatialAudioPanConfig(),
    this.typewriterTitle = const TypewriterTitleConfig(),
    this.crtScanline = const CrtScanlineConfig(),
    this.reverb = const ReverbChamberConfig(),
    this.anamorphicFlare = const AnamorphicFlareConfig(),
    this.filmHalation = const FilmHalationConfig(),
    this.tapeCassette = const TapeCassetteConfig(),
    this.cameraShake = const CameraShakeConfig(),
    this.lensDistortion = const LensDistortionConfig(),
    this.vinylRecord = const VinylRecordConfig(),
    this.lightLeak = const LightLeakConfig(),
    this.nightVision = const NightVisionConfig(),
    this.bitcrusher = const BitcrusherConfig(),
    this.kaleidoscope = const KaleidoscopeConfig(),
    this.datamoshGlitch = const DatamoshGlitchConfig(),
    this.tremoloWah = const TremoloWahConfig(),
    this.tiltShift = const TiltShiftConfig(),
    this.neonGlow = const NeonGlowConfig(),
    this.pitchHarmonizer = const PitchHarmonizerConfig(),
    this.chromaticAberration = const ChromaticAberrationConfig(),
    this.solarizeInvert = const SolarizeInvertConfig(),
    this.audioStutter = const AudioStutterConfig(),
    this.pixelSort = const PixelSortConfig(),
    this.posterizePop = const PosterizePopConfig(),
    this.jetFlanger = const JetFlangerConfig(),
    this.lumaKey = const LumaKeyConfig(),
    this.matrixRain = const MatrixRainConfig(),
    this.ringModulator = const RingModulatorConfig(),
  });

  Clip copyWith({
    String? id,
    String? assetId,
    String? trackId,
    String? sourcePath,
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
    VoiceEffectsConfig? voiceEffects,
    EdgeAuraConfig? edgeAura,
    MosaicConfig? mosaic,
    ObjectRemovalConfig? objectRemoval,
    FaceReshapeConfig? faceReshape,
    ColorWheelsConfig? colorWheels,
    DoodleConfig? doodle,
    CurvesConfig? curves,
    FilmGrainConfig? filmGrain,
    VignetteConfig? vignette,
    VideoTransformConfig? transform,
    KenBurnsConfig? kenBurns,
    AudioFadeConfig? audioFade,
    ImpactFlashConfig? impactFlash,
    SpeedEaseConfig? speedEase,
    SpatialAudioPanConfig? spatialPan,
    TypewriterTitleConfig? typewriterTitle,
    CrtScanlineConfig? crtScanline,
    ReverbChamberConfig? reverb,
    AnamorphicFlareConfig? anamorphicFlare,
    FilmHalationConfig? filmHalation,
    TapeCassetteConfig? tapeCassette,
    CameraShakeConfig? cameraShake,
    LensDistortionConfig? lensDistortion,
    VinylRecordConfig? vinylRecord,
    LightLeakConfig? lightLeak,
    NightVisionConfig? nightVision,
    BitcrusherConfig? bitcrusher,
    KaleidoscopeConfig? kaleidoscope,
    DatamoshGlitchConfig? datamoshGlitch,
    TremoloWahConfig? tremoloWah,
    TiltShiftConfig? tiltShift,
    NeonGlowConfig? neonGlow,
    PitchHarmonizerConfig? pitchHarmonizer,
    ChromaticAberrationConfig? chromaticAberration,
    SolarizeInvertConfig? solarizeInvert,
    AudioStutterConfig? audioStutter,
    PixelSortConfig? pixelSort,
    PosterizePopConfig? posterizePop,
    JetFlangerConfig? jetFlanger,
    LumaKeyConfig? lumaKey,
    MatrixRainConfig? matrixRain,
    RingModulatorConfig? ringModulator,
  }) {
    return Clip(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      trackId: trackId ?? this.trackId,
      sourcePath: sourcePath ?? this.sourcePath,
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
      voiceEffects: voiceEffects ?? this.voiceEffects,
      edgeAura: edgeAura ?? this.edgeAura,
      mosaic: mosaic ?? this.mosaic,
      objectRemoval: objectRemoval ?? this.objectRemoval,
      faceReshape: faceReshape ?? this.faceReshape,
      colorWheels: colorWheels ?? this.colorWheels,
      doodle: doodle ?? this.doodle,
      curves: curves ?? this.curves,
      filmGrain: filmGrain ?? this.filmGrain,
      vignette: vignette ?? this.vignette,
      transform: transform ?? this.transform,
      kenBurns: kenBurns ?? this.kenBurns,
      audioFade: audioFade ?? this.audioFade,
      impactFlash: impactFlash ?? this.impactFlash,
      speedEase: speedEase ?? this.speedEase,
      spatialPan: spatialPan ?? this.spatialPan,
      typewriterTitle: typewriterTitle ?? this.typewriterTitle,
      crtScanline: crtScanline ?? this.crtScanline,
      reverb: reverb ?? this.reverb,
      anamorphicFlare: anamorphicFlare ?? this.anamorphicFlare,
      filmHalation: filmHalation ?? this.filmHalation,
      tapeCassette: tapeCassette ?? this.tapeCassette,
      cameraShake: cameraShake ?? this.cameraShake,
      lensDistortion: lensDistortion ?? this.lensDistortion,
      vinylRecord: vinylRecord ?? this.vinylRecord,
      lightLeak: lightLeak ?? this.lightLeak,
      nightVision: nightVision ?? this.nightVision,
      bitcrusher: bitcrusher ?? this.bitcrusher,
      kaleidoscope: kaleidoscope ?? this.kaleidoscope,
      datamoshGlitch: datamoshGlitch ?? this.datamoshGlitch,
      tremoloWah: tremoloWah ?? this.tremoloWah,
      tiltShift: tiltShift ?? this.tiltShift,
      neonGlow: neonGlow ?? this.neonGlow,
      pitchHarmonizer: pitchHarmonizer ?? this.pitchHarmonizer,
      chromaticAberration: chromaticAberration ?? this.chromaticAberration,
      solarizeInvert: solarizeInvert ?? this.solarizeInvert,
      audioStutter: audioStutter ?? this.audioStutter,
      pixelSort: pixelSort ?? this.pixelSort,
      posterizePop: posterizePop ?? this.posterizePop,
      jetFlanger: jetFlanger ?? this.jetFlanger,
      lumaKey: lumaKey ?? this.lumaKey,
      matrixRain: matrixRain ?? this.matrixRain,
      ringModulator: ringModulator ?? this.ringModulator,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetId': assetId,
        'trackId': trackId,
        if (sourcePath.isNotEmpty) 'sourcePath': sourcePath,
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
        'voiceEffects': voiceEffects.toJson(),
        'edgeAura': edgeAura.toJson(),
        'mosaic': mosaic.toJson(),
        'objectRemoval': objectRemoval.toJson(),
        'faceReshape': faceReshape.toJson(),
        'colorWheels': colorWheels.toJson(),
        'doodle': doodle.toJson(),
        'curves': curves.toJson(),
        'filmGrain': filmGrain.toJson(),
        'vignette': vignette.toJson(),
        'transform': transform.toJson(),
        'kenBurns': kenBurns.toJson(),
        'audioFade': audioFade.toJson(),
        'impactFlash': impactFlash.toJson(),
        'speedEase': speedEase.toJson(),
        'spatialPan': spatialPan.toJson(),
        'typewriterTitle': typewriterTitle.toJson(),
        'crtScanline': crtScanline.toJson(),
        'reverb': reverb.toJson(),
        'anamorphicFlare': anamorphicFlare.toJson(),
        'filmHalation': filmHalation.toJson(),
        'tapeCassette': tapeCassette.toJson(),
        'cameraShake': cameraShake.toJson(),
        'lensDistortion': lensDistortion.toJson(),
        'vinylRecord': vinylRecord.toJson(),
        'lightLeak': lightLeak.toJson(),
        'nightVision': nightVision.toJson(),
        'bitcrusher': bitcrusher.toJson(),
        'kaleidoscope': kaleidoscope.toJson(),
        'datamoshGlitch': datamoshGlitch.toJson(),
        'tremoloWah': tremoloWah.toJson(),
        'tiltShift': tiltShift.toJson(),
        'neonGlow': neonGlow.toJson(),
        'pitchHarmonizer': pitchHarmonizer.toJson(),
        'chromaticAberration': chromaticAberration.toJson(),
        'solarizeInvert': solarizeInvert.toJson(),
        'audioStutter': audioStutter.toJson(),
        'pixelSort': pixelSort.toJson(),
        'posterizePop': posterizePop.toJson(),
        'jetFlanger': jetFlanger.toJson(),
        'lumaKey': lumaKey.toJson(),
        'matrixRain': matrixRain.toJson(),
        'ringModulator': ringModulator.toJson(),
      };

  factory Clip.fromJson(Map<String, dynamic> json) => Clip(
        id: json['id'] as String,
        assetId: json['assetId'] as String,
        trackId: json['trackId'] as String,
        sourcePath: json['sourcePath'] as String? ?? '',
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
        voiceEffects: json['voiceEffects'] != null
            ? VoiceEffectsConfig.fromJson(json['voiceEffects'] as Map<String, dynamic>)
            : const VoiceEffectsConfig(),
        edgeAura: json['edgeAura'] != null
            ? EdgeAuraConfig.fromJson(json['edgeAura'] as Map<String, dynamic>)
            : const EdgeAuraConfig(),
        mosaic: json['mosaic'] != null
            ? MosaicConfig.fromJson(json['mosaic'] as Map<String, dynamic>)
            : const MosaicConfig(),
        objectRemoval: json['objectRemoval'] != null
            ? ObjectRemovalConfig.fromJson(json['objectRemoval'] as Map<String, dynamic>)
            : const ObjectRemovalConfig(),
        faceReshape: json['faceReshape'] != null
            ? FaceReshapeConfig.fromJson(json['faceReshape'] as Map<String, dynamic>)
            : const FaceReshapeConfig(),
        colorWheels: json['colorWheels'] != null
            ? ColorWheelsConfig.fromJson(json['colorWheels'] as Map<String, dynamic>)
            : const ColorWheelsConfig(),
        doodle: json['doodle'] != null
            ? DoodleConfig.fromJson(json['doodle'] as Map<String, dynamic>)
            : const DoodleConfig(),
        curves: json['curves'] != null
            ? CurvesConfig.fromJson(json['curves'] as Map<String, dynamic>)
            : const CurvesConfig(),
        filmGrain: json['filmGrain'] != null
            ? FilmGrainConfig.fromJson(json['filmGrain'] as Map<String, dynamic>)
            : const FilmGrainConfig(),
        vignette: json['vignette'] != null
            ? VignetteConfig.fromJson(json['vignette'] as Map<String, dynamic>)
            : const VignetteConfig(),
        transform: json['transform'] != null
            ? VideoTransformConfig.fromJson(json['transform'] as Map<String, dynamic>)
            : const VideoTransformConfig(),
        kenBurns: json['kenBurns'] != null
            ? KenBurnsConfig.fromJson(json['kenBurns'] as Map<String, dynamic>)
            : const KenBurnsConfig(),
        audioFade: json['audioFade'] != null
            ? AudioFadeConfig.fromJson(json['audioFade'] as Map<String, dynamic>)
            : const AudioFadeConfig(),
        impactFlash: json['impactFlash'] != null
            ? ImpactFlashConfig.fromJson(json['impactFlash'] as Map<String, dynamic>)
            : const ImpactFlashConfig(),
        speedEase: json['speedEase'] != null
            ? SpeedEaseConfig.fromJson(json['speedEase'] as Map<String, dynamic>)
            : const SpeedEaseConfig(),
        spatialPan: json['spatialPan'] != null
            ? SpatialAudioPanConfig.fromJson(json['spatialPan'] as Map<String, dynamic>)
            : const SpatialAudioPanConfig(),
        typewriterTitle: json['typewriterTitle'] != null
            ? TypewriterTitleConfig.fromJson(json['typewriterTitle'] as Map<String, dynamic>)
            : const TypewriterTitleConfig(),
        crtScanline: json['crtScanline'] != null
            ? CrtScanlineConfig.fromJson(json['crtScanline'] as Map<String, dynamic>)
            : const CrtScanlineConfig(),
        reverb: json['reverb'] != null
            ? ReverbChamberConfig.fromJson(json['reverb'] as Map<String, dynamic>)
            : const ReverbChamberConfig(),
        anamorphicFlare: json['anamorphicFlare'] != null
            ? AnamorphicFlareConfig.fromJson(json['anamorphicFlare'] as Map<String, dynamic>)
            : const AnamorphicFlareConfig(),
        filmHalation: json['filmHalation'] != null
            ? FilmHalationConfig.fromJson(json['filmHalation'] as Map<String, dynamic>)
            : const FilmHalationConfig(),
        tapeCassette: json['tapeCassette'] != null
            ? TapeCassetteConfig.fromJson(json['tapeCassette'] as Map<String, dynamic>)
            : const TapeCassetteConfig(),
        cameraShake: json['cameraShake'] != null
            ? CameraShakeConfig.fromJson(json['cameraShake'] as Map<String, dynamic>)
            : const CameraShakeConfig(),
        lensDistortion: json['lensDistortion'] != null
            ? LensDistortionConfig.fromJson(json['lensDistortion'] as Map<String, dynamic>)
            : const LensDistortionConfig(),
        vinylRecord: json['vinylRecord'] != null
            ? VinylRecordConfig.fromJson(json['vinylRecord'] as Map<String, dynamic>)
            : const VinylRecordConfig(),
        lightLeak: json['lightLeak'] != null
            ? LightLeakConfig.fromJson(json['lightLeak'] as Map<String, dynamic>)
            : const LightLeakConfig(),
        nightVision: json['nightVision'] != null
            ? NightVisionConfig.fromJson(json['nightVision'] as Map<String, dynamic>)
            : const NightVisionConfig(),
        bitcrusher: json['bitcrusher'] != null
            ? BitcrusherConfig.fromJson(json['bitcrusher'] as Map<String, dynamic>)
            : const BitcrusherConfig(),
        kaleidoscope: json['kaleidoscope'] != null
            ? KaleidoscopeConfig.fromJson(json['kaleidoscope'] as Map<String, dynamic>)
            : const KaleidoscopeConfig(),
        datamoshGlitch: json['datamoshGlitch'] != null
            ? DatamoshGlitchConfig.fromJson(json['datamoshGlitch'] as Map<String, dynamic>)
            : const DatamoshGlitchConfig(),
        tremoloWah: json['tremoloWah'] != null
            ? TremoloWahConfig.fromJson(json['tremoloWah'] as Map<String, dynamic>)
            : const TremoloWahConfig(),
        tiltShift: json['tiltShift'] != null
            ? TiltShiftConfig.fromJson(json['tiltShift'] as Map<String, dynamic>)
            : const TiltShiftConfig(),
        neonGlow: json['neonGlow'] != null
            ? NeonGlowConfig.fromJson(json['neonGlow'] as Map<String, dynamic>)
            : const NeonGlowConfig(),
        pitchHarmonizer: json['pitchHarmonizer'] != null
            ? PitchHarmonizerConfig.fromJson(json['pitchHarmonizer'] as Map<String, dynamic>)
            : const PitchHarmonizerConfig(),
        chromaticAberration: json['chromaticAberration'] != null
            ? ChromaticAberrationConfig.fromJson(json['chromaticAberration'] as Map<String, dynamic>)
            : const ChromaticAberrationConfig(),
        solarizeInvert: json['solarizeInvert'] != null
            ? SolarizeInvertConfig.fromJson(json['solarizeInvert'] as Map<String, dynamic>)
            : const SolarizeInvertConfig(),
        audioStutter: json['audioStutter'] != null
            ? AudioStutterConfig.fromJson(json['audioStutter'] as Map<String, dynamic>)
            : const AudioStutterConfig(),
        pixelSort: json['pixelSort'] != null
            ? PixelSortConfig.fromJson(json['pixelSort'] as Map<String, dynamic>)
            : const PixelSortConfig(),
        posterizePop: json['posterizePop'] != null
            ? PosterizePopConfig.fromJson(json['posterizePop'] as Map<String, dynamic>)
            : const PosterizePopConfig(),
        jetFlanger: json['jetFlanger'] != null
            ? JetFlangerConfig.fromJson(json['jetFlanger'] as Map<String, dynamic>)
            : const JetFlangerConfig(),
        lumaKey: json['lumaKey'] != null
            ? LumaKeyConfig.fromJson(json['lumaKey'] as Map<String, dynamic>)
            : const LumaKeyConfig(),
        matrixRain: json['matrixRain'] != null
            ? MatrixRainConfig.fromJson(json['matrixRain'] as Map<String, dynamic>)
            : const MatrixRainConfig(),
        ringModulator: json['ringModulator'] != null
            ? RingModulatorConfig.fromJson(json['ringModulator'] as Map<String, dynamic>)
            : const RingModulatorConfig(),
      );

  @override
  List<Object?> get props => [
        id,
        assetId,
        trackId,
        sourcePath,
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
        voiceEffects,
        edgeAura,
        mosaic,
        objectRemoval,
        faceReshape,
        colorWheels,
        doodle,
        curves,
        filmGrain,
        vignette,
        transform,
        kenBurns,
        audioFade,
        impactFlash,
        speedEase,
        spatialPan,
        typewriterTitle,
        crtScanline,
        reverb,
        anamorphicFlare,
        filmHalation,
        tapeCassette,
        cameraShake,
        lensDistortion,
        vinylRecord,
        lightLeak,
        nightVision,
        bitcrusher,
        kaleidoscope,
        datamoshGlitch,
        tremoloWah,
        tiltShift,
        neonGlow,
        pitchHarmonizer,
        chromaticAberration,
        solarizeInvert,
        audioStutter,
        pixelSort,
        posterizePop,
        jetFlanger,
        lumaKey,
        matrixRain,
        ringModulator,
      ];
}
