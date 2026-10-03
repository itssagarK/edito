import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../ai_model_manager.dart';
import '../models/ai_model_descriptor.dart';
import '../on_device_inference_runner.dart';
import '../device_tier_service.dart';

/// Result of an on-device subject segmentation inference
class SegmentationResult extends Equatable {
  final bool isSuccess;
  final String? maskPath;
  final double centroidX;
  final double centroidY;
  final List<double> boundingBox;
  final double subjectAreaRatio;
  final int width;
  final int height;
  final String? errorMessage;

  const SegmentationResult({
    required this.isSuccess,
    this.maskPath,
    this.centroidX = 0.5,
    this.centroidY = 0.5,
    this.boundingBox = const [0.2, 0.1, 0.8, 0.9],
    this.subjectAreaRatio = 0.35,
    this.width = 1920,
    this.height = 1080,
    this.errorMessage,
  });

  factory SegmentationResult.failure(String message) {
    return SegmentationResult(
      isSuccess: false,
      errorMessage: message,
    );
  }

  factory SegmentationResult.fromMap(Map<dynamic, dynamic> map) {
    final rawBbox = map['bbox'] as List<dynamic>?;
    final bbox = rawBbox != null
        ? rawBbox.map((e) => (e as num).toDouble()).toList()
        : const [0.2, 0.1, 0.8, 0.9];

    return SegmentationResult(
      isSuccess: map['isSuccess'] as bool? ?? false,
      maskPath: map['maskPath'] as String?,
      centroidX: (map['centroidX'] as num?)?.toDouble() ?? 0.5,
      centroidY: (map['centroidY'] as num?)?.toDouble() ?? 0.5,
      boundingBox: bbox,
      subjectAreaRatio: (map['subjectAreaRatio'] as num?)?.toDouble() ?? 0.35,
      width: (map['width'] as num?)?.toInt() ?? 1920,
      height: (map['height'] as num?)?.toInt() ?? 1080,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'isSuccess': isSuccess,
        'maskPath': maskPath,
        'centroidX': centroidX,
        'centroidY': centroidY,
        'bbox': boundingBox,
        'subjectAreaRatio': subjectAreaRatio,
        'width': width,
        'height': height,
        'errorMessage': errorMessage,
      };

  @override
  List<Object?> get props => [
        isSuccess,
        maskPath,
        centroidX,
        centroidY,
        boundingBox,
        subjectAreaRatio,
        width,
        height,
        errorMessage,
      ];
}

/// 100% Offline, On-Device Subject Segmentation Service
/// Powers Character Highlight, B&W Background Pop, Neon Aura, and Smart Cutout.
class OnDeviceSegmentationService {
  static final OnDeviceSegmentationService instance = OnDeviceSegmentationService._();
  OnDeviceSegmentationService._();

  static const MethodChannel _channel = MethodChannel('com.edito.app/gallery');

  /// Check whether the selfie segmentation model is ready
  Future<bool> isModelInstalled() async {
    return AiModelManager.instance.isModelInstalled(AiModelCatalog.selfieSegmentation);
  }

  /// Ensure model is present locally (extracts bundled asset or verifies disk storage)
  Future<File> ensureModelReady({
    Function(double progress)? onDownloadProgress,
  }) async {
    return AiModelManager.instance.ensureModelInstalled(
      AiModelCatalog.selfieSegmentation,
      onProgress: onDownloadProgress != null
          ? (p) => onDownloadProgress(p.progress)
          : null,
    );
  }

  /// Extracts a video frame at [timeMs] into a temporary image file
  Future<String?> extractVideoFrame({
    required String videoPath,
    required int timeMs,
  }) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final frameDir = Directory(p.join(cacheDir.path, 'frames'));
      if (!await frameDir.exists()) {
        await frameDir.create(recursive: true);
      }
      final outPath = p.join(
        frameDir.path,
        'frame_${p.basenameWithoutExtension(videoPath)}_$timeMs.jpg',
      );

      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'extractVideoFrameAtTime',
        {
          'videoPath': videoPath,
          'timeMs': timeMs,
          'outputPath': outPath,
        },
      );

      if (res != null && res['isSuccess'] == true) {
        return res['outputPath'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error extracting video frame: $e');
      return null;
    }
  }

  /// Segments the foreground subject in a static image frame
  Future<SegmentationResult> segmentFrame({
    required String imagePath,
    CancellationToken? cancelToken,
    double temporalSmoothing = 0.65,
  }) async {
    return OnDeviceInferenceRunner.instance.runHeavyInference(
      taskName: 'SelfieSegmentation',
      cancelToken: cancelToken,
      action: () async {
        // Retrieve local model path if installed
        String? modelPath;
        try {
          if (await isModelInstalled()) {
            final modelFile = await ensureModelReady();
            modelPath = modelFile.path;
          }
        } catch (e) {
          debugPrint('Model path lookup note: using native on-device pipeline fallback ($e)');
        }

        final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'segmentSubjectOnDevice',
          {
            'imagePath': imagePath,
            'modelPath': modelPath,
            'temporalSmoothing': temporalSmoothing,
          },
        );

        if (res == null) {
          return SegmentationResult.failure('Platform channel returned null for segmentation');
        }

        return SegmentationResult.fromMap(res);
      },
    );
  }

  /// Extracts frame at [timeMs] from [videoPath] and segments the subject
  Future<SegmentationResult> segmentVideoFrame({
    required String videoPath,
    required int timeMs,
    CancellationToken? cancelToken,
    double temporalSmoothing = 0.65,
  }) async {
    final framePath = await extractVideoFrame(
      videoPath: videoPath,
      timeMs: timeMs,
    );

    if (framePath == null || !File(framePath).existsSync()) {
      return SegmentationResult.failure('Could not extract frame from video');
    }

    return segmentFrame(
      imagePath: framePath,
      cancelToken: cancelToken,
      temporalSmoothing: temporalSmoothing,
    );
  }

  /// Generates a video segmentation mask with temporal smoothing across frames
  Future<SegmentationResult> generateVideoMask({
    required String videoPath,
    required String outputMaskPath,
    CancellationToken? cancelToken,
    Function(double progress)? onProgress,
  }) async {
    return OnDeviceInferenceRunner.instance.runHeavyInference(
      taskName: 'VideoMaskGeneration',
      cancelToken: cancelToken,
      action: () async {
        final tier = await DeviceTierService.instance.getDeviceTier();
        final frameSkip = tier.previewFrameSkip;

        String? modelPath;
        try {
          if (await isModelInstalled()) {
            final modelFile = await ensureModelReady();
            modelPath = modelFile.path;
          }
        } catch (_) {}

        final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'generateVideoSegmentationMask',
          {
            'videoPath': videoPath,
            'outputMaskPath': outputMaskPath,
            'modelPath': modelPath,
            'targetFps': 15,
            'frameSkip': frameSkip,
            'temporalSmoothing': 0.65,
          },
        );

        if (res == null) {
          return SegmentationResult.failure('Failed to generate video mask');
        }

        return SegmentationResult.fromMap(res);
      },
    );
  }
}
