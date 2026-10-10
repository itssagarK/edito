import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/vfx/models/water_caustics_config.dart';
import 'package:edito/features/vfx/services/water_caustics_compiler_service.dart';
import 'package:edito/features/vfx/models/diamond_prism_config.dart';
import 'package:edito/features/vfx/services/diamond_prism_compiler_service.dart';
import 'package:edito/features/audio/models/multiband_compressor_config.dart';
import 'package:edito/features/audio/services/multiband_compressor_compiler_service.dart';

void main() {
  group('Phase 27: Liquid Water Caustics Studio Tests', () {
    test('WaterCausticsConfig default and inactive state', () {
      const config = WaterCausticsConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isActive, isFalse);
      expect(config.intensity, equals(0.6));
      expect(config.scale, equals(1.2));
      expect(config.speed, equals(1.0));
      expect(config.refractionWarp, equals(0.4));
      expect(config.chromaticDispersion, equals(0.35));
      expect(config.tintDepth, equals(0.45));
    });

    test('WaterCausticsConfig presets have valid active configurations', () {
      expect(WaterCausticsConfig.presetTropicalLagoon.isActive, isTrue);
      expect(WaterCausticsConfig.presetTropicalLagoon.mode, equals(WaterCausticsMode.tropicalPool));

      expect(WaterCausticsConfig.presetAbyssalTrench.isActive, isTrue);
      expect(WaterCausticsConfig.presetAbyssalTrench.mode, equals(WaterCausticsMode.abyssalDeep));

      expect(WaterCausticsConfig.presetEmeraldCenote.isActive, isTrue);
      expect(WaterCausticsConfig.presetEmeraldCenote.mode, equals(WaterCausticsMode.emeraldLagoon));

      expect(WaterCausticsConfig.presetBioluminescentNight.isActive, isTrue);
      expect(WaterCausticsConfig.presetBioluminescentNight.mode, equals(WaterCausticsMode.bioluminescentReef));

      expect(WaterCausticsConfig.presetSunkenGoldSandbar.isActive, isTrue);
      expect(WaterCausticsConfig.presetSunkenGoldSandbar.mode, equals(WaterCausticsMode.sunkenGold));
    });

    test('WaterCausticsConfig copyWith and JSON roundtrip', () {
      final original = WaterCausticsConfig.presetTropicalLagoon.copyWith(
        intensity: 0.85,
        scale: 1.5,
        speed: 2.0,
      );
      final json = original.toJson();
      final roundtrip = WaterCausticsConfig.fromJson(json);

      expect(roundtrip, equals(original));
      expect(roundtrip.intensity, equals(0.85));
      expect(roundtrip.scale, equals(1.5));
      expect(roundtrip.speed, equals(2.0));
    });

    test('WaterCausticsCompilerService generates valid filter and handles disabled', () {
      const compiler = WaterCausticsCompilerService();
      expect(compiler.compile(const WaterCausticsConfig()), isEmpty);

      final filter = compiler.compile(WaterCausticsConfig.presetTropicalLagoon);
      expect(filter, contains('colorbalance'));
      expect(filter, contains('curves'));
      expect(filter, contains('unsharp'));
    });
  });

  group('Phase 27: Diamond Glass Prism Studio Tests', () {
    test('DiamondPrismConfig default and inactive state', () {
      const config = DiamondPrismConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isActive, isFalse);
      expect(config.facetCount, equals(8));
      expect(config.dispersionStrength, equals(0.65));
      expect(config.refractionAngle, equals(45.0));
      expect(config.innerReflectionIntensity, equals(0.5));
      expect(config.spectralSaturation, equals(1.3));
      expect(config.isRotating, isFalse);
    });

    test('DiamondPrismConfig presets have valid active configurations', () {
      expect(DiamondPrismConfig.presetBrilliantDiamond.isActive, isTrue);
      expect(DiamondPrismConfig.presetBrilliantDiamond.mode, equals(DiamondPrismMode.brilliantCut));
      expect(DiamondPrismConfig.presetBrilliantDiamond.facetCount, equals(8));
      expect(DiamondPrismConfig.presetBrilliantDiamond.isRotating, isTrue);

      expect(DiamondPrismConfig.presetNewtonPrism.isActive, isTrue);
      expect(DiamondPrismConfig.presetNewtonPrism.mode, equals(DiamondPrismMode.triangularPrism));

      expect(DiamondPrismConfig.presetEmeraldChamber.isActive, isTrue);
      expect(DiamondPrismConfig.presetEmeraldChamber.mode, equals(DiamondPrismMode.emeraldFacet));

      expect(DiamondPrismConfig.presetCosmicCrystal.isActive, isTrue);
      expect(DiamondPrismConfig.presetCosmicCrystal.mode, equals(DiamondPrismMode.kaleidoCrystal));

      expect(DiamondPrismConfig.presetSpectralHeartBurst.isActive, isTrue);
      expect(DiamondPrismConfig.presetSpectralHeartBurst.mode, equals(DiamondPrismMode.spectralHeart));
    });

    test('DiamondPrismConfig copyWith and JSON roundtrip', () {
      final original = DiamondPrismConfig.presetBrilliantDiamond.copyWith(
        dispersionStrength: 0.9,
        facetCount: 12,
        isRotating: false,
      );
      final json = original.toJson();
      final roundtrip = DiamondPrismConfig.fromJson(json);

      expect(roundtrip, equals(original));
      expect(roundtrip.dispersionStrength, equals(0.9));
      expect(roundtrip.facetCount, equals(12));
      expect(roundtrip.isRotating, isFalse);
    });

    test('DiamondPrismCompilerService generates valid filter with chromatic shift and eq', () {
      const compiler = DiamondPrismCompilerService();
      expect(compiler.compile(const DiamondPrismConfig()), isEmpty);

      final filter = compiler.compile(DiamondPrismConfig.presetBrilliantDiamond);
      expect(filter, contains('rgbashift'));
      expect(filter, contains('eq'));
      expect(filter, contains('unsharp'));
      expect(filter, contains('vignette'));
    });
  });

  group('Phase 27: Multiband Mastering Compressor Studio Tests', () {
    test('MultibandCompressorConfig default and inactive state', () {
      const config = MultibandCompressorConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isActive, isFalse);
      expect(config.lowThresholdDb, equals(-18.0));
      expect(config.lowRatio, equals(3.0));
      expect(config.midThresholdDb, equals(-20.0));
      expect(config.midRatio, equals(2.5));
      expect(config.highThresholdDb, equals(-24.0));
      expect(config.highRatio, equals(3.5));
      expect(config.crossoverLowHz, equals(250.0));
      expect(config.crossoverHighHz, equals(4000.0));
    });

    test('MultibandCompressorConfig presets have valid active configurations', () {
      expect(MultibandCompressorConfig.presetTransparentMaster.isActive, isTrue);
      expect(MultibandCompressorConfig.presetTransparentMaster.mode, equals(MultibandCompressorMode.transparentMaster));

      expect(MultibandCompressorConfig.presetClub808Punch.isActive, isTrue);
      expect(MultibandCompressorConfig.presetClub808Punch.mode, equals(MultibandCompressorMode.punchyClub808));

      expect(MultibandCompressorConfig.presetVocalBroadcastRadio.isActive, isTrue);
      expect(MultibandCompressorConfig.presetVocalBroadcastRadio.mode, equals(MultibandCompressorMode.vocalPresenceRadio));

      expect(MultibandCompressorConfig.presetWarmTapeGlue.isActive, isTrue);
      expect(MultibandCompressorConfig.presetWarmTapeGlue.mode, equals(MultibandCompressorMode.warmTapeSaturate));

      expect(MultibandCompressorConfig.presetHeavyMasterGlue.isActive, isTrue);
      expect(MultibandCompressorConfig.presetHeavyMasterGlue.mode, equals(MultibandCompressorMode.heavyGlueMix));
    });

    test('MultibandCompressorConfig copyWith and JSON roundtrip', () {
      final original = MultibandCompressorConfig.presetClub808Punch.copyWith(
        lowGainDb: 4.0,
        highRatio: 5.0,
        crossoverLowHz: 180.0,
      );
      final json = original.toJson();
      final roundtrip = MultibandCompressorConfig.fromJson(json);

      expect(roundtrip, equals(original));
      expect(roundtrip.lowGainDb, equals(4.0));
      expect(roundtrip.highRatio, equals(5.0));
      expect(roundtrip.crossoverLowHz, equals(180.0));
    });

    test('MultibandCompressorCompilerService strictly enforces Rule 4 brickwall ceiling limiter', () {
      const compiler = MultibandCompressorCompilerService();
      expect(compiler.compile(const MultibandCompressorConfig()), isEmpty);

      final filter = compiler.compile(MultibandCompressorConfig.presetClub808Punch);
      expect(filter, contains('bass='));
      expect(filter, contains('equalizer='));
      expect(filter, contains('treble='));
      expect(filter, contains('acompressor='));
      // AGENTS.md Rule 4 true-peak brickwall ceiling limiter
      expect(filter, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
    });
  });

  group('Phase 27: Clip Domain Model Integration & Export Parity Tests', () {
    test('Clip domain model initializes with Phase 27 configs and supports copyWith', () {
      final clip = Clip(
        id: 'clip_phase_27',
        assetId: 'asset_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      expect(clip.waterCaustics.isEnabled, isFalse);
      expect(clip.diamondPrism.isEnabled, isFalse);
      expect(clip.multibandCompressor.isEnabled, isFalse);

      final updated = clip.copyWith(
        waterCaustics: WaterCausticsConfig.presetTropicalLagoon,
        diamondPrism: DiamondPrismConfig.presetBrilliantDiamond,
        multibandCompressor: MultibandCompressorConfig.presetClub808Punch,
      );

      expect(updated.waterCaustics.isActive, isTrue);
      expect(updated.diamondPrism.isActive, isTrue);
      expect(updated.multibandCompressor.isActive, isTrue);
    });

    test('Clip serialization roundtrip preserves Phase 27 configurations', () {
      final clip = Clip(
        id: 'clip_phase_27_json',
        assetId: 'asset_test',
        startTimeMs: 1000,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        waterCaustics: WaterCausticsConfig.presetBioluminescentNight,
        diamondPrism: DiamondPrismConfig.presetNewtonPrism,
        multibandCompressor: MultibandCompressorConfig.presetHeavyMasterGlue,
      );

      final json = clip.toJson();
      final restored = Clip.fromJson(json);

      expect(restored.waterCaustics, equals(WaterCausticsConfig.presetBioluminescentNight));
      expect(restored.diamondPrism, equals(DiamondPrismConfig.presetNewtonPrism));
      expect(restored.multibandCompressor, equals(MultibandCompressorConfig.presetHeavyMasterGlue));
    });

    test('FFmpegCommandBuilder compiles video and audio filtergraphs with Phase 27 tools', () {
      const preset = ExportPreset(
        name: '1080p',
        width: 1920,
        height: 1080,
        fps: 30,
        videoBitrateKbps: 8000,
        audioBitrateKbps: 192,
      );

      final clip = Clip(
        id: 'c1',
        assetId: 'a1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        waterCaustics: WaterCausticsConfig.presetTropicalLagoon,
        diamondPrism: DiamondPrismConfig.presetBrilliantDiamond,
        multibandCompressor: MultibandCompressorConfig.presetTransparentMaster,
      );

      final project = Project(
        id: 'p1',
        title: 'Phase 27 Export Test',
        width: 1920,
        height: 1080,
        fps: 30,
        assets: const [
          MediaAsset(
            id: 'a1',
            path: '/path/to/test.mp4',
            type: MediaType.video,
            durationMs: 5000,
            width: 1920,
            height: 1080,
          ),
        ],
        tracks: [
          Track(
            id: 't1',
            type: TrackType.video,
            clips: [clip],
          ),
        ],
      );

      final args = FFmpegCommandBuilder.buildArguments(
        project: project,
        outputPath: '/path/to/output.mp4',
        preset: preset,
      );

      final filterComplexArg = args.join(' ');
      // Verify video filtergraph contains Water Caustics & Diamond Prism
      expect(filterComplexArg, contains('colorbalance'));
      expect(filterComplexArg, contains('rgbashift'));
      // Verify audio filtergraph contains Multiband Compressor & mandatory Rule 4 limiter
      expect(filterComplexArg, contains('acompressor='));
      expect(filterComplexArg, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
    });
  });
}
