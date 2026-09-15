import 'dart:math';
import '../../../models/clip.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';

class AudioInterval {
  final double startSec;
  final double endSec;

  const AudioInterval(this.startSec, this.endSec);
}

class AudioDuckingService {
  /// Finds all active foreground speech / dialogue intervals (in seconds) in the project
  static List<AudioInterval> getForegroundSpeechIntervals(Project project) {
    final intervals = <AudioInterval>[];
    for (final track in project.tracks) {
      if (track.type == TrackType.video && !track.isMuted) {
        for (final clip in track.clips) {
          if (!clip.isMuted) {
            final startSec = clip.startTimeMs / 1000.0;
            final endSec = (clip.startTimeMs + clip.durationMs) / 1000.0;
            intervals.add(AudioInterval(startSec, endSec));
          }
        }
      }
    }
    if (intervals.isEmpty) return intervals;

    intervals.sort((a, b) => a.startSec.compareTo(b.startSec));
    final merged = <AudioInterval>[intervals.first];
    for (int i = 1; i < intervals.length; i++) {
      final current = intervals[i];
      final last = merged.last;
      if (current.startSec <= last.endSec + 0.15) {
        merged[merged.length - 1] = AudioInterval(
          last.startSec,
          max(last.endSec, current.endSec),
        );
      } else {
        merged.add(current);
      }
    }
    return merged;
  }

  /// Calculates the volume attenuation factor (0.0 to 1.0) for a track at a given millisecond timestamp,
  /// with smooth attack and release envelope ramps.
  static double calculateDuckingFactor(
    Project project,
    Track currentTrack,
    int timestampMs, {
    double duckingAttenuation = 0.30,
    int attackMs = 50,
    int releaseMs = 300,
  }) {
    // Only duck background audio tracks
    if (currentTrack.type != TrackType.audio) return 1.0;

    final intervals = getForegroundSpeechIntervals(project);
    if (intervals.isEmpty) return 1.0;

    final tSec = timestampMs / 1000.0;
    final attackSec = max(0.01, attackMs / 1000.0);
    final releaseSec = max(0.05, releaseMs / 1000.0);

    for (final interval in intervals) {
      // Inside active foreground speech
      if (tSec >= interval.startSec && tSec <= interval.endSec) {
        // Smooth attack ramp at the beginning of speech
        if (tSec < interval.startSec + attackSec) {
          final progress = (tSec - interval.startSec) / attackSec;
          return 1.0 - (progress * (1.0 - duckingAttenuation));
        }
        return duckingAttenuation;
      }

      // Smooth release ramp immediately following speech
      if (tSec > interval.endSec && tSec <= interval.endSec + releaseSec) {
        final progress = (tSec - interval.endSec) / releaseSec;
        return duckingAttenuation + (progress * (1.0 - duckingAttenuation));
      }
    }

    return 1.0;
  }

  /// Builds a dynamic FFmpeg frame-evaluated volume filter expression for seamless audio ducking
  static String buildDuckingVolumeFilter({
    required Project project,
    required Clip backgroundClip,
    required double baseVolume,
  }) {
    if (!backgroundClip.audioEffects.isDuckingEnabled) {
      return '';
    }

    final speechIntervals = getForegroundSpeechIntervals(project);
    final clipStartSec = backgroundClip.startTimeMs / 1000.0;
    final clipEndSec = (backgroundClip.startTimeMs + backgroundClip.durationMs) / 1000.0;

    // Filter to intervals that overlap with this clip
    final overlapping = speechIntervals.where((s) => s.endSec > clipStartSec && s.startSec < clipEndSec).toList();

    if (overlapping.isEmpty) {
      return '';
    }

    final duckedVol = (baseVolume * backgroundClip.audioEffects.duckingAttenuation).toStringAsFixed(2);
    final normalVol = baseVolume.toStringAsFixed(2);

    // Build between() conditions for FFmpeg volume evaluation
    final conditions = overlapping.map((i) {
      final s = max(clipStartSec, i.startSec).toStringAsFixed(2);
      final e = min(clipEndSec, i.endSec).toStringAsFixed(2);
      return 'between(t,$s,$e)';
    }).join('+');

    return "volume=eval=frame:volume='if($conditions,$duckedVol,$normalVol)'";
  }
}
