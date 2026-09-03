import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/clip.dart';
import '../../../models/media_asset.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import '../../audio/models/audio_effects_config.dart';
import '../../color_grading/models/color_grading_config.dart';
import '../../overlays/models/text_overlay_config.dart';
import '../../transitions/models/transition_type.dart';
import '../../project/services/project_storage_service.dart';

final projectListProvider = StateNotifierProvider<ProjectListNotifier, List<Project>>((ref) {
  return ProjectListNotifier();
});

class ProjectListNotifier extends StateNotifier<List<Project>> {
  ProjectListNotifier() : super([]) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    final loaded = await ProjectStorageService.loadAllProjects();
    final hasActiveClips = loaded.any((p) => p.tracks.any((t) => t.clips.isNotEmpty));

    if (loaded.isNotEmpty && hasActiveClips) {
      state = loaded;
    } else {
      // Seed a rich, interactive demo project
      final videoTrackId = const Uuid().v4();
      final audioTrackId = const Uuid().v4();

      final introAssetId = const Uuid().v4();
      final brollAssetId = const Uuid().v4();
      final musicAssetId = const Uuid().v4();

      final introAsset = MediaAsset(
        id: introAssetId,
        path: 'sample_cinematic_intro.mp4',
        fileName: 'Cinematic_Intro.mp4',
        type: MediaType.video,
        durationMs: 6000,
        width: 1920,
        height: 1080,
        fps: 30.0,
      );

      final brollAsset = MediaAsset(
        id: brollAssetId,
        path: 'sample_urban_scene.mp4',
        fileName: 'Urban_Scene.mp4',
        type: MediaType.video,
        durationMs: 8000,
        width: 1920,
        height: 1080,
        fps: 30.0,
      );

      final musicAsset = MediaAsset(
        id: musicAssetId,
        path: 'sample_electronic_beat.mp3',
        fileName: 'Electronic_Beat.mp3',
        type: MediaType.audio,
        durationMs: 14000,
        width: 0,
        height: 0,
        fps: 0.0,
      );

      final clip1 = Clip(
        id: const Uuid().v4(),
        assetId: introAssetId,
        trackId: videoTrackId,
        startTimeMs: 0,
        durationMs: 6000,
        sourceInMs: 0,
        sourceOutMs: 6000,
        colorGrading: const ColorGradingConfig(
          activeLut: LutPreset.tealAndOrange,
          contrast: 1.15,
          saturation: 1.25,
        ),
        textOverlay: const TextOverlayConfig(
          text: 'EDITO CINEMATIC',
          fontSize: 26.0,
          animationType: TextAnimationType.typewriter,
        ),
        transitionIn: const TransitionConfig(
          type: TransitionType.zoomIn,
          durationMs: 1000,
        ),
      );

      final clip2 = Clip(
        id: const Uuid().v4(),
        assetId: brollAssetId,
        trackId: videoTrackId,
        startTimeMs: 6000,
        durationMs: 8000,
        sourceInMs: 0,
        sourceOutMs: 8000,
        speed: 1.25,
        colorGrading: const ColorGradingConfig(
          activeLut: LutPreset.moodyCyber,
          saturation: 1.3,
        ),
        textOverlay: const TextOverlayConfig(
          text: '4K PRO MASTER',
          fontSize: 28.0,
          animationType: TextAnimationType.slideUp,
        ),
        transitionIn: const TransitionConfig(
          type: TransitionType.crossDissolve,
          durationMs: 800,
        ),
      );

      final audioClip = Clip(
        id: const Uuid().v4(),
        assetId: musicAssetId,
        trackId: audioTrackId,
        startTimeMs: 0,
        durationMs: 14000,
        sourceInMs: 0,
        sourceOutMs: 14000,
        volume: 0.85,
        audioEffects: const AudioEffectsConfig(
          isDuckingEnabled: true,
          isVoiceEnhancerEnabled: true,
          denoiseIntensity: 0.80,
        ),
      );

      final sampleProject = Project(
        id: const Uuid().v4(),
        title: 'Demo Reel 2026',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
        durationMs: 14000,
        assets: [introAsset, brollAsset, musicAsset],
        tracks: [
          Track(
            id: videoTrackId,
            name: 'Video Track 1',
            type: TrackType.video,
            order: 0,
            clips: [clip1, clip2],
          ),
          Track(
            id: audioTrackId,
            name: 'Audio Track 1',
            type: TrackType.audio,
            order: 1,
            clips: [audioClip],
          ),
        ],
      );

      state = [sampleProject];
      await ProjectStorageService.saveProject(sampleProject);
    }
  }

  Future<Project> createNewProject({String title = 'Untitled Project'}) async {
    final now = DateTime.now();
    final videoTrackId = const Uuid().v4();
    final audioTrackId = const Uuid().v4();
    final starterAssetId = const Uuid().v4();

    final starterAsset = MediaAsset(
      id: starterAssetId,
      path: 'starter_scene.mp4',
      fileName: 'Scene_01.mp4',
      type: MediaType.video,
      durationMs: 6000,
      width: 1920,
      height: 1080,
      fps: 30.0,
    );

    final starterClip = Clip(
      id: const Uuid().v4(),
      assetId: starterAssetId,
      trackId: videoTrackId,
      startTimeMs: 0,
      durationMs: 6000,
      sourceInMs: 0,
      sourceOutMs: 6000,
      textOverlay: const TextOverlayConfig(
        text: 'EDITO TITLE',
        fontSize: 28.0,
        animationType: TextAnimationType.typewriter,
      ),
      colorGrading: const ColorGradingConfig(
        activeLut: LutPreset.goldenHour,
      ),
    );

    final newProj = Project(
      id: const Uuid().v4(),
      title: title,
      createdAt: now,
      updatedAt: now,
      durationMs: 6000,
      assets: [starterAsset],
      tracks: [
        Track(
          id: videoTrackId,
          name: 'Video Track 1',
          type: TrackType.video,
          order: 0,
          clips: [starterClip],
        ),
        Track(
          id: audioTrackId,
          name: 'Audio Track 1',
          type: TrackType.audio,
          order: 1,
          clips: const [],
        ),
      ],
    );

    state = [newProj, ...state];
    await ProjectStorageService.saveProject(newProj);
    return newProj;
  }

  Future<void> deleteProject(String id) async {
    state = state.where((p) => p.id != id).toList();
    await ProjectStorageService.deleteProject(id);
  }

  Future<void> updateProject(Project updated) async {
    state = [
      for (final p in state)
        if (p.id == updated.id) updated else p
    ];
    await ProjectStorageService.saveProject(updated);
  }
}
