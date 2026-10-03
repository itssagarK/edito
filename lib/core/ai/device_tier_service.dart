import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'models/ai_model_descriptor.dart';

enum DeviceTier {
  low('Low-End Device', 'Optimized for power savings & low memory overhead'),
  medium('Mid-Range Device', 'Balanced performance with smooth preview rates'),
  high('High-Performance Device', 'Full-speed inference with hardware acceleration');

  final String label;
  final String description;
  const DeviceTier(this.label, this.description);
}

class DeviceHardwareInfo {
  final int totalRamMb;
  final int availableRamMb;
  final int cpuCores;
  final int androidApiLevel;
  final String modelName;
  final DeviceTier tier;

  const DeviceHardwareInfo({
    required this.totalRamMb,
    required this.availableRamMb,
    required this.cpuCores,
    required this.androidApiLevel,
    required this.modelName,
    required this.tier,
  });

  /// Recommended preview frame-skip factor (run segmentation/tracking every N frames)
  int get previewFrameSkip {
    switch (tier) {
      case DeviceTier.low:
        return 5;
      case DeviceTier.medium:
        return 3;
      case DeviceTier.high:
        return 2;
    }
  }

  /// Target input resolution (width/height square) for vision inference
  int get maxInferenceResolution {
    switch (tier) {
      case DeviceTier.low:
        return 256;
      case DeviceTier.medium:
        return 384;
      case DeviceTier.high:
        return 512;
    }
  }

  /// Number of background threads allocated to model inference
  int get inferenceThreads {
    switch (tier) {
      case DeviceTier.low:
        return 2;
      case DeviceTier.medium:
        return (cpuCores >= 6) ? 4 : 3;
      case DeviceTier.high:
        return 4;
    }
  }

  /// Whether to attempt NNAPI / GPU hardware delegate initialization
  bool get enableHardwareDelegate {
    return androidApiLevel >= 29 && (tier == DeviceTier.medium || tier == DeviceTier.high);
  }

  /// Recommended default Whisper speech model for this device
  AiModelDescriptor get recommendedWhisperModel {
    return (tier == DeviceTier.low)
        ? AiModelCatalog.whisperTinyEn
        : AiModelCatalog.whisperTinyMultilingual;
  }
}

class DeviceTierService {
  static const MethodChannel _channel = MethodChannel('com.edito.app/gallery');

  static DeviceHardwareInfo? _cachedInfo;

  /// Detects device specifications and computes optimal AI workload tier
  static Future<DeviceHardwareInfo> getHardwareInfo() async {
    if (_cachedInfo != null) return _cachedInfo!;

    int ramMb = 4096;
    int availRamMb = 2048;
    int cores = Platform.numberOfProcessors;
    int apiLevel = 30;
    String model = 'Android Device';

    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDeviceHardwareInfo');
        if (result != null) {
          ramMb = (result['totalRamMb'] as num?)?.toInt() ?? ramMb;
          availRamMb = (result['availableRamMb'] as num?)?.toInt() ?? availRamMb;
          cores = (result['cpuCores'] as num?)?.toInt() ?? cores;
          apiLevel = (result['apiLevel'] as num?)?.toInt() ?? apiLevel;
          model = (result['model'] as String?) ?? model;
        }
      } catch (e) {
        debugPrint('Platform getDeviceHardwareInfo error (using fallback): $e');
      }
    }

    DeviceTier tier;
    if (ramMb < 3800 || cores <= 4) {
      tier = DeviceTier.low;
    } else if (ramMb <= 6200 || cores <= 6) {
      tier = DeviceTier.medium;
    } else {
      tier = DeviceTier.high;
    }

    _cachedInfo = DeviceHardwareInfo(
      totalRamMb: ramMb,
      availableRamMb: availRamMb,
      cpuCores: cores,
      androidApiLevel: apiLevel,
      modelName: model,
      tier: tier,
    );

    return _cachedInfo!;
  }

  /// Resets cached hardware info (useful for testing or profile switches)
  static void resetCache() {
    _cachedInfo = null;
  }
}
