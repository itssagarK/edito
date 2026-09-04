import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/export/services/gallery_saver_service.dart';
import 'package:edito/features/export/services/export_render_service.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gallery Saver Service & Export Tests', () {
    test('GallerySaverService returns error when source video does not exist', () async {
      final result = await GallerySaverService.saveVideoToGallery(
        '/non_existent_path/video_fake.mp4',
        title: 'NonExistent',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('does not exist'));
    });

    test('GallerySaverService returns error when source image does not exist', () async {
      final result = await GallerySaverService.saveImageToGallery(
        '/non_existent_path/cover_fake.png',
        title: 'NonExistent',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('does not exist'));
    });

    test('ExportRenderService generateOutputPath generates valid mp4 path in documents', () async {
      final outputPath = await ExportRenderService.generateOutputPath('My Summer Vacation');

      expect(outputPath.endsWith('.mp4'), isTrue);
      expect(outputPath, contains('My_Summer_Vacation'));
      final parentDir = File(outputPath).parent;
      expect(parentDir.existsSync(), isTrue);
    });

    test('ExportRenderService performs end-to-end export and saves video file', () async {
      final service = ExportRenderService();
      final now = DateTime.now();

      // Create a small temporary video file to simulate real asset
      final tempDir = Directory.systemTemp.createTempSync('edito_test_');
      final sampleVideoFile = File('${tempDir.path}/test_source.mp4');
      sampleVideoFile.writeAsBytesSync([0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70]);

      final asset = MediaAsset(
        id: 'test_asset_id',
        path: sampleVideoFile.path,
        fileName: 'test_source.mp4',
        type: MediaType.video,
        durationMs: 4000,
        width: 1920,
        height: 1080,
      );

      final clip = const Clip(
        id: 'test_clip_id',
        assetId: 'test_asset_id',
        trackId: 'track_v',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      final project = Project(
        id: 'p_export_test',
        title: 'Export Test Project',
        createdAt: now,
        updatedAt: now,
        durationMs: 4000,
        assets: [asset],
        tracks: [
          Track(
            id: 'track_v',
            name: 'Video',
            type: TrackType.video,
            order: 0,
            clips: [clip],
          ),
        ],
      );

      final config = const ExportConfiguration(
        resolution: ResolutionPreset.fhd1080p,
        framerate: FrameratePreset.fps30,
        codec: CodecPreset.h264,
        quality: QualityPreset.balanced,
      );

      final exportedPath = await service.startExport(project, config);

      expect(exportedPath, isNotEmpty);
      expect(File(exportedPath).existsSync(), isTrue);
      expect(File(exportedPath).lengthSync(), greaterThan(0));

      // Clean up
      tempDir.deleteSync(recursive: true);
      if (File(exportedPath).existsSync()) {
        try {
          File(exportedPath).deleteSync();
        } catch (_) {}
      }
    });
  });
}
