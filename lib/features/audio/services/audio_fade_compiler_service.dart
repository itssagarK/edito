import '../models/audio_fade_config.dart';

class AudioFadeCompilerService {
  /// Compiles audio fade in & fade out envelope settings into native FFmpeg audio filter commands
  static List<String> generateFFmpegFilters(
    AudioFadeConfig config, {
    required int clipDurationMs,
  }) {
    if (!config.hasFade || clipDurationMs <= 0) return const [];

    final filters = <String>[];
    final totalSec = clipDurationMs / 1000.0;
    final curve = config.curve.ffmpegCurveName;

    // Fade In
    if (config.fadeInDurationMs > 0) {
      final inSec = (config.fadeInDurationMs / 1000.0).clamp(0.02, totalSec / 2.0);
      filters.add('afade=t=in:ss=0:d=${inSec.toStringAsFixed(3)}:curve=$curve');
    }

    // Fade Out
    if (config.fadeOutDurationMs > 0) {
      final outSec = (config.fadeOutDurationMs / 1000.0).clamp(0.02, totalSec / 2.0);
      final startSec = (totalSec - outSec).clamp(0.0, totalSec);
      filters.add('afade=t=out:st=${startSec.toStringAsFixed(3)}:d=${outSec.toStringAsFixed(3)}:curve=$curve');
    }

    return filters;
  }
}
