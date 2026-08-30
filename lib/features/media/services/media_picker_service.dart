import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/media_asset.dart';
import 'metadata_probe_service.dart';

class MediaPickerService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Picks videos from device gallery or files
  Future<List<MediaAsset>> pickVideos({bool allowMultiple = true}) async {
    try {
      if (allowMultiple) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: true,
        );
        if (result == null || result.files.isEmpty) return [];

        final assets = <MediaAsset>[];
        for (final file in result.files) {
          if (file.path != null) {
            final asset = await MetadataProbeService.probeFile(file.path!, MediaType.video);
            assets.add(asset);
          }
        }
        return assets;
      } else {
        final picked = await _imagePicker.pickVideo(source: ImageSource.gallery);
        if (picked == null) return [];
        final asset = await MetadataProbeService.probeFile(picked.path, MediaType.video);
        return [asset];
      }
    } catch (_) {
      return [];
    }
  }

  /// Picks audio files from device
  Future<List<MediaAsset>> pickAudios({bool allowMultiple = true}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: allowMultiple,
      );
      if (result == null || result.files.isEmpty) return [];

      final assets = <MediaAsset>[];
      for (final file in result.files) {
        if (file.path != null) {
          final asset = await MetadataProbeService.probeFile(file.path!, MediaType.audio);
          assets.add(asset);
        }
      }
      return assets;
    } catch (_) {
      return [];
    }
  }

  /// Picks photos / images from gallery
  Future<List<MediaAsset>> pickImages({bool allowMultiple = true}) async {
    try {
      if (allowMultiple) {
        final pickedList = await _imagePicker.pickMultiImage();
        if (pickedList.isEmpty) return [];

        final assets = <MediaAsset>[];
        for (final xFile in pickedList) {
          final asset = await MetadataProbeService.probeFile(xFile.path, MediaType.image);
          assets.add(asset);
        }
        return assets;
      } else {
        final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (picked == null) return [];
        final asset = await MetadataProbeService.probeFile(picked.path, MediaType.image);
        return [asset];
      }
    } catch (_) {
      return [];
    }
  }
}
