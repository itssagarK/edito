import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/chroma/models/chroma_key_config.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/overlays/models/text_overlay_config.dart';

void main() {
  group('Multi-Track Compositing & Audio Pipeline Stress Tests', () {
    late MediaAsset bg1080pAsset;
    late MediaAsset chromaActorAsset;
    late MediaAsset silentAsset;
    late MediaAsset asset24fps;
    late MediaAsset portrait916Asset;

    setUp(() {
      bg1080pAsset = const MediaAsset(
        id: 'asset_bg',
        path: '/storage/movies/background.mp4',
        fileName: 'background.mp4',
        type: MediaType.video,
        durationMs: 8000,
        width: 1920,
        height: 1080,
        fps: 30.0,
        hasAudio: true,
      );

      chromaActorAsset = const MediaAsset(
        id: 'asset_actor',
        path: '/storage/movies/actor_chroma.mp4',
        fileName: 'actor_chroma.mp4',
        type: MediaType.video,
        durationMs: 8000,
        width: 1920,
        height: 1080,
        fps: 30.0,
        hasAudio: true,
      );

      silentAsset = const MediaAsset(
        id: 'asset_silent',
        path: '/storage/movies/silent_clip.mp4',
        fileName: 'silent_clip.mp4',
        type: MediaType.video,
        durationMs: 5000,
        width: 1280,
        height: 720,
        fps: 30.0,
        hasAudio: false,
      );

      asset24fps = const MediaAsset(
        id: 'asset_24fps',
        path: '/storage/movies/cinema_24fps.mp4',
        fileName: 'cinema_24fps.mp4',
        type: MediaType.video,
        durationMs: 8000,
        width: 1920,
        height: 1080,
        fps: 24.0,
        hasAudio: true,
      );

      portrait916Asset = const MediaAsset(
        id: 'asset_portrait',
        path: '/storage/movies/portrait_shorts.mp4',
        fileName: 'portrait_shorts.mp4',
        type: MediaType.video,
        durationMs: 5000,
        width: 1080,
        height: 1920,
        fps: 30.0,
        hasAudio: false,
      );
    });

    test('TEST 1 — Three overlapping tracks composite in correct z-order with active gating', () {
      final now = DateTime.now();
      final project = Project(
        id: 'test_1_proj',
        title: 'Test 1: Three Overlapping Tracks',
        createdAt: now,
        updatedAt: now,
        durationMs: 8000,
        assets: [bg1080pAsset, chromaActorAsset],
        tracks: [
          Track(
            id: 'track_bg',
            name: 'Background Track',
            type: TrackType.video,
            order: 0,
            clips: [
              const Clip(
                id: 'c_bg',
                assetId: 'asset_bg',
                trackId: 'track_bg',
                startTimeMs: 0,
                durationMs: 8000,
                sourceInMs: 0,
                sourceOutMs: 8000,
              ),
            ],
          ),
          Track(
            id: 'track_actor',
            name: 'Chroma Actor Track',
            type: TrackType.video,
            order: 1,
            clips: [
              const Clip(
                id: 'c_actor',
                assetId: 'asset_actor',
                trackId: 'track_actor',
                startTimeMs: 2000,
                durationMs: 6000,
                sourceInMs: 0,
                sourceOutMs: 6000,
                chromaKey: ChromaKeyConfig(
                  isEnabled: true,
                  keyColorValue: 0xFF00FF00,
                  similarity: 0.25,
                  smoothness: 0.15,
                ),
              ),
            ],
          ),
          Track(
            id: 'track_overlay',
            name: 'Active Window Overlay Track',
            type: TrackType.text,
            order: 2,
            clips: [
              const Clip(
                id: 'c_overlay',
                assetId: '',
                trackId: 'track_overlay',
                startTimeMs: 3000,
                durationMs: 3000,
                sourceInMs: 0,
                sourceOutMs: 3000,
                textOverlay: TextOverlayConfig(
                  text: 'Track3 Active',
                  fontSize: 32.0,
                ),
              ),
            ],
          ),
        ],
      );

      const config = ExportConfiguration(
        resolution: ExportResolution.res1080p,
        outputPath: '/storage/exports/test1_out.mp4',
      );

      final args = FFmpegCommandBuilder.buildArguments(project, config);
      final filterIdx = args.indexOf('-filter_complex');
      expect(filterIdx, isNot(-1));
      final graph = args[filterIdx + 1];

      // Verify layer 0 canvas -> layer 1 overlay -> layer 2 text burn-in
      expect(graph, contains('[v0][v1] overlay=enable=\'between(t,2.00,8.00)\':eof_action=pass [vcomp1]'));
      expect(graph, contains("drawtext=text='Track3 Active'"));
      expect(graph, contains("enable='between(t,3.00,6.00)'"));
      expect(graph, contains('format=yuv420p [vout]'));
    });

    test('TEST 2 — Non-zero start offset audio sync applies adelay for sample-accurate amix alignment', () {
      final now = DateTime.now();
      final project = Project(
        id: 'test_2_proj',
        title: 'Test 2: Non-zero Audio Offset',
        createdAt: now,
        updatedAt: now,
        durationMs: 8000,
        assets: [bg1080pAsset, chromaActorAsset],
        tracks: [
          Track(
            id: 'track_bg',
            name: 'Background',
            type: TrackType.video,
            order: 0,
            clips: [
              const Clip(
                id: 'c_bg',
                assetId: 'asset_bg',
                trackId: 'track_bg',
                startTimeMs: 0,
                durationMs: 8000,
                sourceInMs: 0,
                sourceOutMs: 8000,
              ),
            ],
          ),
          Track(
            id: 'track_delayed',
            name: 'Delayed Audio Clip',
            type: TrackType.audio,
            order: 1,
            clips: [
              const Clip(
                id: 'c_delayed',
                assetId: 'asset_actor',
                trackId: 'track_delayed',
                startTimeMs: 3500,
                durationMs: 2000,
                sourceInMs: 0,
                sourceOutMs: 2000,
              ),
            ],
          ),
        ],
      );

      const config = ExportConfiguration(
        outputPath: '/storage/exports/test2_out.mp4',
      );

      final args = FFmpegCommandBuilder.buildArguments(project, config);
      final filterIdx = args.indexOf('-filter_complex');
      final graph = args[filterIdx + 1];

      // Verify adelay=3500|3500:all=1 is generated for the clip starting at t=3500ms
      expect(graph, contains('adelay=3500|3500:all=1'));
      expect(graph, contains('asetpts=PTS-STARTPTS'));
      expect(graph, contains('amix=inputs=2:normalize=0,alimiter=limit=0.95:attack=5:release=50:asc=1 [aout]'));
    });

    test('TEST 3 — Mixed audio presence skips silent assets without crashing amix', () {
      final now = DateTime.now();
      final project = Project(
        id: 'test_3_proj',
        title: 'Test 3: Mixed Audio Presence',
        createdAt: now,
        updatedAt: now,
        durationMs: 8000,
        assets: [bg1080pAsset, silentAsset],
        tracks: [
          Track(
            id: 'track_0',
            name: 'Track with Audio',
            type: TrackType.video,
            order: 0,
            clips: [
              const Clip(
                id: 'c_with_audio',
                assetId: 'asset_bg',
                trackId: 'track_0',
                startTimeMs: 0,
                durationMs: 8000,
                sourceInMs: 0,
                sourceOutMs: 8000,
              ),
            ],
          ),
          Track(
            id: 'track_1',
            name: 'Track without Audio (silent)',
            type: TrackType.video,
            order: 1,
            clips: [
              const Clip(
                id: 'c_silent',
                assetId: 'asset_silent',
                trackId: 'track_1',
                startTimeMs: 1000,
                durationMs: 5000,
                sourceInMs: 0,
                sourceOutMs: 5000,
              ),
            ],
          ),
        ],
      );

      const config = ExportConfiguration(
        outputPath: '/storage/exports/test3_out.mp4',
      );

      final args = FFmpegCommandBuilder.buildArguments(project, config);
      final filterIdx = args.indexOf('-filter_complex');
      final graph = args[filterIdx + 1];

      // Only 1 audio stream should be bound ([0:a]), silent asset must not generate [1:a]
      expect(graph, contains('[0:a]'));
      expect(graph, isNot(contains('[1:a]')));
      expect(graph, contains('amix=inputs=1:normalize=0,alimiter=limit=0.95:attack=5:release=50:asc=1 [aout]'));
      expect(args, contains('[aout]'));
    });

    test('TEST 4 — Mismatched source frame rates applies per-input fps normalization', () {
      final now = DateTime.now();
      final project = Project(
        id: 'test_4_proj',
        title: 'Test 4: Mismatched Frame Rates',
        createdAt: now,
        updatedAt: now,
        durationMs: 8000,
        assets: [asset24fps, bg1080pAsset],
        tracks: [
          Track(
            id: 'track_24',
            name: '24fps Source',
            type: TrackType.video,
            order: 0,
            clips: [
              const Clip(
                id: 'c_24',
                assetId: 'asset_24fps',
                trackId: 'track_24',
                startTimeMs: 0,
                durationMs: 8000,
                sourceInMs: 0,
                sourceOutMs: 8000,
              ),
            ],
          ),
          Track(
            id: 'track_30',
            name: '30fps Source',
            type: TrackType.video,
            order: 1,
            clips: [
              const Clip(
                id: 'c_30',
                assetId: 'asset_bg',
                trackId: 'track_30',
                startTimeMs: 1000,
                durationMs: 6000,
                sourceInMs: 0,
                sourceOutMs: 6000,
              ),
            ],
          ),
        ],
      );

      const config = ExportConfiguration(
        framerate: ExportFramerate.fps30,
        outputPath: '/storage/exports/test4_out.mp4',
      );

      final args = FFmpegCommandBuilder.buildArguments(project, config);
      final filterIdx = args.indexOf('-filter_complex');
      final graph = args[filterIdx + 1];

      // Verify per-input fps normalization is applied to each stream
      expect(graph, contains('fps=fps=30:round=near'));
    });

    test('TEST 5 — Mismatched aspect ratios uses transparent padding on upper tracks', () {
      final now = DateTime.now();
      final project = Project(
        id: 'test_5_proj',
        title: 'Test 5: Mismatched Aspect Ratios',
        createdAt: now,
        updatedAt: now,
        durationMs: 5000,
        assets: [bg1080pAsset, portrait916Asset],
        tracks: [
          Track(
            id: 'track_landscape',
            name: 'Landscape Background Canvas',
            type: TrackType.video,
            order: 0,
            clips: [
              const Clip(
                id: 'c_landscape',
                assetId: 'asset_bg',
                trackId: 'track_landscape',
                startTimeMs: 0,
                durationMs: 5000,
                sourceInMs: 0,
                sourceOutMs: 5000,
              ),
            ],
          ),
          Track(
            id: 'track_portrait',
            name: 'Portrait 9:16 Upper Track',
            type: TrackType.video,
            order: 1,
            clips: [
              const Clip(
                id: 'c_portrait',
                assetId: 'asset_portrait',
                trackId: 'track_portrait',
                startTimeMs: 0,
                durationMs: 5000,
                sourceInMs: 0,
                sourceOutMs: 5000,
              ),
            ],
          ),
        ],
      );

      const config = ExportConfiguration(
        resolution: ExportResolution.res1080p,
        outputPath: '/storage/exports/test5_out.mp4',
      );

      final args = FFmpegCommandBuilder.buildArguments(project, config);
      final filterIdx = args.indexOf('-filter_complex');
      final graph = args[filterIdx + 1];

      // Track 0 (base canvas) uses opaque background pad
      expect(graph, contains('pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0x000000'));
      // Track 1 (upper track) converts to yuva420p and uses transparent pad (color=black@0)
      expect(graph, contains('pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=black@0'));
    });
  });
}
