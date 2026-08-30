import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';

void main() {
  group('Project and Timeline Data Model Tests', () {
    test('Project JSON serialization & deserialization roundtrip', () {
      final now = DateTime.now();
      final asset = MediaAsset(
        id: 'asset_1',
        path: '/storage/emulated/0/Movies/sample.mp4',
        fileName: 'sample.mp4',
        type: MediaType.video,
        durationMs: 12000,
        width: 1920,
        height: 1080,
      );

      final clip = const Clip(
        id: 'clip_1',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 8000,
        sourceInMs: 1000,
        sourceOutMs: 9000,
        volume: 1.0,
      );

      final track = Track(
        id: 'track_1',
        name: 'Video Track 1',
        type: TrackType.video,
        order: 0,
        clips: [clip],
      );

      final project = Project(
        id: 'proj_1',
        title: 'Cinematic Reel',
        createdAt: now,
        updatedAt: now,
        durationMs: 8000,
        tracks: [track],
        assets: [asset],
      );

      final json = project.toJson();
      final restored = Project.fromJson(json);

      expect(restored.id, equals(project.id));
      expect(restored.title, equals(project.title));
      expect(restored.tracks.length, equals(1));
      expect(restored.tracks.first.clips.length, equals(1));
      expect(restored.tracks.first.clips.first.id, equals('clip_1'));
      expect(restored.assets.length, equals(1));
      expect(restored.assets.first.fileName, equals('sample.mp4'));
    });

    test('Project duration recalculation on clip add and remove', () {
      final now = DateTime.now();
      var project = Project(
        id: 'proj_test',
        title: 'Duration Test',
        createdAt: now,
        updatedAt: now,
        tracks: [
          const Track(
            id: 't_video',
            name: 'Video',
            type: TrackType.video,
            order: 0,
          ),
          const Track(
            id: 't_audio',
            name: 'Audio',
            type: TrackType.audio,
            order: 1,
          ),
        ],
      );

      expect(project.durationMs, equals(0));

      // Add a 5-second video clip starting at 0
      final clip1 = const Clip(
        id: 'c1',
        assetId: 'a1',
        trackId: 't_video',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );
      project = project.addClipToTrack('t_video', clip1);
      expect(project.durationMs, equals(5000));

      // Add a second 10-second video clip starting at 5000ms
      final clip2 = const Clip(
        id: 'c2',
        assetId: 'a2',
        trackId: 't_video',
        startTimeMs: 5000,
        durationMs: 10000,
        sourceInMs: 0,
        sourceOutMs: 10000,
      );
      project = project.addClipToTrack('t_video', clip2);
      expect(project.durationMs, equals(15000));

      // Remove clip2
      project = project.removeClip('c2');
      expect(project.durationMs, equals(5000));
    });
  });
}
