import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class GallerySaveResult {
  final bool isSuccess;
  final String? savedPath;
  final String? mediaUri;
  final String? errorMessage;

  const GallerySaveResult({
    required this.isSuccess,
    this.savedPath,
    this.mediaUri,
    this.errorMessage,
  });
}

class GallerySaverService {
  static const MethodChannel _channel = MethodChannel('com.edito.app/gallery');

  /// Saves a rendered video to the Android Gallery / MediaStore (Movies/Edito)
  static Future<GallerySaveResult> saveVideoToGallery(
    String filePath, {
    String? title,
    String album = 'Edito',
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return GallerySaveResult(
        isSuccess: false,
        errorMessage: 'Source file does not exist at $filePath',
      );
    }

    final videoTitle = title ?? p.basenameWithoutExtension(filePath);

    // 1. Primary: Use native Android MediaStore channel
    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<Map>('saveVideoToGallery', {
          'filePath': filePath,
          'title': videoTitle,
          'album': album,
        });

        if (result != null && result['success'] == true) {
          final savedPath = result['path'] as String?;
          final uri = result['uri'] as String?;
          debugPrint('Successfully saved video to MediaStore: $savedPath ($uri)');
          return GallerySaveResult(
            isSuccess: true,
            savedPath: savedPath ?? filePath,
            mediaUri: uri,
          );
        }
      } catch (e) {
        debugPrint('MediaStore channel error, using fallback: $e');
      }
    }

    // 2. Fallback: Copy to public Movies/Edito or external storage directory
    try {
      Directory? targetDir;
      if (Platform.isAndroid) {
        final publicMovies = Directory('/storage/emulated/0/Movies/$album');
        if (!publicMovies.existsSync()) {
          try {
            publicMovies.createSync(recursive: true);
          } catch (_) {}
        }
        if (publicMovies.existsSync()) {
          targetDir = publicMovies;
        } else {
          final extDirs = await getExternalStorageDirectories(type: StorageDirectory.movies);
          if (extDirs != null && extDirs.isNotEmpty) {
            targetDir = extDirs.first;
          }
        }
      }

      targetDir ??= await getApplicationDocumentsDirectory();

      final fileName = '${videoTitle.replaceAll(RegExp(r'[^\w\s]+'), '_')}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final targetPath = p.join(targetDir.path, fileName);
      await file.copy(targetPath);

      // Trigger MediaScanner
      if (Platform.isAndroid) {
        try {
          await _channel.invokeMethod('scanFile', {'filePath': targetPath});
        } catch (_) {}
      }

      return GallerySaveResult(
        isSuccess: true,
        savedPath: targetPath,
      );
    } catch (e) {
      return GallerySaveResult(
        isSuccess: false,
        savedPath: filePath,
        errorMessage: e.toString(),
      );
    }
  }

  /// Saves an image/cover to the Android Gallery / MediaStore (Pictures/Edito)
  static Future<GallerySaveResult> saveImageToGallery(
    String filePath, {
    String? title,
    String album = 'Edito',
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return GallerySaveResult(
        isSuccess: false,
        errorMessage: 'Source file does not exist at $filePath',
      );
    }

    final imageTitle = title ?? p.basenameWithoutExtension(filePath);

    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<Map>('saveImageToGallery', {
          'filePath': filePath,
          'title': imageTitle,
          'album': album,
        });

        if (result != null && result['success'] == true) {
          final savedPath = result['path'] as String?;
          final uri = result['uri'] as String?;
          return GallerySaveResult(
            isSuccess: true,
            savedPath: savedPath ?? filePath,
            mediaUri: uri,
          );
        }
      } catch (e) {
        debugPrint('MediaStore image channel error: $e');
      }
    }

    // Fallback
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final targetPath = p.join(docDir.path, '${imageTitle}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.copy(targetPath);
      return GallerySaveResult(isSuccess: true, savedPath: targetPath);
    } catch (e) {
      return GallerySaveResult(isSuccess: false, errorMessage: e.toString());
    }
  }
}
