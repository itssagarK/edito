import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/ai/services/on_device_segmentation_service.dart';

class CutoutResult {
  final bool isSuccess;
  final String? outputPath;
  final String? errorMessage;
  final double centroidX;
  final double centroidY;
  final List<double> boundingBox;

  const CutoutResult({
    required this.isSuccess,
    this.outputPath,
    this.errorMessage,
    this.centroidX = 0.5,
    this.centroidY = 0.5,
    this.boundingBox = const [0.2, 0.1, 0.8, 0.9],
  });
}

/// 100% Offline, On-Device AI Background Removal Service
/// Replaces legacy cloud Remove.bg API with local neural selfie segmentation.
class AiBackgroundRemovalService {
  /// Removes background from an image file using 100% on-device MediaPipe Selfie Segmentation
  static Future<CutoutResult> removeBackground(String imagePath) async {
    final inputFile = File(imagePath);
    if (!inputFile.existsSync()) {
      return const CutoutResult(
        isSuccess: false,
        errorMessage: 'Source image does not exist on disk.',
      );
    }

    try {
      final res = await OnDeviceSegmentationService.instance.segmentFrame(
        imagePath: imagePath,
      );

      if (res.isSuccess && res.maskPath != null) {
        return CutoutResult(
          isSuccess: true,
          outputPath: res.maskPath,
          centroidX: res.centroidX,
          centroidY: res.centroidY,
          boundingBox: res.boundingBox,
        );
      } else {
        return CutoutResult(
          isSuccess: false,
          errorMessage: res.errorMessage ?? 'On-device segmentation failed.',
        );
      }
    } catch (e) {
      debugPrint('On-device background removal error: $e');
      return CutoutResult(
        isSuccess: false,
        errorMessage: 'Background removal error: $e',
      );
    }
  }
}
