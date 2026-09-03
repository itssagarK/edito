import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../models/media_asset.dart';

class ProxyGenerationService {
  /// Generates or resolves a lightweight 720p proxy for large / 4K media files
  static Future<String?> resolveOrCreateProxy(MediaAsset asset) async {
    if (!asset.is4kOrHigher) return null;

    try {
      final cacheDir = await getTemporaryDirectory();
      final proxyDir = Directory(p.join(cacheDir.path, 'proxies'));
      if (!proxyDir.existsSync()) {
        proxyDir.createSync(recursive: true);
      }

      final proxyFileName = 'proxy_${asset.id}.mp4';
      final proxyPath = p.join(proxyDir.path, proxyFileName);
      final proxyFile = File(proxyPath);

      if (proxyFile.existsSync() && proxyFile.lengthSync() > 0) {
        return proxyPath;
      }

      // If ffmpeg is available, transcode a fast 720p 30fps editing proxy
      final originalFile = File(asset.path);
      if (!originalFile.existsSync()) return null;

      try {
        final result = await Process.run('ffmpeg', [
          '-i', asset.path,
          '-vf', 'scale=-2:720',
          '-c:v', 'libx264',
          '-preset', 'ultrafast',
          '-crf', '28',
          '-r', '30',
          '-c:a', 'aac',
          '-y', proxyPath,
        ]);
        if (result.exitCode == 0 && proxyFile.existsSync()) {
          debugPrint('Generated 720p editing proxy: $proxyPath');
          return proxyPath;
        }
      } catch (_) {
        // Native FFmpeg executable not present on path
      }

      return null;
    } catch (e) {
      debugPrint('Proxy generation error: $e');
      return null;
    }
  }
}
