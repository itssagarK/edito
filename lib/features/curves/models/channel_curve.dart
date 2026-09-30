import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'curve_point.dart';

/// Supported color curve grading channels.
enum CurveChannel {
  luma,
  red,
  green,
  blue;

  String get label {
    switch (this) {
      case CurveChannel.luma:
        return 'ALL (RGB)';
      case CurveChannel.red:
        return 'RED';
      case CurveChannel.green:
        return 'GREEN';
      case CurveChannel.blue:
        return 'BLUE';
    }
  }

  Color get accentColor {
    switch (this) {
      case CurveChannel.luma:
        return Colors.white;
      case CurveChannel.red:
        return const Color(0xFFFF453A);
      case CurveChannel.green:
        return const Color(0xFF32D74B);
      case CurveChannel.blue:
        return const Color(0xFF0A84FF);
    }
  }
}

/// Represents an independent spline curve for a specific color channel.
class ChannelCurve extends Equatable {
  final CurveChannel channel;
  final List<CurvePoint> points;
  final double intensity;

  const ChannelCurve({
    required this.channel,
    required this.points,
    this.intensity = 1.0,
  });

  /// Factory for creating an identity straight diagonal line [(0,0), (1,1)].
  factory ChannelCurve.identity(CurveChannel channel) {
    return ChannelCurve(
      channel: channel,
      points: const [
        CurvePoint(x: 0.0, y: 0.0),
        CurvePoint(x: 1.0, y: 1.0),
      ],
      intensity: 1.0,
    );
  }

  /// Whether the curve deviates from the identity line (y = x).
  bool get isIdentity {
    if (points.length != 2) return false;
    final p0 = points.first;
    final p1 = points.last;
    return (p0.x == 0.0 && p0.y == 0.0) && (p1.x == 1.0 && p1.y == 1.0);
  }

  /// Returns a copy of the curve with a new control point inserted and sorted by x.
  ChannelCurve withPointAdded(CurvePoint point) {
    final updated = List<CurvePoint>.from(points)..add(point);
    updated.sort((a, b) => a.x.compareTo(b.x));
    return copyWith(points: updated);
  }

  /// Returns a copy with the point at [index] removed (endpoints cannot be deleted).
  ChannelCurve withPointRemovedAt(int index) {
    if (index <= 0 || index >= points.length - 1) return this;
    final updated = List<CurvePoint>.from(points)..removeAt(index);
    return copyWith(points: updated);
  }

  /// Returns a copy with the point at [index] updated.
  ChannelCurve withPointUpdated(int index, CurvePoint newPoint) {
    if (index < 0 || index >= points.length) return this;
    final updated = List<CurvePoint>.from(points);

    // Endpoints cannot change their X coordinate
    if (index == 0) {
      updated[0] = CurvePoint(x: 0.0, y: newPoint.y);
    } else if (index == points.length - 1) {
      updated[points.length - 1] = CurvePoint(x: 1.0, y: newPoint.y);
    } else {
      updated[index] = newPoint;
      updated.sort((a, b) => a.x.compareTo(b.x));
    }

    return copyWith(points: updated);
  }

  ChannelCurve copyWith({
    CurveChannel? channel,
    List<CurvePoint>? points,
    double? intensity,
  }) {
    return ChannelCurve(
      channel: channel ?? this.channel,
      points: points ?? this.points,
      intensity: (intensity ?? this.intensity).clamp(0.0, 1.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel': channel.name,
      'points': points.map((p) => p.toJson()).toList(),
      'intensity': double.parse(intensity.toStringAsFixed(2)),
    };
  }

  factory ChannelCurve.fromJson(Map<String, dynamic> json) {
    final chName = json['channel'] as String? ?? 'luma';
    final ch = CurveChannel.values.firstWhere(
      (e) => e.name == chName,
      orElse: () => CurveChannel.luma,
    );

    final rawPoints = json['points'] as List<dynamic>? ?? [];
    final parsedPoints = rawPoints
        .map((e) => CurvePoint.fromJson(e as Map<String, dynamic>))
        .toList();

    return ChannelCurve(
      channel: ch,
      points: parsedPoints.isEmpty
          ? const [CurvePoint(x: 0.0, y: 0.0), CurvePoint(x: 1.0, y: 1.0)]
          : parsedPoints,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [channel, points, intensity];
}
