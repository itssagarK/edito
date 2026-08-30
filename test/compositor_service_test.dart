import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/features/preview/models/aspect_ratio_preset.dart';
import 'package:edito/features/preview/services/timeline_compositor_service.dart';

void main() {
  group('Timeline Compositor Engine Tests', () {
    late Project sampleProject;

    setUp(() {
      final now = DateTime.now();

      final videoAsset = MediaAsset(
        id: 'asset_video',
        path: '/storage/video.mp4',
        fileName: 'video.mp4',
        type: MediaType.video,
        durationMs: 30000,
        width: 1920,
        height: 1080,
      );

      final audioAsset = MediaAsset(
        id: 'asset_audio',
        path: '/storage/music.mp3',
        fileName: 'music.mp3',
        type: MediaType.audio,
        durationMs: 60000,
      );

      // Video Clip: 2000ms to 8000ms (duration 6000ms), trimmed source 1000ms to 7000ms, speed 2.0x
      final videoClip = const Clip(
        id: 'v_clip_1',
        assetId: 'asset_video',
        trackId: 'track_v1',
        startTimeMs: 2000,
        durationMs: 6000,
        sourceInMs: 1000,
        sourceOutMs: 13000,
        volume: 0.8,
        speed: 2.0,
      );

      // Audio Clip: 0ms to 10000ms, volume 0.5
      final audioClip = const Clip(
        id: 'a_clip_1',
        assetId: 'asset_audio',
        trackId: 'track_a1',
        startTimeMs: 0,
        durationMs: 10000,
        sourceInMs: 500,
        sourceOutMs: 10500,
        volume: 0.5,
      );

      final videoTrack = Track(
        id: 'track_v1',
        name: 'Video 1',
        type: TrackType.video,
        order: 0,
        clips: [videoClip],
      );

      final audioTrack = Track(
        id: 'track_a1',
        name: 'Background Audio',
        type: TrackType.audio,
        order: 1,
        clips: [audioClip],
      );

      sampleProject = Project(
        id: 'p_comp',
        title: 'Compositor Test',
        createdAt: now,
        updatedAt: now,
        durationMs: 10000,
        tracks: [videoTrack, audioTrack],
        assets: [videoAsset, audioAsset],
      );
    });

    test('Compositor evaluates frame before video starts (timestamp 1000ms)', () {
      final frame = TimelineCompositorService.evaluateFrame(sampleProject, 1000);

      expect(frame.hasVisualContent, isFalse);
      expect(frame.primaryVideoClip, isNull);

      // Audio is active at 1000ms (audio clip spans 0 to 10000ms)
      expect(frame.activeAudioSources.length, equals(1));
      final audioSrc = frame.activeAudioSources.first;
      expect(audioSrc.clipId, equals('a_clip_1'));
      expect(audioSrc.sourceOffsetMs, equals(1500)); // 500 sourceIn + 1000 offset
      expect(audioSrc.effectiveVolume, equals(0.5));
    });

    test('Compositor evaluates active video frame with 2x speed (timestamp 5000ms)', () {
      final frame = TimelineCompositorService.evaluateFrame(sampleProject, 5000);

      expect(frame.hasVisualContent, isTrue);
      expect(frame.primaryVideoClip, isNotNull);
      expect(frame.primaryVideoClip!.id, equals('v_clip_1'));
      expect(frame.primaryAsset?.fileName, equals('video.mp4'));

      // Video source offset: sourceInMs(1000) + (5000 - 2000) * 2.0 = 1000 + 6000 = 7000ms
      expect(frame.sourceFrameTimeMs, equals(7000));

      // Both video audio (0.8) and soundtrack (0.5) active
      expect(frame.activeAudioSources.length, equals(2));
    });

    test('Muted video track omits video audio from active audio sources', () {
      final mutedVideoTrack = sampleProject.tracks.first.copyWith(isMuted: true);
      final projectWithMute = sampleProject.copyWith(
        tracks: [mutedVideoTrack, sampleProject.tracks[1]],
      );

      final frame = TimelineCompositorService.evaluateFrame(projectWithMute, 5000);

      expect(frame.hasVisualContent, isTrue);
      // Only soundtrack active because video track is muted
      expect(frame.activeAudioSources.length, equals(1));
      expect(frame.activeAudioSources.first.clipId, equals('a_clip_1'));
    });

    test('Aspect ratio presets return accurate dimensions and ratios', () {
      expect(AspectRatioPreset.ratio16x9.ratio, closeTo(16.0 / 9.0, 0.001));
      expect(AspectRatioPreset.ratio9x16.ratio, closeTo(9.0 / 16.0, 0.001));
      expect(AspectRatioPreset.ratio1x1.ratio, equals(1.0));
      expect(AspectRatioPreset.ratio21x9.ratio, closeTo(21.0 / 9.0, 0.001));
    });
  });
}
