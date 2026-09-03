import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../models/media_asset.dart';
import 'metadata_probe_service.dart';

class MediaPickerService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Picks a video from the system gallery (Google Photos, Samsung Gallery, etc.)
  Future<List<MediaAsset>> pickVideoFromGallery() async {
    try {
      final picked = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 60),
      );
      if (picked == null) return [];

      final asset = await MetadataProbeService.probeFile(picked.path, MediaType.video);
      return [asset];
    } catch (e) {
      debugPrint('pickVideoFromGallery error: $e');
      return [];
    }
  }

  /// Records a new video using the device camera
  Future<List<MediaAsset>> recordVideoWithCamera() async {
    try {
      final picked = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      );
      if (picked == null) return [];

      final asset = await MetadataProbeService.probeFile(picked.path, MediaType.video);
      return [asset];
    } catch (e) {
      debugPrint('recordVideoWithCamera error: $e');
      return [];
    }
  }

  /// Picks videos via FilePicker with fallback to gallery
  Future<List<MediaAsset>> pickVideos({bool allowMultiple = true}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: allowMultiple,
      );

      if (result != null && result.files.isNotEmpty) {
        final assets = <MediaAsset>[];
        for (final file in result.files) {
          String? resolvedPath = file.path;

          // If path is null (common on some SAF providers), cache bytes to temp file
          if (resolvedPath == null && file.bytes != null) {
            final tempDir = await getTemporaryDirectory();
            final ext = file.extension ?? 'mp4';
            final tempFile = File(p.join(tempDir.path, '${const Uuid().v4()}.$ext'));
            await tempFile.writeAsBytes(file.bytes!);
            resolvedPath = tempFile.path;
          }

          if (resolvedPath != null && resolvedPath.isNotEmpty) {
            final asset = await MetadataProbeService.probeFile(resolvedPath, MediaType.video);
            assets.add(asset);
          }
        }
        if (assets.isNotEmpty) return assets;
      }
    } catch (e) {
      debugPrint('FilePicker error, falling back to gallery: $e');
    }

    // Reliable fallback to system gallery
    return pickVideoFromGallery();
  }

  /// Picks audio files from device
  Future<List<MediaAsset>> pickAudios({bool allowMultiple = true}) async {
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowMultiple: allowMultiple,
        );
      } catch (_) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg', 'wma'],
          allowMultiple: allowMultiple,
        );
      }

      if (result == null || result.files.isEmpty) return [];

      final assets = <MediaAsset>[];
      for (final file in result.files) {
        String? resolvedPath = file.path;
        if (resolvedPath == null && file.bytes != null) {
          final tempDir = await getTemporaryDirectory();
          final ext = file.extension ?? 'mp3';
          final tempFile = File(p.join(tempDir.path, '${const Uuid().v4()}.$ext'));
          await tempFile.writeAsBytes(file.bytes!);
          resolvedPath = tempFile.path;
        }

        if (resolvedPath != null && resolvedPath.isNotEmpty) {
          final asset = await MetadataProbeService.probeFile(resolvedPath, MediaType.audio);
          assets.add(asset);
        }
      }
      return assets;
    } catch (e) {
      debugPrint('pickAudios error: $e');
      return [];
    }
  }

  /// Picks photos / images from gallery or files
  Future<List<MediaAsset>> pickImages({bool allowMultiple = true}) async {
    try {
      if (allowMultiple) {
        final pickedList = await _imagePicker.pickMultiImage();
        if (pickedList.isNotEmpty) {
          final assets = <MediaAsset>[];
          for (final xFile in pickedList) {
            final asset = await MetadataProbeService.probeFile(xFile.path, MediaType.image);
            assets.add(asset);
          }
          return assets;
        }
      }

      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return [];
      final asset = await MetadataProbeService.probeFile(picked.path, MediaType.image);
      return [asset];
    } catch (e) {
      debugPrint('pickImages error: $e');
      return [];
    }
  }

  /// Captures a photo using the device camera
  Future<List<MediaAsset>> capturePhotoWithCamera() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.camera);
      if (picked == null) return [];
      final asset = await MetadataProbeService.probeFile(picked.path, MediaType.image);
      return [asset];
    } catch (e) {
      debugPrint('capturePhotoWithCamera error: $e');
      return [];
    }
  }
}
