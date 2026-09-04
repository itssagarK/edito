import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../editor/providers/editor_provider.dart';
import '../models/aspect_ratio_preset.dart';
import '../models/compositor_frame.dart';
import '../services/playback_clock_service.dart';
import '../services/timeline_compositor_service.dart';
import '../services/video_playback_bridge_service.dart';

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

final videoPlaybackBridgeServiceProvider = Provider<VideoPlaybackBridgeService>((ref) {
  final service = VideoPlaybackBridgeService();
  ref.onDispose(() => service.dispose());
  return service;
});

final previewPlaybackProvider = StateNotifierProvider<PreviewPlaybackNotifier, PreviewState>((ref) {
  final clock = ref.watch(playbackClockServiceProvider);
  final bridge = ref.watch(videoPlaybackBridgeServiceProvider);
  return PreviewPlaybackNotifier(clock, bridge, ref);
});

class PreviewPlaybackNotifier extends StateNotifier<PreviewState> {
  final PlaybackClockService _clock;
  final VideoPlaybackBridgeService _playbackBridge;
  final Ref _ref;

  PreviewPlaybackNotifier(this._clock, this._playbackBridge, this._ref) : super(const PreviewState()) {
    _clock.tickStream.listen((positionMs) {
      _ref.read(editorProvider.notifier).seek(positionMs);
      _updateCurrentFrame(positionMs);
    });

    // Automatically synchronize when project is loaded, mutated, or playhead moves
    _ref.listen<EditorState>(editorProvider, (previous, next) {
      final prevProject = previous?.project;
      final nextProject = next.project;
      final prevPos = previous?.playheadPositionMs;
      final nextPos = next.playheadPositionMs;
      final prevPlaying = previous?.isPlaying ?? false;
      final nextPlaying = next.isPlaying;

      if (nextProject != null) {
        if (prevProject != nextProject || (!nextPlaying && prevPos != nextPos) || prevPlaying != nextPlaying) {
          _updateCurrentFrame(nextPos);
        }
      }
    });

    // Evaluate initial frame immediately if project is already available
    final initialProject = _ref.read(editorProvider).project;
    if (initialProject != null) {
      final pos = _ref.read(editorProvider).playheadPositionMs;
      _updateCurrentFrame(pos);
    }
  }

  /// Manually forces a synchronization of the current compositor frame
  void syncCurrentFrame() {
    final editorState = _ref.read(editorProvider);
    final currentPos = editorState.playheadPositionMs;
    _updateCurrentFrame(currentPos);
  }

  void togglePlay() {
    final editorState = _ref.read(editorProvider);
    final project = editorState.project;
    if (project == null) return;

    if (editorState.isPlaying) {
      _clock.pause();
      _playbackBridge.pause();
      _ref.read(editorProvider.notifier).pause();
    } else {
      final maxDuration = project.durationMs > 0 ? project.durationMs : 30000;
      final startPos = editorState.playheadPositionMs >= maxDuration ? 0 : editorState.playheadPositionMs;

      _clock.start(startPositionMs: startPos, maxDurationMs: maxDuration);
      _ref.read(editorProvider.notifier).play();
      _playbackBridge.play();
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

    _playbackBridge.syncPlayback(
      frame: frame,
      isPlaying: _ref.read(editorProvider).isPlaying,
      timestampMs: timestampMs,
    );
  }
}
