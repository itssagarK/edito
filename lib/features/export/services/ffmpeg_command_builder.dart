import '../../../models/clip.dart';
import '../../../models/media_asset.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import '../../audio/services/ai_voice_enhancer_service.dart';
import '../../color_grading/services/color_filter_compiler_service.dart';
import '../models/export_preset.dart';

class FFmpegCommandBuilder {
  /// Builds the complete list of FFmpeg command-line arguments for rendering the project
  static List<String> buildArguments(Project project, ExportConfiguration config) {
    final args = <String>[];

    // 1. Gather all unique media assets used in clips
    final usedAssetIds = <String>{};
    for (final track in project.tracks) {
      for (final clip in track.clips) {
        usedAssetIds.add(clip.assetId);
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

          // Scale & Pad to target canvas resolution
          vFilters.add('scale=$targetW:$targetH:force_original_aspect_ratio=decrease');
          vFilters.add('pad=$targetW:$targetH:(ow-iw)/2:(oh-ih)/2:color=black');
          vFilters.add('setsar=1');

          // Color Grading & 3D LUT filter
          final colorFilter = ColorFilterCompilerService.generateFFmpegFilter(clip.colorGrading);
          if (colorFilter.isNotEmpty) {
            vFilters.add(colorFilter);
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
    if (videoStreamLabels.isNotEmpty) {
      filterComplexSegments.add(
        '${videoStreamLabels.join('')} concat=n=${videoStreamLabels.length}:v=1:a=0 [vout]',
      );
    } else {
      filterComplexSegments.add('color=c=black:s=${targetW}x${targetH}:d=1 [vout]');
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
