import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/color_grading/models/color_grading_config.dart';
import 'package:edito/features/color_grading/services/color_filter_compiler_service.dart';

void main() {
  group('HSL 8-Channel Selective Color Qualifier Suite Tests', () {
    test('HslPreset enum provides correct cinematic presets', () {
      expect(HslPreset.selectiveRed.label, contains('Sin City'));
      expect(HslPreset.tealAndOrange.label, equals('Teal & Orange'));
      expect(HslPreset.autumnGold.label, equals('Autumn Gold'));
      expect(HslPreset.emeraldLush.label, equals('Emerald Foliage'));
      expect(HslPreset.urbanDesat.label, equals('Urban Desat'));
    });

    test('Sin City Red Pop preset isolates red and fully desaturates all other 7 sectors', () {
      final shifts = HslPreset.getPresetShifts(HslPreset.selectiveRed);
      expect(shifts.length, equals(8));

      // Red channel is boosted
      expect(shifts['red']?.saturation, greaterThan(0.0));
      expect(shifts['red']?.luminance, greaterThan(0.0));

      // All other 7 channels are desaturated to -1.0
      const otherChannels = ['orange', 'yellow', 'green', 'cyan', 'blue', 'purple', 'magenta'];
      for (final channel in otherChannels) {
        expect(shifts[channel]?.saturation, equals(-1.0), reason: '$channel should be -1.0 desaturated');
      }
    });

    test('Teal & Orange preset configures warm skin tones and cool teal shadows', () {
      final shifts = HslPreset.getPresetShifts(HslPreset.tealAndOrange);
      expect(shifts['orange']?.saturation, greaterThan(0.0));
      expect(shifts['cyan']?.saturation, greaterThan(0.0));
      expect(shifts['blue']?.saturation, greaterThan(0.0));
      expect(shifts['green']?.saturation, lessThan(0.0));
    });

    test('ColorGradingConfig hasActiveHsl detects any active channel shift', () {
      const emptyConfig = ColorGradingConfig();
      expect(emptyConfig.hasActiveHsl, isFalse);

      final withRed = emptyConfig.copyWith(
        hsl: const {'red': HslShift(saturation: 0.5)},
      );
      expect(withRed.hasActiveHsl, isTrue);

      final withHue = emptyConfig.copyWith(
        hsl: const {'blue': HslShift(hue: 25.0)},
      );
      expect(withHue.hasActiveHsl, isTrue);

      final withLum = emptyConfig.copyWith(
        hsl: const {'green': HslShift(luminance: -0.2)},
      );
      expect(withLum.hasActiveHsl, isTrue);
    });

    test('ColorGradingConfig applyHslPreset applies preset shifts cleanly', () {
      const config = ColorGradingConfig();
      final sinCity = config.applyHslPreset(HslPreset.selectiveRed);

      expect(sinCity.hasActiveHsl, isTrue);
      expect(sinCity.hsl['red']?.saturation, equals(0.40));
      expect(sinCity.hsl['green']?.saturation, equals(-1.0));
    });

    test('ColorGradingConfig JSON serialization roundtrip preserves 8-channel HSL shifts', () {
      final config = const ColorGradingConfig().applyHslPreset(HslPreset.selectiveRed);
      final json = config.toJson();
      final restored = ColorGradingConfig.fromJson(json);

      expect(restored.hasActiveHsl, isTrue);
      expect(restored.hsl.length, equals(8));
      expect(restored.hsl['red'], equals(config.hsl['red']));
      expect(restored.hsl['green'], equals(config.hsl['green']));
      expect(restored.hsl['blue'], equals(config.hsl['blue']));
    });

    test('ColorFilterCompilerService isIdentity treats active HSL as non-identity', () {
      const empty = ColorGradingConfig();
      expect(ColorFilterCompilerService.isIdentity(empty), isTrue);

      final active = empty.applyHslPreset(HslPreset.selectiveRed);
      expect(ColorFilterCompilerService.isIdentity(active), isFalse);
    });

    test('ColorFilterCompilerService compileColorMatrix modifies color matrix under HSL shifts', () {
      const empty = ColorGradingConfig();
      final baseMatrix = ColorFilterCompilerService.compileColorMatrix(empty);

      final sinCity = empty.applyHslPreset(HslPreset.selectiveRed);
      final sinCityMatrix = ColorFilterCompilerService.compileColorMatrix(sinCity);

      expect(sinCityMatrix.length, equals(20));
      // Base matrix is identity
      expect(baseMatrix, equals(ColorFilterCompilerService.identityMatrix));
      // Sin City matrix differs from identity
      expect(sinCityMatrix, isNot(equals(baseMatrix)));

      // In Sin City, non-red channels are desaturated towards luminance coefficients
      // Green row has luminance cross-terms
      expect(sinCityMatrix[1], isNot(equals(0.0)));
    });

    test('ColorFilterCompilerService generateFFmpegFilter compiles native selectivecolor filter', () {
      const empty = ColorGradingConfig();
      final filterEmpty = ColorFilterCompilerService.generateFFmpegFilter(empty);
      expect(filterEmpty, isNot(contains('selectivecolor')));

      final sinCity = empty.applyHslPreset(HslPreset.selectiveRed);
      final filterSinCity = ColorFilterCompilerService.generateFFmpegFilter(sinCity);

      expect(filterSinCity, contains('selectivecolor='));
      expect(filterSinCity, contains('reds='));
      expect(filterSinCity, contains('greens='));
      expect(filterSinCity, contains('blues='));
    });

    test('ColorFilterCompilerService getHslBadge returns formatted badge string', () {
      const empty = ColorGradingConfig();
      expect(ColorFilterCompilerService.getHslBadge(empty), isEmpty);

      final sinCity = empty.applyHslPreset(HslPreset.selectiveRed);
      expect(ColorFilterCompilerService.getHslBadge(sinCity), equals('🎯 HSL (8ch)'));

      final twoChannel = empty.copyWith(
        hsl: const {
          'red': HslShift(saturation: 0.3),
          'cyan': HslShift(hue: -10.0),
        },
      );
      expect(ColorFilterCompilerService.getHslBadge(twoChannel), equals('🎯 HSL (2ch)'));
    });
  });
}
