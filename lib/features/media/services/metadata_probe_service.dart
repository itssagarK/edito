import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import '../../../models/media_asset.dart';
import 'thumbnail_service.dart';

class MetadataProbeService {
  /// Probes a given file path and extracts technical metadata into a MediaAsset
  static Future<MediaAsset> probeFile(String filePath, MediaType type) async {
    final file = File(filePath);
    final fileExists = await file.exists();
    final fileSize = fileExists ? await file.length() : 0;
    final fileName = p.basename(filePath);
    final assetId = const Uuid().v4();

    final thumbPath = await ThumbnailService.getThumbnailCachePath(assetId);

    int durationMs = 0;
    int width = 0;
    int height = 0;
    double fps = 30.0;

    switch (type) {
      case MediaType.video:
        if (fileExists) {
          try {
            final controller = VideoPlayerController.file(file);
            await controller.initialize();
            final d = controller.value.duration.inMilliseconds;
            if (d > 0) durationMs = d;
            final w = controller.value.size.width.toInt();
            final h = controller.value.size.height.toInt();
            if (w > 0 && h > 0) {
              width = w;
              height = h;
            } else {
              width = 1920;
              height = 1080;
            }
            await controller.dispose();
          } catch (_) {
            durationMs = 10000;
            width = 1920;
            height = 1080;
          }
        } else {
          durationMs = 10000;
          width = 1920;
          height = 1080;
        }
        fps = 30.0;
        break;

      case MediaType.audio:
        if (fileExists) {
          try {
            final controller = VideoPlayerController.file(file);
            await controller.initialize();
            final d = controller.value.duration.inMilliseconds;
            if (d > 0) durationMs = d;
            await controller.dispose();
          } catch (_) {
            durationMs = 30000;
          }
        } else {
          durationMs = 30000;
        }
        width = 0;
        height = 0;
        fps = 0.0;
        break;

      case MediaType.image:
        durationMs = 4000; // Images get default 4.0s timeline duration
        width = 1920;
        height = 1080;
        fps = 0.0;
        break;
    }

    return MediaAsset(
      id: assetId,
      path: filePath,
      fileName: fileName,
      type: type,
      durationMs: durationMs,
      width: width,
      height: height,
      fps: fps,
      fileSize: fileSize,
      thumbnailPath: thumbPath,
    );
  }

  /// Identifies MediaType by file extension
  static MediaType detectTypeFromExtension(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    const videoExts = ['.mp4', '.mov', '.mkv', '.avi', '.webm', '.flv', '.m4v', '.3gp'];
    const audioExts = ['.mp3', '.wav', '.aac', '.m4a', '.flac', '.ogg', '.wma'];
    const imageExts = ['.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif'];

    if (videoExts.contains(ext)) {
      return MediaType.video;
    } else if (audioExts.contains(ext)) {
      return MediaType.audio;
    } else if (imageExts.contains(ext)) {
      return MediaType.image;
    }
    return MediaType.video;
  }
}
