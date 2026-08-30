import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../editor/providers/editor_provider.dart';
import '../models/aspect_ratio_preset.dart';
import '../models/compositor_frame.dart';
import '../services/playback_clock_service.dart';
import '../services/timeline_compositor_service.dart';

class PreviewState {
  final AspectRatioPreset aspectRatio;
  final bool showSafeGuides;
  final bool isBuffering;
  final CompositorFrame? currentFrame;

  const PreviewState({
    this.aspectRatio = AspectRatioPreset.ratio16x9,
    this.showSafeGuides = false,
    this.isBuffering = false,
    this.currentFrame,
  });

  PreviewState copyWith({
    AspectRatioPreset? aspectRatio,
    bool? showSafeGuides,
    bool? isBuffering,
    CompositorFrame? currentFrame,
  }) {
    return PreviewState(
      aspectRatio: aspectRatio ?? this.aspectRatio,
      showSafeGuides: showSafeGuides ?? this.showSafeGuides,
      isBuffering: isBuffering ?? this.isBuffering,
      currentFrame: currentFrame ?? this.currentFrame,
    );
  }
}

final playbackClockServiceProvider = Provider<PlaybackClockService>((ref) {
  final service = PlaybackClockService();
  ref.onDispose(() => service.dispose());
  return service;
});

final previewPlaybackProvider = StateNotifierProvider<PreviewPlaybackNotifier, PreviewState>((ref) {
  final clock = ref.watch(playbackClockServiceProvider);
  return PreviewPlaybackNotifier(clock, ref);
});

class PreviewPlaybackNotifier extends StateNotifier<PreviewState> {
  final PlaybackClockService _clock;
  final Ref _ref;

  PreviewPlaybackNotifier(this._clock, this._ref) : super(const PreviewState()) {
    _clock.tickStream.listen((positionMs) {
      _ref.read(editorProvider.notifier).seek(positionMs);
      _updateCurrentFrame(positionMs);
    });
  }

  void togglePlay() {
    final editorState = _ref.read(editorProvider);
    final project = editorState.project;
    if (project == null) return;

    if (editorState.isPlaying) {
      _clock.pause();
      _ref.read(editorProvider.notifier).pause();
    } else {
      final maxDuration = project.durationMs > 0 ? project.durationMs : 30000;
      final startPos = editorState.playheadPositionMs >= maxDuration ? 0 : editorState.playheadPositionMs;

      _clock.start(startPositionMs: startPos, maxDurationMs: maxDuration);
      _ref.read(editorProvider.notifier).play();
    }
  }

  void seek(int positionMs) {
    _clock.seek(positionMs);
    _ref.read(editorProvider.notifier).seek(positionMs);
    _updateCurrentFrame(positionMs);
  }

  void setAspectRatio(AspectRatioPreset ratio) {
    state = state.copyWith(aspectRatio: ratio);
    final currentPos = _ref.read(editorProvider).playheadPositionMs;
    _updateCurrentFrame(currentPos);
  }

  void toggleSafeGuides() {
    state = state.copyWith(showSafeGuides: !state.showSafeGuides);
  }

  void _updateCurrentFrame(int timestampMs) {
    final project = _ref.read(editorProvider).project;
    if (project == null) return;

    final frame = TimelineCompositorService.evaluateFrame(
      project,
      timestampMs,
      aspectRatio: state.aspectRatio,
    );
    state = state.copyWith(currentFrame: frame);
  }
}
