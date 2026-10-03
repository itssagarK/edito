import 'dart:io';
import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/blending/models/blend_mode_config.dart';
import 'package:edito/features/character_zoom/models/character_zoom_config.dart';
import 'package:edito/features/enhancement/models/video_enhancement_config.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/preview/services/timeline_compositor_service.dart';
import 'package:edito/features/transform/models/video_transform_config.dart';
import 'package:edito/features/transform/services/video_transform_compiler_service.dart';

void main() {
  group('Rendering Fidelity & Preview/Export Parity Tests', () {
    late MediaAsset baseVideoAsset;
    late MediaAsset audioAsset;
    late String tempUpscaledPath;

    setUp(() {
      final now = DateTime.now();

      baseVideoAsset = MediaAsset(
        id: 'asset_vid_1',
        path: '/storage/sample_raw.mp4',
        fileName: 'sample_raw.mp4',
        type: MediaType.video,
        durationMs: 15000,
        width: 1920,
        height: 1080,
      );

      audioAsset = MediaAsset(
        id: 'asset_audio_1',
        path: '/storage/sample_audio.mp3',
        fileName: 'sample_audio.mp3',
        type: MediaType.audio,
        durationMs: 20000,
      );

      // Create a temporary file to represent an on-device Real-ESRGAN upscaled asset
      final tempDir = Directory.systemTemp;
      tempUpscaledPath = '${tempDir.path}/test_upscaled_4x_${now.millisecondsSinceEpoch}.png';
      File(tempUpscaledPath).writeAsBytesSync([0x89, 0x50, 0x4E, 0x47]); // dummy PNG header
    });

    tearDown(() {
      final f = File(tempUpscaledPath);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    });

    test('Real-ESRGAN upscaled asset is prioritized in both Preview and Export', () {
      final clipWithUpscale = Clip(
        id: 'clip_upscaled',
        assetId: 'asset_vid_1',
        trackId: 'track_v0',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        enhancement: VideoEnhancementConfig(
          useNeuralRealEsrgan: true,
          upscaledAssetPath: tempUpscaledPath,
        ),
      );

      final project = Project(
        id: 'proj_upscale_test',
        title: 'Upscale Parity Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 5000,
        tracks: [
          Track(
            id: 'track_v0',
            name: 'Video Track',
            type: TrackType.video,
            order: 0,
            clips: [clipWithUpscale],
          ),
        ],
        assets: [baseVideoAsset],
      );

      // 1. Verify Preview Viewport Compositor resolves to upscaled path
      final frame = TimelineCompositorService.evaluateFrame(project, 2500);
      expect(frame.primaryAsset, isNotNull);
      expect(frame.primaryAsset!.path, equals(tempUpscaledPath));

      // 2. Verify FFmpeg export command builder includes upscaled file as input
      const config = ExportConfiguration(
        resolution: ExportResolution.res1080p,
        framerate: ExportFramerate.fps30,
        outputPath: '/storage/export_upscaled.mp4',
      );
      final args = FFmpegCommandBuilder.buildArguments(project, config);
      expect(args, contains('-i'));
      expect(args, contains(tempUpscaledPath));

      final filterIdx = args.indexOf('-filter_complex');
      expect(filterIdx, isNonNegative);
      final filterGraph = args[filterIdx + 1];

      // Input stream for video must point to the upscaled input index (index 1)
      expect(filterGraph, contains('[1:v]'));
    });

    test('VideoTransformCompilerService generates exact FFmpeg filters for rotations, flips, scale & translation', () {
      // 1. 90-degree clockwise rotation + horizontal mirror
      const rot90Flip = VideoTransformConfig(
        rotationDegrees: 90,
        isFlippedHorizontal: true,
      );
      final filters1 = VideoTransformCompilerService.generateFFmpegFilters(rot90Flip);
      expect(filters1, contains('transpose=1'));
      expect(filters1, contains('hflip'));

      // 2. 180-degree rotation + vertical flip
      const rot180Flip = VideoTransformConfig(
        rotationDegrees: 180,
        isFlippedVertical: true,
      );
      final filters2 = VideoTransformCompilerService.generateFFmpegFilters(rot180Flip);
      expect(filters2, contains('hflip,vflip'));
      expect(filters2, contains('vflip'));

      // 3. Zoom-in punch scale (1.5x) with offset (positionX: 0.70, positionY: 0.30)
      const zoomTransform = VideoTransformConfig(
        scale: 1.5,
        positionX: 0.70,
        positionY: 0.30,
      );
      final zoomFilters = VideoTransformCompilerService.generateFFmpegFilters(
        zoomTransform,
        targetWidth: 1920,
        targetHeight: 1080,
      );
      expect(zoomFilters.any((f) => f.contains('crop=w=') && f.contains('scale=1920:1080')), isTrue);

      // 4. Zoom-out shrink scale (0.8x) with padding
      const shrinkTransform = VideoTransformConfig(
        scale: 0.8,
        positionX: 0.50,
        positionY: 0.50,
      );
      final shrinkFilters = VideoTransformCompilerService.generateFFmpegFilters(
        shrinkTransform,
        targetWidth: 1920,
        targetHeight: 1080,
      );
      expect(shrinkFilters.any((f) => f.contains('scale=') && f.contains('flags=lanczos')), isTrue);
      expect(shrinkFilters.any((f) => f.contains('pad=1920:1080')), isTrue);
    });

    test('Track 0 timeline gaps are accurately preserved in export to eliminate timecode desync', () {
      // Clip 1 starts at 2000ms (2s head gap), runs to 5000ms
      // Clip 2 starts at 7000ms (2s inter-clip gap), runs to 10000ms
      const clip1 = Clip(
        id: 'clip_t0_1',
        assetId: 'asset_vid_1',
        trackId: 'track_v0',
        startTimeMs: 2000,
        durationMs: 3000,
        sourceInMs: 0,
        sourceOutMs: 3000,
      );

      const clip2 = Clip(
        id: 'clip_t0_2',
        assetId: 'asset_vid_1',
        trackId: 'track_v0',
        startTimeMs: 7000,
        durationMs: 3000,
        sourceInMs: 4000,
        sourceOutMs: 7000,
      );

      final projectWithGaps = Project(
        id: 'proj_gaps',
        title: 'Timeline Gaps Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 10000,
        tracks: [
          Track(
            id: 'track_v0',
            name: 'Main Video',
            type: TrackType.video,
            order: 0,
            clips: const [clip1, clip2],
          ),
        ],
        assets: [baseVideoAsset],
      );

      const config = ExportConfiguration(
        resolution: ExportResolution.res1080p,
        framerate: ExportFramerate.fps30,
        outputPath: '/storage/export_gaps.mp4',
      );
      final args = FFmpegCommandBuilder.buildArguments(projectWithGaps, config);
      final filterIdx = args.indexOf('-filter_complex');
      final filterGraph = args[filterIdx + 1];

      // Initial head gap of 2.0s
      expect(filterGraph, contains('color=c=black:s=1920x1080:r=30:d=2.000,setsar=1 [vgap_head]'));

      // Inter-clip gap of 2.0s between clip 1 (ends at 5s) and clip 2 (starts at 7s)
      expect(filterGraph, contains('color=c=black:s=1920x1080:r=30:d=2.000,setsar=1 [vgap_0]'));

      // Concat includes head gap, clip 1, inter gap, and clip 2
      expect(filterGraph, contains('[vgap_head][v0][vgap_0][v1] concat=n=4:v=1:a=0 [track_0]'));
    });

    test('Upper video tracks composite clips with per-clip blend modes and accurate time windows', () {
      const baseClip = Clip(
        id: 'clip_base',
        assetId: 'asset_vid_1',
        trackId: 'track_v0',
        startTimeMs: 0,
        durationMs: 10000,
        sourceInMs: 0,
        sourceOutMs: 10000,
      );

      // Upper track Clip 1: 1s to 4s with Screen blend mode
      const upperClip1 = Clip(
        id: 'clip_upper_1',
        assetId: 'asset_vid_1',
        trackId: 'track_v1',
        startTimeMs: 1000,
        durationMs: 3000,
        sourceInMs: 0,
        sourceOutMs: 3000,
        blendMode: BlendModeConfig(
          isEnabled: true,
          mode: ProBlendMode.screen,
          opacity: 0.85,
        ),
      );

      // Upper track Clip 2: 6s to 9s with Multiply blend mode
      const upperClip2 = Clip(
        id: 'clip_upper_2',
        assetId: 'asset_vid_1',
        trackId: 'track_v1',
        startTimeMs: 6000,
        durationMs: 3000,
        sourceInMs: 0,
        sourceOutMs: 3000,
        blendMode: BlendModeConfig(
          isEnabled: true,
          mode: ProBlendMode.multiply,
          opacity: 0.90,
        ),
      );

      final multiTrackProject = Project(
        id: 'proj_multitrack',
        title: 'Multi-Track Composite',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 10000,
        tracks: [
          Track(
            id: 'track_v0',
            name: 'Base Video',
            type: TrackType.video,
            order: 0,
            clips: const [baseClip],
          ),
          Track(
            id: 'track_v1',
            name: 'Overlay Video',
            type: TrackType.video,
            order: 1,
            clips: const [upperClip1, upperClip2],
          ),
        ],
        assets: [baseVideoAsset],
      );

      const config = ExportConfiguration(
        resolution: ExportResolution.res1080p,
        framerate: ExportFramerate.fps30,
        outputPath: '/storage/export_multitrack.mp4',
      );
      final args = FFmpegCommandBuilder.buildArguments(multiTrackProject, config);
      final filterIdx = args.indexOf('-filter_complex');
      final filterGraph = args[filterIdx + 1];

      // Clip 1 composites with Screen blend mode from 1.000s to 4.000s
      expect(filterGraph, contains('all_mode=screen:all_opacity=0.85:enable=\'between(t,1.000,4.000)\''));

      // Clip 2 composites with Multiply blend mode from 6.000s to 9.000s
      expect(filterGraph, contains('all_mode=multiply:all_opacity=0.90:enable=\'between(t,6.000,9.000)\''));
    });
  });
}
