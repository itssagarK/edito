import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/vfx/models/radial_zoom_blur_config.dart';
import 'package:edito/features/vfx/services/radial_zoom_blur_compiler_service.dart';
import 'package:edito/features/vfx/models/cyber_hud_config.dart';
import 'package:edito/features/vfx/services/cyber_hud_compiler_service.dart';
import 'package:edito/features/audio/models/binaural_auto_pan_config.dart';
import 'package:edito/features/audio/services/binaural_auto_pan_compiler_service.dart';

void main() {
  group('Phase 26: Anamorphic Radial Zoom Blur Studio Tests', () {
    test('RadialZoomBlurConfig default and inactive state', () {
      const config = RadialZoomBlurConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isActive, isFalse);
      expect(config.blurAmount, equals(0.4));
      expect(config.centerX, equals(0.5));
      expect(config.centerY, equals(0.5));
      expect(config.rotationSpin, equals(0.0));
      expect(config.sampleQuality, equals(6));
      expect(config.isPulsing, isFalse);
    });

    test('RadialZoomBlurConfig presets have valid active configurations', () {
      expect(RadialZoomBlurConfig.presetHyperspace.isActive, isTrue);
      expect(RadialZoomBlurConfig.presetHyperspace.mode, equals(RadialZoomBlurMode.hyperspaceWarp));
      expect(RadialZoomBlurConfig.presetHyperspace.isPulsing, isTrue);

      expect(RadialZoomBlurConfig.presetImpactSlam.isActive, isTrue);
      expect(RadialZoomBlurConfig.presetImpactSlam.mode, equals(RadialZoomBlurMode.actionImpactZoom));

      expect(RadialZoomBlurConfig.presetAnamorphicSpiral.isActive, isTrue);
      expect(RadialZoomBlurConfig.presetAnamorphicSpiral.mode, equals(RadialZoomBlurMode.anamorphicVortex));
      expect(RadialZoomBlurConfig.presetAnamorphicSpiral.rotationSpin, greaterThan(0));

      expect(RadialZoomBlurConfig.presetFocusPunch.isActive, isTrue);
      expect(RadialZoomBlurConfig.presetFocusPunch.mode, equals(RadialZoomBlurMode.subtleFocusPunch));

      expect(RadialZoomBlurConfig.presetDizzyWhirlwind.isActive, isTrue);
      expect(RadialZoomBlurConfig.presetDizzyWhirlwind.mode, equals(RadialZoomBlurMode.dizzySpin));
    });

    test('RadialZoomBlurConfig copyWith and JSON roundtrip', () {
      final original = RadialZoomBlurConfig.presetAnamorphicSpiral.copyWith(
        blurAmount: 0.85,
        centerX: 0.4,
        centerY: 0.6,
        isPulsing: true,
      );
      final json = original.toJson();
      final roundtrip = RadialZoomBlurConfig.fromJson(json);

      expect(roundtrip, equals(original));
      expect(roundtrip.blurAmount, equals(0.85));
      expect(roundtrip.centerX, equals(0.4));
      expect(roundtrip.centerY, equals(0.6));
      expect(roundtrip.isPulsing, isTrue);
    });

    test('RadialZoomBlurCompilerService returns empty string when disabled', () {
      const config = RadialZoomBlurConfig(isEnabled: false);
      expect(RadialZoomBlurCompilerService.compileFilter(config), isEmpty);
      expect(RadialZoomBlurCompilerService.getRadialZoomBlurBadge(config), isEmpty);
    });

    test('RadialZoomBlurCompilerService compiles distinct filtergraphs for each mode', () {
      for (final mode in RadialZoomBlurMode.values) {
        final config = RadialZoomBlurConfig(
          isEnabled: true,
          mode: mode,
          blurAmount: 0.5,
          centerX: 0.5,
          centerY: 0.5,
          rotationSpin: 15.0,
          isPulsing: true,
        );
        final filter = RadialZoomBlurCompilerService.compileFilter(config);
        expect(filter, isNotEmpty);
        expect(filter, contains('boxblur'));
        expect(RadialZoomBlurCompilerService.getRadialZoomBlurBadge(config), contains('RADIAL ZOOM'));
      }
    });
  });

  group('Phase 26: Cyber HUD Hologram Grid Studio Tests', () {
    test('CyberHudConfig default and inactive state', () {
      const config = CyberHudConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isActive, isFalse);
      expect(config.opacity, equals(0.85));
      expect(config.scale, equals(1.0));
      expect(config.scanlines, isTrue);
      expect(config.showTelemetry, isTrue);
    });

    test('CyberHudConfig presets have valid active configurations', () {
      expect(CyberHudConfig.presetHunterLock.isActive, isTrue);
      expect(CyberHudConfig.presetHunterLock.color, equals(CyberHudColor.crimsonCombat));

      expect(CyberHudConfig.presetSonarSweep.isActive, isTrue);
      expect(CyberHudConfig.presetSonarSweep.color, equals(CyberHudColor.neonGreen));

      expect(CyberHudConfig.presetAvionicsHud.isActive, isTrue);
      expect(CyberHudConfig.presetAvionicsHud.color, equals(CyberHudColor.cyanQuantum));

      expect(CyberHudConfig.presetCyberCombat.isActive, isTrue);
      expect(CyberHudConfig.presetCyberCombat.color, equals(CyberHudColor.amberWarning));

      expect(CyberHudConfig.presetQuantumOrbital.isActive, isTrue);
      expect(CyberHudConfig.presetQuantumOrbital.color, equals(CyberHudColor.violetSyndicate));
    });

    test('CyberHudConfig copyWith and JSON roundtrip', () {
      final original = CyberHudConfig.presetSonarSweep.copyWith(
        opacity: 0.95,
        scale: 1.3,
        scanlines: false,
      );
      final json = original.toJson();
      final roundtrip = CyberHudConfig.fromJson(json);

      expect(roundtrip, equals(original));
      expect(roundtrip.opacity, equals(0.95));
      expect(roundtrip.scale, equals(1.3));
      expect(roundtrip.scanlines, isFalse);
    });

    test('CyberHudCompilerService returns empty string when disabled', () {
      const config = CyberHudConfig(isEnabled: false);
      expect(CyberHudCompilerService.compileFilter(config), isEmpty);
      expect(CyberHudCompilerService.getCyberHudBadge(config), isEmpty);
    });

    test('CyberHudCompilerService compiles grid, corner brackets, and bloom', () {
      for (final color in CyberHudColor.values) {
        final config = CyberHudConfig(
          isEnabled: true,
          mode: CyberHudMode.tacticalTargeting,
          color: color,
          opacity: 0.8,
          scanlines: true,
        );
        final filter = CyberHudCompilerService.compileFilter(config);
        expect(filter, isNotEmpty);
        expect(filter, contains('drawgrid'));
        expect(filter, contains('drawbox'));
        expect(filter, contains('unsharp'));
        expect(CyberHudCompilerService.getCyberHudBadge(config), contains('CYBER HUD'));
      }
    });
  });

  group('Phase 26: 3D Binaural Auto-Pan & Doppler Swell Studio Tests', () {
    test('BinauralAutoPanConfig default and inactive state', () {
      const config = BinauralAutoPanConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isActive, isFalse);
      expect(config.rateHz, equals(0.35));
      expect(config.depth, equals(0.85));
      expect(config.dopplerIntensity, equals(0.25));
      expect(config.elevation, equals(0.0));
    });

    test('BinauralAutoPanConfig presets have valid active configurations', () {
      expect(BinauralAutoPanConfig.presetHeadphoneOrbit.isActive, isTrue);
      expect(BinauralAutoPanConfig.presetHeadphoneOrbit.mode, equals(BinauralAutoPanMode.circular3DOrbit));

      expect(BinauralAutoPanConfig.presetMetronomeSwing.isActive, isTrue);
      expect(BinauralAutoPanConfig.presetMetronomeSwing.mode, equals(BinauralAutoPanMode.pendulumSwing));

      expect(BinauralAutoPanConfig.presetJetDopplerPass.isActive, isTrue);
      expect(BinauralAutoPanConfig.presetJetDopplerPass.mode, equals(BinauralAutoPanMode.dopplerFlyby));
      expect(BinauralAutoPanConfig.presetJetDopplerPass.dopplerIntensity, greaterThan(0.5));

      expect(BinauralAutoPanConfig.presetCrazyVortex.isActive, isTrue);
      expect(BinauralAutoPanConfig.presetCrazyVortex.mode, equals(BinauralAutoPanMode.chaoticVortex));

      expect(BinauralAutoPanConfig.presetAmbientSpatial.isActive, isTrue);
      expect(BinauralAutoPanConfig.presetAmbientSpatial.mode, equals(BinauralAutoPanMode.subtleStereoSpread));
    });

    test('BinauralAutoPanConfig copyWith and JSON roundtrip', () {
      final original = BinauralAutoPanConfig.presetJetDopplerPass.copyWith(
        rateHz: 0.8,
        depth: 0.95,
        elevation: 0.4,
      );
      final json = original.toJson();
      final roundtrip = BinauralAutoPanConfig.fromJson(json);

      expect(roundtrip, equals(original));
      expect(roundtrip.rateHz, equals(0.8));
      expect(roundtrip.depth, equals(0.95));
      expect(roundtrip.elevation, equals(0.4));
    });

    test('BinauralAutoPanCompilerService returns empty string when disabled', () {
      const config = BinauralAutoPanConfig(isEnabled: false);
      expect(BinauralAutoPanCompilerService.compileFilter(config), isEmpty);
      expect(const BinauralAutoPanCompilerService().getBadgeLabel(config), isEmpty);
    });

    test('BinauralAutoPanCompilerService strictly enforces AGENTS.md Rule 4 brickwall ceiling limiter', () {
      const rule4Limiter = 'alimiter=limit=0.95:attack=5:release=50:asc=1';

      for (final mode in BinauralAutoPanMode.values) {
        final config = BinauralAutoPanConfig(
          isEnabled: true,
          mode: mode,
          rateHz: 0.5,
          depth: 0.8,
          dopplerIntensity: 0.4,
          elevation: 0.3,
          stereoSpread: 1.4,
        );
        final filter = BinauralAutoPanCompilerService.compileFilter(config);
        expect(filter, isNotEmpty);
        expect(filter, contains('apulsator'));
        expect(filter, contains('vibrato'));
        expect(filter, contains('extrastereo'));
        expect(filter, contains('treble')); // elevation above
        // Strictly verify AGENTS.md Rule 4 true-peak brickwall limiter
        expect(filter, contains(rule4Limiter));
        expect(filter.endsWith(rule4Limiter), isTrue);
      }
    });
  });

  group('Phase 26: Clip Domain Model & FFmpeg Export Pipeline Integration', () {
    test('Clip contains Phase 26 configs with proper defaults', () {
      const clip = Clip(
        id: 'c1',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );
      expect(clip.radialZoomBlur.isEnabled, isFalse);
      expect(clip.cyberHud.isEnabled, isFalse);
      expect(clip.binauralAutoPan.isEnabled, isFalse);
    });

    test('Clip copyWith and JSON roundtrip preserves Phase 26 configurations', () {
      const clip = Clip(
        id: 'c1',
        assetId: 'a1',
        trackId: 't1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );
      final updated = clip.copyWith(
        radialZoomBlur: RadialZoomBlurConfig.presetImpactSlam,
        cyberHud: CyberHudConfig.presetHunterLock,
        binauralAutoPan: BinauralAutoPanConfig.presetHeadphoneOrbit,
      );

      final json = updated.toJson();
      final restored = Clip.fromJson(json);

      expect(restored.radialZoomBlur.isActive, isTrue);
      expect(restored.radialZoomBlur.mode, equals(RadialZoomBlurMode.actionImpactZoom));
      expect(restored.cyberHud.isActive, isTrue);
      expect(restored.cyberHud.color, equals(CyberHudColor.crimsonCombat));
      expect(restored.binauralAutoPan.isActive, isTrue);
      expect(restored.binauralAutoPan.mode, equals(BinauralAutoPanMode.circular3DOrbit));
    });

    test('FFmpegCommandBuilder compiles Phase 26 filters into video and audio pipelines', () {
      const asset = MediaAsset(
        id: 'asset_1',
        path: '/storage/video.mp4',
        fileName: 'video.mp4',
        type: MediaType.video,
        durationMs: 5000,
        hasAudio: true,
      );

      final clip = Clip(
        id: 'clip_1',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        radialZoomBlur: RadialZoomBlurConfig.presetHyperspace,
        cyberHud: CyberHudConfig.presetAvionicsHud,
        binauralAutoPan: BinauralAutoPanConfig.presetJetDopplerPass,
      );

      final track = Track(
        id: 'track_1',
        name: 'Video Track 1',
        type: TrackType.video,
        clips: [clip],
      );

      final project = Project(
        id: 'proj_1',
        title: 'Phase 26 Export Test',
        tracks: [track],
        assets: [asset],
        durationMs: 5000,
      );

      const config = ExportConfiguration(
        preset: ExportPreset.standard1080p,
        framerate: ExportFramerate.fps30,
      );

      final result = FFmpegCommandBuilder.build(project: project, config: config);
      expect(result.command, isNotEmpty);
      // Video filters
      expect(result.command, contains('boxblur'));
      expect(result.command, contains('drawgrid'));
      // Audio filters with Rule 4 limiter
      expect(result.command, contains('apulsator'));
      expect(result.command, contains('vibrato'));
      expect(result.command, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
    });
  });
}
