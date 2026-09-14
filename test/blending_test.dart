import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/blending/models/blend_mode_config.dart';
import 'package:edito/features/blending/services/blend_mode_compiler_service.dart';

void main() {
  group('Pro Blending Modes Model Tests', () {
    test('Default BlendModeConfig is normal and disabled', () {
      const config = BlendModeConfig();
      expect(config.mode, ProBlendMode.normal);
      expect(config.opacity, 1.0);
      expect(config.isEnabled, false);
    });

    test('BlendModeConfig detects active state when mode is non-normal or opacity reduced', () {
      const screenConfig = BlendModeConfig(mode: ProBlendMode.screen);
      expect(screenConfig.isEnabled, true);

      const opacityOnly = BlendModeConfig(mode: ProBlendMode.normal, opacity: 0.75);
      expect(opacityOnly.isEnabled, true);
    });

    test('BlendModeConfig copyWith updates fields properly', () {
      const original = BlendModeConfig();
      final updated = original.copyWith(
        mode: ProBlendMode.overlay,
        opacity: 0.85,
      );

      expect(updated.mode, ProBlendMode.overlay);
      expect(updated.opacity, 0.85);
      expect(updated.isEnabled, true);
    });

    test('BlendModeConfig serializes and deserializes accurately', () {
      const original = BlendModeConfig(
        mode: ProBlendMode.colorDodge,
        opacity: 0.70,
      );

      final json = original.toJson();
      final revived = BlendModeConfig.fromJson(json);

      expect(revived, equals(original));
      expect(revived.mode, ProBlendMode.colorDodge);
      expect(revived.opacity, 0.70);
    });

    test('All BlendModePresets construct expected blend modes', () {
      final leak = BlendModeConfig.fromPreset(BlendModePreset.lightLeak);
      expect(leak.mode, ProBlendMode.screen);
      expect(leak.opacity, 0.85);
      expect(leak.isEnabled, true);

      final shadow = BlendModeConfig.fromPreset(BlendModePreset.shadowTexture);
      expect(shadow.mode, ProBlendMode.multiply);
      expect(shadow.opacity, 0.75);

      final cinema = BlendModeConfig.fromPreset(BlendModePreset.cinematicVibe);
      expect(cinema.mode, ProBlendMode.overlay);

      final glow = BlendModeConfig.fromPreset(BlendModePreset.subtleGlow);
      expect(glow.mode, ProBlendMode.softLight);

      final energy = BlendModeConfig.fromPreset(BlendModePreset.magicEnergy);
      expect(energy.mode, ProBlendMode.colorDodge);

      final psych = BlendModeConfig.fromPreset(BlendModePreset.psychedelicX);
      expect(psych.mode, ProBlendMode.difference);
    });
  });

  group('BlendModeCompilerService Tests', () {
    test('Maps all ProBlendModes to Flutter BlendMode without error', () {
      for (final mode in ProBlendMode.values) {
        final flutterBlend = BlendModeCompilerService.toFlutterBlendMode(mode);
        expect(flutterBlend, isNotNull);
      }
      expect(BlendModeCompilerService.toFlutterBlendMode(ProBlendMode.normal), BlendMode.srcOver);
      expect(BlendModeCompilerService.toFlutterBlendMode(ProBlendMode.screen), BlendMode.screen);
      expect(BlendModeCompilerService.toFlutterBlendMode(ProBlendMode.multiply), BlendMode.multiply);
      expect(BlendModeCompilerService.toFlutterBlendMode(ProBlendMode.overlay), BlendMode.overlay);
      expect(BlendModeCompilerService.toFlutterBlendMode(ProBlendMode.colorDodge), BlendMode.colorDodge);
      expect(BlendModeCompilerService.toFlutterBlendMode(ProBlendMode.difference), BlendMode.difference);
    });

    test('generateFFmpegLayerCompositor produces overlay for normal mode', () {
      const config = BlendModeConfig(mode: ProBlendMode.normal);
      final filter = BlendModeCompilerService.generateFFmpegLayerCompositor(
        config: config,
        baseLabel: 'vbase',
        overlayLabel: 'vtop',
        outputLabel: 'vout',
        enableExpression: 'between(t,0,5)',
      );

      expect(filter, '[vbase][vtop]overlay=eof_action=pass:enable=\'between(t,0,5)\'[vout]');
    });

    test('generateFFmpegLayerCompositor produces blend filter for screen and multiply modes', () {
      const screenConfig = BlendModeConfig(mode: ProBlendMode.screen, opacity: 0.85);
      final screenFilter = BlendModeCompilerService.generateFFmpegLayerCompositor(
        config: screenConfig,
        baseLabel: 'vbase',
        overlayLabel: 'vtop',
        outputLabel: 'vout',
        enableExpression: 'between(t,2,8)',
      );

      expect(screenFilter, contains('blend=all_mode=screen:all_opacity=0.85:enable=\'between(t,2,8)\''));

      const multConfig = BlendModeConfig(mode: ProBlendMode.multiply, opacity: 0.70);
      final multFilter = BlendModeCompilerService.generateFFmpegLayerCompositor(
        config: multConfig,
        baseLabel: 'v0',
        overlayLabel: 'v1',
        outputLabel: 'vcomp',
      );

      expect(multFilter, contains('blend=all_mode=multiply:all_opacity=0.70'));
    });

    test('generateInStreamFilters handles opacity scaling', () {
      const disabled = BlendModeConfig();
      expect(BlendModeCompilerService.generateInStreamFilters(disabled), isEmpty);

      const semiTransparent = BlendModeConfig(opacity: 0.60);
      final filters = BlendModeCompilerService.generateInStreamFilters(semiTransparent);
      expect(filters, contains('format=yuva420p'));
      expect(filters, contains('colorchannelmixer=aa=0.60'));
    });
  });

  group('Clip Domain Integration with BlendModeConfig Tests', () {
    test('Clip initializes with default BlendModeConfig', () {
      const clip = Clip(
        id: 'clip_blend_1',
        assetId: 'asset_blend_1',
        trackId: 'track_v0',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      expect(clip.blendMode, isNotNull);
      expect(clip.blendMode.mode, ProBlendMode.normal);
      expect(clip.blendMode.isEnabled, false);
    });

    test('Clip copyWith updates blendMode cleanly', () {
      const clip = Clip(
        id: 'clip_blend_2',
        assetId: 'asset_blend_2',
        trackId: 'track_v1',
        startTimeMs: 1000,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      final updated = clip.copyWith(
        blendMode: const BlendModeConfig(
          mode: ProBlendMode.screen,
          opacity: 0.90,
        ),
      );

      expect(updated.blendMode.mode, ProBlendMode.screen);
      expect(updated.blendMode.opacity, 0.90);
      expect(updated.blendMode.isEnabled, true);
    });

    test('Clip with blendMode serializes and deserializes roundtrip', () {
      const clip = Clip(
        id: 'clip_blend_3',
        assetId: 'asset_blend_3',
        trackId: 'track_v2',
        startTimeMs: 2000,
        durationMs: 3000,
        sourceInMs: 0,
        sourceOutMs: 3000,
        blendMode: BlendModeConfig(
          mode: ProBlendMode.colorBurn,
          opacity: 0.65,
        ),
      );

      final json = clip.toJson();
      final revived = Clip.fromJson(json);

      expect(revived.blendMode, equals(clip.blendMode));
      expect(revived.blendMode.mode, ProBlendMode.colorBurn);
      expect(revived.blendMode.opacity, 0.65);
    });
  });
}
