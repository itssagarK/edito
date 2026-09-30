import 'package:equatable/equatable.dart';
import 'curve_point.dart';
import 'channel_curve.dart';

/// Curated cinematic and aesthetic RGB curve presets.
enum CurvesPreset {
  linearReset,
  sCurveContrast,
  fadedMatte,
  crossProcess,
  tealAndOrange,
  punchyPop,
  bleachBypass;

  String get label {
    switch (this) {
      case CurvesPreset.linearReset:
        return 'Linear';
      case CurvesPreset.sCurveContrast:
        return 'S-Curve';
      case CurvesPreset.fadedMatte:
        return 'Faded Film';
      case CurvesPreset.crossProcess:
        return 'Cross Process';
      case CurvesPreset.tealAndOrange:
        return 'Teal & Orange';
      case CurvesPreset.punchyPop:
        return 'Punchy Pop';
      case CurvesPreset.bleachBypass:
        return 'Bleach Bypass';
    }
  }

  String get description {
    switch (this) {
      case CurvesPreset.linearReset:
        return 'Default neutral 1:1 identity linear curve';
      case CurvesPreset.sCurveContrast:
        return 'Deepens shadows and elevates highlights for punchy contrast';
      case CurvesPreset.fadedMatte:
        return 'Lifts black pedestal and rolls off whites for vintage film print';
      case CurvesPreset.crossProcess:
        return 'Split-tones cyan shadows with warm golden yellow highlights';
      case CurvesPreset.tealAndOrange:
        return 'Iconic Hollywood blockbuster color harmony with warm skin tones';
      case CurvesPreset.punchyPop:
        return 'Ultra-vibrant dynamic range expansion with boosted midtone slope';
      case CurvesPreset.bleachBypass:
        return 'Gritty silver-halide desaturated look with severe high contrast';
    }
  }
}

/// Comprehensive CapCut Pro RGB Curves & Luma Spline Color Grading Configuration.
class CurvesConfig extends Equatable {
  final ChannelCurve lumaCurve;
  final ChannelCurve redCurve;
  final ChannelCurve greenCurve;
  final ChannelCurve blueCurve;
  final double masterIntensity;

  const CurvesConfig({
    this.lumaCurve = const ChannelCurve(
      channel: CurveChannel.luma,
      points: [CurvePoint(x: 0.0, y: 0.0), CurvePoint(x: 1.0, y: 1.0)],
      intensity: 1.0,
    ),
    this.redCurve = const ChannelCurve(
      channel: CurveChannel.red,
      points: [CurvePoint(x: 0.0, y: 0.0), CurvePoint(x: 1.0, y: 1.0)],
      intensity: 1.0,
    ),
    this.greenCurve = const ChannelCurve(
      channel: CurveChannel.green,
      points: [CurvePoint(x: 0.0, y: 0.0), CurvePoint(x: 1.0, y: 1.0)],
      intensity: 1.0,
    ),
    this.blueCurve = const ChannelCurve(
      channel: CurveChannel.blue,
      points: [CurvePoint(x: 0.0, y: 0.0), CurvePoint(x: 1.0, y: 1.0)],
      intensity: 1.0,
    ),
    this.masterIntensity = 1.0,
  });

  /// Factory for constructing presets directly.
  factory CurvesConfig.fromPreset(CurvesPreset preset) {
    switch (preset) {
      case CurvesPreset.linearReset:
        return const CurvesConfig();

      case CurvesPreset.sCurveContrast:
        return const CurvesConfig(
          lumaCurve: ChannelCurve(
            channel: CurveChannel.luma,
            points: [
              CurvePoint(x: 0.0, y: 0.0),
              CurvePoint(x: 0.25, y: 0.18),
              CurvePoint(x: 0.75, y: 0.82),
              CurvePoint(x: 1.0, y: 1.0),
            ],
          ),
        );

      case CurvesPreset.fadedMatte:
        return const CurvesConfig(
          lumaCurve: ChannelCurve(
            channel: CurveChannel.luma,
            points: [
              CurvePoint(x: 0.0, y: 0.12),
              CurvePoint(x: 0.35, y: 0.38),
              CurvePoint(x: 0.75, y: 0.76),
              CurvePoint(x: 1.0, y: 0.90),
            ],
          ),
          redCurve: ChannelCurve(
            channel: CurveChannel.red,
            points: [
              CurvePoint(x: 0.0, y: 0.04),
              CurvePoint(x: 1.0, y: 0.96),
            ],
          ),
        );

      case CurvesPreset.crossProcess:
        return const CurvesConfig(
          lumaCurve: ChannelCurve(
            channel: CurveChannel.luma,
            points: [
              CurvePoint(x: 0.0, y: 0.02),
              CurvePoint(x: 0.30, y: 0.25),
              CurvePoint(x: 0.70, y: 0.78),
              CurvePoint(x: 1.0, y: 0.98),
            ],
          ),
          redCurve: ChannelCurve(
            channel: CurveChannel.red,
            points: [
              CurvePoint(x: 0.0, y: 0.0),
              CurvePoint(x: 0.35, y: 0.28),
              CurvePoint(x: 0.75, y: 0.86),
              CurvePoint(x: 1.0, y: 1.0),
            ],
          ),
          greenCurve: ChannelCurve(
            channel: CurveChannel.green,
            points: [
              CurvePoint(x: 0.0, y: 0.0),
              CurvePoint(x: 0.50, y: 0.52),
              CurvePoint(x: 1.0, y: 1.0),
            ],
          ),
          blueCurve: ChannelCurve(
            channel: CurveChannel.blue,
            points: [
              CurvePoint(x: 0.0, y: 0.16),
              CurvePoint(x: 0.40, y: 0.38),
              CurvePoint(x: 0.70, y: 0.68),
              CurvePoint(x: 1.0, y: 0.88),
            ],
          ),
        );

      case CurvesPreset.tealAndOrange:
        return const CurvesConfig(
          lumaCurve: ChannelCurve(
            channel: CurveChannel.luma,
            points: [
              CurvePoint(x: 0.0, y: 0.0),
              CurvePoint(x: 0.25, y: 0.20),
              CurvePoint(x: 0.75, y: 0.80),
              CurvePoint(x: 1.0, y: 1.0),
            ],
          ),
          redCurve: ChannelCurve(
            channel: CurveChannel.red,
            points: [
              CurvePoint(x: 0.0, y: 0.0),
              CurvePoint(x: 0.30, y: 0.24),
              CurvePoint(x: 0.70, y: 0.78),
              CurvePoint(x: 1.0, y: 1.0),
            ],
          ),
          blueCurve: ChannelCurve(
            channel: CurveChannel.blue,
            points: [
              CurvePoint(x: 0.0, y: 0.08),
              CurvePoint(x: 0.35, y: 0.42),
              CurvePoint(x: 0.65, y: 0.60),
              CurvePoint(x: 1.0, y: 0.88),
            ],
          ),
        );

      case CurvesPreset.punchyPop:
        return const CurvesConfig(
          lumaCurve: ChannelCurve(
            channel: CurveChannel.luma,
            points: [
              CurvePoint(x: 0.0, y: 0.0),
              CurvePoint(x: 0.20, y: 0.14),
              CurvePoint(x: 0.50, y: 0.50),
              CurvePoint(x: 0.80, y: 0.88),
              CurvePoint(x: 1.0, y: 1.0),
            ],
          ),
          redCurve: ChannelCurve(
            channel: CurveChannel.red,
            points: [
              CurvePoint(x: 0.0, y: 0.0),
              CurvePoint(x: 0.50, y: 0.54),
              CurvePoint(x: 1.0, y: 1.0),
            ],
          ),
          greenCurve: ChannelCurve(
            channel: CurveChannel.green,
            points: [
              CurvePoint(x: 0.0, y: 0.0),
              CurvePoint(x: 0.50, y: 0.52),
              CurvePoint(x: 1.0, y: 1.0),
            ],
          ),
        );

      case CurvesPreset.bleachBypass:
        return const CurvesConfig(
          lumaCurve: ChannelCurve(
            channel: CurveChannel.luma,
            points: [
              CurvePoint(x: 0.0, y: 0.0),
              CurvePoint(x: 0.20, y: 0.10),
              CurvePoint(x: 0.80, y: 0.92),
              CurvePoint(x: 1.0, y: 1.0),
            ],
          ),
          redCurve: ChannelCurve(
            channel: CurveChannel.red,
            points: [
              CurvePoint(x: 0.0, y: 0.05),
              CurvePoint(x: 0.50, y: 0.48),
              CurvePoint(x: 1.0, y: 0.95),
            ],
          ),
          greenCurve: ChannelCurve(
            channel: CurveChannel.green,
            points: [
              CurvePoint(x: 0.0, y: 0.05),
              CurvePoint(x: 0.50, y: 0.48),
              CurvePoint(x: 1.0, y: 0.95),
            ],
          ),
          blueCurve: ChannelCurve(
            channel: CurveChannel.blue,
            points: [
              CurvePoint(x: 0.0, y: 0.05),
              CurvePoint(x: 0.50, y: 0.48),
              CurvePoint(x: 1.0, y: 0.95),
            ],
          ),
        );
    }
  }

  /// Whether any of the channels deviate from identity and master intensity > 0.
  bool get isActive {
    if (masterIntensity <= 0.001) return false;
    return !lumaCurve.isIdentity ||
        !redCurve.isIdentity ||
        !greenCurve.isIdentity ||
        !blueCurve.isIdentity;
  }

  /// Returns the corresponding curve for a given [channel].
  ChannelCurve getChannel(CurveChannel channel) {
    switch (channel) {
      case CurveChannel.luma:
        return lumaCurve;
      case CurveChannel.red:
        return redCurve;
      case CurveChannel.green:
        return greenCurve;
      case CurveChannel.blue:
        return blueCurve;
    }
  }

  /// Returns a copy updating the specified [channel].
  CurvesConfig withChannelUpdated(CurveChannel channel, ChannelCurve updated) {
    switch (channel) {
      case CurveChannel.luma:
        return copyWith(lumaCurve: updated);
      case CurveChannel.red:
        return copyWith(redCurve: updated);
      case CurveChannel.green:
        return copyWith(greenCurve: updated);
      case CurveChannel.blue:
        return copyWith(blueCurve: updated);
    }
  }

  CurvesConfig copyWith({
    ChannelCurve? lumaCurve,
    ChannelCurve? redCurve,
    ChannelCurve? greenCurve,
    ChannelCurve? blueCurve,
    double? masterIntensity,
  }) {
    return CurvesConfig(
      lumaCurve: lumaCurve ?? this.lumaCurve,
      redCurve: redCurve ?? this.redCurve,
      greenCurve: greenCurve ?? this.greenCurve,
      blueCurve: blueCurve ?? this.blueCurve,
      masterIntensity: (masterIntensity ?? this.masterIntensity).clamp(0.0, 1.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lumaCurve': lumaCurve.toJson(),
      'redCurve': redCurve.toJson(),
      'greenCurve': greenCurve.toJson(),
      'blueCurve': blueCurve.toJson(),
      'masterIntensity': double.parse(masterIntensity.toStringAsFixed(2)),
    };
  }

  factory CurvesConfig.fromJson(Map<String, dynamic> json) {
    return CurvesConfig(
      lumaCurve: json['lumaCurve'] != null
          ? ChannelCurve.fromJson(json['lumaCurve'] as Map<String, dynamic>)
          : const ChannelCurve(
              channel: CurveChannel.luma,
              points: [CurvePoint(x: 0.0, y: 0.0), CurvePoint(x: 1.0, y: 1.0)],
            ),
      redCurve: json['redCurve'] != null
          ? ChannelCurve.fromJson(json['redCurve'] as Map<String, dynamic>)
          : const ChannelCurve(
              channel: CurveChannel.red,
              points: [CurvePoint(x: 0.0, y: 0.0), CurvePoint(x: 1.0, y: 1.0)],
            ),
      greenCurve: json['greenCurve'] != null
          ? ChannelCurve.fromJson(json['greenCurve'] as Map<String, dynamic>)
          : const ChannelCurve(
              channel: CurveChannel.green,
              points: [CurvePoint(x: 0.0, y: 0.0), CurvePoint(x: 1.0, y: 1.0)],
            ),
      blueCurve: json['blueCurve'] != null
          ? ChannelCurve.fromJson(json['blueCurve'] as Map<String, dynamic>)
          : const ChannelCurve(
              channel: CurveChannel.blue,
              points: [CurvePoint(x: 0.0, y: 0.0), CurvePoint(x: 1.0, y: 1.0)],
            ),
      masterIntensity: (json['masterIntensity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [
        lumaCurve,
        redCurve,
        greenCurve,
        blueCurve,
        masterIntensity,
      ];
}
