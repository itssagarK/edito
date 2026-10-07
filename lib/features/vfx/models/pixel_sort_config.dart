import 'package:equatable/equatable.dart';

/// Direction and geometry modes for algorithmic luminance pixel sorting.
enum PixelSortMode {
  verticalDown,
  horizontalTear,
  diagonalSlant,
  radiantBurst,
  thresholdBand;

  String get displayName {
    switch (this) {
      case PixelSortMode.verticalDown:
        return 'Cyber Rain (Vertical)';
      case PixelSortMode.horizontalTear:
        return 'Data Tear (Horizontal)';
      case PixelSortMode.diagonalSlant:
        return 'Diagonal Slant Drift';
      case PixelSortMode.radiantBurst:
        return 'Radiant Center Burst';
      case PixelSortMode.thresholdBand:
        return 'Selective Midtone Band';
    }
  }

  String get description {
    switch (this) {
      case PixelSortMode.verticalDown:
        return 'Pixels cascade downwards in vertical sorted luminance streaks like digital rain';
      case PixelSortMode.horizontalTear:
        return 'Horizontal pixel sorting streaks tearing high-brightness edges across the frame';
      case PixelSortMode.diagonalSlant:
        return 'Angular 45-degree pixel sorting displacement flowing across composition diagonals';
      case PixelSortMode.radiantBurst:
        return 'Outward radiating pixel sort trajectories expanding dynamically from frame center';
      case PixelSortMode.thresholdBand:
        return 'Restricts pixel sorting exclusively to highlights and specular reflections';
    }
  }
}

/// Configuration for algorithmic pixel sorting and digital glitch data streaks.
class PixelSortConfig extends Equatable {
  final bool isEnabled;
  final PixelSortMode mode;
  final double threshold; // 0.1 to 0.95 (luminance trigger point for sorting)
  final double streakLength; // 0.1 to 1.0 (length of sorted pixel smears)
  final double angleDeg; // 0.0 to 360.0 (displacement vector direction)
  final double randomness; // 0.0 to 1.0 (streak boundary jitter and noise)
  final double intensity; // 0.0 to 1.0 (streak blend mix)

  const PixelSortConfig({
    this.isEnabled = false,
    this.mode = PixelSortMode.verticalDown,
    this.threshold = 0.60,
    this.streakLength = 0.50,
    this.angleDeg = 90.0,
    this.randomness = 0.30,
    this.intensity = 0.85,
  });

  bool get isActive => isEnabled && streakLength > 0.05 && intensity > 0.05;

  PixelSortConfig copyWith({
    bool? isEnabled,
    PixelSortMode? mode,
    double? threshold,
    double? streakLength,
    double? angleDeg,
    double? randomness,
    double? intensity,
  }) {
    return PixelSortConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      threshold: threshold ?? this.threshold,
      streakLength: streakLength ?? this.streakLength,
      angleDeg: angleDeg ?? this.angleDeg,
      randomness: randomness ?? this.randomness,
      intensity: intensity ?? this.intensity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'threshold': threshold,
      'streakLength': streakLength,
      'angleDeg': angleDeg,
      'randomness': randomness,
      'intensity': intensity,
    };
  }

  factory PixelSortConfig.fromJson(Map<String, dynamic> json) {
    PixelSortMode parsedMode = PixelSortMode.verticalDown;
    if (json['mode'] != null) {
      try {
        parsedMode = PixelSortMode.values.byName(json['mode'] as String);
      } catch (_) {
        parsedMode = PixelSortMode.verticalDown;
      }
    }

    return PixelSortConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: parsedMode,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.60,
      streakLength: (json['streakLength'] as num?)?.toDouble() ?? 0.50,
      angleDeg: (json['angleDeg'] as num?)?.toDouble() ?? 90.0,
      randomness: (json['randomness'] as num?)?.toDouble() ?? 0.30,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.85,
    );
  }

  // Curated presets
  static const PixelSortConfig cyberRainDown = PixelSortConfig(
    isEnabled: true,
    mode: PixelSortMode.verticalDown,
    threshold: 0.55,
    streakLength: 0.70,
    angleDeg: 90.0,
    randomness: 0.40,
    intensity: 0.90,
  );

  static const PixelSortConfig horizontalDataTear = PixelSortConfig(
    isEnabled: true,
    mode: PixelSortMode.horizontalTear,
    threshold: 0.65,
    streakLength: 0.60,
    angleDeg: 0.0,
    randomness: 0.35,
    intensity: 0.85,
  );

  static const PixelSortConfig neonStreakWarp = PixelSortConfig(
    isEnabled: true,
    mode: PixelSortMode.diagonalSlant,
    threshold: 0.45,
    streakLength: 0.80,
    angleDeg: 45.0,
    randomness: 0.25,
    intensity: 0.95,
  );

  static const PixelSortConfig radiantBurstSort = PixelSortConfig(
    isEnabled: true,
    mode: PixelSortMode.radiantBurst,
    threshold: 0.50,
    streakLength: 0.65,
    angleDeg: 0.0,
    randomness: 0.50,
    intensity: 0.90,
  );

  static const PixelSortConfig subtleGrainStreak = PixelSortConfig(
    isEnabled: true,
    mode: PixelSortMode.thresholdBand,
    threshold: 0.75,
    streakLength: 0.35,
    angleDeg: 90.0,
    randomness: 0.20,
    intensity: 0.70,
  );

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        threshold,
        streakLength,
        angleDeg,
        randomness,
        intensity,
      ];
}
