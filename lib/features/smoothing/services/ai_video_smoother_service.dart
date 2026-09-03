import '../models/video_smoother_config.dart';

class AIVideoSmootherService {
  /// Generates the FFmpeg video filter chain for anti-shake stabilization, motion smoothing, and glitch removal
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

    // 4. Optical Flow Frame Rate Smoothing (interpolates in-between frames for fluid 60/120 FPS motion)
    if (config.isMotionSmoothingEnabled) {
      final fps = config.targetFps;
      // High-precision motion compensation interpolation
      filters.add('minterpolate=fps=$fps:mi_mode=mci:mc_mode=aobmc:vsbmc=1');
    }

    return filters;
  }

  /// Returns badge label for preview viewport
  static String getSmootherBadge(VideoSmootherConfig config) {
    if (config.isMotionSmoothingEnabled && config.isStabilizationEnabled) {
      return 'GIMBAL + ${config.targetFps}FPS';
    }
    if (config.isStabilizationEnabled) {
      return 'GIMBAL STABILIZED';
    }
    if (config.isMotionSmoothingEnabled) {
      return '${config.targetFps}FPS FLUID';
    }
    if (config.isDeGlitchEnabled) {
      return 'ANTI-GLITCH';
    }
    return 'STANDARD';
  }
}
