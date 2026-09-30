import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/object_removal/models/object_removal_config.dart';
import 'package:edito/features/object_removal/models/object_removal_stroke.dart';
import 'package:edito/features/object_removal/services/object_removal_compiler_service.dart';
import 'package:edito/features/object_removal/presentation/widgets/object_removal_brush_overlay.dart';
import 'package:edito/features/object_removal/presentation/widgets/object_removal_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    Animate.restartOnHotReload = false;
  });

  group('Object Removal Domain & Model Tests', () {
    test('ObjectRemovalPoint toOffset and serialization', () {
      const pt = ObjectRemovalPoint(x: 0.25, y: 0.75, radius: 0.05);
      final offset = pt.toOffset(const Size(1000, 500));
      expect(offset.dx, equals(250.0));
      expect(offset.dy, equals(375.0));

      final json = pt.toJson();
      final copy = ObjectRemovalPoint.fromJson(json);
      expect(copy, equals(pt));
    });

    test('ObjectRemovalStroke computes normalized and pixel bounds correctly', () {
      const stroke = ObjectRemovalStroke(
        id: 'stroke_1',
        points: [
          ObjectRemovalPoint(x: 0.2, y: 0.3),
          ObjectRemovalPoint(x: 0.4, y: 0.6),
        ],
        strokeWidth: 40.0,
      );

      final normBounds = stroke.computeNormalizedBounds();
      expect(normBounds.left, lessThan(0.2));
      expect(normBounds.right, greaterThan(0.4));
      expect(normBounds.top, lessThan(0.3));
      expect(normBounds.bottom, greaterThan(0.6));

      final pixelBounds = stroke.computePixelBounds(const Size(1000, 1000));
      expect(pixelBounds.left, closeTo(normBounds.left * 1000, 1e-3));
      expect(pixelBounds.right, closeTo(normBounds.right * 1000, 1e-3));

      final json = stroke.toJson();
      final reconstructed = ObjectRemovalStroke.fromJson(json);
      expect(reconstructed.id, equals(stroke.id));
      expect(reconstructed.points.length, equals(2));
      expect(reconstructed.strokeWidth, equals(40.0));
    });

    test('ObjectRemovalRegion toRect and serialization', () {
      const region = ObjectRemovalRegion(id: 'reg_1', x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      final rect = region.toRect(const Size(1920, 1080));
      expect(rect.left, closeTo(192.0, 1e-2));
      expect(rect.top, closeTo(216.0, 1e-2));
      expect(rect.width, closeTo(576.0, 1e-2));
      expect(rect.height, closeTo(432.0, 1e-2));

      final json = region.toJson();
      final copy = ObjectRemovalRegion.fromJson(json);
      expect(copy, equals(region));
    });

    test('ObjectRemovalConfig default state is inactive', () {
      const config = ObjectRemovalConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isActive, isFalse);
      expect(config.mode, equals(ObjectRemovalMode.aiMagicEraser));
      expect(config.activeTool, equals(ObjectRemovalToolType.brush));
      expect(config.strokes, isEmpty);
      expect(config.regions, isEmpty);
      expect(config.brushSize, equals(28.0));
    });

    test('ObjectRemovalConfig isActive requires isEnabled and non-empty strokes or regions', () {
      const emptyEnabled = ObjectRemovalConfig(isEnabled: true);
      expect(emptyEnabled.isActive, isFalse);

      const withStroke = ObjectRemovalConfig(
        isEnabled: true,
        strokes: [
          ObjectRemovalStroke(
            id: 's1',
            points: [ObjectRemovalPoint(x: 0.5, y: 0.5)],
          ),
        ],
      );
      expect(withStroke.isActive, isTrue);

      const withRegion = ObjectRemovalConfig(
        isEnabled: true,
        regions: [
          ObjectRemovalRegion(id: 'r1', x: 0.1, y: 0.1, width: 0.2, height: 0.2),
        ],
      );
      expect(withRegion.isActive, isTrue);
    });

    test('ObjectRemovalConfig presets generate valid configurations', () {
      final watermark = ObjectRemovalConfig.fromPreset(ObjectRemovalPreset.watermark);
      expect(watermark.isEnabled, isTrue);
      expect(watermark.mode, equals(ObjectRemovalMode.smartDelogo));
      expect(watermark.activeTool, equals(ObjectRemovalToolType.rectangle));

      final photobomber = ObjectRemovalConfig.fromPreset(ObjectRemovalPreset.photobomber);
      expect(photobomber.mode, equals(ObjectRemovalMode.aiMagicEraser));
      expect(photobomber.brushSize, equals(42.0));

      final blemish = ObjectRemovalConfig.fromPreset(ObjectRemovalPreset.blemish);
      expect(blemish.feather, equals(0.40));
    });

    test('ObjectRemovalConfig computeCombinedBounds merges strokes and regions', () {
      const config = ObjectRemovalConfig(
        isEnabled: true,
        strokes: [
          ObjectRemovalStroke(
            id: 's1',
            points: [ObjectRemovalPoint(x: 0.1, y: 0.1)],
            strokeWidth: 20.0,
          ),
        ],
        regions: [
          ObjectRemovalRegion(id: 'r1', x: 0.5, y: 0.5, width: 0.3, height: 0.3),
        ],
      );

      final bounds = config.computeCombinedBounds(const Size(1000, 1000));
      expect(bounds, isNotNull);
      expect(bounds!.left, lessThan(150.0));
      expect(bounds.right, greaterThanOrEqualTo(800.0));
    });

    test('Clip model integrates objectRemoval and serializes correctly', () {
      const testClip = Clip(
        id: 'clip_removal_test',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        objectRemoval: ObjectRemovalConfig(
          isEnabled: true,
          mode: ObjectRemovalMode.smartDelogo,
          brushSize: 36.0,
        ),
      );

      expect(testClip.objectRemoval.isEnabled, isTrue);
      expect(testClip.objectRemoval.mode, equals(ObjectRemovalMode.smartDelogo));
      expect(testClip.objectRemoval.brushSize, equals(36.0));

      final json = testClip.toJson();
      final reconstructed = Clip.fromJson(json);
      expect(reconstructed.objectRemoval.isEnabled, isTrue);
      expect(reconstructed.objectRemoval.mode, equals(ObjectRemovalMode.smartDelogo));
      expect(reconstructed.objectRemoval.brushSize, equals(36.0));
    });
  });

  group('ObjectRemovalCompilerService Tests', () {
    test('buildMaskPath returns empty path when inactive', () {
      const config = ObjectRemovalConfig();
      final path = ObjectRemovalCompilerService.buildMaskPath(config, const Size(1920, 1080));
      expect(path.getBounds().isEmpty, isTrue);
    });

    test('buildMaskPath constructs geometry for strokes and regions', () {
      const config = ObjectRemovalConfig(
        isEnabled: true,
        strokes: [
          ObjectRemovalStroke(
            id: 's1',
            points: [
              ObjectRemovalPoint(x: 0.2, y: 0.2),
              ObjectRemovalPoint(x: 0.3, y: 0.3),
            ],
            strokeWidth: 30.0,
          ),
        ],
        regions: [
          ObjectRemovalRegion(id: 'r1', x: 0.6, y: 0.6, width: 0.2, height: 0.2),
        ],
      );

      final path = ObjectRemovalCompilerService.buildMaskPath(config, const Size(1000, 1000));
      final bounds = path.getBounds();
      expect(bounds.isEmpty, isFalse);
      expect(bounds.left, closeTo(185.0, 30.0));
      expect(bounds.right, greaterThanOrEqualTo(800.0));
    });

    test('buildMaskPath handles invertMask subtraction', () {
      const config = ObjectRemovalConfig(
        isEnabled: true,
        invertMask: true,
        regions: [
          ObjectRemovalRegion(id: 'r1', x: 0.2, y: 0.2, width: 0.6, height: 0.6),
        ],
      );

      final path = ObjectRemovalCompilerService.buildMaskPath(config, const Size(1000, 1000));
      final bounds = path.getBounds();
      expect(bounds.left, equals(0.0));
      expect(bounds.top, equals(0.0));
      expect(bounds.right, equals(1000.0));
      expect(bounds.bottom, equals(1000.0));
    });

    test('extractBoundingBoxes clamps coordinates within frame dimensions', () {
      const config = ObjectRemovalConfig(
        isEnabled: true,
        regions: [
          ObjectRemovalRegion(id: 'r1', x: 0.9, y: 0.9, width: 0.5, height: 0.5),
        ],
      );

      final boxes = ObjectRemovalCompilerService.extractBoundingBoxes(
        config,
        targetWidth: 1000,
        targetHeight: 1000,
      );
      expect(boxes.length, equals(1));
      expect(boxes.first.left, equals(900.0));
      expect(boxes.first.top, equals(900.0));
    });

    test('generateFFmpegFilters compiles delogo commands for all modes', () {
      for (final mode in ObjectRemovalMode.values) {
        final config = ObjectRemovalConfig(
          isEnabled: true,
          mode: mode,
          feather: 0.4,
          regions: const [
            ObjectRemovalRegion(id: 'r1', x: 0.2, y: 0.3, width: 0.1, height: 0.1),
          ],
        );

        final filters = ObjectRemovalCompilerService.generateFFmpegFilters(
          config,
          targetWidth: 1920,
          targetHeight: 1080,
        );

        expect(filters.length, equals(1));
        expect(filters.first, startsWith('delogo='));
        expect(filters.first, contains('show=0'));
      }
    });

    test('generateFFmpegFilters returns empty when inactive', () {
      const config = ObjectRemovalConfig();
      final filters = ObjectRemovalCompilerService.generateFFmpegFilters(config);
      expect(filters, isEmpty);
    });
  });

  group('ObjectRemoval Widgets Tests', () {
    testWidgets('ObjectRemovalBrushOverlay renders without crash and handles gestures', (tester) async {
      ObjectRemovalConfig captured = const ObjectRemovalConfig(isEnabled: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: ObjectRemovalBrushOverlay(
                config: captured,
                onConfigChanged: (cfg) => captured = cfg,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ObjectRemovalBrushOverlay), findsOneWidget);

      // Perform swipe gesture to simulate pen stroke
      final gesture = await tester.startGesture(const Offset(50, 50));
      await gesture.moveTo(const Offset(100, 100));
      await gesture.moveTo(const Offset(150, 150));
      await gesture.up();
      await tester.pump();

      expect(captured.strokes.length, equals(1));
      expect(captured.strokes.first.points.length, greaterThanOrEqualTo(2));
    });

    testWidgets('ObjectRemovalSheet renders controls and updates state', (tester) async {
      Clip testClip = const Clip(
        id: 'clip_sheet_test',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: ObjectRemovalSheet(
                clip: testClip,
                onSave: (updated, {applyToAll = false}) {
                  testClip = updated;
                },
                onDone: () {},
                isDocked: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('AI Magic Eraser'), findsOneWidget);
      expect(find.text('Enable AI Removal'), findsOneWidget);

      // Tap enable switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(testClip.objectRemoval.isEnabled, isTrue);

      // Select watermark preset chip
      final watermarkChip = find.text('Watermark / Text');
      expect(watermarkChip, findsOneWidget);
      await tester.tap(watermarkChip);
      await tester.pumpAndSettle();

      expect(testClip.objectRemoval.mode, equals(ObjectRemovalMode.smartDelogo));
      expect(testClip.objectRemoval.activeTool, equals(ObjectRemovalToolType.rectangle));
    });
  });
}
