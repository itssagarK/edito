import 'dart:math' as math;
import '../../../models/clip.dart';
import '../../color_grading/models/color_grading_config.dart';
import '../models/auto_velocity_config.dart';
import '../models/speed_curve_preset.dart';

class AutoVelocityService {
  /// Generates a beat-synchronized dynamic speed curve with explosive surges on beat hits
  static SpeedCurveConfig generateVelocityCurve(
    Clip clip,
    AutoVelocityConfig config, {
    List<int>? explicitBeatMs,
    double? fallbackBpm,
  }) {
    if (!config.isEnabled) {
      return clip.speedCurve;
    }

    final durationMs = clip.durationMs;
    if (durationMs <= 200) {
      return const SpeedCurveConfig();
    }

    // 1. Resolve beat timestamps relative to clip start (0 to durationMs)
    final beats = <int>[];
    if (explicitBeatMs != null && explicitBeatMs.isNotEmpty) {
      beats.addAll(explicitBeatMs.where((b) => b >= 0 && b <= durationMs));
    } else if (clip.beatConfig.hasBeats) {
      beats.addAll(clip.beatConfig.beatTimestampsMs.where((b) => b >= 0 && b <= durationMs));
    }

    // If no explicit beats, synthesize grid from BPM (default 120 BPM)
    if (beats.isEmpty) {
      final bpm = fallbackBpm ?? (clip.beatConfig.bpm > 0 ? clip.beatConfig.bpm : 120.0);
      double beatInterval = 60000.0 / bpm;
      if (config.interval == VelocityInterval.halfBeat) {
        beatInterval /= 2.0;
      } else if (config.interval == VelocityInterval.doubleBeat) {
        beatInterval *= 2.0;
      }

      double currentMs = beatInterval;
      while (currentMs < durationMs) {
        beats.add(currentMs.round());
        currentMs += beatInterval;
      }
    }

    if (beats.isEmpty) {
      return const SpeedCurveConfig();
    }

    // 2. Construct cubic Bezier speed points
    final rawPoints = <CurvePoint>[];
    rawPoints.add(CurvePoint(0.0, config.slowSpeed));

    final windowMs = (durationMs / (beats.length * 2.5)).clamp(60.0, 300.0);

    for (final beat in beats) {
      final beatNorm = (beat / durationMs).clamp(0.0, 1.0);
      final rampInNorm = ((beat - windowMs * 0.4) / durationMs).clamp(0.0, 1.0);
      final rampOutNorm = ((beat + windowMs * 0.6) / durationMs).clamp(0.0, 1.0);

      // Pre-beat slow valley
      if (rampInNorm > 0.02 && rampInNorm < beatNorm - 0.01) {
        rawPoints.add(CurvePoint(rampInNorm, config.slowSpeed));
      }

      // Exact Beat Peak Burst
      rawPoints.add(CurvePoint(beatNorm, config.fastSpeed));

      // Post-beat deceleration
      if (rampOutNorm < 0.98 && rampOutNorm > beatNorm + 0.01) {
        rawPoints.add(CurvePoint(rampOutNorm, config.slowSpeed));
      }
    }

    rawPoints.add(CurvePoint(1.0, config.slowSpeed));

    // Sort by x and deduplicate
    rawPoints.sort((a, b) => a.x.compareTo(b.x));

    final sanitizedPoints = <CurvePoint>[];
    for (final p in rawPoints) {
      if (sanitizedPoints.isEmpty) {
        sanitizedPoints.add(p);
      } else {
        final last = sanitizedPoints.last;
        if ((p.x - last.x).abs() > 0.015) {
          sanitizedPoints.add(p);
        } else if (p.y > last.y) {
          sanitizedPoints[sanitizedPoints.length - 1] = p; // Keep higher peak
        }
      }
    }

    // Ensure strictly starts at 0.0 and ends at 1.0
    if (sanitizedPoints.first.x > 0.0) {
      sanitizedPoints.insert(0, CurvePoint(0.0, config.slowSpeed));
    }
    if (sanitizedPoints.last.x < 1.0) {
      sanitizedPoints.add(CurvePoint(1.0, config.slowSpeed));
    }

    return SpeedCurveConfig(
      type: SpeedCurveType.custom,
      curvePoints: sanitizedPoints,
      isSmoothSlowMo: config.enableSmoothSlowMo,
      enablePitchCorrection: true,
    );
  }

  /// Calculates dynamic micro-zoom scale multiplier for current frame playback
  static double calculateMicroZoom(
    int currentClipTimeMs,
    List<int> beatTimestamps,
    AutoVelocityConfig config,
  ) {
    if (!config.isEnabled || !config.enableMicroZoom || beatTimestamps.isEmpty) {
      return 1.0;
    }

    const decayWindowMs = 140.0;
    double maxZoom = 1.0;

    for (final beat in beatTimestamps) {
      final delta = (currentClipTimeMs - beat).abs();
      if (delta <= decayWindowMs) {
        final factor = 1.0 - (delta / decayWindowMs);
        final currentZoom = 1.0 + ((config.microZoomFactor - 1.0) * (factor * factor));
        if (currentZoom > maxZoom) {
          maxZoom = currentZoom;
        }
      }
    }

    return maxZoom;
  }

  /// Calculates dynamic white flash pulse opacity for current frame playback
  static double calculateFlashOpacity(
    int currentClipTimeMs,
    List<int> beatTimestamps,
    AutoVelocityConfig config,
  ) {
    if (!config.isEnabled || !config.enableFlashPulse || beatTimestamps.isEmpty) {
      return 0.0;
    }

    const flashDurationMs = 100.0;
    double maxOpacity = 0.0;

    for (final beat in beatTimestamps) {
      final delta = currentClipTimeMs - beat;
      // Flash triggers on beat and decays forward
      if (delta >= 0 && delta <= flashDurationMs) {
        final progress = 1.0 - (delta / flashDurationMs);
        final opacity = (config.flashIntensity * 0.75 * progress).clamp(0.0, 1.0);
        if (opacity > maxOpacity) {
          maxOpacity = opacity;
        }
      }
    }

    return maxOpacity;
  }

  /// Compiles synchronized visual micro-effects into FFmpeg filter chain
  static List<String> generateFFmpegFilters(
    Clip clip,
    AutoVelocityConfig config, {
    List<int>? beatTimestamps,
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isEnabled) return const [];

    final filters = <String>[];
    final beats = beatTimestamps ?? clip.beatConfig.beatTimestampsMs;

    if (beats.isNotEmpty && config.enableFlashPulse) {
      // Build periodic brightness flash expressions for beats
      final conditions = <String>[];
      for (final b in beats.take(12)) {
        final tSec = (b / 1000.0).toStringAsFixed(3);
        conditions.add('between(t\\,$tSec\\,$tSec+0.08)');
      }
      if (conditions.isNotEmpty) {
        final condStr = conditions.join('+');
        final boost = (config.flashIntensity * 0.35).toStringAsFixed(2);
        filters.add('eq=brightness=\'if($condStr\\,$boost\\,0.0)\'');
      }
    }

    if (config.enableRgbGlitch) {
      filters.add('rgbashift=rh=5:bh=-5');
    }

    return filters;
  }

  /// Returns user-facing badge string for preview viewport HUD
  static String getBadge(AutoVelocityConfig config) {
    if (!config.isEnabled) return '';
    final burst = '${config.fastSpeed.toStringAsFixed(1)}x';
    switch (config.style) {
      case AutoVelocityStyle.classic:
        return '⚡ AUTO-VELOCITY ($burst)';
      case AutoVelocityStyle.phonkTrap:
        return '💥 PHONK RUSH ($burst + FLASH)';
      case AutoVelocityStyle.hyperDrift:
        return '🌊 HYPER-DRIFT ($burst)';
      case AutoVelocityStyle.stutterBpm:
        return '🥁 STUTTER BPM ($burst)';
      case AutoVelocityStyle.lofiChill:
        return '☕ LOFI EBB & FLOW';
    }
  }
}
