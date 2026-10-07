import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/vfx/models/echo_motion_config.dart';
import 'package:edito/features/vfx/services/echo_motion_compiler_service.dart';
import 'package:edito/features/vfx/models/ascii_art_config.dart';
import 'package:edito/features/vfx/services/ascii_art_compiler_service.dart';
import 'package:edito/features/audio/models/sub_bass_exciter_config.dart';
import 'package:edito/features/audio/services/sub_bass_exciter_compiler_service.dart';
import 'package:edito/models/clip.dart';

void main() {
  group('EchoMotionConfig & Compiler Tests', () {
    test('Default values are correct and disabled by default', () {
      const config = EchoMotionConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isActive, isFalse);
      expect(config.mode, equals(EchoMotionMode.smoothMotionBlur));
      expect(config.decay, equals(0.65));
      expect(config.trailCount, equals(5));
      expect(config.shutterAngle, equals(180.0));
      expect(config.opacity, equals(0.85));
    });

    test('copyWith updates fields accurately', () {
      const config = EchoMotionConfig();
      final updated = config.copyWith(
        isEnabled: true,
        mode: EchoMotionMode.lightTrailSmear,
        decay: 0.88,
        trailCount: 8,
        opacity: 0.95,
      );
      expect(updated.isEnabled, isTrue);
      expect(updated.isActive, isTrue);
      expect(updated.mode, equals(EchoMotionMode.lightTrailSmear));
      expect(updated.decay, equals(0.88));
      expect(updated.trailCount, equals(8));
      expect(updated.opacity, equals(0.95));
    });

    test('toJson and fromJson serialize and deserialize correctly', () {
      final original = EchoMotionConfig.neonLightTrails;
      final json = original.toJson();
      final restored = EchoMotionConfig.fromJson(json);

      expect(restored.isEnabled, equals(original.isEnabled));
      expect(restored.mode, equals(original.mode));
      expect(restored.decay, closeTo(original.decay, 0.001));
      expect(restored.trailCount, equals(original.trailCount));
      expect(restored.shutterAngle, closeTo(original.shutterAngle, 0.001));
      expect(restored.opacity, closeTo(original.opacity, 0.001));
    });

    test('EchoMotionCompilerService returns empty string when disabled', () {
      const compiler = EchoMotionCompilerService();
      expect(compiler.compile(const EchoMotionConfig(isEnabled: false)), isEmpty);
      expect(EchoMotionCompilerService.compileFilter(const EchoMotionConfig(isEnabled: false)), isEmpty);
    });

    test('EchoMotionCompilerService compiles valid filters for all modes', () {
      const compiler = EchoMotionCompilerService();
      for (final mode in EchoMotionMode.values) {
        final config = EchoMotionConfig(
          isEnabled: true,
          mode: mode,
          trailCount: 6,
          decay: 0.75,
        );
        final filter = compiler.compile(config);
        expect(filter, isNotEmpty);
        expect(compiler.getBadgeLabel(config), contains(mode.label.toUpperCase()));
      }
    });

    test('SmoothMotionBlur uses tmix with normalized decay weights', () {
      const compiler = EchoMotionCompilerService();
      final filter = compiler.compile(const EchoMotionConfig(
        isEnabled: true,
        mode: EchoMotionMode.smoothMotionBlur,
        trailCount: 4,
        decay: 0.5,
      ));
      expect(filter, contains('tmix=frames=4'));
      expect(filter, contains('weights='));
    });

    test('LightTrailSmear uses lighten blend mode', () {
      const compiler = EchoMotionCompilerService();
      final filter = compiler.compile(const EchoMotionConfig(
        isEnabled: true,
        mode: EchoMotionMode.lightTrailSmear,
      ));
      expect(filter, contains('tblend=all_mode=lighten'));
      expect(filter, contains('lagfun=decay='));
    });
  });

  group('AsciiArtConfig & Compiler Tests', () {
    test('Default values are correct and disabled by default', () {
      const config = AsciiArtConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isActive, isFalse);
      expect(config.mode, equals(AsciiArtMode.greenPhosphor));
      expect(config.cellSize, equals(8));
      expect(config.contrast, equals(1.3));
      expect(config.glyphGlow, equals(0.4));
      expect(config.isInverted, isFalse);
    });

    test('copyWith updates fields accurately', () {
      const config = AsciiArtConfig();
      final updated = config.copyWith(
        isEnabled: true,
        mode: AsciiArtMode.amberCathode,
        cellSize: 12,
        contrast: 1.8,
        isInverted: true,
      );
      expect(updated.isEnabled, isTrue);
      expect(updated.mode, equals(AsciiArtMode.amberCathode));
      expect(updated.cellSize, equals(12));
      expect(updated.contrast, equals(1.8));
      expect(updated.isInverted, isTrue);
    });

    test('toJson and fromJson serialize and deserialize correctly', () {
      final original = AsciiArtConfig.vintageAmberCathode;
      final json = original.toJson();
      final restored = AsciiArtConfig.fromJson(json);

      expect(restored.isEnabled, equals(original.isEnabled));
      expect(restored.mode, equals(original.mode));
      expect(restored.cellSize, equals(original.cellSize));
      expect(restored.contrast, closeTo(original.contrast, 0.001));
      expect(restored.glyphGlow, closeTo(original.glyphGlow, 0.001));
    });

    test('AsciiArtCompilerService returns empty string when disabled', () {
      const compiler = AsciiArtCompilerService();
      expect(compiler.compile(const AsciiArtConfig(isEnabled: false)), isEmpty);
      expect(AsciiArtCompilerService.compileFilter(const AsciiArtConfig(isEnabled: false)), isEmpty);
    });

    test('AsciiArtCompilerService generates cell downscaling, color channels, and drawgrid', () {
      const compiler = AsciiArtCompilerService();
      for (final mode in AsciiArtMode.values) {
        final config = AsciiArtConfig(
          isEnabled: true,
          mode: mode,
          cellSize: 8,
          contrast: 1.4,
          glyphGlow: 0.5,
        );
        final filter = compiler.compile(config);
        expect(filter, contains('scale=iw/8:ih/8:flags=neighbor'));
        expect(filter, contains('scale=iw*8:ih*8:flags=neighbor'));
        expect(filter, contains('drawgrid=w=8:h=8:t=1:color=black@0.65'));
        expect(filter, contains('eq=contrast=1.40'));
        expect(compiler.getBadgeLabel(config), contains(mode.label.toUpperCase()));
      }
    });

    test('Inversion adds negate filter', () {
      const compiler = AsciiArtCompilerService();
      final filter = compiler.compile(const AsciiArtConfig(
        isEnabled: true,
        isInverted: true,
      ));
      expect(filter, contains('negate'));
    });
  });

  group('SubBassExciterConfig & Compiler Tests (with AGENTS.md Rule 4 Safeguard)', () {
    test('Default values are correct and disabled by default', () {
      const config = SubBassExciterConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isActive, isFalse);
      expect(config.mode, equals(SubBassExciterMode.club808Punch));
      expect(config.subFrequency, equals(55.0));
      expect(config.subBoostDb, equals(6.0));
      expect(config.driveSaturation, equals(0.35));
      expect(config.harmonicsMix, equals(0.5));
    });

    test('copyWith updates fields accurately', () {
      const config = SubBassExciterConfig();
      final updated = config.copyWith(
        isEnabled: true,
        mode: SubBassExciterMode.cinematicSubRumble,
        subFrequency: 42.0,
        subBoostDb: 10.5,
        driveSaturation: 0.6,
      );
      expect(updated.isEnabled, isTrue);
      expect(updated.mode, equals(SubBassExciterMode.cinematicSubRumble));
      expect(updated.subFrequency, equals(42.0));
      expect(updated.subBoostDb, equals(10.5));
      expect(updated.driveSaturation, equals(0.6));
    });

    test('toJson and fromJson serialize and deserialize correctly', () {
      final original = SubBassExciterConfig.trap808Punch;
      final json = original.toJson();
      final restored = SubBassExciterConfig.fromJson(json);

      expect(restored.isEnabled, equals(original.isEnabled));
      expect(restored.mode, equals(original.mode));
      expect(restored.subFrequency, closeTo(original.subFrequency, 0.001));
      expect(restored.subBoostDb, closeTo(original.subBoostDb, 0.001));
      expect(restored.harmonicsMix, closeTo(original.harmonicsMix, 0.001));
    });

    test('SubBassExciterCompilerService returns empty string when disabled', () {
      const compiler = SubBassExciterCompilerService();
      expect(compiler.compile(const SubBassExciterConfig(isEnabled: false)), isEmpty);
      expect(SubBassExciterCompilerService.compileFilter(const SubBassExciterConfig(isEnabled: false)), isEmpty);
    });

    test('CRITICAL: Compiles audio DSP chain with STRICT Rule 4 brickwall ceiling limiter', () {
      const compiler = SubBassExciterCompilerService();
      for (final mode in SubBassExciterMode.values) {
        final config = SubBassExciterConfig(
          isEnabled: true,
          mode: mode,
          subFrequency: 60.0,
          subBoostDb: 8.0,
          driveSaturation: 0.4,
          harmonicsMix: 0.6,
        );
        final filter = compiler.compile(config);
        expect(filter, isNotEmpty);
        expect(filter, contains('equalizer=f=60.0'));
        expect(filter, contains('bass=g=4.0:f=60.0'));

        // MANDATORY AGENTS.md Rule 4 True-Peak Brickwall Ceiling Limiter Verification
        expect(
          filter,
          contains('alimiter=limit=0.95:attack=5:release=50:asc=1'),
          reason: 'Every audio DSP boost must strictly include true-peak brickwall ceiling limiter!',
        );
        expect(compiler.getBadgeLabel(config), contains(mode.label.toUpperCase()));
      }
    });

    test('PhoneSpeakerExciter generates both 2nd and 3rd harmonics', () {
      const compiler = SubBassExciterCompilerService();
      final filter = compiler.compile(const SubBassExciterConfig(
        isEnabled: true,
        mode: SubBassExciterMode.phoneSpeakerExciter,
        subFrequency: 50.0,
        harmonicsMix: 0.8,
      ));
      // Fundamental: 50 Hz, 2nd Harmonic: 100 Hz, 3rd Harmonic: 150 Hz
      expect(filter, contains('equalizer=f=50.0'));
      expect(filter, contains('equalizer=f=100.0'));
      expect(filter, contains('equalizer=f=150.0'));
    });
  });

  group('Clip Integration Tests for Phase 25 Features', () {
    test('Clip initializes with non-null defaults for Phase 25 configs', () {
      const clip = Clip(
        id: 'clip_p25_test',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      expect(clip.echoMotion, isNotNull);
      expect(clip.echoMotion.isEnabled, isFalse);

      expect(clip.asciiArt, isNotNull);
      expect(clip.asciiArt.isEnabled, isFalse);

      expect(clip.subBassExciter, isNotNull);
      expect(clip.subBassExciter.isEnabled, isFalse);
    });

    test('Clip.copyWith correctly preserves and updates Phase 25 configs', () {
      const clip = Clip(
        id: 'clip_p25_test',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      final updated = clip.copyWith(
        echoMotion: EchoMotionConfig.neonLightTrails,
        asciiArt: AsciiArtConfig.cyberpunkConsole,
        subBassExciter: SubBassExciterConfig.trap808Punch,
      );

      expect(updated.echoMotion.isEnabled, isTrue);
      expect(updated.echoMotion.mode, equals(EchoMotionMode.lightTrailSmear));

      expect(updated.asciiArt.isEnabled, isTrue);
      expect(updated.asciiArt.mode, equals(AsciiArtMode.cyberpunkNeon));

      expect(updated.subBassExciter.isEnabled, isTrue);
      expect(updated.subBassExciter.mode, equals(SubBassExciterMode.club808Punch));
    });

    test('Clip toJson and fromJson full serialization roundtrip', () {
      final clip = const Clip(
        id: 'clip_p25_roundtrip',
        assetId: 'asset_rt',
        trackId: 'track_rt',
        startTimeMs: 1000,
        durationMs: 4000,
        sourceInMs: 500,
        sourceOutMs: 4500,
      ).copyWith(
        echoMotion: EchoMotionConfig.spectralGhost,
        asciiArt: AsciiArtConfig.vintageAmberCathode,
        subBassExciter: SubBassExciterConfig.dubstepSeismic,
      );

      final json = clip.toJson();
      final restored = Clip.fromJson(json);

      expect(restored.echoMotion.isEnabled, isTrue);
      expect(restored.echoMotion.mode, equals(EchoMotionMode.longExposureGhost));

      expect(restored.asciiArt.isEnabled, isTrue);
      expect(restored.asciiArt.mode, equals(AsciiArtMode.amberCathode));

      expect(restored.subBassExciter.isEnabled, isTrue);
      expect(restored.subBassExciter.mode, equals(SubBassExciterMode.heavyBassDrop));
    });

    test('Clip Equatable props includes Phase 25 configs', () {
      const clip1 = Clip(
        id: 'clip_props',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 1000,
        sourceInMs: 0,
        sourceOutMs: 1000,
      );

      final clip2 = clip1.copyWith(
        echoMotion: EchoMotionConfig.naturalActionBlur,
      );

      expect(clip1, isNot(equals(clip2)));
      expect(clip1.props, contains(clip1.echoMotion));
      expect(clip1.props, contains(clip1.asciiArt));
      expect(clip1.props, contains(clip1.subBassExciter));
    });
  });
}
