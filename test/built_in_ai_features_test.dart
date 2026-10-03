import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/features/audio/services/ai_silence_remover_service.dart';
import 'package:edito/features/timeline/services/ai_scene_detector_service.dart';
import 'package:edito/features/tracking/services/motion_tracking_service.dart';
import 'package:edito/features/tracking/models/motion_tracking_config.dart';
import 'package:edito/features/image_editor/services/auto_reframe_service.dart';
import 'package:edito/features/image_editor/models/video_layout_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Built-in AI Features - AI Silence Remover', () {
    test('analyzeClipForSilences correctly derives silence gaps and speech percentage', () async {
      const clip = Clip(
        id: 'clip_speech_1',
        trackId: 'track_v0',
        assetId: 'asset_test',
        startTimeMs: 0,
        durationMs: 10000,
        sourceInMs: 0,
        sourceOutMs: 10000,
      );

      final result = await AiSilenceRemoverService.analyzeClipForSilences(
        clip: clip,
        mediaPath: '', // fallback to default
        minSilenceMs: 300,
      );

      expect(result.totalClipDurationMs, equals(10000));
      expect(result.speechSegments.isNotEmpty, isTrue);
      expect(result.speechPercentage, inInclusiveRange(0.0, 100.0));
    });

    test('removeSilencesFromClip splits clip into speech segments and ripples track', () {
      const initialClip = Clip(
        id: 'c1',
        trackId: 't0',
        assetId: 'a1',
        startTimeMs: 0,
        durationMs: 10000,
        sourceInMs: 0,
        sourceOutMs: 10000,
      );
      const followingClip = Clip(
        id: 'c2',
        trackId: 't0',
        assetId: 'a2',
        startTimeMs: 10000,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      final track = Track(
        id: 't0',
        name: 'Video 1',
        type: TrackType.video,
        clips: [initialClip, followingClip],
      );

      final project = Project(
        id: 'p1',
        name: 'Test Project',
        durationMs: 15000,
        tracks: [track],
      );

      // Simulated speech segments: 0-3000ms and 6000-10000ms (silence: 3000-6000ms = 3000ms gap)
      const analysis = SilenceAnalysisResult(
        totalClipDurationMs: 10000,
        speechSegments: [
          [0, 3000],
          [6000, 10000],
        ],
        silenceSegments: [
          [3000, 6000],
        ],
        totalSilenceDurationMs: 3000,
        speechPercentage: 70.0,
      );

      final updatedProject = AiSilenceRemoverService.removeSilencesFromClip(
        project: project,
        clipId: 'c1',
        analysis: analysis,
        paddingMs: 0,
      );

      expect(updatedProject, isNotNull);
      final updatedTrack = updatedProject!.tracks.first;

      // c1 split into 2 speech sub-clips, plus c2 = 3 clips total
      expect(updatedTrack.clips.length, equals(3));

      final subClip1 = updatedTrack.clips[0];
      final subClip2 = updatedTrack.clips[1];
      final rippledFollowing = updatedTrack.clips[2];

      expect(subClip1.startTimeMs, equals(0));
      expect(subClip1.durationMs, equals(3000));
      expect(subClip1.sourceInMs, equals(0));
      expect(subClip1.sourceOutMs, equals(3000));

      expect(subClip2.startTimeMs, equals(3000));
      expect(subClip2.durationMs, equals(4000));
      expect(subClip2.sourceInMs, equals(6000));
      expect(subClip2.sourceOutMs, equals(10000));

      // c2 rippled backwards by deleted silence (3000ms)
      expect(rippledFollowing.startTimeMs, equals(7000));
      expect(rippledFollowing.durationMs, equals(5000));
    });
  });

  group('Built-in AI Features - AI Scene Cut Detection', () {
    test('detectSceneCuts fallback computes analytical scene intervals', () async {
      final res = await AiSceneDetectorService.detectSceneCuts(
        videoPath: 'dummy_video.mp4',
        durationMs: 30000,
        sensitivity: 0.50,
      );

      expect(res.isSuccess, isTrue);
      expect(res.totalDurationMs, equals(30000));
      expect(res.totalCuts, greaterThan(0));
      expect(res.totalScenes, equals(res.totalCuts + 1));

      for (int i = 0; i < res.scenes.length; i++) {
        expect(res.scenes[i][0], lessThan(res.scenes[i][1]));
        if (i > 0) {
          expect(res.scenes[i][0], equals(res.scenes[i - 1][1]));
        }
      }
    });

    test('splitClipAtSceneCuts divides clip at cut timestamps with accurate timing', () {
      const clip = Clip(
        id: 'raw_footage',
        trackId: 't0',
        assetId: 'a0',
        startTimeMs: 0,
        durationMs: 20000,
        sourceInMs: 5000,
        sourceOutMs: 25000,
      );

      final track = Track(
        id: 't0',
        name: 'Video 1',
        type: TrackType.video,
        clips: [clip],
      );

      final project = Project(
        id: 'proj',
        name: 'Scene Test',
        durationMs: 20000,
        tracks: [track],
      );

      // Cuts at 6s and 14s
      final cuts = [6000, 14000];

      final updated = AiSceneDetectorService.splitClipAtSceneCuts(
        project: project,
        clipId: 'raw_footage',
        cutTimestampsMs: cuts,
      );

      expect(updated, isNotNull);
      final clips = updated!.tracks.first.clips;
      expect(clips.length, equals(3));

      // Scene 1: 0 - 6s (source: 5000 - 11000)
      expect(clips[0].startTimeMs, equals(0));
      expect(clips[0].durationMs, equals(6000));
      expect(clips[0].sourceInMs, equals(5000));
      expect(clips[0].sourceOutMs, equals(11000));

      // Scene 2: 6s - 14s (source: 11000 - 19000)
      expect(clips[1].startTimeMs, equals(6000));
      expect(clips[1].durationMs, equals(8000));
      expect(clips[1].sourceInMs, equals(11000));
      expect(clips[1].sourceOutMs, equals(19000));

      // Scene 3: 14s - 20s (source: 19000 - 25000)
      expect(clips[2].startTimeMs, equals(14000));
      expect(clips[2].durationMs, equals(6000));
      expect(clips[2].sourceInMs, equals(19000));
      expect(clips[2].sourceOutMs, equals(25000));

      expect(updated.durationMs, equals(20000));
    });
  });

  group('Built-in AI Features - Motion Tracking & Keyframing', () {
    test('generateOpticalTrajectoryFromVideo falls back gracefully when file absent', () async {
      final points = await MotionTrackingService.generateOpticalTrajectoryFromVideo(
        videoPath: 'non_existent_path.mp4',
        totalDurationMs: 3000,
        targetType: TrackingTargetType.face,
        startX: 0.5,
        startY: 0.4,
        smoothingFactor: 0.4,
      );

      expect(points.isNotEmpty, isTrue);
      expect(points.first.normalizedX, closeTo(0.5, 0.15));
      expect(points.first.normalizedY, closeTo(0.4, 0.15));
      expect(points.last.offsetMs, equals(3000));
    });

    test('convertTrajectoryToKeyframes creates smooth keyframes', () {
      final points = MotionTrackingService.generateTrajectory(
        totalDurationMs: 2000,
        targetType: TrackingTargetType.face,
        startX: 0.5,
        startY: 0.5,
      );

      final config = MotionTrackingConfig(
        isEnabled: true,
        trajectory: points,
        targetType: TrackingTargetType.face,
        mode: TrackingMode.followPositionAndScale,
      );

      final keyframes = MotionTrackingService.convertTrajectoryToKeyframes(config, intervalMs: 200);
      expect(keyframes.isNotEmpty, isTrue);
      expect(keyframes.first.timeOffsetMs, equals(0));
      expect(keyframes.first.positionX, inInclusiveRange(0.0, 1.0));
      expect(keyframes.first.positionY, inInclusiveRange(0.0, 1.0));
    });
  });

  group('Built-in AI Features - AI Auto-Reframe', () {
    test('detectOptimalSpeakerFocalPoint handles absent files safely', () async {
      final fx = await AutoReframeService.detectOptimalSpeakerFocalPoint(
        videoPath: '',
        durationMs: 5000,
      );
      expect(fx, equals(0.0));
    });

    test('generateFFmpegFilter incorporates focal point pan and scan accurately', () {
      const layout = VideoLayoutConfig(
        ratio: VideoAspectRatio.vertical9x16,
        reframeMode: AutoReframeMode.smartCrop,
        focalPointX: 0.35,
        focalPointY: 0.0,
      );

      final filter = AutoReframeService.generateFFmpegFilter(
        layout: layout,
        targetWidth: 1080,
        targetHeight: 1920,
      );

      expect(filter, contains('crop=1080:1920'));
      expect(filter, contains('0.35'));
    });
  });
}
