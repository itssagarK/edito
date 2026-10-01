import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/film_grain/models/film_grain_type.dart';
import 'package:edito/features/film_grain/models/film_grain_config.dart';
import 'package:edito/features/film_grain/services/film_grain_compiler_service.dart';
import 'package:edito/features/film_grain/presentation/widgets/film_grain_preview_overlay.dart';
import 'package:edito/features/film_grain/presentation/widgets/film_grain_studio_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    Animate.restartOnHotReload = false;
  });

  group('Film Grain Domain & Model Tests', () {
    test('FilmGrainType enum properties', () {
      for (final type in FilmGrainType.values) {
        expect(type.label.isNotEmpty, isTrue);
        expect(type.subtitle.isNotEmpty, isTrue);
        expect(type.icon, isNotNull);
      }
    });

    test('FilmGrainConfig defaults and active status', () {
      const def = FilmGrainConfig();
      expect(def.isEnabled, isFalse);
      expect(def.isActive, isFalse);
      expect(def.intensity, equals(0.35));
      expect(def.grainSize, equals(1.0));

      final active = def.copyWith(isEnabled: true, intensity: 0.4);
      expect(active.isActive, isTrue);
    });

    test('FilmGrainConfig presets construction and serialization', () {
      for (final preset in FilmGrainPreset.values) {
        final cfg = FilmGrainConfig.fromPreset(preset);
        if (preset == FilmGrainPreset.neutralOff) {
          expect(cfg.isActive, isFalse);
        } else {
          expect(cfg.isActive, isTrue);
        }

        final json = cfg.toJson();
        final copy = FilmGrainConfig.fromJson(json);
        expect(copy.type, equals(cfg.type));
        expect(copy.intensity, equals(cfg.intensity));
      }
    });

    test('Noir B&W preset sets roughness to 0 for monochrome grain', () {
      final noir = FilmGrainConfig.fromPreset(FilmGrainPreset.noirArchival);
      expect(noir.type, equals(FilmGrainType.silverHalide));
      expect(noir.roughness, equals(0.0));
    });
  });

  group('FilmGrainCompilerService Tests', () {
    test('calculateLumaMask returns valid non-linear weights', () {
      final midLuma = FilmGrainCompilerService.calculateLumaMask(0.5);
      expect(midLuma, greaterThan(0.0));
      expect(midLuma, lessThanOrEqualTo(1.0));

      final darkLuma = FilmGrainCompilerService.calculateLumaMask(0.05);
      expect(darkLuma, greaterThanOrEqualTo(0.0));

      final brightLuma = FilmGrainCompilerService.calculateLumaMask(0.95);
      expect(brightLuma, greaterThanOrEqualTo(0.0));
    });

    test('hash13 outputs pseudo-random numbers in [0, 1)', () {
      final val1 = FilmGrainCompilerService.hash13(12.0, 34.0, 56.0);
      final val2 = FilmGrainCompilerService.hash13(12.0, 34.0, 57.0);
      expect(val1, greaterThanOrEqualTo(0.0));
      expect(val1, lessThan(1.0));
      expect(val2, greaterThanOrEqualTo(0.0));
      expect(val2, lessThan(1.0));
      expect(val1, isNot(equals(val2)));
    });

    test('generateFFmpegFilters generates noise commands', () {
      const inactive = FilmGrainConfig();
      expect(FilmGrainCompilerService.generateFFmpegFilters(inactive), isEmpty);

      final active = FilmGrainConfig.fromPreset(FilmGrainPreset.kodakVision3);
      final filters = FilmGrainCompilerService.generateFFmpegFilters(active);
      expect(filters.length, equals(1));
      expect(filters.first, startsWith('noise='));
      expect(filters.first, contains('c0s='));
      expect(filters.first, contains('c0f=t+u'));

      final silverHalide = FilmGrainConfig.fromPreset(FilmGrainPreset.noirArchival);
      final shFilters = FilmGrainCompilerService.generateFFmpegFilters(silverHalide);
      expect(shFilters.first, contains('c1s=0'));
      expect(shFilters.first, contains('c2s=0'));
    });
  });

  group('Film Grain Widget Tests', () {
    testWidgets('FilmGrainPreviewOverlay renders with custom painter', (tester) async {
      const config = FilmGrainConfig(
        isEnabled: true,
        type: FilmGrainType.celluloid35mm,
        intensity: 0.5,
        grainSize: 1.2,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: FilmGrainPreviewOverlay(config: config, seed: 10),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilmGrainPreviewOverlay), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('FilmGrainStudioSheet renders controls, stocks, sliders, and actions', (tester) async {
      final clip = Clip(
        id: 'clip_grain_test',
        assetId: 'asset_1',
        startTimeMs: 0,
        durationMs: 5000,
        filmGrain: FilmGrainConfig.fromPreset(FilmGrainPreset.kodakVision3),
      );

      Clip? savedClip;
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: FilmGrainStudioSheet(
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
      expect(find.text('Film Grain Studio'), findsOneWidget);
      expect(find.text('Edito Pro Celluloid & Texture Engine'), findsOneWidget);
      expect(find.byIcon(Icons.grain), findsWidgets);

      // Check film stock types
      expect(find.text('35mm Film'), findsOneWidget);
      expect(find.text('16mm Indie'), findsOneWidget);
      expect(find.text('Super 8mm'), findsOneWidget);
      expect(find.text('Silver Halide'), findsOneWidget);

      // Tap 16mm Indie card
      await tester.tap(find.text('16mm Indie'));
      await tester.pumpAndSettle();
      expect(savedClip, isNotNull);
      expect(savedClip!.filmGrain.type, equals(FilmGrainType.celluloid16mm));

      // Tap Reset Film Grain button
      await tester.tap(find.text('Reset Film Grain'));
      await tester.pumpAndSettle();
      expect(savedClip!.filmGrain.isActive, isFalse);

      // Tap Done checkmark
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(doneCalled, isTrue);
    });
  });
}
