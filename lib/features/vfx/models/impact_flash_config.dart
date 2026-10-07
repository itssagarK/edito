import 'dart:math' as math;
import 'package:equatable/equatable.dart';

enum ImpactFlashType {
  whiteFlash,
  blackFlash,
  warmGlow,
  rgbStrobe,
}

extension ImpactFlashTypeExtension on ImpactFlashType {
  String get label {
    switch (this) {
      case ImpactFlashType.whiteFlash:
        return 'White Flash (Impact)';
      case ImpactFlashType.blackFlash:
        return 'Black Dip (Dramatic)';
      case ImpactFlashType.warmGlow:
        return 'Warm Sunset Glow';
      case ImpactFlashType.rgbStrobe:
        return 'RGB Cyber Strobe';
    }
  }

  String get description {
    switch (this) {
      case ImpactFlashType.whiteFlash:
        return 'High-energy white burst decaying rapidly across the cut';
      case ImpactFlashType.blackFlash:
        return 'Cinematic dark dip for dramatic scene transitions';
      case ImpactFlashType.warmGlow:
        return 'Golden amber flash accentuating warm emotion';
      case ImpactFlashType.rgbStrobe:
        return 'Vibrant neon chromatic accent on beat drops';
    }
  }
}

enum ImpactDecayCurve {
  exponential,
  linear,
  sCurve,
}

class ImpactFlashConfig extends Equatable {
  final bool isEnabled;
  final ImpactFlashType type;
  final int durationMs;      // 50ms to 1000ms (default 200ms)
  final double intensity;    // 0.1 to 1.0 (default 0.85)
  final ImpactDecayCurve decayCurve;

  const ImpactFlashConfig({
    this.isEnabled = false,
    this.type = ImpactFlashType.whiteFlash,
    this.durationMs = 200,
    this.intensity = 0.85,
    this.decayCurve = ImpactDecayCurve.exponential,
  });

  bool get isActive => isEnabled && durationMs > 0 && intensity > 0;

  /// Evaluates the opacity (0.0 to 1.0) of the flash effect at a specific millisecond offset into the clip
  double evaluateOpacity(int offsetMs) {
    if (!isActive || offsetMs < 0 || offsetMs >= durationMs) return 0.0;

    final progress = (offsetMs / durationMs).clamp(0.0, 1.0);

    switch (decayCurve) {
      case ImpactDecayCurve.linear:
        return (intensity * (1.0 - progress)).clamp(0.0, 1.0);
      case ImpactDecayCurve.exponential:
        return (intensity * math.exp(-3.5 * progress)).clamp(0.0, 1.0);
      case ImpactDecayCurve.sCurve:
        return (intensity * math.cos(progress * (math.pi / 2.0))).clamp(0.0, 1.0);
    }
  }

  ImpactFlashConfig copyWith({
    bool? isEnabled,
    ImpactFlashType? type,
    int? durationMs,
    double? intensity,
    ImpactDecayCurve? decayCurve,
  }) {
    return ImpactFlashConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      type: type ?? this.type,
      durationMs: durationMs ?? this.durationMs,
      intensity: intensity ?? this.intensity,
      decayCurve: decayCurve ?? this.decayCurve,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'type': type.name,
      'durationMs': durationMs,
      'intensity': intensity,
      'decayCurve': decayCurve.name,
    };
  }

  factory ImpactFlashConfig.fromJson(Map<String, dynamic> json) {
    return ImpactFlashConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      type: ImpactFlashType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ImpactFlashType.whiteFlash,
      ),
      durationMs: json['durationMs'] as int? ?? 200,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.85,
      decayCurve: ImpactDecayCurve.values.firstWhere(
        (e) => e.name == json['decayCurve'],
        orElse: () => ImpactDecayCurve.exponential,
      ),
    );
  }

  @override
  List<Object?> get props => [isEnabled, type, durationMs, intensity, decayCurve];
}
