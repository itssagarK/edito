import 'package:equatable/equatable.dart';
import '../../color_grading/models/color_grading_config.dart';

enum SpeedCurveType {
  constant,
  montage,
  hero,
  bulletTime,
  jumpCut,
}

extension SpeedCurveTypeExtension on SpeedCurveType {
  String get label {
    switch (this) {
      case SpeedCurveType.constant:
        return 'Constant Speed';
      case SpeedCurveType.montage:
        return 'Montage Ramp (Fast ➔ Slow ➔ Fast)';
      case SpeedCurveType.hero:
        return 'Hero Slow-Mo (Normal ➔ Slow ➔ Normal)';
      case SpeedCurveType.bulletTime:
        return 'Bullet Time (Drop to 0.1x)';
      case SpeedCurveType.jumpCut:
        return 'Jump Cut Rush (3x Fast)';
    }
  }

  List<CurvePoint> get defaultCurvePoints {
    switch (this) {
      case SpeedCurveType.constant:
        return [const CurvePoint(0.0, 1.0), const CurvePoint(1.0, 1.0)];
      case SpeedCurveType.montage:
        return [
          const CurvePoint(0.0, 2.0),
          const CurvePoint(0.35, 0.4),
          const CurvePoint(0.65, 0.4),
          const CurvePoint(1.0, 2.0),
        ];
      case SpeedCurveType.hero:
        return [
          const CurvePoint(0.0, 1.0),
          const CurvePoint(0.3, 1.0),
          const CurvePoint(0.5, 0.25),
          const CurvePoint(0.7, 1.0),
          const CurvePoint(1.0, 1.0),
        ];
      case SpeedCurveType.bulletTime:
        return [
          const CurvePoint(0.0, 1.0),
          const CurvePoint(0.2, 0.1),
          const CurvePoint(0.8, 0.1),
          const CurvePoint(1.0, 1.0),
        ];
      case SpeedCurveType.jumpCut:
        return [
          const CurvePoint(0.0, 3.0),
          const CurvePoint(0.6, 3.0),
          const CurvePoint(1.0, 1.0),
        ];
    }
  }
}

class SpeedCurveConfig extends Equatable {
  final SpeedCurveType type;
  final double constantSpeed;
  final bool enablePitchCorrection;
  final List<CurvePoint> curvePoints;

  const SpeedCurveConfig({
    this.type = SpeedCurveType.constant,
    this.constantSpeed = 1.0,
    this.enablePitchCorrection = true,
    this.curvePoints = const [CurvePoint(0.0, 1.0), CurvePoint(1.0, 1.0)],
  });

  SpeedCurveConfig copyWith({
    SpeedCurveType? type,
    double? constantSpeed,
    bool? enablePitchCorrection,
    List<CurvePoint>? curvePoints,
  }) {
    return SpeedCurveConfig(
      type: type ?? this.type,
      constantSpeed: constantSpeed ?? this.constantSpeed,
      enablePitchCorrection: enablePitchCorrection ?? this.enablePitchCorrection,
      curvePoints: curvePoints ?? this.curvePoints,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'constantSpeed': constantSpeed,
        'enablePitchCorrection': enablePitchCorrection,
        'curvePoints': curvePoints.map((p) => p.toJson()).toList(),
      };

  factory SpeedCurveConfig.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['curvePoints'] as List<dynamic>? ?? [];
    final points = rawPoints.map((p) => CurvePoint.fromJson(p as Map<String, dynamic>)).toList();

    return SpeedCurveConfig(
      type: SpeedCurveType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SpeedCurveType.constant,
      ),
      constantSpeed: (json['constantSpeed'] as num?)?.toDouble() ?? 1.0,
      enablePitchCorrection: json['enablePitchCorrection'] as bool? ?? true,
      curvePoints: points.isNotEmpty ? points : const [CurvePoint(0.0, 1.0), CurvePoint(1.0, 1.0)],
    );
  }

  @override
  List<Object?> get props => [type, constantSpeed, enablePitchCorrection, curvePoints];
}
