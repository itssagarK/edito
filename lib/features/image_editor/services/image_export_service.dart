import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart' hide Clip;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../models/clip.dart';
import '../../../models/media_asset.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import '../../export/services/gallery_saver_service.dart';

class ImageExportService {
  /// Captures a RepaintBoundary widget tree and exports it to a high-res PNG file
  static Future<String?> captureBoundaryToFile(
    GlobalKey repaintKey, {
    String? prefix = 'Thumbnail',
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Render at 2.5x pixel ratio for ultra-crisp HD output
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${prefix}_$timestamp.png';

      final docDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(docDir.path, 'thumbnails'));
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }
      final localPath = p.join(targetDir.path, fileName);
      await File(localPath).writeAsBytes(bytes, flush: true);

      // Save to Android Gallery MediaStore (Pictures/Edito)
      final galleryResult = await GallerySaverService.saveImageToGallery(
        localPath,
        title: prefix,
        album: 'Edito',
      );

      return galleryResult.savedPath ?? localPath;
    } catch (e) {
      debugPrint('captureBoundaryToFile error: $e');
      return null;
    }
  }

  /// Integrates an edited image file into the project timeline as a video track clip
  static Project addImageToTimeline(
    Project project,
    String imagePath, {
    int durationMs = 4000,
  }) {
    final assetId = const Uuid().v4();
    final fileName = p.basename(imagePath);

    final imageAsset = MediaAsset(
      id: assetId,
      path: imagePath,
      fileName: fileName,
      type: MediaType.image,
      durationMs: durationMs,
      width: 1920,
      height: 1080,
    );

    // Find primary video track or create one
    Track? videoTrack;
    for (final t in project.tracks) {
      if (t.type == TrackType.video) {
        videoTrack = t;
        break;
      }
    }

    final trackId = videoTrack?.id ?? const Uuid().v4();
    final startTime = videoTrack?.durationMs ?? 0;

    final newClip = Clip(
      id: const Uuid().v4(),
      assetId: assetId,
      trackId: trackId,
      startTimeMs: startTime,
      durationMs: durationMs,
      sourceInMs: 0,
      sourceOutMs: durationMs,
    );

    List<Track> updatedTracks;
    if (videoTrack != null) {
      updatedTracks = project.tracks.map((t) {
        if (t.id == trackId) {
          return t.copyWith(clips: [...t.clips, newClip]);
        }
        return t;
      }).toList();
    } else {
      final newTrack = Track(
        id: trackId,
        name: 'Video Track 1',
        type: TrackType.video,
        order: 0,
        clips: [newClip],
      );
      updatedTracks = [newTrack, ...project.tracks];
    }

    final updatedProject = project.copyWith(
      tracks: updatedTracks,
      assets: [...project.assets, imageAsset],
      thumbnailPath: imagePath, // Also update project thumbnail
    );

    return updatedProject.recalculateDuration();
  }

  /// Broadcasts intent to Android MediaScanner to index image in gallery
  static void _notifyMediaScanner(String filePath) {
    if (!Platform.isAndroid) return;
    try {
      Process.run('am', [
        'broadcast',
        '-a',
        'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
        '-d',
        'file://$filePath',
      ]);
    } catch (_) {}
  }
}
