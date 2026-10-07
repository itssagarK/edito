import '../models/camera_shake_config.dart';

class CameraShakeCompilerService {
  /// Compiles an FFmpeg video filter string for dynamic camera shake.
  /// Uses a crop window with harmonic sinusoidal displacement expressions
  /// scaled back to full resolution to prevent black border artifacts.
  static String? compileFilter(CameraShakeConfig config) {
    if (!config.isEnabled || config.intensity <= 0.001) {
      return null;
    }

    // Zoom crop factor (0.90 to 0.95 depending on intensity)
    // Higher intensity requires larger margin so edges don't leave canvas
    final margin = 0.05 + (config.intensity * 0.07); // 0.05 to 0.12
    final cropFactor = (1.0 - margin).clamp(0.85, 0.95);

    // Amplitudes in pixels for 1080p canvas baseline
    final maxDisplacementX = (config.intensity * 24.0).clamp(2.0, 48.0);
    final maxDisplacementY = (config.intensity * 18.0).clamp(2.0, 36.0);
    final speed = config.speed.clamp(0.2, 3.0);

    // Frequency coefficients based on shake type
    double freqX1;
    double freqX2;
    double freqY1;
    double freqY2;

    switch (config.shakeType) {
      case CameraShakeType.handheld:
        freqX1 = 0.28 * speed;
        freqX2 = 0.14 * speed;
        freqY1 = 0.35 * speed;
        freqY2 = 0.21 * speed;
        break;
      case CameraShakeType.earthquake:
        freqX1 = 0.85 * speed;
        freqX2 = 1.35 * speed;
        freqY1 = 0.95 * speed;
        freqY2 = 1.45 * speed;
        break;
      case CameraShakeType.carBumpy:
        freqX1 = 0.65 * speed;
        freqX2 = 0.45 * speed;
        freqY1 = 0.78 * speed;
        freqY2 = 0.52 * speed;
        break;
      case CameraShakeType.heartbeatPulse:
        freqX1 = 0.18 * speed;
        freqX2 = 0.36 * speed;
        freqY1 = 0.42 * speed;
        freqY2 = 0.84 * speed;
        break;
      case CameraShakeType.impactTremor:
        freqX1 = 1.10 * speed;
        freqX2 = 0.55 * speed;
        freqY1 = 1.25 * speed;
        freqY2 = 0.70 * speed;
        break;
    }

    final ampX1 = maxDisplacementX.toStringAsFixed(1);
    final ampX2 = (maxDisplacementX * 0.45).toStringAsFixed(1);
    final ampY1 = maxDisplacementY.toStringAsFixed(1);
    final ampY2 = (maxDisplacementY * 0.55).toStringAsFixed(1);

    final fX1 = freqX1.toStringAsFixed(3);
    final fX2 = freqX2.toStringAsFixed(3);
    final fY1 = freqY1.toStringAsFixed(3);
    final fY2 = freqY2.toStringAsFixed(3);

    final cropW = 'trunc(in_w*${cropFactor.toStringAsFixed(3)}/2)*2';
    final cropH = 'trunc(in_h*${cropFactor.toStringAsFixed(3)}/2)*2';

    final exprX = "(in_w-out_w)/2+sin(n*$fX1)*$ampX1+cos(n*$fX2)*$ampX2";
    final exprY = "(in_h-out_h)/2+cos(n*$fY1)*$ampY1+sin(n*$fY2)*$ampY2";

    final cropFilter = "crop=w=$cropW:h=$cropH:x='$exprX':y='$exprY'";
    final scaleBack = "scale=in_w:in_h:flags=lanczos";

    return "$cropFilter,$scaleBack";
  }

  /// Generates filter list for FFmpeg export pipeline
  static List<String> generateFFmpegFilters(CameraShakeConfig config) {
    final filter = compileFilter(config);
    if (filter == null || filter.isEmpty) return [];
    return [filter];
  }

  /// Formats human-readable status badge for playback HUD
  static String getHudBadge(CameraShakeConfig config) {
    if (!config.isEnabled) return 'Shake OFF';
    final pct = (config.intensity * 100).round();
    return '${config.shakeType.displayName} ($pct%)';
  }
}
