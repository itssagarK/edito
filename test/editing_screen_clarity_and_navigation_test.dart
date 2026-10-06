import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/timeline/services/timeline_editing_service.dart';
import 'package:edito/core/utils/timecode_formatter.dart';
import 'package:edito/features/editor/providers/editor_provider.dart';

void main() {
  group('Editing Screen Clarity & Timestamp Navigation Tests', () {
    late Project testProject;

    setUp(() {
      final clip1 = const Clip(
        id: 'clip_1',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      final clip2 = const Clip(
        id: 'clip_2',
        assetId: 'asset_2',
        trackId: 'track_1',
        startTimeMs: 4000,
        durationMs: 6000,
        sourceInMs: 0,
        sourceOutMs: 6000,
      );

      final clipAudio = const Clip(
        id: 'clip_audio',
        assetId: 'asset_audio',
        trackId: 'track_audio',
        startTimeMs: 2000,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      testProject = Project(
        id: 'proj_test',
        title: 'Clarity Test Project',
        durationMs: 10000,
        width: 1920,
        height: 1080,
        fps: 30.0,
        tracks: [
          Track(
            id: 'track_1',
            name: 'Video Track',
            type: TrackType.video,
            order: 0,
            clips: [clip1, clip2],
          ),
          Track(
            id: 'track_audio',
            name: 'Audio Track',
            type: TrackType.audio,
            order: 1,
            clips: [clipAudio],
          ),
        ],
      );
    });

    test('getAllCutPoints collects and sorts all clip boundaries and project endpoints', () {
      final cutPoints = TimelineEditingService.getAllCutPoints(testProject);

      // Expected cuts: 0 (start), 2000 (audio in), 4000 (clip1 end / clip2 start), 7000 (audio end), 10000 (clip2 end / project end)
      expect(cutPoints, containsAll([0, 2000, 4000, 7000, 10000]));
      expect(cutPoints, equals([0, 2000, 4000, 7000, 10000]));
    });

    test('findPreviousCutPoint navigates back to preceding cut boundary', () {
      // From 5000ms, previous cut should be 4000ms
      final prevCutFrom5000 = TimelineEditingService.findPreviousCutPoint(testProject, 5000);
      expect(prevCutFrom5000, equals(4000));

      // From 3500ms, previous cut should be 2000ms
      final prevCutFrom3500 = TimelineEditingService.findPreviousCutPoint(testProject, 3500);
      expect(prevCutFrom3500, equals(2000));

      // From 1000ms, previous cut should be 0ms
      final prevCutFrom1000 = TimelineEditingService.findPreviousCutPoint(testProject, 1000);
      expect(prevCutFrom1000, equals(0));

      // From 0ms, should return null (already at beginning)
      final prevCutFrom0 = TimelineEditingService.findPreviousCutPoint(testProject, 0);
      expect(prevCutFrom0, isNull);
    });

    test('findNextCutPoint navigates forward to next cut boundary', () {
      // From 0ms, next cut should be 2000ms
      final nextCutFrom0 = TimelineEditingService.findNextCutPoint(testProject, 0);
      expect(nextCutFrom0, equals(2000));

      // From 2500ms, next cut should be 4000ms
      final nextCutFrom2500 = TimelineEditingService.findNextCutPoint(testProject, 2500);
      expect(nextCutFrom2500, equals(4000));

      // From 8000ms, next cut should be 10000ms
      final nextCutFrom8000 = TimelineEditingService.findNextCutPoint(testProject, 8000);
      expect(nextCutFrom8000, equals(10000));

      // From 10000ms, should return null (already at end)
      final nextCutFrom10000 = TimelineEditingService.findNextCutPoint(testProject, 10000);
      expect(nextCutFrom10000, isNull);
    });

    test('TimecodeFormatter formats SMPTE and milliseconds with frame precision', () {
      // 0ms at 30fps -> 00:00:00:00
      expect(TimecodeFormatter.formatSmpte(0, fps: 30), equals('00:00:00:00'));

      // 1000ms (1s) at 30fps -> 00:00:01:00
      expect(TimecodeFormatter.formatSmpte(1000, fps: 30), equals('00:00:01:00'));

      // 1500ms at 30fps -> frame 15 -> 00:00:01:15
      expect(TimecodeFormatter.formatSmpte(1500, fps: 30), equals('00:00:01:15'));

      // Millisecond formatter
      expect(TimecodeFormatter.formatMilliseconds(1500), equals('00:01.50'));
    });

    test('EditorNotifier clearSelection safely deselects clip and clears selected track', () {
      final notifier = EditorNotifier();
      notifier.initProject(testProject);

      notifier.selectClip('clip_1', trackId: 'track_1');
      expect(notifier.state.selectedClipId, equals('clip_1'));
      expect(notifier.state.selectedTrackId, equals('track_1'));

      notifier.clearSelection();
      expect(notifier.state.selectedClipId, isNull);
      expect(notifier.state.selectedTrackId, isNull);
    });
  });
}
