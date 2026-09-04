import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/clip.dart';
import '../../../models/media_asset.dart';
import '../../../models/track.dart';
import '../../editor/providers/editor_provider.dart';
import '../../home/providers/project_list_provider.dart';
import '../../preview/providers/preview_playback_provider.dart';
import '../services/media_picker_service.dart';

final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  return MediaPickerService();
});

final mediaImportProvider = StateNotifierProvider<MediaImportNotifier, AsyncValue<List<MediaAsset>>>((ref) {
  final pickerService = ref.watch(mediaPickerServiceProvider);
  return MediaImportNotifier(pickerService, ref);
});

class MediaImportNotifier extends StateNotifier<AsyncValue<List<MediaAsset>>> {
  final MediaPickerService _pickerService;
  final Ref _ref;

  MediaImportNotifier(this._pickerService, this._ref) : super(const AsyncValue.data([]));

  /// Imports video directly from device gallery / Google Photos
  Future<List<MediaAsset>> importVideoFromGallery() async {
    state = const AsyncValue.loading();
    try {
      final assets = await _pickerService.pickVideoFromGallery();
      state = AsyncValue.data(assets);
      _addAssetsToProject(assets, targetType: TrackType.video);
      return assets;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  /// Records and imports a video from the camera
  Future<List<MediaAsset>> recordVideoWithCamera() async {
    state = const AsyncValue.loading();
    try {
      final assets = await _pickerService.recordVideoWithCamera();
      state = AsyncValue.data(assets);
      _addAssetsToProject(assets, targetType: TrackType.video);
      return assets;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  /// Imports videos from files / downloads
  Future<List<MediaAsset>> importVideos() async {
    state = const AsyncValue.loading();
    try {
      final assets = await _pickerService.pickVideos(allowMultiple: true);
      state = AsyncValue.data(assets);
      _addAssetsToProject(assets, targetType: TrackType.video);
      return assets;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  /// Imports audio files from device storage
  Future<List<MediaAsset>> importAudios() async {
    state = const AsyncValue.loading();
    try {
      final assets = await _pickerService.pickAudios(allowMultiple: true);
      state = AsyncValue.data(assets);
      _addAssetsToProject(assets, targetType: TrackType.audio);
      return assets;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  /// Imports images / photos from gallery
  Future<List<MediaAsset>> importImages() async {
    state = const AsyncValue.loading();
    try {
      final assets = await _pickerService.pickImages(allowMultiple: true);
      state = AsyncValue.data(assets);
      _addAssetsToProject(assets, targetType: TrackType.video);
      return assets;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  /// Captures photo with camera and imports
  Future<List<MediaAsset>> capturePhotoWithCamera() async {
    state = const AsyncValue.loading();
    try {
      final assets = await _pickerService.capturePhotoWithCamera();
      state = AsyncValue.data(assets);
      _addAssetsToProject(assets, targetType: TrackType.video);
      return assets;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  void _addAssetsToProject(List<MediaAsset> assets, {required TrackType targetType}) {
    if (assets.isEmpty) return;

    final editorState = _ref.read(editorProvider);
    var project = editorState.project;
    if (project == null) return;

    // Check if the current project only contains starter/placeholder clips
    final hasOnlyPlaceholderClips = project.tracks.every((t) => t.clips.every((c) {
      MediaAsset? asset;
      for (final a in project!.assets) {
        if (a.id == c.assetId) {
          asset = a;
          break;
        }
      }
      if (asset == null) return true;
      return asset.path == 'starter_scene.mp4' || asset.path.startsWith('sample_');
    }));

    if (hasOnlyPlaceholderClips && targetType == TrackType.video) {
      // Clear out starter clips and assets so user's real media is the foundation
      final clearedTracks = project.tracks.map((t) => t.copyWith(clips: const [])).toList();
      project = project.copyWith(
        tracks: clearedTracks,
        assets: const [],
        durationMs: 0,
      );
    }

    // Find or create suitable target track
    Track? targetTrack;
    for (final t in project.tracks) {
      if (t.type == targetType) {
        targetTrack = t;
        break;
      }
    }

    if (targetTrack == null) {
      targetTrack = Track(
        id: const Uuid().v4(),
        name: targetType == TrackType.audio ? 'Audio Track' : 'Video Track',
        type: targetType,
        order: project.tracks.length,
      );
      project = project.addTrack(targetTrack);
    }

    // Insert at 0ms if track is empty, or at current playhead position
    int insertionPositionMs = targetTrack.clips.isEmpty ? 0 : editorState.playheadPositionMs;
    Clip? firstNewClip;

    for (final asset in assets) {
      project = project!.addAsset(asset);

      final clipDuration = asset.durationMs > 0 ? asset.durationMs : 4000;
      final newClip = Clip(
        id: const Uuid().v4(),
        assetId: asset.id,
        trackId: targetTrack.id,
        startTimeMs: insertionPositionMs,
        durationMs: clipDuration,
        sourceInMs: 0,
        sourceOutMs: clipDuration,
      );

      firstNewClip ??= newClip;
      project = project.addClipToTrack(targetTrack.id, newClip);
      insertionPositionMs += clipDuration;
    }

    _ref.read(editorProvider.notifier).updateProject(project!);
    _ref.read(projectListProvider.notifier).updateProject(project);

    // Auto-select and jump playhead to the newly imported clip and force frame sync
    if (firstNewClip != null) {
      _ref.read(editorProvider.notifier).selectClip(firstNewClip.id, trackId: targetTrack.id);
      _ref.read(previewPlaybackProvider.notifier).seek(firstNewClip.startTimeMs);
      _ref.read(previewPlaybackProvider.notifier).syncCurrentFrame();
    }
  }
}
