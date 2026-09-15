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

    final normTime = (offsetInTimelineMs / (clip.durationMs > 0 ? clip.durationMs : 1)).clamp(0.0, 1.0);

    // Trapezoidal integration of speed curve from 0 to normTime
    double integratedArea = 0.0;
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];

      if (normTime <= p0.x) break;

      if (normTime >= p1.x) {
        // Entire segment is before normTime
        final dt = p1.x - p0.x;
        final avgV = (p0.y + p1.y) / 2.0;
        integratedArea += dt * avgV;
      } else {
        // Partial segment up to normTime
        final span = p1.x - p0.x;
        final t = span > 0 ? (normTime - p0.x) / span : 0.0;
        final currentV = p0.y + (t * (p1.y - p0.y));
        final dt = normTime - p0.x;
        final avgV = (p0.y + currentV) / 2.0;
        integratedArea += dt * avgV;
        break;
      }
    }

    return (integratedArea * (clip.sourceOutMs - clip.sourceInMs)).round();
  }

  /// Calculates the effective average speed of a curve configuration
  static double calculateEffectiveAverageSpeed(SpeedCurveConfig config, double fallbackSpeed) {
    if (config.type == SpeedCurveType.constant) {
      return config.constantSpeed > 0 ? config.constantSpeed : fallbackSpeed;
    }

    final points = config.curvePoints;
    if (points.length < 2) return fallbackSpeed;

    double totalArea = 0.0;
    for (int i = 1; i < points.length; i++) {
      final dt = (points[i].x - points[i - 1].x).clamp(0.0, 1.0);
      final avgV = (points[i - 1].y + points[i].y) / 2.0;
      totalArea += dt * avgV;
    }

    return totalArea.clamp(0.05, 10.0);
  }

  /// Generates the FFmpeg audio tempo filter chain with pitch correction support
  static String generateAudioSpeedFilter(double speed, {bool enablePitchCorrection = true}) {
    if ((speed - 1.0).abs() < 0.01) return '';

    if (!enablePitchCorrection) {
      // Natural tape / vinyl record pitch modulation
      final targetSampleRate = (48000 * speed).round().clamp(8000, 192000);
      return 'asetrate=$targetSampleRate,aresample=48000';
    }

    // FFmpeg atempo filter accepts 0.5 to 2.0 per instance.
    // For speeds outside [0.5, 2.0], chain multiple atempo filters.
    if (speed >= 0.5 && speed <= 2.0) {
      return 'atempo=${speed.toStringAsFixed(2)}';
    } else if (speed > 2.0 && speed <= 4.0) {
      final half = speed / 2.0;
      return 'atempo=2.0,atempo=${half.toStringAsFixed(2)}';
    } else if (speed > 4.0 && speed <= 8.0) {
      final half = (speed / 4.0).clamp(0.5, 2.0);
      return 'atempo=2.0,atempo=2.0,atempo=${half.toStringAsFixed(2)}';
    } else if (speed > 8.0) {
      return 'atempo=2.0,atempo=2.0,atempo=2.0';
    } else if (speed < 0.5 && speed >= 0.25) {
      final dbl = speed * 2.0;
      return 'atempo=0.5,atempo=${dbl.toStringAsFixed(2)}';
    } else {
      return 'atempo=0.5,atempo=0.5';
    }
  }

  /// Generates FFmpeg video filters for speed curve and optical flow slow-mo
  static List<String> generateFFmpegVideoSpeedFilters(
    SpeedCurveConfig config,
    double baseSpeed, {
    int targetFps = 30,
  }) {
    final filters = <String>[];
    final effectiveSpeed = calculateEffectiveAverageSpeed(config, baseSpeed);

    if ((effectiveSpeed - 1.0).abs() > 0.01) {
      filters.add('setpts=PTS/${effectiveSpeed.toStringAsFixed(2)}');
    }

    // Optical-Flow Smooth Slow-Mo (minterpolate) for stutter-free slow motion
    if (config.isSmoothSlowMo && effectiveSpeed < 0.95) {
      filters.add('minterpolate=fps=$targetFps:mi_mode=mci:mc_mode=aobmc:vsbmc=1');
    }

    return filters;
  }
}
