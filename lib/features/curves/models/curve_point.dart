import 'package:equatable/equatable.dart';

/// Represents a single normalized control point on a 2D color grading curve.
/// Both [x] (input luminance/chrominance) and [y] (output value) range from 0.0 to 1.0.
class CurvePoint extends Equatable {
  final double x;
  final double y;

  const CurvePoint({
    required double x,
    required double y,
  })  : x = x < 0.0 ? 0.0 : (x > 1.0 ? 1.0 : x),
        y = y < 0.0 ? 0.0 : (y > 1.0 ? 1.0 : y);

  /// Identity default origin (0.0, 0.0).
  static const zero = CurvePoint(x: 0.0, y: 0.0);

  /// Identity default end point (1.0, 1.0).
  static const one = CurvePoint(x: 1.0, y: 1.0);

  CurvePoint copyWith({
    double? x,
    double? y,
  }) {
    return CurvePoint(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': double.parse(x.toStringAsFixed(4)),
      'y': double.parse(y.toStringAsFixed(4)),
    };
  }

  factory CurvePoint.fromJson(Map<String, dynamic> json) {
    return CurvePoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [x, y];
}
