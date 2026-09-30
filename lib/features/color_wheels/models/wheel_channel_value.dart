import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// Single Color Wheel Value representing chromatic hue shift, saturation magnitude, and luminance.
class WheelChannelValue extends Equatable {
  final double angle; // Hue angle 0.0 to 360.0 degrees (0 = Red, 120 = Green, 240 = Blue)
  final double saturation; // Distance from center 0.0 to 1.0
  final double luminance; // Vertical pedestal / exposure shift -1.0 to +1.0
  final double red; // Explicit red channel shift -1.0 to +1.0
  final double green; // Explicit green channel shift -1.0 to +1.0
  final double blue; // Explicit blue channel shift -1.0 to +1.0

  const WheelChannelValue({
    this.angle = 0.0,
    this.saturation = 0.0,
    this.luminance = 0.0,
    this.red = 0.0,
    this.green = 0.0,
    this.blue = 0.0,
  });

  /// Factory creating WheelChannelValue from angle, saturation, and luminance.
  factory WheelChannelValue.fromHsl({
    required double angle,
    required double saturation,
    double luminance = 0.0,
  }) {
    final normAngle = (angle % 360.0 + 360.0) % 360.0;
    final normSat = saturation.clamp(0.0, 1.0);
    final rad = normAngle * (math.pi / 180.0);

    // Project polar coordinates to RGB chromatic bias
    final r = math.cos(rad) * normSat;
    final g = math.cos(rad - (2.0 * math.pi / 3.0)) * normSat;
    final b = math.cos(rad - (4.0 * math.pi / 3.0)) * normSat;

    return WheelChannelValue(
      angle: normAngle,
      saturation: normSat,
      luminance: luminance.clamp(-1.0, 1.0),
      red: r.clamp(-1.0, 1.0),
      green: g.clamp(-1.0, 1.0),
      blue: b.clamp(-1.0, 1.0),
    );
  }

  /// Factory creating WheelChannelValue from discrete RGB channel adjustments.
  factory WheelChannelValue.fromRgb({
    required double red,
    required double green,
    required double blue,
    double luminance = 0.0,
  }) {
    final r = red.clamp(-1.0, 1.0);
    final g = green.clamp(-1.0, 1.0);
    final b = blue.clamp(-1.0, 1.0);

    // Compute polar coordinates from RGB bias
    final x = r - 0.5 * (g + b);
    final y = (math.sqrt(3.0) / 2.0) * (g - b);
    var ang = math.atan2(y, x) * (180.0 / math.pi);
    if (ang < 0) ang += 360.0;

    final sat = math.sqrt(x * x + y * y).clamp(0.0, 1.0);

    return WheelChannelValue(
      angle: ang,
      saturation: sat,
      luminance: luminance.clamp(-1.0, 1.0),
      red: r,
      green: g,
      blue: b,
    );
  }

  bool get isDefault =>
      saturation.abs() < 0.001 &&
      luminance.abs() < 0.001 &&
      red.abs() < 0.001 &&
      green.abs() < 0.001 &&
      blue.abs() < 0.001;

  WheelChannelValue copyWith({
    double? angle,
    double? saturation,
    double? luminance,
    double? red,
    double? green,
    double? blue,
  }) {
    return WheelChannelValue(
      angle: angle ?? this.angle,
      saturation: saturation ?? this.saturation,
      luminance: luminance ?? this.luminance,
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
    );
  }

  Map<String, dynamic> toJson() => {
        'angle': angle,
        'saturation': saturation,
        'luminance': luminance,
        'red': red,
        'green': green,
        'blue': blue,
      };

  factory WheelChannelValue.fromJson(Map<String, dynamic> json) => WheelChannelValue(
        angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
        saturation: (json['saturation'] as num?)?.toDouble() ?? 0.0,
        luminance: (json['luminance'] as num?)?.toDouble() ?? 0.0,
        red: (json['red'] as num?)?.toDouble() ?? 0.0,
        green: (json['green'] as num?)?.toDouble() ?? 0.0,
        blue: (json['blue'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  List<Object?> get props => [angle, saturation, luminance, red, green, blue];
}
