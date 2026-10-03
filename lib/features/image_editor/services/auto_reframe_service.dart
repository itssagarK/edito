import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/ai/services/on_device_segmentation_service.dart';
import '../models/video_layout_config.dart';

class AutoReframeService {
  /// Automatically analyzes video frames on-device using subject segmentation
  /// to detect the average horizontal center-of-mass of the speaker / main subject.
  ///
  /// Returns the optimal focalPointX [-1.0, 1.0] for centering the subject in 9:16 vertical video crops.
  static Future<double> detectOptimalSpeakerFocalPoint({
    required String videoPath,
    required int durationMs,
    int sampleCount = 5,
  }) async {
    if (videoPath.isEmpty || !File(videoPath).existsSync() || durationMs <= 0) {
      return 0.0;
    }

    try {
      final sampleTimes = <int>[];
      final step = durationMs ~/ (sampleCount + 1);
      for (int i = 1; i <= sampleCount; i++) {
        sampleTimes.add(step * i);
      }

      double sumCentroidX = 0.0;
      int validSamples = 0;

      for (final t in sampleTimes) {
        final seg = await OnDeviceSegmentationService.instance.segmentVideoFrame(
          videoPath: videoPath,
          timeMs: t,
        );
        if (seg.isSuccess) {
          sumCentroidX += seg.centroidX;
          validSamples++;
        }
      }

      if (validSamples > 0) {
        final avgX = sumCentroidX / validSamples; // 0.0 (left) to 1.0 (right), 0.5 center
        // Convert [0.0, 1.0] to pan-and-scan focalPointX [-1.0, 1.0]
        final fx = ((avgX - 0.5) * 2.0).clamp(-0.85, 0.85);
        return fx;
      }
    } catch (e) {
      debugPrint('Auto-reframe speaker detection note: $e');
    }

    return 0.0;
  }
  /// Generates the deterministic FFmpeg filter expression for canvas reframing
  static String generateFFmpegFilter({
    required VideoLayoutConfig layout,
    required int targetWidth,
    required int targetHeight,
    int trackIndex = 0,
  }) {
    final evenTargetW = (targetWidth ~/ 2) * 2;
    final evenTargetH = (targetHeight ~/ 2) * 2;
    final padPx = layout.framePadding.round();
    final innerW = ((evenTargetW - (padPx * 2)).clamp(32, evenTargetW) ~/ 2) * 2;
    final innerH = ((evenTargetH - (padPx * 2)).clamp(32, evenTargetH) ~/ 2) * 2;

    switch (layout.reframeMode) {
      case AutoReframeMode.fitWithBlur:
        final blurRadius = layout.blurIntensity.clamp(5.0, 50.0).round();
        // Cloned blurred video background: split into background and foreground streams
        return 'split=2[fg_raw][bg_raw];'
            '[bg_raw]scale=$targetWidth:$targetHeight:force_original_aspect_ratio=increase,crop=$targetWidth:$targetHeight,gblur=sigma=$blurRadius:steps=2[bg_blur];'
            '[fg_raw]scale=$innerW:$innerH:force_original_aspect_ratio=decrease:flags=lanczos[fg_scaled];'
            '[bg_blur][fg_scaled]overlay=(W-w)/2:(H-h)/2';

      case AutoReframeMode.smartCrop:
        // Pan-and-scan intelligent crop centering active subject
        final fx = layout.focalPointX.clamp(-1.0, 1.0);
        final fy = layout.focalPointY.clamp(-1.0, 1.0);

        if (fx == 0.0 && fy == 0.0) {
          return 'scale=$targetWidth:$targetHeight:force_original_aspect_ratio=increase:flags=lanczos,'
              'crop=$targetWidth:$targetHeight:(iw-ow)/2:(ih-oh)/2';
        } else {
          final fxStr = fx.toStringAsFixed(2);
          final fyStr = fy.toStringAsFixed(2);
          return 'scale=$targetWidth:$targetHeight:force_original_aspect_ratio=increase:flags=lanczos,'
              "crop=$targetWidth:$targetHeight:'(iw-ow)/2 + ($fxStr * (iw-ow)/2)':'(ih-oh)/2 + ($fyStr * (ih-oh)/2)'";
        }

      case AutoReframeMode.gradientCanvas:
        final primaryColor = layout.gradientPreset.colors.first;
        final hex = '0x${primaryColor.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
        final padColor = trackIndex > 0 ? 'black@0' : hex;
        return 'scale=$innerW:$innerH:force_original_aspect_ratio=decrease:flags=lanczos,'
            'pad=$targetWidth:$targetHeight:(ow-iw)/2:(oh-ih)/2:color=$padColor';

      case AutoReframeMode.solidPillarbox:
        final hex = '0x${layout.backgroundColor.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
        final padColor = trackIndex > 0 ? 'black@0' : hex;
        return 'scale=$innerW:$innerH:force_original_aspect_ratio=decrease:flags=lanczos,'
            'pad=$targetWidth:$targetHeight:(ow-iw)/2:(oh-ih)/2:color=$padColor';
    }
  }

  /// Returns a live HUD badge describing active reframing state
  static String getReframeBadge(VideoLayoutConfig layout) {
    final ratioStr = layout.ratio.label.split(' ').first;
    switch (layout.reframeMode) {
      case AutoReframeMode.fitWithBlur:
        return '📐 REFRAME: $ratioStr (BLUR CLONE)';
      case AutoReframeMode.smartCrop:
        final panInfo = layout.focalPointX != 0.0 ? ' PAN ${(layout.focalPointX * 100).toInt()}%' : '';
        return '📐 REFRAME: $ratioStr (SMART CROP$panInfo)';
      case AutoReframeMode.solidPillarbox:
        return '📐 REFRAME: $ratioStr (SOLID FRAME)';
      case AutoReframeMode.gradientCanvas:
        return '📐 REFRAME: $ratioStr (${layout.gradientPreset.label.toUpperCase()})';
    }
  }
}
