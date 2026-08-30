import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/project.dart';
import 'package:edito/features/history/services/history_manager_service.dart';

void main() {
  group('HistoryManagerService Undo/Redo Engine Tests', () {
    late Project p1;
    late Project p2;
    late Project p3;

    setUp(() {
      final now = DateTime.now();
      p1 = Project(id: 'p1', title: 'State 1', createdAt: now, updatedAt: now);
      p2 = Project(id: 'p2', title: 'State 2', createdAt: now, updatedAt: now);
      p3 = Project(id: 'p3', title: 'State 3', createdAt: now, updatedAt: now);
    });

    test('Initial history is empty', () {
      final history = HistoryManagerService();
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
      expect(history.undoCount, equals(0));
      expect(history.redoCount, equals(0));
    });

    test('Pushing states enables undo and clears redo', () {
      final history = HistoryManagerService();
      history.pushState(p1);

      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
      expect(history.undoCount, equals(1));
    });

    test('Undo retrieves previous snapshot and enables redo', () {
      final history = HistoryManagerService();
      history.pushState(p1);

      final restored = history.undo(p2);
      expect(restored?.title, equals('State 1'));
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isTrue);
      expect(history.redoCount, equals(1));
    });

    test('Redo retrieves undone snapshot and reenables undo', () {
      final history = HistoryManagerService();
      history.pushState(p1);

      final undone = history.undo(p2);
      expect(undone?.title, equals('State 1'));

      final redone = history.redo(p1);
      expect(redone?.title, equals('State 2'));
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
    });

    test('Pushing a new state after undo clears the redo branch', () {
      final history = HistoryManagerService();
      history.pushState(p1);
      history.pushState(p2);

      // Undo p2 -> p1
      history.undo(p3);
      expect(history.canRedo, isTrue);

      // Now user performs a new mutation instead of redo
      final p4 = Project(id: 'p4', title: 'State 4', createdAt: DateTime.now(), updatedAt: DateTime.now());
      history.pushState(p4);

      expect(history.canRedo, isFalse);
      expect(history.redoCount, equals(0));
    });

    test('History stack honors maxHistoryLength capacity limit', () {
      final history = HistoryManagerService(maxHistoryLength: 5);
      final now = DateTime.now();

      for (int i = 0; i < 10; i++) {
        history.pushState(Project(id: 'p_$i', title: 'State $i', createdAt: now, updatedAt: now));
      }

      expect(history.undoCount, equals(5));
      // Oldest remaining should be State 5
      final oldest = history.undo(p1);
      expect(oldest?.title, equals('State 9'));
    });
  });
}
