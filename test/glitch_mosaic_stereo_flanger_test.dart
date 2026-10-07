import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/vfx/models/pixel_sort_config.dart';
import 'package:edito/features/vfx/services/pixel_sort_compiler_service.dart';
import 'package:edito/features/vfx/models/posterize_pop_config.dart';
import 'package:edito/features/vfx/services/posterize_pop_compiler_service.dart';
import 'package:edito/features/audio/models/jet_flanger_config.dart';
import 'package:edito/features/audio/services/jet_flanger_compiler_service.dart';

void main() {
  group('Phase 23: Glitch Mosaic & Stereo Flanger Dynamic Suite', () {
    group('23.1 Pixel Sort & Glitch Streak Studio', () {
      test('PixelSortConfig default values & curated presets', () {
        const config = PixelSortConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(PixelSortMode.verticalDown));
        expect(config.threshold, equals(0.60));
        expect(config.streakLength, equals(0.40));
        expect(config.angleDeg, equals(90.0));
        expect(config.smoothBlending, isTrue);

        final cyber = PixelSortConfig.cyberRain;
        expect(cyber.isEnabled, isTrue);
        expect(cyber.isActive, isTrue);
        expect(cyber.mode, equals(PixelSortMode.verticalDown));
        expect(cyber.threshold, equals(0.55));
        expect(cyber.streakLength, equals(0.65));

        final tear = PixelSortConfig.matrixTear;
        expect(tear.isActive, isTrue);
        expect(tear.mode, equals(PixelSortMode.horizontalTear));
        expect(tear.angleDeg, equals(0.0));

        final slant = PixelSortConfig.neonSlant;
        expect(slant.isActive, isTrue);
        expect(slant.mode, equals(PixelSortMode.diagonalSlant));
        expect(slant.angleDeg, equals(45.0));

        final burst = PixelSortConfig.radiantExplosion;
        expect(burst.isActive, isTrue);
        expect(burst.mode, equals(PixelSortMode.radiantBurst));
        expect(burst.threshold, equals(0.45));

        final phosphor = PixelSortConfig.phosphorData;
        expect(phosphor.isActive, isTrue);
        expect(phosphor.mode, equals(PixelSortMode.thresholdBand));
        expect(phosphor.threshold, equals(0.70));
      });

      test('PixelSortConfig JSON serialization roundtrip', () {
        const original = PixelSortConfig(
          isEnabled: true,
          mode: PixelSortMode.diagonalSlant,
          threshold: 0.68,
          streakLength: 0.52,
          angleDeg: 35.0,
          smoothBlending: false,
        );

        final json = original.toJson();
        final reconstituted = PixelSortConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(PixelSortMode.diagonalSlant));
        expect(reconstituted.threshold, equals(0.68));
        expect(reconstituted.streakLength, equals(0.52));
        expect(reconstituted.angleDeg, equals(35.0));
        expect(reconstituted.smoothBlending, isFalse);
      });

      test('PixelSortCompilerService compiles deterministic FFmpeg filters & HUD badge', () {
        // Disabled returns empty
        const disabled = PixelSortConfig(isEnabled: false);
        expect(PixelSortCompilerService.compileFilter(disabled), isEmpty);
        expect(PixelSortCompilerService.getPixelSortBadge(disabled), isEmpty);

        // Vertical down
        const vertical = PixelSortConfig(
          isEnabled: true,
          mode: PixelSortMode.verticalDown,
          threshold: 0.60,
          streakLength: 0.50,
        );
        final vFilter = PixelSortCompilerService.compileFilter(vertical);
        expect(vFilter, contains('boxblur='));
        expect(vFilter, contains('blend=all_expr='));
        expect(vFilter, contains('gt(Y,'));
        expect(PixelSortCompilerService.getPixelSortBadge(vertical), contains('PIXEL SORT'));

        // Horizontal tear
        const horiz = PixelSortConfig(
          isEnabled: true,
          mode: PixelSortMode.horizontalTear,
          threshold: 0.50,
          streakLength: 0.70,
        );
        final hFilter = PixelSortCompilerService.compileFilter(horiz);
        expect(hFilter, contains('boxblur=lr='));

        // Diagonal slant
        const slant = PixelSortConfig(
          isEnabled: true,
          mode: PixelSortMode.diagonalSlant,
          threshold: 0.60,
          streakLength: 0.50,
          angleDeg: 45.0,
        );
        final sFilter = PixelSortCompilerService.compileFilter(slant);
        expect(sFilter, contains('rotate='));

        // Radiant burst
        const burst = PixelSortConfig(
          isEnabled: true,
          mode: PixelSortMode.radiantBurst,
          threshold: 0.40,
        );
        final bFilter = PixelSortCompilerService.compileFilter(burst);
        expect(bFilter, contains('hue=s=1.35'));

        // Threshold band
        const band = PixelSortConfig(
          isEnabled: true,
          mode: PixelSortMode.thresholdBand,
          threshold: 0.70,
        );
        final bandFilter = PixelSortCompilerService.compileFilter(band);
        expect(bandFilter, contains('eq=contrast=1.20'));
      });
    });

    group('23.2 Threshold Posterization & Pop Art Chromatic Studio', () {
      test('PosterizePopConfig default values & curated presets', () {
        const config = PosterizePopConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(PosterizePopMode.warholPopArt));
        expect(config.colorLevels, equals(4));
        expect(config.outlineStrength, equals(0.40));
        expect(config.saturationBoost, equals(1.50));
        expect(config.contrast, equals(1.25));

        final warhol = PosterizePopConfig.warholPop;
        expect(warhol.isEnabled, isTrue);
        expect(warhol.isActive, isTrue);
        expect(warhol.mode, equals(PosterizePopMode.warholPopArt));
        expect(warhol.colorLevels, equals(4));
        expect(warhol.saturationBoost, equals(1.80));

        final comic = PosterizePopConfig.comicBook;
        expect(comic.isActive, isTrue);
        expect(comic.mode, equals(PosterizePopMode.comicBookInk));
        expect(comic.colorLevels, equals(3));
        expect(comic.outlineStrength, equals(0.85));

        final duotone = PosterizePopConfig.cyberDuotone;
        expect(duotone.isActive, isTrue);
        expect(duotone.mode, equals(PosterizePopMode.cyberpunkDuotone));
        expect(duotone.saturationBoost, equals(1.90));

        final retro = PosterizePopConfig.retro8Bit;
        expect(retro.isActive, isTrue);
        expect(retro.mode, equals(PosterizePopMode.retro8BitPoster));
        expect(retro.colorLevels, equals(8));
        expect(retro.outlineStrength, equals(0.0));

        final noir = PosterizePopConfig.noirMonochrome;
        expect(noir.isActive, isTrue);
        expect(noir.mode, equals(PosterizePopMode.monochromeNoir));
        expect(noir.colorLevels, equals(3));
      });

      test('PosterizePopConfig JSON serialization roundtrip', () {
        const original = PosterizePopConfig(
          isEnabled: true,
          mode: PosterizePopMode.cyberpunkDuotone,
          colorLevels: 6,
          outlineStrength: 0.65,
          saturationBoost: 1.75,
          contrast: 1.40,
        );

        final json = original.toJson();
        final reconstituted = PosterizePopConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(PosterizePopMode.cyberpunkDuotone));
        expect(reconstituted.colorLevels, equals(6));
        expect(reconstituted.outlineStrength, equals(0.65));
        expect(reconstituted.saturationBoost, equals(1.75));
        expect(reconstituted.contrast, equals(1.40));
      });

      test('PosterizePopCompilerService compiles discrete lutrgb stepping & modes', () {
        // Disabled returns empty
        const disabled = PosterizePopConfig(isEnabled: false);
        expect(PosterizePopCompilerService.compileFilter(disabled), isEmpty);
        expect(PosterizePopCompilerService.getPosterizePopBadge(disabled), isEmpty);

        // Warhol pop art
        const warhol = PosterizePopConfig(
          isEnabled: true,
          mode: PosterizePopMode.warholPopArt,
          colorLevels: 4,
          saturationBoost: 1.80,
          contrast: 1.30,
        );
        final wFilter = PosterizePopCompilerService.compileFilter(warhol);
        expect(wFilter, contains('lutrgb=r='));
        expect(wFilter, contains('hue=h=45:s=1.80'));
        expect(wFilter, contains('eq=contrast=1.30'));
        expect(PosterizePopCompilerService.getPosterizePopBadge(warhol), contains('POSTERIZE POP'));

        // Comic ink
        const comic = PosterizePopConfig(
          isEnabled: true,
          mode: PosterizePopMode.comicBookInk,
          colorLevels: 3,
          contrast: 1.50,
        );
        final cFilter = PosterizePopCompilerService.compileFilter(comic);
        expect(cFilter, contains('lutrgb='));
        expect(cFilter, contains('eq=contrast='));

        // Cyberpunk duotone
        const duo = PosterizePopConfig(
          isEnabled: true,
          mode: PosterizePopMode.cyberpunkDuotone,
          colorLevels: 4,
          saturationBoost: 1.90,
        );
        final dFilter = PosterizePopCompilerService.compileFilter(duo);
        expect(dFilter, contains('colorchannelmixer='));
        expect(dFilter, contains('hue=s=1.90'));

        // Retro 8-bit
        const retro = PosterizePopConfig(
          isEnabled: true,
          mode: PosterizePopMode.retro8BitPoster,
          colorLevels: 8,
          saturationBoost: 1.30,
        );
        final rFilter = PosterizePopCompilerService.compileFilter(retro);
        expect(rFilter, contains('eq=saturation=1.30:contrast=1.15'));

        // Monochrome noir
        const noir = PosterizePopConfig(
          isEnabled: true,
          mode: PosterizePopMode.monochromeNoir,
          colorLevels: 3,
        );
        final nFilter = PosterizePopCompilerService.compileFilter(noir);
        expect(nFilter, contains('hue=s=0'));
      });
    });

    group('23.3 Jet Flanger & Barberpole Frequency Phaser Studio', () {
      test('JetFlangerConfig default values & curated presets', () {
        const config = JetFlangerConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(JetFlangerMode.jetEngineFlyby));
        expect(config.sweepSpeedHz, equals(0.25));
        expect(config.depthMs, equals(6.0));
        expect(config.feedback, equals(0.70));
        expect(config.stereoPhaseDeg, equals(90.0));
        expect(config.mix, equals(0.75));

        final flyby = JetFlangerConfig.jetFlyby;
        expect(flyby.isEnabled, isTrue);
        expect(flyby.isActive, isTrue);
        expect(flyby.mode, equals(JetFlangerMode.jetEngineFlyby));
        expect(flyby.sweepSpeedHz, equals(0.20));
        expect(flyby.feedback, equals(0.85));

        final barberpole = JetFlangerConfig.barberpole;
        expect(barberpole.isActive, isTrue);
        expect(barberpole.mode, equals(JetFlangerMode.barberpolePhaser));
        expect(barberpole.stereoPhaseDeg, equals(180.0));

        final metallic = JetFlangerConfig.metallicRing;
        expect(metallic.isActive, isTrue);
        expect(metallic.mode, equals(JetFlangerMode.metallicResonator));
        expect(metallic.depthMs, equals(2.0));
        expect(metallic.feedback, equals(0.88));

        final stereo = JetFlangerConfig.stereoWide;
        expect(stereo.isActive, isTrue);
        expect(stereo.mode, equals(JetFlangerMode.stereoSpreadFlanger));
        expect(stereo.stereoPhaseDeg, equals(180.0));

        final deepSpace = JetFlangerConfig.deepSpaceHypnotic;
        expect(deepSpace.isActive, isTrue);
        expect(deepSpace.mode, equals(JetFlangerMode.deepSpaceComb));
        expect(deepSpace.sweepSpeedHz, equals(0.10));
      });

      test('JetFlangerConfig JSON serialization roundtrip', () {
        const original = JetFlangerConfig(
          isEnabled: true,
          mode: JetFlangerMode.metallicResonator,
          sweepSpeedHz: 1.45,
          depthMs: 3.2,
          feedback: 0.82,
          stereoPhaseDeg: 60.0,
          mix: 0.90,
        );

        final json = original.toJson();
        final reconstituted = JetFlangerConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(JetFlangerMode.metallicResonator));
        expect(reconstituted.sweepSpeedHz, equals(1.45));
        expect(reconstituted.depthMs, equals(3.2));
        expect(reconstituted.feedback, equals(0.82));
        expect(reconstituted.stereoPhaseDeg, equals(60.0));
        expect(reconstituted.mix, equals(0.90));
      });

      test('JetFlangerCompilerService compiles comb flangers & enforces AGENTS.md Rule 4 true-peak brickwall ceiling', () {
        // Disabled returns empty
        const disabled = JetFlangerConfig(isEnabled: false);
        expect(JetFlangerCompilerService.compileFilter(disabled), isEmpty);
        expect(JetFlangerCompilerService.getJetFlangerBadge(disabled), isEmpty);

        // Jet engine flyby mode
        const flyby = JetFlangerConfig.jetFlyby;
        final fFilter = JetFlangerCompilerService.compileFilter(flyby);
        expect(fFilter, contains('flanger=delay=1.5:depth=8.5:regen=85'));
        expect(fFilter, contains('speed=0.20'));
        // CRITICAL Rule 4 check: True-peak brickwall ceiling limiter must be strictly present!
        expect(fFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
        expect(JetFlangerCompilerService.getJetFlangerBadge(flyby), contains('JET FLANGER'));

        // Barberpole phaser mode
        const barber = JetFlangerConfig.barberpole;
        final bFilter = JetFlangerCompilerService.compileFilter(barber);
        expect(bFilter, contains('aphaser=in_gain=0.6:out_gain=0.8:delay=4.5'));
        expect(bFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // Metallic resonator mode
        const metal = JetFlangerConfig.metallicRing;
        final mFilter = JetFlangerCompilerService.compileFilter(metal);
        expect(mFilter, contains('flanger=delay=0.4:depth=2.0:regen=88:width=95:speed=1.50:shape=triangular'));
        expect(mFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // Stereo wide flanger mode
        const stereo = JetFlangerConfig.stereoWide;
        final sFilter = JetFlangerCompilerService.compileFilter(stereo);
        expect(sFilter, contains('flanger=delay=2.0'));
        expect(sFilter, contains('extrastereo=m=1.45'));
        expect(sFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // Deep space comb mode
        const space = JetFlangerConfig.deepSpaceHypnotic;
        final spFilter = JetFlangerCompilerService.compileFilter(space);
        expect(spFilter, contains('flanger=delay=4.0'));
        expect(spFilter, contains('extrastereo=m=1.25'));
        expect(spFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
      });
    });

    group('23.4 Clip Model Integration & Pipeline Consistency', () {
      test('Clip initializes with default pixelSort, posterizePop, and jetFlanger configs', () {
        const clip = Clip(
          id: 'test_clip_23',
          assetId: 'asset_23',
          trackId: 'track_video',
          startTimeMs: 0,
          durationMs: 5000,
          sourceInMs: 0,
          sourceOutMs: 5000,
        );

        expect(clip.pixelSort, equals(const PixelSortConfig()));
        expect(clip.pixelSort.isActive, isFalse);

        expect(clip.posterizePop, equals(const PosterizePopConfig()));
        expect(clip.posterizePop.isActive, isFalse);

        expect(clip.jetFlanger, equals(const JetFlangerConfig()));
        expect(clip.jetFlanger.isActive, isFalse);
      });

      test('Clip copyWith updates pixelSort, posterizePop, and jetFlanger', () {
        const initialClip = Clip(
          id: 'clip_orig',
          assetId: 'asset_orig',
          trackId: 'track_0',
          startTimeMs: 0,
          durationMs: 4000,
          sourceInMs: 0,
          sourceOutMs: 4000,
        );

        final updatedClip = initialClip.copyWith(
          pixelSort: PixelSortConfig.cyberRain,
          posterizePop: PosterizePopConfig.warholPop,
          jetFlanger: JetFlangerConfig.jetFlyby,
        );

        expect(updatedClip.pixelSort.isActive, isTrue);
        expect(updatedClip.pixelSort.mode, equals(PixelSortMode.verticalDown));

        expect(updatedClip.posterizePop.isActive, isTrue);
        expect(updatedClip.posterizePop.mode, equals(PosterizePopMode.warholPopArt));

        expect(updatedClip.jetFlanger.isActive, isTrue);
        expect(updatedClip.jetFlanger.mode, equals(JetFlangerMode.jetEngineFlyby));
      });

      test('Clip JSON roundtrip preserves Phase 23 configs perfectly', () {
        const configuredClip = Clip(
          id: 'clip_roundtrip',
          assetId: 'asset_roundtrip',
          trackId: 'track_0',
          startTimeMs: 1000,
          durationMs: 6000,
          sourceInMs: 500,
          sourceOutMs: 6500,
          pixelSort: PixelSortConfig.neonSlant,
          posterizePop: PosterizePopConfig.comicBook,
          jetFlanger: JetFlangerConfig.metallicRing,
        );

        final json = configuredClip.toJson();
        final reconstituted = Clip.fromJson(json);

        expect(reconstituted.pixelSort, equals(PixelSortConfig.neonSlant));
        expect(reconstituted.pixelSort.isActive, isTrue);

        expect(reconstituted.posterizePop, equals(PosterizePopConfig.comicBook));
        expect(reconstituted.posterizePop.isActive, isTrue);

        expect(reconstituted.jetFlanger, equals(JetFlangerConfig.metallicRing));
        expect(reconstituted.jetFlanger.isActive, isTrue);
      });
    });
  });
}
