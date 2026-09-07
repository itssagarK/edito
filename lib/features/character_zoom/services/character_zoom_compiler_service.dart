import 'dart:math' as math;
import '../models/character_zoom_config.dart';

class CharacterZoomCompilerService {
  /// Compiles CharacterZoomConfig into deterministic FFmpeg video filter chain
  static String generateFFmpegFilter(
    CharacterZoomConfig config, {
    int clipDurationMs = 5000,
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isEnabled) return '';

    final filters = <String>[];
    final cx = config.characterCenterX.clamp(0.05, 0.95).toStringAsFixed(2);
    final cy = config.characterCenterY.clamp(0.05, 0.95).toStringAsFixed(2);
    final zTarget = config.targetZoom.clamp(1.05, 3.0).toStringAsFixed(2);
    final zStart = config.startZoom.clamp(1.0, config.targetZoom).toStringAsFixed(2);
    final durSec = (clipDurationMs / 1000.0).clamp(0.2, 7200.0).toStringAsFixed(2);
    final animSec = config.animationDurationSec.clamp(0.2, 10.0).toStringAsFixed(2);
    final delaySec = config.startDelaySec.clamp(0.0, 5.0).toStringAsFixed(2);

    switch (config.mode) {
      case CharacterZoomMode.punchIn:
      case CharacterZoomMode.closeUpLock:
        // Instant static framing / jump-cut punch-in onto the character
        filters.add(
          "crop=w='iw/$zTarget':h='ih/$zTarget':"
          "x='max(0,min(iw-iw/$zTarget,iw*$cx-(iw/$zTarget)/2))':"
          "y='max(0,min(ih-ih/$zTarget,ih*$cy-(ih/$zTarget)/2))'",
        );
        filters.add('scale=$targetWidth:$targetHeight:flags=lanczos');
        break;

      case CharacterZoomMode.cinematicPushIn:
        // Smooth progressive push-in using smoothstep polynomial easing
        final progExpr = "min(1,max(0,(t-$delaySec)/$animSec))";
        final zExpr = "($zStart+($zTarget-$zStart)*(3*pow($progExpr,2)-2*pow($progExpr,3)))";
        filters.add(
          "crop=w='iw/$zExpr':h='ih/$zExpr':"
          "x='max(0,min(iw-iw/$zExpr,iw*$cx-(iw/$zExpr)/2))':"
          "y='max(0,min(ih-ih/$zExpr,ih*$cy-(ih/$zExpr)/2))'",
        );
        filters.add('scale=$targetWidth:$targetHeight:flags=lanczos');
        break;

      case CharacterZoomMode.dramaticCrash:
        // Rapid high-energy snap zoom in 0.35 seconds
        final crashProg = "min(1,max(0,(t-$delaySec)/0.35))";
        final crashZ = "($zStart+($zTarget-$zStart)*(1-pow(1-$crashProg,3)))";
        filters.add(
          "crop=w='iw/$crashZ':h='ih/$crashZ':"
          "x='max(0,min(iw-iw/$crashZ,iw*$cx-(iw/$crashZ)/2))':"
          "y='max(0,min(ih-ih/$crashZ,ih*$cy-(ih/$crashZ)/2))'",
        );
        filters.add('scale=$targetWidth:$targetHeight:flags=lanczos');
        break;

      case CharacterZoomMode.slowCreep:
        // Subtle tension builder creeping across the entire clip
        final creepProg = "min(1,max(0,t/$durSec))";
        final creepZ = "($zStart+($zTarget-$zStart)*$creepProg)";
        filters.add(
          "crop=w='iw/$creepZ':h='ih/$creepZ':"
          "x='max(0,min(iw-iw/$creepZ,iw*$cx-(iw/$creepZ)/2))':"
          "y='max(0,min(ih-ih/$creepZ,ih*$cy-(ih/$creepZ)/2))'",
        );
        filters.add('scale=$targetWidth:$targetHeight:flags=lanczos');
        break;

      case CharacterZoomMode.pulse:
        // Rhythmic pulsing oscillation
        final pulseZ = "(1.0+($zTarget-1.0)*(0.5+0.5*sin(2*3.14159*t/1.6)))";
        filters.add(
          "crop=w='iw/$pulseZ':h='ih/$pulseZ':"
          "x='max(0,min(iw-iw/$pulseZ,iw*$cx-(iw/$pulseZ)/2))':"
          "y='max(0,min(ih-ih/$pulseZ,ih*$cy-(ih/$pulseZ)/2))'",
        );
        filters.add('scale=$targetWidth:$targetHeight:flags=lanczos');
        break;
    }

    // Optional Focus Vignette centered on the character
    if (config.addFocusVignette) {
      filters.add('vignette=angle=0.75:x0=w*$cx:y0=h*$cy');
    }

    // Optional Subject Aura / Vibrance Pop
    if (config.addSubjectAura) {
      filters.add('eq=saturation=1.20:contrast=1.08');
    }

    return filters.join(',');
  }

  /// Calculates the active scale factor at a given clip timestamp for real-time viewport playback
  static double calculateCurrentScale(
    CharacterZoomConfig config, {
    required int currentClipTimeMs,
    required int clipDurationMs,
  }) {
    if (!config.isEnabled) return 1.0;

    switch (config.mode) {
      case CharacterZoomMode.punchIn:
      case CharacterZoomMode.closeUpLock:
        return config.targetZoom;

      case CharacterZoomMode.cinematicPushIn:
        final elapsedSec = (currentClipTimeMs / 1000.0) - config.startDelaySec;
        if (elapsedSec <= 0) return config.startZoom;
        final progress = (elapsedSec / config.animationDurationSec).clamp(0.0, 1.0);
        // Smoothstep easing (3p^2 - 2p^3)
        final eased = progress * progress * (3.0 - 2.0 * progress);
        return config.startZoom + (config.targetZoom - config.startZoom) * eased;

      case CharacterZoomMode.dramaticCrash:
        final elapsedSec = (currentClipTimeMs / 1000.0) - config.startDelaySec;
        if (elapsedSec <= 0) return config.startZoom;
        final progress = (elapsedSec / 0.35).clamp(0.0, 1.0);
        // Cubic ease-out (1 - (1-p)^3)
        final eased = 1.0 - math.pow(1.0 - progress, 3.0);
        return config.startZoom + (config.targetZoom - config.startZoom) * eased;

      case CharacterZoomMode.slowCreep:
        final totalDur = (clipDurationMs > 0 ? clipDurationMs : 5000) / 1000.0;
        final progress = ((currentClipTimeMs / 1000.0) / totalDur).clamp(0.0, 1.0);
        return config.startZoom + (config.targetZoom - config.startZoom) * progress;

      case CharacterZoomMode.pulse:
        final t = currentClipTimeMs / 1000.0;
        final wave = 0.5 + 0.5 * math.sin(2 * math.pi * t / 1.6);
        return 1.0 + (config.targetZoom - 1.0) * wave;
    }
  }

  /// Returns user-facing HUD badge label
  static String getZoomBadge(CharacterZoomConfig config) {
    if (!config.isEnabled) return '';
    final zoomStr = '${config.targetZoom.toStringAsFixed(1)}x';
    switch (config.mode) {
      case CharacterZoomMode.cinematicPushIn:
        return '🎯 CHARACTER ZOOM ($zoomStr Push)';
      case CharacterZoomMode.punchIn:
        return '⚡ PUNCH-IN ($zoomStr Jump)';
      case CharacterZoomMode.dramaticCrash:
        return '💥 DRAMATIC CRASH ($zoomStr Snap)';
      case CharacterZoomMode.slowCreep:
        return '🕵️ SLOW CREEP ($zoomStr)';
      case CharacterZoomMode.closeUpLock:
        return '🔍 CLOSE-UP LOCK ($zoomStr Crop)';
      case CharacterZoomMode.pulse:
        return '💓 PULSE ZOOM ($zoomStr)';
    }
  }
}
