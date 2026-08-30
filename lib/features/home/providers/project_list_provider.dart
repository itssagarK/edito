import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';

final projectListProvider = StateNotifierProvider<ProjectListNotifier, List<Project>>((ref) {
  return ProjectListNotifier();
});

class ProjectListNotifier extends StateNotifier<List<Project>> {
  static const String _storageKey = 'edito_saved_projects';

  ProjectListNotifier() : super([]) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(data);
        state = decoded.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        // Provide an initial sample project for quick testing
        final sampleProject = Project(
          id: const Uuid().v4(),
          title: 'Demo Reel 2026',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
          durationMs: 14500,
          tracks: [
            Track(
              id: const Uuid().v4(),
              name: 'Main Video',
              type: TrackType.video,
              order: 0,
            ),
            Track(
              id: const Uuid().v4(),
              name: 'Soundtrack',
              type: TrackType.audio,
              order: 1,
            ),
          ],
        );
        state = [sampleProject];
        _saveToPrefs();
      }
    } catch (_) {
      // Fallback
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
    await _saveToPrefs();
    return newProj;
  }

  Future<void> deleteProject(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _saveToPrefs();
  }

  Future<void> updateProject(Project updated) async {
    state = [
      for (final p in state)
        if (p.id == updated.id) updated else p
    ];
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }
}
