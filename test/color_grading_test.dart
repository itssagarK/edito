import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/color_grading/models/color_grading_config.dart';
import 'package:edito/features/color_grading/services/color_filter_compiler_service.dart';

void main() {
  group('Color Grading & 3D LUT Pipeline Tests', () {
    test('ColorGradingConfig JSON serialization roundtrip', () {
      final config = ColorGradingConfig(
        exposure: 0.5,
        contrast: 1.2,
        saturation: 1.3,
        temperature: 25.0,
        tint: -10.0,
        vignette: 0.4,
        activeLut: LutPreset.tealAndOrange,
        lutIntensity: 0.85,
        hsl: const {
          'red': HslShift(hue: 10.0, saturation: 0.2, luminance: -0.1),
          'cyan': HslShift(hue: -15.0, saturation: 0.4, luminance: 0.1),
        },
        masterCurve: const [
          CurvePoint(0.0, 0.0),
          CurvePoint(0.5, 0.6),
          CurvePoint(1.0, 1.0),
        ],
      );

      final json = config.toJson();
      final restored = ColorGradingConfig.fromJson(json);

      expect(restored.exposure, equals(0.5));
      expect(restored.contrast, equals(1.2));
      expect(restored.saturation, equals(1.3));
      expect(restored.temperature, equals(25.0));
      expect(restored.tint, equals(-10.0));
      expect(restored.vignette, equals(0.4));
      expect(restored.activeLut, equals(LutPreset.tealAndOrange));
      expect(restored.lutIntensity, equals(0.85));
      expect(restored.hsl['red']?.hue, equals(10.0));
      expect(restored.masterCurve.length, equals(3));
    });

    test('ColorFilterCompilerService generates 4x5 20-element color matrix', () {
      const config = ColorGradingConfig(
        contrast: 1.15,
        saturation: 1.20,
        temperature: 30.0,
        exposure: 0.4,
      );

      final matrix = ColorFilterCompilerService.compileColorMatrix(config);

      expect(matrix.length, equals(20)); // 4x5 matrix
      expect(matrix[3], equals(0.0));
      expect(matrix[18], equals(1.0)); // Alpha channel identity
    });

    test('ColorFilterCompilerService generates accurate FFmpeg filter strings', () {
      const config = ColorGradingConfig(
        contrast: 1.25,
        saturation: 1.10,
        exposure: 0.3,
        temperature: 20.0,
        tint: -15.0,
        activeLut: LutPreset.tealAndOrange,
        vignette: 0.5,
      );

      final filterStr = ColorFilterCompilerService.generateFFmpegFilter(config);

      expect(filterStr, contains('eq=contrast=1.25'));
      expect(filterStr, contains('colorbalance='));
      expect(filterStr, contains('curves='));
      expect(filterStr, contains('vignette='));
    });
  });
}
