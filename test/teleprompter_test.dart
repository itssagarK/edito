import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edito/features/teleprompter/models/teleprompter_script.dart';
import 'package:edito/features/teleprompter/models/teleprompter_config.dart';
import 'package:edito/features/teleprompter/presentation/widgets/teleprompter_overlay.dart';
import 'package:edito/features/teleprompter/presentation/widgets/teleprompter_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    Animate.restartOnHotReload = false;
  });

  group('Creator Teleprompter Domain & Script Tests', () {
    test('TeleprompterScript calculates word count and estimated duration correctly', () {
      final script = TeleprompterScript(
        id: 'test_1',
        title: 'Tech Review Hook',
        content: 'Welcome back to my channel! Today we are testing this brand new smartphone camera.',
        createdAt: DateTime(2026, 1, 1),
      );

      // 14 words
      expect(script.wordCount, equals(14));
      // At 120 WPM: 14 words / (120/60) = 7 seconds = 7000ms
      expect(script.estimatedDurationMs(120), equals(7000));
      expect(script.formattedDuration(120), equals('00:07'));

      // At 140 WPM: 14 / (140/60000) = 6000ms = 00:06
      expect(script.estimatedDurationMs(140), equals(6000));
      expect(script.formattedDuration(140), equals('00:06'));
    });

    test('TeleprompterScript serialization and deserialization work deterministically', () {
      final original = TeleprompterScript(
        id: 'script_100',
        title: 'Storytelling Script',
        content: 'Once upon a time in a digital studio...',
        createdAt: DateTime.parse('2026-09-27T12:00:00.000Z'),
      );

      final json = original.toJson();
      final restored = TeleprompterScript.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.content, equals(original.content));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored, equals(original));
    });

    test('TeleprompterScript sample scripts are populated with content', () {
      final samples = TeleprompterScript.samples;
      expect(samples.isNotEmpty, isTrue);
      for (final sample in samples) {
        expect(sample.id.isNotEmpty, isTrue);
        expect(sample.title.isNotEmpty, isTrue);
        expect(sample.content.isNotEmpty, isTrue);
        expect(sample.wordCount, greaterThan(0));
      }
    });

    test('TeleprompterConfig default values and speed presets', () {
      const config = TeleprompterConfig();
      expect(config.isEnabled, isFalse);
      expect(config.scrollSpeedWpm, equals(140));
      expect(config.fontSize, equals(26.0));
      expect(config.lineHeight, equals(1.4));
      expect(config.textAlign, equals(TextAlign.center));
      expect(config.isMirrorMode, isFalse);
      expect(config.countdownSeconds, equals(3));
      expect(config.backgroundOpacity, equals(0.65));
      expect(config.isHighlightFocusLine, isTrue);
      expect(TeleprompterConfig.speedPresets, containsAll([80, 110, 140, 180, 220]));
    });

    test('TeleprompterConfig effectiveScripts and activeScript resolution', () {
      // Empty scripts fall back to samples
      const configWithDefaults = TeleprompterConfig();
      expect(configWithDefaults.effectiveScripts.isNotEmpty, isTrue);
      expect(configWithDefaults.activeScript.title, equals(configWithDefaults.effectiveScripts.first.title));

      // Custom active script ID
      final customScript = TeleprompterScript(
        id: 'custom_promo',
        title: 'Special Promo',
        content: 'Get 50% discount on all presets today.',
      );
      final customConfig = TeleprompterConfig(
        scripts: [customScript],
        activeScriptId: 'custom_promo',
      );
      expect(customConfig.effectiveScripts.length, equals(1));
      expect(customConfig.activeScript.id, equals('custom_promo'));
      expect(customConfig.activeScript.title, equals('Special Promo'));
    });

    test('TeleprompterConfig serialization and copyWith', () {
      final script = TeleprompterScript(
        id: 's1',
        title: 'Title 1',
        content: 'Content 1',
      );
      final original = TeleprompterConfig(
        isEnabled: true,
        scripts: [script],
        activeScriptId: 's1',
        scrollSpeedWpm: 180,
        fontSize: 32.0,
        lineHeight: 1.5,
        textAlign: TextAlign.left,
        isMirrorMode: true,
        countdownSeconds: 5,
        backgroundOpacity: 0.8,
        isHighlightFocusLine: false,
        windowWidth: 0.9,
        windowHeight: 0.45,
        windowYOffset: 0.15,
      );

      final json = original.toJson();
      final restored = TeleprompterConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.activeScriptId, equals('s1'));
      expect(restored.scrollSpeedWpm, equals(180));
      expect(restored.fontSize, equals(32.0));
      expect(restored.textAlign, equals(TextAlign.left));
      expect(restored.isMirrorMode, isTrue);
      expect(restored.countdownSeconds, equals(5));
      expect(restored.backgroundOpacity, equals(0.8));
      expect(restored.isHighlightFocusLine, isFalse);
      expect(restored.windowWidth, equals(0.9));
      expect(restored, equals(original));
    });
  });

  group('Creator Teleprompter Widget Tests', () {
    testWidgets('TeleprompterOverlay renders nothing when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeleprompterOverlay(
              config: TeleprompterConfig(isEnabled: false),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ListView), findsNothing);
      expect(find.text('140 WPM'), findsNothing);
    });

    testWidgets('TeleprompterOverlay renders prompt window and controls when enabled', (tester) async {
      final script = TeleprompterScript(
        id: 'active_1',
        title: 'Opening Monologue',
        content: 'Hello creator community, welcome to the test.',
      );
      final config = TeleprompterConfig(
        isEnabled: true,
        scripts: [script],
        activeScriptId: 'active_1',
        scrollSpeedWpm: 140,
        countdownSeconds: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: TeleprompterOverlay(
                config: config,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Opening Monologue'), findsOneWidget);
      expect(find.text('140 WPM'), findsOneWidget);
      expect(find.text('Hello creator community, welcome to the test.'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      expect(find.byIcon(Icons.replay), findsOneWidget);
    });

    testWidgets('TeleprompterSheet renders studio title and controls', (tester) async {
      TeleprompterConfig currentConfig = const TeleprompterConfig(isEnabled: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 900,
              child: TeleprompterSheet(
                config: currentConfig,
                onSave: (updated) {
                  currentConfig = updated;
                },
                onDone: () {},
                isDocked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Creator Teleprompter Studio'), findsOneWidget);
      expect(find.text('Enable Teleprompter'), findsOneWidget);
      expect(find.text('Speed Presets (WPM)'), findsOneWidget);
      expect(find.text('140 WPM (Normal)'), findsOneWidget);
      expect(find.text('Font Size: 26 pt'), findsOneWidget);
      expect(find.text('Horizontal Mirror Mode'), findsOneWidget);
      expect(find.text('Reading Focus Line Guide'), findsOneWidget);
    });
  });
}
