import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../models/project.dart';

class ProjectStorageService {
  static Future<Directory> get _projectsDir async {
    final docDir = await getApplicationDocumentsDirectory();
    final projectsDir = Directory(p.join(docDir.path, 'edito_projects'));
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    return projectsDir;
  }

  /// Saves a project to disk atomically using temporary file rename
  static Future<void> saveProject(Project project) async {
    try {
      final dir = await _projectsDir;
      final targetFile = File(p.join(dir.path, '${project.id}.edito.json'));
      final tempFile = File(p.join(dir.path, '${project.id}.tmp'));

      final jsonString = jsonEncode(project.toJson());
      await tempFile.writeAsString(jsonString, flush: true);
      await tempFile.rename(targetFile.path);
    } catch (_) {
      // Handle file write errors
    }
  }

  /// Loads a single project from its file
  static Future<Project?> loadProject(String projectId) async {
    try {
      final dir = await _projectsDir;
      final file = File(p.join(dir.path, '$projectId.edito.json'));
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      return Project.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Loads all saved projects on the device
  static Future<List<Project>> loadAllProjects() async {
    try {
      final dir = await _projectsDir;
      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.edito.json'));

      final projects = <Project>[];
      for (final file in files) {
        try {
          final content = await file.readAsString();
          final decoded = jsonDecode(content) as Map<String, dynamic>;
          projects.add(Project.fromJson(decoded));
        } catch (_) {
          // Skip corrupt files
        }
      }

      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return projects;
    } catch (_) {
      return [];
    }
  }

  /// Deletes a project file from storage
  static Future<void> deleteProject(String projectId) async {
    try {
      final dir = await _projectsDir;
      final file = File(p.join(dir.path, '$projectId.edito.json'));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
