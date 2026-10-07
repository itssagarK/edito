import '../../../models/clip.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import '../../timeline/services/timeline_editing_service.dart';

class BeatCutResult {
  final Project project;
  final int cutsCreated;
  final int beatsProcessed;

  const BeatCutResult({
    required this.project,
    required this.cutsCreated,
    required this.beatsProcessed,
  });
}

class BeatCutterService {
  /// Scans the project for any audio/video clips containing active beat markers
  /// and returns a sorted list of unique timeline beat timestamps in milliseconds.
  static List<int> gatherProjectBeats(Project project) {
    final beatSet = <int>{};

    for (final track in project.tracks) {
      if (track.isHidden) continue;
      for (final clip in track.clips) {
        if (clip.beatConfig.hasBeats) {
          for (final b in clip.beatConfig.beatTimestampsMs) {
            final timelineBeatMs = clip.startTimeMs + b;
            if (timelineBeatMs >= 0 && timelineBeatMs <= project.durationMs) {
              beatSet.add(timelineBeatMs);
            }
          }
        }
      }
    }

    final sortedBeats = beatSet.toList()..sort();
    return sortedBeats;
  }

  /// Generates synthetic tempo grid beat timestamps aligned to a target BPM
  static List<int> generateTempoGridBeats({
    required double bpm,
    required int durationMs,
    int startOffsetMs = 0,
  }) {
    if (bpm <= 20 || durationMs <= 0) return const [];

    final intervalMs = (60000.0 / bpm).round().clamp(100, 5000);
    final beats = <int>[];

    int t = startOffsetMs;
    while (t < durationMs) {
      if (t >= 0) {
        beats.add(t);
      }
      t += intervalMs;
    }

    return beats;
  }

  /// Automatically splits video clips on the specified track at musical beat intervals.
  ///
  /// [beatCadence]: 1 = every beat, 2 = every 2nd beat (half-time), 4 = every 4th beat (downbeats).
  /// [minClipDurationMs]: Prevents creating micro-clips shorter than this threshold (default 250ms).
  static BeatCutResult cutTrackOnBeats({
    required Project project,
    required String trackId,
    required List<int> beatTimestampsMs,
    int beatCadence = 1,
    int minClipDurationMs = 250,
  }) {
    if (beatTimestampsMs.isEmpty) {
      return BeatCutResult(project: project, cutsCreated: 0, beatsProcessed: 0);
    }

    // Filter beats according to cadence (e.g. step by 1, 2, or 4)
    final cadenceBeats = <int>[];
    for (int i = 0; i < beatTimestampsMs.length; i++) {
      if (i % beatCadence == 0) {
        cadenceBeats.add(beatTimestampsMs[i]);
      }
    }

    var currentProject = project;
    int cutsCreated = 0;

    for (final beatMs in cadenceBeats) {
      // Find the track and clip that spans across beatMs
      Track? targetTrack;
      Clip? clipToSplit;

      for (final track in currentProject.tracks) {
        if (track.id == trackId) {
          targetTrack = track;
          for (final clip in track.clips) {
            final clipStart = clip.startTimeMs;
            final clipEnd = clip.startTimeMs + clip.durationMs;

            // Must fall strictly inside the clip with safe padding on both ends
            if (beatMs >= clipStart + minClipDurationMs && beatMs <= clipEnd - minClipDurationMs) {
              clipToSplit = clip;
              break;
            }
          }
          break;
        }
      }

      if (targetTrack != null && clipToSplit != null) {
        final updatedProject = TimelineEditingService.splitClip(
          currentProject,
          clipToSplit.id,
          beatMs,
        );

        if (updatedProject != null) {
          currentProject = updatedProject;
          cutsCreated++;
        }
      }
    }

    return BeatCutResult(
      project: currentProject,
      cutsCreated: cutsCreated,
      beatsProcessed: cadenceBeats.length,
    );
  }

  /// Snaps existing clip boundaries (cuts) on the track to the nearest musical beat within tolerance.
  static Project snapClipsToBeats({
    required Project project,
    required String trackId,
    required List<int> beatTimestampsMs,
    int snapToleranceMs = 150,
  }) {
    if (beatTimestampsMs.isEmpty) return project;

    var currentProject = project;

    // Scan track clips
    Track? track;
    for (final t in currentProject.tracks) {
      if (t.id == trackId) {
        track = t;
        break;
      }
    }

    if (track == null || track.clips.length <= 1) return project;

    // We check internal boundaries between consecutive clips
    for (int i = 0; i < track.clips.length - 1; i++) {
      final clip = track.clips[i];
      final cutPointMs = clip.startTimeMs + clip.durationMs;

      // Find closest beat
      int? closestBeat;
      int minDiff = snapToleranceMs + 1;

      for (final b in beatTimestampsMs) {
        final diff = (b - cutPointMs).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestBeat = b;
        }
      }

      if (closestBeat != null && minDiff <= snapToleranceMs && closestBeat != cutPointMs) {
        // Adjust the cut point by trimming tail of current clip to closestBeat
        final trimmed = TimelineEditingService.trimClipTail(
          currentProject,
          clip.id,
          closestBeat,
          ripple: true,
        );
        if (trimmed != null) {
          currentProject = trimmed;
        }
      }
    }

    return currentProject;
  }
}
