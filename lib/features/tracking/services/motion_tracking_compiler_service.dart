import 'dart:math' as math;
import '../models/motion_tracking_config.dart';
import 'motion_tracking_service.dart';

/// CapCut Pro Motion Tracking Filtergraph Compiler Service
class MotionTrackingCompilerService {
  /// Compiles continuous X/Y/Scale expressions for FFmpeg overlay and drawtext filters
  static Map<String, String> generateFFmpegMotionExpressions({
    required MotionTrackingConfig config,
    required int clipStartTimeMs,
    required int clipDurationMs,
    required int targetWidth,
    required int targetHeight,
  }) {
    if (!config.isEnabled || config.trajectory.isEmpty) {
      return {};
    }

    final trajectory = config.trajectory;
    final startSec = (clipStartTimeMs / 1000.0).toStringAsFixed(2);
    final tExpr = "(t-$startSec)";

    // Pick key milestones for linear interpolation in FFmpeg
    // We sample 5 to 10 points across the clip to form clean lerp expressions
    final sampleCount = math.min(8, trajectory.length);
    final step = (trajectory.length / sampleCount).floor().clamp(1, trajectory.length);

    final sampled = <TrackingTrajectoryPoint>[];
    for (int i = 0; i < trajectory.length; i += step) {
      sampled.add(trajectory[i]);
      if (sampled.length >= sampleCount) break;
    }
    if (sampled.last.offsetMs != trajectory.last.offsetMs) {
      sampled.add(trajectory.last);
    }

    final anchorOffsetY = config.anchor == TrackingAnchor.customOffset
        ? config.offsetY
        : config.anchor.defaultOffsetY;

    // Build piecewise linear interpolation expression:
    // x = if(lt(t_rel, t1), x0 + (x1-x0)*(t_rel-t0)/(t1-t0), if(...))
    String buildExpr(double Function(TrackingTrajectoryPoint) selector) {
      if (sampled.length == 1) {
        return selector(sampled.first).toStringAsFixed(3);
      }

      String expr = selector(sampled.last).toStringAsFixed(3);
      for (int i = sampled.length - 2; i >= 0; i--) {
        final p0 = sampled[i];
        final p1 = sampled[i + 1];
        final t0 = (p0.offsetMs / 1000.0).toStringAsFixed(2);
        final t1 = (p1.offsetMs / 1000.0).toStringAsFixed(2);
        final dt = ((p1.offsetMs - p0.offsetMs) / 1000.0).toStringAsFixed(3);
        final v0 = selector(p0).toStringAsFixed(3);
        final v1 = selector(p1).toStringAsFixed(3);

        if (p1.offsetMs == p0.offsetMs) continue;

        expr = "if(lt($tExpr,$t1),$v0+($v1-$v0)*($tExpr-$t0)/$dt,$expr)";
      }
      return expr;
    }

    final xExpr = buildExpr((p) => (p.normalizedX + config.offsetX).clamp(0.0, 1.0) * targetWidth);
    final yExpr = buildExpr((p) => (p.normalizedY + anchorOffsetY).clamp(0.0, 1.0) * targetHeight);
    final scaleExpr = config.mode == TrackingMode.followPosition
        ? '1.0'
        : buildExpr((p) => p.scale.clamp(0.5, 2.0));

    return {
      'x': xExpr,
      'y': yExpr,
      'scale': scaleExpr,
      'badge': MotionTrackingService.getBadge(config),
    };
  }

  /// Floating Viewport HUD badge
  static String getTrackingBadge(MotionTrackingConfig config) {
    return MotionTrackingService.getBadge(config);
  }
}
