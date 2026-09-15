import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/export/models/export_config.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/timeline/services/timeline_editing_service.dart';

void main() {
  group('Clip Model - Timeline Workflow Attributes', () {
    test('Clip default workflow values are neutral', () {
      const clip = Clip(
        id: 'clip-1',
        assetId: 'asset-1',
        trackId: 'track-1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      expect(clip.isReversed, false);
      expect(clip.isFreezeFrame, false);
      expect(clip.freezeSourceMs, isNull);
    });

    test('Clip copyWith and JSON serialization preserves workflow fields', () {
      const original = Clip(
        id: 'clip-2',
        assetId: 'asset-1',
        trackId: 'track-1',
        startTimeMs: 1000,
        durationMs: 4000,
        sourceInMs: 500,
        sourceOutMs: 4500,
        isReversed: true,
        isFreezeFrame: true,
        freezeSourceMs: 2500,
      );

      final json = original.toJson();
      final deserialized = Clip.fromJson(json);

      expect(deserialized.isReversed, true);
      expect(deserialized.isFreezeFrame, true);
      expect(deserialized.freezeSourceMs, 2500);
      expect(deserialized, equals(original));
    });
  });

  group('TimelineEditingService - Freeze Frame Operations', () {
    late Project testProject;

    setUp(() {
      const asset = MediaAsset(
        id: 'asset-1',
        path: '/storage/test.mp4',
        fileName: 'test.mp4',
        type: MediaType.video,
        durationMs: 10000,
        hasAudio: true,
      );

      const clip = Clip(
        id: 'c1',
        assetId: 'asset-1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 6000,
        sourceInMs: 0,
        sourceOutMs: 6000,
      );

      const track = Track(
        id: 't1',
        name: 'Video 1',
        type: TrackType.video,
        clips: [clip],
      );

      testProject = Project(
        id: 'proj-1',
        name: 'Freeze Test Project',
        durationMs: 6000,
        tracks: [track],
        assets: [asset],
      );
    });

    test('Splits clip and inserts 3s freeze frame mid-clip at playhead with ripple', () {
      final updated = TimelineEditingService.freezeFrame(
        testProject,
        'c1',
        2000,
        freezeDurationMs: 3000,
      );

      expect(updated, isNotNull);
      final videoTrack = updated!.tracks.firstWhere((t) => t.id == 't1');
      expect(videoTrack.clips.length, 3);

      // Clip 1: Head (0s to 2s)
      final head = videoTrack.clips[0];
      expect(head.startTimeMs, 0);
      expect(head.durationMs, 2000);
      expect(head.sourceOutMs, 2000);

      // Clip 2: Freeze frame (2s to 5s, held at 2000ms source)
      final freeze = videoTrack.clips[1];
      expect(freeze.startTimeMs, 2000);
      expect(freeze.durationMs, 3000);
      expect(freeze.isFreezeFrame, true);
      expect(freeze.freezeSourceMs, 2000);
      expect(freeze.isMuted, true);

      // Clip 3: Tail (5s to 9s, shifted by freeze duration)
      final tail = videoTrack.clips[2];
      expect(tail.startTimeMs, 5000);
      expect(tail.durationMs, 4000);
      expect(tail.sourceInMs, 2000);
      expect(tail.sourceOutMs, 6000);

      expect(updated.durationMs, 9000);
    });

    test('Toggles reverse playback state on clip cleanly', () {
      final reversedProject = TimelineEditingService.toggleReverseClip(testProject, 'c1');
      expect(reversedProject, isNotNull);
      final clipRev = reversedProject!.tracks.first.clips.first;
      expect(clipRev.isReversed, true);

      // Toggling again restores forward playback
      final restoredProject = TimelineEditingService.toggleReverseClip(reversedProject, 'c1');
      expect(restoredProject, isNotNull);
      final clipRestored = restoredProject!.tracks.first.clips.first;
      expect(clipRestored.isReversed, false);
    });

    test('Extracts audio to dedicated audio track and mutes original video', () {
      final updated = TimelineEditingService.extractAudio(testProject, 'c1');
      expect(updated, isNotNull);

      final videoTrack = updated!.tracks.firstWhere((t) => t.type == TrackType.video);
      final audioTrack = updated.tracks.firstWhere((t) => t.type == TrackType.audio);

      // Video clip should now be muted with 0 volume
      final videoClip = videoTrack.clips.first;
      expect(videoClip.isMuted, true);
      expect(videoClip.volume, 0.0);

      // Dedicated audio track should contain independent audio clip
      expect(audioTrack.clips.length, 1);
      final audioClip = audioTrack.clips.first;
      expect(audioClip.assetId, 'asset-1');
      expect(audioClip.startTimeMs, videoClip.startTimeMs);
      expect(audioClip.durationMs, videoClip.durationMs);
      expect(audioClip.sourceInMs, videoClip.sourceInMs);
      expect(audioClip.sourceOutMs, videoClip.sourceOutMs);
      expect(audioClip.isMuted, false);
      expect(audioClip.volume, 1.0);
    });

    test('Duplicates clip and appends immediately adjacent in track', () {
      final updated = TimelineEditingService.duplicateClip(testProject, 'c1');
      final track = updated.tracks.first;
      expect(track.clips.length, 2);

      final dup = track.clips[1];
      expect(dup.startTimeMs, 6000);
      expect(dup.durationMs, 6000);
      expect(dup.assetId, 'asset-1');
      expect(updated.durationMs, 12000);
    });
  });

  group('FFmpeg Export Pipeline - Freeze & Reverse Filters', () {
    test('Builds tpad freeze frame video filter and skips audio for freeze clips', () {
      const asset = MediaAsset(
        id: 'asset-v1',
        path: '/storage/sample.mp4',
        fileName: 'sample.mp4',
        type: MediaType.video,
        durationMs: 8000,
        hasAudio: true,
      );

      const freezeClip = Clip(
        id: 'freeze-1',
        assetId: 'asset-v1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 3000,
        sourceInMs: 1500,
        sourceOutMs: 1540,
        isFreezeFrame: true,
        freezeSourceMs: 1500,
        isMuted: true,
      );

      const track = Track(
        id: 't1',
        name: 'Video',
        type: TrackType.video,
        clips: [freezeClip],
      );

      const project = Project(
        id: 'p-freeze',
        name: 'Freeze Export',
        durationMs: 3000,
        tracks: [track],
        assets: [asset],
      );

      final cmd = FFmpegCommandBuilder.build(
        project: project,
        config: const ExportConfig(),
        outputPath: '/storage/freeze_out.mp4',
      );

      // Verify tpad filter is present in video filtergraph
      expect(cmd.command.contains('tpad=stop_mode=clone:stop_duration=3.000'), isTrue);
      // Verify freeze clip is excluded from audio chains (silence)
      expect(cmd.command.contains('[0:a]'), isFalse);
    });

    test('Builds reverse and areverse filters when clip is reversed', () {
      const asset = MediaAsset(
        id: 'asset-v2',
        path: '/storage/sample2.mp4',
        fileName: 'sample2.mp4',
        type: MediaType.video,
        durationMs: 5000,
        hasAudio: true,
      );

      const revClip = Clip(
        id: 'rev-1',
        assetId: 'asset-v2',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 500,
        sourceOutMs: 4500,
        isReversed: true,
      );

      const track = Track(
        id: 't1',
        name: 'Video',
        type: TrackType.video,
        clips: [revClip],
      );

      const project = Project(
        id: 'p-rev',
        name: 'Reverse Export',
        durationMs: 4000,
        tracks: [track],
        assets: [asset],
      );

      final cmd = FFmpegCommandBuilder.build(
        project: project,
        config: const ExportConfig(),
        outputPath: '/storage/reverse_out.mp4',
      );

      // Verify both reverse (video) and areverse (audio) are included
      expect(cmd.command.contains('reverse'), isTrue);
      expect(cmd.command.contains('areverse'), isTrue);
    });
  });
}
