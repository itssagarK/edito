import 'dart:math';
import '../../../models/clip.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';

/// Summary of detected micro-gaps and black flash intervals across timeline tracks.
class GapAnalysisResult {
  final int totalGapsFound;
  final int totalGapDurationMs;
  final Map<String, List<List<int>>> gapsByTrack; // trackId -> List of [gapStart, gapEnd]

  const GapAnalysisResult({
    required this.totalGapsFound,
    required this.totalGapDurationMs,
    required this.gapsByTrack,
  });

  bool get hasGaps => totalGapsFound > 0;
}

/// 100% Offline, Deterministic Timeline Micro-Gap Finder & Ripple Closer Service.
///
/// Eliminates accidental 1-frame to 15-frame black flashes and blank pauses
/// caused by imprecise touch dragging on multi-track timelines.
class GapCloserService {
  /// Analyzes all tracks in the project for accidental empty gaps between clips.
  static GapAnalysisResult analyzeGaps(
    Project project, {
    int minGapMs = 15,
    int maxGapMs = 2000,
  }) {
    int totalGaps = 0;
    int totalGapMs = 0;
    final gapsByTrack = <String, List<List<int>>>{};

    for (final track in project.tracks) {
      if (track.clips.length < 2) continue;

      final sorted = List<Clip>.from(track.clips)..sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));
      final trackGaps = <List<int>>[];

      for (int i = 0; i < sorted.length - 1; i++) {
        final currentEnd = sorted[i].startTimeMs + sorted[i].durationMs;
        final nextStart = sorted[i + 1].startTimeMs;
        final gap = nextStart - currentEnd;

        if (gap >= minGapMs && gap <= maxGapMs) {
          trackGaps.add([currentEnd, nextStart]);
          totalGaps++;
          totalGapMs += gap;
        }
      }

      if (trackGaps.isNotEmpty) {
        gapsByTrack[track.id] = trackGaps;
      }
    }

    return GapAnalysisResult(
      totalGapsFound: totalGaps,
      totalGapDurationMs: totalGapMs,
      gapsByTrack: gapsByTrack,
    );
  }

  /// Compacts timeline tracks by rippling clips backwards to eliminate micro-gaps.
  static Project? closeAllGaps(
    Project project, {
    int minGapMs = 15,
    int maxGapMs = 2000,
  }) {
    final analysis = analyzeGaps(project, minGapMs: minGapMs, maxGapMs: maxGapMs);
    if (!analysis.hasGaps) return null;

    final updatedTracks = <Track>[];

    for (final track in project.tracks) {
      if (track.clips.length < 2) {
        updatedTracks.add(track);
        continue;
      }

      final sorted = List<Clip>.from(track.clips)..sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));
      final compacted = <Clip>[];

      int runningOffset = 0;
      int previousEnd = 0;

      for (int i = 0; i < sorted.length; i++) {
        final c = sorted[i];
        if (i == 0) {
          compacted.add(c);
          previousEnd = c.startTimeMs + c.durationMs;
          continue;
        }

        final originalStart = c.startTimeMs;
        final currentGap = originalStart - previousEnd;

        if (currentGap >= minGapMs && currentGap <= maxGapMs) {
          // Accumulate the gap to shift this and subsequent clips left
          runningOffset += currentGap;
        }

        final newStart = max(0, originalStart - runningOffset);
        final shiftedClip = c.copyWith(startTimeMs: newStart);
        compacted.add(shiftedClip);
        previousEnd = newStart + shiftedClip.durationMs;
      }

      updatedTracks.add(track.copyWith(clips: compacted));
    }

    return project.copyWith(tracks: updatedTracks).recalculateDuration();
  }
}
