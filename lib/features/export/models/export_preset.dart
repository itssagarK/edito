import '../../preview/models/aspect_ratio_preset.dart';

enum ExportResolution {
  res8k,
  res4k,
  res1080p,
  res720p,
}

extension ExportResolutionExtension on ExportResolution {
  String get label {
    switch (this) {
      case ExportResolution.res8k:
        return '8K Ultra HD (4320p)';
      case ExportResolution.res4k:
        return '4K Ultra HD (2160p)';
      case ExportResolution.res1080p:
        return '1080p Full HD';
      case ExportResolution.res720p:
        return '720p HD';
    }
  }

  int get width {
    switch (this) {
      case ExportResolution.res8k:
        return 7680;
      case ExportResolution.res4k:
        return 3840;
      case ExportResolution.res1080p:
        return 1920;
      case ExportResolution.res720p:
        return 1280;
    }
  }

  int get height {
    switch (this) {
      case ExportResolution.res8k:
        return 4320;
      case ExportResolution.res4k:
        return 2160;
      case ExportResolution.res1080p:
        return 1080;
      case ExportResolution.res720p:
        return 720;
    }
  }

  double get baseBitrateMbps {
    switch (this) {
      case ExportResolution.res8k:
        return 80.0;
      case ExportResolution.res4k:
        return 35.0;
      case ExportResolution.res1080p:
        return 12.0;
      case ExportResolution.res720p:
        return 6.0;
    }
  }
}

enum ExportFramerate {
  fps24,
  fps30,
  fps60,
}

extension ExportFramerateExtension on ExportFramerate {
  int get fpsValue {
    switch (this) {
      case ExportFramerate.fps24:
        return 24;
      case ExportFramerate.fps30:
        return 30;
      case ExportFramerate.fps60:
        return 60;
    }
  }

  String get label {
    switch (this) {
      case ExportFramerate.fps24:
        return '24 FPS (Cinematic)';
      case ExportFramerate.fps30:
        return '30 FPS (Standard)';
      case ExportFramerate.fps60:
        return '60 FPS (Smooth)';
    }
  }
}

enum ExportCodec {
  h264,
  hevc,
}

extension ExportCodecExtension on ExportCodec {
  String get label {
    switch (this) {
      case ExportCodec.h264:
        return 'H.264 / AVC (Universal)';
      case ExportCodec.hevc:
        return 'H.265 / HEVC (Space Saver)';
    }
  }

  String get ffmpegEncoder {
    switch (this) {
      case ExportCodec.h264:
        return 'libx264';
      case ExportCodec.hevc:
        return 'libx265';
    }
  }
}

enum ExportQuality {
  standard,
  high,
  ultra,
}

extension ExportQualityExtension on ExportQuality {
  String get label {
    switch (this) {
      case ExportQuality.standard:
        return 'Standard (Fast)';
      case ExportQuality.high:
        return 'High Quality (Recommended)';
      case ExportQuality.ultra:
        return 'Ultra Master (Lossless)';
    }
  }

  int get crf {
    switch (this) {
      case ExportQuality.standard:
        return 23;
      case ExportQuality.high:
        return 18;
      case ExportQuality.ultra:
        return 14;
    }
  }

  double get sizeMultiplier {
    switch (this) {
      case ExportQuality.standard:
        return 1.0;
      case ExportQuality.high:
        return 1.4;
      case ExportQuality.ultra:
        return 2.0;
    }
  }
}

class ExportConfiguration {
  final ExportResolution resolution;
  final ExportFramerate framerate;
  final ExportCodec codec;
  final ExportQuality quality;
  final AspectRatioPreset aspectRatio;
  final String outputPath;

  const ExportConfiguration({
    this.resolution = ExportResolution.res1080p,
    this.framerate = ExportFramerate.fps30,
    this.codec = ExportCodec.h264,
    this.quality = ExportQuality.high,
    this.aspectRatio = AspectRatioPreset.ratio16x9,
    this.outputPath = '',
  });

  ExportConfiguration copyWith({
    ExportResolution? resolution,
    ExportFramerate? framerate,
    ExportCodec? codec,
    ExportQuality? quality,
    AspectRatioPreset? aspectRatio,
    String? outputPath,
  }) {
    return ExportConfiguration(
      resolution: resolution ?? this.resolution,
      framerate: framerate ?? this.framerate,
      codec: codec ?? this.codec,
      quality: quality ?? this.quality,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      outputPath: outputPath ?? this.outputPath,
    );
  }

  /// Estimates output file size in megabytes
  double estimateFileSizeMb(int durationMs) {
    if (durationMs <= 0) return 0.0;
    final seconds = durationMs / 1000.0;
    final mbps = resolution.baseBitrateMbps * quality.sizeMultiplier * (codec == ExportCodec.hevc ? 0.65 : 1.0);
    final sizeMb = (seconds * mbps) / 8.0;
    return (sizeMb * 10).roundToDouble() / 10.0;
  }
}
