import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/features/image_editor/models/image_overlay_config.dart';
import 'package:edito/features/image_editor/services/pip_compiler_service.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/export/models/export_preset.dart';

void main() {
  group('Picture-in-Picture (PiP) Multi-Layer Video Overlay Studio Tests', () {
    test('PipShape and PipPreset enums provide descriptive human-readable labels', () {
      expect(PipShape.rectangle.label, equals('Sharp Window'));
      expect(PipShape.roundedRect.label, equals('Rounded Window'));
      expect(PipShape.circle.label, equals('Circle Webcam'));
      expect(PipShape.diamond.label, equals('Diamond'));
      expect(PipShape.squircle.label, contains('Squircle'));

      expect(PipPreset.custom.label, contains('Custom'));
      expect(PipPreset.bottomRightWebcam.label, contains('Bottom-Right'));
      expect(PipPreset.bottomLeft.label, equals('Bottom-Left'));
      expect(PipPreset.topRight.label, equals('Top-Right'));
      expect(PipPreset.topLeftGaming.label, contains('Gaming'));
      expect(PipPreset.sideBySideLeft.label, contains('Split Left'));
      expect(PipPreset.sideBySideRight.label, contains('Split Right'));
      expect(PipPreset.circleWebcam.label, contains('Circle'));
      expect(PipPreset.centerFloating.label, contains('Center Floating'));
    });

    test('ImageOverlayConfig default constructor sets standard PiP properties', () {
      const config = ImageOverlayConfig();
      expect(config.isEnabled, isFalse);
      expect(config.isPiP, isTrue);
      expect(config.shape, equals(PipShape.roundedRect));
      expect(config.preset, equals(PipPreset.bottomRightWebcam));
      expect(config.scale, equals(0.32));
      expect(config.positionX, equals(0.80));
      expect(config.positionY, equals(0.80));
      expect(config.cornerRadius, equals(14.0));
      expect(config.borderWidth, equals(2.5));
      expect(config.borderColor, equals(0xFFFFFFFF));
      expect(config.hasShadow, isTrue);
      expect(config.shadowBlur, equals(10.0));
    });

    test('ImageOverlayConfig.getPresetConfig configures accurate geometries for all presets', () {
      final webcam = ImageOverlayConfig.getPresetConfig(PipPreset.bottomRightWebcam);
      expect(webcam.isEnabled, isTrue);
      expect(webcam.positionX, equals(0.80));
      expect(webcam.positionY, equals(0.80));
      expect(webcam.shape, equals(PipShape.roundedRect));

      final circle = ImageOverlayConfig.getPresetConfig(PipPreset.circleWebcam);
      expect(circle.isEnabled, isTrue);
      expect(circle.shape, equals(PipShape.circle));
      expect(circle.cornerRadius, equals(999.0));
      expect(circle.borderWidth, equals(3.0));

      final splitLeft = ImageOverlayConfig.getPresetConfig(PipPreset.sideBySideLeft);
      expect(splitLeft.positionX, equals(0.25));
      expect(splitLeft.positionY, equals(0.50));
      expect(splitLeft.scale, equals(0.50));
      expect(splitLeft.shape, equals(PipShape.rectangle));
      expect(splitLeft.cornerRadius, equals(0.0));

      final splitRight = ImageOverlayConfig.getPresetConfig(PipPreset.sideBySideRight);
      expect(splitRight.positionX, equals(0.75));
      expect(splitRight.positionY, equals(0.50));
      expect(splitRight.scale, equals(0.50));

      final gaming = ImageOverlayConfig.getPresetConfig(PipPreset.topLeftGaming);
      expect(gaming.positionX, equals(0.20));
      expect(gaming.positionY, equals(0.20));

      final center = ImageOverlayConfig.getPresetConfig(PipPreset.centerFloating);
      expect(center.positionX, equals(0.50));
      expect(center.positionY, equals(0.50));
      expect(center.shape, equals(PipShape.squircle));
    });

    test('ImageOverlayConfig JSON serialization roundtrip preserves all PiP attributes', () {
      const original = ImageOverlayConfig(
        isEnabled: true,
        mediaPath: '/storage/emulated/0/Movies/webcam.mp4',
        assetLabel: 'Facecam 1080p',
        shape: PipShape.diamond,
        preset: PipPreset.topRight,
        positionX: 0.85,
        positionY: 0.15,
        scale: 0.28,
        opacity: 0.95,
        rotation: 4.0,
        isPiP: true,
        cornerRadius: 8.0,
        borderWidth: 3.5,
        borderColor: 0xFF00E5FF,
        hasShadow: true,
        shadowBlur: 14.0,
        shadowColor: 0xCC000000,
      );

      final json = original.toJson();
      final restored = ImageOverlayConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.mediaPath, equals('/storage/emulated/0/Movies/webcam.mp4'));
      expect(restored.imagePath, equals('/storage/emulated/0/Movies/webcam.mp4')); // legacy alias
      expect(restored.assetLabel, equals('Facecam 1080p'));
      expect(restored.shape, equals(PipShape.diamond));
      expect(restored.preset, equals(PipPreset.topRight));
      expect(restored.positionX, equals(0.85));
      expect(restored.positionY, equals(0.15));
      expect(restored.scale, equals(0.28));
      expect(restored.opacity, equals(0.95));
      expect(restored.rotation, equals(4.0));
      expect(restored.borderWidth, equals(3.5));
      expect(restored.borderColor, equals(0xFF00E5FF));
      expect(restored.shadowBlur, equals(14.0));
    });

    test('PipCompilerService generates deterministic FFmpeg overlay filter commands', () {
      const disabledConfig = ImageOverlayConfig(isEnabled: false);
      expect(
        PipCompilerService.generateFFmpegOverlayFilter(disabledConfig, targetWidth: 1920, targetHeight: 1080),
        isEmpty,
      );

      const enabledConfig = ImageOverlayConfig(
        isEnabled: true,
        mediaPath: '/dummy/path.png',
        assetLabel: 'Gamer Cam',
        shape: PipShape.roundedRect,
        preset: PipPreset.bottomRightWebcam,
        positionX: 0.80,
        positionY: 0.80,
        scale: 0.30,
        borderWidth: 3.0,
        borderColor: 0xFF00E5FF,
      );

      final filter = PipCompilerService.generateFFmpegOverlayFilter(
        enabledConfig,
        targetWidth: 1920,
        targetHeight: 1080,
      );

      expect(filter, isNotEmpty);
      expect(filter, contains('drawbox='));
      expect(filter, contains('t=fill'));
      expect(filter, contains('t=3'));
      expect(filter, contains("drawtext=text='Gamer Cam'"));
    });

    test('PipCompilerService generates accurate HUD status badge strings', () {
      expect(PipCompilerService.getPipBadge(const ImageOverlayConfig(isEnabled: false)), isEmpty);

      final circle = ImageOverlayConfig.getPresetConfig(PipPreset.circleWebcam);
      expect(PipCompilerService.getPipBadge(circle), equals('🪟 PiP (CIRCLE WEBCAM)'));

      final split = ImageOverlayConfig.getPresetConfig(PipPreset.sideBySideLeft);
      expect(PipCompilerService.getPipBadge(split), equals('🪟 PiP (SPLIT 50/50)'));

      final webcam = ImageOverlayConfig.getPresetConfig(PipPreset.bottomRightWebcam);
      expect(PipCompilerService.getPipBadge(webcam), contains('PiP'));
    });

    test('FFmpegCommandBuilder integrates PiP filter commands into export pipeline', () {
      final pipClip = Clip(
        id: 'clip_pip_01',
        assetId: 'asset_01',
        trackId: 'track_video_01',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        imageOverlay: const ImageOverlayConfig(
          isEnabled: true,
          mediaPath: '/media/cam.mp4',
          assetLabel: 'Host Cam',
          scale: 0.35,
          borderWidth: 2.0,
        ),
      );

      final project = Project(
        id: 'proj_pip_test',
        name: 'PiP Test Project',
        assets: const [
          MediaAsset(
            id: 'asset_01',
            path: '/media/base.mp4',
            fileName: 'base.mp4',
            type: MediaType.video,
            durationMs: 5000,
          ),
        ],
        tracks: [
          Track(
            id: 'track_video_01',
            name: 'Main Video',
            type: TrackType.video,
            clips: [pipClip],
          ),
        ],
      );

      const config = ExportConfiguration(
        outputPath: '/out/pip_render.mp4',
      );

      final cmd = FFmpegCommandBuilder.buildArguments(project, config);

      expect(cmd.any((arg) => arg.contains('drawbox=')), isTrue);
      expect(cmd.any((arg) => arg.contains('Host Cam')), isTrue);
    });
  });
}
