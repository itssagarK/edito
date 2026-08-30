import '../../../models/project.dart';

class HistoryManagerService {
  final int maxHistoryLength;
  final List<Project> _undoStack = [];
  final List<Project> _redoStack = [];

  HistoryManagerService({this.maxHistoryLength = 50});

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  /// Pushes the previous project state before a mutation occurs
  void pushState(Project previousState) {
    _undoStack.add(previousState);
    if (_undoStack.length > maxHistoryLength) {
      _undoStack.removeAt(0); // Evict oldest state to conserve memory
    }
    _redoStack.clear(); // Any new mutation invalidates the redo branch
  }

  /// Undoes the last mutation, returning the previous project snapshot
  Project? undo(Project currentState) {
    if (_undoStack.isEmpty) return null;

    final targetState = _undoStack.removeLast();
    _redoStack.add(currentState);

    return targetState;
  }

  /// Redoes the last undone mutation, returning the next project snapshot
  Project? redo(Project currentState) {
    if (_redoStack.isEmpty) return null;

    final targetState = _redoStack.removeLast();
    _undoStack.add(currentState);

    return targetState;
  }

  /// Clears all undo/redo history (e.g. when opening a new project)
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
