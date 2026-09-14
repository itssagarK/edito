import 'dart:math' as math;
import 'package:equatable/equatable.dart';

enum KeyframeEasing {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  bounce,
}

extension KeyframeEasingExtension on KeyframeEasing {
  String get label {
    switch (this) {
      case KeyframeEasing.linear:
        return 'Linear';
      case KeyframeEasing.easeIn:
        return 'Ease In';
      case KeyframeEasing.easeOut:
        return 'Ease Out';
      case KeyframeEasing.easeInOut:
        return 'Ease In-Out';
      case KeyframeEasing.bounce:
        return 'Bounce';
    }
  }

  String get description {
    switch (this) {
      case KeyframeEasing.linear:
        return 'Constant velocity motion';
      case KeyframeEasing.easeIn:
        return 'Starts slow and smoothly accelerates';
      case KeyframeEasing.easeOut:
        return 'Starts fast and gently decelerates';
      case KeyframeEasing.easeInOut:
        return 'Natural S-curve acceleration and deceleration';
      case KeyframeEasing.bounce:
        return 'Punchy spring arrival with bounce';
    }
  }

  /// Evaluates normalized progress t in [0.0, 1.0] through the easing function.
  double evaluate(double t) {
    final double clamped = t.clamp(0.0, 1.0);
    switch (this) {
      case KeyframeEasing.linear:
        return clamped;
      case KeyframeEasing.easeIn:
        return clamped * clamped;
      case KeyframeEasing.easeOut:
        return 1.0 - (1.0 - clamped) * (1.0 - clamped);
      case KeyframeEasing.easeInOut:
        if (clamped < 0.5) {
          return 2.0 * clamped * clamped;
        } else {
          return 1.0 - math.pow(-2.0 * clamped + 2.0, 2) / 2.0;
        }
      case KeyframeEasing.bounce:
        const double n1 = 7.5625;
        const double d1 = 2.75;
        double x = clamped;
        if (x < 1.0 / d1) {
          return n1 * x * x;
        } else if (x < 2.0 / d1) {
          x -= 1.5 / d1;
          return n1 * x * x + 0.75;
        } else if (x < 2.5 / d1) {
          x -= 2.25 / d1;
          return n1 * x * x + 0.9375;
        } else {
          x -= 2.625 / d1;
          return n1 * x * x + 0.984375;
        }
    }
  }
}

class Keyframe extends Equatable {
  final int timeOffsetMs;
  final double positionX; // 0.0 to 1.0 (0.5 is center)
  final double positionY; // 0.0 to 1.0 (0.5 is center)
  final double scale; // 0.1 to 5.0 (1.0 is default)
  final double rotation; // -360.0 to +360.0 degrees
  final double opacity; // 0.0 to 1.0
  final KeyframeEasing easing;

  const Keyframe({
    required this.timeOffsetMs,
    this.positionX = 0.5,
    this.positionY = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.easing = KeyframeEasing.easeInOut,
  });

  Keyframe copyWith({
    int? timeOffsetMs,
    double? positionX,
    double? positionY,
    double? scale,
    double? rotation,
    double? opacity,
    KeyframeEasing? easing,
  }) {
    return Keyframe(
      timeOffsetMs: timeOffsetMs ?? this.timeOffsetMs,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      easing: easing ?? this.easing,
    );
  }

  Map<String, dynamic> toJson() => {
        'timeOffsetMs': timeOffsetMs,
        'positionX': positionX,
        'positionY': positionY,
        'scale': scale,
        'rotation': rotation,
        'opacity': opacity,
        'easing': easing.name,
      };

  factory Keyframe.fromJson(Map<String, dynamic> json) => Keyframe(
        timeOffsetMs: (json['timeOffsetMs'] as num).toInt(),
        positionX: (json['positionX'] as num?)?.toDouble() ?? 0.5,
        positionY: (json['positionY'] as num?)?.toDouble() ?? 0.5,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        easing: KeyframeEasing.values.firstWhere(
          (e) => e.name == json['easing'],
          orElse: () => KeyframeEasing.easeInOut,
        ),
      );

  @override
  List<Object?> get props => [
        timeOffsetMs,
        positionX,
        positionY,
        scale,
        rotation,
        opacity,
        easing,
      ];
}
