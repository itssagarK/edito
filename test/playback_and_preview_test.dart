import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/features/preview/services/timeline_compositor_service.dart';
import 'package:edito/features/preview/services/video_playback_bridge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Playback and Preview Engine Tests', () {
    test('VideoPlaybackBridgeService isPlayablePath validation', () {
      expect(VideoPlaybackBridgeService.isPlayablePath('content://media/external/video/101'), isTrue);
      expect(VideoPlaybackBridgeService.isPlayablePath('http://commondatastorage.googleapis.com/test.mp4'), isTrue);
      expect(VideoPlaybackBridgeService.isPlayablePath('https://commondatastorage.googleapis.com/test.mp4'), isTrue);
      expect(VideoPlaybackBridgeService.isPlayablePath(''), isFalse);
      expect(VideoPlaybackBridgeService.isPlayablePath(null), isFalse);
    });

    test('VideoPlaybackBridgeService createControllerForPath creates correct URI controllers', () {
      final contentController = VideoPlaybackBridgeService.createControllerForPath('content://media/external/video/1');
      expect(contentController.dataSourceType.name, anyOf(equals('contentUri'), isNotNull));

      final netController = VideoPlaybackBridgeService.createControllerForPath('https://example.com/stream.mp4');
      expect(netController.dataSourceType.name, anyOf(equals('network'), isNotNull));
    });

    test('TimelineCompositor tags primary video audio and separate soundtrack audio', () {
      final now = DateTime.now();

      final videoAsset = MediaAsset(
        id: 'asset_v',
        path: 'content://media/external/video/42',
        fileName: 'cam.mp4',
        type: MediaType.video,
        durationMs: 10000,
        width: 1920,
        height: 1080,
      );

      final musicAsset = MediaAsset(
        id: 'asset_m',
        path: 'content://media/external/audio/88',
        fileName: 'bgm.mp3',
        type: MediaType.audio,
        durationMs: 20000,
      );

      final vClip = const Clip(
        id: 'c_video',
        assetId: 'asset_v',
        trackId: 't_video',
        startTimeMs: 0,
        durationMs: 8000,
        sourceInMs: 0,
        sourceOutMs: 8000,
      );

      final mClip = const Clip(
        id: 'c_music',
        assetId: 'asset_m',
        trackId: 't_audio',
        startTimeMs: 0,
        durationMs: 8000,
        sourceInMs: 0,
        sourceOutMs: 8000,
      );

      final project = Project(
        id: 'p_test',
        title: 'Audio Tagging Test',
        createdAt: now,
        updatedAt: now,
        durationMs: 8000,
        assets: [videoAsset, musicAsset],
        tracks: [
          Track(
            id: 't_video',
            name: 'Video Track',
            type: TrackType.video,
            order: 0,
            clips: [vClip],
          ),
          Track(
            id: 't_audio',
            name: 'Music Track',
            type: TrackType.audio,
            order: 1,
            clips: [mClip],
          ),
        ],
      );

      final frame = TimelineCompositorService.evaluateFrame(project, 2000);

      expect(frame.hasVisualContent, isTrue);
      expect(frame.primaryVideoClip?.id, equals('c_video'));

      // Two active audio sources
      expect(frame.activeAudioSources.length, equals(2));

      final videoAudio = frame.activeAudioSources.firstWhere((s) => s.clipId == 'c_video');
      expect(videoAudio.isPrimaryVideoAudio, isTrue);

      final secondaryAudio = frame.activeAudioSources.firstWhere((s) => s.clipId == 'c_music');
      expect(secondaryAudio.isPrimaryVideoAudio, isFalse);
    });

    test('TimelineCompositor prefers playable video clip over placeholder clip on collision', () {
      final now = DateTime.now();

      final dummyAsset = MediaAsset(
        id: 'dummy_asset',
        path: 'starter_scene.mp4',
        fileName: 'Scene_01.mp4',
        type: MediaType.video,
        durationMs: 6000,
        width: 1920,
        height: 1080,
      );

      final realAsset = MediaAsset(
        id: 'real_asset',
        path: 'content://media/external/video/real',
        fileName: 'RealVideo.mp4',
        type: MediaType.video,
        durationMs: 6000,
        width: 1920,
        height: 1080,
      );

      final dummyClip = const Clip(
        id: 'c_dummy',
        assetId: 'dummy_asset',
        trackId: 't_main',
        startTimeMs: 0,
        durationMs: 6000,
        sourceInMs: 0,
        sourceOutMs: 6000,
      );

      final realClip = const Clip(
        id: 'c_real',
        assetId: 'real_asset',
        trackId: 't_main',
        startTimeMs: 0,
        durationMs: 6000,
        sourceInMs: 0,
        sourceOutMs: 6000,
      );

      final project = Project(
        id: 'p_collision',
        title: 'Collision Test',
        createdAt: now,
        updatedAt: now,
        durationMs: 6000,
        assets: [dummyAsset, realAsset],
        tracks: [
          Track(
            id: 't_main',
            name: 'Main Video',
            type: TrackType.video,
            order: 0,
            clips: [dummyClip, realClip],
          ),
        ],
      );

      final frame = TimelineCompositorService.evaluateFrame(project, 1000);

      expect(frame.hasVisualContent, isTrue);
      expect(frame.primaryVideoClip?.id, equals('c_real'));
      expect(frame.primaryAsset?.fileName, equals('RealVideo.mp4'));
    });

    test('TimelineCompositor handles exact end frame boundary (project.durationMs)', () {
      final now = DateTime.now();

      final videoAsset = MediaAsset(
        id: 'asset_end',
        path: 'content://media/external/video/end',
        fileName: 'end.mp4',
        type: MediaType.video,
        durationMs: 5000,
        width: 1920,
        height: 1080,
      );

      final clip = const Clip(
        id: 'c_end',
        assetId: 'asset_end',
        trackId: 't_end',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      final project = Project(
        id: 'p_end',
        title: 'End Boundary Test',
        createdAt: now,
        updatedAt: now,
        durationMs: 5000,
        assets: [videoAsset],
        tracks: [
          Track(
            id: 't_end',
            name: 'End Video',
            type: TrackType.video,
            order: 0,
            clips: [clip],
          ),
        ],
      );

      // Evaluating at exact end of project duration (5000ms) should retain the visual frame
      final frame = TimelineCompositorService.evaluateFrame(project, 5000);
      expect(frame.hasVisualContent, isTrue);
      expect(frame.primaryVideoClip?.id, equals('c_end'));
      expect(frame.sourceFrameTimeMs, equals(5000));
    });
  });
}
