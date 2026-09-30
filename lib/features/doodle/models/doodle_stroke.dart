import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

enum DoodleBrushType {
  pen, // Standard solid ink pen (normal_pen)
  neon, // Glowing electric halo pen
  highlighter, // Broad semi-transparent marker
  arrow, // Directional vector line with arrowhead
  dashed, // Dotted / dashed pattern pen
  eraser, // Erases intersecting doodle strokes
}

extension DoodleBrushTypeExtension on DoodleBrushType {
  String get label {
    switch (this) {
      case DoodleBrushType.pen:
        return 'Ink Pen';
      case DoodleBrushType.neon:
        return 'Neon Glow';
      case DoodleBrushType.highlighter:
        return 'Highlighter';
      case DoodleBrushType.arrow:
        return 'Arrow Line';
      case DoodleBrushType.dashed:
        return 'Dashed Line';
      case DoodleBrushType.eraser:
        return 'Eraser';
    }
  }

  IconData get icon {
    switch (this) {
      case DoodleBrushType.pen:
        return Icons.edit;
      case DoodleBrushType.neon:
        return Icons.flare;
      case DoodleBrushType.highlighter:
        return Icons.brush;
      case DoodleBrushType.arrow:
        return Icons.arrow_outward;
      case DoodleBrushType.dashed:
        return Icons.linear_scale;
      case DoodleBrushType.eraser:
        return Icons.auto_fix_normal;
    }
  }
}

/// Single normalized touch point in a doodle drawing stroke.
class DoodlePoint extends Equatable {
  final double x; // Normalized 0.0 to 1.0
  final double y; // Normalized 0.0 to 1.0
  final double pressure; // 0.0 to 1.0 (default 1.0)

  const DoodlePoint({
    required this.x,
    required this.y,
    this.pressure = 1.0,
  });

  Offset toOffset(Size size) => Offset(x * size.width, y * size.height);

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'pressure': pressure,
      };

  factory DoodlePoint.fromJson(Map<String, dynamic> json) => DoodlePoint(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        pressure: (json['pressure'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  List<Object?> get props => [x, y, pressure];
}

/// Continuous brush stroke containing smoothed points, color, size, and brush type.
class DoodleStroke extends Equatable {
  final String id;
  final List<DoodlePoint> points;
  final DoodleBrushType brushType;
  final int colorValue; // ARGB int
  final double strokeWidth; // Pixel width at 1080p reference (2 to 80)
  final double opacity; // 0.0 to 1.0
  final double hardness; // 0.0 to 1.0

  const DoodleStroke({
    required this.id,
    required this.points,
    this.brushType = DoodleBrushType.pen,
    this.colorValue = 0xFFFFD700, // Vibrant Gold default
    this.strokeWidth = 14.0,
    this.opacity = 1.0,
    this.hardness = 1.0,
  });

  Color get color => Color(colorValue).withOpacity(opacity);

  Rect computeNormalizedBounds() {
    if (points.isEmpty) return Rect.zero;
    double minX = 1.0;
    double minY = 1.0;
    double maxX = 0.0;
    double maxY = 0.0;

    for (final pt in points) {
      minX = math.min(minX, pt.x);
      minY = math.min(minY, pt.y);
      maxX = math.max(maxX, pt.x);
      maxY = math.max(maxY, pt.y);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Rect computePixelBounds(Size size) {
    final norm = computeNormalizedBounds();
    final pad = strokeWidth * 1.5;
    return Rect.fromLTRB(
      math.max(0.0, norm.left * size.width - pad),
      math.max(0.0, norm.top * size.height - pad),
      math.min(size.width, norm.right * size.width + pad),
      math.min(size.height, norm.bottom * size.height + pad),
    );
  }

  DoodleStroke copyWith({
    String? id,
    List<DoodlePoint>? points,
    DoodleBrushType? brushType,
    int? colorValue,
    double? strokeWidth,
    double? opacity,
    double? hardness,
  }) {
    return DoodleStroke(
      id: id ?? this.id,
      points: points ?? this.points,
      brushType: brushType ?? this.brushType,
      colorValue: colorValue ?? this.colorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      hardness: hardness ?? this.hardness,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => p.toJson()).toList(),
        'brushType': brushType.name,
        'colorValue': colorValue,
        'strokeWidth': strokeWidth,
        'opacity': opacity,
        'hardness': hardness,
      };

  factory DoodleStroke.fromJson(Map<String, dynamic> json) => DoodleStroke(
        id: json['id'] as String,
        points: (json['points'] as List<dynamic>)
            .map((p) => DoodlePoint.fromJson(p as Map<String, dynamic>))
            .toList(),
        brushType: json['brushType'] != null
            ? DoodleBrushType.values.firstWhere(
                (b) => b.name == json['brushType'],
                orElse: () => DoodleBrushType.pen,
              )
            : DoodleBrushType.pen,
        colorValue: json['colorValue'] as int? ?? 0xFFFFD700,
        strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 14.0,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        hardness: (json['hardness'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  List<Object?> get props => [id, points, brushType, colorValue, strokeWidth, opacity, hardness];
}
