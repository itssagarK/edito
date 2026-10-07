import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/vfx/models/anamorphic_flare_config.dart';
import 'package:edito/features/vfx/services/anamorphic_flare_compiler_service.dart';
import 'package:edito/features/vfx/models/film_halation_config.dart';
import 'package:edito/features/vfx/services/film_halation_compiler_service.dart';
import 'package:edito/features/audio/models/tape_cassette_config.dart';
import 'package:edito/features/audio/services/tape_cassette_compiler_service.dart';

void main() {
  group('Phase 17: Feature 17.1 - Anamorphic Streak Flare Studio', () {
    test('AnamorphicFlareConfig default values and presets', () {
      const config = AnamorphicFlareConfig();
      expect(config.isEnabled, isFalse);
      expect(config.intensity, equals(0.70));
      expect(config.streakLength, equals(0.85));
      expect(config.threshold, equals(0.75));
      expect(config.tint, equals(FlareTint.cinemaBlue));
      expect(config.spikes, equals(0));
      expect(config.verticalSpread, equals(0.12));

      expect(AnamorphicFlareConfig.hollywoodCyan.tint, equals(FlareTint.cinemaBlue));
      expect(AnamorphicFlareConfig.hollywoodCyan.spikes, equals(0));
      expect(AnamorphicFlareConfig.goldenHour.tint, equals(FlareTint.goldenAmber));
      expect(AnamorphicFlareConfig.sciFiNeon.tint, equals(FlareTint.neonMagenta));
      expect(AnamorphicFlareConfig.sciFiNeon.spikes, equals(6));
      expect(AnamorphicFlareConfig.polarIce.tint, equals(FlareTint.iceWhite));
      expect(AnamorphicFlareConfig.polarIce.spikes, equals(4));
      expect(AnamorphicFlareConfig.matrixTerminal.tint, equals(FlareTint.emeraldMatrix));
      expect(AnamorphicFlareConfig.matrixTerminal.spikes, equals(8));
    });

    test('AnamorphicFlareConfig copyWith and immutability', () {
      const config = AnamorphicFlareConfig();
      final updated = config.copyWith(
        isEnabled: true,
        intensity: 0.95,
        tint: FlareTint.neonMagenta,
        spikes: 8,
      );

      expect(updated.isEnabled, isTrue);
      expect(updated.intensity, equals(0.95));
      expect(updated.tint, equals(FlareTint.neonMagenta));
      expect(updated.spikes, equals(8));
      expect(updated.streakLength, equals(0.85)); // Unchanged
    });

    test('AnamorphicFlareConfig JSON round-trip serialization', () {
      const config = AnamorphicFlareConfig(
        isEnabled: true,
        intensity: 0.88,
        streakLength: 0.92,
        threshold: 0.80,
        tint: FlareTint.goldenAmber,
        spikes: 6,
        verticalSpread: 0.15,
      );

      final json = config.toJson();
      final restored = AnamorphicFlareConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.intensity, equals(0.88));
      expect(restored.streakLength, equals(0.92));
      expect(restored.threshold, equals(0.80));
      expect(restored.tint, equals(FlareTint.goldenAmber));
      expect(restored.spikes, equals(6));
      expect(restored.verticalSpread, equals(0.15));
      expect(restored, equals(config));
    });

    test('AnamorphicFlareCompilerService compiles filters and HUD badge', () {
      const disabledConfig = AnamorphicFlareConfig();
      expect(AnamorphicFlareCompilerService.compileFilter(disabledConfig), isNull);

      const enabledConfig = AnamorphicFlareConfig(
        isEnabled: true,
        intensity: 0.80,
        streakLength: 0.90,
        threshold: 0.72,
        tint: FlareTint.cinemaBlue,
        spikes: 4,
      );

      final filter = AnamorphicFlareCompilerService.compileFilter(enabledConfig);
      expect(filter, isNotNull);
      expect(filter, contains('colorchannelmixer'));
      expect(filter, contains('gblur'));
      expect(filter, contains('curves'));

      final hudBadge = AnamorphicFlareCompilerService.getHudBadge(enabledConfig);
      expect(hudBadge, contains('Cinema Blue'));
      expect(hudBadge, contains('80%'));
    });
  });

  group('Phase 17: Feature 17.2 - 35mm Film Halation Studio', () {
    test('FilmHalationConfig default values and presets', () {
      const config = FilmHalationConfig();
      expect(config.isEnabled, isFalse);
      expect(config.intensity, equals(0.65));
      expect(config.radius, equals(14.0));
      expect(config.threshold, equals(0.70));
      expect(config.hue, equals(HalationHue.cineStillRed));
      expect(config.warmthScatter, equals(0.35));

      expect(FilmHalationConfig.cineStill800T.hue, equals(HalationHue.cineStillRed));
      expect(FilmHalationConfig.cineStill800T.radius, equals(16.0));
      expect(FilmHalationConfig.vision3500T.hue, equals(HalationHue.vision3WarmOrange));
      expect(FilmHalationConfig.eternaBloom.hue, equals(HalationHue.eternaMagenta));
      expect(FilmHalationConfig.kodachrome64.hue, equals(HalationHue.kodachromeAmber));
    });

    test('FilmHalationConfig copyWith and immutability', () {
      const config = FilmHalationConfig();
      final updated = config.copyWith(
        isEnabled: true,
        intensity: 0.90,
        radius: 22.0,
        hue: HalationHue.eternaMagenta,
      );

      expect(updated.isEnabled, isTrue);
      expect(updated.intensity, equals(0.90));
      expect(updated.radius, equals(22.0));
      expect(updated.hue, equals(HalationHue.eternaMagenta));
      expect(updated.threshold, equals(0.70)); // Unchanged
    });

    test('FilmHalationConfig JSON round-trip serialization', () {
      const config = FilmHalationConfig(
        isEnabled: true,
        intensity: 0.82,
        radius: 18.5,
        threshold: 0.68,
        hue: HalationHue.kodachromeAmber,
        warmthScatter: 0.45,
      );

      final json = config.toJson();
      final restored = FilmHalationConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.intensity, equals(0.82));
      expect(restored.radius, equals(18.5));
      expect(restored.threshold, equals(0.68));
      expect(restored.hue, equals(HalationHue.kodachromeAmber));
      expect(restored.warmthScatter, equals(0.45));
      expect(restored, equals(config));
    });

    test('FilmHalationCompilerService compiles filters and HUD badge', () {
      const disabledConfig = FilmHalationConfig();
      expect(FilmHalationCompilerService.compileFilter(disabledConfig), isNull);

      const enabledConfig = FilmHalationConfig(
        isEnabled: true,
        intensity: 0.75,
        radius: 15.0,
        threshold: 0.65,
        hue: HalationHue.cineStillRed,
      );

      final filter = FilmHalationCompilerService.compileFilter(enabledConfig);
      expect(filter, isNotNull);
      expect(filter, contains('colorchannelmixer'));
      expect(filter, contains('gblur'));
      expect(filter, contains('curves'));

      final hudBadge = FilmHalationCompilerService.getHudBadge(enabledConfig);
      expect(hudBadge, contains('CineStill Neon Red'));
      expect(hudBadge, contains('15px'));
    });
  });

  group('Phase 17: Feature 17.3 - Vintage Tape Cassette Studio', () {
    test('TapeCassetteConfig default values and presets', () {
      const config = TapeCassetteConfig();
      expect(config.isEnabled, isFalse);
      expect(config.era, equals(TapeCassetteEra.walkman1985));
      expect(config.wowRateHz, equals(0.5));
      expect(config.wowDepth, equals(0.35));
      expect(config.flutterRateHz, equals(9.5));
      expect(config.flutterDepth, equals(0.25));
      expect(config.tapeWarmth, equals(0.60));
      expect(config.hissFloorDb, equals(-42.0));

      expect(TapeCassetteConfig.walkman1985.era, equals(TapeCassetteEra.walkman1985));
      expect(TapeCassetteConfig.microcassette.era, equals(TapeCassetteEra.dictaphone));
      expect(TapeCassetteConfig.vhsHiFi.era, equals(TapeCassetteEra.vhsHiFi));
      expect(TapeCassetteConfig.masterReel15ips.era, equals(TapeCassetteEra.masterReel));
      expect(TapeCassetteConfig.wornThriftTape.era, equals(TapeCassetteEra.wornCassette));
    });

    test('TapeCassetteConfig copyWith and immutability', () {
      const config = TapeCassetteConfig();
      final updated = config.copyWith(
        isEnabled: true,
        wowDepth: 0.55,
        flutterDepth: 0.40,
        tapeWarmth: 0.85,
      );

      expect(updated.isEnabled, isTrue);
      expect(updated.wowDepth, equals(0.55));
      expect(updated.flutterDepth, equals(0.40));
      expect(updated.tapeWarmth, equals(0.85));
      expect(updated.wowRateHz, equals(0.5)); // Unchanged
    });

    test('TapeCassetteConfig JSON round-trip serialization', () {
      const config = TapeCassetteConfig(
        isEnabled: true,
        era: TapeCassetteEra.vhsHiFi,
        wowRateHz: 0.4,
        wowDepth: 0.28,
        flutterRateHz: 8.0,
        flutterDepth: 0.20,
        tapeWarmth: 0.70,
        hissFloorDb,
      );

      final json = config.toJson();
      final restored = TapeCassetteConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.era, equals(TapeCassetteEra.vhsHiFi));
      expect(restored.wowRateHz, equals(0.4));
      expect(restored.wowDepth, equals(0.28));
      expect(restored.flutterRateHz, equals(8.0));
      expect(restored.flutterDepth, equals(0.20));
      expect(restored.tapeWarmth, equals(0.70));
      expect(restored, equals(config));
    });

    test('TapeCassetteCompilerService compiles filters and strictly enforces brickwall ceiling', () {
      const disabledConfig = TapeCassetteConfig();
      expect(TapeCassetteCompilerService.compileFilters(disabledConfig), isEmpty);

      const enabledConfig = TapeCassetteConfig(
        isEnabled: true,
        era: TapeCassetteEra.walkman1985,
        wowDepth: 0.40,
        flutterDepth: 0.30,
        tapeWarmth: 0.65,
      );

      final filters = TapeCassetteCompilerService.compileFilters(enabledConfig);
      expect(filters, isNotEmpty);

      // Verify wow and flutter vibrato DSP filters
      final filterString = filters.join(',');
      expect(filterString, contains('vibrato'));
      expect(filterString, contains('equalizer'));
      expect(filterString, contains('lowpass'));

      // CRITICAL: Strictly verify AGENTS.md Rule 4 True-Peak Brickwall Limiter
      expect(
        filterString,
        contains('alimiter=limit=0.95:attack=5:release=50:asc=1'),
        reason: 'AGENTS.md Rule 4 requires true-peak brickwall ceiling alimiter=limit=0.95:attack=5:release=50:asc=1',
      );

      final hudBadge = TapeCassetteCompilerService.getHudBadge(enabledConfig);
      expect(hudBadge, contains('Walkman 1985'));
      expect(hudBadge, contains('Wow 40%'));
    });
  });

  group('Clip Model Integration', () {
    test('Clip includes anamorphicFlare, filmHalation, tapeCassette defaults', () {
      const clip = Clip(
        id: 'clip_p17_test',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      expect(clip.anamorphicFlare.isEnabled, isFalse);
      expect(clip.filmHalation.isEnabled, isFalse);
      expect(clip.tapeCassette.isEnabled, isFalse);
    });

    test('Clip copyWith preserves and updates Phase 17 configs', () {
      const clip = Clip(
        id: 'clip_p17_test',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      final updated = clip.copyWith(
        anamorphicFlare: const AnamorphicFlareConfig(isEnabled: true, intensity: 0.85),
        filmHalation: const FilmHalationConfig(isEnabled: true, radius: 20.0),
        tapeCassette: const TapeCassetteConfig(isEnabled: true, wowDepth: 0.5),
      );

      expect(updated.anamorphicFlare.isEnabled, isTrue);
      expect(updated.anamorphicFlare.intensity, equals(0.85));
      expect(updated.filmHalation.isEnabled, isTrue);
      expect(updated.filmHalation.radius, equals(20.0));
      expect(updated.tapeCassette.isEnabled, isTrue);
      expect(updated.tapeCassette.wowDepth, equals(0.5));
    });

    test('Clip serialization roundtrip retains Phase 17 fields', () {
      const clip = Clip(
        id: 'clip_p17_json_test',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        anamorphicFlare: AnamorphicFlareConfig(
          isEnabled: true,
          tint: FlareTint.neonMagenta,
          spikes: 6,
        ),
        filmHalation: FilmHalationConfig(
          isEnabled: true,
          hue: HalationHue.eternaMagenta,
          radius: 18.0,
        ),
        tapeCassette: TapeCassetteConfig(
          isEnabled: true,
          era: TapeCassetteEra.masterReel,
          wowDepth: 0.15,
        ),
      );

      final json = clip.toJson();
      final restored = Clip.fromJson(json);

      expect(restored.anamorphicFlare.isEnabled, isTrue);
      expect(restored.anamorphicFlare.tint, equals(FlareTint.neonMagenta));
      expect(restored.anamorphicFlare.spikes, equals(6));

      expect(restored.filmHalation.isEnabled, isTrue);
      expect(restored.filmHalation.hue, equals(HalationHue.eternaMagenta));
      expect(restored.filmHalation.radius, equals(18.0));

      expect(restored.tapeCassette.isEnabled, isTrue);
      expect(restored.tapeCassette.era, equals(TapeCassetteEra.masterReel));
      expect(restored.tapeCassette.wowDepth, equals(0.15));
    });
  });
}
