import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/chroma/models/chroma_key_config.dart';
import 'package:edito/features/color_grading/models/color_grading_config.dart';
import 'package:edito/features/color_grading/services/color_filter_compiler_service.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/overlays/models/keyframe.dart';
import 'package:edito/features/overlays/models/text_overlay_config.dart';
import 'package:edito/features/overlays/services/overlay_compiler_service.dart';
import 'package:edito/features/preview/services/timeline_compositor_service.dart';

void main() {
  group('Combined-Effects Stress Test (Color Grading + Chroma Key + Keyframed Text)', () {
    late Project combinedProject;
    late MediaAsset backgroundAsset;
    late MediaAsset greenScreenAsset;
    late Clip colorGradedClip;
    late Clip chromaKeyClip;
    late Clip keyframedTextClip;

    setUp(() {
      final now = DateTime.now();

      backgroundAsset = const MediaAsset(
        id: 'asset_bg',
        path: '/storage/movies/background.mp4',
        fileName: 'background.mp4',
        type: MediaType.video,
        durationMs: 8000,
        width: 1920,
        height: 1080,
      );

      greenScreenAsset = const MediaAsset(
        id: 'asset_green',
        path: '/storage/movies/actor_greenscreen.mp4',
        fileName: 'actor_greenscreen.mp4',
        type: MediaType.video,
        durationMs: 8000,
        width: 1920,
        height: 1080,
      );

      // Clip 1: Color Graded Background
      colorGradedClip = const Clip(
        id: 'clip_bg_graded',
        assetId: 'asset_bg',
        trackId: 'track_video_0',
        startTimeMs: 0,
        durationMs: 8000,
        sourceInMs: 0,
        sourceOutMs: 8000,
        colorGrading: ColorGradingConfig(
          exposure: 0.3,
          contrast: 1.2,
          saturation: 1.15,
          temperature: 20.0,
          tint: -10.0,
          activeLut: LutPreset.tealAndOrange,
          vignette: 0.4,
        ),
      );

      // Clip 2: Chroma Key Actor
      chromaKeyClip = const Clip(
        id: 'clip_actor_chroma',
        assetId: 'asset_green',
        trackId: 'track_video_1',
        startTimeMs: 0,
        durationMs: 8000,
        sourceInMs: 0,
        sourceOutMs: 8000,
        chromaKey: ChromaKeyConfig(
          isEnabled: true,
          keyColorValue: 0xFF00FF00,
          similarity: 0.25,
          smoothness: 0.15,
          spill: 0.12,
        ),
      );

      // Clip 3: Keyframed Text Overlay
      keyframedTextClip = const Clip(
        id: 'clip_text_motion',
        assetId: '',
        trackId: 'track_text',
        startTimeMs: 0,
        durationMs: 8000,
        sourceInMs: 0,
        sourceOutMs: 8000,
        textOverlay: TextOverlayConfig(
          text: 'Hero Intro',
          fontSize: 32.0,
          textColor: 0xFFFFCC00, // Custom gold/yellow text color
          positionX: 0.2,
          positionY: 0.2,
        ),
        keyframes: [
          Keyframe(timeOffsetMs: 0, positionX: 0.2, positionY: 0.2, scale: 1.0, opacity: 0.2),
          Keyframe(timeOffsetMs: 2000, positionX: 0.7, positionY: 0.6, scale: 1.8, opacity: 1.0),
        ],
      );

      combinedProject = Project(
        id: 'proj_stress_test',
        title: 'Combined Effects Stress Test',
        createdAt: now,
        updatedAt: now,
        durationMs: 8000,
        assets: [backgroundAsset, greenScreenAsset],
        tracks: [
          Track(
            id: 'track_video_0',
            name: 'Background Track',
            type: TrackType.video,
            order: 0,
            clips: [colorGradedClip],
          ),
          Track(
            id: 'track_video_1',
            name: 'Green Screen Track',
            type: TrackType.video,
            order: 1,
            clips: [chromaKeyClip],
          ),
          Track(
            id: 'track_text',
            name: 'Text Overlay Track',
            type: TrackType.text,
            order: 2,
            clips: [keyframedTextClip],
          ),
        ],
      );
    });

    test('Audit: Preview Compositor handling of multi-track video with Chroma Key', () {
      final compositor = TimelineCompositorService();
      final frame = compositor.composeFrame(combinedProject, 1000);

      // 1. Check primary video clip selection:
      // Note: Because TimelineCompositorService only has a single primaryVideoClip slot,
      // the higher order track (track_video_1) overwrites track_video_0.
      expect(frame.primaryVideoClip?.id, equals('clip_actor_chroma'));

      // 2. Check overlay collection:
      expect(frame.activeOverlays.length, equals(1));
      expect(frame.activeOverlays.first.id, equals('clip_text_motion'));

      // 3. Check live keyframe interpolation:
      final evaluatedText = OverlayCompilerService.evaluateOverlayAt(frame.activeOverlays.first, 1000);
      expect(evaluatedText.positionX, closeTo(0.45, 0.01));
      expect(evaluatedText.positionY, closeTo(0.40, 0.01));
      expect(evaluatedText.scale, closeTo(1.4, 0.01));
      expect(evaluatedText.opacity, closeTo(0.6, 0.01));

      // 4. Check color filter matrix output for chromaKeyClip:
      final matrix = ColorFilterCompilerService.compileColorMatrix(
        chromaKeyClip.colorGrading,
        chromaKey: chromaKeyClip.chromaKey,
      );
      // Matrix has 20 elements, but alpha row remains strictly [0, 0, 0, 1, 0] (no transparency)
      expect(matrix.length, equals(20));
      expect(matrix[18], equals(1.0));
      expect(matrix[19], equals(0.0));
    });

    test('Audit: FFmpegCommandBuilder complex filter generation under combined effects', () {
      const exportConfig = ExportConfiguration(
        resolution: ExportResolution.res1080p,
        framerate: ExportFramerate.fps30,
        outputPath: '/storage/exports/combined_test.mp4',
      );

      final args = FFmpegCommandBuilder.buildArguments(combinedProject, exportConfig);
      final filterIdx = args.indexOf('-filter_complex');
      expect(filterIdx, isNot(-1));

      final filterGraph = args[filterIdx + 1];

      // Print full filter graph for pipeline diagnostic audit
      // ignore: avoid_print
      print('=== GENERATED FFMPEG FILTER GRAPH ===\n$filterGraph\n=== END ===');

      // 1. Verify Color Grading filters are present for clip 0
      expect(filterGraph, contains('eq=contrast=1.20:brightness=0.04:saturation=1.15'));
      expect(filterGraph, contains('colorbalance=rm=0.05:gm=0.02:bm=-0.05'));
      expect(filterGraph, contains('curves=r='));
      expect(filterGraph, contains('vignette=angle=0.42'));

      // 2. Verify Chroma Key filter is present for clip 1 and executes BEFORE scale/pad
      expect(filterGraph, contains('chromakey=color=0x00FF00:similarity=0.25:blend=0.15,format=yuva420p'));
      final chromaIdx = filterGraph.indexOf('chromakey=color=0x00FF00');
      final clip1ScaleIdx = filterGraph.indexOf('scale=1920:1080', chromaIdx);
      expect(clip1ScaleIdx, isNot(-1)); // chromakey occurs before scale in stream [1:v]!

      // 3. Verify Layered Overlay Compositing (not sequential concatenation)
      expect(filterGraph, isNot(contains('concat=n=2:v=1:a=0')));
      expect(filterGraph, contains('[v0][v1] overlay=enable=\'between(t,0.00,8.00)\':eof_action=pass [vcomp1]'));
      expect(filterGraph, contains('format=yuva420p')); // Preserves alpha for overlay
      expect(filterGraph, contains('format=yuv420p [vout]')); // Converts to yuv420p at final output

      // 4. Verify Frame-Accurate Audio Pipeline with Timeline Synchronization & Brickwall Limiter
      expect(filterGraph, contains('asetpts=PTS-STARTPTS,aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo [a0]'));
      expect(filterGraph, contains('asetpts=PTS-STARTPTS,aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo [a1]'));
      expect(filterGraph, contains('[a0][a1] amix=inputs=2:normalize=0,alimiter=limit=0.95:attack=5:release=50:asc=1 [aout]'));
      expect(args, contains('[aout]'));

      // 5. Verify Keyframe Motion, Custom Styling, and 1080p Proportional Font Scaling (32 * 1.5 = 48)
      expect(filterGraph, contains("drawtext=text='Hero Intro'"));
      expect(filterGraph, contains('fontsize=48')); // Proportionally scaled from 32 (720p) to 48 (1080p)
      expect(filterGraph, contains('fontcolor=0xFFCC00')); // Custom gold color (0xFFFFCC00) preserved
      expect(filterGraph, contains('(w-text_w)*(if(lt((t-0.00)')); // Keyframe motion expression generated!

      // 6. Verify 720p and 4K Resolution Font Scaling & Duration Matching
      const config720p = ExportConfiguration(
        resolution: ExportResolution.res720p,
        outputPath: '/storage/exports/test_720p.mp4',
      );
      final args720p = FFmpegCommandBuilder.buildArguments(combinedProject, config720p);
      final graph720p = args720p[args720p.indexOf('-filter_complex') + 1];
      expect(graph720p, contains('fontsize=32')); // Base 720p font size
      expect(graph720p, contains('[v0][v1] overlay='));

      const config4k = ExportConfiguration(
        resolution: ExportResolution.res4k,
        outputPath: '/storage/exports/test_4k.mp4',
      );
      final args4k = FFmpegCommandBuilder.buildArguments(combinedProject, config4k);
      final graph4k = args4k[args4k.indexOf('-filter_complex') + 1];
      expect(graph4k, contains('fontsize=96')); // 3x scaled at 4K (32 * 3.0 = 96)
      expect(graph4k, contains('[v0][v1] overlay='));
    });
  });
}
