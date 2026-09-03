import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/project.dart';
import '../../history/services/history_manager_service.dart';

enum EditorTool {
  select,
  split,
  trim,
  smooth,
  audio,
  color,
  text,
  captions,
  effects,
  speed,
  enhance,
  chromaKey,
  imageEditor,
}

class EditorState {
  final Project? project;
  final int playheadPositionMs;
  final bool isPlaying;
  final double zoomScale;
  final String? selectedClipId;
  final String? selectedTrackId;
  final EditorTool activeTool;
  final bool canUndo;
  final bool canRedo;

  const EditorState({
    this.project,
    this.playheadPositionMs = 0,
    this.isPlaying = false,
    this.zoomScale = 1.0,
    this.selectedClipId,
    this.selectedTrackId,
    this.activeTool = EditorTool.select,
    this.canUndo = false,
    this.canRedo = false,
  });

  EditorState copyWith({
    Project? project,
    int? playheadPositionMs,
    bool? isPlaying,
    double? zoomScale,
    String? selectedClipId,
    String? selectedTrackId,
    EditorTool? activeTool,
    bool? canUndo,
    bool? canRedo,
    bool clearSelectedClip = false,
  }) {
    return EditorState(
      project: project ?? this.project,
      playheadPositionMs: playheadPositionMs ?? this.playheadPositionMs,
      isPlaying: isPlaying ?? this.isPlaying,
      zoomScale: zoomScale ?? this.zoomScale,
      selectedClipId: clearSelectedClip ? null : (selectedClipId ?? this.selectedClipId),
      selectedTrackId: selectedTrackId ?? this.selectedTrackId,
      activeTool: activeTool ?? this.activeTool,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

class EditorNotifier extends StateNotifier<EditorState> {
  final HistoryManagerService _history = HistoryManagerService();

  EditorNotifier() : super(const EditorState());

  void initProject(Project project) {
    _history.clear();
    state = EditorState(
      project: project,
      playheadPositionMs: 0,
      isPlaying: false,
      canUndo: false,
      canRedo: false,
    );
  }

  void updateProject(Project newProject) {
    if (state.project != null) {
      _history.pushState(state.project!);
    }
    state = state.copyWith(
      project: newProject,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
    );
  }

  void undo() {
    if (!_history.canUndo || state.project == null) return;

    final targetState = _history.undo(state.project!);
    if (targetState != null) {
      state = state.copyWith(
        project: targetState,
        canUndo: _history.canUndo,
        canRedo: _history.canRedo,
      );
    }
  }

  void redo() {
    if (!_history.canRedo || state.project == null) return;

    final targetState = _history.redo(state.project!);
    if (targetState != null) {
      state = state.copyWith(
        project: targetState,
        canUndo: _history.canUndo,
        canRedo: _history.canRedo,
      );
    }
  }

  void seek(int positionMs) {
    final maxDuration = state.project?.durationMs ?? 0;
    final clamped = positionMs.clamp(0, maxDuration > 0 ? maxDuration : 600000);
    state = state.copyWith(playheadPositionMs: clamped);
  }

  void togglePlay() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  void pause() {
    state = state.copyWith(isPlaying: false);
  }

  void play() {
    state = state.copyWith(isPlaying: true);
  }

  void setZoom(double zoom) {
    final clamped = zoom.clamp(0.2, 5.0);
    state = state.copyWith(zoomScale: clamped);
  }

  void selectClip(String? clipId, {String? trackId}) {
    if (clipId == null) {
      state = state.copyWith(clearSelectedClip: true, selectedTrackId: null);
    } else {
      state = state.copyWith(selectedClipId: clipId, selectedTrackId: trackId);
    }
  }

  void setActiveTool(EditorTool tool) {
    state = state.copyWith(activeTool: tool);
  }
}
