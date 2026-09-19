import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/color_grading/models/color_grading_config.dart';
import 'package:edito/features/color_grading/presentation/widgets/color_wheel_widget.dart';
import 'package:edito/features/color_grading/services/color_filter_compiler_service.dart';
import 'package:edito/features/editor/presentation/widgets/editing_toolbar.dart';
import 'package:edito/features/editor/providers/editor_provider.dart';

void main() {
  group('Feature 18 - 3-Way Color Wheels Model & Presets Tests', () {
    test('ColorWheelValue default initialization is inactive and neutral', () {
      const value = ColorWheelValue();
      expect(value.angle, 0.0);
      expect(value.saturation, 0.0);
      expect(value.luminance, 0.0);
      expect(value.isActive, isFalse);
    });

    test('ColorWheelValue isActive becomes true with non-zero saturation or luminance', () {
      const activeSat = ColorWheelValue(angle: 180.0, saturation: 0.25);
      expect(activeSat.isActive, isTrue);

      const activeLum = ColorWheelValue(luminance: -0.15);
      expect(activeLum.isActive, isTrue);
    });

    test('ColorWheelValue JSON serialization round-trip', () {
      const original = ColorWheelValue(angle: 215.5, saturation: 0.65, luminance: 0.12);
      final json = original.toJson();
      final restored = ColorWheelValue.fromJson(json);

      expect(restored.angle, 215.5);
      expect(restored.saturation, 0.65);
      expect(restored.luminance, 0.12);
      expect(restored, equals(original));
    });

    test('ColorWheelsPreset values all have non-empty labels', () {
      for (final preset in ColorWheelsPreset.values) {
        expect(preset.label.isNotEmpty, isTrue);
      }
      expect(ColorWheelsPreset.values.length, 7);
    });

    test('applyColorWheelsPreset applies blockbuster Teal and Orange accurately', () {
      const config = ColorGradingConfig();
      final graded = config.applyColorWheelsPreset(ColorWheelsPreset.tealAndOrange);

      expect(graded.lift.isActive, isTrue);
      expect(graded.lift.angle, 195.0);
      expect(graded.lift.saturation, 0.35);

      expect(graded.gain.isActive, isTrue);
      expect(graded.gain.angle, 35.0);
      expect(graded.gain.saturation, 0.40);

      expect(graded.isGraded, isTrue);
    });

    test('applyColorWheelsPreset neutral resets all 4 wheels', () {
      const config = ColorGradingConfig(
        lift: ColorWheelValue(angle: 120.0, saturation: 0.5),
        gain: ColorWheelValue(angle: 240.0, saturation: 0.5),
      );
      expect(config.lift.isActive, isTrue);

      final reset = config.applyColorWheelsPreset(ColorWheelsPreset.neutral);
      expect(reset.lift.isActive, isFalse);
      expect(reset.gamma.isActive, isFalse);
      expect(reset.gain.isActive, isFalse);
      expect(reset.offset.isActive, isFalse);
    });

    test('ColorFilterCompilerService generates colorbalance filter for active wheels', () {
      const config = ColorGradingConfig(
        lift: ColorWheelValue(angle: 195.0, saturation: 0.35, luminance: -0.05),
        gain: ColorWheelValue(angle: 35.0, saturation: 0.40, luminance: 0.08),
      );

      expect(ColorFilterCompilerService.isIdentity(config), isFalse);

      final ffmpegFilter = ColorFilterCompilerService.generateFFmpegFilter(config);
      expect(ffmpegFilter, contains('colorbalance='));
      expect(ffmpegFilter, contains('rs='));
      expect(ffmpegFilter, contains('gs='));
      expect(ffmpegFilter, contains('bs='));
      expect(ffmpegFilter, contains('rm='));
      expect(ffmpegFilter, contains('gm='));
      expect(ffmpegFilter, contains('bm='));
      expect(ffmpegFilter, contains('rh='));
      expect(ffmpegFilter, contains('gh='));
      expect(ffmpegFilter, contains('bh='));

      final matrix = ColorFilterCompilerService.compileColorMatrix(config);
      expect(matrix.length, 20);
      expect(matrix, isNot(equals(ColorFilterCompilerService.identityMatrix)));
    });
  });

  group('Feature 18 - CapCut Two-Tier Contextual Dock Widget Tests', () {
    testWidgets('EditingToolbar displays global categories when no clip is selected', (tester) async {
      EditorTool? selectedTool;
      bool addTrackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: EditingToolbar(
              activeTool: EditorTool.select,
              hasSelectedClip: false,
              onSelectTool: (tool) => selectedTool = tool,
              onAddTrack: () => addTrackCalled = true,
            ),
          ),
        ),
      );

      // Verify Global Categories are rendered
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Captions'), findsOneWidget);
      expect(find.text('Overlay'), findsOneWidget);
      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Add Track'), findsOneWidget);

      // Back button must NOT be present in global mode
      expect(find.text('Back'), findsNothing);

      // Tap on Filters
      await tester.tap(find.text('Filters'));
      expect(selectedTool, equals(EditorTool.color));

      // Tap on Add Track
      await tester.tap(find.text('Add Track'));
      expect(addTrackCalled, isTrue);
    });

    testWidgets('EditingToolbar displays contextual clip actions with Back button when clip is selected', (tester) async {
      EditorTool? selectedTool;
      bool deselectCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: EditingToolbar(
              activeTool: EditorTool.split,
              hasSelectedClip: true,
              onSelectTool: (tool) => selectedTool = tool,
              onDeselectClip: () => deselectCalled = true,
              onAddTrack: () {},
            ),
          ),
        ),
      );

      // Verify Back button and Clip Actions are present
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Split'), findsOneWidget);
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('Animation'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('Cutout'), findsOneWidget);
      expect(find.text('Mask'), findsOneWidget);
      expect(find.text('Blend'), findsOneWidget);

      // Tap Back button
      await tester.tap(find.text('Back'));
      expect(deselectCalled, isTrue);

      // Tap Split tool
      await tester.tap(find.text('Split'));
      expect(selectedTool, equals(EditorTool.split));
    });

    testWidgets('ColorWheelWidget renders and triggers callbacks', (tester) async {
      ColorWheelValue currentValue = const ColorWheelValue();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ColorWheelWidget(
                  label: 'LIFT (SHADOWS)',
                  description: 'Shadow control 0-25%',
                  value: currentValue,
                  size: 160.0,
                  accentColor: const Color(0xFF00E5FF),
                  onChanged: (val) {
                    setState(() => currentValue = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('LIFT (SHADOWS)'), findsOneWidget);
      expect(find.text('Shadow control 0-25%'), findsOneWidget);
      expect(find.text('0° • 0%'), findsOneWidget);
    });
  });
}
