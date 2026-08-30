import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ThumbnailService {
  static Future<Directory> get _thumbnailCacheDir async {
    final cacheDir = await getTemporaryDirectory();
    final thumbDir = Directory(p.join(cacheDir.path, 'edito_thumbnails'));
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }
    return thumbDir;
  }

  /// Generates a unique cached thumbnail file path for an asset
  static Future<String> getThumbnailCachePath(String assetId) async {
    final dir = await _thumbnailCacheDir;
    return p.join(dir.path, 'thumb_$assetId.jpg');
  }

  /// Checks if a thumbnail already exists on disk
  static Future<bool> thumbnailExists(String thumbnailPath) async {
    return File(thumbnailPath).exists();
  }

  /// Clears temporary cached thumbnails
  static Future<void> clearThumbnailCache() async {
    try {
      final dir = await _thumbnailCacheDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
