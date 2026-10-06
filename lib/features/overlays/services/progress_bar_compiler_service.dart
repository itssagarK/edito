import 'package:flutter/material.dart';
import '../models/progress_bar_config.dart';

class ProgressBarCompilerService {
  /// Compiles social retention progress bar into native FFmpeg video filter commands
  static List<String> generateFFmpegFilters(
    ProgressBarConfig config, {
    required int totalDurationMs,
    required int targetWidth,
    required int targetHeight,
  }) {
    if (!config.enabled || totalDurationMs <= 0) return const [];

    final durationSec = (totalDurationMs / 1000.0).clamp(0.1, 86400.0).toStringAsFixed(3);
    final scale = targetHeight / 720.0;
    final barHeight = (config.height * scale).round().clamp(2, 60);

    final yPos = config.position == ProgressBarPosition.top
        ? 0
        : targetHeight - barHeight;

    final primaryColor = config.colors.isNotEmpty ? config.colors.first : const Color(0xFF00E5FF);
    final hexVal = primaryColor.value.toRadixString(16).padLeft(8, '0');
    final colorHex = hexVal.length == 8 ? hexVal.substring(2) : hexVal;

    final filters = <String>[];

    // 1. Subtle background track bar (semi-transparent dark)
    filters.add(
      'drawbox=x=0:y=$yPos:w=iw:h=$barHeight:color=black@0.45:t=fill',
    );

    // 2. Glow layer if enabled
    if (config.glow) {
      final glowHeight = (barHeight * 1.6).round().clamp(3, 80);
      final glowY = config.position == ProgressBarPosition.top
          ? 0
          : targetHeight - glowHeight;
      filters.add(
        "drawbox=x=0:y=$glowY:w='min(iw,iw*(t/$durationSec))':h=$glowHeight:color=0x$colorHex@0.30:t=fill",
      );
    }

    // 3. Dynamic progress bar expanding with playback time
    filters.add(
      "drawbox=x=0:y=$yPos:w='min(iw,iw*(t/$durationSec))':h=$barHeight:color=0x$colorHex@1.0:t=fill",
    );

    return filters;
  }
}
