import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;
import 'package:equatable/equatable.dart';

/// Single normalized touch point along an AI object removal stroke.
class ObjectRemovalPoint extends Equatable {
  final double x; // 0.0 to 1.0 normalized x
  final double y; // 0.0 to 1.0 normalized y
  final double radius; // normalized brush radius

  const ObjectRemovalPoint({
    required this.x,
    required this.y,
    this.radius = 0.03,
  });

  Offset toOffset(Size size) => Offset(x * size.width, y * size.height);

  ObjectRemovalPoint copyWith({
    double? x,
    double? y,
    double? radius,
  }) {
    return ObjectRemovalPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      radius: radius ?? this.radius,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'radius': radius,
      };

  factory ObjectRemovalPoint.fromJson(Map<String, dynamic> json) {
    return ObjectRemovalPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      radius: (json['radius'] as num?)?.toDouble() ?? 0.03,
    );
  }

  @override
  List<Object?> get props => [x, y, radius];
}

/// Continuous brush stroke defining an object removal / inpainting mask.
class ObjectRemovalStroke extends Equatable {
  final String id;
  final List<ObjectRemovalPoint> points;
  final double strokeWidth; // Display pixel width (e.g. 28.0)
  final double feather; // Edge softness 0.0 (sharp) to 1.0 (smooth)
  final bool isEraser; // When true, stroke erases previous mask areas
  final int timestampMs;

  const ObjectRemovalStroke({
    required this.id,
    required this.points,
    this.strokeWidth = 28.0,
    this.feather = 0.25,
    this.isEraser = false,
    this.timestampMs = 0,
  });

  /// Computes the normalized bounding rectangle (0..1) of this stroke.
  Rect computeNormalizedBounds() {
    if (points.isEmpty) return Rect.zero;
    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;

    for (final p in points) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }

    final double pad = (strokeWidth / 1000.0).clamp(0.01, 0.1);
    return Rect.fromLTRB(
      (minX - pad).clamp(0.0, 1.0),
      (minY - pad).clamp(0.0, 1.0),
      (maxX + pad).clamp(0.0, 1.0),
      (maxY + pad).clamp(0.0, 1.0),
    );
  }

  /// Computes actual pixel bounding rectangle for a given render [Size].
  Rect computePixelBounds(Size size) {
    final norm = computeNormalizedBounds();
    return Rect.fromLTRB(
      norm.left * size.width,
      norm.top * size.height,
      norm.right * size.width,
      norm.bottom * size.height,
    );
  }

  ObjectRemovalStroke copyWith({
    String? id,
    List<ObjectRemovalPoint>? points,
    double? strokeWidth,
    double? feather,
    bool? isEraser,
    int? timestampMs,
  }) {
    return ObjectRemovalStroke(
      id: id ?? this.id,
      points: points ?? this.points,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      feather: feather ?? this.feather,
      isEraser: isEraser ?? this.isEraser,
      timestampMs: timestampMs ?? this.timestampMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => p.toJson()).toList(),
        'strokeWidth': strokeWidth,
        'feather': feather,
        'isEraser': isEraser,
        'timestampMs': timestampMs,
      };

  factory ObjectRemovalStroke.fromJson(Map<String, dynamic> json) {
    return ObjectRemovalStroke(
      id: json['id'] as String? ?? 'stroke_${DateTime.now().millisecondsSinceEpoch}',
      points: (json['points'] as List<dynamic>?)
              ?.map((p) => ObjectRemovalPoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 28.0,
      feather: (json['feather'] as num?)?.toDouble() ?? 0.25,
      isEraser: json['isEraser'] as bool? ?? false,
      timestampMs: json['timestampMs'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, points, strokeWidth, feather, isEraser, timestampMs];
}

/// Geometric selection region (e.g. bounding box or lasso region).
class ObjectRemovalRegion extends Equatable {
  final String id;
  final double x; // normalized 0..1 top-left x
  final double y; // normalized 0..1 top-left y
  final double width; // normalized width
  final double height; // normalized height

  const ObjectRemovalRegion({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Rect toRect(Size size) => Rect.fromLTWH(
        x * size.width,
        y * size.height,
        width * size.width,
        height * size.height,
      );

  ObjectRemovalRegion copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return ObjectRemovalRegion(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  factory ObjectRemovalRegion.fromJson(Map<String, dynamic> json) {
    return ObjectRemovalRegion(
      id: json['id'] as String? ?? 'region_${DateTime.now().millisecondsSinceEpoch}',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.2,
      height: (json['height'] as num?)?.toDouble() ?? 0.2,
    );
  }

  @override
  List<Object?> get props => [id, x, y, width, height];
}
