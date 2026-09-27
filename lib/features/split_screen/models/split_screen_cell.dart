import 'package:equatable/equatable.dart';

class SplitScreenCell extends Equatable {
  final int index;
  final String? clipId;
  final String? assetPath;
  final double panX;
  final double panY;
  final double scale;
  final bool isMuted;
  final double volume;

  const SplitScreenCell({
    required this.index,
    this.clipId,
    this.assetPath,
    this.panX = 0.0,
    this.panY = 0.0,
    this.scale = 1.0,
    this.isMuted = false,
    this.volume = 1.0,
  });

  bool get hasMedia => (clipId != null && clipId!.isNotEmpty) || (assetPath != null && assetPath!.isNotEmpty);

  SplitScreenCell copyWith({
    int? index,
    String? clipId,
    String? assetPath,
    double? panX,
    double? panY,
    double? scale,
    bool? isMuted,
    double? volume,
  }) {
    return SplitScreenCell(
      index: index ?? this.index,
      clipId: clipId ?? this.clipId,
      assetPath: assetPath ?? this.assetPath,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      scale: scale ?? this.scale,
      isMuted: isMuted ?? this.isMuted,
      volume: volume ?? this.volume,
    );
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'clipId': clipId,
        'assetPath': assetPath,
        'panX': panX,
        'panY': panY,
        'scale': scale,
        'isMuted': isMuted,
        'volume': volume,
      };

  factory SplitScreenCell.fromJson(Map<String, dynamic> json) => SplitScreenCell(
        index: (json['index'] as num?)?.toInt() ?? 0,
        clipId: json['clipId'] as String?,
        assetPath: json['assetPath'] as String?,
        panX: (json['panX'] as num?)?.toDouble() ?? 0.0,
        panY: (json['panY'] as num?)?.toDouble() ?? 0.0,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        isMuted: json['isMuted'] as bool? ?? false,
        volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  List<Object?> get props => [
        index,
        clipId,
        assetPath,
        panX,
        panY,
        scale,
        isMuted,
        volume,
      ];
}
