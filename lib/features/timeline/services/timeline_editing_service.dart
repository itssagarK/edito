import 'package:uuid/uuid.dart';
import '../../../models/clip.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';

class TimelineEditingService {
  static const int minClipDurationMs = 100;

  /// Splits a clip at the specified playhead position into two contiguous clips
  static Project? splitClip(Project project, String clipId, int splitPositionMs) {
    Track? targetTrack;
    Clip? targetClip;

    for (final track in project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) {
          targetTrack = track;
          targetClip = clip;
          break;
        }
      }
      if (targetClip != null) break;
    }

    if (targetTrack == null || targetClip == null) return null;

    final clipStart = targetClip.startTimeMs;
    final clipEnd = targetClip.startTimeMs + targetClip.durationMs;

    // Split position must be strictly inside the clip boundaries
    if (splitPositionMs <= clipStart + minClipDurationMs || splitPositionMs >= clipEnd - minClipDurationMs) {
      return null;
    }

    final splitOffset = splitPositionMs - clipStart;
    final sourceSplitPoint = targetClip.sourceInMs + (splitOffset * targetClip.speed).round();

    // First half
    final firstHalf = targetClip.copyWith(
      durationMs: splitOffset,
      sourceOutMs: sourceSplitPoint,
    );

    // Second half
    final secondHalf = Clip(
      id: const Uuid().v4(),
      assetId: targetClip.assetId,
      trackId: targetTrack.id,
      startTimeMs: splitPositionMs,
      durationMs: targetClip.durationMs - splitOffset,
      sourceInMs: sourceSplitPoint,
      sourceOutMs: targetClip.sourceOutMs,
      volume: targetClip.volume,
      speed: targetClip.speed,
      isMuted: targetClip.isMuted,
    );

    // Replace in track
    final updatedClips = <Clip>[];
    for (final clip in targetTrack.clips) {
      if (clip.id == clipId) {
        updatedClips.add(firstHalf);
        updatedClips.add(secondHalf);
      } else {
        updatedClips.add(clip);
      }
    }

    final updatedTrack = targetTrack.copyWith(clips: updatedClips);
    final updatedTracks = project.tracks.map((t) => t.id == updatedTrack.id ? updatedTrack : t).toList();

    return project.copyWith(tracks: updatedTracks).recalculateDuration();
  }

  /// Trims the head (start) of a clip
  static Project? trimClipHead(Project project, String clipId, int newStartMs) {
    if (newStartMs < 0) return null;

    for (final track in project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) {
          final clipEnd = clip.startTimeMs + clip.durationMs;
          if (newStartMs >= clipEnd - minClipDurationMs) return null;

          final deltaMs = newStartMs - clip.startTimeMs;
          final newDurationMs = clip.durationMs - deltaMs;
          final newSourceInMs = clip.sourceInMs + (deltaMs * clip.speed).round();

          if (newSourceInMs < 0 || newSourceInMs >= clip.sourceOutMs) return null;

          final updatedClip = clip.copyWith(
            startTimeMs: newStartMs,
            durationMs: newDurationMs,
            sourceInMs: newSourceInMs,
          );

          return project.updateClip(updatedClip);
        }
      }
    }
    return null;
  }

  /// Trims the tail (end) of a clip
  static Project? trimClipTail(Project project, String clipId, int newEndMs) {
    for (final track in project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) {
          if (newEndMs <= clip.startTimeMs + minClipDurationMs) return null;

          final newDurationMs = newEndMs - clip.startTimeMs;
          final newSourceOutMs = clip.sourceInMs + (newDurationMs * clip.speed).round();

          final updatedClip = clip.copyWith(
            durationMs: newDurationMs,
            sourceOutMs: newSourceOutMs,
          );

          return project.updateClip(updatedClip);
        }
      }
    }
    return null;
  }

  /// Moves a clip to a new start time or track
  static Project moveClip(Project project, String clipId, String targetTrackId, int newStartTimeMs) {
    final clampedStart = newStartTimeMs < 0 ? 0 : newStartTimeMs;

    Clip? movingClip;
    for (final track in project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) {
          movingClip = clip;
          break;
        }
      }
      if (movingClip != null) break;
    }

    if (movingClip == null) return project;

    // Remove from original track
    var currentProject = project.removeClip(clipId);

    // Add to target track with new startTimeMs
    final updatedClip = movingClip.copyWith(
      trackId: targetTrackId,
      startTimeMs: clampedStart,
    );

    return currentProject.addClipToTrack(targetTrackId, updatedClip);
  }

  /// Duplicates a clip and inserts it immediately after the original
  static Project duplicateClip(Project project, String clipId) {
    Clip? originalClip;
    Track? parentTrack;

    for (final track in project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) {
          originalClip = clip;
          parentTrack = track;
          break;
        }
      }
      if (originalClip != null) break;
    }

    if (originalClip == null || parentTrack == null) return project;

    final newClip = Clip(
      id: const Uuid().v4(),
      assetId: originalClip.assetId,
      trackId: originalClip.trackId,
      startTimeMs: originalClip.startTimeMs + originalClip.durationMs,
      durationMs: originalClip.durationMs,
      sourceInMs: originalClip.sourceInMs,
      sourceOutMs: originalClip.sourceOutMs,
      volume: originalClip.volume,
      speed: originalClip.speed,
      isMuted: originalClip.isMuted,
    );

    return project.addClipToTrack(parentTrack.id, newClip);
  }

  /// Deletes a clip, optionally rippling subsequent clips to the left
  static Project deleteClip(Project project, String clipId, {bool ripple = false}) {
    if (!ripple) {
      return project.removeClip(clipId);
    }

    Clip? toDelete;
    Track? targetTrack;

    for (final track in project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) {
          toDelete = clip;
          targetTrack = track;
          break;
        }
      }
      if (toDelete != null) break;
    }

    if (toDelete == null || targetTrack == null) return project;

    final deleteEnd = toDelete.startTimeMs + toDelete.durationMs;
    final durationToShift = toDelete.durationMs;

    final updatedClips = <Clip>[];
    for (final clip in targetTrack.clips) {
      if (clip.id == clipId) continue;
      if (clip.startTimeMs >= deleteEnd) {
        updatedClips.add(clip.copyWith(startTimeMs: clip.startTimeMs - durationToShift));
      } else {
        updatedClips.add(clip);
      }
    }

    final updatedTrack = targetTrack.copyWith(clips: updatedClips);
    final updatedTracks = project.tracks.map((t) => t.id == updatedTrack.id ? updatedTrack : t).toList();

    return project.copyWith(tracks: updatedTracks).recalculateDuration();
  }

  /// Calculates magnetic snapping to clip start/end boundaries and playhead
  static int calculateSnapTime(
    Project project,
    int targetTimeMs, {
    int thresholdMs = 150,
    String? ignoreClipId,
  }) {
    int closestPoint = targetTimeMs;
    int minDiff = thresholdMs + 1;

    final snapPoints = <int>{0, project.durationMs};

    for (final track in project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == ignoreClipId) continue;
        snapPoints.add(clip.startTimeMs);
        snapPoints.add(clip.startTimeMs + clip.durationMs);
      }
    }

    for (final point in snapPoints) {
      final diff = (targetTimeMs - point).abs();
      if (diff <= thresholdMs && diff < minDiff) {
        minDiff = diff;
        closestPoint = point;
      }
    }

    return closestPoint;
  }
}
