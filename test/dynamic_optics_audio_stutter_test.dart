import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/vfx/models/chromatic_aberration_config.dart';
import 'package:edito/features/vfx/services/chromatic_aberration_compiler_service.dart';
import 'package:edito/features/vfx/models/solarize_invert_config.dart';
import 'package:edito/features/vfx/services/solarize_invert_compiler_service.dart';
import 'package:edito/features/audio/models/audio_stutter_config.dart';
import 'package:edito/features/audio/services/audio_stutter_compiler_service.dart';

void main() {
  group('Phase 22: Dynamic Optics & Audio Stutter Suite', () {
    group('22.1 RGB Color Aberration & Holographic Glitch Shift Studio', () {
      test('ChromaticAberrationConfig default values & presets', () {
        const config = ChromaticAberrationConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(ChromaticAberrationMode.horizontalSplit));
        expect(config.shiftAmount, equals(0.35));
        expect(config.angleDeg, equals(0.0));
        expect(config.falloff, equals(0.50));
        expect(config.jitterSpeed, equals(3.0));
        expect(config.colorMix, equals(0.85));

        final cyber = ChromaticAberrationConfig.cyberGlitch;
        expect(cyber.isEnabled, isTrue);
        expect(cyber.isActive, isTrue);
        expect(cyber.mode, equals(ChromaticAberrationMode.horizontalSplit));
        expect(cyber.shiftAmount, equals(0.65));
        expect(cyber.jitterSpeed, equals(5.0));

        final prism = ChromaticAberrationConfig.lensPrism;
        expect(prism.isActive, isTrue);
        expect(prism.mode, equals(ChromaticAberrationMode.radialDispersion));
        expect(prism.falloff, equals(0.70));

        final anaglyph = ChromaticAberrationConfig.vintageAnaglyph;
        expect(anaglyph.isActive, isTrue);
        expect(anaglyph.mode, equals(ChromaticAberrationMode.anaglyph3d));
        expect(anaglyph.shiftAmount, equals(0.50));

        final holo = ChromaticAberrationConfig.hologramShift;
        expect(holo.isActive, isTrue);
        expect(holo.mode, equals(ChromaticAberrationMode.hologramJitter));
        expect(holo.jitterSpeed, equals(4.0));

        final radial = ChromaticAberrationConfig.radialWarp;
        expect(radial.isActive, isTrue);
        expect(radial.mode, equals(ChromaticAberrationMode.radialDispersion));
        expect(radial.shiftAmount, equals(0.85));
      });

      test('ChromaticAberrationConfig JSON serialization roundtrip', () {
        const original = ChromaticAberrationConfig(
          isEnabled: true,
          mode: ChromaticAberrationMode.prismaticAngle,
          shiftAmount: 0.55,
          angleDeg: 45.0,
          falloff: 0.65,
          jitterSpeed: 4.5,
          colorMix: 0.90,
        );

        final json = original.toJson();
        final reconstituted = ChromaticAberrationConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(ChromaticAberrationMode.prismaticAngle));
        expect(reconstituted.shiftAmount, equals(0.55));
        expect(reconstituted.angleDeg, equals(45.0));
        expect(reconstituted.jitterSpeed, equals(4.5));
      });

      test('ChromaticAberrationCompilerService compiles FFmpeg filters & HUD badge', () {
        // Disabled returns empty
        const disabled = ChromaticAberrationConfig(isEnabled: false);
        expect(ChromaticAberrationCompilerService.compileFilter(disabled), isEmpty);
        expect(ChromaticAberrationCompilerService.getChromaticAberrationBadge(disabled), isEmpty);

        // Horizontal split
        const horiz = ChromaticAberrationConfig(
          isEnabled: true,
          mode: ChromaticAberrationMode.horizontalSplit,
          shiftAmount: 0.5,
        );
        final horizFilter = ChromaticAberrationCompilerService.compileFilter(horiz);
        expect(horizFilter, contains('rgbashift=rh=12:rv=0:bh=-12:bv=0:gh=0:gv=0:edge=smear'));
        expect(ChromaticAberrationCompilerService.getChromaticAberrationBadge(horiz), contains('CHROMATIC RGB'));

        // Directional angle
        const angle = ChromaticAberrationConfig(
          isEnabled: true,
          mode: ChromaticAberrationMode.prismaticAngle,
          shiftAmount: 0.5,
          angleDeg: 90.0,
        );
        final angleFilter = ChromaticAberrationCompilerService.compileFilter(angle);
        expect(angleFilter, contains('rgbashift='));
        expect(angleFilter, contains('rv=12'));

        // Anaglyph 3D
        const anaglyph = ChromaticAberrationConfig(
          isEnabled: true,
          mode: ChromaticAberrationMode.anaglyph3d,
          shiftAmount: 0.5,
        );
        final anaglyphFilter = ChromaticAberrationCompilerService.compileFilter(anaglyph);
        expect(anaglyphFilter, contains('rgbashift=rh=15:rv=0:bh=-15'));

        // Hologram jitter temporal expression
        const holo = ChromaticAberrationConfig(
          isEnabled: true,
          mode: ChromaticAberrationMode.hologramJitter,
          shiftAmount: 0.5,
          jitterSpeed: 3.5,
        );
        final holoFilter = ChromaticAberrationCompilerService.compileFilter(holo);
        expect(holoFilter, contains("rgbashift=rh='12*sin(2*PI*3.5*t)':bh='-12*sin(2*PI*3.5*t)'"));

        // Radial dispersion
        const radial = ChromaticAberrationConfig(
          isEnabled: true,
          mode: ChromaticAberrationMode.radialDispersion,
          shiftAmount: 0.5,
          colorMix: 0.95,
        );
        final radialFilter = ChromaticAberrationCompilerService.compileFilter(radial);
        expect(radialFilter, contains('rgbashift=rh=12:rv=7:bh=-12:bv=-7'));
        expect(radialFilter, contains('eq=saturation=1.12:contrast=1.05'));
      });
    });

    group('22.2 Thermal Solarization & Psychedelic Color Invert Studio', () {
      test('SolarizeInvertConfig default values & presets', () {
        const config = SolarizeInvertConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(SolarizeInvertMode.sabattier));
        expect(config.threshold, equals(0.50));
        expect(config.intensity, equals(0.85));
        expect(config.saturationBoost, equals(1.40));
        expect(config.tintHue, equals(180.0));

        final sabattier = SolarizeInvertConfig.sabattierSolarize;
        expect(sabattier.isEnabled, isTrue);
        expect(sabattier.isActive, isTrue);
        expect(sabattier.mode, equals(SolarizeInvertMode.sabattier));
        expect(sabattier.intensity, equals(0.90));

        final negative = SolarizeInvertConfig.negativeFilm;
        expect(negative.isActive, isTrue);
        expect(negative.mode, equals(SolarizeInvertMode.negativeInvert));
        expect(negative.intensity, equals(1.0));

        final acid = SolarizeInvertConfig.acidTrip;
        expect(acid.isActive, isTrue);
        expect(acid.mode, equals(SolarizeInvertMode.psychedelic));
        expect(acid.saturationBoost, equals(2.20));

        final thermal = SolarizeInvertConfig.thermalInfrared;
        expect(thermal.isActive, isTrue);
        expect(thermal.mode, equals(SolarizeInvertMode.thermalHeat));
        expect(thermal.threshold, equals(0.30));

        final cross = SolarizeInvertConfig.darkroomCross;
        expect(cross.isActive, isTrue);
        expect(cross.mode, equals(SolarizeInvertMode.crossProcess));
        expect(cross.threshold, equals(0.60));
      });

      test('SolarizeInvertConfig JSON serialization roundtrip', () {
        const original = SolarizeInvertConfig(
          isEnabled: true,
          mode: SolarizeInvertMode.thermalHeat,
          threshold: 0.35,
          intensity: 0.92,
          saturationBoost: 1.85,
          tintHue: 45.0,
        );

        final json = original.toJson();
        final reconstituted = SolarizeInvertConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(SolarizeInvertMode.thermalHeat));
        expect(reconstituted.threshold, equals(0.35));
        expect(reconstituted.intensity, equals(0.92));
        expect(reconstituted.saturationBoost, equals(1.85));
      });

      test('SolarizeInvertCompilerService compiles FFmpeg filters & HUD badge', () {
        // Disabled returns empty
        const disabled = SolarizeInvertConfig(isEnabled: false);
        expect(SolarizeInvertCompilerService.compileFilter(disabled), isEmpty);
        expect(SolarizeInvertCompilerService.getSolarizeInvertBadge(disabled), isEmpty);

        // Negative invert
        const neg = SolarizeInvertConfig(
          isEnabled: true,
          mode: SolarizeInvertMode.negativeInvert,
          intensity: 1.0,
        );
        final negFilter = SolarizeInvertCompilerService.compileFilter(neg);
        expect(negFilter, contains('lutrgb=r=negval:g=negval:b=negval'));
        expect(SolarizeInvertCompilerService.getSolarizeInvertBadge(neg), contains('SOLARIZE'));

        // Sabattier inflection
        const sab = SolarizeInvertConfig(
          isEnabled: true,
          mode: SolarizeInvertMode.sabattier,
          threshold: 0.50,
          intensity: 1.0,
        );
        final sabFilter = SolarizeInvertCompilerService.compileFilter(sab);
        expect(sabFilter, contains("lutrgb=r='if(gt(val,128),255-val,val)'"));

        // Psychedelic
        const psych = SolarizeInvertConfig(
          isEnabled: true,
          mode: SolarizeInvertMode.psychedelic,
          threshold: 0.40,
          tintHue: 280.0,
          saturationBoost: 2.0,
          intensity: 1.0,
        );
        final psychFilter = SolarizeInvertCompilerService.compileFilter(psych);
        expect(psychFilter, contains('hue=h=280:s=2.00'));

        // Thermal heat
        const thermal = SolarizeInvertConfig(
          isEnabled: true,
          mode: SolarizeInvertMode.thermalHeat,
          saturationBoost: 1.5,
          intensity: 1.0,
        );
        final thermalFilter = SolarizeInvertCompilerService.compileFilter(thermal);
        expect(thermalFilter, contains("curves=r='0/0 0.5/1 1/0.8'"));
        expect(thermalFilter, contains('eq=saturation=1.50:contrast=1.20'));

        // Cross process
        const cross = SolarizeInvertConfig(
          isEnabled: true,
          mode: SolarizeInvertMode.crossProcess,
          intensity: 1.0,
        );
        final crossFilter = SolarizeInvertCompilerService.compileFilter(cross);
        expect(crossFilter, contains("curves=r='0/0 0.5/0.85 1/1'"));
      });
    });

    group('22.3 Rhythmic Audio Stutter & Glitch Buffer Beat Repeater Studio', () {
      test('AudioStutterConfig default values & presets', () {
        const config = AudioStutterConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.division, equals(StutterDivision.eighth));
        expect(config.mode, equals(AudioStutterMode.straight));
        expect(config.repeats, equals(4));
        expect(config.bpm, equals(120.0));
        expect(config.gateWidth, equals(0.75));
        expect(config.pitchDropSemitones, equals(4.0));
        expect(config.mix, equals(0.85));

        // Beat slice calculation: at 120 BPM, 1 beat = 500ms
        // Eighth note = 250ms
        expect(config.sliceDurationMs, closeTo(250.0, 0.1));

        final roll = AudioStutterConfig.eighthBeatRoll;
        expect(roll.isEnabled, isTrue);
        expect(roll.isActive, isTrue);
        expect(roll.repeats, equals(4));

        final glitch = AudioStutterConfig.sixteenthGlitch;
        expect(glitch.isActive, isTrue);
        expect(glitch.division, equals(StutterDivision.sixteenth));
        expect(glitch.repeats, equals(6));
        // At 128 BPM, 1/16 note = (60000 / 128) * 0.25 = 117.1875ms
        expect(glitch.sliceDurationMs, closeTo(117.18, 0.1));

        final drop = AudioStutterConfig.pitchDropBrake;
        expect(drop.isActive, isTrue);
        expect(drop.mode, equals(AudioStutterMode.pitchDrop));
        expect(drop.pitchDropSemitones, equals(6.0));

        final drill = AudioStutterConfig.machineGunDrill;
        expect(drill.isActive, isTrue);
        expect(drill.division, equals(StutterDivision.thirtySecond));
        expect(drill.mode, equals(AudioStutterMode.accelerando));
        expect(drill.repeats, equals(8));

        final cloud = AudioStutterConfig.granularCloud;
        expect(cloud.isActive, isTrue);
        expect(cloud.mode, equals(AudioStutterMode.granularCloud));
        expect(cloud.repeats, equals(5));
      });

      test('AudioStutterConfig JSON serialization roundtrip', () {
        const original = AudioStutterConfig(
          isEnabled: true,
          division: StutterDivision.sixteenth,
          mode: AudioStutterMode.accelerando,
          repeats: 6,
          bpm: 135.0,
          gateWidth: 0.82,
          pitchDropSemitones: 5.5,
          mix: 0.90,
        );

        final json = original.toJson();
        final reconstituted = AudioStutterConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.division, equals(StutterDivision.sixteenth));
        expect(reconstituted.mode, equals(AudioStutterMode.accelerando));
        expect(reconstituted.repeats, equals(6));
        expect(reconstituted.bpm, equals(135.0));
      });

      test('AudioStutterCompilerService compiles FFmpeg DSP pipeline with Rule 4 limiter', () {
        // Disabled returns empty
        const disabled = AudioStutterConfig(isEnabled: false);
        expect(AudioStutterCompilerService.compileFilter(disabled), isEmpty);
        expect(AudioStutterCompilerService.getAudioStutterBadge(disabled), isEmpty);

        // Straight roll with multi-tap delay
        const roll = AudioStutterConfig(
          isEnabled: true,
          division: StutterDivision.eighth,
          mode: AudioStutterMode.straight,
          repeats: 4,
          bpm: 120.0,
          gateWidth: 0.70,
        );
        final rollFilter = AudioStutterCompilerService.compileFilter(roll);
        expect(rollFilter, contains('aecho='));
        expect(rollFilter, contains('tremolo='));
        // CRITICAL Safeguard (AGENTS.md Rule 4):
        expect(rollFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
        expect(AudioStutterCompilerService.getAudioStutterBadge(roll), contains('STUTTER'));

        // Pitch drop tape stop brake
        const drop = AudioStutterConfig(
          isEnabled: true,
          mode: AudioStutterMode.pitchDrop,
          repeats: 4,
          pitchDropSemitones: 6.0,
        );
        final dropFilter = AudioStutterCompilerService.compileFilter(drop);
        expect(dropFilter, contains('vibrato='));
        expect(dropFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // Reverse echo ping-pong
        const reverse = AudioStutterConfig(
          isEnabled: true,
          mode: AudioStutterMode.reverseEcho,
          repeats: 3,
        );
        final reverseFilter = AudioStutterCompilerService.compileFilter(reverse);
        expect(reverseFilter, contains('aphaser='));
        expect(reverseFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // Granular cloud flanger diffusion
        const cloud = AudioStutterConfig(
          isEnabled: true,
          mode: AudioStutterMode.granularCloud,
          repeats: 4,
        );
        final cloudFilter = AudioStutterCompilerService.compileFilter(cloud);
        expect(cloudFilter, contains('flanger='));
        expect(cloudFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
      });
    });

    group('Clip Domain Model Integration', () {
      test('Clip initializes with new default configs and supports copyWith and JSON roundtrip', () {
        final clip = Clip(
          id: 'test_clip_p22',
          assetId: 'asset_22',
          trackId: 'track_22',
          startTimeMs: 0,
          durationMs: 4000,
          sourceInMs: 0,
          sourceOutMs: 4000,
        );

        // Verify default instances
        expect(clip.chromaticAberration.isEnabled, isFalse);
        expect(clip.solarizeInvert.isEnabled, isFalse);
        expect(clip.audioStutter.isEnabled, isFalse);

        // Verify copyWith
        final updated = clip.copyWith(
          chromaticAberration: ChromaticAberrationConfig.cyberGlitch,
          solarizeInvert: SolarizeInvertConfig.sabattierSolarize,
          audioStutter: AudioStutterConfig.eighthBeatRoll,
        );

        expect(updated.chromaticAberration.isActive, isTrue);
        expect(updated.solarizeInvert.isActive, isTrue);
        expect(updated.audioStutter.isActive, isTrue);

        // Verify JSON roundtrip
        final json = updated.toJson();
        final reconstituted = Clip.fromJson(json);

        expect(reconstituted.chromaticAberration.mode, equals(ChromaticAberrationMode.horizontalSplit));
        expect(reconstituted.solarizeInvert.mode, equals(SolarizeInvertMode.sabattier));
        expect(reconstituted.audioStutter.division, equals(StutterDivision.eighth));
      });
    });
  });
}
