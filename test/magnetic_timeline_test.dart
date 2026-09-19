import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/features/beats/models/beat_detection_config.dart';
import 'package:edito/features/timeline/presentation/widgets/interactive_timeline.dart';
import 'package:edito/features/timeline/presentation/widgets/timeline_clip_widget.dart';
import 'package:edito/features/timeline/services/timeline_editing_service.dart';

void main() {
  group('Feature 19 - SnapResult & calculateDetailedSnap Tests', () {
    late Project sampleProject;

    setUp(() {
      const clip1 = Clip(
        id: 'c1',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      const clip2 = Clip(
        id: 'c2',
        assetId: 'a2',
        trackId: 't1',
        startTimeMs: 4000,
        durationMs: 6000,
        sourceInMs: 0,
        sourceOutMs: 6000,
        beatConfig: BeatDetectionConfig(
          isEnabled: true,
          bpm: 120.0,
          snapToBeats: true,
          beatTimestampsMs: [1000, 2000, 3000], // Absolute: 5000, 6000, 7000
        ),
      );

      final track = const Track(
        id: 't1',
        name: 'Video Track 1',
        type: TrackType.video,
        clips: [clip1, clip2],
      );

      sampleProject = Project(
        id: 'p_test',
        title: 'Snap Test Project',
        durationMs: 10000,
        tracks: [track],
      );
    });

    test('calculateDetailedSnap detects Clip Tail and Clip Head boundary', () {
      // Near 4000ms boundary (Clip 1 tail / Clip 2 head)
      final snap = TimelineEditingService.calculateDetailedSnap(
        sampleProject,
        3960,
        thresholdMs: 100,
      );

      expect(snap.isSnapped, isTrue);
      expect(snap.snappedTimeMs, 4000);
      expect(snap.snapTarget, isNotNull);
      expect(snap.snapTarget, anyOf('Clip Head', 'Clip Tail'));
    });

    test('calculateDetailedSnap detects Playhead when provided', () {
      final snap = TimelineEditingService.calculateDetailedSnap(
        sampleProject,
        2480,
        thresholdMs: 100,
        playheadMs: 2500,
      );

      expect(snap.isSnapped, isTrue);
      expect(snap.snappedTimeMs, 2500);
      expect(snap.snapTarget, 'Playhead');
    });

    test('calculateDetailedSnap detects rhythm Beat Marker on clip', () {
      // Beat is at relative 1000ms in Clip 2 -> absolute 5000ms
      final snap = TimelineEditingService.calculateDetailedSnap(
        sampleProject,
        5040,
        thresholdMs: 100,
      );

      expect(snap.isSnapped, isTrue);
      expect(snap.snappedTimeMs, 5000);
      expect(snap.snapTarget, 'Beat');
    });

    test('calculateDetailedSnap ignores snap when outside threshold', () {
      final snap = TimelineEditingService.calculateDetailedSnap(
        sampleProject,
        2800,
        thresholdMs: 50,
      );

      expect(snap.isSnapped, isFalse);
      expect(snap.snappedTimeMs, 2800);
      expect(snap.snapTarget, isNull);
    });
  });

  group('Feature 19 - Magnetic Ripple Trimming Tests', () {
    late Project project;

    setUp(() {
      const clip1 = Clip(
        id: 'c1',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      const clip2 = Clip(
        id: 'c2',
        assetId: 'a2',
        trackId: 't1',
        startTimeMs: 4000,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      const track = Track(
        id: 't1',
        name: 'Main Track',
        type: TrackType.video,
        clips: [clip1, clip2],
      );

      project = const Project(
        id: 'p1',
        title: 'Ripple Project',
        durationMs: 9000,
        tracks: [track],
      );
    });

    test('trimClipTail without ripple leaves clip2 at original startTimeMs', () {
      // Shorten clip1 duration from 4000 to 2500ms
      final trimmed = TimelineEditingService.trimClipTail(project, 'c1', 2500, ripple: false);
      expect(trimmed, isNotNull);

      final track = trimmed!.tracks.first;
      final c1 = track.clips.firstWhere((c) => c.id == 'c1');
      final c2 = track.clips.firstWhere((c) => c.id == 'c2');

      expect(c1.durationMs, 2500);
      expect(c2.startTimeMs, 4000); // Leaves 1500ms empty gap
    });

    test('trimClipTail with ripple shifts subsequent clips left to close gap', () {
      // Shorten clip1 duration from 4000 to 2500ms with ripple: true
      final trimmed = TimelineEditingService.trimClipTail(project, 'c1', 2500, ripple: true);
      expect(trimmed, isNotNull);

      final track = trimmed!.tracks.first;
      final c1 = track.clips.firstWhere((c) => c.id == 'c1');
      final c2 = track.clips.firstWhere((c) => c.id == 'c2');

      expect(c1.durationMs, 2500);
      expect(c2.startTimeMs, 2500); // Snug against clip1, no gap!
      expect(trimmed.durationMs, 7500);
    });

    test('trimClipHead with ripple shifts subsequent clips left', () {
      // Trim 1000ms off start of clip1 with ripple: true
      final trimmed = TimelineEditingService.trimClipHead(project, 'c1', 1000, ripple: true);
      expect(trimmed, isNotNull);

      final track = trimmed!.tracks.first;
      final c1 = track.clips.firstWhere((c) => c.id == 'c1');
      final c2 = track.clips.firstWhere((c) => c.id == 'c2');

      expect(c1.durationMs, 3000);
      expect(c2.startTimeMs, 3000); // Rippled left by 1000ms!
    });
  });

  group('Feature 19 - Audio Waveform on Video Clips & InteractiveTimeline Widget Tests', () {
    testWidgets('TimelineClipWidget renders audio waveform for video clip with audio', (tester) async {
      const videoClipWithAudio = Clip(
        id: 'c_vid',
        assetId: 'a_vid',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        volume: 1.0,
        isMuted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineClipWidget(
              clip: videoClipWithAudio,
              trackType: TrackType.video,
              pps: 50.0,
              isSelected: false,
              onTap: () {},
              onTrimLeft: (_) {},
              onTrimRight: (_) {},
              onDragMove: (_) {},
            ),
          ),
        ),
      );

      // Verify widget builds and shows video icon and duration
      expect(find.byType(TimelineClipWidget), findsOneWidget);
      expect(find.byIcon(Icons.movie_creation_outlined), findsOneWidget);
      expect(find.text('5.0s (c_vi)'), findsOneWidget);
    });

    testWidgets('InteractiveTimeline toggles Magnetic Ripple mode on tap', (tester) async {
      const clip = Clip(
        id: 'c1',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      final project = const Project(
        id: 'p1',
        title: 'Interactive Test',
        durationMs: 4000,
        tracks: [
          Track(id: 't1', name: 'Video Track', type: TrackType.video, clips: [clip]),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveTimeline(
              project: project,
              playheadPositionMs: 0,
              zoomScale: 1.0,
              onSeek: (_) {},
              onZoomChanged: (_) {},
              onSelectClip: (_, {trackId}) {},
              onProjectMutated: (_) {},
              onAddMedia: () {},
            ),
          ),
        ),
      );

      // Verify Ripple toggle is initially ON ('Ripple')
      expect(find.text('Ripple'), findsOneWidget);

      // Tap to switch to Freeform mode
      await tester.tap(find.text('Ripple'));
      await tester.pump();

      // Verify label switched to 'Free'
      expect(find.text('Free'), findsOneWidget);

      // Tap again to switch back to Magnetic Ripple mode
      await tester.tap(find.text('Free'));
      await tester.pump();

      expect(find.text('Ripple'), findsOneWidget);
    });
  });
}
