import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/doodle/models/doodle_stroke.dart';
import 'package:edito/features/doodle/models/doodle_config.dart';
import 'package:edito/features/doodle/services/doodle_compiler_service.dart';
import 'package:edito/features/doodle/presentation/widgets/doodle_canvas_overlay.dart';
import 'package:edito/features/doodle/presentation/widgets/doodle_studio_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    Animate.restartOnHotReload = false;
  });

  group('Doodle Studio Domain & Model Tests', () {
    test('DoodlePoint coordinates, offset conversion, and serialization', () {
      const pt = DoodlePoint(x: 0.25, y: 0.75, pressure: 0.8);
      expect(pt.x, equals(0.25));
      expect(pt.y, equals(0.75));
      expect(pt.pressure, equals(0.8));

      final offset = pt.toOffset(const Size(1000, 500));
      expect(offset.dx, equals(250.0));
      expect(offset.dy, equals(375.0));

      final json = pt.toJson();
      final copy = DoodlePoint.fromJson(json);
      expect(copy, equals(pt));
    });

    test('DoodleStroke creation, bounds computation, and serialization', () {
      final stroke = DoodleStroke(
        id: 'stroke_1',
        brushType: DoodleBrushType.neon,
        colorValue: 0xFF00FFCC,
        strokeWidth: 16.0,
        opacity: 0.9,
        points: const [
          DoodlePoint(x: 0.1, y: 0.2),
          DoodlePoint(x: 0.3, y: 0.5),
          DoodlePoint(x: 0.6, y: 0.8),
        ],
      );

      expect(stroke.brushType, equals(DoodleBrushType.neon));
      expect(stroke.color, equals(const Color(0xFF00FFCC)));
      expect(stroke.points.length, equals(3));

      final bounds = stroke.computePixelBounds(const Size(1000, 1000));
      expect(bounds.left, equals(100.0));
      expect(bounds.top, equals(200.0));
      expect(bounds.right, equals(600.0));
      expect(bounds.bottom, equals(800.0));

      final json = stroke.toJson();
      final copy = DoodleStroke.fromJson(json);
      expect(copy.id, equals(stroke.id));
      expect(copy.brushType, equals(DoodleBrushType.neon));
      expect(copy.points.length, equals(3));
    });

    test('DoodleConfig defaults, stroke manipulation, and presets', () {
      const def = DoodleConfig();
      expect(def.isActive, isFalse);
      expect(def.strokes, isEmpty);
      expect(def.selectedBrush, equals(DoodleBrushType.pen));
      expect(def.strokeSize, equals(12.0));
      expect(def.opacity, equals(1.0));

      final strokeA = DoodleStroke(
        id: 'a',
        brushType: DoodleBrushType.pen,
        colorValue: 0xFFFFFFFF,
        strokeWidth: 10.0,
        opacity: 1.0,
        points: const [DoodlePoint(x: 0.1, y: 0.1), DoodlePoint(x: 0.2, y: 0.2)],
      );

      final withA = def.withAddedStroke(strokeA);
      expect(withA.isActive, isTrue);
      expect(withA.strokes.length, equals(1));

      final withB = withA.withAddedStroke(
        strokeA.copyWith(id: 'b'),
      );
      expect(withB.strokes.length, equals(2));

      final undone = withB.withUndoneStroke();
      expect(undone.strokes.length, equals(1));
      expect(undone.strokes.first.id, equals('a'));

      final cleared = undone.withClearedStrokes();
      expect(cleared.strokes, isEmpty);
      expect(cleared.isActive, isFalse);

      final json = withB.toJson();
      final copy = DoodleConfig.fromJson(json);
      expect(copy.strokes.length, equals(2));
    });
  });

  group('DoodleCompilerService Tests', () {
    test('buildSmoothPath handles empty, single, double, and curve points', () {
      const size = Size(1000, 1000);

      final emptyPath = DoodleCompilerService.buildSmoothPath([], size);
      expect(emptyPath, isNotNull);

      final singlePoint = [const DoodlePoint(x: 0.5, y: 0.5)];
      final singlePath = DoodleCompilerService.buildSmoothPath(singlePoint, size);
      expect(singlePath, isNotNull);

      final twoPoints = [const DoodlePoint(x: 0.1, y: 0.1), const DoodlePoint(x: 0.9, y: 0.9)];
      final twoPath = DoodleCompilerService.buildSmoothPath(twoPoints, size);
      expect(twoPath, isNotNull);

      final multiPoints = [
        const DoodlePoint(x: 0.1, y: 0.1),
        const DoodlePoint(x: 0.4, y: 0.6),
        const DoodlePoint(x: 0.8, y: 0.3),
        const DoodlePoint(x: 0.9, y: 0.9),
      ];
      final multiPath = DoodleCompilerService.buildSmoothPath(multiPoints, size);
      expect(multiPath, isNotNull);
    });

    test('paintStroke renders all brush variants on canvas without crashing', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(1080, 1920);

      final points = [
        const DoodlePoint(x: 0.2, y: 0.2),
        const DoodlePoint(x: 0.5, y: 0.6),
        const DoodlePoint(x: 0.8, y: 0.7),
      ];

      for (final brush in DoodleBrushType.values) {
        final stroke = DoodleStroke(
          id: 'test_${brush.name}',
          brushType: brush,
          colorValue: 0xFFFF0055,
          strokeWidth: 20.0,
          opacity: 0.85,
          points: points,
        );
        expect(() => DoodleCompilerService.paintStroke(canvas, stroke, size), returnsNormally);
      }

      final pic = recorder.endRecording();
      expect(pic, isNotNull);
    });

    test('eraseAtPoint removes intersecting strokes and preserves non-intersecting', () {
      const size = Size(1000, 1000);
      final stroke1 = DoodleStroke(
        id: 's1',
        brushType: DoodleBrushType.pen,
        colorValue: 0xFFFFFFFF,
        strokeWidth: 10.0,
        opacity: 1.0,
        points: const [DoodlePoint(x: 0.1, y: 0.1), DoodlePoint(x: 0.2, y: 0.2)],
      );
      final stroke2 = DoodleStroke(
        id: 's2',
        brushType: DoodleBrushType.neon,
        colorValue: 0xFFFF0000,
        strokeWidth: 10.0,
        opacity: 1.0,
        points: const [DoodlePoint(x: 0.8, y: 0.8), DoodlePoint(x: 0.9, y: 0.9)],
      );

      final strokes = [stroke1, stroke2];

      // Erase near stroke1 (100, 100) with radius 30
      final afterErase1 = DoodleCompilerService.eraseAtPoint(
        strokes,
        const Offset(105, 105),
        30.0,
        size,
      );
      expect(afterErase1.length, equals(1));
      expect(afterErase1.first.id, equals('s2'));

      // Erase in empty zone (500, 500)
      final noErase = DoodleCompilerService.eraseAtPoint(
        strokes,
        const Offset(500, 500),
        20.0,
        size,
      );
      expect(noErase.length, equals(2));
    });

    test('generateFFmpegFilters produces drawbox directives for active strokes', () {
      const inactive = DoodleConfig();
      expect(DoodleCompilerService.generateFFmpegFilters(inactive), isEmpty);

      final active = DoodleConfig(
        strokes: [
          DoodleStroke(
            id: 's1',
            brushType: DoodleBrushType.neon,
            colorValue: 0xFFFF0055,
            strokeWidth: 12.0,
            opacity: 0.9,
            points: const [
              DoodlePoint(x: 0.1, y: 0.1),
              DoodlePoint(x: 0.4, y: 0.5),
            ],
          ),
        ],
      );

      final filters = DoodleCompilerService.generateFFmpegFilters(active, targetWidth: 1920, targetHeight: 1080);
      expect(filters.isNotEmpty, isTrue);
      expect(filters.first, contains('drawbox='));
    });
  });

  group('Doodle Studio Widget Tests', () {
    testWidgets('DoodleCanvasOverlay handles pan gestures and adds strokes', (tester) async {
      DoodleConfig currentConfig = const DoodleConfig(
        selectedBrush: DoodleBrushType.pen,
        selectedColorValue: 0xFF00FFCC,
        strokeSize: 15.0,
        opacity: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: DoodleCanvasOverlay(
                config: currentConfig,
                onConfigChanged: (updated) {
                  currentConfig = updated;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DoodleCanvasOverlay), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Perform drawing drag gesture
      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveBy(const Offset(50, 50));
      await gesture.moveBy(const Offset(30, -20));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(currentConfig.strokes.length, equals(1));
      expect(currentConfig.strokes.first.points.length, greaterThan(1));
    });

    testWidgets('DoodleStudioSheet renders brushes, swatches, sliders, and controls', (tester) async {
      final clip = Clip(
        id: 'clip_doodle_test',
        assetId: 'asset_1',
        startTimeMs: 0,
        durationMs: 5000,
        doodle: DoodleConfig(
          strokes: [
            DoodleStroke(
              id: 'init_stroke',
              brushType: DoodleBrushType.neon,
              colorValue: 0xFF00E5FF,
              strokeWidth: 15.0,
              opacity: 0.9,
              points: const [DoodlePoint(x: 0.2, y: 0.2), DoodlePoint(x: 0.4, y: 0.4)],
            ),
          ],
        ),
      );

      Clip? savedClip;
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: DoodleStudioSheet(
                clip: clip,
                onSave: (c, {applyToAll = false}) => savedClip = c,
                onDone: () => doneCalled = true,
                isDocked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and branding
      expect(find.text('Creative Doodle Studio'), findsOneWidget);
      expect(find.text('Edito Pro Vector & Neon Brush Studio'), findsOneWidget);
      expect(find.byIcon(Icons.draw), findsWidgets);

      // Check brush options
      expect(find.text('Pen'), findsWidgets);
      expect(find.text('Neon Glow'), findsWidgets);
      expect(find.text('Highlighter'), findsWidgets);
      expect(find.text('Arrow'), findsWidgets);
      expect(find.text('Eraser'), findsWidgets);

      // Switch to Neon Glow brush
      await tester.tap(find.text('Neon Glow').first);
      await tester.pumpAndSettle();

      // Tap Undo button
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(savedClip, isNotNull);
      expect(savedClip!.doodle.strokes, isEmpty);

      // Tap Done checkmark
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(doneCalled, isTrue);
    });
  });
}
