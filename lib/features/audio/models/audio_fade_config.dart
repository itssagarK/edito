import 'package:equatable/equatable.dart';

enum AudioFadeCurve {
  logarithmic,
  linear,
  exponential,
  sCurve,
}

extension AudioFadeCurveExtension on AudioFadeCurve {
  String get label {
    switch (this) {
      case AudioFadeCurve.logarithmic:
        return 'Natural (Logarithmic)';
      case AudioFadeCurve.linear:
        return 'Linear';
      case AudioFadeCurve.exponential:
        return 'Smooth (Exponential)';
      case AudioFadeCurve.sCurve:
        return 'Cinematic (S-Curve)';
    }
  }

  String get ffmpegCurveName {
    switch (this) {
      case AudioFadeCurve.logarithmic:
        return 'log';
      case AudioFadeCurve.linear:
        return 'tri';
      case AudioFadeCurve.exponential:
        return 'exp';
      case AudioFadeCurve.sCurve:
        return 'qsin';
    }
  }
}

class AudioFadeConfig extends Equatable {
  final int fadeInDurationMs;
  final int fadeOutDurationMs;
  final AudioFadeCurve curve;

  const AudioFadeConfig({
    this.fadeInDurationMs = 0,
    this.fadeOutDurationMs = 0,
    this.curve = AudioFadeCurve.logarithmic,
  });

  bool get hasFade => fadeInDurationMs > 0 || fadeOutDurationMs > 0;

  AudioFadeConfig copyWith({
    int? fadeInDurationMs,
    int? fadeOutDurationMs,
    AudioFadeCurve? curve,
  }) {
    return AudioFadeConfig(
      fadeInDurationMs: fadeInDurationMs ?? this.fadeInDurationMs,
      fadeOutDurationMs: fadeOutDurationMs ?? this.fadeOutDurationMs,
      curve: curve ?? this.curve,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fadeInDurationMs': fadeInDurationMs,
      'fadeOutDurationMs': fadeOutDurationMs,
      'curve': curve.name,
    };
  }

  factory AudioFadeConfig.fromJson(Map<String, dynamic> json) {
    return AudioFadeConfig(
      fadeInDurationMs: json['fadeInDurationMs'] as int? ?? 0,
      fadeOutDurationMs: json['fadeOutDurationMs'] as int? ?? 0,
      curve: AudioFadeCurve.values.firstWhere(
        (e) => e.name == json['curve'],
        orElse: () => AudioFadeCurve.logarithmic,
      ),
    );
  }

  @override
  List<Object?> get props => [fadeInDurationMs, fadeOutDurationMs, curve];
}
