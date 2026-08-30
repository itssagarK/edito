import 'package:flutter/material.dart';

enum AspectRatioPreset {
  ratio16x9, // YouTube, TV (1920x1080)
  ratio9x16, // TikTok, Instagram Reels, YouTube Shorts (1080x1920)
  ratio1x1,  // Instagram Square Post (1080x1080)
  ratio4x5,  // Instagram Portrait (1080x1350)
  ratio21x9, // Cinemascope Ultra-Wide (2560x1080)
}

extension AspectRatioPresetExtension on AspectRatioPreset {
  double get ratio {
    switch (this) {
      case AspectRatioPreset.ratio16x9:
        return 16.0 / 9.0;
      case AspectRatioPreset.ratio9x16:
        return 9.0 / 16.0;
      case AspectRatioPreset.ratio1x1:
        return 1.0;
      case AspectRatioPreset.ratio4x5:
        return 4.0 / 5.0;
      case AspectRatioPreset.ratio21x9:
        return 21.0 / 9.0;
    }
  }

  String get label {
    switch (this) {
      case AspectRatioPreset.ratio16x9:
        return '16:9 (Landscape)';
      case AspectRatioPreset.ratio9x16:
        return '9:16 (Shorts / Reels)';
      case AspectRatioPreset.ratio1x1:
        return '1:1 (Square)';
      case AspectRatioPreset.ratio4x5:
        return '4:5 (Portrait)';
      case AspectRatioPreset.ratio21x9:
        return '21:9 (Cinematic)';
    }
  }

  IconData get icon {
    switch (this) {
      case AspectRatioPreset.ratio16x9:
        return Icons.crop_16_9;
      case AspectRatioPreset.ratio9x16:
        return Icons.crop_portrait;
      case AspectRatioPreset.ratio1x1:
        return Icons.crop_square;
      case AspectRatioPreset.ratio4x5:
        return Icons.crop_5_4;
      case AspectRatioPreset.ratio21x9:
        return Icons.crop_din;
    }
  }

  int get standardWidth {
    switch (this) {
      case AspectRatioPreset.ratio16x9:
        return 1920;
      case AspectRatioPreset.ratio9x16:
        return 1080;
      case AspectRatioPreset.ratio1x1:
        return 1080;
      case AspectRatioPreset.ratio4x5:
        return 1080;
      case AspectRatioPreset.ratio21x9:
        return 2560;
    }
  }

  int get standardHeight {
    switch (this) {
      case AspectRatioPreset.ratio16x9:
        return 1080;
      case AspectRatioPreset.ratio9x16:
        return 1920;
      case AspectRatioPreset.ratio1x1:
        return 1080;
      case AspectRatioPreset.ratio4x5:
        return 1350;
      case AspectRatioPreset.ratio21x9:
        return 1080;
    }
  }
}
