import 'dart:math' as math;
import '../models/video_smoother_config.dart';

class AIVideoSmootherService {
  /// Generates the FFmpeg video filter chain for anti-shake stabilization, motion smoothing, optical flow, frame blending, and velocity motion blur
  static List<String> generateFFmpegFilters(VideoSmootherConfig config) {
    final filters = <String>[];

    // 1. Anti-Flicker (eliminates rolling shutter & ambient light flutter)
    if (config.isDeFlickerEnabled) {
      filters.add('deflicker=mode=pm:size=10');
    }

    // 2. Glitch & Stutter Removal (drops duplicate frozen frames and locks constant frame pacing)
    if (config.isDeGlitchEnabled) {
      filters.add('mpdecimate');
      filters.add('fps=fps=${config.targetFps}:round=near');
    }

    // 3. AI Camera Video Stabilization (cancels camera wobble and flutter like a 3-axis gimbal)
    if (config.isStabilizationEnabled) {
      final radius = (config.stabilizationStrength * 40).round().clamp(12, 64);
      filters.add('deshake=x=-1:y=-1:w=-1:h=-1:rx=$radius:ry=$radius:edge=mirror:blocksize=32');
    }

    // 4. Optical Flow & Frame Rate Interpolation
    switch (config.effectiveInterpolationMode) {
      case MotionInterpolationMode.opticalFlow:
        final fps = config.targetFps;
        // High-precision bidirectional motion-compensated optical flow interpolation (MCI)
        filters.add('minterpolate=fps=$fps:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1');
        break;
      case MotionInterpolationMode.frameBlend:
        final fps = config.targetFps;
        // Natural linear temporal frame crossfade blending
        filters.add('tblend=all_mode=average,fps=fps=$fps:round=near');
        break;
      case MotionInterpolationMode.none:
        break;
    }

    // 5. Velocity Motion Blur (Shutter Angle Simulation)
    if (config.isMotionBlurEnabled) {
      final samples = config.motionBlurSamples.clamp(2, 16);
      final decay = (config.shutterAngle / 360.0).clamp(0.1, 1.0);

      // Compute normalized Gaussian temporal distribution weights for consecutive sub-frames
      final weights = <double>[];
      for (int i = 0; i < samples; i++) {
        final w = math.exp(-0.5 * math.pow(i / (samples * decay), 2));
        weights.add(w);
      }
      final sum = weights.reduce((a, b) => a + b);
      final normalizedWeights = weights.map((w) => (w / sum).toStringAsFixed(2)).join(' ');
      filters.add('tmix=frames=$samples:weights=\'$normalizedWeights\'');

      // Directional velocity blur component
      final sigma = (config.shutterAngle / 360.0) * config.motionBlurIntensity * 3.5;
      if (sigma >= 0.4) {
        if (config.motionBlurDirection == MotionBlurDirection.horizontal ||
            config.motionBlurDirection == MotionBlurDirection.vertical) {
          filters.add('gblur=sigma=${sigma.toStringAsFixed(1)}:steps=1');
        }
      }
    }

    return filters;
  }

  /// Returns badge label for preview viewport
  static String getSmootherBadge(VideoSmootherConfig config) {
    if (!config.hasActiveSmoothing) return '';

    if (config.isMotionBlurEnabled && config.effectiveInterpolationMode == MotionInterpolationMode.opticalFlow) {
      return '🌪️ BLUR (${config.shutterAngle.toInt()}°) + 🌊 ${config.targetFps}FPS';
    }
    if (config.isMotionBlurEnabled) {
      return '🌪️ MOTION BLUR (${config.shutterAngle.toInt()}°)';
    }
    if ((config.effectiveInterpolationMode == MotionInterpolationMode.opticalFlow || config.isMotionSmoothingEnabled) &&
        config.isStabilizationEnabled) {
      return 'GIMBAL + ${config.targetFps}FPS';
    }
    if (config.effectiveInterpolationMode == MotionInterpolationMode.opticalFlow || config.isMotionSmoothingEnabled) {
      return '🌊 OPTICAL FLOW (${config.targetFps}FPS)';
    }
    if (config.effectiveInterpolationMode == MotionInterpolationMode.frameBlend) {
      return '🔄 FRAME BLEND (${config.targetFps}FPS)';
    }
    if (config.isStabilizationEnabled) {
      return '🛡️ GIMBAL STABILIZED';
    }
    if (config.isDeGlitchEnabled) {
      return 'ANTI-GLITCH';
    }
    return '';
  }
}
