import '../models/ken_burns_config.dart';

class KenBurnsCompilerService {
  /// Compiles Ken Burns dynamic 2D camera motion into native FFmpeg video filter commands
  static List<String> generateFFmpegFilters(
    KenBurnsConfig config, {
    required int clipDurationMs,
    required int targetWidth,
    required int targetHeight,
  }) {
    if (!config.isActive) return const [];

    final durationSec = (clipDurationMs / 1000.0).clamp(0.1, 86400.0);
    final intensity = config.intensity.clamp(0.05, 0.60);
    final dStr = durationSec.toStringAsFixed(3);
    final iStr = intensity.toStringAsFixed(3);

    final filters = <String>[];

    switch (config.mode) {
      case KenBurnsMode.zoomIn:
        // Scale/crop expression: zoom smoothly in from 1.0 to 1.0 + intensity
        filters.add(
          "crop=w='iw/(1.0+${iStr}*min(t/$dStr,1.0))':h='ih/(1.0+${iStr}*min(t/$dStr,1.0))':x='(iw-ow)/2':y='(ih-oh)/2',scale=$targetWidth:$targetHeight",
        );
        break;

      case KenBurnsMode.zoomOut:
        // Zoom smoothly out from 1.0 + intensity to 1.0
        filters.add(
          "crop=w='iw/(1.0+${iStr}*(1.0-min(t/$dStr,1.0)))':h='ih/(1.0+${iStr}*(1.0-min(t/$dStr,1.0)))':x='(iw-ow)/2':y='(ih-oh)/2',scale=$targetWidth:$targetHeight",
        );
        break;

      case KenBurnsMode.panLeft:
        // Slight base zoom, smoothly pan camera from right to left
        final baseZoom = (1.0 + intensity * 0.5).toStringAsFixed(3);
        filters.add(
          "crop=w='iw/$baseZoom':h='ih/$baseZoom':x='(iw-ow)*(1.0-min(t/$dStr,1.0))':y='(ih-oh)/2',scale=$targetWidth:$targetHeight",
        );
        break;

      case KenBurnsMode.panRight:
        // Slight base zoom, smoothly pan camera from left to right
        final baseZoom = (1.0 + intensity * 0.5).toStringAsFixed(3);
        filters.add(
          "crop=w='iw/$baseZoom':h='ih/$baseZoom':x='(iw-ow)*min(t/$dStr,1.0)':y='(ih-oh)/2',scale=$targetWidth:$targetHeight",
        );
        break;

      case KenBurnsMode.diagonalDrift:
        // Zoom in while drifting diagonally across frame
        filters.add(
          "crop=w='iw/(1.0+${iStr}*min(t/$dStr,1.0))':h='ih/(1.0+${iStr}*min(t/$dStr,1.0))':x='(iw-ow)*min(t/$dStr,1.0)':y='(ih-oh)*min(t/$dStr,1.0)',scale=$targetWidth:$targetHeight",
        );
        break;

      case KenBurnsMode.none:
        break;
    }

    return filters;
  }
}
