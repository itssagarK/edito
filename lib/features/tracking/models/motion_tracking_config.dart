import 'package:equatable/equatable.dart';

/// CapCut Pro Subject Tracking Types
enum TrackingTargetType {
  face,
  body,
  hand,
  customRegion,
}

extension TrackingTargetTypeExtension on TrackingTargetType {
  String get label {
    switch (this) {
      case TrackingTargetType.face:
        return 'Face / Head';
      case TrackingTargetType.body:
        return 'Body / Subject';
      case TrackingTargetType.hand:
        return 'Hand / Point';
      case TrackingTargetType.customRegion:
        return 'Custom Region';
    }
  }

  String get icon {
    switch (this) {
      case TrackingTargetType.face:
        return '👤';
      case TrackingTargetType.body:
        return '🧍';
      case TrackingTargetType.hand:
        return '✋';
      case TrackingTargetType.customRegion:
        return '🎯';
    }
  }
}

/// Tracking Motion Constraints
enum TrackingMode {
  followPosition,
  scaleAndFollow,
  fullKinematics,
}

extension TrackingModeExtension on TrackingMode {
  String get label {
    switch (this) {
      case TrackingMode.followPosition:
        return 'Follow Position (X/Y)';
      case TrackingMode.scaleAndFollow:
        return 'Scale & Follow (Zoom + X/Y)';
      case TrackingMode.fullKinematics:
        return 'Full Kinematics (Tilt + Scale + X/Y)';
    }
  }

  String get description {
    switch (this) {
      case TrackingMode.followPosition:
        return 'Pins overlay to subject coordinates maintaining constant size';
      case TrackingMode.scaleAndFollow:
        return 'Scales overlay dynamically as subject gets closer or farther';
      case TrackingMode.fullKinematics:
        return 'Pins translation, zooms with subject depth, and tilts with angle';
    }
  }
}

/// Relative Anchor Placement
enum TrackingAnchor {
  aboveSubject,
  centerSubject,
  belowSubject,
  customOffset,
}

extension TrackingAnchorExtension on TrackingAnchor {
  String get label {
    switch (this) {
      case TrackingAnchor.aboveSubject:
        return 'Floating Above';
      case TrackingAnchor.centerSubject:
        return 'Subject Center';
      case TrackingAnchor.belowSubject:
        return 'Floating Below';
      case TrackingAnchor.customOffset:
        return 'Custom Offset';
    }
  }

  double get defaultOffsetY {
    switch (this) {
      case TrackingAnchor.aboveSubject:
        return -0.16;
      case TrackingAnchor.centerSubject:
        return 0.0;
      case TrackingAnchor.belowSubject:
        return 0.16;
      case TrackingAnchor.customOffset:
        return 0.0;
    }
  }
}

/// Individual Solved Motion Keyframe Point
class TrackingTrajectoryPoint extends Equatable {
  final int offsetMs;
  final double normalizedX; // 0.0 to 1.0 (screen relative)
  final double normalizedY; // 0.0 to 1.0 (screen relative)
  final double scale; // Relative scale (1.0 = baseline)
  final double rotationDeg; // Tilt rotation in degrees
  final double confidence; // 0.0 to 1.0 tracking certainty

  const TrackingTrajectoryPoint({
    required this.offsetMs,
    required this.normalizedX,
    required this.normalizedY,
    this.scale = 1.0,
    this.rotationDeg = 0.0,
    this.confidence = 1.0,
  });

  TrackingTrajectoryPoint copyWith({
    int? offsetMs,
    double? normalizedX,
    double? normalizedY,
    double? scale,
    double? rotationDeg,
    double? confidence,
  }) {
    return TrackingTrajectoryPoint(
      offsetMs: offsetMs ?? this.offsetMs,
      normalizedX: normalizedX ?? this.normalizedX,
      normalizedY: normalizedY ?? this.normalizedY,
      scale: scale ?? this.scale,
      rotationDeg: rotationDeg ?? this.rotationDeg,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toJson() => {
        'offsetMs': offsetMs,
        'normalizedX': normalizedX,
        'normalizedY': normalizedY,
        'scale': scale,
        'rotationDeg': rotationDeg,
        'confidence': confidence,
      };

  factory TrackingTrajectoryPoint.fromJson(Map<String, dynamic> json) =>
      TrackingTrajectoryPoint(
        offsetMs: json['offsetMs'] as int? ?? 0,
        normalizedX: (json['normalizedX'] as num?)?.toDouble() ?? 0.5,
        normalizedY: (json['normalizedY'] as num?)?.toDouble() ?? 0.5,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        rotationDeg: (json['rotationDeg'] as num?)?.toDouble() ?? 0.0,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  List<Object?> get props => [
        offsetMs,
        normalizedX,
        normalizedY,
        scale,
        rotationDeg,
        confidence,
      ];
}

/// CapCut Pro Smart Motion Tracking Configuration
class MotionTrackingConfig extends Equatable {
  final bool isEnabled;
  final TrackingTargetType targetType;
  final TrackingMode mode;
  final TrackingAnchor anchor;
  final double offsetX; // Normalized horizontal anchor offset (-0.5 to 0.5)
  final double offsetY; // Normalized vertical anchor offset (-0.5 to 0.5)
  final double smoothingFactor; // 0.0 (raw) to 1.0 (cinematic damping)
  final double reticleX; // Initial reticle X position (0.0 to 1.0)
  final double reticleY; // Initial reticle Y position (0.0 to 1.0)
  final double reticleRadius; // Normalized radius for tracking bounding box
  final String? pinnedOverlayId; // Clip ID of pinned text/sticker/PiP
  final List<TrackingTrajectoryPoint> trajectory;

  const MotionTrackingConfig({
    this.isEnabled = false,
    this.targetType = TrackingTargetType.face,
    this.mode = TrackingMode.scaleAndFollow,
    this.anchor = TrackingAnchor.aboveSubject,
    this.offsetX = 0.0,
    this.offsetY = -0.16,
    this.smoothingFactor = 0.35,
    this.reticleX = 0.5,
    this.reticleY = 0.4,
    this.reticleRadius = 0.12,
    this.pinnedOverlayId,
    this.trajectory = const [],
  });

  /// Floating Viewport HUD badge
  String get badge {
    if (!isEnabled) return '';
    switch (mode) {
      case TrackingMode.followPosition:
        return '🎯 TRACK (POSITION)';
      case TrackingMode.scaleAndFollow:
        return '🎯 TRACK (SCALE & FOLLOW)';
      case TrackingMode.fullKinematics:
        return '🎯 TRACK (FULL KINEMATICS)';
    }
  }

  MotionTrackingConfig copyWith({
    bool? isEnabled,
    TrackingTargetType? targetType,
    TrackingMode? mode,
    TrackingAnchor? anchor,
    double? offsetX,
    double? offsetY,
    double? smoothingFactor,
    double? reticleX,
    double? reticleY,
    double? reticleRadius,
    String? pinnedOverlayId,
    List<TrackingTrajectoryPoint>? trajectory,
  }) {
    return MotionTrackingConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      targetType: targetType ?? this.targetType,
      mode: mode ?? this.mode,
      anchor: anchor ?? this.anchor,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      smoothingFactor: smoothingFactor ?? this.smoothingFactor,
      reticleX: reticleX ?? this.reticleX,
      reticleY: reticleY ?? this.reticleY,
      reticleRadius: reticleRadius ?? this.reticleRadius,
      pinnedOverlayId: pinnedOverlayId ?? this.pinnedOverlayId,
      trajectory: trajectory ?? this.trajectory,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'targetType': targetType.name,
        'mode': mode.name,
        'anchor': anchor.name,
        'offsetX': offsetX,
        'offsetY': offsetY,
        'smoothingFactor': smoothingFactor,
        'reticleX': reticleX,
        'reticleY': reticleY,
        'reticleRadius': reticleRadius,
        'pinnedOverlayId': pinnedOverlayId,
        'trajectory': trajectory.map((p) => p.toJson()).toList(),
      };

  factory MotionTrackingConfig.fromJson(Map<String, dynamic> json) {
    final rawTarget = json['targetType'] as String?;
    final targetType = TrackingTargetType.values.firstWhere(
      (t) => t.name == rawTarget,
      orElse: () => TrackingTargetType.face,
    );

    final rawMode = json['mode'] as String?;
    final mode = TrackingMode.values.firstWhere(
      (m) => m.name == rawMode,
      orElse: () => TrackingMode.scaleAndFollow,
    );

    final rawAnchor = json['anchor'] as String?;
    final anchor = TrackingAnchor.values.firstWhere(
      (a) => a.name == rawAnchor,
      orElse: () => TrackingAnchor.aboveSubject,
    );

    final rawTrajectory = json['trajectory'] as List<dynamic>?;
    final trajectory = rawTrajectory != null
        ? rawTrajectory
            .map((p) => TrackingTrajectoryPoint.fromJson(p as Map<String, dynamic>))
            .toList()
        : const <TrackingTrajectoryPoint>[];

    return MotionTrackingConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      targetType: targetType,
      mode: mode,
      anchor: anchor,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? -0.16,
      smoothingFactor: (json['smoothingFactor'] as num?)?.toDouble() ?? 0.35,
      reticleX: (json['reticleX'] as num?)?.toDouble() ?? 0.5,
      reticleY: (json['reticleY'] as num?)?.toDouble() ?? 0.4,
      reticleRadius: (json['reticleRadius'] as num?)?.toDouble() ?? 0.12,
      pinnedOverlayId: json['pinnedOverlayId'] as String?,
      trajectory: trajectory,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        targetType,
        mode,
        anchor,
        offsetX,
        offsetY,
        smoothingFactor,
        reticleX,
        reticleY,
        reticleRadius,
        pinnedOverlayId,
        trajectory,
      ];
}
