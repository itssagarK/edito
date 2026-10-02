import 'package:equatable/equatable.dart';

/// Configuration for spatial video transforms: 90-degree step rotations,
/// horizontal mirroring, vertical flipping, and scale zoom.
class VideoTransformConfig extends Equatable {
  final int rotationDegrees; // 0, 90, 180, 270
  final bool isFlippedHorizontal; // Horizontal mirror (left <-> right)
  final bool isFlippedVertical; // Vertical flip (upside down)
  final double scale; // 0.5 to 3.0 (1.0 = 100% normal)

  const VideoTransformConfig({
    this.rotationDegrees = 0,
    this.isFlippedHorizontal = false,
    this.isFlippedVertical = false,
    this.scale = 1.0,
  });

  bool get isActive =>
      rotationDegrees != 0 ||
      isFlippedHorizontal ||
      isFlippedVertical ||
      (scale - 1.0).abs() > 0.001;

  VideoTransformConfig copyWith({
    int? rotationDegrees,
    bool? isFlippedHorizontal,
    bool? isFlippedVertical,
    double? scale,
  }) {
    return VideoTransformConfig(
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      isFlippedHorizontal: isFlippedHorizontal ?? this.isFlippedHorizontal,
      isFlippedVertical: isFlippedVertical ?? this.isFlippedVertical,
      scale: scale ?? this.scale,
    );
  }

  Map<String, dynamic> toJson() => {
        'rotationDegrees': rotationDegrees,
        'isFlippedHorizontal': isFlippedHorizontal,
        'isFlippedVertical': isFlippedVertical,
        'scale': scale,
      };

  factory VideoTransformConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VideoTransformConfig();
    return VideoTransformConfig(
      rotationDegrees: (json['rotationDegrees'] as num?)?.toInt() ?? 0,
      isFlippedHorizontal: json['isFlippedHorizontal'] as bool? ?? false,
      isFlippedVertical: json['isFlippedVertical'] as bool? ?? false,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [
        rotationDegrees,
        isFlippedHorizontal,
        isFlippedVertical,
        scale,
      ];
}
