import 'package:flutter/material.dart';
import '../models/blend_mode_config.dart';

class BlendModeCompilerService {
  /// Converts a [ProBlendMode] to Flutter's native [BlendMode] for real-time viewport compositing.
  static BlendMode toFlutterBlendMode(ProBlendMode mode) {
    switch (mode) {
      case ProBlendMode.normal:
        return BlendMode.srcOver;
      case ProBlendMode.screen:
        return BlendMode.screen;
      case ProBlendMode.multiply:
        return BlendMode.multiply;
      case ProBlendMode.overlay:
        return BlendMode.overlay;
      case ProBlendMode.softLight:
        return BlendMode.softLight;
      case ProBlendMode.hardLight:
        return BlendMode.hardLight;
      case ProBlendMode.colorDodge:
        return BlendMode.colorDodge;
      case ProBlendMode.colorBurn:
        return BlendMode.colorBurn;
      case ProBlendMode.darken:
        return BlendMode.darken;
      case ProBlendMode.lighten:
        return BlendMode.lighten;
      case ProBlendMode.difference:
        return BlendMode.difference;
      case ProBlendMode.exclusion:
        return BlendMode.exclusion;
    }
  }

  /// Generates the two-input FFmpeg compositing filter segment connecting [baseLabel] and [overlayLabel].
  static String generateFFmpegLayerCompositor({
    required BlendModeConfig config,
    required String baseLabel,
    required String overlayLabel,
    required String outputLabel,
    String? enableExpression,
  }) {
    final double opacity = config.opacity.clamp(0.0, 1.0);
    final String enableStr = (enableExpression != null && enableExpression.isNotEmpty)
        ? ":enable='$enableExpression'"
        : "";

    if (config.mode == ProBlendMode.normal) {
      // Standard alpha overlay
      return '[$baseLabel][$overlayLabel]overlay=eof_action=pass$enableStr[$outputLabel]';
    }

    // High-end mathematical blend filter (screen, multiply, overlay, dodge, etc.)
    final String modeName = config.mode.ffmpegModeName;
    return '[$baseLabel][$overlayLabel]blend=all_mode=$modeName:all_opacity=${opacity.toStringAsFixed(2)}$enableStr[$outputLabel]';
  }

  /// Generates in-stream opacity filters for standalone clip adjustment.
  static List<String> generateInStreamFilters(BlendModeConfig config) {
    if (!config.isEnabled) return [];

    final double opacity = config.opacity.clamp(0.0, 1.0);
    if (opacity < 0.999) {
      return [
        'format=yuva420p',
        'colorchannelmixer=aa=${opacity.toStringAsFixed(2)}',
      ];
    }
    return [];
  }
}
