import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/vignette/models/vignette_config.dart';
import 'package:edito/features/vignette/services/vignette_compiler_service.dart';
import 'package:edito/features/vignette/presentation/widgets/vignette_preview_overlay.dart';
import 'package:edito/features/vignette/presentation/widgets/vignette_studio_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VignetteConfig Model Tests', () {
    test('default configuration has correct initial values', () {
      const config = VignetteConfig();
      expect(config.isEnabled, isFalse);
      expect(config.intensity, equals(0.45));
      expect(config.radius, equals(0.60));
      expect(config.feather, equals(0.50));
      expect(config.roundness, equals(0.0));
      expect(config.centerX, equals(0.0));
      expect(config.centerY, equals(0.0));
      expect(config.tint, equals(VignetteTint.carbonBlack));
      expect(config.hasActiveVignette, isFalse);
    });

    test('hasActiveVignette is true only when enabled and non-zero intensity', () {
      const disabled = VignetteConfig(isEnabled: false, intensity: 0.5);
      expect(disabled.hasActiveVignette, isFalse);

      const enabledZero = VignetteConfig(isEnabled: true, intensity: 0.0);
      expect(enabledZero.hasActiveVignette, isFalse);

      const enabledActive = VignetteConfig(isEnabled: true, intensity: 0.45);
      expect(enabledActive.hasActiveVignette, isTrue);

      const spotlightActive = VignetteConfig(isEnabled: true, intensity: -0.5);
      expect(spotlightActive.hasActiveVignette, isTrue);
    });

    test('all presets initialize with expected profiles', () {
      for (final preset in VignettePreset.values) {
        final config = VignetteConfig.fromPreset(preset);
        expect(preset.label, isNotEmpty);
        expect(preset.description, isNotEmpty);

        if (preset == VignettePreset.neutralOff) {
          expect(config.isEnabled, isFalse);
        } else {
          expect(config.isEnabled, isTrue);
          expect(config.intensity.abs(), greaterThan(0.0));
        }

        if (preset == VignettePreset.dreamyHighKey) {
          expect(config.intensity, lessThan(0.0)); // Negative for white spotlight
          expect(config.tint, equals(VignetteTint.frostWhite));
        } else if (preset == VignettePreset.anamorphicWidescreen) {
          expect(config.roundness, lessThan(0.0)); // Widescreen deformation
        } else if (preset == VignettePreset.goldenHour) {
          expect(config.tint, equals(VignetteTint.warmAmber));
        }
      }
    });

    test('copyWith properly overrides values', () {
      const initial = VignetteConfig();
      final updated = initial.copyWith(
        isEnabled: true,
        intensity: 0.85,
        radius: 0.40,
        roundness: -0.3,
        tint: VignetteTint.midnightBlue,
      );

      expect(updated.isEnabled, isTrue);
      expect(updated.intensity, equals(0.85));
      expect(updated.radius, equals(0.40));
      expect(updated.roundness, equals(-0.3));
      expect(updated.tint, equals(VignetteTint.midnightBlue));
      expect(updated.feather, equals(initial.feather)); // preserved
    });

    test('serialization roundtrip produces equal instance', () {
      const original = VignetteConfig(
        isEnabled: true,
        intensity: -0.65,
        radius: 0.45,
        feather: 0.70,
        roundness: 0.25,
        centerX: -0.15,
        centerY: 0.20,
        tint: VignetteTint.vintageSepia,
      );

      final json = original.toJson();
      final reconstructed = VignetteConfig.fromJson(json);

      expect(reconstructed, equals(original));
      expect(reconstructed.intensity, equals(-0.65));
      expect(reconstructed.tint, equals(VignetteTint.vintageSepia));
    });
  });

  group('VignetteCompilerService Math & Shader Tests', () {
    test('falloff calculation preserves clear focal center', () {
      const config = VignetteConfig(
        isEnabled: true,
        intensity: 0.5,
        radius: 0.6,
        feather: 0.5,
      );

      // (0.5, 0.5) is dead center in UV coordinates
      final centerFalloff = VignetteCompilerService.computeFalloffAt(
        u: 0.5,
        v: 0.5,
        config: config,
      );
      expect(centerFalloff, equals(0.0));
    });

    test('falloff calculation smoothly darkens corners', () {
      const config = VignetteConfig(
        isEnabled: true,
        intensity: 0.8,
        radius: 0.4,
        feather: 0.4,
      );

      // (0.0, 0.0) is the top-left corner
      final cornerFalloff = VignetteCompilerService.computeFalloffAt(
        u: 0.0,
        v: 0.0,
        config: config,
      );
      expect(cornerFalloff, greaterThan(0.0));
      expect(cornerFalloff, lessThanOrEqualTo(0.8));
    });

    test('anamorphic roundness alters horizontal and vertical falloffs', () {
      const anamorphic = VignetteConfig(
        isEnabled: true,
        intensity: 0.5,
        radius: 0.5,
        feather: 0.5,
        roundness: -0.8, // stretched horizontally
      );

      // Point along X vs point along Y
      final falloffX = VignetteCompilerService.computeFalloffAt(u: 0.85, v: 0.5, config: anamorphic);
      final falloffY = VignetteCompilerService.computeFalloffAt(u: 0.5, v: 0.85, config: anamorphic);

      // Due to horizontal oval stretch, edge falloff arrives further out horizontally
      expect(falloffX, isNot(equals(falloffY)));
    });

    test('generateFFmpegFilters produces native vignette filter', () {
      const config = VignetteConfig(
        isEnabled: true,
        intensity: 0.65,
        radius: 0.55,
        feather: 0.50,
        centerX: 0.1,
        centerY: -0.2,
      );

      final filters = VignetteCompilerService.generateFFmpegFilters(config);
      expect(filters, isNotEmpty);
      expect(filters.first, startsWith('vignette='));
      expect(filters.first, contains('mode=forward'));
      expect(filters.first, contains('x0=\'w*0.550\''));
      expect(filters.first, contains('y0=\'h*0.400\''));
    });

    test('generateFFmpegFilters switches to backward mode for spotlight', () {
      const spotlight = VignetteConfig(
        isEnabled: true,
        intensity: -0.50, // Negative for spotlight
      );

      final filters = VignetteCompilerService.generateFFmpegFilters(spotlight);
      expect(filters, isNotEmpty);
      expect(filters.first, contains('mode=backward'));
    });

    test('generateFFmpegFilters adds color grading filter for tinted presets', () {
      const sepia = VignetteConfig(
        isEnabled: true,
        intensity: 0.70,
        tint: VignetteTint.vintageSepia,
      );

      final filters = VignetteCompilerService.generateFFmpegFilters(sepia);
      expect(filters.length, equals(2));
      expect(filters.last, contains('colorchannelmixer='));
    });

    test('generateFFmpegFilters returns empty list when inactive', () {
      const inactive = VignetteConfig(isEnabled: false);
      expect(VignetteCompilerService.generateFFmpegFilters(inactive), isEmpty);
    });
  });

  group('Vignette UI & Overlay Widget Tests', () {
    testWidgets('VignettePreviewOverlay renders Skia CustomPaint when active', (tester) async {
      const config = VignetteConfig(
        isEnabled: true,
        intensity: 0.6,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: VignettePreviewOverlay(config: config),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('VignettePreviewOverlay renders reticle when showReticle is true', (tester) async {
      const config = VignetteConfig(
        isEnabled: true,
        intensity: 0.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: VignettePreviewOverlay(
                config: config,
                showReticle: true,
                onCenterChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('VignetteStudioSheet renders presets and responds to preset selection', (tester) async {
      VignetteConfig currentConfig = const VignetteConfig(isEnabled: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VignetteStudioSheet(
              initialConfig: currentConfig,
              onChanged: (updated) {
                currentConfig = updated;
              },
            ),
          ),
        ),
      );

      expect(find.text('Cinematic Vignette & Spotlight'), findsOneWidget);
      expect(find.text('CINEMATIC PRESETS'), findsOneWidget);
      expect(find.text('35mm Film'), findsOneWidget);
      expect(find.text('Vintage Drama'), findsOneWidget);
      expect(find.text('Anamorphic'), findsOneWidget);
      expect(find.text('Dreamy Light'), findsOneWidget);

      // Tap '35mm Film' preset
      await tester.tap(find.text('35mm Film'));
      await tester.pumpAndSettle();

      expect(currentConfig.isEnabled, isTrue);
      expect(currentConfig.intensity, equals(0.45));
    });
  });
}
