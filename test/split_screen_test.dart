import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edito/features/split_screen/models/split_screen_preset.dart';
import 'package:edito/features/split_screen/models/split_screen_cell.dart';
import 'package:edito/features/split_screen/models/split_screen_config.dart';
import 'package:edito/features/split_screen/services/split_screen_compiler_service.dart';
import 'package:edito/features/split_screen/presentation/widgets/split_screen_overlay.dart';
import 'package:edito/features/split_screen/presentation/widgets/split_screen_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    Animate.restartOnHotReload = false;
  });

  group('Multi-Grid Split Screen Domain Tests', () {
    test('SplitScreenPresetType returns accurate cell counts and labels', () {
      expect(SplitScreenPresetType.twoVertical.cellCount, equals(2));
      expect(SplitScreenPresetType.twoHorizontal.cellCount, equals(2));
      expect(SplitScreenPresetType.threeVertical.cellCount, equals(3));
      expect(SplitScreenPresetType.threeHorizontal.cellCount, equals(3));
      expect(SplitScreenPresetType.threeTTop.cellCount, equals(3));
      expect(SplitScreenPresetType.threeTBottom.cellCount, equals(3));
      expect(SplitScreenPresetType.fourGrid.cellCount, equals(4));
      expect(SplitScreenPresetType.fiveGrid.cellCount, equals(5));
      expect(SplitScreenPresetType.sixGrid.cellCount, equals(6));
      expect(SplitScreenPresetType.nineGrid.cellCount, equals(9));

      for (final preset in SplitScreenPresetType.values) {
        expect(preset.label.isNotEmpty, isTrue);
        expect(preset.cellRects.length, equals(preset.cellCount));
        for (final rect in preset.cellRects) {
          expect(rect.left, greaterThanOrEqualTo(0.0));
          expect(rect.top, greaterThanOrEqualTo(0.0));
          expect(rect.right, lessThanOrEqualTo(1.001));
          expect(rect.bottom, lessThanOrEqualTo(1.001));
          expect(rect.width, greaterThan(0.0));
          expect(rect.height, greaterThan(0.0));
        }
      }
    });

    test('SplitScreenCell serialization and copyWith', () {
      const cell = SplitScreenCell(
        index: 2,
        clipId: 'clip_abc',
        assetPath: '/videos/reaction.mp4',
        panX: 0.1,
        panY: -0.2,
        scale: 1.5,
        isMuted: true,
        volume: 0.8,
      );

      expect(cell.hasMedia, isTrue);

      final json = cell.toJson();
      final restored = SplitScreenCell.fromJson(json);

      expect(restored.index, equals(2));
      expect(restored.clipId, equals('clip_abc'));
      expect(restored.assetPath, equals('/videos/reaction.mp4'));
      expect(restored.panX, equals(0.1));
      expect(restored.panY, equals(-0.2));
      expect(restored.scale, equals(1.5));
      expect(restored.isMuted, isTrue);
      expect(restored.volume, equals(0.8));
      expect(restored, equals(cell));
    });

    test('SplitScreenConfig defaults and effectiveCells population', () {
      const config = SplitScreenConfig();
      expect(config.isEnabled, isFalse);
      expect(config.preset, equals(SplitScreenPresetType.twoVertical));
      expect(config.borderWidth, equals(2.0));
      expect(config.borderColor, equals(0xFFFFFFFF));
      expect(config.cornerRadius, equals(0.0));

      final cells = config.effectiveCells;
      expect(cells.length, equals(2));
      expect(cells[0].index, equals(0));
      expect(cells[1].index, equals(1));
    });

    test('SplitScreenConfig serialization and cell update', () {
      const original = SplitScreenConfig(
        isEnabled: true,
        preset: SplitScreenPresetType.fourGrid,
        borderWidth: 4.0,
        borderColor: 0xFFBD00FF,
        cornerRadius: 8.0,
        activeCellIndex: 1,
      );

      expect(original.effectiveCells.length, equals(4));

      final updated = original.updateCell(
        const SplitScreenCell(index: 1, clipId: 'clip_gameplay'),
      );
      expect(updated.effectiveCells[1].clipId, equals('clip_gameplay'));

      final json = updated.toJson();
      final restored = SplitScreenConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.preset, equals(SplitScreenPresetType.fourGrid));
      expect(restored.borderWidth, equals(4.0));
      expect(restored.borderColor, equals(0xFFBD00FF));
      expect(restored.cornerRadius, equals(8.0));
      expect(restored.activeCellIndex, equals(1));
      expect(restored.effectiveCells[1].clipId, equals('clip_gameplay'));
    });
  });

  group('SplitScreenCompilerService Tests', () {
    test('resolveAbsoluteCellRect accurately computes pixel coordinates', () {
      final rect = SplitScreenCompilerService.resolveAbsoluteCellRect(
        SplitScreenPresetType.twoVertical,
        1, // right half
        1920,
        1080,
      );

      expect(rect.left, equals(960.0));
      expect(rect.top, equals(0.0));
      expect(rect.width, equals(960.0));
      expect(rect.height, equals(1080.0));
    });

    test('buildFFmpegFilterGraph returns empty string when disabled', () {
      const config = SplitScreenConfig(isEnabled: false);
      final filter = SplitScreenCompilerService.buildFFmpegFilterGraph(
        config: config,
        inputLabels: ['0:v', '1:v'],
      );
      expect(filter, isEmpty);
    });

    test('buildFFmpegFilterGraph constructs valid xstack multi-grid filter', () {
      const config = SplitScreenConfig(
        isEnabled: true,
        preset: SplitScreenPresetType.fourGrid,
        borderWidth: 3.0,
        borderColor: 0xFF00F0FF,
      );

      final filter = SplitScreenCompilerService.buildFFmpegFilterGraph(
        config: config,
        inputLabels: ['0:v', '1:v', '2:v', '3:v'],
        outputWidth: 1920,
        outputHeight: 1080,
      );

      expect(filter, contains('[0:v]scale=960:540'));
      expect(filter, contains('[1:v]scale=960:540'));
      expect(filter, contains('[2:v]scale=960:540'));
      expect(filter, contains('[3:v]scale=960:540'));
      expect(filter, contains('xstack=inputs=4'));
      expect(filter, contains('0_0|960_0|0_540|960_540'));
      expect(filter, contains('drawbox'));
    });
  });

  group('Split Screen Widget Tests', () {
    testWidgets('SplitScreenOverlay renders nothing when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SplitScreenOverlay(
              config: SplitScreenConfig(isEnabled: false),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('#1'), findsNothing);
      expect(find.text('Slot 1'), findsNothing);
    });

    testWidgets('SplitScreenOverlay renders slots and highlights active cell', (tester) async {
      int? selectedIndex;

      const config = SplitScreenConfig(
        isEnabled: true,
        preset: SplitScreenPresetType.twoHorizontal,
        activeCellIndex: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: SplitScreenOverlay(
                config: config,
                onSelectCell: (idx) => selectedIndex = idx,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('Slot 1'), findsOneWidget);
      expect(find.text('Slot 2'), findsOneWidget);

      await tester.tap(find.text('Slot 2'));
      await tester.pump();
      expect(selectedIndex, equals(1));
    });

    testWidgets('SplitScreenSheet renders studio controls, presets and sliders', (tester) async {
      SplitScreenConfig currentConfig = const SplitScreenConfig(
        isEnabled: true,
        preset: SplitScreenPresetType.fourGrid,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 900,
              child: SplitScreenSheet(
                config: currentConfig,
                onSave: (c) => currentConfig = c,
                onDone: () {},
                isDocked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Multi-Grid Split Screen Studio'), findsOneWidget);
      expect(find.text('Split Screen Collage'), findsOneWidget);
      expect(find.text('Grid Layout Presets'), findsOneWidget);
      expect(find.text('4 Slots'), findsOneWidget);
      expect(find.text('Media Slots & Assignment'), findsOneWidget);
      expect(find.text('Slot 1'), findsOneWidget);
      expect(find.text('Slot 4'), findsOneWidget);
      expect(find.text('Grid Dividers & Frame Style'), findsOneWidget);
      expect(find.text('Divider Width'), findsOneWidget);
      expect(find.text('Cell Rounded Corners'), findsOneWidget);
    });
  });
}
