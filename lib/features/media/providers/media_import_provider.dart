import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/clip.dart';
import '../../../models/media_asset.dart';
import '../../../models/track.dart';
import '../../editor/providers/editor_provider.dart';
import '../../home/providers/project_list_provider.dart';
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

  void _addAssetsToProject(List<MediaAsset> assets, {required TrackType targetType}) {
    if (assets.isEmpty) return;

    final editorState = _ref.read(editorProvider);
    var project = editorState.project;
    if (project == null) return;

    // Find or create suitable target track
    Track? targetTrack = project.tracks.firstWhere(
      (t) => t.type == targetType,
      orElse: () => project!.tracks.first,
    );

    int insertionPositionMs = targetTrack.durationMs;

    for (final asset in assets) {
      project = project!.addAsset(asset);

      final clipDuration = asset.durationMs > 0 ? asset.durationMs : 3000;
      final newClip = Clip(
        id: const Uuid().v4(),
        assetId: asset.id,
        trackId: targetTrack.id,
        startTimeMs: insertionPositionMs,
        durationMs: clipDuration,
        sourceInMs: 0,
        sourceOutMs: clipDuration,
      );

      project = project.addClipToTrack(targetTrack.id, newClip);
      insertionPositionMs += clipDuration;
    }

    _ref.read(editorProvider.notifier).updateProject(project!);
    _ref.read(projectListProvider.notifier).updateProject(project);
  }
}
