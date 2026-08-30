import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/features/timeline/services/timeline_editing_service.dart';

void main() {
  group('Timeline Editing Operations Tests', () {
    late Project sampleProject;

    setUp(() {
      final now = DateTime.now();
      final asset = MediaAsset(
        id: 'asset_test',
        path: '/storage/sample.mp4',
        fileName: 'sample.mp4',
        type: MediaType.video,
        durationMs: 30000,
      );

      final clip1 = const Clip(
        id: 'c1',
        assetId: 'asset_test',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 10000,
        sourceInMs: 0,
        sourceOutMs: 10000,
      );

      final clip2 = const Clip(
        id: 'c2',
        assetId: 'asset_test',
        trackId: 't1',
        startTimeMs: 10000,
        durationMs: 5000,
        sourceInMs: 10000,
        sourceOutMs: 15000,
      );

      final track = Track(
        id: 't1',
        name: 'Video Track 1',
        type: TrackType.video,
        order: 0,
        clips: [clip1, clip2],
      );

      sampleProject = Project(
        id: 'p1',
        title: 'Timeline Test',
        createdAt: now,
        updatedAt: now,
        durationMs: 15000,
        tracks: [track],
        assets: [asset],
      );
    });

    test('Split clip into two contiguous clips', () {
      // Split c1 (0-10000ms) at 4000ms
      final updated = TimelineEditingService.splitClip(sampleProject, 'c1', 4000);
      expect(updated, isNotNull);

      final clips = updated!.tracks.first.clips;
      expect(clips.length, equals(3));

      final firstHalf = clips[0];
      final secondHalf = clips[1];

      expect(firstHalf.id, equals('c1'));
      expect(firstHalf.startTimeMs, equals(0));
      expect(firstHalf.durationMs, equals(4000));
      expect(firstHalf.sourceInMs, equals(0));
      expect(firstHalf.sourceOutMs, equals(4000));

      expect(secondHalf.startTimeMs, equals(4000));
      expect(secondHalf.durationMs, equals(6000));
      expect(secondHalf.sourceInMs, equals(4000));
      expect(secondHalf.sourceOutMs, equals(10000));
    });

    test('Trim head moves startTime and sourceIn', () {
      // Trim head of c1 by 2000ms (new start = 2000ms)
      final updated = TimelineEditingService.trimClipHead(sampleProject, 'c1', 2000);
      expect(updated, isNotNull);

      final trimmedClip = updated!.tracks.first.clips.first;
      expect(trimmedClip.startTimeMs, equals(2000));
      expect(trimmedClip.durationMs, equals(8000));
      expect(trimmedClip.sourceInMs, equals(2000));
    });

    test('Trim tail reduces duration and sourceOut', () {
      // Trim tail of c1 to end at 7000ms
      final updated = TimelineEditingService.trimClipTail(sampleProject, 'c1', 7000);
      expect(updated, isNotNull);

      final trimmedClip = updated!.tracks.first.clips.first;
      expect(trimmedClip.durationMs, equals(7000));
      expect(trimmedClip.sourceOutMs, equals(7000));
    });

    test('Duplicate clip appends clone right after original', () {
      final updated = TimelineEditingService.duplicateClip(sampleProject, 'c1');
      final clips = updated.tracks.first.clips;

      expect(clips.length, equals(3));
      final duplicate = clips[2];
      expect(duplicate.startTimeMs, equals(10000));
      expect(duplicate.durationMs, equals(10000));
    });

    test('Ripple delete shifts succeeding clips to the left', () {
      // Delete c1 (duration 10000ms) with ripple = true
      final updated = TimelineEditingService.deleteClip(sampleProject, 'c1', ripple: true);
      final clips = updated.tracks.first.clips;

      expect(clips.length, equals(1));
      final shiftedClip = clips.first;
      expect(shiftedClip.id, equals('c2'));
      expect(shiftedClip.startTimeMs, equals(0)); // Shifted from 10000 to 0
    });

    test('Magnetic snapping calculates closest clip edge within 150ms', () {
      // Target time 9920ms should snap to c1 end / c2 start at 10000ms (diff 80ms <= 150ms)
      final snapped = TimelineEditingService.calculateSnapTime(sampleProject, 9920, thresholdMs: 150);
      expect(snapped, equals(10000));

      // Target time 3000ms is far from any edge, should return 3000ms unmodified
      final notSnapped = TimelineEditingService.calculateSnapTime(sampleProject, 3000, thresholdMs: 150);
      expect(notSnapped, equals(3000));
    });
  });
}
