import '../../../models/project.dart';
import '../../../models/track.dart';

class AudioDuckingService {
  /// Calculates the volume attenuation factor (0.0 to 1.0) for a track at a given millisecond timestamp
  static double calculateDuckingFactor(
    Project project,
    Track currentTrack,
    int timestampMs, {
    double duckingAttenuation = 0.30,
  }) {
    // Only duck background audio tracks
    if (currentTrack.type != TrackType.audio) return 1.0;

    // Check if there is active foreground speech/video at this timestamp
    bool hasForegroundSpeech = false;
    for (final track in project.tracks) {
      if (track.type == TrackType.video && !track.isMuted) {
        for (final clip in track.clips) {
          if (!clip.isMuted &&
              timestampMs >= clip.startTimeMs &&
              timestampMs < (clip.startTimeMs + clip.durationMs)) {
            hasForegroundSpeech = true;
            break;
          }
        }
      }
      if (hasForegroundSpeech) break;
    }

    if (hasForegroundSpeech) {
      return duckingAttenuation;
    }

    return 1.0;
  }
}
