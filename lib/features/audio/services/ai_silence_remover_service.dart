import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../../models/clip.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import 'audio_vad_service.dart';

/// Summary of detected speech and silent pauses in an audio/video clip.
class SilenceAnalysisResult {
  final int totalClipDurationMs;
  final List<List<int>> speechSegments;
  final List<List<int>> silenceSegments;
  final int totalSilenceDurationMs;
  final double speechPercentage;

  const SilenceAnalysisResult({
    required this.totalClipDurationMs,
    required this.speechSegments,
    required this.silenceSegments,
    required this.totalSilenceDurationMs,
    required this.speechPercentage,
  });

  int get silenceCount => silenceSegments.length;
}

/// On-Device AI Silence Remover & Smart Jump-Cut Service.
///
/// Uses Voice Activity Detection (VAD) to scan audio for dead-air intervals,
/// pauses, and unvoiced gaps, then ripple-excises them to generate high-retention,
/// snappy social media jump cuts (YouTube Shorts, TikTok, Reels, Podcasts).
class AiSilenceRemoverService {
  /// Scans a clip for voice activity and computes all dead-air silence intervals.
  static Future<SilenceAnalysisResult> analyzeClipForSilences({
    required Clip clip,
    required String mediaPath,
    int minSilenceMs = 350,
    double sensitivity = 0.70,
  }) async {
    final durationMs = clip.durationMs;
    if (durationMs <= 0) {
      return const SilenceAnalysisResult(
        totalClipDurationMs: 0,
        speechSegments: [],
        silenceSegments: [],
        totalSilenceDurationMs: 0,
        speechPercentage: 0.0,
      );
    }

    // 1. Detect active speech intervals via on-device VAD
    List<List<int>> speechIntervals = [];
    if (mediaPath.isNotEmpty) {
      speechIntervals = await AudioVadService.detectVoiceActivity(
        filePath: mediaPath,
        durationMs: durationMs,
        sensitivity: sensitivity,
      );
    }

    // Fallback if no speech returned (or purely empty media): synthesize based on audio effects intervals
    if (speechIntervals.isEmpty && clip.audioEffects.speechIntervalsMs.isNotEmpty) {
      speechIntervals = List<List<int>>.from(clip.audioEffects.speechIntervalsMs);
    }

    // If still empty, assume the clip is active speech (no silences found to be safe)
    if (speechIntervals.isEmpty) {
      return SilenceAnalysisResult(
        totalClipDurationMs: durationMs,
        speechSegments: [[0, durationMs]],
        silenceSegments: const [],
        totalSilenceDurationMs: 0,
        speechPercentage: 100.0,
      );
    }

    // 2. Derive silence intervals (gaps between speech segments)
    final silenceIntervals = <List<int>>[];
    int cursor = 0;

    for (final seg in speechIntervals) {
      final segStart = seg[0].clamp(0, durationMs);
      final segEnd = seg[1].clamp(0, durationMs);

      if (segStart - cursor >= minSilenceMs) {
        silenceIntervals.add([cursor, segStart]);
      }
      cursor = max(cursor, segEnd);
    }

    if (durationMs - cursor >= minSilenceMs) {
      silenceIntervals.add([cursor, durationMs]);
    }

    int totalSilenceMs = 0;
    for (final s in silenceIntervals) {
      totalSilenceMs += (s[1] - s[0]);
    }

    final speechMs = max(0, durationMs - totalSilenceMs);
    final speechPct = durationMs > 0 ? (speechMs / durationMs) * 100.0 : 100.0;

    return SilenceAnalysisResult(
      totalClipDurationMs: durationMs,
      speechSegments: speechIntervals,
      silenceSegments: silenceIntervals,
      totalSilenceDurationMs: totalSilenceMs,
      speechPercentage: speechPct.clamp(0.0, 100.0),
    );
  }

  /// Removes dead-air silences from a clip and ripples the speech segments contiguously.
  ///
  /// Splits the target clip into speech sub-clips, preserving all visual effects,
  /// color grading, transforms, and audio settings, while deleting the silent dead-air gaps.
  static Project? removeSilencesFromClip({
    required Project project,
    required String clipId,
    required SilenceAnalysisResult analysis,
    int paddingMs = 40,
  }) {
    if (analysis.silenceSegments.isEmpty || analysis.speechSegments.isEmpty) {
      return null;
    }

    Track? targetTrack;
    Clip? targetClip;

    for (final track in project.tracks) {
      for (final c in track.clips) {
        if (c.id == clipId) {
          targetTrack = track;
          targetClip = c;
          break;
        }
      }
      if (targetClip != null) break;
    }

    if (targetTrack == null || targetClip == null) return null;

    // 1. Expand speech segments by paddingMs to prevent clipping natural word endings
    final paddedSpeechSegments = <List<int>>[];
    for (final seg in analysis.speechSegments) {
      final paddedStart = max(0, seg[0] - paddingMs);
      final paddedEnd = min(targetClip.durationMs, seg[1] + paddingMs);

      if (paddedSpeechSegments.isEmpty) {
        paddedSpeechSegments.add([paddedStart, paddedEnd]);
      } else {
        final last = paddedSpeechSegments.last;
        if (paddedStart <= last[1]) {
          // Merge overlapping padded segments
          last[1] = max(last[1], paddedEnd);
        } else {
          paddedSpeechSegments.add([paddedStart, paddedEnd]);
        }
      }
    }

    if (paddedSpeechSegments.isEmpty) return null;

    // 2. Generate sub-clips for each speech segment
    final speechSubClips = <Clip>[];
    int currentTimelineStartMs = targetClip.startTimeMs;

    for (int i = 0; i < paddedSpeechSegments.length; i++) {
      final seg = paddedSpeechSegments[i];
      final segStartOffsetMs = seg[0];
      final segEndOffsetMs = seg[1];
      final segDurationMs = segEndOffsetMs - segStartOffsetMs;

      if (segDurationMs < 80) continue; // Skip micro-glitches under 80ms

      final sourceInMs = targetClip.sourceInMs + (segStartOffsetMs * targetClip.speed).round();
      final sourceOutMs = targetClip.sourceInMs + (segEndOffsetMs * targetClip.speed).round();

      final subClip = targetClip.copyWith(
        id: i == 0 ? targetClip.id : const Uuid().v4(),
        startTimeMs: currentTimelineStartMs,
        durationMs: segDurationMs,
        sourceInMs: sourceInMs,
        sourceOutMs: sourceOutMs,
      );

      speechSubClips.add(subClip);
      currentTimelineStartMs += segDurationMs;
    }

    if (speechSubClips.isEmpty) return null;

    // 3. Replace target clip in track with speech sub-clips and ripple subsequent clips
    final originalClipEndMs = targetClip.startTimeMs + targetClip.durationMs;
    final newClipEndMs = currentTimelineStartMs;
    final rippleDeltaMs = newClipEndMs - originalClipEndMs;

    final updatedClips = <Clip>[];
    for (final c in targetTrack.clips) {
      if (c.id == clipId) {
        updatedClips.addAll(speechSubClips);
      } else if (c.startTimeMs >= originalClipEndMs) {
        // Ripple subsequent clips backwards to close the removed silence gap
        final newStart = max(0, c.startTimeMs + rippleDeltaMs);
        updatedClips.add(c.copyWith(startTimeMs: newStart));
      } else {
        updatedClips.add(c);
      }
    }

    final updatedTrack = targetTrack.copyWith(clips: updatedClips);
    final updatedTracks = project.tracks.map((t) => t.id == updatedTrack.id ? updatedTrack : t).toList();

    return project.copyWith(tracks: updatedTracks).recalculateDuration();
  }
}
