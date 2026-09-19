import 'package:uuid/uuid.dart';
import '../../../models/clip.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';

class SnapResult {
  final int snappedTimeMs;
  final bool isSnapped;
  final String? snapTarget;

  const SnapResult({
    required this.snappedTimeMs,
    required this.isSnapped,
    this.snapTarget,
  });
}

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

  /// Trims the head (start) of a clip, optionally rippling subsequent clips
  static Project? trimClipHead(Project project, String clipId, int newStartMs, {bool ripple = false}) {
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
            startTimeMs: ripple ? clip.startTimeMs : newStartMs,
            durationMs: newDurationMs,
            sourceInMs: newSourceInMs,
          );

          if (!ripple) {
            return project.updateClip(updatedClip);
          }

          final updatedClips = <Clip>[];
          for (final c in track.clips) {
            if (c.id == clipId) {
              updatedClips.add(updatedClip);
            } else if (c.startTimeMs > clip.startTimeMs) {
              updatedClips.add(c.copyWith(startTimeMs: (c.startTimeMs - deltaMs).clamp(0, 3600000)));
            } else {
              updatedClips.add(c);
            }
          }

          final updatedTrack = track.copyWith(clips: updatedClips);
          final updatedTracks = project.tracks.map((t) => t.id == updatedTrack.id ? updatedTrack : t).toList();
          return project.copyWith(tracks: updatedTracks).recalculateDuration();
        }
      }
    }
    return null;
  }

  /// Trims the tail (end) of a clip, optionally rippling subsequent clips
  static Project? trimClipTail(Project project, String clipId, int newEndMs, {bool ripple = false}) {
    for (final track in project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) {
          if (newEndMs <= clip.startTimeMs + minClipDurationMs) return null;

          final newDurationMs = newEndMs - clip.startTimeMs;
          final deltaDuration = newDurationMs - clip.durationMs;
          final newSourceOutMs = clip.sourceInMs + (newDurationMs * clip.speed).round();

          final updatedClip = clip.copyWith(
            durationMs: newDurationMs,
            sourceOutMs: newSourceOutMs,
          );

          if (!ripple) {
            return project.updateClip(updatedClip);
          }

          final updatedClips = <Clip>[];
          for (final c in track.clips) {
            if (c.id == clipId) {
              updatedClips.add(updatedClip);
            } else if (c.startTimeMs > clip.startTimeMs) {
              updatedClips.add(c.copyWith(startTimeMs: (c.startTimeMs + deltaDuration).clamp(0, 3600000)));
            } else {
              updatedClips.add(c);
            }
          }

          final updatedTrack = track.copyWith(clips: updatedClips);
          final updatedTracks = project.tracks.map((t) => t.id == updatedTrack.id ? updatedTrack : t).toList();
          return project.copyWith(tracks: updatedTracks).recalculateDuration();
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

  /// Calculates magnetic snapping to clip boundaries, playhead, and rhythm beat markers with detailed metadata
  static SnapResult calculateDetailedSnap(
    Project project,
    int targetTimeMs, {
    int thresholdMs = 150,
    String? ignoreClipId,
    List<int>? customSnapPoints,
    int? playheadMs,
  }) {
    int closestPoint = targetTimeMs;
    int minDiff = thresholdMs + 1;
    String? snapTarget;

    final snapPoints = <int, String>{
      0: 'Start (0s)',
      if (project.durationMs > 0) project.durationMs: 'Project End',
    };

    if (playheadMs != null) {
      snapPoints[playheadMs] = 'Playhead';
    }

    if (customSnapPoints != null) {
      for (final p in customSnapPoints) {
        snapPoints[p] = 'Marker';
      }
    }

    for (final track in project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == ignoreClipId) continue;
        snapPoints[clip.startTimeMs] = 'Clip Head';
        snapPoints[clip.startTimeMs + clip.durationMs] = 'Clip Tail';

        // Magnetic Snapping to Beat Markers
        if (clip.beatConfig.hasBeats && clip.beatConfig.snapToBeats) {
          for (final beatMs in clip.beatConfig.beatTimestampsMs) {
            final absBeatMs = clip.startTimeMs + beatMs;
            if (absBeatMs >= clip.startTimeMs && absBeatMs <= clip.startTimeMs + clip.durationMs) {
              snapPoints[absBeatMs] = 'Beat';
            }
          }
        }
      }
    }

    for (final entry in snapPoints.entries) {
      final diff = (targetTimeMs - entry.key).abs();
      if (diff <= thresholdMs && diff < minDiff) {
        minDiff = diff;
        closestPoint = entry.key;
        snapTarget = entry.value;
      }
    }

    final isSnapped = minDiff <= thresholdMs;
    return SnapResult(
      snappedTimeMs: isSnapped ? closestPoint : targetTimeMs,
      isSnapped: isSnapped,
      snapTarget: isSnapped ? snapTarget : null,
    );
  }

  /// Calculates magnetic snapping to clip start/end boundaries, playhead, and rhythm beat markers
  static int calculateSnapTime(
    Project project,
    int targetTimeMs, {
    int thresholdMs = 150,
    String? ignoreClipId,
    List<int>? customSnapPoints,
  }) {
    return calculateDetailedSnap(
      project,
      targetTimeMs,
      thresholdMs: thresholdMs,
      ignoreClipId: ignoreClipId,
      customSnapPoints: customSnapPoints,
    ).snappedTimeMs;
  }

  /// Inserts a freeze frame clip at playhead position, splitting the clip and rippling subsequent clips
  static Project? freezeFrame(
    Project project,
    String clipId,
    int playheadMs, {
    int freezeDurationMs = 3000,
  }) {
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
    final offsetMs = (playheadMs - clipStart).clamp(0, targetClip.durationMs);
    final freezeSourceMs = targetClip.sourceInMs + (offsetMs * targetClip.speed).round();

    final updatedClips = <Clip>[];

    if (offsetMs > minClipDurationMs && offsetMs < targetClip.durationMs - minClipDurationMs) {
      // Split mid-clip: First Half -> Freeze Frame -> Second Half
      final firstHalf = targetClip.copyWith(
        durationMs: offsetMs,
        sourceOutMs: freezeSourceMs,
      );

      final freezeClip = Clip(
        id: const Uuid().v4(),
        assetId: targetClip.assetId,
        trackId: targetTrack.id,
        startTimeMs: playheadMs,
        durationMs: freezeDurationMs,
        sourceInMs: freezeSourceMs,
        sourceOutMs: freezeSourceMs + 40,
        volume: 0.0,
        speed: 1.0,
        isMuted: true,
        isFreezeFrame: true,
        freezeSourceMs: freezeSourceMs,
        colorGrading: targetClip.colorGrading,
        border: targetClip.border,
        headerFooter: targetClip.headerFooter,
        mask: targetClip.mask,
        blendMode: targetClip.blendMode,
      );

      final secondHalf = Clip(
        id: const Uuid().v4(),
        assetId: targetClip.assetId,
        trackId: targetTrack.id,
        startTimeMs: playheadMs + freezeDurationMs,
        durationMs: targetClip.durationMs - offsetMs,
        sourceInMs: freezeSourceMs,
        sourceOutMs: targetClip.sourceOutMs,
        volume: targetClip.volume,
        speed: targetClip.speed,
        isMuted: targetClip.isMuted,
        audioEffects: targetClip.audioEffects,
        colorGrading: targetClip.colorGrading,
        border: targetClip.border,
        headerFooter: targetClip.headerFooter,
        mask: targetClip.mask,
        blendMode: targetClip.blendMode,
      );

      for (final clip in targetTrack.clips) {
        if (clip.id == clipId) {
          updatedClips.add(firstHalf);
          updatedClips.add(freezeClip);
          updatedClips.add(secondHalf);
        } else if (clip.startTimeMs >= clipEnd) {
          updatedClips.add(clip.copyWith(startTimeMs: clip.startTimeMs + freezeDurationMs));
        } else {
          updatedClips.add(clip);
        }
      }
    } else if (offsetMs <= minClipDurationMs) {
      // Insert at head of clip
      final freezeClip = Clip(
        id: const Uuid().v4(),
        assetId: targetClip.assetId,
        trackId: targetTrack.id,
        startTimeMs: clipStart,
        durationMs: freezeDurationMs,
        sourceInMs: targetClip.sourceInMs,
        sourceOutMs: targetClip.sourceInMs + 40,
        volume: 0.0,
        speed: 1.0,
        isMuted: true,
        isFreezeFrame: true,
        freezeSourceMs: targetClip.sourceInMs,
        colorGrading: targetClip.colorGrading,
        border: targetClip.border,
        headerFooter: targetClip.headerFooter,
        mask: targetClip.mask,
        blendMode: targetClip.blendMode,
      );

      for (final clip in targetTrack.clips) {
        if (clip.id == clipId) {
          updatedClips.add(freezeClip);
          updatedClips.add(clip.copyWith(startTimeMs: clip.startTimeMs + freezeDurationMs));
        } else if (clip.startTimeMs >= clipStart) {
          updatedClips.add(clip.copyWith(startTimeMs: clip.startTimeMs + freezeDurationMs));
        } else {
          updatedClips.add(clip);
        }
      }
    } else {
      // Insert at tail of clip
      final freezeClip = Clip(
        id: const Uuid().v4(),
        assetId: targetClip.assetId,
        trackId: targetTrack.id,
        startTimeMs: clipEnd,
        durationMs: freezeDurationMs,
        sourceInMs: targetClip.sourceOutMs > 40 ? targetClip.sourceOutMs - 40 : targetClip.sourceOutMs,
        sourceOutMs: targetClip.sourceOutMs,
        volume: 0.0,
        speed: 1.0,
        isMuted: true,
        isFreezeFrame: true,
        freezeSourceMs: targetClip.sourceOutMs > 40 ? targetClip.sourceOutMs - 40 : targetClip.sourceOutMs,
        colorGrading: targetClip.colorGrading,
        border: targetClip.border,
        headerFooter: targetClip.headerFooter,
        mask: targetClip.mask,
        blendMode: targetClip.blendMode,
      );

      for (final clip in targetTrack.clips) {
        if (clip.id == clipId) {
          updatedClips.add(clip);
          updatedClips.add(freezeClip);
        } else if (clip.startTimeMs >= clipEnd) {
          updatedClips.add(clip.copyWith(startTimeMs: clip.startTimeMs + freezeDurationMs));
        } else {
          updatedClips.add(clip);
        }
      }
    }

    final updatedTrack = targetTrack.copyWith(clips: updatedClips);
    final updatedTracks = project.tracks.map((t) => t.id == updatedTrack.id ? updatedTrack : t).toList();

    return project.copyWith(tracks: updatedTracks).recalculateDuration();
  }

  /// Toggles reverse video & audio playback for the specified clip
  static Project? toggleReverseClip(Project project, String clipId) {
    for (final track in project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) {
          final updated = clip.copyWith(isReversed: !clip.isReversed);
          return project.updateClip(updated);
        }
      }
    }
    return null;
  }

  /// Extracts audio from a video clip onto a dedicated audio track
  static Project? extractAudio(Project project, String clipId) {
    Track? sourceTrack;
    Clip? sourceClip;

    for (final track in project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) {
          sourceTrack = track;
          sourceClip = clip;
          break;
        }
      }
      if (sourceClip != null) break;
    }

    if (sourceTrack == null || sourceClip == null) return null;

    // 1. Mute the original video clip
    final updatedVideoClip = sourceClip.copyWith(isMuted: true, volume: 0.0);
    var updatedProject = project.updateClip(updatedVideoClip);

    // 2. Find existing audio track or create a new audio track
    Track? targetAudioTrack;
    final audioTracks = updatedProject.tracks.where((t) => t.type == TrackType.audio).toList();
    if (audioTracks.isNotEmpty) {
      targetAudioTrack = audioTracks.first;
    } else {
      targetAudioTrack = Track(
        id: const Uuid().v4(),
        name: 'Extracted Audio',
        type: TrackType.audio,
        order: updatedProject.tracks.length,
        clips: const [],
      );
      updatedProject = updatedProject.addTrack(targetAudioTrack);
    }

    // 3. Create independent audio clip
    final extractedClip = Clip(
      id: const Uuid().v4(),
      assetId: sourceClip.assetId,
      trackId: targetAudioTrack.id,
      startTimeMs: sourceClip.startTimeMs,
      durationMs: sourceClip.durationMs,
      sourceInMs: sourceClip.sourceInMs,
      sourceOutMs: sourceClip.sourceOutMs,
      volume: sourceClip.volume > 0 ? sourceClip.volume : 1.0,
      speed: sourceClip.speed,
      isMuted: false,
      isReversed: sourceClip.isReversed,
      audioEffects: sourceClip.audioEffects,
    );

    return updatedProject.addClipToTrack(targetAudioTrack.id, extractedClip).recalculateDuration();
  }
}
