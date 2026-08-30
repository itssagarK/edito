import 'package:equatable/equatable.dart';

class Keyframe extends Equatable {
  final int timeOffsetMs;
  final double positionX; // 0.0 to 1.0
  final double positionY; // 0.0 to 1.0
  final double scale;     // 0.2 to 5.0
  final double rotation;  // degrees
  final double opacity;   // 0.0 to 1.0

  const Keyframe({
    required this.timeOffsetMs,
    this.positionX = 0.5,
    this.positionY = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
  });

  Keyframe copyWith({
    int? timeOffsetMs,
    double? positionX,
    double? positionY,
    double? scale,
    double? rotation,
    double? opacity,
  }) {
    return Keyframe(
      timeOffsetMs: timeOffsetMs ?? this.timeOffsetMs,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
    );
  }

  Map<String, dynamic> toJson() => {
        'timeOffsetMs': timeOffsetMs,
        'positionX': positionX,
        'positionY': positionY,
        'scale': scale,
        'rotation': rotation,
        'opacity': opacity,
      };

  factory Keyframe.fromJson(Map<String, dynamic> json) => Keyframe(
        timeOffsetMs: (json['timeOffsetMs'] as num).toInt(),
        positionX: (json['positionX'] as num?)?.toDouble() ?? 0.5,
        positionY: (json['positionY'] as num?)?.toDouble() ?? 0.5,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  List<Object?> get props => [timeOffsetMs, positionX, positionY, scale, rotation, opacity];
}
