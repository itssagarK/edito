import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/vfx/models/camera_shake_config.dart';
import 'package:edito/features/vfx/services/camera_shake_compiler_service.dart';
import 'package:edito/features/vfx/models/lens_distortion_config.dart';
import 'package:edito/features/vfx/services/lens_distortion_compiler_service.dart';
import 'package:edito/features/audio/models/vinyl_record_config.dart';
import 'package:edito/features/audio/services/vinyl_record_compiler_service.dart';

void main() {
  group('Phase 18: Feature 18.1 - Organic Handheld Camera Shake & Tremor Studio', () {
    test('CameraShakeConfig default values and presets', () {
      const config = CameraShakeConfig();
      expect(config.isEnabled, isFalse);
      expect(config.intensity, equals(0.40));
      expect(config.speed, equals(1.0));
      expect(config.rotationShake, equals(0.25));
      expect(config.shakeType, equals(CameraShakeType.handheld));
      expect(config.motionBlur, isTrue);

      expect(CameraShakeConfig.gentleHandheld.shakeType, equals(CameraShakeType.handheld));
      expect(CameraShakeConfig.gentleHandheld.intensity, equals(0.30));
      expect(CameraShakeConfig.actionCamTremor.speed, equals(1.40));
      expect(CameraShakeConfig.earthquakeShock.shakeType, equals(CameraShakeType.earthquake));
      expect(CameraShakeConfig.earthquakeShock.intensity, equals(0.90));
      expect(CameraShakeConfig.carOffroad.shakeType, equals(CameraShakeType.carBumpy));
      expect(CameraShakeConfig.impactThud.shakeType, equals(CameraShakeType.impactTremor));
    });

    test('CameraShakeConfig copyWith and immutability', () {
      const config = CameraShakeConfig();
      final updated = config.copyWith(
        isEnabled: true,
        intensity: 0.85,
        speed: 2.2,
        shakeType: CameraShakeType.earthquake,
      );

      expect(updated.isEnabled, isTrue);
      expect(updated.intensity, equals(0.85));
      expect(updated.speed, equals(2.2));
      expect(updated.shakeType, equals(CameraShakeType.earthquake));
      expect(updated.rotationShake, equals(0.25)); // Unchanged
    });

    test('CameraShakeConfig JSON round-trip serialization', () {
      const config = CameraShakeConfig(
        isEnabled: true,
        intensity: 0.72,
        speed: 1.5,
        rotationShake: 0.40,
        shakeType: CameraShakeType.carBumpy,
        motionBlur: false,
      );

      final json = config.toJson();
      final restored = CameraShakeConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.intensity, equals(0.72));
      expect(restored.speed, equals(1.5));
      expect(restored.rotationShake, equals(0.40));
      expect(restored.shakeType, equals(CameraShakeType.carBumpy));
      expect(restored.motionBlur, isFalse);
      expect(restored, equals(config));
    });

    test('CameraShakeCompilerService compiles crop-jitter filters and HUD badge', () {
      const disabledConfig = CameraShakeConfig();
      expect(CameraShakeCompilerService.compileFilter(disabledConfig), isNull);
      expect(CameraShakeCompilerService.generateFFmpegFilters(disabledConfig), isEmpty);

      const enabledConfig = CameraShakeConfig(
        isEnabled: true,
        intensity: 0.75,
        speed: 1.2,
        shakeType: CameraShakeType.handheld,
      );

      final filter = CameraShakeCompilerService.compileFilter(enabledConfig);
      expect(filter, isNotNull);
      expect(filter, contains('crop=w='));
      expect(filter, contains('scale=in_w:in_h'));

      final filterList = CameraShakeCompilerService.generateFFmpegFilters(enabledConfig);
      expect(filterList, isNotEmpty);
      expect(filterList.first, contains('crop=w='));

      final hudBadge = CameraShakeCompilerService.getHudBadge(enabledConfig);
      expect(hudBadge, contains('Organic Handheld'));
      expect(hudBadge, contains('75%'));
    });
  });

  group('Phase 18: Feature 18.2 - Lens Distortion & Fisheye Studio', () {
    test('LensDistortionConfig default values and presets', () {
      const config = LensDistortionConfig();
      expect(config.isEnabled, isFalse);
      expect(config.distortion, equals(0.35));
      expect(config.chromaticAberration, equals(0.20));
      expect(config.vignetteFalloff, equals(0.30));
      expect(config.profile, equals(LensDistortionProfile.fisheyeActionCam));

      expect(LensDistortionConfig.actionGoPro.distortion, equals(0.55));
      expect(LensDistortionConfig.skateVideoFisheye.distortion, equals(0.85));
      expect(LensDistortionConfig.cinemaAnamorphic.profile, equals(LensDistortionProfile.anamorphicBarrel));
      expect(LensDistortionConfig.telephotoPincushion.distortion, equals(-0.40));
      expect(LensDistortionConfig.securityCCTV.profile, equals(LensDistortionProfile.retroSpyglass));
    });

    test('LensDistortionConfig copyWith and immutability', () {
      const config = LensDistortionConfig();
      final updated = config.copyWith(
        isEnabled: true,
        distortion: 0.70,
        chromaticAberration: 0.45,
        profile: LensDistortionProfile.retroSpyglass,
      );

      expect(updated.isEnabled, isTrue);
      expect(updated.distortion, equals(0.70));
      expect(updated.chromaticAberration, equals(0.45));
      expect(updated.profile, equals(LensDistortionProfile.retroSpyglass));
      expect(updated.vignetteFalloff, equals(0.30)); // Unchanged
    });

    test('LensDistortionConfig JSON round-trip serialization', () {
      const config = LensDistortionConfig(
        isEnabled: true,
        distortion: -0.35,
        chromaticAberration: 0.15,
        vignetteFalloff: 0.25,
        profile: LensDistortionProfile.pincushionZoom,
      );

      final json = config.toJson();
      final restored = LensDistortionConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.distortion, equals(-0.35));
      expect(restored.chromaticAberration, equals(0.15));
      expect(restored.vignetteFalloff, equals(0.25));
      expect(restored.profile, equals(LensDistortionProfile.pincushionZoom));
      expect(restored, equals(config));
    });

    test('LensDistortionCompilerService compiles lenscorrection and vignette filters', () {
      const disabledConfig = LensDistortionConfig();
      expect(LensDistortionCompilerService.compileFilter(disabledConfig), isNull);
      expect(LensDistortionCompilerService.generateFFmpegFilters(disabledConfig), isEmpty);

      const enabledConfig = LensDistortionConfig(
        isEnabled: true,
        distortion: 0.60,
        chromaticAberration: 0.30,
        vignetteFalloff: 0.40,
        profile: LensDistortionProfile.fisheyeActionCam,
      );

      final filter = LensDistortionCompilerService.compileFilter(enabledConfig);
      expect(filter, isNotNull);
      expect(filter, contains('lenscorrection'));
      expect(filter, contains('colorchannelmixer'));
      expect(filter, contains('vignette'));

      final filterList = LensDistortionCompilerService.generateFFmpegFilters(enabledConfig);
      expect(filterList, isNotEmpty);

      final hudBadge = LensDistortionCompilerService.getHudBadge(enabledConfig);
      expect(hudBadge, contains('Action Cam Fisheye'));
      expect(hudBadge, contains('+60%'));
    });
  });

  group('Phase 18: Feature 18.3 - Vintage Vinyl Turntable Studio', () {
    test('VinylRecordConfig default values and presets', () {
      const config = VinylRecordConfig();
      expect(config.isEnabled, isFalse);
      expect(config.rpm, equals(VinylRpm.rpm33));
      expect(config.dustCrackle, equals(0.50));
      expect(config.surfaceNoise, equals(0.35));
      expect(config.needleWearTone, equals(0.40));
      expect(config.needleDropCue, isTrue);

      expect(VinylRecordConfig.classicLp33.rpm, equals(VinylRpm.rpm33));
      expect(VinylRecordConfig.vintageSingle45.rpm, equals(VinylRpm.rpm45));
      expect(VinylRecordConfig.antiqueGramophone78.rpm, equals(VinylRpm.rpm78));
      expect(VinylRecordConfig.antiqueGramophone78.dustCrackle, equals(0.85));
      expect(VinylRecordConfig.lofiWarmBeats.needleDropCue, isFalse);
    });

    test('VinylRecordConfig copyWith and immutability', () {
      const config = VinylRecordConfig();
      final updated = config.copyWith(
        isEnabled: true,
        rpm: VinylRpm.rpm45,
        dustCrackle: 0.70,
        needleWearTone: 0.60,
      );

      expect(updated.isEnabled, isTrue);
      expect(updated.rpm, equals(VinylRpm.rpm45));
      expect(updated.dustCrackle, equals(0.70));
      expect(updated.needleWearTone, equals(0.60));
      expect(updated.surfaceNoise, equals(0.35)); // Unchanged
    });

    test('VinylRecordConfig JSON round-trip serialization', () {
      const config = VinylRecordConfig(
        isEnabled: true,
        rpm: VinylRpm.rpm78,
        dustCrackle: 0.88,
        surfaceNoise: 0.65,
        needleWearTone: 0.75,
        needleDropCue: true,
      );

      final json = config.toJson();
      final restored = VinylRecordConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.rpm, equals(VinylRpm.rpm78));
      expect(restored.dustCrackle, equals(0.88));
      expect(restored.surfaceNoise, equals(0.65));
      expect(restored.needleWearTone, equals(0.75));
      expect(restored.needleDropCue, isTrue);
      expect(restored, equals(config));
    });

    test('VinylRecordCompilerService compiles RIAA warmth and strictly enforces brickwall limiter', () {
      const disabledConfig = VinylRecordConfig();
      expect(VinylRecordCompilerService.compileFilters(disabledConfig), isEmpty);
      expect(VinylRecordCompilerService.generateFFmpegFilters(disabledConfig), isEmpty);

      const enabledConfig = VinylRecordConfig(
        isEnabled: true,
        rpm: VinylRpm.rpm33,
        dustCrackle: 0.50,
        needleWearTone: 0.50,
      );

      final filters = VinylRecordCompilerService.compileFilters(enabledConfig);
      expect(filters, isNotEmpty);

      final filterString = filters.join(',');
      expect(filterString, contains('highpass'));
      expect(filterString, contains('equalizer'));
      expect(filterString, contains('lowpass'));
      expect(filterString, contains('vibrato'));

      // CRITICAL: Strictly verify AGENTS.md Rule 4 True-Peak Brickwall Limiter
      expect(
        filterString,
        contains('alimiter=limit=0.95:attack=5:release=50:asc=1'),
        reason: 'AGENTS.md Rule 4 requires true-peak brickwall ceiling alimiter=limit=0.95:attack=5:release=50:asc=1',
      );

      final hudBadge = VinylRecordCompilerService.getHudBadge(enabledConfig);
      expect(hudBadge, contains('33⅓ RPM'));
      expect(hudBadge, contains('Dust 50%'));
    });
  });

  group('Clip Model Integration', () {
    test('Clip includes cameraShake, lensDistortion, vinylRecord defaults', () {
      const clip = Clip(
        id: 'clip_p18_test',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      expect(clip.cameraShake.isEnabled, isFalse);
      expect(clip.lensDistortion.isEnabled, isFalse);
      expect(clip.vinylRecord.isEnabled, isFalse);
    });

    test('Clip copyWith preserves and updates Phase 18 configs', () {
      const clip = Clip(
        id: 'clip_p18_test',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      final updated = clip.copyWith(
        cameraShake: const CameraShakeConfig(isEnabled: true, intensity: 0.80),
        lensDistortion: const LensDistortionConfig(isEnabled: true, distortion: 0.50),
        vinylRecord: const VinylRecordConfig(isEnabled: true, dustCrackle: 0.60),
      );

      expect(updated.cameraShake.isEnabled, isTrue);
      expect(updated.cameraShake.intensity, equals(0.80));
      expect(updated.lensDistortion.isEnabled, isTrue);
      expect(updated.lensDistortion.distortion, equals(0.50));
      expect(updated.vinylRecord.isEnabled, isTrue);
      expect(updated.vinylRecord.dustCrackle, equals(0.60));
    });

    test('Clip serialization roundtrip retains Phase 18 fields', () {
      const clip = Clip(
        id: 'clip_p18_json_test',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        cameraShake: CameraShakeConfig(
          isEnabled: true,
          shakeType: CameraShakeType.impactTremor,
          intensity: 0.85,
        ),
        lensDistortion: LensDistortionConfig(
          isEnabled: true,
          profile: LensDistortionProfile.retroSpyglass,
          distortion: 0.70,
        ),
        vinylRecord: VinylRecordConfig(
          isEnabled: true,
          rpm: VinylRpm.rpm45,
          dustCrackle: 0.65,
        ),
      );

      final json = clip.toJson();
      final restored = Clip.fromJson(json);

      expect(restored.cameraShake.isEnabled, isTrue);
      expect(restored.cameraShake.shakeType, equals(CameraShakeType.impactTremor));
      expect(restored.cameraShake.intensity, equals(0.85));

      expect(restored.lensDistortion.isEnabled, isTrue);
      expect(restored.lensDistortion.profile, equals(LensDistortionProfile.retroSpyglass));
      expect(restored.lensDistortion.distortion, equals(0.70));

      expect(restored.vinylRecord.isEnabled, isTrue);
      expect(restored.vinylRecord.rpm, equals(VinylRpm.rpm45));
      expect(restored.vinylRecord.dustCrackle, equals(0.65));
    });
  });
}
