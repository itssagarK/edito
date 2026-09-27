import 'package:flutter/material.dart';

enum SplitScreenPresetType {
  twoVertical,
  twoHorizontal,
  threeVertical,
  threeHorizontal,
  threeTTop,
  threeTBottom,
  fourGrid,
  fiveGrid,
  sixGrid,
  nineGrid,
}

extension SplitScreenPresetTypeExtension on SplitScreenPresetType {
  String get label {
    switch (this) {
      case SplitScreenPresetType.twoVertical:
        return '2 Splits (Side-by-Side)';
      case SplitScreenPresetType.twoHorizontal:
        return '2 Splits (Top & Bottom)';
      case SplitScreenPresetType.threeVertical:
        return '3 Columns';
      case SplitScreenPresetType.threeHorizontal:
        return '3 Rows';
      case SplitScreenPresetType.threeTTop:
        return '3 Splits (1 Top, 2 Bottom)';
      case SplitScreenPresetType.threeTBottom:
        return '3 Splits (2 Top, 1 Bottom)';
      case SplitScreenPresetType.fourGrid:
        return '4 Grid (2x2 Quad)';
      case SplitScreenPresetType.fiveGrid:
        return '5 Grid Collage';
      case SplitScreenPresetType.sixGrid:
        return '6 Grid (2x3 Matrix)';
      case SplitScreenPresetType.nineGrid:
        return '9 Grid (3x3 Wall)';
    }
  }

  int get cellCount {
    switch (this) {
      case SplitScreenPresetType.twoVertical:
      case SplitScreenPresetType.twoHorizontal:
        return 2;
      case SplitScreenPresetType.threeVertical:
      case SplitScreenPresetType.threeHorizontal:
      case SplitScreenPresetType.threeTTop:
      case SplitScreenPresetType.threeTBottom:
        return 3;
      case SplitScreenPresetType.fourGrid:
        return 4;
      case SplitScreenPresetType.fiveGrid:
        return 5;
      case SplitScreenPresetType.sixGrid:
        return 6;
      case SplitScreenPresetType.nineGrid:
        return 9;
    }
  }

  /// Calculates normalized cell rectangles [0.0, 1.0] for viewport rendering
  List<Rect> get cellRects {
    switch (this) {
      case SplitScreenPresetType.twoVertical:
        return const [
          Rect.fromLTWH(0.0, 0.0, 0.5, 1.0),
          Rect.fromLTWH(0.5, 0.0, 0.5, 1.0),
        ];

      case SplitScreenPresetType.twoHorizontal:
        return const [
          Rect.fromLTWH(0.0, 0.0, 1.0, 0.5),
          Rect.fromLTWH(0.0, 0.5, 1.0, 0.5),
        ];

      case SplitScreenPresetType.threeVertical:
        return const [
          Rect.fromLTWH(0.0, 0.0, 1.0 / 3.0, 1.0),
          Rect.fromLTWH(1.0 / 3.0, 0.0, 1.0 / 3.0, 1.0),
          Rect.fromLTWH(2.0 / 3.0, 0.0, 1.0 / 3.0, 1.0),
        ];

      case SplitScreenPresetType.threeHorizontal:
        return const [
          Rect.fromLTWH(0.0, 0.0, 1.0, 1.0 / 3.0),
          Rect.fromLTWH(0.0, 1.0 / 3.0, 1.0, 1.0 / 3.0),
          Rect.fromLTWH(0.0, 2.0 / 3.0, 1.0, 1.0 / 3.0),
        ];

      case SplitScreenPresetType.threeTTop:
        return const [
          Rect.fromLTWH(0.0, 0.0, 1.0, 0.5),
          Rect.fromLTWH(0.0, 0.5, 0.5, 0.5),
          Rect.fromLTWH(0.5, 0.5, 0.5, 0.5),
        ];

      case SplitScreenPresetType.threeTBottom:
        return const [
          Rect.fromLTWH(0.0, 0.0, 0.5, 0.5),
          Rect.fromLTWH(0.5, 0.0, 0.5, 0.5),
          Rect.fromLTWH(0.0, 0.5, 1.0, 0.5),
        ];

      case SplitScreenPresetType.fourGrid:
        return const [
          Rect.fromLTWH(0.0, 0.0, 0.5, 0.5),
          Rect.fromLTWH(0.5, 0.0, 0.5, 0.5),
          Rect.fromLTWH(0.0, 0.5, 0.5, 0.5),
          Rect.fromLTWH(0.5, 0.5, 0.5, 0.5),
        ];

      case SplitScreenPresetType.fiveGrid:
        return const [
          Rect.fromLTWH(0.0, 0.0, 0.5, 1.0), // Featured left
          Rect.fromLTWH(0.5, 0.0, 0.25, 0.5),
          Rect.fromLTWH(0.75, 0.0, 0.25, 0.5),
          Rect.fromLTWH(0.5, 0.5, 0.25, 0.5),
          Rect.fromLTWH(0.75, 0.5, 0.25, 0.5),
        ];

      case SplitScreenPresetType.sixGrid:
        return const [
          Rect.fromLTWH(0.0, 0.0, 1.0 / 3.0, 0.5),
          Rect.fromLTWH(1.0 / 3.0, 0.0, 1.0 / 3.0, 0.5),
          Rect.fromLTWH(2.0 / 3.0, 0.0, 1.0 / 3.0, 0.5),
          Rect.fromLTWH(0.0, 0.5, 1.0 / 3.0, 0.5),
          Rect.fromLTWH(1.0 / 3.0, 0.5, 1.0 / 3.0, 0.5),
          Rect.fromLTWH(2.0 / 3.0, 0.5, 1.0 / 3.0, 0.5),
        ];

      case SplitScreenPresetType.nineGrid:
        return const [
          Rect.fromLTWH(0.0, 0.0, 1.0 / 3.0, 1.0 / 3.0),
          Rect.fromLTWH(1.0 / 3.0, 0.0, 1.0 / 3.0, 1.0 / 3.0),
          Rect.fromLTWH(2.0 / 3.0, 0.0, 1.0 / 3.0, 1.0 / 3.0),
          Rect.fromLTWH(0.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0),
          Rect.fromLTWH(1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0),
          Rect.fromLTWH(2.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0),
          Rect.fromLTWH(0.0, 2.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0),
          Rect.fromLTWH(1.0 / 3.0, 2.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0),
          Rect.fromLTWH(2.0 / 3.0, 2.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0),
        ];
    }
  }
}
