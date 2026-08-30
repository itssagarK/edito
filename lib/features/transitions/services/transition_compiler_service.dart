import '../models/transition_type.dart';

class TransitionCompilerService {
  /// Generates the FFmpeg xfade filter expression for a transition
  static String generateFFmpegXFade(
    TransitionConfig config, {
    required double offsetSec,
  }) {
    if (!config.isEnabled) return '';

    final transitionName = config.type.ffmpegXFadeName;
    if (transitionName.isEmpty) return '';

    final durationSec = (config.durationMs / 1000.0).toStringAsFixed(2);
    final offsetStr = offsetSec.toStringAsFixed(2);

    return 'xfade=transition=$transitionName:duration=$durationSec:offset=$offsetStr';
  }
}
