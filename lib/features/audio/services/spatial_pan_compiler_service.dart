import '../models/spatial_audio_pan_config.dart';

class SpatialPanCompilerService {
  /// Compiles spatial stereo pan and viral 8D orbit filters for native FFmpeg audio pipeline
  static List<String> generateFFmpegFilters(SpatialAudioPanConfig config) {
    if (!config.isActive) return const [];

    final filters = <String>[];

    if (config.is8DOrbitEnabled) {
      // 8D Audio: continuous circular binaural orbit via sinusoidal LFO expression in stereotools
      final freq = config.orbitSpeedHz.clamp(0.05, 5.0).toStringAsFixed(2);
      final depth = config.orbitDepth.clamp(0.1, 1.0).toStringAsFixed(2);
      final basePan = config.pan.clamp(-1.0, 1.0).toStringAsFixed(2);

      final mpanExpr = "($basePan+sin(2*PI*$freq*t)*$depth)";
      filters.add("stereotools=mpan='$mpanExpr'");
    } else {
      // Static stereo balance using equal-power panning
      final gains = config.calculateEqualPowerGains();
      final lGain = gains.$1.toStringAsFixed(3);
      final rGain = gains.$2.toStringAsFixed(3);
      filters.add('pan=stereo|c0=$lGain*c0|c1=$rGain*c1');
    }

    // AGENTS.md Rule 4: True-peak brickwall limiter ceiling to eliminate digital clipping
    filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');

    return filters;
  }
}
