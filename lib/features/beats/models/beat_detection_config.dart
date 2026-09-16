import 'package:equatable/equatable.dart';

enum BeatDetectionMode {
  auto,
  manual,
  gridBpm,
}

extension BeatDetectionModeExtension on BeatDetectionMode {
  String get label {
    switch (this) {
      case BeatDetectionMode.auto:
        return 'Auto Transient';
      case BeatDetectionMode.manual:
        return 'Tap Tempo / Manual';
      case BeatDetectionMode.gridBpm:
        return 'Rhythm Grid BPM';
    }
  }

  String get description {
    switch (this) {
      case BeatDetectionMode.auto:
        return 'Automatic transient peak energy detection';
      case BeatDetectionMode.manual:
        return 'Tap along with the rhythm to place custom beat markers';
      case BeatDetectionMode.gridBpm:
        return 'Mathematical tempo grid aligned to target BPM';
    }
  }
}

class BeatDetectionConfig extends Equatable {
  final bool isEnabled;
  final BeatDetectionMode mode;
  final double bpm;                      // 40.0 to 240.0 (default 120.0)
  final double sensitivity;              // 0.1 to 1.0 (default 0.70)
  final bool snapToBeats;                // Magnetic timeline snapping
  final List<int> beatTimestampsMs;      // Milliseconds relative to clip start

  const BeatDetectionConfig({
    this.isEnabled = false,
    this.mode = BeatDetectionMode.auto,
    this.bpm = 120.0,
    this.sensitivity = 0.70,
    this.snapToBeats = true,
    this.beatTimestampsMs = const [],
  });

  bool get hasBeats => isEnabled && beatTimestampsMs.isNotEmpty;

  BeatDetectionConfig copyWith({
    bool? isEnabled,
    BeatDetectionMode? mode,
    double? bpm,
    double? sensitivity,
    bool? snapToBeats,
    List<int>? beatTimestampsMs,
  }) {
    return BeatDetectionConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      bpm: bpm ?? this.bpm,
      sensitivity: sensitivity ?? this.sensitivity,
      snapToBeats: snapToBeats ?? this.snapToBeats,
      beatTimestampsMs: beatTimestampsMs ?? this.beatTimestampsMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'mode': mode.name,
        'bpm': bpm,
        'sensitivity': sensitivity,
        'snapToBeats': snapToBeats,
        'beatTimestampsMs': beatTimestampsMs,
      };

  factory BeatDetectionConfig.fromJson(Map<String, dynamic> json) => BeatDetectionConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        mode: BeatDetectionMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => BeatDetectionMode.auto,
        ),
        bpm: (json['bpm'] as num?)?.toDouble() ?? 120.0,
        sensitivity: (json['sensitivity'] as num?)?.toDouble() ?? 0.70,
        snapToBeats: json['snapToBeats'] as bool? ?? true,
        beatTimestampsMs: (json['beatTimestampsMs'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        bpm,
        sensitivity,
        snapToBeats,
        beatTimestampsMs,
      ];
}
