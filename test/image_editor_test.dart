import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/image_editor/models/image_editor_config.dart';
import 'package:edito/features/image_editor/services/image_export_service.dart';

void main() {
  group('Image & Thumbnail Editor Tests', () {
    test('ImageEditorConfig JSON serialization roundtrip', () {
      const config = ImageEditorConfig(
        imagePath: '/photos/cover.jpg',
        layoutRatio: ThumbnailLayoutRatio.ratio9_16,
        filterPreset: ImageFilterPreset.cyberpunk,
        brightness: 0.15,
        contrast: 1.25,
        saturation: 1.4,
        vignette: 0.35,
        headlines: [
          ImageTextHeadline(
            text: 'EPIC REACTION',
            positionX: 0.5,
            positionY: 0.85,
            fontSize: 32,
            textColor: 0xFFFFEA00,
          ),
        ],
        badges: [
          ImageStickerBadge(
            id: 'b1',
            label: 'TOP 10',
            emoji: '⭐',
            backgroundColor: 0xFF00B4D8,
          ),
        ],
      );

      final json = config.toJson();
      final restored = ImageEditorConfig.fromJson(json);

      expect(restored.imagePath, equals('/photos/cover.jpg'));
      expect(restored.layoutRatio, equals(ThumbnailLayoutRatio.ratio9_16));
      expect(restored.filterPreset, equals(ImageFilterPreset.cyberpunk));
      expect(restored.brightness, equals(0.15));
      expect(restored.contrast, equals(1.25));
      expect(restored.headlines.first.text, equals('EPIC REACTION'));
      expect(restored.badges.first.label, equals('TOP 10'));
    });

    test('ThumbnailLayoutRatio exposes correct aspect ratios', () {
      expect(ThumbnailLayoutRatio.ratio16_9.aspectRatio, closeTo(1.77, 0.01));
      expect(ThumbnailLayoutRatio.ratio9_16.aspectRatio, closeTo(0.56, 0.01));
      expect(ThumbnailLayoutRatio.ratio1_1.aspectRatio, equals(1.0));
      expect(ThumbnailLayoutRatio.ratio4_5.aspectRatio, equals(0.8));
    });

    test('ImageExportService adds edited image to video timeline and updates thumbnail', () {
      final now = DateTime.now();
      final project = Project(
        id: 'proj_test',
        title: 'Vlog Project',
        createdAt: now,
        updatedAt: now,
        durationMs: 5000,
        tracks: const [
          Track(
            id: 't_video',
            name: 'Video Track',
            type: TrackType.video,
            order: 0,
            clips: [],
          ),
        ],
      );

      final updated = ImageExportService.addImageToTimeline(
        project,
        '/storage/pictures/thumbnail_test.png',
        durationMs: 4000,
      );

      expect(updated.thumbnailPath, equals('/storage/pictures/thumbnail_test.png'));
      expect(updated.assets.any((a) => a.type == MediaType.image), isTrue);
      expect(updated.tracks.first.clips.length, equals(1));
      expect(updated.tracks.first.clips.first.durationMs, equals(4000));
      expect(updated.durationMs, equals(4000));
    });
  });
}
