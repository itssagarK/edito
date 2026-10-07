import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/vfx/models/kaleidoscope_config.dart';
import 'package:edito/features/vfx/services/kaleidoscope_compiler_service.dart';
import 'package:edito/features/vfx/models/datamosh_glitch_config.dart';
import 'package:edito/features/vfx/services/datamosh_glitch_compiler_service.dart';
import 'package:edito/features/audio/models/tremolo_wah_config.dart';
import 'package:edito/features/audio/services/tremolo_wah_compiler_service.dart';

void main() {
  group('Phase 20: Prismatic Geometry & Audio Modulation Suite', () {
    group('20.1 Prismatic Kaleidoscope & Radial Mirror Studio', () {
      test('KaleidoscopeConfig default values & curated presets', () {
        const config = KaleidoscopeConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.pattern, equals(KaleidoscopePattern.hexagon6));
        expect(config.segments, equals(6));
        expect(config.rotationSpeed, equals(0.20));
        expect(config.zoom, equals(1.0));
        expect(config.centerX, equals(0.5));
        expect(config.centerY, equals(0.5));

        final hexagon = KaleidoscopeConfig.classicHexagon;
        expect(hexagon.isEnabled, isTrue);
        expect(hexagon.isActive, isTrue);
        expect(hexagon.segments, equals(6));
        expect(hexagon.pattern, equals(KaleidoscopePattern.hexagon6));

        final mandala = KaleidoscopeConfig.sacredMandala;
        expect(mandala.isActive, isTrue);
        expect(mandala.segments, equals(12));
        expect(mandala.pattern, equals(KaleidoscopePattern.dodecagon12));

        final quad = KaleidoscopeConfig.quadRetroMirror;
        expect(quad.isActive, isTrue);
        expect(quad.segments, equals(4));
        expect(quad.pattern, equals(KaleidoscopePattern.quad4));

        final crystal = KaleidoscopeConfig.cosmicCrystal;
        expect(crystal.isActive, isTrue);
        expect(crystal.segments, equals(8));
        expect(crystal.pattern, equals(KaleidoscopePattern.octagon8));

        final twin = KaleidoscopeConfig.twinSymmetry;
        expect(twin.isActive, isTrue);
        expect(twin.segments, equals(2));
        expect(twin.pattern, equals(KaleidoscopePattern.bilateral2));
      });

      test('KaleidoscopeConfig JSON serialization roundtrip', () {
        const original = KaleidoscopeConfig(
          isEnabled: true,
          pattern: KaleidoscopePattern.octagon8,
          segments: 8,
          rotationSpeed: 0.45,
          zoom: 1.35,
          centerX: 0.55,
          centerY: 0.48,
        );

        final json = original.toJson();
        final reconstituted = KaleidoscopeConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.pattern, equals(KaleidoscopePattern.octagon8));
        expect(reconstituted.segments, equals(8));
        expect(reconstituted.rotationSpeed, equals(0.45));
        expect(reconstituted.zoom, equals(1.35));
      });

      test('KaleidoscopeCompilerService compiles FFmpeg filters & HUD badge', () {
        // Disabled config returns empty
        const disabled = KaleidoscopeConfig(isEnabled: false);
        expect(KaleidoscopeCompilerService.compileFilter(disabled), isEmpty);
        expect(KaleidoscopeCompilerService.getKaleidoscopeBadge(disabled), isEmpty);

        // Bilateral twin mirror
        const twin = KaleidoscopeConfig.twinSymmetry;
        final twinFilter = KaleidoscopeCompilerService.compileFilter(twin, targetWidth: 1920, targetHeight: 1080);
        expect(twinFilter, contains('split[orig][left]'));
        expect(twinFilter, contains('hflip'));
        expect(twinFilter, contains('hstack'));

        // Hexagon & Octagon radial symmetry
        const hexagon = KaleidoscopeConfig.classicHexagon;
        final hexFilter = KaleidoscopeCompilerService.compileFilter(hexagon, targetWidth: 1280, targetHeight: 720);
        expect(hexFilter, contains('split[base][fliph]'));
        expect(hexFilter, contains('hstack'));
        expect(hexFilter, contains('vstack'));
        expect(hexFilter, contains('rotate='));

        // HUD badge format
        final badge = KaleidoscopeCompilerService.getKaleidoscopeBadge(hexagon);
        expect(badge, contains('KALEIDOSCOPE:'));
        expect(badge, contains('HEXAGONAL 6-FACET'));
        expect(badge, contains('6 FACETS'));
      });
    });

    group('20.2 Glitch Data-Mosh & Compression Artifacts Studio', () {
      test('DatamoshGlitchConfig default values & curated presets', () {
        const config = DatamoshGlitchConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.profile, equals(DatamoshGlitchProfile.classicIFrameDropout));
        expect(config.intensity, equals(0.70));
        expect(config.blockiness, equals(0.60));
        expect(config.macroblockSize, equals(16));
        expect(config.chromaBleed, equals(0.50));
        expect(config.trackingLoss, isFalse);

        final classic = DatamoshGlitchConfig.classicDatamosh;
        expect(classic.isEnabled, isTrue);
        expect(classic.isActive, isTrue);
        expect(classic.profile, equals(DatamoshGlitchProfile.classicIFrameDropout));

        final cyberpunk = DatamoshGlitchConfig.cyberpunkGlitch;
        expect(cyberpunk.isActive, isTrue);
        expect(cyberpunk.profile, equals(DatamoshGlitchProfile.cyberpunkRgbDisplace));
        expect(cyberpunk.chromaBleed, equals(0.85));

        final extreme = DatamoshGlitchConfig.extremeCompression;
        expect(extreme.isActive, isTrue);
        expect(extreme.profile, equals(DatamoshGlitchProfile.extremeMacroblockDecay));
        expect(extreme.macroblockSize, equals(32));

        final vhs = DatamoshGlitchConfig.vhsTapeTear;
        expect(vhs.isActive, isTrue);
        expect(vhs.profile, equals(DatamoshGlitchProfile.vhsTrackingLoss));
        expect(vhs.trackingLoss, isTrue);

        final fatal = DatamoshGlitchConfig.fatalDataDecay;
        expect(fatal.isActive, isTrue);
        expect(fatal.profile, equals(DatamoshGlitchProfile.fatalDecaySmear));
      });

      test('DatamoshGlitchConfig JSON serialization roundtrip', () {
        const original = DatamoshGlitchConfig(
          isEnabled: true,
          profile: DatamoshGlitchProfile.vhsTrackingLoss,
          intensity: 0.88,
          blockiness: 0.75,
          macroblockSize: 24,
          chromaBleed: 0.65,
          trackingLoss: true,
        );

        final json = original.toJson();
        final reconstituted = DatamoshGlitchConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.profile, equals(DatamoshGlitchProfile.vhsTrackingLoss));
        expect(reconstituted.macroblockSize, equals(24));
        expect(reconstituted.trackingLoss, isTrue);
      });

      test('DatamoshGlitchCompilerService compiles FFmpeg filters & HUD badge', () {
        // Disabled returns empty
        const disabled = DatamoshGlitchConfig(isEnabled: false);
        expect(DatamoshGlitchCompilerService.compileFilter(disabled), isEmpty);
        expect(DatamoshGlitchCompilerService.getDatamoshBadge(disabled), isEmpty);

        // Cyberpunk RGB displacement
        const cyberpunk = DatamoshGlitchConfig.cyberpunkGlitch;
        final cyberFilter = DatamoshGlitchCompilerService.compileFilter(cyberpunk, targetWidth: 1920, targetHeight: 1080);
        expect(cyberFilter, contains('rgbashift='));
        expect(cyberFilter, contains('rh='));
        expect(cyberFilter, contains('bh='));

        // Macroblock downscale/upscale decimation
        const extreme = DatamoshGlitchConfig.extremeCompression;
        final extremeFilter = DatamoshGlitchCompilerService.compileFilter(extreme, targetWidth: 1280, targetHeight: 720);
        expect(extremeFilter, contains('scale=w='));
        expect(extremeFilter, contains('flags=neighbor'));

        // VHS tracking tear noise
        const vhs = DatamoshGlitchConfig.vhsTapeTear;
        final vhsFilter = DatamoshGlitchCompilerService.compileFilter(vhs);
        expect(vhsFilter, contains('noise=alls='));

        // HUD badge check
        final badge = DatamoshGlitchCompilerService.getDatamoshBadge(cyberpunk);
        expect(badge, contains('DATAMOSH:'));
        expect(badge, contains('CYBERPUNK RGB DISPLACEMENT'));
      });
    });

    group('20.3 Stereo Tremolo & Auto-Wah Dynamic Filter Studio', () {
      test('TremoloWahConfig default values & curated presets', () {
        const config = TremoloWahConfig();
        expect(config.isEnabled, isFalse);
        expect(config.isActive, isFalse);
        expect(config.mode, equals(TremoloWahMode.stereoTremolo));
        expect(config.waveform, equals(LfoWaveform.sine));
        expect(config.frequencyHz, equals(4.0));
        expect(config.depth, equals(0.70));
        expect(config.resonance, equals(3.0));
        expect(config.centerFreqHz, equals(1000.0));
        expect(config.stereoPhaseOffsetDeg, equals(90.0));
        expect(config.mix, equals(1.0));

        final surf = TremoloWahConfig.vintageSurfTremolo;
        expect(surf.isEnabled, isTrue);
        expect(surf.isActive, isTrue);
        expect(surf.mode, equals(TremoloWahMode.stereoTremolo));
        expect(surf.frequencyHz, equals(5.0));

        final funk = TremoloWahConfig.funkyAutoWah;
        expect(funk.isActive, isTrue);
        expect(funk.mode, equals(TremoloWahMode.autoWahFunk));
        expect(funk.resonance, equals(5.5));
        expect(funk.centerFreqHz, equals(1200.0));

        final leslie = TremoloWahConfig.leslieOrganSpeaker;
        expect(leslie.isActive, isTrue);
        expect(leslie.mode, equals(TremoloWahMode.leslieRotary));
        expect(leslie.stereoPhaseOffsetDeg, equals(120.0));

        final edm = TremoloWahConfig.hardEdmStutter;
        expect(edm.isActive, isTrue);
        expect(edm.mode, equals(TremoloWahMode.stutterGate));
        expect(edm.waveform, equals(LfoWaveform.square));

        final phaser = TremoloWahConfig.trippyPhaserSweep;
        expect(phaser.isActive, isTrue);
        expect(phaser.mode, equals(TremoloWahMode.psychedelicSweep));
        expect(phaser.frequencyHz, equals(0.5));
      });

      test('TremoloWahConfig JSON serialization roundtrip', () {
        const original = TremoloWahConfig(
          isEnabled: true,
          mode: TremoloWahMode.autoWahFunk,
          waveform: LfoWaveform.triangle,
          frequencyHz: 3.2,
          depth: 0.85,
          resonance: 6.0,
          centerFreqHz: 1400.0,
          stereoPhaseOffsetDeg: 45.0,
          mix: 0.90,
        );

        final json = original.toJson();
        final reconstituted = TremoloWahConfig.fromJson(json);

        expect(reconstituted, equals(original));
        expect(reconstituted.isActive, isTrue);
        expect(reconstituted.mode, equals(TremoloWahMode.autoWahFunk));
        expect(reconstituted.waveform, equals(LfoWaveform.triangle));
        expect(reconstituted.frequencyHz, equals(3.2));
        expect(reconstituted.resonance, equals(6.0));
        expect(reconstituted.centerFreqHz, equals(1400.0));
      });

      test('TremoloWahCompilerService strictly enforces Rule 4 brickwall ceiling limiter', () {
        // Inactive returns empty
        const disabled = TremoloWahConfig(isEnabled: false);
        expect(TremoloWahCompilerService.compileFilter(disabled), isEmpty);
        expect(TremoloWahCompilerService.getTremoloWahBadge(disabled), isEmpty);

        // Stereo Tremolo LFO
        const surf = TremoloWahConfig.vintageSurfTremolo;
        final surfFilter = TremoloWahCompilerService.compileFilter(surf);
        expect(surfFilter, contains('apulsator=hz=5.00:amount=0.75:mode=sine'));
        // AGENTS.md Rule 4 True-Peak Brickwall Ceiling Limiter check
        expect(surfFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // Funky Auto-Wah
        const funk = TremoloWahConfig.funkyAutoWah;
        final funkFilter = TremoloWahCompilerService.compileFilter(funk);
        expect(funkFilter, contains('equalizer=f=1200:t=q:w=5.5:g=9'));
        expect(funkFilter, contains('tremolo=f=2.50:d=0.85'));
        expect(funkFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // Leslie Rotary Speaker
        const leslie = TremoloWahConfig.leslieOrganSpeaker;
        final leslieFilter = TremoloWahCompilerService.compileFilter(leslie);
        expect(leslieFilter, contains('vibrato='));
        expect(leslieFilter, contains('tremolo='));
        expect(leslieFilter, contains('extrastereo=m=1.35'));
        expect(leslieFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // Psychedelic Resonant Sweep
        const sweep = TremoloWahConfig.trippyPhaserSweep;
        final sweepFilter = TremoloWahCompilerService.compileFilter(sweep);
        expect(sweepFilter, contains('bandpass=f=1800:width_type=q:w=4.5'));
        expect(sweepFilter, contains('apulsator=hz=0.50'));
        expect(sweepFilter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));

        // HUD badge check
        final badge = TremoloWahCompilerService.getTremoloWahBadge(funk);
        expect(badge, contains('MODULATION:'));
        expect(badge, contains('AUTO-WAH FUNK ENVELOPE'));
      });
    });

    group('20.4 Clip Domain Model Integration', () {
      test('Clip domain model initializes with Phase 20 defaults and copyWith works', () {
        const clip = Clip(
          id: 'clip_20',
          assetId: 'asset_20',
          trackId: 'track_20',
          startTimeMs: 0,
          durationMs: 5000,
          sourceInMs: 0,
          sourceOutMs: 5000,
        );

        expect(clip.kaleidoscope.isEnabled, isFalse);
        expect(clip.datamoshGlitch.isEnabled, isFalse);
        expect(clip.tremoloWah.isEnabled, isFalse);

        final updatedClip = clip.copyWith(
          kaleidoscope: KaleidoscopeConfig.classicHexagon,
          datamoshGlitch: DatamoshGlitchConfig.cyberpunkGlitch,
          tremoloWah: TremoloWahConfig.funkyAutoWah,
        );

        expect(updatedClip.kaleidoscope.isActive, isTrue);
        expect(updatedClip.datamoshGlitch.isActive, isTrue);
        expect(updatedClip.tremoloWah.isActive, isTrue);

        final json = updatedClip.toJson();
        final reconstituted = Clip.fromJson(json);

        expect(reconstituted.kaleidoscope, equals(KaleidoscopeConfig.classicHexagon));
        expect(reconstituted.datamoshGlitch, equals(DatamoshGlitchConfig.cyberpunkGlitch));
        expect(reconstituted.tremoloWah, equals(TremoloWahConfig.funkyAutoWah));
      });
    });
  });
}
