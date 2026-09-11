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

    test('ColorFilterCompilerService default grade produces pure identity matrix with zero greenish bleed', () {
      const defaultGrade = ColorGradingConfig();
      expect(ColorFilterCompilerService.isIdentity(defaultGrade), isTrue);

      final matrix = ColorFilterCompilerService.compileColorMatrix(defaultGrade);

      expect(matrix.length, equals(20));
      expect(matrix, equals(ColorFilterCompilerService.identityMatrix));

      // Assert diagonal elements are 1.0 (R, G, B, A)
      expect(matrix[0], equals(1.0)); // R->R
      expect(matrix[6], equals(1.0)); // G->G
      expect(matrix[12], equals(1.0)); // B->B
      expect(matrix[18], equals(1.0)); // A->A

      // Assert cross-channel elements are strictly 0.0 (prevents greenish tone)
      expect(matrix[1], equals(0.0)); // G->R
      expect(matrix[2], equals(0.0)); // B->R
      expect(matrix[5], equals(0.0)); // R->G (must NEVER be 1.0)
      expect(matrix[7], equals(0.0)); // B->G
      expect(matrix[10], equals(0.0)); // R->B (must NEVER be 1.0)
      expect(matrix[11], equals(0.0)); // G->B

      // Offsets
      expect(matrix[4], equals(0.0)); // R offset
      expect(matrix[9], equals(0.0)); // G offset
      expect(matrix[14], equals(0.0)); // B offset
      expect(matrix[19], equals(0.0)); // A offset
    });

    test('ColorFilterCompilerService treats vignette-only config as matrix identity', () {
      const vignetteOnly = ColorGradingConfig(vignette: 0.5);
      expect(ColorFilterCompilerService.isIdentity(vignetteOnly), isTrue);
    });

    test('ColorFilterCompilerService treats active LUT as non-identity', () {
      const lutGraded = ColorGradingConfig(activeLut: LutPreset.tealAndOrange);
      expect(ColorFilterCompilerService.isIdentity(lutGraded), isFalse);
    });

    test('ColorFilterCompilerService treats customized curve as non-identity', () {
      const curveGraded = ColorGradingConfig(
        masterCurve: [
          CurvePoint(0.0, 0.0),
          CurvePoint(0.4, 0.6),
          CurvePoint(1.0, 1.0),
        ],
      );
      expect(ColorFilterCompilerService.isIdentity(curveGraded), isFalse);
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
