import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/image_editor/models/video_layout_config.dart';
import 'package:edito/features/image_editor/services/auto_reframe_service.dart';
import 'package:edito/features/preview/models/aspect_ratio_preset.dart';
import 'package:edito/features/export/models/export_config.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';

void main() {
  group('VideoLayoutConfig & Aspect Ratio Model Tests', () {
    test('Default VideoLayoutConfig has proper initial values', () {
      const config = VideoLayoutConfig();
      expect(config.ratio, VideoLayoutRatio.ratio16_9);
      expect(config.reframeMode, AutoReframeMode.fitWithBlur);
      expect(config.blurIntensity, 22.0);
      expect(config.framePadding, 0.0);
      expect(config.cornerRadius, 0.0);
      expect(config.focalPointX, 0.0);
      expect(config.focalPointY, 0.0);
      expect(config.isBlurFill, true);
      expect(config.isSmartCrop, false);
    });

    test('VideoLayoutConfig serialization and deserialization retains all fields', () {
      const original = VideoLayoutConfig(
        ratio: VideoLayoutRatio.ratio9_16,
        reframeMode: AutoReframeMode.smartCrop,
        backgroundMode: LayoutBackgroundMode.solidColor,
        fillMode: LayoutFillMode.fill,
        backgroundColor: 0xFF141A29,
        gradientPreset: GradientCanvasPreset.cyberpunk,
        framePadding: 8.0,
        cornerRadius: 12.0,
        blurIntensity: 30.0,
        focalPointX: 0.35,
        focalPointY: -0.15,
      );

      final json = original.toJson();
      final deserialized = VideoLayoutConfig.fromJson(json);

      expect(deserialized.ratio, VideoLayoutRatio.ratio9_16);
      expect(deserialized.reframeMode, AutoReframeMode.smartCrop);
      expect(deserialized.backgroundColor, 0xFF141A29);
      expect(deserialized.gradientPreset, GradientCanvasPreset.cyberpunk);
      expect(deserialized.framePadding, 8.0);
      expect(deserialized.cornerRadius, 12.0);
      expect(deserialized.blurIntensity, 30.0);
      expect(deserialized.focalPointX, 0.35);
      expect(deserialized.focalPointY, -0.15);
      expect(deserialized.isSmartCrop, true);
      expect(deserialized, equals(original));
    });

    test('VideoLayoutConfig legacy JSON fallback resolves appropriate reframeMode', () {
      final legacyFillJson = {
        'ratio': 'ratio9_16',
        'fillMode': 'fill',
        'backgroundMode': 'solidColor',
      };
      final resolvedFill = VideoLayoutConfig.fromJson(legacyFillJson);
      expect(resolvedFill.reframeMode, AutoReframeMode.smartCrop);

      final legacySolidJson = {
        'ratio': 'ratio1_1',
        'fillMode': 'fit',
        'backgroundMode': 'solidColor',
      };
      final resolvedSolid = VideoLayoutConfig.fromJson(legacySolidJson);
      expect(resolvedSolid.reframeMode, AutoReframeMode.solidPillarbox);
    });

    test('All VideoLayoutRatio and AspectRatioPreset definitions maintain exact math ratios', () {
      expect(VideoLayoutRatio.ratio16_9.aspectRatio, closeTo(16.0 / 9.0, 0.001));
      expect(VideoLayoutRatio.ratio9_16.aspectRatio, closeTo(9.0 / 16.0, 0.001));
      expect(VideoLayoutRatio.ratio1_1.aspectRatio, 1.0);
      expect(VideoLayoutRatio.ratio4_5.aspectRatio, 0.8);
      expect(VideoLayoutRatio.ratio4_3.aspectRatio, closeTo(4.0 / 3.0, 0.001));
      expect(VideoLayoutRatio.ratio3_4.aspectRatio, 0.75);
      expect(VideoLayoutRatio.ratio21_9.aspectRatio, closeTo(21.0 / 9.0, 0.001));
      expect(VideoLayoutRatio.ratio239_1.aspectRatio, 2.39);

      expect(AspectRatioPreset.ratio4x3.standardWidth, 1440);
      expect(AspectRatioPreset.ratio4x3.standardHeight, 1080);
      expect(AspectRatioPreset.ratio239x1.standardWidth, 2560);
      expect(AspectRatioPreset.ratio239x1.standardHeight, 1072);
    });
  });

  group('AutoReframeService Tests', () {
    test('Fit with blur generates split filter with background gblur and centered overlay', () {
      const layout = VideoLayoutConfig(
        ratio: VideoLayoutRatio.ratio9_16,
        reframeMode: AutoReframeMode.fitWithBlur,
        blurIntensity: 25.0,
      );

      final filter = AutoReframeService.generateFFmpegFilter(
        layout: layout,
        targetWidth: 1080,
        targetHeight: 1920,
      );

      expect(filter, contains('split=2[fg_raw][bg_raw]'));
      expect(filter, contains('scale=1080:1920:force_original_aspect_ratio=increase'));
      expect(filter, contains('gblur=sigma=25:steps=2[bg_blur]'));
      expect(filter, contains('scale=1080:1920:force_original_aspect_ratio=decrease'));
      expect(filter, contains('[bg_blur][fg_scaled]overlay=(W-w)/2:(H-h)/2'));
      expect(AutoReframeService.getReframeBadge(layout), contains('BLUR CLONE'));
    });

    test('Smart crop centered generates scale and center crop expression', () {
      const layout = VideoLayoutConfig(
        ratio: VideoLayoutRatio.ratio9_16,
        reframeMode: AutoReframeMode.smartCrop,
        focalPointX: 0.0,
        focalPointY: 0.0,
      );

      final filter = AutoReframeService.generateFFmpegFilter(
        layout: layout,
        targetWidth: 1080,
        targetHeight: 1920,
      );

      expect(filter, contains('scale=1080:1920:force_original_aspect_ratio=increase'));
      expect(filter, contains('crop=1080:1920:(iw-ow)/2:(ih-oh)/2'));
      expect(AutoReframeService.getReframeBadge(layout), contains('SMART CROP'));
    });

    test('Smart crop with horizontal pan incorporates focal point offset in crop expression', () {
      const layout = VideoLayoutConfig(
        ratio: VideoLayoutRatio.ratio9_16,
        reframeMode: AutoReframeMode.smartCrop,
        focalPointX: 0.40,
        focalPointY: 0.0,
      );

      final filter = AutoReframeService.generateFFmpegFilter(
        layout: layout,
        targetWidth: 1080,
        targetHeight: 1920,
      );

      expect(filter, contains('scale=1080:1920:force_original_aspect_ratio=increase'));
      expect(filter, contains('(iw-ow)/2 + (0.40 * (iw-ow)/2)'));
      expect(AutoReframeService.getReframeBadge(layout), contains('PAN 40%'));
    });

    test('Solid pillarbox generates decrease scale and pad with hex color', () {
      const layout = VideoLayoutConfig(
        ratio: VideoLayoutRatio.ratio1_1,
        reframeMode: AutoReframeMode.solidPillarbox,
        backgroundColor: 0xFF141A29,
        framePadding: 10.0,
      );

      final filter = AutoReframeService.generateFFmpegFilter(
        layout: layout,
        targetWidth: 1080,
        targetHeight: 1080,
      );

      expect(filter, contains('scale=1060:1060:force_original_aspect_ratio=decrease'));
      expect(filter, contains('pad=1080:1080:(ow-iw)/2:(oh-ih)/2:color=0x141A29'));
      expect(AutoReframeService.getReframeBadge(layout), contains('SOLID FRAME'));
    });

    test('Gradient canvas generates pad with gradient preset tone', () {
      const layout = VideoLayoutConfig(
        ratio: VideoLayoutRatio.ratio4_5,
        reframeMode: AutoReframeMode.gradientCanvas,
        gradientPreset: GradientCanvasPreset.sunset,
      );

      final filter = AutoReframeService.generateFFmpegFilter(
        layout: layout,
        targetWidth: 1080,
        targetHeight: 1350,
      );

      expect(filter, contains('scale=1080:1350:force_original_aspect_ratio=decrease'));
      expect(filter, contains('color=0xFF512F'));
      expect(AutoReframeService.getReframeBadge(layout), contains('VIBRANT SUNSET'));
    });
  });

  group('FFmpegCommandBuilder Auto-Reframing Integration Tests', () {
    test('FFmpegCommandBuilder includes blur clone auto-reframe filter in export arguments', () {
      final clip = Clip(
        id: 'c1',
        assetId: 'a1',
        startTimeMs: 0,
        durationMs: 3000,
        sourceInMs: 0,
        sourceOutMs: 3000,
      );

      final project = Project(
        id: 'p1',
        title: 'Auto-Reframe Project',
        durationMs: 3000,
        tracks: [
          Track(id: 't1', type: TrackType.video, clips: [clip]),
        ],
        assets: const [
          MediaAsset(id: 'a1', path: 'landscape.mp4', fileName: 'landscape.mp4', type: MediaType.video, durationMs: 3000),
        ],
        layoutConfig: const VideoLayoutConfig(
          ratio: VideoLayoutRatio.ratio9_16,
          reframeMode: AutoReframeMode.fitWithBlur,
          blurIntensity: 28.0,
        ),
      );

      final args = FFmpegCommandBuilder.buildArguments(project, const ExportConfiguration());
      final filterComplexArg = args[args.indexOf('-filter_complex') + 1];

      expect(filterComplexArg, contains('split=2[fg_raw][bg_raw]'));
      expect(filterComplexArg, contains('gblur=sigma=28'));
      expect(filterComplexArg, contains('[bg_blur][fg_scaled]overlay=(W-w)/2:(H-h)/2'));
    });

    test('FFmpegCommandBuilder includes smart crop auto-reframe filter with pan offset', () {
      final clip = Clip(
        id: 'c1',
        assetId: 'a1',
        startTimeMs: 0,
        durationMs: 3000,
        sourceInMs: 0,
        sourceOutMs: 3000,
      );

      final project = Project(
        id: 'p1',
        title: 'Smart Crop Project',
        durationMs: 3000,
        tracks: [
          Track(id: 't1', type: TrackType.video, clips: [clip]),
        ],
        assets: const [
          MediaAsset(id: 'a1', path: 'landscape.mp4', fileName: 'landscape.mp4', type: MediaType.video, durationMs: 3000),
        ],
        layoutConfig: const VideoLayoutConfig(
          ratio: VideoLayoutRatio.ratio9_16,
          reframeMode: AutoReframeMode.smartCrop,
          focalPointX: -0.50,
        ),
      );

      final args = FFmpegCommandBuilder.buildArguments(project, const ExportConfiguration());
      final filterComplexArg = args[args.indexOf('-filter_complex') + 1];

      expect(filterComplexArg, contains('scale=1080:1920:force_original_aspect_ratio=increase'));
      expect(filterComplexArg, contains('-0.50 * (iw-ow)/2'));
    });
  });
}
