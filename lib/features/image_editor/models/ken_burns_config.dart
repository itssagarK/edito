import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Available motion paths for Ken Burns documentary photo animation.
enum KenBurnsMode {
  zoomIn,
  zoomOut,
  panLeft,
  panRight,
  diagonalDrift,
}

extension KenBurnsModeExtension on KenBurnsMode {
  String get label {
    switch (this) {
      case KenBurnsMode.zoomIn:
        return '🔍 Slow Zoom In';
      case KenBurnsMode.zoomOut:
        return '🔎 Slow Zoom Out';
      case KenBurnsMode.panLeft:
        return '⬅️ Cinematic Pan Left';
      case KenBurnsMode.panRight:
        return '➡️ Cinematic Pan Right';
      case KenBurnsMode.diagonalDrift:
        return '↗️ Diagonal Drift';
    }
  }

  String get description {
    switch (this) {
      case KenBurnsMode.zoomIn:
        return 'Subtle slow push-in focusing toward the center of the frame';
      case KenBurnsMode.zoomOut:
        return 'Slow pull-back revealing surrounding context and background';
      case KenBurnsMode.panLeft:
        return 'Smooth horizontal tracking drift from right to left';
      case KenBurnsMode.panRight:
        return 'Smooth horizontal tracking drift from left to right';
      case KenBurnsMode.diagonalDrift:
        return 'Dynamic cinematic diagonal glide combining gentle zoom and pan';
    }
  }
}

enum KenBurnsEasing {
  easeInOut,
  linear,
  easeOut,
}

extension KenBurnsEasingExtension on KenBurnsEasing {
  String get label {
    switch (this) {
      case KenBurnsEasing.easeInOut:
        return 'Smooth Ease (Filmic)';
      case KenBurnsEasing.linear:
        return 'Steady Linear';
      case KenBurnsEasing.easeOut:
        return 'Gentle Decel';
    }
  }
}

/// 100% Offline, Deterministic 2D Affine Ken Burns Motion Animation.
///
/// Converts static photos, graphics, covers, and B-roll into living, breathing
/// documentary-style cinematic footage using pure mathematical matrix transformations.
class KenBurnsConfig extends Equatable {
  final bool isEnabled;
  final KenBurnsMode mode;
  final double intensity; // 0.05 to 0.40 (zoom delta)
  final KenBurnsEasing easing;

  const KenBurnsConfig({
    this.isEnabled = false,
    this.mode = KenBurnsMode.zoomIn,
    this.intensity = 0.20,
    this.easing = KenBurnsEasing.easeInOut,
  });

  /// Evaluates the affine scale and translation offsets at normalized clip time [0.0, 1.0].
  Map<String, double> evaluateTransform(double normalizedProgress) {
    if (!isEnabled) {
      return {'scale': 1.0, 'translateX': 0.0, 'translateY': 0.0};
    }

    final p = normalizedProgress.clamp(0.0, 1.0);
    double t;
    switch (easing) {
      case KenBurnsEasing.linear:
        t = p;
        break;
      case KenBurnsEasing.easeOut:
        t = math.sin(p * math.pi / 2);
        break;
      case KenBurnsEasing.easeInOut:
        t = (1.0 - math.cos(p * math.pi)) / 2.0;
        break;
    }

    double scale = 1.0;
    double transX = 0.0;
    double transY = 0.0;

    switch (mode) {
      case KenBurnsMode.zoomIn:
        scale = 1.0 + (intensity * t);
        break;

      case KenBurnsMode.zoomOut:
        scale = (1.0 + intensity) - (intensity * t);
        break;

      case KenBurnsMode.panLeft:
        scale = 1.0 + intensity;
        final maxOffset = intensity * 0.5;
        transX = maxOffset - (2 * maxOffset * t);
        break;

      case KenBurnsMode.panRight:
        scale = 1.0 + intensity;
        final maxOffset = intensity * 0.5;
        transX = -maxOffset + (2 * maxOffset * t);
        break;

      case KenBurnsMode.diagonalDrift:
        scale = 1.0 + (intensity * t * 0.7);
        final maxOffset = intensity * 0.35;
        transX = -maxOffset + (2 * maxOffset * t);
        transY = maxOffset - (2 * maxOffset * t);
        break;
    }

    return {
      'scale': scale,
      'translateX': transX,
      'translateY': transY,
    };
  }

  KenBurnsConfig copyWith({
    bool? isEnabled,
    KenBurnsMode? mode,
    double? intensity,
    KenBurnsEasing? easing,
  }) {
    return KenBurnsConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      intensity: intensity ?? this.intensity,
      easing: easing ?? this.easing,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'mode': mode.name,
        'intensity': intensity,
        'easing': easing.name,
      };

  factory KenBurnsConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const KenBurnsConfig();
    return KenBurnsConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: KenBurnsMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => KenBurnsMode.zoomIn,
      ),
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.20,
      easing: KenBurnsEasing.values.firstWhere(
        (e) => e.name == json['easing'],
        orElse: () => KenBurnsEasing.easeInOut,
      ),
    );
  }

  @override
  List<Object?> get props => [isEnabled, mode, intensity, easing];
}
