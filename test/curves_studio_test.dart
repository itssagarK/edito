import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/curves/models/curve_point.dart';
import 'package:edito/features/curves/models/channel_curve.dart';
import 'package:edito/features/curves/models/curves_config.dart';
import 'package:edito/features/curves/services/curves_compiler_service.dart';
import 'package:edito/features/curves/presentation/widgets/curve_grid_editor_widget.dart';
import 'package:edito/features/curves/presentation/widgets/curves_studio_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    Animate.restartOnHotReload = false;
  });

  group('RGB Curves Domain & Model Tests', () {
    test('CurvePoint clamping, serialization and equality', () {
      const p = CurvePoint(x: -0.2, y: 1.4);
      expect(p.x, equals(0.0));
      expect(p.y, equals(1.0));

      const validP = CurvePoint(x: 0.35, y: 0.65);
      final json = validP.toJson();
      final copy = CurvePoint.fromJson(json);
      expect(copy, equals(validP));
    });

    test('ChannelCurve identity, point modification, and serialization', () {
      final curve = ChannelCurve.identity(CurveChannel.luma);
      expect(curve.isIdentity, isTrue);
      expect(curve.points.length, equals(2));

      // Add point
      final withPoint = curve.withPointAdded(const CurvePoint(x: 0.5, y: 0.7));
      expect(withPoint.isIdentity, isFalse);
      expect(withPoint.points.length, equals(3));
      expect(withPoint.points[1].x, equals(0.5));

      // Update point
      final updated = withPoint.withPointUpdated(1, const CurvePoint(x: 0.5, y: 0.8));
      expect(updated.points[1].y, equals(0.8));

      // Remove intermediate point
      final removed = updated.withPointRemovedAt(1);
      expect(removed.points.length, equals(2));
      expect(removed.isIdentity, isTrue);

      // JSON roundtrip
      final json = withPoint.toJson();
      final fromJson = ChannelCurve.fromJson(json);
      expect(fromJson.points.length, equals(3));
      expect(fromJson.channel, equals(CurveChannel.luma));
    });

    test('CurvesConfig defaults, presets, and active state', () {
      const def = CurvesConfig();
      expect(def.isActive, isFalse);
      expect(def.masterIntensity, equals(1.0));

      for (final preset in CurvesPreset.values) {
        final cfg = CurvesConfig.fromPreset(preset);
        if (preset == CurvesPreset.linearReset) {
          expect(cfg.isActive, isFalse);
        } else {
          expect(cfg.isActive, isTrue);
        }
      }

      final sCurve = CurvesConfig.fromPreset(CurvesPreset.sCurveContrast);
      final json = sCurve.toJson();
      final copy = CurvesConfig.fromJson(json);
      expect(copy.lumaCurve.points.length, equals(4));
      expect(copy.isActive, isTrue);
    });
  });

  group('CurvesCompilerService Tests', () {
    test('evaluateCurve handles endpoints and smooth interpolation', () {
      final curve = ChannelCurve(
        channel: CurveChannel.luma,
        points: const [
          CurvePoint(x: 0.0, y: 0.0),
          CurvePoint(x: 0.5, y: 0.8),
          CurvePoint(x: 1.0, y: 1.0),
        ],
      );

      // Boundaries
      expect(CurvesCompilerService.evaluateCurve(curve, 0.0), closeTo(0.0, 1e-4));
      expect(CurvesCompilerService.evaluateCurve(curve, 1.0), closeTo(1.0, 1e-4));

      // Midpoint
      expect(CurvesCompilerService.evaluateCurve(curve, 0.5), closeTo(0.8, 1e-3));

      // Interpolated points monotonic
      final y25 = CurvesCompilerService.evaluateCurve(curve, 0.25);
      final y75 = CurvesCompilerService.evaluateCurve(curve, 0.75);
      expect(y25, greaterThan(0.0));
      expect(y25, lessThan(0.8));
      expect(y75, greaterThan(0.8));
      expect(y75, lessThan(1.0));
    });

    test('generateLut produces 256 values', () {
      final curve = ChannelCurve.identity(CurveChannel.red);
      final lut = CurvesCompilerService.generateLut(curve);
      expect(lut.length, equals(256));
      expect(lut.first, equals(0));
      expect(lut.last, equals(255));
    });

    test('compileSkiaMatrix returns 20 elements', () {
      const inactive = CurvesConfig();
      final identityMatrix = CurvesCompilerService.compileSkiaMatrix(inactive);
      expect(identityMatrix.length, equals(20));
      expect(identityMatrix[0], equals(1.0));
      expect(identityMatrix[4], equals(0.0));

      final active = CurvesConfig.fromPreset(CurvesPreset.tealAndOrange);
      final activeMatrix = CurvesCompilerService.compileSkiaMatrix(active);
      expect(activeMatrix.length, equals(20));
    });

    test('generateFFmpegFilters formats native curves filter string', () {
      const inactive = CurvesConfig();
      expect(CurvesCompilerService.generateFFmpegFilters(inactive), isEmpty);

      final active = CurvesConfig.fromPreset(CurvesPreset.sCurveContrast);
      final filters = CurvesCompilerService.generateFFmpegFilters(active);
      expect(filters.length, equals(1));
      expect(filters.first, startsWith('curves='));
      expect(filters.first, contains("m='"));
    });
  });

  group('RGB Curves Widget Tests', () {
    testWidgets('CurveGridEditorWidget renders grid, curve, and handles interaction', (tester) async {
      ChannelCurve currentCurve = ChannelCurve.identity(CurveChannel.luma);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CurveGridEditorWidget(
                curve: currentCurve,
                onCurveChanged: (updated) => currentCurve = updated,
                size: 260.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ALL (RGB)'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Tap on grid center to add a control point
      await tester.tapAt(tester.getCenter(find.byType(CustomPaint).first));
      await tester.pumpAndSettle();

      expect(currentCurve.points.length, greaterThan(2));
    });

    testWidgets('CurvesStudioSheet renders channel selector, sliders, presets, and actions', (tester) async {
      final clip = Clip(
        id: 'clip_curves_test',
        assetId: 'asset_1',
        startTimeMs: 0,
        durationMs: 5000,
        curves: CurvesConfig.fromPreset(CurvesPreset.sCurveContrast),
      );

      Clip? savedClip;
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: CurvesStudioSheet(
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
      expect(find.text('RGB Curves Studio'), findsOneWidget);
      expect(find.text('Edito Pro Luma & RGB Spline Grading'), findsOneWidget);
      expect(find.byIcon(Icons.show_chart), findsWidgets);

      // Check channel selector tabs
      expect(find.text('ALL (RGB)'), findsOneWidget);
      expect(find.text('RED'), findsOneWidget);
      expect(find.text('GREEN'), findsOneWidget);
      expect(find.text('BLUE'), findsOneWidget);

      // Switch to RED channel
      await tester.tap(find.text('RED'));
      await tester.pumpAndSettle();

      // Tap S-Curve preset chip
      expect(find.text('S-Curve'), findsWidgets);
      await tester.tap(find.text('S-Curve').first);
      await tester.pumpAndSettle();
      expect(savedClip, isNotNull);

      // Tap Reset All Curves
      await tester.tap(find.text('Reset All Curves'));
      await tester.pumpAndSettle();
      expect(savedClip!.curves.isActive, isFalse);

      // Tap Done checkmark
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(doneCalled, isTrue);
    });
  });
}
