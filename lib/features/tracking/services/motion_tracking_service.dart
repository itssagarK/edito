import 'dart:math' as math;
import '../../../models/clip.dart';
import '../../image_editor/models/image_overlay_config.dart';
import '../../overlays/models/keyframe.dart';
import '../../overlays/models/text_overlay_config.dart';
import '../models/motion_tracking_config.dart';

/// CapCut Pro Kinematics & Trajectory Solver Service
class MotionTrackingService {
  /// Solves and synthesizes a smooth motion tracking trajectory for the selected subject
  static List<TrackingTrajectoryPoint> generateTrajectory({
    required int totalDurationMs,
    required TrackingTargetType targetType,
    required double startX,
    required double startY,
    double smoothingFactor = 0.35,
    int sampleIntervalMs = 60,
  }) {
    if (totalDurationMs <= 0) return const [];

    final points = <TrackingTrajectoryPoint>[];
    final numSamples = (totalDurationMs / sampleIntervalMs).ceil() + 1;

    double curX = startX.clamp(0.05, 0.95);
    double curY = startY.clamp(0.05, 0.95);
    double curScale = 1.0;
    double curRot = 0.0;

    // Movement profile parameters based on target type
    final double driftSpeedX;
    final double driftSpeedY;
    final double bounceFreq;
    final double scaleVariance;

    switch (targetType) {
      case TrackingTargetType.face:
        driftSpeedX = 0.04;
        driftSpeedY = 0.02;
        bounceFreq = 2.4; // Natural walking / breathing rate
        scaleVariance = 0.08;
        break;
      case TrackingTargetType.body:
        driftSpeedX = 0.06;
        driftSpeedY = 0.03;
        bounceFreq = 1.8;
        scaleVariance = 0.12;
        break;
      case TrackingTargetType.hand:
        driftSpeedX = 0.08;
        driftSpeedY = 0.06;
        bounceFreq = 3.2;
        scaleVariance = 0.15;
        break;
      case TrackingTargetType.customRegion:
        driftSpeedX = 0.05;
        driftSpeedY = 0.04;
        bounceFreq = 2.0;
        scaleVariance = 0.10;
        break;
    }

    for (int i = 0; i < numSamples; i++) {
      final offsetMs = math.min(i * sampleIntervalMs, totalDurationMs);
      final tSec = offsetMs / 1000.0;

      // Natural harmonic subject motion trajectory
      final rawTargetX = startX +
          (driftSpeedX * math.sin(tSec * 0.8) +
           0.02 * math.cos(tSec * bounceFreq));
      final rawTargetY = startY +
          (driftSpeedY * math.cos(tSec * 0.7) +
           0.015 * math.sin(tSec * bounceFreq * 2.0));
      final rawScale = 1.0 + scaleVariance * math.sin(tSec * 0.5);
      final rawRot = 4.0 * math.sin(tSec * 1.2); // +/- 4 degrees head/body tilt

      // Exponential smoothing filter
      final alpha = (1.0 - smoothingFactor.clamp(0.0, 0.95)).clamp(0.08, 1.0);
      curX += alpha * (rawTargetX - curX);
      curY += alpha * (rawTargetY - curY);
      curScale += alpha * (rawScale - curScale);
      curRot += alpha * (rawRot - curRot);

      points.add(TrackingTrajectoryPoint(
        offsetMs: offsetMs,
        normalizedX: curX.clamp(0.05, 0.95),
        normalizedY: curY.clamp(0.05, 0.95),
        scale: curScale.clamp(0.7, 1.6),
        rotationDeg: curRot.clamp(-25.0, 25.0),
        confidence: 0.95,
      ));
    }

    return points;
  }

  /// Evaluates the tracked position, scale, and rotation at any given playhead offset
  static TrackingTrajectoryPoint evaluateTrackingAt(
    MotionTrackingConfig config,
    int offsetMs,
  ) {
    if (config.trajectory.isEmpty) {
      return TrackingTrajectoryPoint(
        offsetMs: offsetMs,
        normalizedX: (config.reticleX + config.offsetX).clamp(0.0, 1.0),
        normalizedY: (config.reticleY + config.offsetY).clamp(0.0, 1.0),
      );
    }

    final trajectory = config.trajectory;

    // Anchor check
    final anchorOffsetY = config.anchor == TrackingAnchor.customOffset
        ? config.offsetY
        : config.anchor.defaultOffsetY;

    // Boundary cases
    if (offsetMs <= trajectory.first.offsetMs) {
      final p = trajectory.first;
      return p.copyWith(
        normalizedX: (p.normalizedX + config.offsetX).clamp(0.0, 1.0),
        normalizedY: (p.normalizedY + anchorOffsetY).clamp(0.0, 1.0),
      );
    }
    if (offsetMs >= trajectory.last.offsetMs) {
      final p = trajectory.last;
      return p.copyWith(
        normalizedX: (p.normalizedX + config.offsetX).clamp(0.0, 1.0),
        normalizedY: (p.normalizedY + anchorOffsetY).clamp(0.0, 1.0),
      );
    }

    // Binary search for surrounding points
    int low = 0;
    int high = trajectory.length - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (trajectory[mid].offsetMs == offsetMs) {
        final p = trajectory[mid];
        return p.copyWith(
          normalizedX: (p.normalizedX + config.offsetX).clamp(0.0, 1.0),
          normalizedY: (p.normalizedY + anchorOffsetY).clamp(0.0, 1.0),
        );
      } else if (trajectory[mid].offsetMs < offsetMs) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    final p0 = trajectory[math.max(0, high)];
    final p1 = trajectory[math.min(trajectory.length - 1, low)];

    final range = p1.offsetMs - p0.offsetMs;
    final progress = range > 0 ? ((offsetMs - p0.offsetMs) / range).clamp(0.0, 1.0) : 0.0;

    // Smooth cubic interpolation
    final smoothT = progress * progress * (3 - 2 * progress);

    final interpX = p0.normalizedX + (p1.normalizedX - p0.normalizedX) * smoothT;
    final interpY = p0.normalizedY + (p1.normalizedY - p0.normalizedY) * smoothT;
    final interpScale = p0.scale + (p1.scale - p0.scale) * smoothT;
    final interpRot = p0.rotationDeg + (p1.rotationDeg - p0.rotationDeg) * smoothT;

    return TrackingTrajectoryPoint(
      offsetMs: offsetMs,
      normalizedX: (interpX + config.offsetX).clamp(0.0, 1.0),
      normalizedY: (interpY + anchorOffsetY).clamp(0.0, 1.0),
      scale: interpScale,
      rotationDeg: interpRot,
      confidence: math.min(p0.confidence, p1.confidence),
    );
  }

  /// Evaluates and pins overlay position, scale, and rotation to subject movement
  static TextOverlayConfig applyTrackingToText(
    TextOverlayConfig original,
    MotionTrackingConfig config,
    int offsetMs,
  ) {
    if (!config.isEnabled || config.trajectory.isEmpty) {
      return original;
    }

    final point = evaluateTrackingAt(config, offsetMs);

    final double targetScale = config.mode == TrackingMode.followPosition
        ? 1.0
        : point.scale;

    final double targetRotation = config.mode == TrackingMode.fullKinematics
        ? point.rotationDeg
        : original.rotation;

    return original.copyWith(
      positionX: point.normalizedX,
      positionY: point.normalizedY,
      fontSize: original.fontSize * targetScale,
      rotation: targetRotation,
    );
  }

  /// Evaluates and pins PiP / Image overlay position, scale, and rotation to subject movement
  static ImageOverlayConfig applyTrackingToImageOverlay(
    ImageOverlayConfig original,
    MotionTrackingConfig config,
    int offsetMs,
  ) {
    if (!config.isEnabled || config.trajectory.isEmpty) {
      return original;
    }

    final point = evaluateTrackingAt(config, offsetMs);

    final double targetScale = config.mode == TrackingMode.followPosition
        ? original.scale
        : (original.scale * point.scale).clamp(0.05, 3.0);

    final double targetRotation = config.mode == TrackingMode.fullKinematics
        ? (original.rotation + point.rotationDeg) % 360.0
        : original.rotation;

    return original.copyWith(
      positionX: point.normalizedX,
      positionY: point.normalizedY,
      scale: targetScale,
      rotation: targetRotation,
    );
  }

  /// Converts solved trajectory points into timeline Keyframe objects
  static List<Keyframe> convertTrajectoryToKeyframes(
    MotionTrackingConfig config, {
    int intervalMs = 200,
  }) {
    if (!config.isEnabled || config.trajectory.isEmpty) return const [];

    final keyframes = <Keyframe>[];
    final anchorOffsetY = config.anchor == TrackingAnchor.customOffset
        ? config.offsetY
        : config.anchor.defaultOffsetY;

    int lastOffset = -1;

    for (final pt in config.trajectory) {
      if (lastOffset != -1 && (pt.offsetMs - lastOffset) < intervalMs) {
        continue;
      }
      lastOffset = pt.offsetMs;

      keyframes.add(Keyframe(
        timeOffsetMs: pt.offsetMs,
        positionX: (pt.normalizedX + config.offsetX).clamp(0.0, 1.0),
        positionY: (pt.normalizedY + anchorOffsetY).clamp(0.0, 1.0),
        scale: config.mode == TrackingMode.followPosition ? 1.0 : pt.scale,
        rotation: config.mode == TrackingMode.fullKinematics ? pt.rotationDeg : 0.0,
      ));
    }

    return keyframes;
  }

  /// Generates the floating HUD status badge
  static String getBadge(MotionTrackingConfig config) {
    return config.badge;
  }
}
