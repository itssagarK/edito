import 'dart:math' as math;
import 'package:equatable/equatable.dart';

class SpatialAudioPanConfig extends Equatable {
  final bool isEnabled;
  final double pan;               // -1.0 (Full Left) to +1.0 (Full Right), 0.0 is Center
  final bool is8DOrbitEnabled;     // Viral 8D Binaural continuous headphone rotation
  final double orbitSpeedHz;      // 0.1 Hz to 2.0 Hz (default 0.3 Hz = ~3.3 sec orbit cycle)
  final double orbitDepth;        // 0.2 to 1.0 (stereo width depth, default 0.85)

  const SpatialAudioPanConfig({
    this.isEnabled = false,
    this.pan = 0.0,
    this.is8DOrbitEnabled = false,
    this.orbitSpeedHz = 0.3,
    this.orbitDepth = 0.85,
  });

  bool get isActive => isEnabled && (pan.abs() > 0.01 || is8DOrbitEnabled);

  /// Calculates equal-power Left and Right gains for acoustic energy preservation.
  /// When pan = 0, both channels are at -3dB (~0.707) so perceived volume remains constant.
  (double, double) calculateEqualPowerGains([double? customPan]) {
    final p = (customPan ?? pan).clamp(-1.0, 1.0);
    // Normalized angle: -1.0 -> 0 rad, 0.0 -> pi/4 rad, +1.0 -> pi/2 rad
    final angle = (p + 1.0) * (math.pi / 4.0);
    final leftGain = math.cos(angle);
    final rightGain = math.sin(angle);
    return (leftGain, rightGain);
  }

  /// Calculates the instantaneous pan position (-1.0 to 1.0) at any playback timestamp in seconds
  double calculateInstantaneousPan(double timeSeconds) {
    if (!isActive) return 0.0;
    if (!is8DOrbitEnabled) return pan;

    // LFO cyclic oscillation around base pan
    final lfo = math.sin(2.0 * math.pi * orbitSpeedHz * timeSeconds);
    return (pan + (lfo * orbitDepth)).clamp(-1.0, 1.0);
  }

  SpatialAudioPanConfig copyWith({
    bool? isEnabled,
    double? pan,
    bool? is8DOrbitEnabled,
    double? orbitSpeedHz,
    double? orbitDepth,
  }) {
    return SpatialAudioPanConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      pan: pan ?? this.pan,
      is8DOrbitEnabled: is8DOrbitEnabled ?? this.is8DOrbitEnabled,
      orbitSpeedHz: orbitSpeedHz ?? this.orbitSpeedHz,
      orbitDepth: orbitDepth ?? this.orbitDepth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'pan': pan,
      'is8DOrbitEnabled': is8DOrbitEnabled,
      'orbitSpeedHz': orbitSpeedHz,
      'orbitDepth': orbitDepth,
    };
  }

  factory SpatialAudioPanConfig.fromJson(Map<String, dynamic> json) {
    return SpatialAudioPanConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      pan: (json['pan'] as num?)?.toDouble() ?? 0.0,
      is8DOrbitEnabled: json['is8DOrbitEnabled'] as bool? ?? false,
      orbitSpeedHz: (json['orbitSpeedHz'] as num?)?.toDouble() ?? 0.3,
      orbitDepth: (json['orbitDepth'] as num?)?.toDouble() ?? 0.85,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        pan,
        is8DOrbitEnabled,
        orbitSpeedHz,
        orbitDepth,
      ];
}
