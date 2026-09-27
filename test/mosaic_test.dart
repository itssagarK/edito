import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/mosaic/models/mosaic_config.dart';
import 'package:edito/features/mosaic/services/mosaic_compiler_service.dart';
import 'package:edito/features/mosaic/presentation/widgets/mosaic_overlay_painter.dart';
import 'package:edito/features/mosaic/presentation/widgets/mosaic_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    Animate.restartOnHotReload = false;
  });

  group('Smart Mosaic & Privacy Censor Domain Tests', () {
    test('MosaicConfig default state is inactive and properly defaults', () {
      const config = MosaicConfig();
      expect(config.isEnabled, isFalse);
      expect(config.type, equals(MosaicType.none));
      expect(config.shape, equals(MosaicShape.rectangle));
      expect(config.centerX, equals(0.5));
      expect(config.centerY, equals(0.5));
      expect(config.width, equals(0.35));
      expect(config.height, equals(0.25));
      expect(config.pixelSize, equals(16.0));
      expect(config.blurRadius, equals(24.0));
      expect(config.opacity, equals(1.0));
      expect(config.inverted, isFalse);
      expect(config.isActive, isFalse);
    });

    test('MosaicConfig isActive requires enabled, non-none type, and opacity > 0', () {
      const activeConfig = MosaicConfig(
        isEnabled: true,
        type: MosaicType.pixelMosaic,
        opacity: 0.9,
      );
      expect(activeConfig.isActive, isTrue);

      expect(activeConfig.copyWith(isEnabled: false).isActive, isFalse);
      expect(activeConfig.copyWith(type: MosaicType.none).isActive, isFalse);
      expect(activeConfig.copyWith(opacity: 0.0).isActive, isFalse);
    });

    test('MosaicConfig serialization and copyWith work deterministically', () {
      const original = MosaicConfig(
        isEnabled: true,
        type: MosaicType.gaussianBlur,
        shape: MosaicShape.ellipse,
        centerX: 0.42,
        centerY: 0.38,
        width: 0.28,
        height: 0.32,
        pixelSize: 20.0,
        blurRadius: 36.0,
        rotation: 45.0,
        feather: 0.2,
        roundness: 0.4,
        opacity: 0.85,
        inverted: true,
      );

      final json = original.toJson();
      final reconstructed = MosaicConfig.fromJson(json);
      expect(reconstructed, equals(original));

      final updated = original.copyWith(pixelSize: 32.0, opacity: 0.95);
      expect(updated.pixelSize, equals(32.0));
      expect(updated.opacity, equals(0.95));
      expect(updated.shape, equals(MosaicShape.ellipse));
    });

    test('MosaicType extensions have descriptive labels and descriptions', () {
      expect(MosaicType.pixelMosaic.label, contains('Pixel Mosaic'));
      expect(MosaicType.gaussianBlur.label, contains('Gaussian'));
      expect(MosaicType.hexagonalCrystal.label, contains('Hexagonal'));
      expect(MosaicType.frostedGlass.label, contains('Frosted Glass'));

      expect(MosaicType.pixelMosaic.description, contains('8-bit'));
      expect(MosaicType.gaussianBlur.description, contains('defocus'));
    });

    test('MosaicPreset configurations match CapCut Pro specifications', () {
      final faceCensor = MosaicPreset.faceCensor.createConfig();
      expect(faceCensor.isEnabled, isTrue);
      expect(faceCensor.shape, equals(MosaicShape.ellipse));
      expect(faceCensor.type, equals(MosaicType.pixelMosaic));

      final plate = MosaicPreset.licensePlate.createConfig();
      expect(plate.isEnabled, isTrue);
      expect(plate.shape, equals(MosaicShape.bannerStrip));
      expect(plate.type, equals(MosaicType.gaussianBlur));

      final retro = MosaicPreset.retroPixelArt.createConfig();
      expect(retro.isEnabled, isTrue);
      expect(retro.shape, equals(MosaicShape.fullFrame));
      expect(retro.pixelSize, equals(32.0));

      final frosted = MosaicPreset.frostedGlassBackdrop.createConfig();
      expect(frosted.isEnabled, isTrue);
      expect(frosted.type, equals(MosaicType.frostedGlass));
    });
  });

  group('MosaicCompilerService Path & FFmpeg Compilation Tests', () {
    test('buildMosaicPath builds valid vector paths for all shapes', () {
      const size = Size(1920, 1080);

      // Rectangle
      const rectCfg = MosaicConfig(isEnabled: true, type: MosaicType.pixelMosaic, shape: MosaicShape.rectangle);
      final rectPath = MosaicCompilerService.buildMosaicPath(rectCfg, size);
      expect(rectPath.getBounds().isEmpty, isFalse);

      // Ellipse
      const ellipseCfg = MosaicConfig(isEnabled: true, type: MosaicType.pixelMosaic, shape: MosaicShape.ellipse);
      final ellipsePath = MosaicCompilerService.buildMosaicPath(ellipseCfg, size);
      expect(ellipsePath.getBounds().isEmpty, isFalse);

      // Banner Strip
      const bannerCfg = MosaicConfig(isEnabled: true, type: MosaicType.gaussianBlur, shape: MosaicShape.bannerStrip);
      final bannerPath = MosaicCompilerService.buildMosaicPath(bannerCfg, size);
      expect(bannerPath.getBounds().isEmpty, isFalse);

      // Inverted
      const invCfg = MosaicConfig(isEnabled: true, type: MosaicType.pixelMosaic, shape: MosaicShape.rectangle, inverted: true);
      final invPath = MosaicCompilerService.buildMosaicPath(invCfg, size);
      expect(invPath.getBounds().isEmpty, isFalse);
    });

    test('generateFFmpegFilters generates valid filters for full-frame and regional censor', () {
      // Inactive
      expect(MosaicCompilerService.generateFFmpegFilters(const MosaicConfig()), isEmpty);

      // Regional pixel mosaic generates delogo privacy filter
      const regionalConfig = MosaicConfig(
        isEnabled: true,
        type: MosaicType.pixelMosaic,
        shape: MosaicShape.rectangle,
        centerX: 0.5,
        centerY: 0.5,
        width: 0.3,
        height: 0.2,
      );
      final regionalFilters = MosaicCompilerService.generateFFmpegFilters(
        regionalConfig,
        targetWidth: 1920,
        targetHeight: 1080,
      );
      expect(regionalFilters.length, equals(1));
      expect(regionalFilters.first, contains('delogo=x='));
      expect(regionalFilters.first, contains('w=576'));

      // Full frame pixel mosaic generates neighbor down/upscale
      const fullPixelConfig = MosaicConfig(
        isEnabled: true,
        type: MosaicType.pixelMosaic,
        shape: MosaicShape.fullFrame,
        pixelSize: 16.0,
      );
      final fullPixelFilters = MosaicCompilerService.generateFFmpegFilters(
        fullPixelConfig,
        targetWidth: 1920,
        targetHeight: 1080,
      );
      expect(fullPixelFilters.length, equals(2));
      expect(fullPixelFilters.first, contains('flags=neighbor'));

      // Full frame gaussian blur generates boxblur
      const fullBlurConfig = MosaicConfig(
        isEnabled: true,
        type: MosaicType.gaussianBlur,
        shape: MosaicShape.fullFrame,
        blurRadius: 30.0,
      );
      final fullBlurFilters = MosaicCompilerService.generateFFmpegFilters(
        fullBlurConfig,
        targetWidth: 1920,
        targetHeight: 1080,
      );
      expect(fullBlurFilters.length, equals(1));
      expect(fullBlurFilters.first, contains('boxblur=luma_radius=30'));
    });
  });

  group('MosaicOverlayPainter Visual Renderer Tests', () {
    test('MosaicOverlayPainter repaints when configuration changes', () {
      const config1 = MosaicConfig(isEnabled: true, type: MosaicType.pixelMosaic);
      const config2 = MosaicConfig(isEnabled: true, type: MosaicType.gaussianBlur);
      const painter1 = MosaicOverlayPainter(config: config1);
      const painter2 = MosaicOverlayPainter(config: config2);

      expect(painter1.shouldRepaint(painter2), isTrue);
      expect(painter1.shouldRepaint(painter1), isFalse);
    });

    testWidgets('CustomPaint renders MosaicOverlayPainter across all 4 modes without error', (tester) async {
      for (final type in [MosaicType.pixelMosaic, MosaicType.gaussianBlur, MosaicType.hexagonalCrystal, MosaicType.frostedGlass]) {
        final config = MosaicConfig(isEnabled: true, type: type, shape: MosaicShape.rectangle);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 200,
                child: CustomPaint(
                  painter: MosaicOverlayPainter(config: config, showHandles: true),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CustomPaint), findsWidgets);
      }
    });
  });

  group('MosaicSheet Studio Control Widget Tests', () {
    testWidgets('MosaicSheet renders studio controls and toggles parameters', (tester) async {
      Clip currentClip = const Clip(
        id: 'c_test_01',
        assetId: 'a_01',
        trackId: 't_01',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MosaicSheet(
              clip: currentClip,
              onSave: (updated, {applyToAll = false}) {
                currentClip = updated;
              },
              onDone: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Smart Mosaic & Privacy Censor'), findsOneWidget);
      expect(find.text('Enable Privacy Censor'), findsOneWidget);

      // 1. Toggle switch to enable
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(currentClip.mosaic.isEnabled, isTrue);

      // 2. Presets row is now visible
      expect(find.text('Face Censor'), findsOneWidget);
      expect(find.text('License Plate'), findsOneWidget);
      expect(find.text('Confidential Doc'), findsOneWidget);

      // Tap 'Face Censor' preset chip
      await tester.tap(find.text('Face Censor'));
      await tester.pumpAndSettle();

      expect(currentClip.mosaic.shape, equals(MosaicShape.ellipse));
      expect(currentClip.mosaic.type, equals(MosaicType.pixelMosaic));

      // 3. Switch style to Gaussian Blur
      await tester.tap(find.text('Gaussian Privacy Blur'));
      await tester.pumpAndSettle();
      expect(currentClip.mosaic.type, equals(MosaicType.gaussianBlur));

      // 4. Reset button
      final resetFinder = find.byTooltip('Reset');
      expect(resetFinder, findsOneWidget);
      await tester.tap(resetFinder);
      await tester.pumpAndSettle();

      expect(currentClip.mosaic.isEnabled, isFalse);
    });
  });
}
