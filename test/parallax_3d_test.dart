import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/parallax_3d/models/parallax_3d_config.dart';
import 'package:edito/features/parallax_3d/services/parallax_3d_compiler_service.dart';
import 'package:edito/features/parallax_3d/presentation/widgets/parallax_3d_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature 25: CapCut Pro 3D Zoom & Parallax Motion Engine Tests', () {
    test('Parallax3DStyle enums have labels, descriptions, and icon assets', () {
      expect(Parallax3DStyle.none.label, equals('None'));
      expect(Parallax3DStyle.classicZoomIn.label, contains('Classic 3D Push'));
      expect(Parallax3DStyle.dollyZoomOut.label, contains('3D Dolly Reveal'));
      expect(Parallax3DStyle.orbitalLeft.label, contains('Orbital Arc Left'));
      expect(Parallax3DStyle.orbitalRight.label, contains('Orbital Arc Right'));
      expect(Parallax3DStyle.vertigoDolly.label, contains('Vertigo'));
      expect(Parallax3DStyle.elasticBounce.label, contains('Elastic Snap'));
      expect(Parallax3DStyle.craneGlider.label, contains('Crane Glide'));

      expect(Parallax3DStyle.classicZoomIn.description, contains('dolly'));
      expect(Parallax3DStyle.orbitalLeft.iconAsset, equals('rotate_left'));
    });

    test('FocalPlane and MotionDynamicsCurve enums have labels', () {
      expect(FocalPlane.foreground.label, contains('Foreground'));
      expect(FocalPlane.midground.label, contains('Midground'));
      expect(FocalPlane.background.label, contains('Background'));

      expect(MotionDynamicsCurve.smoothCubic.label, contains('Cubic'));
      expect(MotionDynamicsCurve.elasticSnap.label, contains('Elastic'));
      expect(MotionDynamicsCurve.linear.label, contains('Linear'));
      expect(MotionDynamicsCurve.cinematicSlow.label, contains('Slow'));
    });

    test('Parallax3DConfig model supports full JSON roundtrip and copyWith', () {
      const config = Parallax3DConfig(
        isEnabled: true,
        style: Parallax3DStyle.vertigoDolly,
        intensity: 0.85,
        depthScale: 1.60,
        perspectiveTilt: 0.55,
        depthBlur: 0.40,
        focalPlane: FocalPlane.foreground,
        dynamicsCurve: MotionDynamicsCurve.elasticSnap,
      );

      final json = config.toJson();
      expect(json['isEnabled'], isTrue);
      expect(json['style'], equals('vertigoDolly'));
      expect(json['intensity'], equals(0.85));
      expect(json['depthScale'], equals(1.60));
      expect(json['perspectiveTilt'], equals(0.55));
      expect(json['depthBlur'], equals(0.40));
      expect(json['focalPlane'], equals('foreground'));
      expect(json['dynamicsCurve'], equals('elasticSnap'));

      final restored = Parallax3DConfig.fromJson(json);
      expect(restored.isEnabled, isTrue);
      expect(restored.style, equals(Parallax3DStyle.vertigoDolly));
      expect(restored.intensity, equals(0.85));
      expect(restored.depthScale, equals(1.60));
      expect(restored.perspectiveTilt, equals(0.55));
      expect(restored.depthBlur, equals(0.40));
      expect(restored.focalPlane, equals(FocalPlane.foreground));
      expect(restored.dynamicsCurve, equals(MotionDynamicsCurve.elasticSnap));
      expect(restored.badge, contains('VERTIGO'));

      final modified = config.copyWith(
        style: Parallax3DStyle.classicZoomIn,
        intensity: 0.70,
      );
      expect(modified.style, equals(Parallax3DStyle.classicZoomIn));
      expect(modified.intensity, equals(0.70));
      expect(modified.depthScale, equals(1.60));
    });

    test('Parallax3DCompilerService evaluates curves accurately', () {
      // Linear
      expect(Parallax3DCompilerService.evaluateCurveProgress(MotionDynamicsCurve.linear, 0.0), equals(0.0));
      expect(Parallax3DCompilerService.evaluateCurveProgress(MotionDynamicsCurve.linear, 0.5), equals(0.5));
      expect(Parallax3DCompilerService.evaluateCurveProgress(MotionDynamicsCurve.linear, 1.0), equals(1.0));

      // Smooth cubic
      expect(Parallax3DCompilerService.evaluateCurveProgress(MotionDynamicsCurve.smoothCubic, 0.0), equals(0.0));
      expect(Parallax3DCompilerService.evaluateCurveProgress(MotionDynamicsCurve.smoothCubic, 0.5), equals(0.5));
      expect(Parallax3DCompilerService.evaluateCurveProgress(MotionDynamicsCurve.smoothCubic, 1.0), equals(1.0));

      // Elastic snap
      expect(Parallax3DCompilerService.evaluateCurveProgress(MotionDynamicsCurve.elasticSnap, 0.0), equals(0.0));
      expect(Parallax3DCompilerService.evaluateCurveProgress(MotionDynamicsCurve.elasticSnap, 1.0), equals(1.0));
    });

    test('Parallax3DCompilerService generates 3D Skia transformation matrix', () {
      const disabledConfig = Parallax3DConfig(isEnabled: false);
      final identityMatrix = Parallax3DCompilerService.computePreviewMatrix(disabledConfig, 0.5);
      expect(identityMatrix, equals(Matrix4.identity()));

      const activeConfig = Parallax3DConfig(
        isEnabled: true,
        style: Parallax3DStyle.classicZoomIn,
        intensity: 0.8,
        depthScale: 1.5,
        perspectiveTilt: 0.6,
      );

      final startMatrix = Parallax3DCompilerService.computePreviewMatrix(activeConfig, 0.0);
      final midMatrix = Parallax3DCompilerService.computePreviewMatrix(activeConfig, 0.5);
      final endMatrix = Parallax3DCompilerService.computePreviewMatrix(activeConfig, 1.0);

      // Perspective Z divisor entry (3, 2) must be non-zero
      expect(midMatrix.entry(3, 2), isNonZero);
      // End matrix must be scaled higher than start matrix
      expect(endMatrix.entry(0, 0), greaterThan(startMatrix.entry(0, 0)));
    });

    test('Parallax3DCompilerService generates dynamic optical lens blur', () {
      const config = Parallax3DConfig(
        isEnabled: true,
        style: Parallax3DStyle.classicZoomIn,
        depthBlur: 0.5,
      );

      final blurAtStart = Parallax3DCompilerService.computePreviewBlur(config, 0.0);
      final blurAtMid = Parallax3DCompilerService.computePreviewBlur(config, 0.5);
      final blurAtEnd = Parallax3DCompilerService.computePreviewBlur(config, 1.0);

      expect(blurAtStart, closeTo(0.0, 0.01));
      expect(blurAtMid, greaterThan(1.0));
      expect(blurAtEnd, closeTo(0.0, 0.01));
    });

    test('Parallax3DCompilerService generates deterministic FFmpeg filters', () {
      const disabledConfig = Parallax3DConfig(isEnabled: false);
      final emptyFilters = Parallax3DCompilerService.generateFFmpegFilters(
        disabledConfig,
        3000,
        30,
        1080,
        1920,
      );
      expect(emptyFilters, isEmpty);

      const activeConfig = Parallax3DConfig(
        isEnabled: true,
        style: Parallax3DStyle.classicZoomIn,
        intensity: 0.75,
        depthScale: 1.4,
        depthBlur: 0.3,
      );

      final filters = Parallax3DCompilerService.generateFFmpegFilters(
        activeConfig,
        3000,
        30,
        1080,
        1920,
      );

      expect(filters.isNotEmpty, isTrue);
      expect(filters.any((f) => f.contains('zoompan')), isTrue);
      expect(filters.any((f) => f.contains('boxblur')), isTrue);
    });

    test('Clip model preserves Parallax3DConfig across serialization', () {
      const clip = Clip(
        id: 'test_clip_1',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        parallax3d: Parallax3DConfig(
          isEnabled: true,
          style: Parallax3DStyle.orbitalLeft,
          intensity: 0.70,
        ),
      );

      final json = clip.toJson();
      expect(json['parallax3d'], isNotNull);
      expect(json['parallax3d']['style'], equals('orbitalLeft'));

      final restoredClip = Clip.fromJson(json);
      expect(restoredClip.parallax3d.isEnabled, isTrue);
      expect(restoredClip.parallax3d.style, equals(Parallax3DStyle.orbitalLeft));
      expect(restoredClip.parallax3d.intensity, equals(0.70));
    });

    testWidgets('Parallax3DSheet renders and updates clip configuration', (WidgetTester tester) async {
      Clip testClip = const Clip(
        id: 'clip_ui_test',
        assetId: 'asset_ui',
        trackId: 'track_ui',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      Clip? savedClip;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Parallax3DSheet(
              clip: testClip,
              isDocked: true,
              onSave: (updated) {
                savedClip = updated;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('CapCut Pro 3D Zoom & Parallax'), findsOneWidget);
      expect(find.text('3D MOTION STYLES'), findsOneWidget);
      expect(find.text('Classic 3D Push'), findsOneWidget);

      // Tap Classic 3D Push to enable
      await tester.tap(find.text('Classic 3D Push'));
      await tester.pump();

      expect(savedClip, isNotNull);
      expect(savedClip!.parallax3d.isEnabled, isTrue);
      expect(savedClip!.parallax3d.style, equals(Parallax3DStyle.classicZoomIn));

      // After enabling, fine tuning headers appear
      expect(find.text('CAMERA KINEMATICS'), findsOneWidget);
      expect(find.text('OPTICAL FOCAL PLANE'), findsOneWidget);
      expect(find.text('ACCELERATION & EASING'), findsOneWidget);
    });
  });
}
