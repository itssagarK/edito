import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/vfx/models/vfx_config.dart';
import 'package:edito/features/vfx/services/vfx_compiler_service.dart';
import 'package:edito/features/export/models/export_config.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';

void main() {
  group('VfxConfig Model Tests', () {
    test('Default VfxConfig is inactive and has proper initial values', () {
      const config = VfxConfig();
      expect(config.type, VfxType.none);
      expect(config.intensity, 0.50);
      expect(config.grainSize, 2.0);
      expect(config.rgbOffset, 8.0);
      expect(config.blurRadius, 8.0);
      expect(config.vignetteRadius, 0.55);
      expect(config.shakeAmplitude, 10.0);
      expect(config.isActive, false);
    });

    test('VfxConfig serialization and deserialization retains all fields', () {
      const original = VfxConfig(
        type: VfxType.rgbGlitch,
        intensity: 0.75,
        speed: 1.5,
        grainSize: 3.0,
        rgbOffset: 14.0,
        blurRadius: 12.0,
        vignetteRadius: 0.60,
        vignetteSoftness: 0.50,
        shakeAmplitude: 16.0,
        colorWarmth: 0.25,
      );

      final json = original.toJson();
      final deserialized = VfxConfig.fromJson(json);

      expect(deserialized.type, VfxType.rgbGlitch);
      expect(deserialized.intensity, 0.75);
      expect(deserialized.speed, 1.5);
      expect(deserialized.grainSize, 3.0);
      expect(deserialized.rgbOffset, 14.0);
      expect(deserialized.blurRadius, 12.0);
      expect(deserialized.vignetteRadius, 0.60);
      expect(deserialized.vignetteSoftness, 0.50);
      expect(deserialized.shakeAmplitude, 16.0);
      expect(deserialized.colorWarmth, 0.25);
      expect(deserialized.isActive, true);
      expect(deserialized, equals(original));
    });
  });

  group('VfxCompilerService Tests', () {
    test('Inactive VFX returns empty filter list and empty HUD badge', () {
      const config = VfxConfig(type: VfxType.none);
      expect(VfxCompilerService.generateFFmpegFilters(config), isEmpty);
      expect(VfxCompilerService.getVfxBadge(config), '');
    });

    test('Film grain generates temporal uniform noise filter', () {
      const config = VfxConfig(type: VfxType.filmGrain, intensity: 0.50);
      final filters = VfxCompilerService.generateFFmpegFilters(config);
      expect(filters.length, 1);
      expect(filters[0], contains('noise=alls=20:allf=t+u'));
      expect(VfxCompilerService.getVfxBadge(config), contains('FILM GRAIN (50%)'));
    });

    test('RGB Glitch generates native rgbashift chromatic aberration', () {
      const config = VfxConfig(type: VfxType.rgbGlitch, intensity: 0.80, rgbOffset: 10.0);
      final filters = VfxCompilerService.generateFFmpegFilters(config);
      expect(filters.length, 1);
      expect(filters[0], contains('rgbashift=rh=8:bh=-8'));
      expect(VfxCompilerService.getVfxBadge(config), contains('RGB GLITCH (8px)'));
    });

    test('Lens Blur generates optical Gaussian gblur filter', () {
      const config = VfxConfig(type: VfxType.lensBlur, intensity: 0.50, blurRadius: 10.0);
      final filters = VfxCompilerService.generateFFmpegFilters(config);
      expect(filters.length, 1);
      expect(filters[0], contains('gblur=sigma=5.0:steps=2'));
      expect(VfxCompilerService.getVfxBadge(config), contains('LENS BLUR (5px)'));
    });

    test('Retro VHS generates curves, noise, and vignette', () {
      const config = VfxConfig(type: VfxType.vhsVintage, intensity: 0.70);
      final filters = VfxCompilerService.generateFFmpegFilters(config);
      expect(filters.length, 3);
      expect(filters[0], contains('curves=all='));
      expect(filters[1], contains('noise=alls=15:allf=t'));
      expect(filters[2], contains('vignette=PI/4'));
      expect(VfxCompilerService.getVfxBadge(config), contains('RETRO VHS'));
    });

    test('Vignette generates optical falloff angle', () {
      const config = VfxConfig(type: VfxType.vignette, intensity: 0.60, vignetteRadius: 0.50);
      final filters = VfxCompilerService.generateFFmpegFilters(config);
      expect(filters.length, 1);
      expect(filters[0], contains('vignette=angle=0.48'));
      expect(VfxCompilerService.getVfxBadge(config), contains('VIGNETTE (60%)'));
    });

    test('Light Leak generates warm colorchannelmixer and bloom curves', () {
      const config = VfxConfig(type: VfxType.lightLeak, intensity: 0.50);
      final filters = VfxCompilerService.generateFFmpegFilters(config);
      expect(filters.length, 2);
      expect(filters[0], contains('colorchannelmixer='));
      expect(filters[1], contains("curves=r='0/0.06 1/1'"));
      expect(VfxCompilerService.getVfxBadge(config), contains('LIGHT LEAK'));
    });

    test('Camera Shake generates sinusoidal motion crop and resize', () {
      const config = VfxConfig(type: VfxType.cameraShake, intensity: 0.60, shakeAmplitude: 20.0);
      final filters = VfxCompilerService.generateFFmpegFilters(config);
      expect(filters.length, 1);
      expect(filters[0], contains('crop=w=iw-12:h=ih-12'));
      expect(filters[0], contains('sin(n*1.8)*6'));
      expect(filters[0], contains('scale=iw+12:ih+12'));
      expect(VfxCompilerService.getVfxBadge(config), contains('CAMERA SHAKE'));
    });

    test('Radial Zoom generates scale, crop, and gblur', () {
      const config = VfxConfig(type: VfxType.radialZoom, intensity: 0.50, blurRadius: 10.0);
      final filters = VfxCompilerService.generateFFmpegFilters(config);
      expect(filters.length, 2);
      expect(filters[0], contains('scale=iw*1.05:ih*1.05,crop=iw/1.05:ih/1.05'));
      expect(filters[1], contains('gblur=sigma=2.0:steps=1'));
      expect(VfxCompilerService.getVfxBadge(config), contains('RADIAL ZOOM'));
    });
  });

  group('FFmpeg Export VFX Pipeline Integration', () {
    test('Builds export command with active VFX filterchain', () {
      const asset = MediaAsset(
        id: 'asset-vfx',
        path: '/storage/cinematic.mp4',
        fileName: 'cinematic.mp4',
        type: MediaType.video,
        durationMs: 5000,
        hasAudio: true,
      );

      const vfxClip = Clip(
        id: 'clip-vfx',
        assetId: 'asset-vfx',
        trackId: 't-vfx',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        vfx: VfxConfig(
          type: VfxType.rgbGlitch,
          intensity: 0.70,
          rgbOffset: 12.0,
        ),
      );

      const track = Track(
        id: 't-vfx',
        name: 'VFX Track',
        type: TrackType.video,
        clips: [vfxClip],
      );

      final project = Project(
        id: 'p-vfx',
        name: 'VFX Export Test',
        durationMs: 5000,
        tracks: [track],
        assets: [asset],
      );

      final cmd = FFmpegCommandBuilder.build(
        project: project,
        config: const ExportConfig(),
        outputPath: '/storage/vfx_out.mp4',
      );

      expect(cmd.command.contains('rgbashift=rh=8:bh=-8'), isTrue);
    });
  });
}
