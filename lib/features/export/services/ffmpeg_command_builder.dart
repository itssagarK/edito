import '../../../models/clip.dart';
import '../../../models/media_asset.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import '../../audio/services/ai_voice_enhancer_service.dart';
import '../../color_grading/services/color_filter_compiler_service.dart';
import '../../enhancement/services/ai_video_enhancer_service.dart';
import '../../overlays/services/overlay_compiler_service.dart';
import '../../smoothing/services/ai_video_smoother_service.dart';
import '../../transitions/models/transition_type.dart';
import '../../transitions/services/transition_compiler_service.dart';
import '../models/export_preset.dart';

class FFmpegCommandBuilder {
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
    final videoStreamLabels = <String>[];
    final audioStreamLabels = <String>[];

    final targetW = config.resolution.width;
    final targetH = config.resolution.height;

    int clipCounter = 0;

    for (final track in project.tracks) {
      if (track.isHidden) continue;

      for (final clip in track.clips) {
        final inputIdx = assetIndexMap[clip.assetId] ?? 0;
        final startSec = (clip.sourceInMs / 1000.0).toStringAsFixed(3);
        final endSec = (clip.sourceOutMs / 1000.0).toStringAsFixed(3);
        final speed = clip.speed;

        // Video Chain
        if (track.type == TrackType.video) {
          final vLabel = 'v$clipCounter';
          final vFilters = <String>[
            'trim=start=$startSec:end=$endSec',
            'setpts=PTS-STARTPTS',
          ];

          if (speed != 1.0) {
            vFilters.add('setpts=PTS/${speed.toStringAsFixed(2)}');
          }

          // Scale & Pad with Video Layout Canvas Framing & Background
          final layout = project.layoutConfig;
          final padPx = layout.framePadding.round();
          final innerW = (targetW - (padPx * 2)).clamp(32, targetW);
          final innerH = (targetH - (padPx * 2)).clamp(32, targetH);
          final bgHex = '0x${layout.backgroundColor.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

          vFilters.add('scale=$innerW:$innerH:force_original_aspect_ratio=decrease');
          vFilters.add('pad=$targetW:$targetH:(ow-iw)/2:(oh-ih)/2:color=$bgHex');
          vFilters.add('setsar=1');

          // Color Grading & Looks filter
          final colorFilter = ColorFilterCompilerService.generateFFmpegFilter(clip.colorGrading);
          if (colorFilter.isNotEmpty) {
            vFilters.add(colorFilter);
          }

          // Chroma Key / Green Screen Removal
          if (clip.chromaKey.isEnabled) {
            final hex = '0x${clip.chromaKey.keyColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
            vFilters.add('chromakey=color=$hex:similarity=${clip.chromaKey.similarity.toStringAsFixed(2)}:blend=${clip.chromaKey.smoothness.toStringAsFixed(2)}');
          }

          // Text Titles & DrawText Burn-In
          final drawTextFilter = OverlayCompilerService.generateFFmpegDrawText(clip, clip.textOverlay);
          if (drawTextFilter.isNotEmpty) {
            vFilters.add(drawTextFilter);
          }

          // Image Overlays & Creative Asset Sticker Badges
          if (clip.imageOverlay.isEnabled && clip.imageOverlay.assetLabel.trim().isNotEmpty) {
            final sanitizedLabel = clip.imageOverlay.assetLabel.replaceAll("'", "\\'").replaceAll(':', '\\:');
            final posX = (clip.imageOverlay.positionX * 0.85).toStringAsFixed(2);
            final posY = (clip.imageOverlay.positionY * 0.85).toStringAsFixed(2);
            final borderColorHex = '0x${clip.imageOverlay.borderColor.toRadixString(16).padLeft(8, '0').substring(2)}';
            vFilters.add("drawtext=text='$sanitizedLabel':x=w*$posX:y=h*$posY:fontsize=26:fontcolor=white:box=1:boxcolor=black@0.85:boxborderw=6");
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

          filterComplexSegments.add('[$inputIdx:v]${vFilters.join(',')} [$vLabel]');
          videoStreamLabels.add('[$vLabel]');
        }

        // Audio Chain
        if (!track.isMuted && !clip.isMuted) {
          final aLabel = 'a$clipCounter';
          final aFilters = <String>[
            'atrim=start=$startSec:end=$endSec',
            'asetpts=PTS-STARTPTS',
          ];

          if (speed != 1.0) {
            aFilters.add('atempo=${speed.toStringAsFixed(2)}');
          }

          // AI Voice Enhancer & Audio Effects
          final effectiveVolume = clip.audioEffects.isDuckingEnabled
              ? clip.volume * clip.audioEffects.duckingAttenuation
              : clip.volume;

          final effectChain = AIVoiceEnhancerService.generateFFmpegFilter(
            clip.audioEffects,
            baseVolume: effectiveVolume,
          );

          if (effectChain.isNotEmpty) {
            aFilters.add(effectChain);
          }

          filterComplexSegments.add('[$inputIdx:a]${aFilters.join(',')} [$aLabel]');
          audioStreamLabels.add('[$aLabel]');
        }

        clipCounter++;
      }
    }

    // Concatenate / Mix Streams
    final hasOverlaysOrText = project.tracks
        .where((t) => !t.isHidden && (t.type == TrackType.text || t.type == TrackType.overlay))
        .any((t) => t.clips.any((c) =>
            c.textOverlay.text.trim().isNotEmpty ||
            (c.imageOverlay.isEnabled && c.imageOverlay.assetLabel.trim().isNotEmpty)));

    final baseVideoLabel = hasOverlaysOrText ? '[vconcat]' : '[vout]';

    if (videoStreamLabels.isNotEmpty) {
      final hasTransitions = project.tracks
          .where((t) => t.type == TrackType.video && !t.isHidden)
          .expand((t) => t.clips)
          .any((c) => c.transitionIn.isEnabled);

      if (hasTransitions && videoStreamLabels.length >= 2) {
        final videoClips = project.tracks
            .where((t) => t.type == TrackType.video && !t.isHidden)
            .expand((t) => t.clips)
            .toList();

        String currentStream = videoStreamLabels[0];
        double cumulativeOffset = 0.0;

        for (int i = 1; i < videoStreamLabels.length; i++) {
          final nextStream = videoStreamLabels[i];
          final nextClip = i < videoClips.length ? videoClips[i] : null;
          final trans = nextClip?.transitionIn ?? const TransitionConfig();
          final outLabel = i == videoStreamLabels.length - 1 ? baseVideoLabel : '[vtrans$i]';

          if (trans.isEnabled && trans.type.ffmpegXFadeName.isNotEmpty) {
            final prevClip = videoClips[i - 1];
            final prevSec = prevClip.durationMs / 1000.0;
            cumulativeOffset += prevSec - (trans.durationMs / 1000.0);
            final xfade = TransitionCompilerService.generateFFmpegXFade(
              trans,
              offsetSec: cumulativeOffset.clamp(0.1, 86400.0),
            );
            filterComplexSegments.add('$currentStream$nextStream $xfade $outLabel');
          } else {
            filterComplexSegments.add('$currentStream$nextStream concat=n=2:v=1:a=0 $outLabel');
          }
          currentStream = outLabel;
        }
      } else {
        filterComplexSegments.add(
          '${videoStreamLabels.join('')} concat=n=${videoStreamLabels.length}:v=1:a=0 $baseVideoLabel',
        );
      }
    } else {
      filterComplexSegments.add('color=c=black:s=${targetW}x${targetH}:d=1 $baseVideoLabel');
    }

    // Burn-in overlay titles, captions & sticker badges from text/overlay tracks
    if (hasOverlaysOrText) {
      final overlayFilters = <String>[];
      for (final track in project.tracks) {
        if (track.isHidden) continue;
        if (track.type == TrackType.text || track.type == TrackType.overlay) {
          for (final clip in track.clips) {
            final drawText = OverlayCompilerService.generateFFmpegDrawText(clip, clip.textOverlay);
            if (drawText.isNotEmpty) {
              overlayFilters.add(drawText);
            }
            if (clip.imageOverlay.isEnabled && clip.imageOverlay.assetLabel.trim().isNotEmpty) {
              final sanitizedLabel = clip.imageOverlay.assetLabel.replaceAll("'", "\\'").replaceAll(':', '\\:');
              final posX = (clip.imageOverlay.positionX * 0.85).toStringAsFixed(2);
              final posY = (clip.imageOverlay.positionY * 0.85).toStringAsFixed(2);
              final startSec = (clip.startTimeMs / 1000.0).toStringAsFixed(2);
              final endSec = ((clip.startTimeMs + clip.durationMs) / 1000.0).toStringAsFixed(2);
              overlayFilters.add("drawtext=text='$sanitizedLabel':enable='between(t,$startSec,$endSec)':x=w*$posX:y=h*$posY:fontsize=26:fontcolor=white:box=1:boxcolor=black@0.85:boxborderw=6");
            }
          }
        }
      }
      if (overlayFilters.isNotEmpty) {
        filterComplexSegments.add('$baseVideoLabel ${overlayFilters.join(',')} [vout]');
      } else {
        filterComplexSegments.add('$baseVideoLabel null [vout]');
      }
    }

    if (audioStreamLabels.isNotEmpty) {
      filterComplexSegments.add(
        '${audioStreamLabels.join('')} amix=inputs=${audioStreamLabels.length}:normalize=0 [aout]',
      );
    }

    args.addAll(['-filter_complex', filterComplexSegments.join('; ')]);

    // 3. Map Outputs
    args.addAll(['-map', '[vout]']);
    if (audioStreamLabels.isNotEmpty) {
      args.addAll(['-map', '[aout]']);
    }

    // 4. Video & Audio Encoding Parameters
    args.addAll([
      '-c:v', config.codec.ffmpegEncoder,
      '-preset', 'medium',
      '-crf', config.quality.crf.toString(),
      '-pix_fmt', 'yuv420p',
      '-r', config.framerate.fpsValue.toString(),
    ]);

    if (audioStreamLabels.isNotEmpty) {
      args.addAll([
        '-c:a', 'aac',
        '-b:a', '192k',
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
