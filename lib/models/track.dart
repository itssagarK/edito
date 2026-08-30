import 'package:equatable/equatable.dart';
import 'clip.dart';

enum TrackType { video, audio, text, overlay }

class Track extends Equatable {
  final String id;
  final String name;
  final TrackType type;
  final int order;
  final bool isMuted;
  final bool isLocked;
  final bool isHidden;
  final List<Clip> clips;

  const Track({
    required this.id,
    required this.name,
    required this.type,
    required this.order,
    this.isMuted = false,
    this.isLocked = false,
    this.isHidden = false,
    this.clips = const [],
  });

  int get durationMs {
    if (clips.isEmpty) return 0;
    int maxEnd = 0;
    for (final clip in clips) {
      final end = clip.startTimeMs + clip.durationMs;
      if (end > maxEnd) maxEnd = end;
    }
    return maxEnd;
  }

  Track addClip(Clip clip) {
    return copyWith(
      clips: [...clips, clip],
    );
  }

  Track removeClip(String clipId) {
    return copyWith(
      clips: clips.where((c) => c.id != clipId).toList(),
    );
  }

  Track updateClip(Clip updated) {
    return copyWith(
      clips: clips.map((c) => c.id == updated.id ? updated : c).toList(),
    );
  }

  Track copyWith({
    String? id,
    String? name,
    TrackType? type,
    int? order,
    bool? isMuted,
    bool? isLocked,
    bool? isHidden,
    List<Clip>? clips,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      order: order ?? this.order,
      isMuted: isMuted ?? this.isMuted,
      isLocked: isLocked ?? this.isLocked,
      isHidden: isHidden ?? this.isHidden,
      clips: clips ?? this.clips,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'order': order,
        'isMuted': isMuted,
        'isLocked': isLocked,
        'isHidden': isHidden,
        'clips': clips.map((c) => c.toJson()).toList(),
      };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        name: json['name'] as String,
        type: TrackType.values.firstWhere((e) => e.name == json['type']),
        order: json['order'] as int,
        isMuted: json['isMuted'] as bool? ?? false,
        isLocked: json['isLocked'] as bool? ?? false,
        isHidden: json['isHidden'] as bool? ?? false,
        clips: (json['clips'] as List<dynamic>?)
                ?.map((c) => Clip.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
      );

  @override
  List<Object?> get props => [id, name, type, order, isMuted, isLocked, isHidden, clips];
}
