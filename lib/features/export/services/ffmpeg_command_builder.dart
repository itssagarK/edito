import '../../../models/clip.dart';
import '../../../models/media_asset.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import '../../audio/services/ai_voice_enhancer_service.dart';
import '../../audio/services/audio_ducking_service.dart';
import '../../borders/services/video_border_compiler_service.dart';
import '../../character_zoom/services/character_zoom_compiler_service.dart';
import '../../chroma/services/chroma_key_compiler_service.dart';
import '../../color_grading/services/color_filter_compiler_service.dart';
import '../../enhancement/services/ai_video_enhancer_service.dart';
import '../../hd_converter/services/hd_converter_service.dart';
import '../../header_footer/services/header_footer_compiler_service.dart';
import '../../highlight/services/character_highlight_compiler_service.dart';
import '../../blending/services/blend_mode_compiler_service.dart';
import '../../keyframes/services/keyframe_evaluator_service.dart';
import '../../masking/services/mask_compiler_service.dart';
import '../../overlays/services/overlay_compiler_service.dart';
import '../../smoothing/services/ai_video_smoother_service.dart';
import '../../speed/services/speed_ramping_service.dart';
import '../../transitions/models/transition_type.dart';
import '../../transitions/services/transition_compiler_service.dart';
import '../../vfx/services/vfx_compiler_service.dart';
import '../../image_editor/services/auto_reframe_service.dart';
import '../../image_editor/services/pip_compiler_service.dart';
import '../models/export_preset.dart';

class FFmpegCommandBuilder {
  /// Alias for buildArguments
  static List<String> build(Project project, ExportConfiguration config) => buildArguments(project, config);

  /// Builds the complete list of FFmpeg command-line arguments for rendering the project
  static List<String> buildArguments(Project project, ExportConfiguration config) {
    final args = <String>[];

    // 1. Gather all unique media assets used in clips
    final usedAssetIds = <String>{};
    for (final track in project.tracks) {
      for (final clip in track.clips) {
        if (clip.assetId.isNotEmpty) {
          usedAssetIds.add(clip.assetId);
        }
      }
    }

    final inputAssets = project.assets.where((a) => usedAssetIds.contains(a.id)).toList();
    final assetIndexMap = <String, int>{};

    for (int i = 0; i < inputAssets.length; i++) {
      assetIndexMap[inputAssets[i].id] = i;
      args.addAll(['-i', inputAssets[i].path]);
    }

    // If no assets, create a black video generator fallback
    if (inputAssets.isEmpty) {
      args.addAll([
        '-f', 'lavfi', '-i',
        'color=c=black:s=${config.resolution.width}x${config.resolution.height}:r=${config.framerate.fpsValue}:d=${(project.durationMs / 1000.0).clamp(1.0, 3600.0)}',
        '-f', 'lavfi', '-i',
        'anullsrc=r=44100:cl=stereo',
        '-c:v', config.codec.ffmpegEncoder,
        '-c:a', 'aac',
        '-y', config.outputPath,
      ]);
      return args;
    }

    // 2. Build Filter Complex
    final filterComplexSegments = <String>[];
    final audioStreamLabels = <String>[];

    final targetW = config.resolution.width;
    final targetH = config.resolution.height;

    // Timeline project duration (max of all track end times, not sum of clips)
    int maxTimelineMs = project.durationMs > 0 ? project.durationMs : 0;
    for (final track in project.tracks) {
      if (track.isHidden) continue;
      for (final clip in track.clips) {
        final endMs = clip.startTimeMs + clip.durationMs;
        if (endMs > maxTimelineMs) {
          maxTimelineMs = endMs;
        }
      }
    }
    if (maxTimelineMs <= 0) maxTimelineMs = 10000;
    final totalDurationSec = (maxTimelineMs / 1000.0).toStringAsFixed(3);

    final videoTracks = project.tracks
        .where((t) => t.type == TrackType.video && !t.isHidden && t.clips.isNotEmpty)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    int clipCounter = 0;
    final trackOutputLabels = <String>[];

    for (int tIdx = 0; tIdx < videoTracks.length; tIdx++) {
      final track = videoTracks[tIdx];
      final trackClipLabels = <String>[];

      for (final clip in track.clips) {
        final inputIdx = assetIndexMap[clip.assetId] ?? 0;
        final startSec = (clip.sourceInMs / 1000.0).toStringAsFixed(3);
        final endSec = (clip.sourceOutMs / 1000.0).toStringAsFixed(3);
        final speed = clip.speed;
        final vLabel = 'v$clipCounter';

        final vFilters = <String>[];
        if (clip.isFreezeFrame) {
          final freezeSec = ((clip.freezeSourceMs ?? clip.sourceInMs) / 1000.0).toStringAsFixed(3);
          final freezeDurationSec = (clip.durationMs / 1000.0).toStringAsFixed(3);
          vFilters.add('trim=start=$freezeSec:duration=0.04');
          vFilters.add('fps=fps=${config.framerate.fpsValue}:round=near');
          vFilters.add('tpad=stop_mode=clone:stop_duration=$freezeDurationSec');
          vFilters.add('trim=duration=$freezeDurationSec');
          final timelineStartSec = clip.startTimeMs / 1000.0;
          if (tIdx > 0 && timelineStartSec > 0.0) {
            vFilters.add('setpts=PTS-STARTPTS+(${timelineStartSec.toStringAsFixed(3)}/TB)');
          } else {
            vFilters.add('setpts=PTS-STARTPTS');
          }
        } else {
          vFilters.add('trim=start=$startSec:end=$endSec');
          vFilters.add('fps=fps=${config.framerate.fpsValue}:round=near');
          if (clip.isReversed) {
            vFilters.add('reverse');
          }
          final timelineStartSec = clip.startTimeMs / 1000.0;
          if (tIdx > 0 && timelineStartSec > 0.0) {
            vFilters.add('setpts=PTS-STARTPTS+(${timelineStartSec.toStringAsFixed(3)}/TB)');
          } else {
            vFilters.add('setpts=PTS-STARTPTS');
          }
          final speedFilters = SpeedRampingService.generateFFmpegVideoSpeedFilters(
            clip.speedCurve,
            clip.speed,
            targetFps: config.framerate.fpsValue,
          );
          if (speedFilters.isNotEmpty) {
            vFilters.addAll(speedFilters);
          }
        }

        // Chroma Key / Green Screen Removal (applied BEFORE scale/pad so native resolution pixels are keyed without Lanczos interpolation fringing)
        if (clip.chromaKey.isEnabled) {
          final chromaFilters = ChromaKeyCompilerService.generateFFmpegFilters(clip.chromaKey);
          vFilters.addAll(chromaFilters);
        } else if (tIdx > 0) {
          // Upper track - convert to yuva420p before padding so letterbox/pillarbox areas are transparent
          vFilters.add('format=yuva420p');
        }

        // Auto-Reframing & Video Layout Canvas Framing
        final layoutFilter = AutoReframeService.generateFFmpegFilter(
          layout: project.layoutConfig,
          targetWidth: targetW,
          targetHeight: targetH,
          trackIndex: tIdx,
        );
        if (layoutFilter.isNotEmpty) {
          vFilters.add(layoutFilter);
        }
        vFilters.add('setsar=1');

        // Color Grading & Looks filter
        final colorFilter = ColorFilterCompilerService.generateFFmpegFilter(clip.colorGrading);
        if (colorFilter.isNotEmpty) {
          vFilters.add(colorFilter);
        }

        // Text Titles & DrawText Burn-In (clip-relative coordinates, resolution-scaled font)
        final drawTextFilter = OverlayCompilerService.generateFFmpegDrawText(
          clip,
          clip.textOverlay,
          isClipRelative: true,
          outputHeight: targetH,
          referenceHeight: 720,
        );
        if (drawTextFilter.isNotEmpty) {
          vFilters.add(drawTextFilter);
        }

        // Picture-in-Picture (PiP) & Media Overlays
        if (clip.imageOverlay.isEnabled) {
          final pipFilter = PipCompilerService.generateFFmpegOverlayFilter(
            clip.imageOverlay,
            targetWidth: targetW,
            targetHeight: targetH,
          );
          if (pipFilter.isNotEmpty) {
            vFilters.add(pipFilter);
          }
        }

        // 8K AI Enhancement Filters (Upscaling, Sharpening, Denoising, HDR)
        final enhancementFilters = AIVideoEnhancerService.generateFFmpegFilters(
          clip.enhancement,
          targetWidth: targetW,
          targetHeight: targetH,
        );
        if (enhancementFilters.isNotEmpty) {
          vFilters.addAll(enhancementFilters);
        }

        // Video Smoother, Anti-Flutter, & Frame Interpolation
        final smootherFilters = AIVideoSmootherService.generateFFmpegFilters(clip.smoother);
        if (smootherFilters.isNotEmpty) {
          vFilters.addAll(smootherFilters);
        }

        // Character Highlight & Background Color Customizer
        if (clip.characterHighlight.isEnabled) {
          final highlightFilter = CharacterHighlightCompilerService.generateFFmpegFilter(
            clip.characterHighlight,
            targetWidth: targetW,
            targetHeight: targetH,
          );
          if (highlightFilter.isNotEmpty) {
            vFilters.add(highlightFilter);
          }
        }

        // Main Character Zoom-In & Focus Framing
        if (clip.characterZoom.isEnabled) {
          final zoomFilter = CharacterZoomCompilerService.generateFFmpegFilter(
            clip.characterZoom,
            clipDurationMs: clip.durationMs,
            targetWidth: targetW,
            targetHeight: targetH,
          );
          if (zoomFilter.isNotEmpty) {
            vFilters.add(zoomFilter);
          }
        }

        // Cinematic Motion VFX & Visual Effects
        if (clip.vfx.isActive) {
          final vfxFilters = VfxCompilerService.generateFFmpegFilters(clip.vfx);
          if (vfxFilters.isNotEmpty) {
            vFilters.addAll(vfxFilters);
          }
        }

        // Borders & Frames (solid, neon glow, gradient, 35mm film, polaroid, letterbox, retro TV)
        if (clip.border.isEnabled) {
          final borderFilter = VideoBorderCompilerService.generateFFmpegFilter(
            clip.border,
            targetWidth: targetW,
            targetHeight: targetH,
          );
          if (borderFilter.isNotEmpty) {
            vFilters.add(borderFilter);
          }
        }

        // Header & Footer Burn-in Banners
        if (clip.headerFooter.hasActiveOverlay) {
          final headerFooterFilter = HeaderFooterCompilerService.generateFFmpegFilter(
            clip.headerFooter,
            clipDurationMs: clip.durationMs,
            targetWidth: targetW,
            targetHeight: targetH,
          );
          if (headerFooterFilter.isNotEmpty) {
            vFilters.add(headerFooterFilter);
          }
        }

        // HD Video Converter & Detail Upscaler
        if (clip.hdConverter.isEnabled) {
          final hdFilters = HdConverterService.generateFFmpegFilters(
            clip.hdConverter,
            targetWidth: targetW,
            targetHeight: targetH,
          );
          if (hdFilters.isNotEmpty) {
            vFilters.addAll(hdFilters);
          }
        }

        // Multi-Shape Masking (Linear, Radial, Rectangle, Film Strip, Heart, Star)
        if (clip.mask.isActive) {
          final maskFilters = MaskCompilerService.generateFFmpegFilters(
            clip.mask,
            outputWidth: targetW,
            outputHeight: targetH,
          );
          if (maskFilters.isNotEmpty) {
            vFilters.addAll(maskFilters);
          }
        }

        // Pro Blending in-stream layer opacity
        if (clip.blendMode.isEnabled) {
          final blendFilters = BlendModeCompilerService.generateInStreamFilters(clip.blendMode);
          if (blendFilters.isNotEmpty) {
            vFilters.addAll(blendFilters);
          }
        }

        // Universal Keyframe Transforms (animated opacity, rotation, scale)
        if (clip.keyframes.isNotEmpty) {
          final kfFilters = KeyframeEvaluatorService.generateFFmpegTransformFilters(
            clip.keyframes,
            clipDurationMs: clip.durationMs,
            targetWidth: targetW,
            targetHeight: targetH,
          );
          if (kfFilters.isNotEmpty) {
            vFilters.addAll(kfFilters);
          }
        }

        filterComplexSegments.add('[$inputIdx:v]${vFilters.join(',')} [$vLabel]');
        trackClipLabels.add('[$vLabel]');
        clipCounter++;
      }

      // Track assembly: join clips within the same track
      String trackOutLabel;
      if (trackClipLabels.isEmpty) {
        continue;
      } else if (trackClipLabels.length == 1) {
        trackOutLabel = trackClipLabels[0];
      } else if (track.clips.any((c) => c.transitionIn.isEnabled)) {
        String cur = trackClipLabels[0];
        double cumulativeOffset = 0.0;
        for (int i = 1; i < trackClipLabels.length; i++) {
          final nextStream = trackClipLabels[i];
          final nextClip = track.clips[i];
          final trans = nextClip.transitionIn;
          final outLabel = i == trackClipLabels.length - 1 ? '[track_$tIdx]' : '[vtrans_${tIdx}_$i]';

          if (trans.isEnabled && trans.type.ffmpegXFadeName.isNotEmpty) {
            final prevClip = track.clips[i - 1];
            final prevSec = prevClip.durationMs / 1000.0;
            cumulativeOffset += prevSec - (trans.durationMs / 1000.0);
            final xfade = TransitionCompilerService.generateFFmpegXFade(
              trans,
              offsetSec: cumulativeOffset.clamp(0.1, 86400.0),
            );
            filterComplexSegments.add('$cur$nextStream $xfade $outLabel');
          } else {
            filterComplexSegments.add('$cur$nextStream concat=n=2:v=1:a=0 $outLabel');
          }
          cur = outLabel;
        }
        trackOutLabel = cur;
      } else {
        trackOutLabel = '[track_$tIdx]';
        filterComplexSegments.add('${trackClipLabels.join('')} concat=n=${trackClipLabels.length}:v=1:a=0 $trackOutLabel');
      }

      trackOutputLabels.add(trackOutLabel);
    }

    // Audio Chains across all tracks
    int audioClipCounter = 0;
    for (final track in project.tracks) {
      if (track.isHidden || track.isMuted) continue;
      for (final clip in track.clips) {
        if (clip.isMuted || clip.isFreezeFrame || clip.assetId.isEmpty) continue;

        // Conditional audio binding: check cached hasAudio on MediaAsset without re-probing
        final asset = project.assets.firstWhere(
          (a) => a.id == clip.assetId,
          orElse: () => const MediaAsset(id: '', path: '', fileName: '', type: MediaType.video, durationMs: 0),
        );
        if (!asset.hasAudio) continue;

        final inputIdx = assetIndexMap[clip.assetId] ?? 0;
        final startSec = (clip.sourceInMs / 1000.0).toStringAsFixed(3);
        final endSec = (clip.sourceOutMs / 1000.0).toStringAsFixed(3);
        final speed = clip.speed;

        final aLabel = 'a$audioClipCounter';
        final aFilters = <String>[
          'atrim=start=$startSec:end=$endSec',
        ];

        if (clip.isReversed) {
          aFilters.add('areverse');
        }

        final effectiveAudioSpeed = SpeedRampingService.calculateEffectiveAverageSpeed(clip.speedCurve, clip.speed);
        final audioSpeedFilter = SpeedRampingService.generateAudioSpeedFilter(
          effectiveAudioSpeed,
          enablePitchCorrection: clip.speedCurve.enablePitchCorrection,
        );
        if (audioSpeedFilter.isNotEmpty) {
          aFilters.add(audioSpeedFilter);
        }

        // Frame-accurate timeline synchronization: reset PTS then delay by clip.startTimeMs for amix alignment
        aFilters.add('asetpts=PTS-STARTPTS');
        if (clip.startTimeMs > 0) {
          aFilters.add('adelay=${clip.startTimeMs}|${clip.startTimeMs}:all=1');
        }

        final duckingFilter = AudioDuckingService.buildDuckingVolumeFilter(
          project: project,
          backgroundClip: clip,
          baseVolume: clip.volume,
        );

        final effectChain = AIVoiceEnhancerService.generateFFmpegFilter(
          clip.audioEffects,
          baseVolume: duckingFilter.isNotEmpty ? 1.0 : clip.volume,
          clipDurationMs: clip.durationMs,
        );

        if (duckingFilter.isNotEmpty) {
          aFilters.add(duckingFilter);
        }
        if (effectChain.isNotEmpty) {
          aFilters.add(effectChain);
        }

        // Format harmonization (48kHz sample rate, fltp, stereo)
        aFilters.add('aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo');

        filterComplexSegments.add('[$inputIdx:a]${aFilters.join(',')} [$aLabel]');
        audioStreamLabels.add('[$aLabel]');
        audioClipCounter++;
      }
    }

    // Multi-Track Video Layered Overlay Compositing
    String currentVideoStream;
    if (videoTracks.isEmpty) {
      filterComplexSegments.add('color=c=black:s=${targetW}x${targetH}:r=${config.framerate.fpsValue}:d=$totalDurationSec,setsar=1 [vbase]');
      currentVideoStream = '[vbase]';
    } else {
      currentVideoStream = trackOutputLabels[0]; // Track 0 renders first as the background canvas!
      for (int t = 1; t < trackOutputLabels.length; t++) {
        final upperTrackStream = trackOutputLabels[t];
        final upperTrackClips = videoTracks[t].clips;
        final minStart = upperTrackClips.map((c) => c.startTimeMs).reduce((a, b) => a < b ? a : b) / 1000.0;
        final maxEnd = upperTrackClips.map((c) => c.startTimeMs + c.durationMs).reduce((a, b) => a > b ? a : b) / 1000.0;
        final compLabel = '[vcomp$t]';

        // Check if upper track clips configure a custom blend mode
        final activeBlendClip = upperTrackClips.firstWhere(
          (c) => c.blendMode.isEnabled,
          orElse: () => upperTrackClips.first,
        );

        final compositorFilter = BlendModeCompilerService.generateFFmpegLayerCompositor(
          config: activeBlendClip.blendMode,
          baseLabel: currentVideoStream.replaceAll('[', '').replaceAll(']', ''),
          overlayLabel: upperTrackStream.replaceAll('[', '').replaceAll(']', ''),
          outputLabel: compLabel.replaceAll('[', '').replaceAll(']', ''),
          enableExpression: 'between(t,${minStart.toStringAsFixed(2)},${maxEnd.toStringAsFixed(2)})',
        );
        filterComplexSegments.add(compositorFilter);
        currentVideoStream = compLabel;
      }
    }

    // Burn-in overlay titles, captions & sticker badges from text/overlay tracks
    final hasOverlaysOrText = project.tracks
        .where((t) => !t.isHidden && (t.type == TrackType.text || t.type == TrackType.overlay))
        .any((t) => t.clips.any((c) =>
            c.textOverlay.text.trim().isNotEmpty ||
            (c.imageOverlay.isEnabled && c.imageOverlay.assetLabel.trim().isNotEmpty)));

    if (hasOverlaysOrText) {
      final overlayFilters = <String>[];
      for (final track in project.tracks) {
        if (track.isHidden) continue;
        if (track.type == TrackType.text || track.type == TrackType.overlay) {
          for (final clip in track.clips) {
            final drawText = OverlayCompilerService.generateFFmpegDrawText(
              clip,
              clip.textOverlay,
              isClipRelative: false,
              outputHeight: targetH,
              referenceHeight: 720,
            );
            if (drawText.isNotEmpty) {
              overlayFilters.add(drawText);
            }
            if (clip.imageOverlay.isEnabled && clip.imageOverlay.assetLabel.trim().isNotEmpty) {
              final sanitizedLabel = clip.imageOverlay.assetLabel.replaceAll("'", "\\'").replaceAll(':', '\\:');
              final posX = (clip.imageOverlay.positionX * 0.85).toStringAsFixed(2);
              final posY = (clip.imageOverlay.positionY * 0.85).toStringAsFixed(2);
              final startSec = (clip.startTimeMs / 1000.0).toStringAsFixed(2);
              final endSec = ((clip.startTimeMs + clip.durationMs) / 1000.0).toStringAsFixed(2);
              final scale = targetH / 720.0;
              final labelFontSize = (26 * scale).round().clamp(8, 300);
              final labelBoxBorder = (6 * scale).round().clamp(1, 50);
              overlayFilters.add("drawtext=text='$sanitizedLabel':enable='between(t,$startSec,$endSec)':x=w*$posX:y=h*$posY:fontsize=$labelFontSize:fontcolor=white:box=1:boxcolor=black@0.85:boxborderw=$labelBoxBorder");
            }
          }
        }
      }
      if (overlayFilters.isNotEmpty) {
        filterComplexSegments.add('$currentVideoStream ${overlayFilters.join(',')},format=yuv420p [vout]');
      } else {
        filterComplexSegments.add('$currentVideoStream format=yuv420p [vout]');
      }
    } else {
      filterComplexSegments.add('$currentVideoStream format=yuv420p [vout]');
    }

    if (audioStreamLabels.isNotEmpty) {
      filterComplexSegments.add(
        '${audioStreamLabels.join('')} amix=inputs=${audioStreamLabels.length}:normalize=0,alimiter=limit=0.95:attack=5:release=50:asc=1 [aout]',
      );
    }

    args.addAll(['-filter_complex', filterComplexSegments.join('; ')]);

    // 3. Map Outputs
    args.addAll(['-map', '[vout]']);
    if (audioStreamLabels.isNotEmpty) {
      args.addAll(['-map', '[aout]']);
    }

    // 4. Video & Audio Encoding Parameters
    final isH264 = config.codec == ExportCodec.h264;
    final crfValue = config.quality.crf;

    args.addAll([
      '-c:v', config.codec.ffmpegEncoder,
      '-preset', 'medium',
      '-crf', crfValue.toString(),
      '-pix_fmt', 'yuv420p',
      '-r', config.framerate.fpsValue.toString(),
    ]);

    if (isH264) {
      args.addAll([
        '-profile:v', 'high',
        '-level:v', '4.2',
        '-colorspace', 'bt709',
        '-color_primaries', 'bt709',
        '-color_trc', 'bt709',
      ]);
    } else {
      args.addAll([
        '-tag:v', 'hvc1',
      ]);
    }

    if (audioStreamLabels.isNotEmpty) {
      final audioBitrate = config.quality == ExportQuality.ultra
          ? '320k'
          : (config.quality == ExportQuality.high ? '256k' : '192k');
      args.addAll([
        '-c:a', 'aac',
        '-b:a', audioBitrate,
        '-ar', '48000',
        '-ac', '2',
      ]);
    }

    args.addAll([
      '-movflags', '+faststart',
      '-y', config.outputPath,
    ]);

    return args;
  }

  /// Formats the arguments into a single readable FFmpeg CLI command string
  static String buildCommandString(Project project, ExportConfiguration config) {
    final args = buildArguments(project, config);
    return 'ffmpeg ${args.map((a) => a.contains(' ') ? '"$a"' : a).join(' ')}';
  }
}
