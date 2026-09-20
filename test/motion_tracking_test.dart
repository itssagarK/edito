import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/overlays/models/text_overlay_config.dart';
import 'package:edito/features/image_editor/models/image_overlay_config.dart';
import 'package:edito/features/tracking/models/motion_tracking_config.dart';
import 'package:edito/features/tracking/services/motion_tracking_service.dart';
import 'package:edito/features/tracking/services/motion_tracking_compiler_service.dart';
import 'package:edito/features/tracking/presentation/widgets/motion_tracking_reticle.dart';
import 'package:edito/features/tracking/presentation/widgets/motion_tracking_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature 23: CapCut Pro Smart Motion Tracking Studio Tests', () {
    test('MotionTrackingConfig enum extensions provide intuitive UI labels', () {
      expect(TrackingTargetType.face.label, contains('Face'));
      expect(TrackingTargetType.body.label, contains('Body'));
      expect(TrackingTargetType.hand.label, contains('Hand'));
      expect(TrackingTargetType.customRegion.label, contains('Custom'));

      expect(TrackingMode.followPosition.label, contains('Position'));
      expect(TrackingMode.scaleAndFollow.label, contains('Scale'));
      expect(TrackingMode.fullKinematics.label, contains('Full'));

      expect(TrackingAnchor.aboveSubject.label, contains('Above'));
      expect(TrackingAnchor.centerSubject.label, contains('Center'));
      expect(TrackingAnchor.belowSubject.label, contains('Below'));
      expect(TrackingAnchor.customOffset.label, contains('Offset'));
    });

    test('MotionTrackingConfig serialization and copyWith work losslessly', () {
      const point = TrackingTrajectoryPoint(
        offsetMs: 250,
        normalizedX: 0.55,
        normalizedY: 0.42,
        scale: 1.15,
        rotationDeg: 3.5,
        confidence: 0.98,
      );

      const config = MotionTrackingConfig(
        isEnabled: true,
        targetType: TrackingTargetType.face,
        mode: TrackingMode.fullKinematics,
        anchor: TrackingAnchor.aboveSubject,
        reticleX: 0.52,
        reticleY: 0.38,
        reticleRadius: 0.14,
        smoothingFactor: 0.45,
        pinnedOverlayId: 'text_overlay_99',
        trajectory: [point],
      );

      final json = config.toJson();
      expect(json['isEnabled'], isTrue);
      expect(json['targetType'], equals('face'));
      expect(json['mode'], equals('fullKinematics'));
      expect(json['anchor'], equals('aboveSubject'));
      expect(json['reticleX'], equals(0.52));
      expect(json['reticleY'], equals(0.38));
      expect(json['pinnedOverlayId'], equals('text_overlay_99'));
      expect(json['trajectory'], isList);

      final restored = MotionTrackingConfig.fromJson(json);
      expect(restored, equals(config));
      expect(restored.trajectory.length, equals(1));
      expect(restored.trajectory.first.offsetMs, equals(250));
      expect(restored.trajectory.first.normalizedX, equals(0.55));
      expect(restored.trajectory.first.scale, equals(1.15));
      expect(restored.trajectory.first.rotationDeg, equals(3.5));
      expect(restored.badge, contains('TRACK'));
    });

    test('MotionTrackingService.generateTrajectory produces bounded, smooth motion points', () {
      final trajectory = MotionTrackingService.generateTrajectory(
        totalDurationMs: 3000,
        targetType: TrackingTargetType.face,
        startX: 0.50,
        startY: 0.40,
        smoothingFactor: 0.35,
        sampleIntervalMs: 60,
      );

      expect(trajectory, isNotEmpty);
      expect(trajectory.first.offsetMs, equals(0));
      expect(trajectory.last.offsetMs, equals(3000));

      for (final pt in trajectory) {
        expect(pt.normalizedX, inInclusiveRange(0.05, 0.95));
        expect(pt.normalizedY, inInclusiveRange(0.05, 0.95));
        expect(pt.scale, inInclusiveRange(0.7, 1.6));
        expect(pt.rotationDeg, inInclusiveRange(-25.0, 25.0));
        expect(pt.confidence, inInclusiveRange(0.5, 1.0));
      }
    });

    test('MotionTrackingService.evaluateTrackingAt handles boundaries and interpolates smoothly', () {
      const pts = [
        TrackingTrajectoryPoint(offsetMs: 0, normalizedX: 0.40, normalizedY: 0.30, scale: 1.0, rotationDeg: 0.0),
        TrackingTrajectoryPoint(offsetMs: 1000, normalizedX: 0.60, normalizedY: 0.50, scale: 1.2, rotationDeg: 10.0),
      ];

      const config = MotionTrackingConfig(
        isEnabled: true,
        anchor: TrackingAnchor.centerSubject,
        trajectory: pts,
      );

      // Boundary tests
      final before = MotionTrackingService.evaluateTrackingAt(config, -500);
      expect(before.normalizedX, closeTo(0.40, 0.01));
      expect(before.normalizedY, closeTo(0.30, 0.01));

      final after = MotionTrackingService.evaluateTrackingAt(config, 1500);
      expect(after.normalizedX, closeTo(0.60, 0.01));
      expect(after.normalizedY, closeTo(0.50, 0.01));

      // Midpoint test (t = 500ms) with cubic ease
      final mid = MotionTrackingService.evaluateTrackingAt(config, 500);
      expect(mid.normalizedX, closeTo(0.50, 0.05));
      expect(mid.normalizedY, closeTo(0.40, 0.05));
      expect(mid.scale, closeTo(1.10, 0.05));
      expect(mid.rotationDeg, closeTo(5.0, 0.5));
    });

    test('MotionTrackingService.applyTrackingToText applies position, scale, and tilt according to mode', () {
      const pts = [
        TrackingTrajectoryPoint(offsetMs: 0, normalizedX: 0.30, normalizedY: 0.40, scale: 1.0, rotationDeg: 0.0),
        TrackingTrajectoryPoint(offsetMs: 1000, normalizedX: 0.70, normalizedY: 0.80, scale: 1.5, rotationDeg: 15.0),
      ];

      const originalText = TextOverlayConfig(
        text: 'TRACK ME',
        positionX: 0.50,
        positionY: 0.50,
        fontSize: 24.0,
        rotation: 0.0,
      );

      // 1. followPosition: scale and rotation unaffected
      const posConfig = MotionTrackingConfig(
        isEnabled: true,
        mode: TrackingMode.followPosition,
        anchor: TrackingAnchor.centerSubject,
        trajectory: pts,
      );
      final evalPos = MotionTrackingService.applyTrackingToText(originalText, posConfig, 1000);
      expect(evalPos.positionX, closeTo(0.70, 0.01));
      expect(evalPos.positionY, closeTo(0.80, 0.01));
      expect(evalPos.fontSize, equals(24.0));
      expect(evalPos.rotation, equals(0.0));

      // 2. scaleAndFollow: scale changes, rotation unaffected
      const scaleConfig = MotionTrackingConfig(
        isEnabled: true,
        mode: TrackingMode.scaleAndFollow,
        anchor: TrackingAnchor.centerSubject,
        trajectory: pts,
      );
      final evalScale = MotionTrackingService.applyTrackingToText(originalText, scaleConfig, 1000);
      expect(evalScale.positionX, closeTo(0.70, 0.01));
      expect(evalScale.positionY, closeTo(0.80, 0.01));
      expect(evalScale.fontSize, closeTo(36.0, 0.1)); // 24 * 1.5
      expect(evalScale.rotation, equals(0.0));

      // 3. fullKinematics: scale & rotation tilt
      const fullConfig = MotionTrackingConfig(
        isEnabled: true,
        mode: TrackingMode.fullKinematics,
        anchor: TrackingAnchor.centerSubject,
        trajectory: pts,
      );
      final evalFull = MotionTrackingService.applyTrackingToText(originalText, fullConfig, 1000);
      expect(evalFull.positionX, closeTo(0.70, 0.01));
      expect(evalFull.positionY, closeTo(0.80, 0.01));
      expect(evalFull.fontSize, closeTo(36.0, 0.1));
      expect(evalFull.rotation, closeTo(15.0, 0.1));
    });

    test('MotionTrackingService.applyTrackingToImageOverlay pins PiP and stickers', () {
      const pts = [
        TrackingTrajectoryPoint(offsetMs: 0, normalizedX: 0.20, normalizedY: 0.30, scale: 1.0, rotationDeg: 0.0),
        TrackingTrajectoryPoint(offsetMs: 1000, normalizedX: 0.60, normalizedY: 0.70, scale: 1.4, rotationDeg: 12.0),
      ];

      const originalPiP = ImageOverlayConfig(
        isEnabled: true,
        positionX: 0.50,
        positionY: 0.50,
        scale: 0.30,
        rotation: 0.0,
      );

      const config = MotionTrackingConfig(
        isEnabled: true,
        mode: TrackingMode.fullKinematics,
        anchor: TrackingAnchor.centerSubject,
        trajectory: pts,
      );

      final trackedPiP = MotionTrackingService.applyTrackingToImageOverlay(originalPiP, config, 1000);
      expect(trackedPiP.positionX, closeTo(0.60, 0.01));
      expect(trackedPiP.positionY, closeTo(0.70, 0.01));
      expect(trackedPiP.scale, closeTo(0.42, 0.01)); // 0.30 * 1.4
      expect(trackedPiP.rotation, closeTo(12.0, 0.1));
    });

    test('MotionTrackingService.convertTrajectoryToKeyframes bakes keyframes accurately', () {
      final trajectory = MotionTrackingService.generateTrajectory(
        totalDurationMs: 1000,
        targetType: TrackingTargetType.body,
        startX: 0.5,
        startY: 0.5,
      );

      final config = MotionTrackingConfig(
        isEnabled: true,
        mode: TrackingMode.scaleAndFollow,
        trajectory: trajectory,
      );

      final keyframes = MotionTrackingService.convertTrajectoryToKeyframes(config, intervalMs: 150);
      expect(keyframes, isNotEmpty);
      expect(keyframes.first.timeOffsetMs, equals(0));
      for (int i = 0; i < keyframes.length - 1; i++) {
        expect(keyframes[i + 1].timeOffsetMs, greaterThan(keyframes[i].timeOffsetMs));
      }
    });

    test('MotionTrackingCompilerService.generateFFmpegMotionExpressions compiles piecewise filter expressions', () {
      final trajectory = MotionTrackingService.generateTrajectory(
        totalDurationMs: 2000,
        targetType: TrackingTargetType.face,
        startX: 0.45,
        startY: 0.35,
      );

      final config = MotionTrackingConfig(
        isEnabled: true,
        mode: TrackingMode.scaleAndFollow,
        trajectory: trajectory,
      );

      final expressions = MotionTrackingCompilerService.generateFFmpegMotionExpressions(
        config: config,
        clipStartTimeMs: 1000,
        clipDurationMs: 2000,
        targetWidth: 1920,
        targetHeight: 1080,
      );

      expect(expressions, contains('x'));
      expect(expressions, contains('y'));
      expect(expressions, contains('scale'));
      expect(expressions, contains('badge'));

      expect(expressions['x'], contains('if('));
      expect(expressions['y'], contains('if('));
      expect(expressions['scale'], isNotEmpty);
      expect(expressions['badge'], contains('🎯'));
    });

    test('Clip model preserves motionTracking field through serialization and copyWith', () {
      const tracking = MotionTrackingConfig(
        isEnabled: true,
        targetType: TrackingTargetType.hand,
        mode: TrackingMode.followPosition,
        reticleX: 0.62,
        reticleY: 0.48,
        pinnedOverlayId: 'ov_sticker_1',
      );

      const clip = Clip(
        id: 'clip_track_test',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        motionTracking: tracking,
      );

      final json = clip.toJson();
      expect(json['motionTracking'], isNotNull);
      expect(json['motionTracking']['targetType'], equals('hand'));

      final restored = Clip.fromJson(json);
      expect(restored.motionTracking.isEnabled, isTrue);
      expect(restored.motionTracking.targetType, equals(TrackingTargetType.hand));
      expect(restored.motionTracking.reticleX, equals(0.62));
      expect(restored.motionTracking.pinnedOverlayId, equals('ov_sticker_1'));

      final modified = restored.copyWith(
        motionTracking: restored.motionTracking.copyWith(reticleRadius: 0.22),
      );
      expect(modified.motionTracking.reticleRadius, equals(0.22));
    });

    testWidgets('MotionTrackingReticle renders correctly and updates on drag', (tester) async {
      double curX = 0.5;
      double curY = 0.5;
      double curR = 0.12;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: MotionTrackingReticle(
                config: MotionTrackingConfig(
                  reticleX: curX,
                  reticleY: curY,
                  reticleRadius: curR,
                ),
                onReticleChanged: (x, y, r) {
                  curX = x;
                  curY = y;
                  curR = r;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(MotionTrackingReticle), findsOneWidget);

      // Drag reticle
      await tester.drag(find.byType(GestureDetector).first, const Offset(30, 20));
      await tester.pump();

      expect(curX, isNot(equals(0.5)));
    });

    testWidgets('MotionTrackingSheet renders studio controls and handles analyze workflow', (tester) async {
      final project = Project(
        id: 'proj_test',
        name: 'Track Proj',
        tracks: [
          Track(
            id: 't_video',
            name: 'Video',
            type: TrackType.video,
            clips: [
              Clip(
                id: 'clip_v1',
                assetId: 'a1',
                trackId: 't_video',
                startTimeMs: 0,
                durationMs: 4000,
                sourceInMs: 0,
                sourceOutMs: 4000,
              ),
            ],
          ),
          Track(
            id: 't_text',
            name: 'Text',
            type: TrackType.text,
            clips: [
              Clip(
                id: 'clip_txt1',
                assetId: 'a_txt',
                trackId: 't_text',
                startTimeMs: 500,
                durationMs: 3000,
                sourceInMs: 0,
                sourceOutMs: 3000,
                textOverlay: TextOverlayConfig(text: 'Pinned Title'),
              ),
            ],
          ),
        ],
      );

      Project? updatedProj;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MotionTrackingSheet(
              project: project,
              targetClip: project.tracks.first.clips.first,
              onSave: (p) => updatedProj = p,
              isDocked: true,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Smart Motion Tracking'), findsOneWidget);
      expect(find.text('START MOTION TRACKING'), findsOneWidget);

      // Tap analyze button
      await tester.tap(find.text('START MOTION TRACKING'));
      await tester.pump();

      // Progress animation
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 500));

      expect(updatedProj, isNotNull);
      final trackedClip = updatedProj!.tracks.first.clips.first;
      expect(trackedClip.motionTracking.isEnabled, isTrue);
      expect(trackedClip.motionTracking.trajectory, isNotEmpty);
    });
  });
}
