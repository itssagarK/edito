# Phase 9 Specification — Global Undo/Redo Engine & Performance Optimization

## 1. Objectives
1. Implement the **Global Undo/Redo History Engine** (`HistoryManagerService`):
   - Command pattern state stack storing non-destructive immutable `Project` snapshots.
   - Configurable history capacity (up to 50 undo levels) with LRU eviction to prevent memory bloat.
   - True multi-level `undo()` and `redo()` support across all project mutations (cuts, trims, transitions, color grades, speed changes, text overlays, audio filters).
   - Reactive `canUndo` and `canRedo` states dynamically enabling/disabling UI buttons in `EditorAppBar`.
2. Implement **Debounced Auto-Save & Crash Recovery** (`AutoSaveService`):
   - Flushes dirty project states to atomic disk storage 500ms after the last user interaction.
3. Implement **Performance & Memory Optimization**:
   - Zero-overhead state snapshots using Dart's immutable structural sharing.

---

## 2. Public Interface Contracts (Frozen)

### 2.1 `HistoryManagerService`
```dart
class HistoryManagerService {
  void pushState(Project project);
  Project? undo(Project currentProject);
  Project? redo(Project currentProject);
  bool get canUndo;
  bool get canRedo;
  void clear();
}
```

### 2.2 `EditorState` Integration
```dart
class EditorState {
  final Project? project;
  final bool canUndo;
  final bool canRedo;
  ...
}
```

---

## 3. Acceptance Criteria
- [x] Every timeline edit, split, trim, audio change, LUT adjustment, and text edit pushes a historical snapshot.
- [x] Tapping Undo restores previous project state frame-accurately and updates `canUndo`/`canRedo`.
- [x] Tapping Redo restores the undone state.
- [x] Pushing a new mutation after an undo clears the redo stack.
- [x] Unit tests verify 100% of undo/redo stack transitions, stack limits, and state integrity.
