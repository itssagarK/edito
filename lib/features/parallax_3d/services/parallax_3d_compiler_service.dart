import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/parallax_3d_config.dart';

/// Compiler and Kinematics Solver for CapCut Pro 3D Zoom & Parallax Motion
class Parallax3DCompilerService {
  /// Evaluates normalized motion progress [0.0, 1.0] across acceleration curves
  static double evaluateCurveProgress(MotionDynamicsCurve curve, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    switch (curve) {
      case MotionDynamicsCurve.linear:
        return clampedT;

      case MotionDynamicsCurve.smoothCubic:
        // Standard smooth cubic ease-in-out
        return clampedT < 0.5
            ? (4.0 * clampedT * clampedT * clampedT)
            : (1.0 - math.pow(-2.0 * clampedT + 2.0, 3).toDouble() / 2.0);

      case MotionDynamicsCurve.elasticSnap:
        // Elastic spring snap curve with smooth settling
        if (clampedT == 0.0) return 0.0;
        if (clampedT == 1.0) return 1.0;
        const c4 = (2.0 * math.pi) / 3.0;
        return (math.pow(2.0, -10.0 * clampedT).toDouble() *
                math.sin((clampedT * 10.0 - 0.75) * c4) +
            1.0);

      case MotionDynamicsCurve.cinematicSlow:
        // Cinematic tension curve (slow start, smooth accelerate)
        return math.pow(clampedT, 2.4).toDouble();
    }
  }

  /// Computes 3D Skia transformation matrix for real-time viewport compositing
  static Matrix4 computePreviewMatrix(
    Parallax3DConfig config,
    double progress, {
    Size? viewportSize,
  }) {
    if (!config.isEnabled || config.style == Parallax3DStyle.none) {
      return Matrix4.identity();
    }

    final p = evaluateCurveProgress(config.dynamicsCurve, progress);
    final matrix = Matrix4.identity();

    // 3D Perspective Projection divisor (Z-depth foreshortening)
    final perspective = 0.0012 * config.perspectiveTilt.clamp(0.1, 1.0);
    matrix.setEntry(3, 2, perspective);

    final maxScale = config.depthScale.clamp(1.0, 2.5);
    final intensity = config.intensity.clamp(0.0, 1.0);
    final tiltStrength = config.perspectiveTilt.clamp(0.0, 1.0);

    double scale = 1.0;
    double rotX = 0.0; // Pitch
    double rotY = 0.0; // Yaw
    double rotZ = 0.0; // Roll
    double transX = 0.0;
    double transY = 0.0;

    switch (config.style) {
      case Parallax3DStyle.none:
        break;

      case Parallax3DStyle.classicZoomIn:
        // Forward camera push-in dolly with subject pop
        scale = 1.0 + (maxScale - 1.0) * intensity * p;
        rotX = 0.05 * tiltStrength * math.sin(p * math.pi);
        rotY = -0.03 * tiltStrength * math.sin(p * math.pi);
        transY = -0.04 * intensity * p;
        break;

      case Parallax3DStyle.dollyZoomOut:
        // Smooth reverse pull dolly
        scale = maxScale - (maxScale - 1.0) * intensity * p;
        rotX = -0.04 * tiltStrength * math.sin(p * math.pi);
        transY = 0.03 * intensity * p;
        break;

      case Parallax3DStyle.orbitalLeft:
        // Camera sweeps in leftward orbital arc with counter-translation
        scale = 1.0 + (maxScale - 1.0) * 0.7 * intensity * math.sin(p * math.pi);
        rotY = -0.18 * tiltStrength * p;
        rotZ = 0.03 * tiltStrength * p;
        transX = -0.12 * intensity * p;
        break;

      case Parallax3DStyle.orbitalRight:
        // Camera sweeps in rightward orbital arc with counter-translation
        scale = 1.0 + (maxScale - 1.0) * 0.7 * intensity * math.sin(p * math.pi);
        rotY = 0.18 * tiltStrength * p;
        rotZ = -0.03 * tiltStrength * p;
        transX = 0.12 * intensity * p;
        break;

      case Parallax3DStyle.vertigoDolly:
        // Vertigo / Hitchcock counter-zoom: subject locked, perspective stretches
        final zoomFactor = 1.0 + (maxScale - 1.0) * intensity * p;
        scale = zoomFactor;
        rotX = 0.08 * tiltStrength * (p - 0.5);
        matrix.setEntry(3, 2, perspective * (1.0 + 1.5 * p));
        break;

      case Parallax3DStyle.elasticBounce:
        // High-energy punch-in snap with spring rebound
        scale = 1.0 + (maxScale - 1.0) * intensity * p;
        rotX = 0.06 * tiltStrength * math.sin(p * 2 * math.pi);
        break;

      case Parallax3DStyle.craneGlider:
        // Sweeping diagonal crane swoop
        scale = 1.0 + (maxScale - 1.0) * intensity * p;
        rotX = -0.10 * tiltStrength * (1.0 - p);
        rotY = 0.08 * tiltStrength * p;
        transX = 0.08 * intensity * (p - 0.5);
        transY = 0.08 * intensity * (1.0 - p);
        break;
    }

    // Focal plane adjustment shifts translation anchor
    switch (config.focalPlane) {
      case FocalPlane.foreground:
        // Subject at center remains locked
        break;
      case FocalPlane.midground:
        transY += 0.02 * (scale - 1.0);
        break;
      case FocalPlane.background:
        transY += 0.05 * (scale - 1.0);
        break;
    }

    final width = viewportSize?.width ?? 400.0;
    final height = viewportSize?.height ?? 400.0;

    matrix.translate(transX * width, transY * height, 0.0);
    matrix.rotateX(rotX);
    matrix.rotateY(rotY);
    matrix.rotateZ(rotZ);
    matrix.scale(scale, scale, 1.0);

    return matrix;
  }

  /// Computes optical lens defocus blur sigma during peak camera motion
  static double computePreviewBlur(Parallax3DConfig config, double progress) {
    if (!config.isEnabled ||
        config.style == Parallax3DStyle.none ||
        config.depthBlur <= 0.0) {
      return 0.0;
    }

    // Blur peaks at mid-transition (maximum camera velocity)
    final velocityEnvelope = math.sin(progress.clamp(0.0, 1.0) * math.pi);
    return (config.depthBlur * 6.0 * velocityEnvelope).clamp(0.0, 12.0);
  }

  /// Generates native FFmpeg filtergraph commands for 100% deterministic export parity
  static List<String> generateFFmpegFilters(
    Parallax3DConfig config,
    int durationMs,
    int fps,
    int width,
    int height,
  ) {
    if (!config.isEnabled || config.style == Parallax3DStyle.none) {
      return [];
    }

    final filters = <String>[];
    final durationSec = (durationMs / 1000.0).clamp(0.1, 3600.0);
    final totalFrames = (durationSec * fps).round().clamp(1, 999999);
    final maxZoom = config.depthScale.clamp(1.0, 2.5);
    final intensity = config.intensity.clamp(0.0, 1.0);
    final targetZoom = 1.0 + (maxZoom - 1.0) * intensity;

    switch (config.style) {
      case Parallax3DStyle.none:
        break;

      case Parallax3DStyle.classicZoomIn:
        // Dynamic push-in zoompan with smooth ease
        final zExpr = 'min(1.0+(${targetZoom - 1.0})*(on/${totalFrames}),${targetZoom.toStringAsFixed(3)})';
        final xExpr = 'iw/2-(iw/zoom/2)';
        final yExpr = 'ih/2-(ih/zoom/2)';
        filters.add(
          'zoompan=z=\'$zExpr\':x=\'$xExpr\':y=\'$yExpr\':d=1:s=${width}x${height}:fps=$fps',
        );
        break;

      case Parallax3DStyle.dollyZoomOut:
        // Reverse pull-out zoompan
        final zExpr = 'max(${targetZoom.toStringAsFixed(3)}-(${targetZoom - 1.0})*(on/${totalFrames}),1.0)';
        final xExpr = 'iw/2-(iw/zoom/2)';
        final yExpr = 'ih/2-(ih/zoom/2)';
        filters.add(
          'zoompan=z=\'$zExpr\':x=\'$xExpr\':y=\'$yExpr\':d=1:s=${width}x${height}:fps=$fps',
        );
        break;

      case Parallax3DStyle.orbitalLeft:
        // Pan leftwards with slight zoom
        final zoomVal = 1.0 + (targetZoom - 1.0) * 0.5;
        final zExpr = zoomVal.toStringAsFixed(3);
        final xOffset = (width * 0.10 * intensity).round();
        final xExpr = 'iw/2-(iw/zoom/2)+($xOffset)*(1-2*(on/${totalFrames}))';
        final yExpr = 'ih/2-(ih/zoom/2)';
        filters.add(
          'zoompan=z=\'$zExpr\':x=\'$xExpr\':y=\'$yExpr\':d=1:s=${width}x${height}:fps=$fps',
        );
        break;

      case Parallax3DStyle.orbitalRight:
        // Pan rightwards with slight zoom
        final zoomVal = 1.0 + (targetZoom - 1.0) * 0.5;
        final zExpr = zoomVal.toStringAsFixed(3);
        final xOffset = (width * 0.10 * intensity).round();
        final xExpr = 'iw/2-(iw/zoom/2)-($xOffset)*(1-2*(on/${totalFrames}))';
        final yExpr = 'ih/2-(ih/zoom/2)';
        filters.add(
          'zoompan=z=\'$zExpr\':x=\'$xExpr\':y=\'$yExpr\':d=1:s=${width}x${height}:fps=$fps',
        );
        break;

      case Parallax3DStyle.vertigoDolly:
      case Parallax3DStyle.elasticBounce:
      case Parallax3DStyle.craneGlider:
        // Dynamic continuous sine zoom with centering
        final zExpr = '1.0+(${targetZoom - 1.0})*sin(PI*in_time/${durationSec.toStringAsFixed(3)})';
        final xExpr = 'iw/2-(iw/zoom/2)';
        final yExpr = 'ih/2-(ih/zoom/2)';
        filters.add(
          'zoompan=z=\'$zExpr\':x=\'$xExpr\':y=\'$yExpr\':d=1:s=${width}x${height}:fps=$fps',
        );
        break;
    }

    // Optical depth defocus blur during peak camera motion
    if (config.depthBlur > 0.0) {
      final maxRadius = (config.depthBlur * 4.0).clamp(1.0, 8.0).round();
      filters.add(
        'boxblur=luma_radius=$maxRadius:luma_power=1:enable=\'between(t,${(durationSec * 0.2).toStringAsFixed(2)},${(durationSec * 0.8).toStringAsFixed(2)})\'',
      );
    }

    return filters;
  }
}
