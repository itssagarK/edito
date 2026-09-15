import 'package:flutter/material.dart';
import '../models/chroma_key_config.dart';

class ChromaKeyCompilerService {
  /// Generates the FFmpeg video filter chain for chroma keying and color spill suppression
  static List<String> generateFFmpegFilters(ChromaKeyConfig config) {
    if (!config.isEnabled) return const [];

    final filters = <String>[];
    final color = config.keyColor;
    final hex = '0x${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    // 1. Primary Chromakey filter
    filters.add(
      'chromakey=color=$hex:similarity=${config.similarity.toStringAsFixed(2)}:blend=${config.smoothness.toStringAsFixed(2)}',
    );

    // 2. Alpha channel format
    filters.add('format=yuva420p');

    // 3. Color Spill Suppression filter
    if (config.spill > 0.02) {
      final isBlueDominant = color.blue > color.green && color.blue > color.red;
      final spillType = isBlueDominant ? 'blue' : 'green';
      final spillMix = (config.spill * 2.5).clamp(0.05, 1.0).toStringAsFixed(2);
      filters.add('despill=type=$spillType:mix=$spillMix:expand=0.1');
    }

    return filters;
  }

  /// Returns a clean, human-readable status badge for the preview viewport HUD
  static String getChromaBadge(ChromaKeyConfig config) {
    if (!config.isEnabled) return '';

    final c = config.keyColor;
    final simPct = (config.similarity * 100).round();

    if (config.isLumaKey || (c.red == 0 && c.green == 0 && c.blue == 0)) {
      return '⚫ LUMA KEY (BLACK $simPct%)';
    } else if (c.red == 255 && c.green == 255 && c.blue == 255) {
      return '⚪ LUMA KEY (WHITE $simPct%)';
    } else if (c.green >= c.red && c.green >= c.blue) {
      return '🟢 CHROMA: GREEN ($simPct%)';
    } else if (c.blue > c.green && c.blue > c.red) {
      return '🔵 CHROMA: BLUE ($simPct%)';
    } else if (c.blue > 200 && c.green > 200) {
      return '💠 CHROMA: CYAN ($simPct%)';
    } else {
      return '🎭 CHROMA KEY ($simPct%)';
    }
  }

  /// Generates a 4x5 color matrix for Skia GPU real-time spill suppression in Flutter
  static List<double> generateSpillMatrix(ChromaKeyConfig config) {
    if (!config.isEnabled || config.spill <= 0.01) {
      return const [
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ];
    }

    final c = config.keyColor;
    final spillFactor = (config.spill * 1.5).clamp(0.0, 0.85);

    if (c.green >= c.red && c.green >= c.blue) {
      // Green spill suppression: attenuate green channel and compensate with red/blue
      final gScale = 1.0 - spillFactor;
      final comp = spillFactor * 0.2;
      return [
        1.0, 0.0, 0.0, 0.0, 0.0,
        comp, gScale, comp, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ];
    } else if (c.blue > c.green && c.blue > c.red) {
      // Blue spill suppression: attenuate blue channel
      final bScale = 1.0 - spillFactor;
      final comp = spillFactor * 0.2;
      return [
        1.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        comp, comp, bScale, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ];
    } else {
      return const [
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ];
    }
  }
}
