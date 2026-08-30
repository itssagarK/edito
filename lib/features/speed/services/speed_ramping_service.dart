import '../../../models/clip.dart';
import '../models/speed_curve_preset.dart';

class SpeedRampingService {
  /// Evaluates the source media frame offset for a given timeline offset under speed curves
  static int calculateSourceOffset(Clip clip, int offsetInTimelineMs) {
    if (clip.speedCurve.type == SpeedCurveType.constant) {
      return (offsetInTimelineMs * clip.speed).round();
    }

    final points = clip.speedCurve.curvePoints;
    if (points.isEmpty) return offsetInTimelineMs;

    final normTime = (offsetInTimelineMs / clip.durationMs).clamp(0.0, 1.0);

    // Interpolate speed from curve points
    double speedAtTime = points.first.y;
    for (int i = 1; i < points.length; i++) {
      if (normTime <= points[i].x) {
        final p0 = points[i - 1];
        final p1 = points[i];
        final t = (normTime - p0.x) / (p1.x - p0.x);
        speedAtTime = p0.y + (t * (p1.y - p0.y));
        break;
      }
    }

    return (offsetInTimelineMs * speedAtTime).round();
  }

  /// Generates the FFmpeg audio tempo filter chain with pitch correction support
  static String generateAudioSpeedFilter(double speed, {bool enablePitchCorrection = true}) {
    if (speed == 1.0) return '';

    // FFmpeg atempo filter accepts 0.5 to 2.0 per instance.
    // For speeds outside [0.5, 2.0], chain multiple atempo filters.
    if (speed >= 0.5 && speed <= 2.0) {
      return 'atempo=${speed.toStringAsFixed(2)}';
    } else if (speed > 2.0 && speed <= 4.0) {
      final half = speed / 2.0;
      return 'atempo=2.0,atempo=${half.toStringAsFixed(2)}';
    } else if (speed > 4.0) {
      final quad = speed / 4.0;
      return 'atempo=2.0,atempo=2.0,atempo=${quad.toStringAsFixed(2)}';
    } else if (speed < 0.5 && speed >= 0.25) {
      final dbl = speed * 2.0;
      return 'atempo=0.5,atempo=${dbl.toStringAsFixed(2)}';
    } else {
      return 'atempo=0.5,atempo=0.5';
    }
  }
}
