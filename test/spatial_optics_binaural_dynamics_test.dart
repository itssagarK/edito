import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/vfx/models/tilt_shift_config.dart';
import 'package:edito/features/vfx/services/tilt_shift_compiler_service.dart';
import 'package:edito/features/vfx/models/neon_glow_config.dart';
import 'package:edito/features/vfx/services/neon_glow_compiler_service.dart';
import 'package:edito/features/audio/models/pitch_harmonizer_config.dart';
import 'package:edito/features/audio/services/pitch_harmonizer_compiler_service.dart';

void main() {
  group('Phase 21: Spatial Optics & Binaural Dynamics Suite', () {
    group('21.1 Tilt-Shift Miniature & Depth-of-Field Diorama Studio', () {
      test('TiltShiftConfig default values & presets', () {
        const config = TiltShiftConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(TiltShiftMode.linearBar));
        expect(config.focusPosition, equals(0.50));
        expect(config.focusBandwidth, equals(0.25));
        expect(config.blurRadius, equals(12.0));
        expect(config.feather, equals(0.20));
        expect(config.saturationBoost, equals(1.35));

        final toy = TiltShiftConfig.toyTownMiniature;
        expect(toy.isEnabled, isTrue);
        expect(toy.isActive, isTrue);
        expect(toy.mode, equals(TiltShiftMode.miniatureModel));
        expect(toy.blurRadius, equals(16.0));
        expect(toy.saturationBoost, equals(1.55));

        final radial = TiltShiftConfig.portraitRadialFocus;
        expect(radial.isActive, isTrue);
        expect(radial.mode, equals(TiltShiftMode.radialCircle));
        expect(radial.focusBandwidth, equals(0.35));

        final macro = TiltShiftConfig.macroShallowDof;
        expect(macro.isActive, isTrue);
        expect(macro.mode, equals(TiltShiftMode.cinematicMacro));
        expect(macro.focusBandwidth, equals(0.15));

        final arch = TiltShiftConfig.architecturalTilt;
        expect(arch.isActive, isTrue);
        expect(arch.angleDeg, equals(15.0));
      });

      test('TiltShiftConfig JSON serialization roundtrip', () {
        const original = TiltShiftConfig(
          isEnabled: true,
          mode: TiltShiftMode.radialCircle,
          focusPosition: 0.42,
          focusBandwidth: 0.32,
          blurRadius: 18.0,
          feather, 0.28,
          saturationBoost: 1.45,
          angleDeg: -10.0,
        );

        final json = original.toJson();
        final reconstituted = TiltShiftConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(TiltShiftMode.radialCircle));
        expect(reconstituted.focusPosition, equals(0.42));
        expect(reconstituted.blurRadius, equals(18.0));
      });

      test('TiltShiftCompilerService compiles FFmpeg filters & HUD badge', () {
        // Disabled returns empty
        const disabled = TiltShiftConfig(isEnabled: false);
        expect(TiltShiftCompilerService.compileFilter(disabled), isEmpty);
        expect(TiltShiftCompilerService.getTiltShiftBadge(disabled), isEmpty);

        // Linear diorama focus
        const diorama = TiltShiftConfig.dioramaHorizontal;
        final dioramaFilter = TiltShiftCompilerService.compileFilter(diorama, targetWidth: 1920, targetHeight: 1080);
        expect(dioramaFilter, contains('eq=saturation=1.30'));
        expect(dioramaFilter, contains('boxblur='));
        expect(dioramaFilter, contains('blend=all_expr='));

        // Radial spotlight focus
        const radial = TiltShiftConfig.portraitRadialFocus;
        final radialFilter = TiltShiftCompilerService.compileFilter(radial, targetWidth: 1280, targetHeight: 720);
        expect(radialFilter, contains('split[ts_sharp][ts_blur]'));
        expect(radialFilter, contains('boxblur='));
        expect(radialFilter, contains('hypot(X-W/2,Y-H/2)'));

        // HUD badge check
        final badge = TiltShiftCompilerService.getTiltShiftBadge(diorama);
        expect(badge, contains('TILT-SHIFT:'));
        expect(badge, contains('LINEAR FOCAL STRIP'));
      });
    });

    group('21.2 Edge Glow Cyberpunk Neon & Hologram Wireframe Studio', () {
      test('NeonGlowConfig default values & presets', () {
        const config = NeonGlowConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(NeonGlowMode.cyberpunkNeon));
        expect(config.glowColorHex, equals('#00E5FF'));
        expect(config.edgeThreshold, equals(0.20));
        expect(config.glowRadius, equals(6.0));
        expect(config.glowIntensity, equals(1.2));
        expect(config.mixWithSource, equals(0.60));
        expect(config.scanlines, isFalse);

        final tokyo = NeonGlowConfig.tokyoNeonCyan;
        expect(tokyo.isEnabled, isTrue);
        expect(tokyo.isActive, isTrue);
        expect(tokyo.mode, equals(NeonGlowMode.cyberpunkNeon));
        expect(tokyo.glowColorHex, equals('#00E5FF'));

        final holo = NeonGlowConfig.hologramMeshBlue;
        expect(holo.isActive, isTrue);
        expect(holo.mode, equals(NeonGlowMode.hologramWireframe));
        expect(holo.scanlines, isTrue);

        final matrix = NeonGlowConfig.matrixWireframe;
        expect(matrix.isActive, isTrue);
        expect(matrix.mode, equals(NeonGlowMode.matrixPhosphor));
        expect(matrix.glowColorHex, equals('#00FF66'));

        final synth = NeonGlowConfig.synthwaveMagenta;
        expect(synth.isActive, isTrue);
        expect(synth.glowColorHex, equals('#FF007F'));
      });

      test('NeonGlowConfig JSON serialization roundtrip', () {
        const original = NeonGlowConfig(
          isEnabled: true,
          mode: NeonGlowMode.matrixPhosphor,
          glowColorHex: '#00FF66',
          edgeThreshold: 0.28,
          glowRadius: 8.5,
          glowIntensity: 1.75,
          mixWithSource: 0.35,
          scanlines: true,
        );

        final json = original.toJson();
        final reconstituted = NeonGlowConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(NeonGlowMode.matrixPhosphor));
        expect(reconstituted.scanlines, isTrue);
        expect(reconstituted.glowIntensity, equals(1.75));
      });

      test('NeonGlowCompilerService compiles FFmpeg filters & HUD badge', () {
        // Disabled returns empty
        const disabled = NeonGlowConfig(isEnabled: false);
        expect(NeonGlowCompilerService.compileFilter(disabled), isEmpty);
        expect(NeonGlowCompilerService.getNeonGlowBadge(disabled), isEmpty);

        // Cyberpunk neon edge composite
        const tokyo = NeonGlowConfig.tokyoNeonCyan;
        final tokyoFilter = NeonGlowCompilerService.compileFilter(tokyo, targetWidth: 1920, targetHeight: 1080);
        expect(tokyoFilter, contains('edgedetect='));
        expect(tokyoFilter, contains('boxblur='));
        expect(tokyoFilter, contains('blend=all_mode=addition'));

        // Hologram wireframe with scanlines
        const holo = NeonGlowConfig.hologramMeshBlue;
        final holoFilter = NeonGlowCompilerService.compileFilter(holo);
        expect(holoFilter, contains('drawgrid='));

        // HUD badge check
        final badge = NeonGlowCompilerService.getNeonGlowBadge(tokyo);
        expect(badge, contains('NEON GLOW:'));
        expect(badge, contains('CYBERPUNK NEON EDGES'));
      });
    });

    group('21.3 Dynamic Vocal Pitch Shifter & Formant Harmonizer Studio', () {
      test('PitchHarmonizerConfig default values & presets', () {
        const config = PitchHarmonizerConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(PitchHarmonizerMode.naturalSemitone));
        expect(config.semitones, equals(0));
        expect(config.cents, equals(0));
        expect(config.harmonyInterval, equals(HarmonyInterval.perfectFifth));
        expect(config.harmonyMix, equals(0.50));
        expect(config.formantPreserve, isTrue);
        expect(config.mix, equals(1.0));

        final fifth = PitchHarmonizerConfig.leadVocalFifthHarmony;
        expect(fifth.isEnabled, isTrue);
        expect(fifth.isActive, isTrue);
        expect(fifth.mode, equals(PitchHarmonizerMode.vocalHarmonizer));
        expect(fifth.harmonyInterval, equals(HarmonyInterval.perfectFifth));

        final sub = PitchHarmonizerConfig.deepSubOctaveDoubler;
        expect(sub.isActive, isTrue);
        expect(sub.semitones, equals(-12));
        expect(sub.harmonyInterval, equals(HarmonyInterval.octaveDown));

        final demon = PitchHarmonizerConfig.demonGravePitch;
        expect(demon.isActive, isTrue);
        expect(demon.mode, equals(PitchHarmonizerMode.deepMonsterSub));
        expect(demon.semitones, equals(-8));

        final dalek = PitchHarmonizerConfig.dalekRoboticMod;
        expect(dalek.isActive, isTrue);
        expect(dalek.mode, equals(PitchHarmonizerMode.roboticRingMod));
      });

      test('PitchHarmonizerConfig JSON serialization roundtrip', () {
        const original = PitchHarmonizerConfig(
          isEnabled: true,
          mode: PitchHarmonizerMode.vocalHarmonizer,
          semitones: 2,
          cents: 10,
          harmonyInterval: HarmonyInterval.majorThird,
          harmonyMix: 0.75,
          formantPreserve: true,
          mix: 0.95,
        );

        final json = original.toJson();
        final reconstituted = PitchHarmonizerConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(PitchHarmonizerMode.vocalHarmonizer));
        expect(reconstituted.semitones, equals(2));
        expect(reconstituted.harmonyInterval, equals(HarmonyInterval.majorThird));
      });

      test('PitchHarmonizerCompilerService strictly enforces Rule 4 brickwall ceiling limiter', () {
        // Disabled returns empty
        const disabled = PitchHarmonizerConfig(isEnabled: false);
        expect(PitchHarmonizerCompilerService.compileFilter(disabled), isEmpty);
        expect(PitchHarmonizerCompilerService.getPitchHarmonizerBadge(disabled), isEmpty);

        // Vocal fifth harmony
        const fifth = PitchHarmonizerConfig.leadVocalFifthHarmony;
        final fifthFilter = PitchHarmonizerCompilerService.compileFilter(fifth);
        expect(fifthFilter, contains('asetrate='));
        expect(fifthFilter, contains('atempo='));
        expect(fifthFilter, contains('amix=inputs=2'));
        // AGENTS.md Rule 4 True-Peak Brickwall Ceiling Limiter check
        expect(fifthFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // Monster deep sub-bass
        const demon = PitchHarmonizerConfig.demonGravePitch;
        final demonFilter = PitchHarmonizerCompilerService.compileFilter(demon);
        expect(demonFilter, contains('bass=g=6'));
        expect(demonFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // Robotic ring mod
        const dalek = PitchHarmonizerConfig.dalekRoboticMod;
        final dalekFilter = PitchHarmonizerCompilerService.compileFilter(dalek);
        expect(dalekFilter, contains('flanger='));
        expect(dalekFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // HUD badge check
        final badge = PitchHarmonizerCompilerService.getPitchHarmonizerBadge(fifth);
        expect(badge, contains('HARMONIZER:'));
        expect(badge, contains('DUAL-VOICE HARMONY'));
      });
    });

    group('21.4 Clip Domain Model Integration', () {
      test('Clip domain model initializes with Phase 21 defaults and copyWith works', () {
        const clip = Clip(
          id: 'clip_21',
          assetId: 'asset_21',
          trackId: 'track_21',
          startTimeMs: 0,
          durationMs: 4000,
          sourceInMs: 0,
          sourceOutMs: 4000,
        );

        expect(clip.tiltShift.isEnabled, isFalse);
        expect(clip.neonGlow.isEnabled, isFalse);
        expect(clip.pitchHarmonizer.isEnabled, isFalse);

        final updatedClip = clip.copyWith(
          tiltShift: TiltShiftConfig.toyTownMiniature,
          neonGlow: NeonGlowConfig.tokyoNeonCyan,
          pitchHarmonizer: PitchHarmonizerConfig.leadVocalFifthHarmony,
        );

        expect(updatedClip.tiltShift.isActive, isTrue);
        expect(updatedClip.neonGlow.isActive, isTrue);
        expect(updatedClip.pitchHarmonizer.isActive, isTrue);

        final json = updatedClip.toJson();
        final reconstituted = Clip.fromJson(json);

        expect(reconstituted.tiltShift, equals(TiltShiftConfig.toyTownMiniature));
        expect(reconstituted.neonGlow, equals(NeonGlowConfig.tokyoNeonCyan));
        expect(reconstituted.pitchHarmonizer, equals(PitchHarmonizerConfig.leadVocalFifthHarmony));
      });
    });
  });
}
