import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/masking/models/mask_config.dart';
import 'package:edito/features/masking/services/mask_compiler_service.dart';

void main() {
  group('Multi-Shape Masking Model Tests', () {
    test('Default MaskConfig is inactive and identity', () {
      const config = MaskConfig();
      expect(config.isActive, false);
      expect(config.type, MaskType.none);
      expect(config.centerX, 0.5);
      expect(config.centerY, 0.5);
      expect(config.width, 0.6);
      expect(config.height, 0.6);
      expect(config.rotation, 0.0);
      expect(config.feather, 0.0);
      expect(config.roundness, 0.0);
      expect(config.inverted, false);
      expect(config.opacity, 1.0);
    });

    test('MaskConfig copyWith updates fields cleanly', () {
      const config = MaskConfig();
      final updated = config.copyWith(
        type: MaskType.radial,
        centerX: 0.4,
        centerY: 0.6,
        width: 0.8,
        height: 0.5,
        rotation: 45.0,
        feather: 0.25,
        roundness: 0.2,
        inverted: true,
        opacity: 0.85,
      );

      expect(updated.isActive, true);
      expect(updated.type, MaskType.radial);
      expect(updated.centerX, 0.4);
      expect(updated.centerY, 0.6);
      expect(updated.width, 0.8);
      expect(updated.height, 0.5);
      expect(updated.rotation, 45.0);
      expect(updated.feather, 0.25);
      expect(updated.roundness, 0.2);
      expect(updated.inverted, true);
      expect(updated.opacity, 0.85);
    });

    test('MaskConfig json serialization roundtrips accurately', () {
      const original = MaskConfig(
        type: MaskType.rectangle,
        centerX: 0.35,
        centerY: 0.65,
        width: 0.75,
        height: 0.55,
        rotation: 30.0,
        feather: 0.15,
        roundness: 0.4,
        inverted: true,
        opacity: 0.9,
      );

      final json = original.toJson();
      final deserialized = MaskConfig.fromJson(json);

      expect(deserialized, equals(original));
      expect(deserialized.type, MaskType.rectangle);
      expect(deserialized.centerX, 0.35);
      expect(deserialized.centerY, 0.65);
      expect(deserialized.width, 0.75);
      expect(deserialized.height, 0.55);
      expect(deserialized.rotation, 30.0);
      expect(deserialized.feather, 0.15);
      expect(deserialized.roundness, 0.4);
      expect(deserialized.inverted, true);
      expect(deserialized.opacity, 0.9);
    });

    test('All MaskPresets produce expected geometries', () {
      final splitH = MaskConfig.fromPreset(MaskPreset.splitHorizontal);
      expect(splitH.type, MaskType.linear);
      expect(splitH.rotation, 0.0);
      expect(splitH.isActive, true);

      final splitV = MaskConfig.fromPreset(MaskPreset.splitVertical);
      expect(splitV.type, MaskType.linear);
      expect(splitV.rotation, 90.0);
      expect(splitV.isActive, true);

      final circle = MaskConfig.fromPreset(MaskPreset.spotlightCircle);
      expect(circle.type, MaskType.radial);
      expect(circle.feather, greaterThan(0.0));
      expect(circle.isActive, true);

      final card = MaskConfig.fromPreset(MaskPreset.roundedCard);
      expect(card.type, MaskType.rectangle);
      expect(card.roundness, greaterThan(0.0));
      expect(card.isActive, true);

      final letterbox = MaskConfig.fromPreset(MaskPreset.cinematicLetterbox);
      expect(letterbox.type, MaskType.rectangle);
      expect(letterbox.width, 1.0);
      expect(letterbox.isActive, true);

      final heart = MaskConfig.fromPreset(MaskPreset.dreamyHeart);
      expect(heart.type, MaskType.heart);
      expect(heart.isActive, true);

      final star = MaskConfig.fromPreset(MaskPreset.popStar);
      expect(star.type, MaskType.star);
      expect(star.isActive, true);
    });
  });

  group('MaskCompilerService Tests', () {
    const canvasSize = Size(1920, 1080);

    test('buildMaskPath returns non-null valid Path for all mask types', () {
      for (final type in MaskType.values) {
        final config = MaskConfig(type: type, feather: 0.1, rotation: 15.0);
        final path = MaskCompilerService.buildMaskPath(config, canvasSize);
        expect(path, isNotNull);

        final invConfig = config.copyWith(inverted: true);
        final invPath = MaskCompilerService.buildMaskPath(invConfig, canvasSize);
        expect(invPath, isNotNull);
      }
    });

    test('generateFFmpegFilters returns empty list for inactive mask', () {
      const config = MaskConfig(type: MaskType.none);
      final filters = MaskCompilerService.generateFFmpegFilters(
        config,
        outputWidth: 1920,
        outputHeight: 1080,
      );
      expect(filters, isEmpty);
    });

    test('generateFFmpegFilters creates yuva420p format and geq alpha expression for linear mask', () {
      const config = MaskConfig(
        type: MaskType.linear,
        centerX: 0.5,
        centerY: 0.5,
        rotation: 45.0,
        feather: 0.1,
      );
      final filters = MaskCompilerService.generateFFmpegFilters(
        config,
        outputWidth: 1920,
        outputHeight: 1080,
      );

      expect(filters.length, 2);
      expect(filters[0], 'format=yuva420p');
      expect(filters[1], startsWith("geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='"));
      expect(filters[1], contains('cos'));
      expect(filters[1], contains('sin'));
    });

    test('generateFFmpegFilters creates elliptical distance formula for radial mask', () {
      const config = MaskConfig(
        type: MaskType.radial,
        centerX: 0.4,
        centerY: 0.6,
        width: 0.5,
        height: 0.5,
        feather: 0.2,
      );
      final filters = MaskCompilerService.generateFFmpegFilters(
        config,
        outputWidth: 1280,
        outputHeight: 720,
      );

      expect(filters.length, 2);
      expect(filters[0], 'format=yuva420p');
      expect(filters[1], contains('pow'));
    });

    test('generateFFmpegFilters handles inverted mask and opacity scaling', () {
      const config = MaskConfig(
        type: MaskType.rectangle,
        inverted: true,
        opacity: 0.75,
      );
      final filters = MaskCompilerService.generateFFmpegFilters(
        config,
        outputWidth: 1920,
        outputHeight: 1080,
      );

      expect(filters.length, 2);
      expect(filters[1], contains('*0.75'));
    });
  });

  group('Clip Domain Integration with MaskConfig Tests', () {
    test('Clip initializes with default const MaskConfig', () {
      const clip = Clip(
        id: 'clip_1',
        assetId: 'asset_1',
        trackId: 'track_v0',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      expect(clip.mask, isNotNull);
      expect(clip.mask.isActive, false);
      expect(clip.mask.type, MaskType.none);
    });

    test('Clip copyWith updates mask configuration correctly', () {
      const clip = Clip(
        id: 'clip_1',
        assetId: 'asset_1',
        trackId: 'track_v0',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      final updated = clip.copyWith(
        mask: const MaskConfig(
          type: MaskType.heart,
          feather: 0.2,
          inverted: false,
        ),
      );

      expect(updated.mask.type, MaskType.heart);
      expect(updated.mask.isActive, true);
      expect(updated.mask.feather, 0.2);
    });

    test('Clip with mask serializes and deserializes properly', () {
      const clip = Clip(
        id: 'clip_test',
        assetId: 'asset_test',
        trackId: 'track_test',
        startTimeMs: 1000,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        mask: MaskConfig(
          type: MaskType.star,
          centerX: 0.45,
          centerY: 0.55,
          width: 0.7,
          height: 0.7,
          feather: 0.12,
          inverted: true,
        ),
      );

      final json = clip.toJson();
      final fromJsonClip = Clip.fromJson(json);

      expect(fromJsonClip.mask, equals(clip.mask));
      expect(fromJsonClip.mask.type, MaskType.star);
      expect(fromJsonClip.mask.centerX, 0.45);
      expect(fromJsonClip.mask.inverted, true);
    });
  });
}
