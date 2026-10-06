import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/transform/models/video_transform_config.dart';
import 'package:edito/features/overlays/models/text_overlay_config.dart';
import 'package:edito/features/image_editor/models/image_overlay_config.dart';
import 'package:edito/features/captions/models/caption_line.dart';
import 'package:edito/features/captions/presentation/widgets/kinetic_caption_overlay.dart';
import 'package:edito/features/image_editor/presentation/widgets/pip_preview_overlay.dart';
import 'package:edito/features/preview/presentation/widgets/interactive_transform_box.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Universal On-Canvas Spatial Manipulation & Transform Tests', () {
    testWidgets('InteractiveTransformBox renders child cleanly when unselected', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: InteractiveTransformBox(
                  isSelected: false,
                  positionX: 0.5,
                  positionY: 0.5,
                  scale: 1.0,
                  rotation: 0.0,
                  onTap: () {
                    tapped = true;
                  },
                  child: const Text('Test Clip Content'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Clip Content'), findsOneWidget);
      // Handles should not be present when isSelected is false
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.control_point_duplicate), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.sync), findsNothing);

      // Tapping should invoke onTap
      await tester.tap(find.text('Test Clip Content'));
      expect(tapped, isTrue);
    });

    testWidgets('InteractiveTransformBox shows handles and responds to actions when selected', (tester) async {
      bool deleteCalled = false;
      bool duplicateCalled = false;
      bool editCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: InteractiveTransformBox(
                  isSelected: true,
                  positionX: 0.5,
                  positionY: 0.5,
                  scale: 1.0,
                  rotation: 0.0,
                  onDelete: () {
                    deleteCalled = true;
                  },
                  onDuplicate: () {
                    duplicateCalled = true;
                  },
                  onEdit: () {
                    editCalled = true;
                  },
                  onPositionChanged: (_, __) {},
                  onTransformChanged: (_, __) {},
                  child: const Text('Selected Clip Content'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Selected Clip Content'), findsOneWidget);
      // Control handles should be present
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.control_point_duplicate), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);

      // Tap Delete
      await tester.tap(find.byIcon(Icons.close));
      expect(deleteCalled, isTrue);

      // Tap Duplicate
      await tester.tap(find.byIcon(Icons.control_point_duplicate));
      expect(duplicateCalled, isTrue);

      // Tap Edit
      await tester.tap(find.byIcon(Icons.edit));
      expect(editCalled, isTrue);
    });

    testWidgets('KineticCaptionOverlay supports applyAlignment toggle', (tester) async {
      const caption = CaptionLine(
        id: 'cap_1',
        text: 'Hello Dynamic Captions',
        startTimeMs: 0,
        durationMs: 3000,
        style: TextOverlayConfig(
          text: 'Hello Dynamic Captions',
          positionX: 0.5,
          positionY: 0.8,
        ),
      );

      // Standalone mode: applyAlignment = true
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: KineticCaptionOverlay(
                caption: caption,
                offsetMs: 500,
                applyAlignment: true,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Align), findsOneWidget);

      // Embedded mode inside InteractiveTransformBox: applyAlignment = false
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: KineticCaptionOverlay(
                caption: caption,
                offsetMs: 500,
                applyAlignment: false,
              ),
            ),
          ),
        ),
      );
      // Outer Align inside KineticCaptionOverlay is bypassed
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('PipPreviewOverlay supports applyTransform toggle', (tester) async {
      const pipConfig = ImageOverlayConfig(
        isEnabled: true,
        positionX: 0.7,
        positionY: 0.3,
        scale: 0.8,
        rotation: 15.0,
      );

      // Standalone mode: applyTransform = true
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: PipPreviewOverlay(
                config: pipConfig,
                applyTransform: true,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(FractionallySizedBox), findsOneWidget);

      // Embedded mode: applyTransform = false
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: PipPreviewOverlay(
                config: pipConfig,
                applyTransform: false,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(FractionallySizedBox), findsNothing);
    });

    test('Video clip transform updates and project synchronization', () {
      final initialClip = const Clip(
        id: 'clip_vid_1',
        assetId: 'asset_vid_1',
        trackId: 'track_main',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        transform: VideoTransformConfig(
          positionX: 0.5,
          positionY: 0.5,
          scale: 1.0,
          rotationDegrees: 0,
        ),
      );

      final project = Project(
        id: 'proj_spatial',
        title: 'Spatial Project',
        durationMs: 5000,
        tracks: [
          Track(
            id: 'track_main',
            name: 'Video Track',
            type: TrackType.video,
            order: 0,
            clips: [initialClip],
          ),
        ],
      );

      // Drag to new position and scale
      final updatedTransform = initialClip.transform.copyWith(
        positionX: 0.65,
        positionY: 0.40,
        scale: 1.35,
        rotationDegrees: 90,
      );
      final updatedClip = initialClip.copyWith(transform: updatedTransform);
      final updatedProject = project.updateClip(updatedClip);

      final retrieved = updatedProject.findClipById('clip_vid_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.transform.positionX, equals(0.65));
      expect(retrieved.transform.positionY, equals(0.40));
      expect(retrieved.transform.scale, equals(1.35));
      expect(retrieved.transform.rotationDegrees, equals(90));
      expect(retrieved.transform.isActive, isTrue);
    });

    test('Caption clip transform updates and project synchronization', () {
      final initialCaptionClip = const Clip(
        id: 'clip_cap_1',
        assetId: '',
        trackId: 'track_captions',
        startTimeMs: 1000,
        durationMs: 3000,
        sourceInMs: 0,
        sourceOutMs: 3000,
        textOverlay: TextOverlayConfig(
          text: 'Dynamic moving subtitle',
          positionX: 0.5,
          positionY: 0.85,
          scale: 1.0,
          rotation: 0.0,
        ),
      );

      final project = Project(
        id: 'proj_cap',
        title: 'Caption Project',
        durationMs: 5000,
        tracks: [
          Track(
            id: 'track_captions',
            name: 'Captions Track',
            type: TrackType.overlay,
            order: 1,
            clips: [initialCaptionClip],
          ),
        ],
      );

      // Reposition and scale caption
      final updatedTextOverlay = initialCaptionClip.textOverlay.copyWith(
        positionX: 0.35,
        positionY: 0.60,
        scale: 1.5,
        rotation: 12.0,
      );
      final updatedClip = initialCaptionClip.copyWith(textOverlay: updatedTextOverlay);
      final updatedProject = project.updateClip(updatedClip);

      final retrieved = updatedProject.findClipById('clip_cap_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.textOverlay.positionX, equals(0.35));
      expect(retrieved.textOverlay.positionY, equals(0.60));
      expect(retrieved.textOverlay.scale, equals(1.5));
      expect(retrieved.textOverlay.rotation, equals(12.0));
    });
  });
}
