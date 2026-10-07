import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/vfx/models/light_leak_config.dart';
import 'package:edito/features/vfx/services/light_leak_compiler_service.dart';
import 'package:edito/features/vfx/models/night_vision_config.dart';
import 'package:edito/features/vfx/services/night_vision_compiler_service.dart';
import 'package:edito/features/audio/models/bitcrusher_config.dart';
import 'package:edito/features/audio/services/bitcrusher_compiler_service.dart';

void main() {
  group('Phase 19: Atmospheric Lighting & Retro Texture Suite', () {
    group('19.1 Light Leak Rainbow Prisms Studio', () {
      test('LightLeakConfig default values & presets', () {
        const config = LightLeakConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.profile, equals(LightLeakProfile.rainbowPrism));
        expect(config.position, equals(LightLeakPosition.topLeft));
        expect(config.intensity, equals(0.60));

        final golden = LightLeakConfig.sunsetGoldenHour;
        expect(golden.isEnabled, isTrue);
        expect(golden.isActive, isTrue);
        expect(golden.profile, equals(LightLeakProfile.warmSunsetFlare));
        expect(golden.position, equals(LightLeakPosition.topLeft));

        final prism = LightLeakConfig.spectralPrism;
        expect(prism.isActive, isTrue);
        expect(prism.profile, equals(LightLeakProfile.rainbowPrism));
        expect(prism.position, equals(LightLeakPosition.centerSweep));

        final filmBurn = LightLeakConfig.kodakFilmBurn;
        expect(filmBurn.profile, equals(LightLeakProfile.vintage35mmBurn));
        expect(filmBurn.position, equals(LightLeakPosition.topRight));

        final cyan = LightLeakConfig.cyberpunkCyanFlare;
        expect(cyan.profile, equals(LightLeakProfile.anamorphicCyanLeak));

        final pastel = LightLeakConfig.dreamyPastelBreathing;
        expect(pastel.profile, equals(LightLeakProfile.subtleAmbientGlow));
      });

      test('LightLeakConfig JSON serialization roundtrip', () {
        const original = LightLeakConfig(
          isEnabled: true,
          profile: LightLeakProfile.vintage35mmBurn,
          position: LightLeakPosition.bottomRight,
          intensity: 0.85,
          speed: 1.5,
          saturation: 1.4,
          warmth: 0.7,
        );

        final json = original.toJson();
        final reconstituted = LightLeakConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.profile, equals(LightLeakProfile.vintage35mmBurn));
        expect(reconstituted.position, equals(LightLeakPosition.bottomRight));
      });

      test('LightLeakCompilerService compiles filters and HUD badges', () {
        // Inactive returns empty
        const disabled = LightLeakConfig(isEnabled: false);
        expect(LightLeakCompilerService.compileFilter(disabled), isEmpty);
        expect(LightLeakCompilerService.getLightLeakBadge(disabled), isEmpty);

        // Warm Sunset Flare
        const sunset = LightLeakConfig.sunsetGoldenHour;
        final sunsetFilter = LightLeakCompilerService.compileFilter(sunset);
        expect(sunsetFilter, contains('eq=brightness='));
        expect(sunsetFilter, contains('colorchannelmixer='));
        expect(sunsetFilter, contains('rr='));

        // Rainbow Prism
        const prism = LightLeakConfig.spectralPrism;
        final prismFilter = LightLeakCompilerService.compileFilter(prism);
        expect(prismFilter, contains('eq=brightness='));
        expect(prismFilter, contains('colorchannelmixer='));

        // Vintage 35mm Burn
        const burn = LightLeakConfig.kodakFilmBurn;
        final burnFilter = LightLeakCompilerService.compileFilter(burn);
        expect(burnFilter, contains('eq=brightness='));
        expect(burnFilter, contains('colorchannelmixer='));

        // HUD badge check
        final badge = LightLeakCompilerService.getLightLeakBadge(prism);
        expect(badge, contains('LEAK:'));
        expect(badge, contains('RAINBOW PRISM'));
      });
    });

    group('19.2 Night Vision & Thermal Infrared Scope Studio', () {
      test('NightVisionConfig default values & presets', () {
        const config = NightVisionConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(NightVisionMode.phosphorGreen));
        expect(config.reticle, equals(NightVisionReticle.rangefinderOsd));
        expect(config.gain, equals(1.4));
        expect(config.noise, equals(0.35));
        expect(config.vignette, equals(0.65));
        expect(config.scanlines, isTrue);

        final specOps = NightVisionConfig.specOpsGreen;
        expect(specOps.isActive, isTrue);
        expect(specOps.mode, equals(NightVisionMode.phosphorGreen));

        final predator = NightVisionConfig.predatorThermal;
        expect(predator.isActive, isTrue);
        expect(predator.mode, equals(NightVisionMode.thermalRainbow));

        final flir = NightVisionConfig.flirIronbowThermal;
        expect(flir.isActive, isTrue);
        expect(flir.mode, equals(NightVisionMode.thermalFlirIronbow));

        final whiteHot = NightVisionConfig.covertWhiteHot;
        expect(whiteHot.isActive, isTrue);
        expect(whiteHot.mode, equals(NightVisionMode.whiteHot));

        final blackHot = NightVisionConfig.sniperBlackHot;
        expect(blackHot.isActive, isTrue);
        expect(blackHot.mode, equals(NightVisionMode.blackHot));
      });

      test('NightVisionConfig JSON serialization roundtrip', () {
        const original = NightVisionConfig(
          isEnabled: true,
          mode: NightVisionMode.thermalFlirIronbow,
          reticle: NightVisionReticle.tacticalGrid,
          gain: 1.8,
          noise: 0.45,
          vignette: 0.75,
          scanlines: false,
        );

        final json = original.toJson();
        final reconstituted = NightVisionConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(NightVisionMode.thermalFlirIronbow));
        expect(reconstituted.reticle, equals(NightVisionReticle.tacticalGrid));
      });

      test('NightVisionCompilerService compiles filters and HUD badges', () {
        // Inactive returns empty
        const disabled = NightVisionConfig(isEnabled: false);
        expect(NightVisionCompilerService.compileFilter(disabled), isEmpty);
        expect(NightVisionCompilerService.getNightVisionBadge(disabled), isEmpty);

        // Phosphor Green
        const green = NightVisionConfig.specOpsGreen;
        final greenFilter = NightVisionCompilerService.compileFilter(green);
        expect(greenFilter, contains('format=gray'));
        expect(greenFilter, contains('colorchannelmixer='));
        expect(greenFilter, contains('noise='));
        expect(greenFilter, contains('vignette='));

        // Thermal FLIR Ironbow
        const flir = NightVisionConfig.flirIronbowThermal;
        final flirFilter = NightVisionCompilerService.compileFilter(flir);
        expect(flirFilter, contains('curves='));
        expect(flirFilter, contains('vignette='));

        // Thermal Rainbow
        const rainbow = NightVisionConfig.predatorThermal;
        final rainbowFilter = NightVisionCompilerService.compileFilter(rainbow);
        expect(rainbowFilter, contains('curves='));

        // White-Hot IR
        const whiteHot = NightVisionConfig.covertWhiteHot;
        final whiteHotFilter = NightVisionCompilerService.compileFilter(whiteHot);
        expect(whiteHotFilter, contains('format=gray'));
        expect(whiteHotFilter, contains('eq=contrast='));

        // Black-Hot IR
        const blackHot = NightVisionConfig.sniperBlackHot;
        final blackHotFilter = NightVisionCompilerService.compileFilter(blackHot);
        expect(blackHotFilter, contains('format=gray,negate'));

        // HUD badge check
        final badge = NightVisionCompilerService.getNightVisionBadge(green);
        expect(badge, contains('NVG:'));
        expect(badge, contains('GEN-3 PHOSPHOR GREEN'));
      });
    });

    group('19.3 8-Bit Lo-Fi Chiptune Bitcrusher Studio', () {
      test('BitcrusherConfig default values & presets', () {
        const config = BitcrusherConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(BitcrusherMode.nesChiptune8Bit));
        expect(config.sampleRateKhz, equals(8.0));
        expect(config.bitDepth, equals(8));
        expect(config.drive, equals(0.25));
        expect(config.mix, equals(1.0));

        final nes = BitcrusherConfig.retroNesConsole;
        expect(nes.isActive, isTrue);
        expect(nes.mode, equals(BitcrusherMode.nesChiptune8Bit));
        expect(nes.bitDepth, equals(8));

        final gb = BitcrusherConfig.dmgGameBoy;
        expect(gb.isActive, isTrue);
        expect(gb.bitDepth, equals(4));

        final arcade = BitcrusherConfig.arcadeCabinet;
        expect(arcade.bitDepth, equals(10));

        final radio = BitcrusherConfig.tacticalRadio;
        expect(radio.mode, equals(BitcrusherMode.walkieTalkieRadio));

        final glitch = BitcrusherConfig.bitStarvedGlitch;
        expect(glitch.bitDepth, equals(2));
      });

      test('BitcrusherConfig JSON serialization roundtrip', () {
        const original = BitcrusherConfig(
          isEnabled: true,
          mode: BitcrusherMode.gameBoyLofi,
          sampleRateKhz: 6.0,
          bitDepth: 4,
          drive: 0.35,
          mix: 0.90,
        );

        final json = original.toJson();
        final reconstituted = BitcrusherConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(BitcrusherMode.gameBoyLofi));
        expect(reconstituted.bitDepth, equals(4));
      });

      test('BitcrusherCompilerService compiles filters and strictly enforces brickwall ceiling (Rule 4)', () {
        // Inactive returns empty
        const disabled = BitcrusherConfig(isEnabled: false);
        expect(BitcrusherCompilerService.compileFilter(disabled), isEmpty);
        expect(BitcrusherCompilerService.getBitcrusherBadge(disabled), isEmpty);

        // Active NES 8-bit
        const nes = BitcrusherConfig.retroNesConsole;
        final nesFilter = BitcrusherCompilerService.compileFilter(nes);
        expect(nesFilter, contains('acrusher='));
        expect(nesFilter, contains('bits=8'));
        expect(nesFilter, contains('lowpass='));
        expect(nesFilter, contains('volume='));

        // MANDATORY AGENTS.md Rule 4 verification:
        expect(
          nesFilter,
          contains('alimiter=limit=0.95:attack=5:release=50:asc=1'),
          reason: 'Rule 4: Must contain strict true-peak brickwall ceiling limiter!',
        );

        // Walkie-talkie mode contains bandpass
        const radio = BitcrusherConfig.tacticalRadio;
        final radioFilter = BitcrusherCompilerService.compileFilter(radio);
        expect(radioFilter, contains('highpass=f=450,lowpass=f=3400'));
        expect(
          radioFilter,
          contains('alimiter=limit=0.95:attack=5:release=50:asc=1'),
        );

        // HUD badge check
        final badge = BitcrusherCompilerService.getBitcrusherBadge(nes);
        expect(badge, contains('👾 8-BIT:'));
        expect(badge, contains('NES 8-BIT CHIPTUNE'));
      });
    });

    group('Clip Model Integration', () {
      test('Clip holds lightLeak, nightVision, and bitcrusher with defaults', () {
        const clip = Clip(
          id: 'test_clip_1',
          assetId: 'asset_1',
          trackId: 'track_1',
          startTimeMs: 0,
          durationMs: 5000,
          sourceInMs: 0,
          sourceOutMs: 5000,
        );

        expect(clip.lightLeak.isActive, isFalse);
        expect(clip.nightVision.isActive, isFalse);
        expect(clip.bitcrusher.isActive, isFalse);
      });

      test('Clip copyWith and JSON roundtrip preserves Phase 19 configs', () {
        const clip = Clip(
          id: 'test_clip_p19',
          assetId: 'asset_19',
          trackId: 'track_v1',
          startTimeMs: 1000,
          durationMs: 4000,
          sourceInMs: 0,
          sourceOutMs: 4000,
          lightLeak: LightLeakConfig.spectralPrism,
          nightVision: NightVisionConfig.specOpsGreen,
          bitcrusher: BitcrusherConfig.retroNesConsole,
        );

        expect(clip.lightLeak.isActive, isTrue);
        expect(clip.nightVision.isActive, isTrue);
        expect(clip.bitcrusher.isActive, isTrue);

        final json = clip.toJson();
        expect(json.containsKey('lightLeak'), isTrue);
        expect(json.containsKey('nightVision'), isTrue);
        expect(json.containsKey('bitcrusher'), isTrue);

        final reconstituted = Clip.fromJson(json);
        expect(reconstituted.lightLeak.profile, equals(LightLeakProfile.rainbowPrism));
        expect(reconstituted.nightVision.mode, equals(NightVisionMode.phosphorGreen));
        expect(reconstituted.bitcrusher.mode, equals(BitcrusherMode.nesChiptune8Bit));

        final modified = clip.copyWith(
          lightLeak: LightLeakConfig.sunsetGoldenHour,
          bitcrusher: BitcrusherConfig.dmgGameBoy,
        );
        expect(modified.lightLeak.profile, equals(LightLeakProfile.warmSunsetFlare));
        expect(modified.bitcrusher.bitDepth, equals(4));
        expect(modified.nightVision.mode, equals(NightVisionMode.phosphorGreen));
      });
    });
  });
}
