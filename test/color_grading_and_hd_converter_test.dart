import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/color_grading/models/color_grading_config.dart';
import 'package:edito/features/color_grading/services/color_filter_compiler_service.dart';
import 'package:edito/features/hd_converter/models/hd_converter_config.dart';
import 'package:edito/features/hd_converter/services/hd_converter_service.dart';

void main() {
  group('Professional Color Grading Tests', () {
    test('Default ColorGradingConfig is identity and not graded', () {
      const config = ColorGradingConfig();
      expect(config.isGraded, false);
      expect(config.exposure, 0.0);
      expect(config.contrast, 1.0);
      expect(config.activeLut, LutPreset.none);
      expect(config.lift.isActive, false);
      expect(config.gamma.isActive, false);
      expect(config.gain.isActive, false);
      expect(config.offset.isActive, false);
      expect(config.fade, 0.0);
      expect(config.clarity, 1.0);
    });

    test('ColorWheelValue detects active state and serializes properly', () {
      const neutral = ColorWheelValue();
      expect(neutral.isActive, false);

      const shifted = ColorWheelValue(angle: 120.0, saturation: 0.45, luminance: 0.15);
      expect(shifted.isActive, true);

      final json = shifted.toJson();
      final revived = ColorWheelValue.fromJson(json);
      expect(revived, equals(shifted));
      expect(revived.angle, 120.0);
      expect(revived.saturation, 0.45);
      expect(revived.luminance, 0.15);
    });

    test('ColorGradingConfig with 3-Way Color Wheels and pro adjustments serializes roundtrip', () {
      const config = ColorGradingConfig(
        exposure: 0.5,
        contrast: 1.15,
        saturation: 1.10,
        temperature: 15.0,
        tint: -8.0,
        whites: 0.2,
        blacks: -0.15,
        fade: 0.25,
        clarity: 1.20,
        activeLut: LutPreset.arriAlexa,
        lutIntensity: 0.85,
        lift: ColorWheelValue(angle: 210.0, saturation: 0.3, luminance: -0.05),
        gamma: ColorWheelValue(angle: 45.0, saturation: 0.15, luminance: 0.02),
        gain: ColorWheelValue(angle: 60.0, saturation: 0.25, luminance: 0.1),
        offset: ColorWheelValue(angle: 0.0, saturation: 0.0, luminance: 0.0),
      );

      expect(config.isGraded, true);

      final json = config.toJson();
      final revived = ColorGradingConfig.fromJson(json);

      expect(revived.exposure, config.exposure);
      expect(revived.contrast, config.contrast);
      expect(revived.activeLut, LutPreset.arriAlexa);
      expect(revived.lutIntensity, 0.85);
      expect(revived.fade, 0.25);
      expect(revived.clarity, 1.20);
      expect(revived.whites, 0.2);
      expect(revived.blacks, -0.15);
      expect(revived.lift, config.lift);
      expect(revived.gamma, config.gamma);
      expect(revived.gain, config.gain);
      expect(revived, equals(config));
    });

    test('ColorFilterCompilerService generates 4x5 matrix with Color Wheels & pro adjustments', () {
      const config = ColorGradingConfig(
        exposure: 0.4,
        fade: 0.3,
        activeLut: LutPreset.fujiVelvia,
        lift: ColorWheelValue(angle: 240.0, saturation: 0.4), // Cool shadow tint
      );

      final matrix = ColorFilterCompilerService.compileColorMatrix(config);
      expect(matrix.length, 20);

      // Identity check
      expect(ColorFilterCompilerService.isIdentity(const ColorGradingConfig()), true);
      expect(ColorFilterCompilerService.isIdentity(config), false);
    });

    test('ColorFilterCompilerService generates FFmpeg filters for colorbalance and pro looks', () {
      const config = ColorGradingConfig(
        exposure: 0.3,
        temperature: 20.0,
        activeLut: LutPreset.matrixEmerald,
        lift: ColorWheelValue(angle: 120.0, saturation: 0.5), // Green shadow lift
        fade: 0.2,
      );

      final filter = ColorFilterCompilerService.generateFFmpegFilter(config);
      expect(filter, isNotEmpty);
      expect(filter, contains('eq='));
      expect(filter, contains('colorbalance='));
      expect(filter, contains('curves='));
    });
  });

  group('HD Video Converter Tests', () {
    test('Default HdConverterConfig is disabled and standard', () {
      const config = HdConverterConfig();
      expect(config.isEnabled, false);
      expect(config.targetResolution, HdResolution.fhd1080p);
      expect(config.algorithm, HdScalingAlgorithm.lanczos3);
      expect(config.detailClarity, 1.0);
      expect(config.denoiseStrength, 0.0);
      expect(config.deblocking, false);
      expect(config.hdrColorExpand, false);
      expect(config.hasActiveConversion, false);
    });

    test('HdResolution dimensions and labels are accurate', () {
      expect(HdResolution.hd720p.width, 1280);
      expect(HdResolution.hd720p.height, 720);

      expect(HdResolution.fhd1080p.width, 1920);
      expect(HdResolution.fhd1080p.height, 1080);

      expect(HdResolution.qhd1440p.width, 2560);
      expect(HdResolution.qhd1440p.height, 1440);

      expect(HdResolution.uhd4k.width, 3840);
      expect(HdResolution.uhd4k.height, 2160);

      expect(HdResolution.uhd8k.width, 7680);
      expect(HdResolution.uhd8k.height, 4320);
    });

    test('HdConverterPreset instantiates configurations properly', () {
      final to4k = HdConverterPreset.to4kCinema.createConfig();
      expect(to4k.isEnabled, true);
      expect(to4k.targetResolution, HdResolution.uhd4k);
      expect(to4k.algorithm, HdScalingAlgorithm.superResolution);
      expect(to4k.hdrColorExpand, true);
      expect(to4k.detailClarity, greaterThan(1.0));

      final social = HdConverterPreset.socialVideoRestore.createConfig();
      expect(social.isEnabled, true);
      expect(social.deblocking, true);
      expect(social.denoiseStrength, greaterThan(0.3));
    });

    test('HdConverterConfig serializes and deserializes JSON roundtrip', () {
      final config = HdConverterPreset.to4kCinema.createConfig();
      final json = config.toJson();
      final revived = HdConverterConfig.fromJson(json);

      expect(revived.isEnabled, config.isEnabled);
      expect(revived.targetResolution, config.targetResolution);
      expect(revived.algorithm, config.algorithm);
      expect(revived.detailClarity, config.detailClarity);
      expect(revived.denoiseStrength, config.denoiseStrength);
      expect(revived.deblocking, config.deblocking);
      expect(revived.hdrColorExpand, config.hdrColorExpand);
      expect(revived.sharpness, config.sharpness);
      expect(revived, equals(config));
    });

    test('HdConverterService generates FFmpeg scaling and sharpening filters', () {
      final config = HdConverterPreset.to4kCinema.createConfig();
      final filters = HdConverterService.generateFFmpegFilters(config);

      expect(filters, isNotEmpty);
      expect(filters.any((f) => f.contains('scale=3840:2160')), true);
      expect(filters.any((f) => f.contains('flags=lanczos')), true);
      expect(filters.any((f) => f.contains('unsharp=')), true);
      expect(filters.any((f) => f.contains('deblock=')), true);
      expect(filters.any((f) => f.contains('eq=contrast=')), true);

      // Disabled returns empty list
      const disabled = HdConverterConfig(isEnabled: false);
      expect(HdConverterService.generateFFmpegFilters(disabled), isEmpty);
    });

    test('HdConverterService generates HUD badge', () {
      const disabled = HdConverterConfig(isEnabled: false);
      expect(HdConverterService.getHdBadge(disabled), isEmpty);

      final to4k = HdConverterPreset.to4kCinema.createConfig();
      expect(HdConverterService.getHdBadge(to4k), contains('4K ULTRA HD'));
    });
  });

  group('Clip Integration with Pro Color & HD Converter', () {
    test('Clip model has safe defaults for hdConverter and supports copyWith & JSON', () {
      const clip = Clip(
        id: 'clip-pro-1',
        assetId: 'asset-1',
        trackId: 'track-1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      expect(clip.hdConverter.isEnabled, false);
      expect(clip.colorGrading.isGraded, false);

      final proColor = const ColorGradingConfig(
        exposure: 0.2,
        activeLut: LutPreset.cleanCommercial,
        lift: ColorWheelValue(angle: 180.0, saturation: 0.2),
      );
      final hdConv = HdConverterPreset.sdTo1080pFhd.createConfig();

      final updatedClip = clip.copyWith(
        colorGrading: proColor,
        hdConverter: hdConv,
      );

      expect(updatedClip.colorGrading.isGraded, true);
      expect(updatedClip.colorGrading.activeLut, LutPreset.cleanCommercial);
      expect(updatedClip.hdConverter.isEnabled, true);
      expect(updatedClip.hdConverter.targetResolution, HdResolution.fhd1080p);

      final json = updatedClip.toJson();
      final revived = Clip.fromJson(json);

      expect(revived.colorGrading.activeLut, LutPreset.cleanCommercial);
      expect(revived.colorGrading.lift.angle, 180.0);
      expect(revived.hdConverter.isEnabled, true);
      expect(revived.hdConverter.targetResolution, HdResolution.fhd1080p);
      expect(revived, equals(updatedClip));
    });
  });
}
