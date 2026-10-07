import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/vfx/models/luma_key_config.dart';
import 'package:edito/features/vfx/services/luma_key_compiler_service.dart';
import 'package:edito/features/vfx/models/matrix_rain_config.dart';
import 'package:edito/features/vfx/services/matrix_rain_compiler_service.dart';
import 'package:edito/features/audio/models/ring_modulator_config.dart';
import 'package:edito/features/audio/services/ring_modulator_compiler_service.dart';

void main() {
  group('Phase 24: Luma Keying & Metallic Ring Modulator Suite', () {
    group('24.1 Luma Key & Silhouette Transparency Studio', () {
      test('LumaKeyConfig default values & curated presets', () {
        const config = LumaKeyConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(LumaKeyMode.darkSilhouette));
        expect(config.threshold, equals(0.20));
        expect(config.tolerance, equals(0.10));
        expect(config.invert, isFalse);
        expect(config.opacity, equals(1.0));

        final blackKey = LumaKeyConfig.blackBackdropKey;
        expect(blackKey.isEnabled, isTrue);
        expect(blackKey.isActive, isTrue);
        expect(blackKey.mode, equals(LumaKeyMode.darkSilhouette));
        expect(blackKey.threshold, equals(0.18));

        final skyKey = LumaKeyConfig.whiteSkyCutout;
        expect(skyKey.isActive, isTrue);
        expect(skyKey.mode, equals(LumaKeyMode.brightSpecular));
        expect(skyKey.threshold, equals(0.82));

        final stencil = LumaKeyConfig.highContrastStencil;
        expect(stencil.isActive, isTrue);
        expect(stencil.mode, equals(LumaKeyMode.highContrastLuma));
        expect(stencil.tolerance, equals(0.03));

        final ghost = LumaKeyConfig.shadowGhost;
        expect(ghost.isActive, isTrue);
        expect(ghost.invert, isTrue);
        expect(ghost.opacity, equals(0.85));

        final midtones = LumaKeyConfig.midtonesBand;
        expect(midtones.isActive, isTrue);
        expect(midtones.mode, equals(LumaKeyMode.midtonesOnly));
      });

      test('LumaKeyConfig JSON serialization roundtrip', () {
        const original = LumaKeyConfig(
          isEnabled: true,
          mode: LumaKeyMode.softThresholdGradient,
          threshold: 0.35,
          tolerance: 0.22,
          invert: true,
          opacity: 0.88,
        );

        final json = original.toJson();
        final reconstituted = LumaKeyConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(LumaKeyMode.softThresholdGradient));
        expect(reconstituted.threshold, equals(0.35));
        expect(reconstituted.tolerance, equals(0.22));
        expect(reconstituted.invert, isTrue);
        expect(reconstituted.opacity, equals(0.88));
      });

      test('LumaKeyCompilerService compiles FFmpeg lumakey filter & HUD badge', () {
        // Disabled returns empty
        const disabled = LumaKeyConfig(isEnabled: false);
        expect(LumaKeyCompilerService.compileFilter(disabled), isEmpty);
        expect(LumaKeyCompilerService.getLumaKeyBadge(disabled), isEmpty);

        // Dark silhouette key
        const dark = LumaKeyConfig(
          isEnabled: true,
          mode: LumaKeyMode.darkSilhouette,
          threshold: 0.20,
          tolerance: 0.10,
        );
        final darkFilter = LumaKeyCompilerService.compileFilter(dark);
        expect(darkFilter, contains('format=yuva420p'));
        expect(darkFilter, contains('lumakey=threshold=0.20:tolerance=0.10'));
        expect(LumaKeyCompilerService.getLumaKeyBadge(dark), contains('LUMA KEY'));

        // Dark silhouette inverted
        const darkInvert = LumaKeyConfig(
          isEnabled: true,
          mode: LumaKeyMode.darkSilhouette,
          threshold: 0.20,
          tolerance: 0.10,
          invert: true,
        );
        final darkInvertFilter = LumaKeyCompilerService.compileFilter(darkInvert);
        expect(darkInvertFilter, contains('negate=components=1'));

        // Bright specular key
        const bright = LumaKeyConfig(
          isEnabled: true,
          mode: LumaKeyMode.brightSpecular,
          threshold: 0.80,
          tolerance: 0.15,
        );
        final brightFilter = LumaKeyCompilerService.compileFilter(bright);
        expect(brightFilter, contains('lumakey='));
        expect(brightFilter, contains('negate=components=1'));

        // High-contrast stencil
        const stencil = LumaKeyConfig(
          isEnabled: true,
          mode: LumaKeyMode.highContrastLuma,
          threshold: 0.50,
          tolerance: 0.01,
        );
        final stencilFilter = LumaKeyCompilerService.compileFilter(stencil);
        expect(stencilFilter, contains('softness=0.01'));

        // Opacity attenuation
        const faded = LumaKeyConfig(
          isEnabled: true,
          threshold: 0.25,
          opacity: 0.75,
        );
        final fadedFilter = LumaKeyCompilerService.compileFilter(faded);
        expect(fadedFilter, contains('colorchannelmixer=aa=0.75'));
      });
    });

    group('24.2 Matrix Digital Code Rain & Cyber Stream Studio', () {
      test('MatrixRainConfig default values & curated presets', () {
        const config = MatrixRainConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(MatrixRainMode.classicPhosphorGreen));
        expect(config.density, equals(0.65));
        expect(config.fallSpeed, equals(1.20));
        expect(config.glyphGlow, equals(0.80));
        expect(config.opacity, equals(0.75));

        final classic = MatrixRainConfig.matrixClassic;
        expect(classic.isEnabled, isTrue);
        expect(classic.isActive, isTrue);
        expect(classic.mode, equals(MatrixRainMode.classicPhosphorGreen));
        expect(classic.density, equals(0.75));

        final neon = MatrixRainConfig.neonCyber;
        expect(neon.isActive, isTrue);
        expect(neon.mode, equals(MatrixRainMode.cyberpunkNeonPink));
        expect(neon.fallSpeed, equals(1.50));

        final quantum = MatrixRainConfig.quantumStream;
        expect(quantum.isActive, isTrue);
        expect(quantum.mode, equals(MatrixRainMode.quantumCyanData));
        expect(quantum.density, equals(0.80));

        final gold = MatrixRainConfig.goldenHex;
        expect(gold.isActive, isTrue);
        expect(gold.mode, equals(MatrixRainMode.goldenAsciiGold));
        expect(gold.glyphGlow, equals(0.95));

        final ghost = MatrixRainConfig.ghostCode;
        expect(ghost.isActive, isTrue);
        expect(ghost.mode, equals(MatrixRainMode.ghostMonochrome));
        expect(ghost.fallSpeed, equals(1.80));
      });

      test('MatrixRainConfig JSON serialization roundtrip', () {
        const original = MatrixRainConfig(
          isEnabled: true,
          mode: MatrixRainMode.quantumCyanData,
          density: 0.85,
          fallSpeed: 2.1,
          glyphGlow: 0.92,
          opacity: 0.68,
        );

        final json = original.toJson();
        final reconstituted = MatrixRainConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(MatrixRainMode.quantumCyanData));
        expect(reconstituted.density, equals(0.85));
        expect(reconstituted.fallSpeed, equals(2.1));
        expect(reconstituted.glyphGlow, equals(0.92));
        expect(reconstituted.opacity, equals(0.68));
      });

      test('MatrixRainCompilerService compiles grid raster & chromatic tints', () {
        // Disabled returns empty
        const disabled = MatrixRainConfig(isEnabled: false);
        expect(MatrixRainCompilerService.compileFilter(disabled), isEmpty);
        expect(MatrixRainCompilerService.getMatrixRainBadge(disabled), isEmpty);

        // Phosphor green mode
        const green = MatrixRainConfig(
          isEnabled: true,
          mode: MatrixRainMode.classicPhosphorGreen,
          density: 0.70,
          glyphGlow: 0.80,
        );
        final gFilter = MatrixRainCompilerService.compileFilter(green);
        expect(gFilter, contains('drawgrid='));
        expect(gFilter, contains('colorchannelmixer='));
        expect(gFilter, contains('hue=h=120:s=1.60'));
        expect(gFilter, contains('unsharp='));
        expect(MatrixRainCompilerService.getMatrixRainBadge(green), contains('MATRIX RAIN'));

        // Cyberpunk pink mode
        const pink = MatrixRainConfig(
          isEnabled: true,
          mode: MatrixRainMode.cyberpunkNeonPink,
          density: 0.60,
        );
        final pFilter = MatrixRainCompilerService.compileFilter(pink);
        expect(pFilter, contains('hue=h=310:s=1.75'));

        // Quantum cyan mode
        const cyan = MatrixRainConfig(
          isEnabled: true,
          mode: MatrixRainMode.quantumCyanData,
          density: 0.80,
        );
        final cFilter = MatrixRainCompilerService.compileFilter(cyan);
        expect(cFilter, contains('hue=h=190:s=1.80'));

        // Golden hex mode
        const gold = MatrixRainConfig(
          isEnabled: true,
          mode: MatrixRainMode.goldenAsciiGold,
          density: 0.50,
        );
        final goldFilter = MatrixRainCompilerService.compileFilter(gold);
        expect(goldFilter, contains('hue=h=45:s=1.65'));

        // Ghost monochrome mode
        const ghost = MatrixRainConfig(
          isEnabled: true,
          mode: MatrixRainMode.ghostMonochrome,
          density: 0.65,
        );
        final ghFilter = MatrixRainCompilerService.compileFilter(ghost);
        expect(ghFilter, contains('hue=s=0'));
      });
    });

    group('24.3 Metallic Ring Modulator & Robotic Vocoder Studio', () {
      test('RingModulatorConfig default values & curated presets', () {
        const config = RingModulatorConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(RingModulatorMode.dalekRobotic));
        expect(config.carrierFreqHz, equals(30.0));
        expect(config.depth, equals(0.85));
        expect(config.harmonicMix, equals(0.20));
        expect(config.mix, equals(0.80));

        final dalek = RingModulatorConfig.dalekRobot;
        expect(dalek.isEnabled, isTrue);
        expect(dalek.isActive, isTrue);
        expect(dalek.mode, equals(RingModulatorMode.dalekRobotic));
        expect(dalek.carrierFreqHz, equals(30.0));

        final alien = RingModulatorConfig.alienSpeech;
        expect(alien.isActive, isTrue);
        expect(alien.mode, equals(RingModulatorMode.alienVocoder));
        expect(alien.carrierFreqHz, equals(440.0));

        final tremor = RingModulatorConfig.subTremor;
        expect(tremor.isActive, isTrue);
        expect(tremor.mode, equals(RingModulatorMode.subHarmonicTremor));
        expect(tremor.carrierFreqHz, equals(12.0));

        final chimes = RingModulatorConfig.cyberChime;
        expect(chimes.isActive, isTrue);
        expect(chimes.mode, equals(RingModulatorMode.cyberBellBells));
        expect(chimes.carrierFreqHz, equals(880.0));

        final space = RingModulatorConfig.spaceInterference;
        expect(space.isActive, isTrue);
        expect(space.mode, equals(RingModulatorMode.dualCarrierScifi));
        expect(space.carrierFreqHz, equals(180.0));
      });

      test('RingModulatorConfig JSON serialization roundtrip', () {
        const original = RingModulatorConfig(
          isEnabled: true,
          mode: RingModulatorMode.alienVocoder,
          carrierFreqHz: 520.0,
          depth: 0.90,
          harmonicMix: 0.45,
          mix: 0.70,
        );

        final json = original.toJson();
        final reconstituted = RingModulatorConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(RingModulatorMode.alienVocoder));
        expect(reconstituted.carrierFreqHz, equals(520.0));
        expect(reconstituted.depth, equals(0.90));
        expect(reconstituted.harmonicMix, equals(0.45));
        expect(reconstituted.mix, equals(0.70));
      });

      test('RingModulatorCompilerService compiles carrier DSP & enforces AGENTS.md Rule 4 true-peak brickwall ceiling', () {
        // Disabled returns empty
        const disabled = RingModulatorConfig(isEnabled: false);
        expect(RingModulatorCompilerService.compileFilter(disabled), isEmpty);
        expect(RingModulatorCompilerService.getRingModulatorBadge(disabled), isEmpty);

        // Dalek robot mode
        const dalek = RingModulatorConfig.dalekRobot;
        final dFilter = RingModulatorCompilerService.compileFilter(dalek);
        expect(dFilter, contains('tremolo=f=30.0:d=0.90'));
        // CRITICAL Rule 4 check: True-peak brickwall ceiling limiter must be strictly present!
        expect(dFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
        expect(RingModulatorCompilerService.getRingModulatorBadge(dalek), contains('RING MOD'));

        // Alien vocoder mode
        const alien = RingModulatorConfig.alienSpeech;
        final aFilter = RingModulatorCompilerService.compileFilter(alien);
        expect(aFilter, contains('equalizer=f=440.0:t=q:w=2.0:g=6'));
        expect(aFilter, contains('tremolo=f=440.0:d=0.80'));
        expect(aFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // Sub tremor mode
        const tremor = RingModulatorConfig.subTremor;
        final tFilter = RingModulatorCompilerService.compileFilter(tremor);
        expect(tFilter, contains('tremolo=f=12.0:d=0.95'));
        expect(tFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // Cyber chime mode
        const chimes = RingModulatorConfig.cyberChime;
        final cFilter = RingModulatorCompilerService.compileFilter(chimes);
        expect(cFilter, contains('tremolo=f=880.0:d=0.85'));
        expect(cFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // Dual carrier mode
        const space = RingModulatorConfig.spaceInterference;
        final sFilter = RingModulatorCompilerService.compileFilter(space);
        expect(sFilter, contains('tremolo=f=180.0:d=0.75'));
        expect(sFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
      });
    });

    group('24.4 Clip Model Integration & Pipeline Consistency', () {
      test('Clip initializes with default lumaKey, matrixRain, and ringModulator configs', () {
        const clip = Clip(
          id: 'test_clip_24',
          assetId: 'asset_24',
          trackId: 'track_video',
          startTimeMs: 0,
          durationMs: 4000,
          sourceInMs: 0,
          sourceOutMs: 4000,
        );

        expect(clip.lumaKey, equals(const LumaKeyConfig()));
        expect(clip.lumaKey.isActive, isFalse);

        expect(clip.matrixRain, equals(const MatrixRainConfig()));
        expect(clip.matrixRain.isActive, isFalse);

        expect(clip.ringModulator, equals(const RingModulatorConfig()));
        expect(clip.ringModulator.isActive, isFalse);
      });

      test('Clip copyWith updates lumaKey, matrixRain, and ringModulator', () {
        const initialClip = Clip(
          id: 'clip_orig',
          assetId: 'asset_orig',
          trackId: 'track_0',
          startTimeMs: 0,
          durationMs: 3000,
          sourceInMs: 0,
          sourceOutMs: 3000,
        );

        final updatedClip = initialClip.copyWith(
          lumaKey: LumaKeyConfig.blackBackdropKey,
          matrixRain: MatrixRainConfig.matrixClassic,
          ringModulator: RingModulatorConfig.dalekRobot,
        );

        expect(updatedClip.lumaKey.isActive, isTrue);
        expect(updatedClip.lumaKey.mode, equals(LumaKeyMode.darkSilhouette));

        expect(updatedClip.matrixRain.isActive, isTrue);
        expect(updatedClip.matrixRain.mode, equals(MatrixRainMode.classicPhosphorGreen));

        expect(updatedClip.ringModulator.isActive, isTrue);
        expect(updatedClip.ringModulator.mode, equals(RingModulatorMode.dalekRobotic));
      });

      test('Clip JSON roundtrip preserves Phase 24 configs perfectly', () {
        const configuredClip = Clip(
          id: 'clip_roundtrip_24',
          assetId: 'asset_roundtrip_24',
          trackId: 'track_0',
          startTimeMs: 500,
          durationMs: 5500,
          sourceInMs: 200,
          sourceOutMs: 5700,
          lumaKey: LumaKeyConfig.highContrastStencil,
          matrixRain: MatrixRainConfig.neonCyber,
          ringModulator: RingModulatorConfig.alienSpeech,
        );

        final json = configuredClip.toJson();
        final reconstituted = Clip.fromJson(json);

        expect(reconstituted.lumaKey, equals(LumaKeyConfig.highContrastStencil));
        expect(reconstituted.lumaKey.isActive, isTrue);

        expect(reconstituted.matrixRain, equals(MatrixRainConfig.neonCyber));
        expect(reconstituted.matrixRain.isActive, isTrue);

        expect(reconstituted.ringModulator, equals(RingModulatorConfig.alienSpeech));
        expect(reconstituted.ringModulator.isActive, isTrue);
      });
    });
  });
}
