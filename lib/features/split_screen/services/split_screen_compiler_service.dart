import 'dart:ui';
import '../models/split_screen_config.dart';
import '../models/split_screen_preset.dart';

class SplitScreenCompilerService {
  /// Resolves normalized rectangles for every cell in the preset
  static List<Rect> resolveCellRects(SplitScreenPresetType preset) {
    return preset.cellRects;
  }

  /// Calculates absolute pixel bounds for a given cell on target canvas size
  static Rect resolveAbsoluteCellRect(
    SplitScreenPresetType preset,
    int cellIndex,
    double canvasWidth,
    double canvasHeight,
  ) {
    final rects = preset.cellRects;
    if (cellIndex < 0 || cellIndex >= rects.length) {
      return Rect.fromLTWH(0, 0, canvasWidth, canvasHeight);
    }
    final norm = rects[cellIndex];
    return Rect.fromLTWH(
      norm.left * canvasWidth,
      norm.top * canvasHeight,
      norm.width * canvasWidth,
      norm.height * canvasHeight,
    );
  }

  /// Generates FFmpeg complex filter expressions for compositing multi-grid split screens
  static String buildFFmpegFilterGraph({
    required SplitScreenConfig config,
    required List<String> inputLabels,
    int outputWidth = 1920,
    int outputHeight = 1080,
  }) {
    if (!config.isEnabled || inputLabels.isEmpty) {
      return '';
    }

    final rects = config.preset.cellRects;
    final int cellCount = rects.length;
    final buffer = StringBuffer();
    final cellOutputs = <String>[];

    // 1. Scale and crop each input to fit its cell rectangle
    for (int i = 0; i < cellCount; i++) {
      final input = i < inputLabels.length ? inputLabels[i] : inputLabels.last;
      final normRect = rects[i];
      final cellW = (normRect.width * outputWidth).round().clamp(2, outputWidth);
      final cellH = (normRect.height * outputHeight).round().clamp(2, outputHeight);
      final outLabel = 'cell_$i';

      // Ensure dimensions are even numbers for FFmpeg H.264
      final safeW = cellW % 2 == 0 ? cellW : cellW - 1;
      final safeH = cellH % 2 == 0 ? cellH : cellH - 1;

      buffer.write(
        '[$input]scale=$safeW:$safeH:force_original_aspect_ratio=increase,'
        'crop=$safeW:$safeH[${outLabel}]; ',
      );
      cellOutputs.add(outLabel);
    }

    // 2. Composite using xstack with geometric layout coordinates
    final layoutCoords = <String>[];
    for (int i = 0; i < cellCount; i++) {
      final normRect = rects[i];
      final x = (normRect.left * outputWidth).round();
      final y = (normRect.top * outputHeight).round();
      layoutCoords.add('${x}_${y}');
    }

    final inputsConcat = cellOutputs.map((lbl) => '[$lbl]').join();
    final layoutParam = layoutCoords.join('|');

    buffer.write(
      '${inputsConcat}xstack=inputs=$cellCount:layout=$layoutParam:fill=black[split_base]; ',
    );

    // 3. Optional Border Frame Overlay
    if (config.borderWidth > 0.0) {
      // Draw grid line borders
      final hexColor = config.borderColor.toRadixString(16).padLeft(8, '0');
      final rgb = hexColor.substring(2); // ignore alpha for drawbox
      buffer.write(
        '[split_base]drawbox=x=0:y=0:w=$outputWidth:h=$outputHeight:color=0x$rgb@1.0:t=${config.borderWidth.round()}[split_out]',
      );
    } else {
      buffer.write('[split_base]copy[split_out]');
    }

    return buffer.toString();
  }
}
