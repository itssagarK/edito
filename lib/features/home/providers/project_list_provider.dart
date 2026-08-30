import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
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
    if (loaded.isNotEmpty) {
      state = loaded;
    } else {
      // Seed an initial demo project
      final sampleProject = Project(
        id: const Uuid().v4(),
        title: 'Demo Reel 2026',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
        durationMs: 15000,
        tracks: [
          Track(
            id: const Uuid().v4(),
            name: 'Video Track 1',
            type: TrackType.video,
            order: 0,
          ),
          Track(
            id: const Uuid().v4(),
            name: 'Audio Track 1',
            type: TrackType.audio,
            order: 1,
          ),
        ],
      );
      state = [sampleProject];
      await ProjectStorageService.saveProject(sampleProject);
    }
  }

  Future<Project> createNewProject({String title = 'Untitled Project'}) async {
    final now = DateTime.now();
    final newProj = Project(
      id: const Uuid().v4(),
      title: title,
      createdAt: now,
      updatedAt: now,
      tracks: [
        Track(
          id: const Uuid().v4(),
          name: 'Video Track 1',
          type: TrackType.video,
          order: 0,
        ),
        Track(
          id: const Uuid().v4(),
          name: 'Audio Track 1',
          type: TrackType.audio,
          order: 1,
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
