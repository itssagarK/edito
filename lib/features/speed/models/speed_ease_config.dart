import 'dart:math' as math;
import 'package:equatable/equatable.dart';

enum SpeedEasePreset {
  custom,
  heroEntrance,
  bulletTimeEase,
  exponentialRamp,
  smoothInOut,
  fastSnap,
}

extension SpeedEasePresetExtension on SpeedEasePreset {
  String get label {
    switch (this) {
      case SpeedEasePreset.custom:
        return 'Custom Bezier';
      case SpeedEasePreset.heroEntrance:
        return 'Hero Entrance (Fast ➔ Slow)';
      case SpeedEasePreset.bulletTimeEase:
        return 'Bullet Time Ease (Center Hold)';
      case SpeedEasePreset.exponentialRamp:
        return 'Montage Acceleration';
      case SpeedEasePreset.smoothInOut:
        return 'Smooth Optical Ease';
      case SpeedEasePreset.fastSnap:
        return 'Fast Snap Rush';
    }
  }

  (double, double, double, double) get defaultControlPoints {
    switch (this) {
      case SpeedEasePreset.custom:
        return (0.25, 0.10, 0.25, 1.00);
      case SpeedEasePreset.heroEntrance:
        return (0.05, 0.95, 0.20, 1.00);
      case SpeedEasePreset.bulletTimeEase:
        return (0.40, 0.10, 0.60, 0.10);
      case SpeedEasePreset.exponentialRamp:
        return (0.75, 0.05, 0.90, 0.30);
      case SpeedEasePreset.smoothInOut:
        return (0.42, 0.00, 0.58, 1.00);
      case SpeedEasePreset.fastSnap:
        return (0.15, 0.85, 0.85, 0.15);
    }
  }
}

class SpeedEaseConfig extends Equatable {
  final bool isEnabled;
  final SpeedEasePreset preset;
  final double p1x;
  final double p1y;
  final double p2x;
  final double p2y;
  final double minSpeed; // 0.1x to 1.0x (default 0.25x)
  final double maxSpeed; // 1.0x to 8.0x (default 3.0x)

  const SpeedEaseConfig({
    this.isEnabled = false,
    this.preset = SpeedEasePreset.smoothInOut,
    this.p1x = 0.42,
    this.p1y = 0.0,
    this.p2x = 0.58,
    this.p2y = 1.0,
    this.minSpeed = 0.25,
    this.maxSpeed = 3.0,
  });

  bool get isActive => isEnabled;

  /// Solves the cubic Bezier easing curve at normalized progress [x] in [0, 1] using Newton-Raphson iteration.
  double evaluateEasing(double x) {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;

    // Initial guess
    double t = x;
    for (int i = 0; i < 8; i++) {
      final currentX = _sampleBezier(t, p1x, p2x);
      final dx = currentX - x;
      if (dx.abs() < 1e-5) break;
      final derivative = _sampleDerivative(t, p1x, p2x);
      if (derivative.abs() < 1e-6) break;
      t = (t - dx / derivative).clamp(0.0, 1.0);
    }

    return _sampleBezier(t, p1y, p2y).clamp(0.0, 1.0);
  }

  /// Evaluates instantaneous speed multiplier at normalized progress [normTime]
  double evaluateSpeedAt(double normTime) {
    if (!isActive) return 1.0;
    final ease = evaluateEasing(normTime);
    // Interpolates between minSpeed and maxSpeed
    return minSpeed + (ease * (maxSpeed - minSpeed));
  }

  /// Calculates effective average speed across the curve
  double calculateEffectiveAverageSpeed() {
    if (!isActive) return 1.0;
    // Numerical integration across 20 samples
    double sum = 0.0;
    const steps = 20;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      sum += evaluateSpeedAt(t);
    }
    return (sum / (steps + 1)).clamp(0.1, 10.0);
  }

  static double _sampleBezier(double t, double p1, double p2) {
    // B(t) = 3(1-t)^2 * t * p1 + 3(1-t) * t^2 * p2 + t^3
    final oneMinusT = 1.0 - t;
    return 3.0 * oneMinusT * oneMinusT * t * p1 +
        3.0 * oneMinusT * t * t * p2 +
        t * t * t;
  }

  static double _sampleDerivative(double t, double p1, double p2) {
    final oneMinusT = 1.0 - t;
    return 3.0 * oneMinusT * oneMinusT * p1 +
        6.0 * oneMinusT * t * (p2 - p1) +
        3.0 * t * t * (1.0 - p2);
  }

  SpeedEaseConfig copyWith({
    bool? isEnabled,
    SpeedEasePreset? preset,
    double? p1x,
    double? p1y,
    double? p2x,
    double? p2y,
    double? minSpeed,
    double? maxSpeed,
  }) {
    return SpeedEaseConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      preset: preset ?? this.preset,
      p1x: p1x ?? this.p1x,
      p1y: p1y ?? this.p1y,
      p2x: p2x ?? this.p2x,
      p2y: p2y ?? this.p2y,
      minSpeed: minSpeed ?? this.minSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'preset': preset.name,
      'p1x': p1x,
      'p1y': p1y,
      'p2x': p2x,
      'p2y': p2y,
      'minSpeed': minSpeed,
      'maxSpeed': maxSpeed,
    };
  }

  factory SpeedEaseConfig.fromJson(Map<String, dynamic> json) {
    return SpeedEaseConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      preset: SpeedEasePreset.values.firstWhere(
        (e) => e.name == json['preset'],
        orElse: () => SpeedEasePreset.smoothInOut,
      ),
      p1x: (json['p1x'] as num?)?.toDouble() ?? 0.42,
      p1y: (json['p1y'] as num?)?.toDouble() ?? 0.0,
      p2x: (json['p2x'] as num?)?.toDouble() ?? 0.58,
      p2y: (json['p2y'] as num?)?.toDouble() ?? 1.0,
      minSpeed: (json['minSpeed'] as num?)?.toDouble() ?? 0.25,
      maxSpeed: (json['maxSpeed'] as num?)?.toDouble() ?? 3.0,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        preset,
        p1x,
        p1y,
        p2x,
        p2y,
        minSpeed,
        maxSpeed,
      ];
}
