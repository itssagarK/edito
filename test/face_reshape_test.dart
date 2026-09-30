import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/face_reshape/models/face_reshape_config.dart';
import 'package:edito/features/face_reshape/services/face_reshape_compiler_service.dart';
import 'package:edito/features/face_reshape/presentation/widgets/face_reshape_landmarks_overlay.dart';
import 'package:edito/features/face_reshape/presentation/widgets/face_reshape_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    Animate.restartOnHotReload = false;
  });

  group('Face Reshape Domain & Model Tests', () {
    test('FaceReshapePreset extension returns proper labels and descriptions', () {
      for (final preset in FaceReshapePreset.values) {
        expect(preset.label, isNotEmpty);
        expect(preset.description, isNotEmpty);
      }
      expect(FaceReshapePreset.vLine.label, contains('V-Line'));
      expect(FaceReshapePreset.natural.label, contains('Natural'));
    });

    test('FaceReshapeConfig default values are disabled and zeroed', () {
      const config = FaceReshapeConfig();
      expect(config.isEnabled, isFalse);
      expect(config.intensity, equals(1.0));
      expect(config.faceSlimming, equals(0.0));
      expect(config.vFace, equals(0.0));
      expect(config.jawbone, equals(0.0));
      expect(config.pointyChin, equals(0.0));
      expect(config.chinLength, equals(0.0));
      expect(config.cheekbone, equals(0.0));
      expect(config.eyeSize, equals(0.0));
      expect(config.noseSize, equals(0.0));
      expect(config.mouthSize, equals(0.0));
      expect(config.isActive, isFalse);
    });

    test('FaceReshapeConfig isActive requires isEnabled, intensity > 0, and non-zero sculpt parameters', () {
      const emptyEnabled = FaceReshapeConfig(isEnabled: true);
      expect(emptyEnabled.isActive, isFalse);

      const withSlimming = FaceReshapeConfig(isEnabled: true, faceSlimming: 0.25);
      expect(withSlimming.isActive, isTrue);

      const zeroIntensity = FaceReshapeConfig(isEnabled: true, faceSlimming: 0.25, intensity: 0.0);
      expect(zeroIntensity.isActive, isFalse);
    });

    test('FaceReshapeConfig presets correctly initialize sculpting parameters', () {
      final natural = FaceReshapeConfig.fromPreset(FaceReshapePreset.natural);
      expect(natural.isEnabled, isTrue);
      expect(natural.faceSlimming, equals(0.25));
      expect(natural.isActive, isTrue);

      final vLine = FaceReshapeConfig.fromPreset(FaceReshapePreset.vLine);
      expect(vLine.isEnabled, isTrue);
      expect(vLine.vFace, equals(0.60));
      expect(vLine.pointyChin, equals(0.40));

      final chiseled = FaceReshapeConfig.fromPreset(FaceReshapePreset.chiseled);
      expect(chiseled.jawbone, equals(0.40));
      expect(chiseled.noseBridge, equals(0.30));

      final dollFace = FaceReshapeConfig.fromPreset(FaceReshapePreset.dollFace);
      expect(dollFace.eyeSize, equals(0.60));
      expect(dollFace.lipEnhance, equals(0.45));

      final editorial = FaceReshapeConfig.fromPreset(FaceReshapePreset.editorial);
      expect(editorial.cheekbone, equals(0.50));
      expect(editorial.noseBridge, equals(0.40));
    });

    test('FaceReshapeConfig copyWith, serialization and deserialization round-trip', () {
      const config = FaceReshapeConfig(
        isEnabled: true,
        intensity: 0.85,
        faceSlimming: 0.35,
        vFace: 0.45,
        jawbone: -0.2,
        pointyChin: 0.3,
        chinLength: -0.1,
        cheekbone: 0.25,
        forehead: 0.15,
        temple: -0.1,
        eyeSize: 0.4,
        eyeDistance: -0.15,
        eyeAngle: 0.2,
        eyeCorner: -0.1,
        eyePosition: 0.05,
        noseSize: -0.25,
        noseBridge: 0.3,
        mouthSize: -0.15,
        lipEnhance: 0.35,
        smileCorners: 0.4,
        mouthPosition: -0.05,
      );

      final json = config.toJson();
      final reconstructed = FaceReshapeConfig.fromJson(json);
      expect(reconstructed, equals(config));
      expect(reconstructed.isActive, isTrue);

      final updated = config.copyWith(faceSlimming: 0.5);
      expect(updated.faceSlimming, equals(0.5));
      expect(updated.vFace, equals(0.45));
    });

    test('Clip serialization preserves faceReshape config', () {
      final clip = Clip(
        id: 'clip_sculpt_1',
        assetId: 'asset_1',
        startTimeMs: 0,
        durationMs: 4000,
        faceReshape: FaceReshapeConfig.fromPreset(FaceReshapePreset.vLine),
      );

      final json = clip.toJson();
      final fromJson = Clip.fromJson(json);

      expect(fromJson.faceReshape.isEnabled, isTrue);
      expect(fromJson.faceReshape.vFace, equals(0.60));
      expect(fromJson.faceReshape.isActive, isTrue);
    });
  });

  group('Face Reshape Compiler Service Tests', () {
    test('calculateFacialLandmarks generates valid landmark coordinates for viewport', () {
      const config = FaceReshapeConfig(
        isEnabled: true,
        faceSlimming: 0.3,
        vFace: 0.4,
        eyeSize: 0.5,
      );
      const size = Size(1000, 1000);
      final landmarks = FaceReshapeCompilerService.calculateFacialLandmarks(config, size);

      expect(landmarks.containsKey('forehead'), isTrue);
      expect(landmarks.containsKey('templeLeft'), isTrue);
      expect(landmarks.containsKey('templeRight'), isTrue);
      expect(landmarks.containsKey('leftEye'), isTrue);
      expect(landmarks.containsKey('rightEye'), isTrue);
      expect(landmarks.containsKey('nose'), isTrue);
      expect(landmarks.containsKey('mouthCenter'), isTrue);
      expect(landmarks.containsKey('jawLeft'), isTrue);
      expect(landmarks.containsKey('jawRight'), isTrue);
      expect(landmarks.containsKey('chin'), isTrue);

      // Verify coordinate symmetry
      expect(landmarks['templeLeft']!.dx, lessThan(landmarks['templeRight']!.dx));
      expect(landmarks['leftEye']!.dx, lessThan(landmarks['rightEye']!.dx));
      expect(landmarks['forehead']!.dy, lessThan(landmarks['chin']!.dy));
    });

    test('buildLandmarkContourPath creates non-empty contour wireframe path', () {
      final config = FaceReshapeConfig.fromPreset(FaceReshapePreset.editorial);
      final path = FaceReshapeCompilerService.buildLandmarkContourPath(config, const Size(1920, 1080));
      final bounds = path.getBounds();

      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));
    });

    test('generateFFmpegFilters returns empty list when inactive', () {
      const config = FaceReshapeConfig(isEnabled: false);
      final filters = FaceReshapeCompilerService.generateFFmpegFilters(config);
      expect(filters, isEmpty);
    });

    test('generateFFmpegFilters generates lenscorrection and unsharp filters when active', () {
      final config = FaceReshapeConfig.fromPreset(FaceReshapePreset.vLine);
      final filters = FaceReshapeCompilerService.generateFFmpegFilters(config);

      expect(filters, isNotEmpty);
      expect(filters.any((f) => f.contains('lenscorrection')), isTrue);
      expect(filters.any((f) => f.contains('unsharp')), isTrue);
    });
  });

  group('Face Reshape Presentation & Widget Tests', () {
    testWidgets('FaceReshapeLandmarksOverlay paints facial wireframe and landmarks', (tester) async {
      final config = FaceReshapeConfig.fromPreset(FaceReshapePreset.natural);
      FaceReshapeConfig? updatedConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: FaceReshapeLandmarksOverlay(
                config: config,
                onConfigChanged: (cfg) => updatedConfig = cfg,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FaceReshapeLandmarksOverlay), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Drag landmark anchor
      await tester.drag(find.byType(FaceReshapeLandmarksOverlay), const Offset(20, -10));
      await tester.pumpAndSettle();
    });

    testWidgets('FaceReshapeSheet renders tabs, presets, and sliders', (tester) async {
      final clip = Clip(
        id: 'clip_test_1',
        assetId: 'asset_1',
        startTimeMs: 0,
        durationMs: 5000,
        faceReshape: FaceReshapeConfig.fromPreset(FaceReshapePreset.natural),
      );

      Clip? savedClip;
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: FaceReshapeSheet(
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
      expect(find.text('3D Face Reshape'), findsOneWidget);
      expect(find.text('Edito Pro AI Feature Sculpting'), findsOneWidget);
      expect(find.byIcon(Icons.face), findsWidgets);

      // Check tabs
      expect(find.text('🌟 Presets'), findsOneWidget);
      expect(find.text('👤 Face & Jaw'), findsOneWidget);
      expect(find.text('👁️ Eyes'), findsOneWidget);
      expect(find.text('👃 Nose'), findsOneWidget);
      expect(find.text('👄 Lips & Smile'), findsOneWidget);

      // Switch to Face & Jaw tab
      await tester.tap(find.text('👤 Face & Jaw'));
      await tester.pumpAndSettle();

      expect(find.text('Face Slimming'), findsOneWidget);
      expect(find.text('V-Face Jawline'), findsOneWidget);

      // Switch to Eyes tab
      await tester.tap(find.text('👁️ Eyes'));
      await tester.pumpAndSettle();
      expect(find.text('Eye Size (Zoom)'), findsOneWidget);

      // Switch to Nose tab
      await tester.tap(find.text('👃 Nose'));
      await tester.pumpAndSettle();
      expect(find.text('Nose Slimming'), findsOneWidget);

      // Switch to Lips tab
      await tester.tap(find.text('👄 Lips & Smile'));
      await tester.pumpAndSettle();
      expect(find.text('Plump Lip Volume'), findsOneWidget);

      // Tap Reset button
      await tester.tap(find.text('Reset All Sculpting'));
      await tester.pumpAndSettle();
      expect(savedClip, isNotNull);

      // Tap Done checkmark
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(doneCalled, isTrue);
    });
  });
}
