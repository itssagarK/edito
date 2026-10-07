import '../../color_grading/models/color_grading_config.dart';
import '../models/speed_ease_config.dart';

class SpeedEaseCompilerService {
  /// Converts continuous Bezier easing curve into discrete piecewise CurvePoints
  /// for interpolation and integration engines.
  static List<CurvePoint> convertToCurvePoints(SpeedEaseConfig config, {int subdivisions = 8}) {
    if (!config.isActive) {
      return [const CurvePoint(0.0, 1.0), const CurvePoint(1.0, 1.0)];
    }

    final points = <CurvePoint>[];
    for (int i = 0; i <= subdivisions; i++) {
      final t = (i / subdivisions).clamp(0.0, 1.0);
      final speed = config.evaluateSpeedAt(t);
      points.add(CurvePoint(t, speed));
    }
    return points;
  }

  /// Compiles native FFmpeg video filter commands for Bezier curve speed ease
  static List<String> generateFFmpegFilters(
    SpeedEaseConfig config, {
    required int clipDurationMs,
    int targetFps = 30,
  }) {
    if (!config.isActive || clipDurationMs <= 0) return const [];

    final avgSpeed = config.calculateEffectiveAverageSpeed().clamp(0.1, 10.0);
    final ptsMultiplier = (1.0 / avgSpeed).toStringAsFixed(4);

    return [
      'setpts=$ptsMultiplier*PTS',
      'fps=fps=$targetFps:round=near',
    ];
  }
}
