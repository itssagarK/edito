import 'dart:math' as math;
import '../../../../models/clip.dart';
import '../models/transition_type.dart';

/// Compiler service that generates deterministic FFmpeg xfade filter graphs
/// and calculates timeline transition offsets for multi-clip video export.
class TransitionCompilerService {
  /// Generates the standard single-point FFmpeg xfade filter expression
  static String generateFFmpegXFade(
    TransitionConfig config, {
    required double offsetSec,
  }) {
    if (!config.isEnabled) return '';

    final transitionName = config.type.ffmpegXFadeName;
    if (transitionName.isEmpty) return '';

    final durationSec = (config.durationMs / 1000.0).toStringAsFixed(2);
    final offsetStr = math.max(0.0, offsetSec).toStringAsFixed(2);

    return 'xfade=transition=$transitionName:duration=$durationSec:offset=$offsetStr';
  }

  /// Calculates the effective time overlap in milliseconds required for a transition
  static int calculateOverlapMs(TransitionConfig config) {
    if (!config.isEnabled) return 0;
    return config.durationMs.clamp(100, 3000);
  }

  /// Compiles a complete multi-clip timeline transition chain into an FFmpeg filtergraph
  /// Example output:
  ///   [0:v][1:v]xfade=transition=fade:duration=0.50:offset=4.50[v01];
  ///   [v01][2:v]xfade=transition=wipeleft:duration=0.60:offset=9.40[outv]
  static TimelineTransitionResult compileTimelineTransitions(List<Clip> clips) {
    if (clips.length < 2) {
      return const TimelineTransitionResult(
        filterGraph: '',
        outputLabel: '',
        totalDurationMs: 0,
        transitionCount: 0,
      );
    }

    final buffer = StringBuffer();
    var currentInputLabel = '[0:v]';
    var accumulatedDurationMs = clips.first.durationMs;
    var transitionsApplied = 0;

    for (int i = 1; i < clips.length; i++) {
      final prevClip = clips[i - 1];
      final currentClip = clips[i];

      // Transition is defined on incoming clip or outgoing clip
      final transition = currentClip.transitionIn.isEnabled
          ? currentClip.transitionIn
          : prevClip.transitionOut;

      if (!transition.isEnabled) {
        // Direct cut without xfade filter: accumulate duration
        accumulatedDurationMs += currentClip.durationMs;
        continue;
      }

      final transitionDurMs = transition.durationMs.clamp(100, math.min(prevClip.durationMs, currentClip.durationMs));
      final offsetSec = math.max(0.0, (accumulatedDurationMs - transitionDurMs) / 1000.0);
      final durationSec = (transitionDurMs / 1000.0).toStringAsFixed(2);
      final transitionName = transition.type.ffmpegXFadeName;

      final outputLabel = i == clips.length - 1 ? '[outv]' : '[v_trans_$i]';

      if (transitionsApplied > 0) {
        buffer.write(';');
      }

      buffer.write(
        '$currentInputLabel[$i:v]xfade=transition=$transitionName:duration=$durationSec:offset=${offsetSec.toStringAsFixed(2)}$outputLabel',
      );

      currentInputLabel = outputLabel;
      accumulatedDurationMs = (accumulatedDurationMs - transitionDurMs) + currentClip.durationMs;
      transitionsApplied++;
    }

    return TimelineTransitionResult(
      filterGraph: buffer.toString(),
      outputLabel: transitionsApplied > 0 ? currentInputLabel : '',
      totalDurationMs: accumulatedDurationMs,
      transitionCount: transitionsApplied,
    );
  }

  /// Human-readable UI badge for active transition
  static String getTransitionBadge(TransitionConfig config) {
    if (!config.isEnabled) return 'No Transition';
    return '${config.type.label} (${(config.durationMs / 1000.0).toStringAsFixed(1)}s)';
  }
}

/// Metadata result from compiling a timeline's transitions
class TimelineTransitionResult {
  final String filterGraph;
  final String outputLabel;
  final int totalDurationMs;
  final int transitionCount;

  const TimelineTransitionResult({
    required this.filterGraph,
    required this.outputLabel,
    required this.totalDurationMs,
    required this.transitionCount,
  });

  bool get hasTransitions => transitionCount > 0 && filterGraph.isNotEmpty;
}
