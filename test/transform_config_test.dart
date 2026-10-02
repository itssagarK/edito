import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/features/transform/models/video_transform_config.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/export/models/export_preset.dart';

void main() {
  group('VideoTransformConfig & Spatial Transform Tests', () {
    test('Default VideoTransformConfig is inactive', () {
      const config = VideoTransformConfig();
      expect(config.rotationDegrees, equals(0));
      expect(config.isFlippedHorizontal, isFalse);
      expect(config.isFlippedVertical, isFalse);
      expect(config.scale, equals(1.0));
      expect(config.isActive, isFalse);
    });

    test('VideoTransformConfig activates on rotation, mirror, flip, or scale', () {
      expect(const VideoTransformConfig(rotationDegrees: 90).isActive, isTrue);
      expect(const VideoTransformConfig(isFlippedHorizontal: true).isActive, isTrue);
      expect(const VideoTransformConfig(isFlippedVertical: true).isActive, isTrue);
      expect(const VideoTransformConfig(scale: 1.25).isActive, isTrue);
    });

    test('VideoTransformConfig serialization round-trip', () {
      const original = VideoTransformConfig(
        rotationDegrees: 180,
        isFlippedHorizontal: true,
        isFlippedVertical: false,
        scale: 1.5,
      );
      final json = original.toJson();
      final restored = VideoTransformConfig.fromJson(json);

      expect(restored.rotationDegrees, equals(180));
      expect(restored.isFlippedHorizontal, isTrue);
      expect(restored.isFlippedVertical, isFalse);
      expect(restored.scale, equals(1.5));
      expect(restored, equals(original));
    });

    test('Clip integrates VideoTransformConfig properly', () {
      const clip = Clip(
        id: 'clip_t1',
        assetId: 'asset_t1',
        trackId: 'track_t1',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        transform: VideoTransformConfig(
          rotationDegrees: 270,
          isFlippedHorizontal: true,
        ),
      );

      expect(clip.transform.rotationDegrees, equals(270));
      expect(clip.transform.isFlippedHorizontal, isTrue);

      final updated = clip.copyWith(
        transform: clip.transform.copyWith(rotationDegrees: 0),
      );
      expect(updated.transform.rotationDegrees, equals(0));
      expect(updated.transform.isFlippedHorizontal, isTrue);
    });

    test('FFmpegCommandBuilder includes transpose and hflip/vflip filters for transformed clips', () {
      final asset = MediaAsset(
        id: 'asset_v1',
        filePath: 'C:/media/test_clip.mp4',
        type: MediaType.video,
        durationMs: 5000,
        width: 1920,
        height: 1080,
        fps: 30,
        hasAudio: true,
      );

      final clip90 = Clip(
        id: 'clip_90',
        assetId: asset.id,
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        transform: const VideoTransformConfig(
          rotationDegrees: 90,
          isFlippedHorizontal: true,
        ),
      );

      final track = Track(
        id: 'track_1',
        type: TrackType.video,
        clips: [clip90],
      );

      final project = Project(
        id: 'proj_test',
        name: 'Transform Test',
        assets: [asset],
        tracks: [track],
      );

      final command = FFmpegCommandBuilder.buildComplexExportCommand(
        project: project,
        outputPath: 'C:/media/out.mp4',
        config: const ExportConfig(
          resolution: ExportResolution.r1080p,
          framerate: ExportFramerate.fps30,
          quality: ExportQuality.standard,
        ),
      );

      // Verify that transpose=1 (90 deg) and hflip are present in the filter chain
      final commandStr = command.join(' ');
      expect(commandStr, contains('transpose=1'));
      expect(commandStr, contains('hflip'));
    });
  });
}
