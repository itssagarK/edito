import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/overlays/models/text_overlay_config.dart';
import 'package:edito/features/overlays/models/text_preset_style.dart';
import 'package:edito/features/overlays/presentation/widgets/curved_text_painter.dart';
import 'package:edito/features/overlays/presentation/widgets/text_editor_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    Animate.restartOnHotReload = false;
  });

  group('CapCut Studio Typography & Text Effects Suite Domain Tests', () {
    test('TextOverlayConfig defaults include flat curve and inactive glow', () {
      const config = TextOverlayConfig();
      expect(config.curveAngle, equals(0.0));
      expect(config.offsetOnCurve, equals(0.0));
      expect(config.glowColor, isNull);
      expect(config.glowRadius, equals(0.0));
      expect(config.glowIntensity, equals(0.0));
      expect(config.shadowOffsetX, equals(0.0));
      expect(config.shadowOffsetY, equals(2.0));
    });

    test('TextOverlayConfig serialization and deserialization with curve & glow', () {
      const original = TextOverlayConfig(
        text: 'Curved Neon Cyberpunk',
        fontFamily: 'BebasNeue',
        fontSize: 36.0,
        textColor: 0xFF00F0FF,
        curveAngle: 45.0,
        offsetOnCurve: 0.2,
        glowColor: 0xFFFF0855,
        glowRadius: 18.0,
        glowIntensity: 0.95,
        shadowOffsetX: 3.0,
        shadowOffsetY: 4.0,
      );

      final json = original.toJson();
      final restored = TextOverlayConfig.fromJson(json);

      expect(restored.text, equals('Curved Neon Cyberpunk'));
      expect(restored.curveAngle, equals(45.0));
      expect(restored.offsetOnCurve, equals(0.2));
      expect(restored.glowColor, equals(0xFFFF0855));
      expect(restored.glowRadius, equals(18.0));
      expect(restored.glowIntensity, equals(0.95));
      expect(restored.shadowOffsetX, equals(3.0));
      expect(restored.shadowOffsetY, equals(4.0));
      expect(restored, equals(original));
    });

    test('TextPresetStyle presets list contains CapCut signature styles across all categories', () {
      final presets = TextPresetStyle.presets;
      expect(presets.length, greaterThanOrEqualTo(18));

      final categories = presets.map((p) => p.category).toSet();
      expect(categories, containsAll(['Classic', 'Strokes', 'Badges', 'Shadows', 'Neon Glow']));

      for (final p in presets) {
        expect(p.id.isNotEmpty, isTrue);
        expect(p.name.isNotEmpty, isTrue);
        expect(p.fillColor, isNonZero);
      }
    });

    test('TextPresetStyle applyTo correctly overrides TextOverlayConfig attributes', () {
      const baseConfig = TextOverlayConfig(
        text: 'Dynamic Preset Test',
        textColor: 0xFFFFFFFF,
      );

      final neonCrimson = TextPresetStyle.presets.firstWhere((p) => p.id == 'neon_red_glow');
      final updatedConfig = neonCrimson.applyTo(baseConfig);

      expect(updatedConfig.text, equals('Dynamic Preset Test'));
      expect(updatedConfig.glowColor, equals(0xFFFF0855));
      expect(updatedConfig.glowRadius, equals(18.0));
      expect(updatedConfig.glowIntensity, equals(0.95));

      final yellowBadge = TextPresetStyle.presets.firstWhere((p) => p.id == 'black_yellow_badge');
      final badgeConfig = yellowBadge.applyTo(baseConfig);

      expect(badgeConfig.textColor, equals(0xFF000000));
      expect(badgeConfig.backgroundColor, equals(0xFFFFDC00));
    });
  });

  group('Curved Text & Glow Widget Tests', () {
    testWidgets('CurvedTextWidget renders standard text when curveAngle is 0', (tester) async {
      const config = TextOverlayConfig(
        text: 'Straight Studio Title',
        fontSize: 24.0,
        curveAngle: 0.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CurvedTextWidget(
              config: config,
              baseStyle: TextStyle(fontSize: 24.0),
              displayText: 'Straight Studio Title',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Straight Studio Title'), findsOneWidget);
      expect(find.byType(CustomPaint), findsNothing);
    });

    testWidgets('CurvedTextWidget uses CustomPaint when curveAngle != 0', (tester) async {
      const config = TextOverlayConfig(
        text: 'Curved Dome Title',
        fontSize: 28.0,
        curveAngle: 60.0,
        glowColor: 0xFF00F0FF,
        glowRadius: 12.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CurvedTextWidget(
              config: config,
              baseStyle: TextStyle(fontSize: 28.0),
              displayText: 'Curved Dome Title',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('TextEditorSheet renders all 6 tabs including Presets and Curve & Glow', (tester) async {
      const clip = Clip(
        id: 'c1',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        textOverlay: TextOverlayConfig(
          text: 'Edito Pro Typography',
          fontSize: 26.0,
        ),
      );

      Clip updatedClip = clip;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 900,
              child: TextEditorSheet(
                clip: clip,
                onSave: (c) => updatedClip = c,
                isDocked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify all tabs exist
      expect(find.text('Presets'), findsOneWidget);
      expect(find.text('Style & Font'), findsOneWidget);
      expect(find.text('Curve & Glow'), findsOneWidget);
      expect(find.text('Animation'), findsOneWidget);
      expect(find.text('Position'), findsOneWidget);
      expect(find.text('Keyframes'), findsOneWidget);

      // Verify Presets content is rendered
      expect(find.text('White Outline'), findsOneWidget);
      expect(find.text('Cyber Yellow'), findsOneWidget);

      // Tap on Curve & Glow tab
      await tester.tap(find.text('Curve & Glow'));
      await tester.pumpAndSettle();

      expect(find.text('Curved Text Arc'), findsOneWidget);
      expect(find.text('Flat 0°'), findsOneWidget);
      expect(find.text('Arch +45°'), findsOneWidget);
      expect(find.text('Neon Glow & Outer Halo'), findsOneWidget);
      expect(find.text('Glow Spread / Radius'), findsOneWidget);
    });
  });
}
