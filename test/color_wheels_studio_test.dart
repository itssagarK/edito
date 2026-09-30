import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/color_wheels/models/wheel_channel_value.dart';
import 'package:edito/features/color_wheels/models/color_wheels_config.dart';
import 'package:edito/features/color_wheels/services/color_wheels_compiler_service.dart';
import 'package:edito/features/color_wheels/presentation/widgets/color_wheel_disc_widget.dart';
import 'package:edito/features/color_wheels/presentation/widgets/color_wheels_studio_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    Animate.restartOnHotReload = false;
  });

  group('Color Wheels Domain & Model Tests', () {
    test('WheelChannelValue default state and factory constructors', () {
      const def = WheelChannelValue();
      expect(def.isDefault, isTrue);
      expect(def.saturation, equals(0.0));
      expect(def.luminance, equals(0.0));

      final fromHsl = WheelChannelValue.fromHsl(angle: 180.0, saturation: 0.5, luminance: 0.1);
      expect(fromHsl.angle, equals(180.0));
      expect(fromHsl.saturation, equals(0.5));
      expect(fromHsl.luminance, equals(0.1));
      expect(fromHsl.isDefault, isFalse);

      final fromRgb = WheelChannelValue.fromRgb(red: 0.3, green: -0.2, blue: 0.1, luminance: -0.05);
      expect(fromRgb.red, closeTo(0.3, 1e-3));
      expect(fromRgb.luminance, equals(-0.05));
    });

    test('WheelChannelValue serialization and deserialization round-trip', () {
      final val = WheelChannelValue.fromHsl(angle: 45.0, saturation: 0.6, luminance: 0.15);
      final json = val.toJson();
      final copy = WheelChannelValue.fromJson(json);
      expect(copy, equals(val));
    });

    test('PrimaryWheelConfig and LogWheelConfig defaults and serialization', () {
      const primary = PrimaryWheelConfig();
      expect(primary.isDefault, isTrue);
      expect(primary.lumaMix, equals(0.50));

      final pJson = primary.toJson();
      final pCopy = PrimaryWheelConfig.fromJson(pJson);
      expect(pCopy, equals(primary));

      const log = LogWheelConfig();
      expect(log.isDefault, isTrue);
      expect(log.lowRange, equals(0.33));
      expect(log.highRange, equals(0.66));

      final lJson = log.toJson();
      final lCopy = LogWheelConfig.fromJson(lJson);
      expect(lCopy, equals(log));
    });

    test('ColorWheelsConfig presets correctly initialize grading parameters', () {
      for (final preset in ColorWheelsPreset.values) {
        expect(preset.label, isNotEmpty);
        expect(preset.description, isNotEmpty);
      }

      final tealOrange = ColorWheelsConfig.fromPreset(ColorWheelsPreset.blockbusterTealOrange);
      expect(tealOrange.isEnabled, isTrue);
      expect(tealOrange.mode, equals(ColorWheelsMode.primary));
      expect(tealOrange.primary.lift.angle, equals(195.0)); // Cyan shadows
      expect(tealOrange.primary.lumaMix, equals(0.60));
      expect(tealOrange.isActive, isTrue);

      final bleach = ColorWheelsConfig.fromPreset(ColorWheelsPreset.bleachBypass);
      expect(bleach.mode, equals(ColorWheelsMode.log));
      expect(bleach.log.lowRange, equals(0.28));
      expect(bleach.log.highRange, equals(0.72));
      expect(bleach.isActive, isTrue);
    });

    test('ColorWheelsConfig isActive logic requires isEnabled and non-default config', () {
      const def = ColorWheelsConfig();
      expect(def.isActive, isFalse);

      const enabledEmpty = ColorWheelsConfig(isEnabled: true);
      expect(enabledEmpty.isActive, isFalse);

      final active = ColorWheelsConfig.fromPreset(ColorWheelsPreset.goldenHour);
      expect(active.isActive, isTrue);

      final zeroIntensity = active.copyWith(masterIntensity: 0.0);
      expect(zeroIntensity.isActive, isFalse);
    });

    test('Clip serialization preserves colorWheels config', () {
      final clip = Clip(
        id: 'clip_wheels_1',
        assetId: 'asset_1',
        startTimeMs: 0,
        durationMs: 4000,
        colorWheels: ColorWheelsConfig.fromPreset(ColorWheelsPreset.blockbusterTealOrange),
      );

      final json = clip.toJson();
      final reconstructed = Clip.fromJson(json);

      expect(reconstructed.colorWheels.isEnabled, isTrue);
      expect(reconstructed.colorWheels.mode, equals(ColorWheelsMode.primary));
      expect(reconstructed.colorWheels.primary.lumaMix, equals(0.60));
      expect(reconstructed.colorWheels.isActive, isTrue);
    });
  });

  group('Color Wheels Mathematical Compiler Service Tests', () {
    test('processPrimaryWheel calculates valid non-clipping curve output', () {
      final out1 = ColorWheelsCompilerService.processPrimaryWheel(0.5, 0.0, 1.0, 1.0);
      expect(out1, closeTo(0.5, 0.05));

      final outLifted = ColorWheelsCompilerService.processPrimaryWheel(0.2, 0.1, 1.0, 1.0);
      expect(outLifted, greaterThan(0.0));
      expect(outLifted, lessThanOrEqualTo(1.0));
    });

    test('processLogWheel handles smooth crossover between Shadow, Midtone and Highlight', () {
      final shadowVal = ColorWheelsCompilerService.processLogWheel(
        src: 0.15,
        shadowWeight: 0.25,
        midtoneWeight: 0.0,
        highlightWeight: 0.0,
        offset: 0.0,
        lowRange: 0.33,
        highRange: 0.66,
      );
      expect(shadowVal, greaterThan(0.15));

      final midVal = ColorWheelsCompilerService.processLogWheel(
        src: 0.50,
        shadowWeight: 0.0,
        midtoneWeight: 0.20,
        highlightWeight: 0.0,
        offset: 0.0,
        lowRange: 0.33,
        highRange: 0.66,
      );
      expect(midVal, greaterThan(0.50));
    });

    test('generate4x5ColorMatrix produces 20-element Skia matrix', () {
      const def = ColorWheelsConfig();
      final idMatrix = ColorWheelsCompilerService.generate4x5ColorMatrix(def);
      expect(idMatrix.length, equals(20));
      expect(idMatrix[0], equals(1.0)); // R scale
      expect(idMatrix[6], equals(1.0)); // G scale
      expect(idMatrix[12], equals(1.0)); // B scale

      final active = ColorWheelsConfig.fromPreset(ColorWheelsPreset.blockbusterTealOrange);
      final activeMatrix = ColorWheelsCompilerService.generate4x5ColorMatrix(active);
      expect(activeMatrix.length, equals(20));
    });

    test('generateFFmpegFilters compiles colorbalance and eq filter strings', () {
      const def = ColorWheelsConfig();
      final emptyFilters = ColorWheelsCompilerService.generateFFmpegFilters(def);
      expect(emptyFilters, isEmpty);

      final active = ColorWheelsConfig.fromPreset(ColorWheelsPreset.blockbusterTealOrange);
      final filters = ColorWheelsCompilerService.generateFFmpegFilters(active);
      expect(filters, isNotEmpty);
      expect(filters.any((f) => f.contains('colorbalance')), isTrue);
    });
  });

  group('Color Wheels Presentation & Widget Tests', () {
    testWidgets('ColorWheelDiscWidget renders interactive disc and slider', (tester) async {
      WheelChannelValue currentValue = WheelChannelValue.fromHsl(angle: 60.0, saturation: 0.4, luminance: 0.1);
      WheelChannelValue? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ColorWheelDiscWidget(
                label: 'LIFT (SHADOWS)',
                value: currentValue,
                accentColor: const Color(0xFF00E5FF),
                onChanged: (v) => changedValue = v,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LIFT (SHADOWS)'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(Slider), findsOneWidget);

      // Pan gesture on wheel disc
      await tester.drag(find.byType(CustomPaint).first, const Offset(15, -15));
      await tester.pumpAndSettle();
    });

    testWidgets('ColorWheelsStudioSheet renders modes, tabs, sliders, and presets', (tester) async {
      final clip = Clip(
        id: 'clip_test_wheels',
        assetId: 'asset_1',
        startTimeMs: 0,
        durationMs: 5000,
        colorWheels: ColorWheelsConfig.fromPreset(ColorWheelsPreset.blockbusterTealOrange),
      );

      Clip? savedClip;
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: ColorWheelsStudioSheet(
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
      expect(find.text('Color Wheels Studio'), findsOneWidget);
      expect(find.text('Edito Pro Primary & Log Grading'), findsOneWidget);
      expect(find.byIcon(Icons.donut_large), findsWidgets);

      // Check modes
      expect(find.text('Primary Wheels'), findsWidgets);
      expect(find.text('Log Wheels'), findsWidgets);

      // Check view selector
      expect(find.text('ALL 4'), findsOneWidget);
      expect(find.text('LIFT'), findsOneWidget);
      expect(find.text('GAMMA'), findsOneWidget);

      // Switch to single focused wheel (LIFT)
      await tester.tap(find.text('LIFT'));
      await tester.pumpAndSettle();

      // Switch to Log Wheels mode
      await tester.tap(find.text('Log Wheels').first);
      await tester.pumpAndSettle();

      expect(find.text('SHADOW'), findsOneWidget);
      expect(find.text('Low Range (Shadow Crossover)'), findsOneWidget);

      // Tap Reset button
      await tester.tap(find.text('Reset All Color Wheels'));
      await tester.pumpAndSettle();
      expect(savedClip, isNotNull);

      // Tap Done checkmark
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(doneCalled, isTrue);
    });
  });
}
