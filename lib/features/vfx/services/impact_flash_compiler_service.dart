import '../models/impact_flash_config.dart';

class ImpactFlashCompilerService {
  /// Compiles impact flash and strobe settings into native FFmpeg video filter commands
  static List<String> generateFFmpegFilters(
    ImpactFlashConfig config, {
    required int clipDurationMs,
    required int targetWidth,
    required int targetHeight,
  }) {
    if (!config.isActive || clipDurationMs <= 0) return const [];

    final durationSec = (config.durationMs / 1000.0).clamp(0.04, clipDurationMs / 1000.0);
    final dStr = durationSec.toStringAsFixed(3);
    final intensity = config.intensity.clamp(0.1, 1.0);

    final filters = <String>[];

    switch (config.type) {
      case ImpactFlashType.whiteFlash:
        filters.add(
          "drawbox=x=0:y=0:w=iw:h=ih:color=white@${intensity.toStringAsFixed(2)}:t=fill:enable='lte(t,$dStr)'",
        );
        break;

      case ImpactFlashType.blackFlash:
        filters.add(
          "drawbox=x=0:y=0:w=iw:h=ih:color=black@${intensity.toStringAsFixed(2)}:t=fill:enable='lte(t,$dStr)'",
        );
        break;

      case ImpactFlashType.warmGlow:
        final glowOpacity = (intensity * 0.8).clamp(0.1, 1.0).toStringAsFixed(2);
        filters.add(
          "drawbox=x=0:y=0:w=iw:h=ih:color=0xFF9900@$glowOpacity:t=fill:enable='lte(t,$dStr)'",
        );
        break;

      case ImpactFlashType.rgbStrobe:
        final strobeOpacity = (intensity * 0.8).clamp(0.1, 1.0).toStringAsFixed(2);
        filters.add(
          "drawbox=x=0:y=0:w=iw:h=ih:color=0x00E5FF@$strobeOpacity:t=fill:enable='lte(t,$dStr)'",
        );
        break;
    }

    return filters;
  }
}
