import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/image_editor/models/creative_asset.dart';
import 'package:edito/features/image_editor/models/image_overlay_config.dart';
import 'package:edito/features/image_editor/models/video_layout_config.dart';
import 'package:edito/features/image_editor/services/asset_library_service.dart';

void main() {
  group('Video Layout & Creative Assets Tests', () {
    test('VideoLayoutConfig serialization roundtrip', () {
      const config = VideoLayoutConfig(
        ratio: VideoLayoutRatio.ratio9_16,
        backgroundMode: LayoutBackgroundMode.blur,
        fillMode: LayoutFillMode.fill,
        backgroundColor: 0xFF180B38,
        framePadding: 16.0,
        cornerRadius: 20.0,
        blurIntensity: 30.0,
      );

      final json = config.toJson();
      final restored = VideoLayoutConfig.fromJson(json);

      expect(restored.ratio, equals(VideoLayoutRatio.ratio9_16));
      expect(restored.backgroundMode, equals(LayoutBackgroundMode.blur));
      expect(restored.fillMode, equals(LayoutFillMode.fill));
      expect(restored.backgroundColor, equals(0xFF180B38));
      expect(restored.framePadding, equals(16.0));
      expect(restored.cornerRadius, equals(20.0));
    });

    test('VideoLayoutRatio provides standard dimensions', () {
      expect(VideoLayoutRatio.ratio16_9.defaultWidth, equals(1920));
      expect(VideoLayoutRatio.ratio16_9.defaultHeight, equals(1080));

      expect(VideoLayoutRatio.ratio9_16.defaultWidth, equals(1080));
      expect(VideoLayoutRatio.ratio9_16.defaultHeight, equals(1920));

      expect(VideoLayoutRatio.ratio1_1.defaultWidth, equals(1080));
      expect(VideoLayoutRatio.ratio1_1.defaultHeight, equals(1080));

      expect(VideoLayoutRatio.ratio21_9.defaultWidth, equals(2560));
      expect(VideoLayoutRatio.ratio21_9.defaultHeight, equals(1080));
    });

    test('ImageOverlayConfig serialization roundtrip', () {
      const config = ImageOverlayConfig(
        isEnabled: true,
        imagePath: '/storage/stickers/logo.png',
        assetLabel: 'Logo Overlay',
        positionX: 0.8,
        positionY: 0.2,
        scale: 1.5,
        opacity: 0.9,
        rotation: 45.0,
        isPiP: true,
        cornerRadius: 16.0,
      );

      final json = config.toJson();
      final restored = ImageOverlayConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.imagePath, equals('/storage/stickers/logo.png'));
      expect(restored.assetLabel, equals('Logo Overlay'));
      expect(restored.scale, equals(1.5));
      expect(restored.isPiP, isTrue);
      expect(restored.rotation, equals(45.0));
    });

    test('AssetLibraryService contains assets in all categories', () {
      final assets = AssetLibraryService.getAllAssets();
      expect(assets.isNotEmpty, isTrue);

      final categories = assets.map((a) => a.category).toSet();
      expect(categories.contains(AssetCategory.badge), isTrue);
      expect(categories.contains(AssetCategory.frame), isTrue);
      expect(categories.contains(AssetCategory.lowerThird), isTrue);
      expect(categories.contains(AssetCategory.background), isTrue);
    });

    test('AssetLibraryService applies frame layout asset to project', () {
      final now = DateTime.now();
      final project = Project(
        id: 'p_test',
        title: 'Layout Test',
        createdAt: now,
        updatedAt: now,
      );

      final frameAsset = AssetLibraryService.getAllAssets().firstWhere((a) => a.id == 'frame_rounded');
      final updated = AssetLibraryService.applyAssetToProject(project, frameAsset);

      expect(updated.layoutConfig.framePadding, equals(16.0));
      expect(updated.layoutConfig.cornerRadius, equals(24.0));
      expect(updated.layoutConfig.backgroundMode, equals(LayoutBackgroundMode.blur));
    });

    test('AssetLibraryService applies lower third banner to project', () {
      final now = DateTime.now();
      final project = Project(
        id: 'p_test_lower',
        title: 'Lower Third Test',
        createdAt: now,
        updatedAt: now,
        durationMs: 6000,
      );

      final bannerAsset = AssetLibraryService.getAllAssets().firstWhere((a) => a.id == 'lower_breaking');
      final updated = AssetLibraryService.applyAssetToProject(project, bannerAsset);

      expect(updated.tracks.any((t) => t.type == TrackType.overlay), isTrue);
      final overlayTrack = updated.tracks.firstWhere((t) => t.type == TrackType.overlay);
      expect(overlayTrack.clips.first.textOverlay.text, contains('BREAKING NEWS'));
    });
  });
}
