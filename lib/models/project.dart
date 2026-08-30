import 'package:equatable/equatable.dart';
import 'track.dart';
import 'clip.dart';
import 'media_asset.dart';

class Project extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int durationMs;
  final int fps;
  final int width;
  final int height;
  final String? thumbnailPath;
  final List<Track> tracks;
  final List<MediaAsset> assets;

  const Project({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.durationMs = 0,
    this.fps = 30,
    this.width = 1920,
    this.height = 1080,
    this.thumbnailPath,
    this.tracks = const [],
    this.assets = const [],
  });

  /// Recalculates total project duration from the max end time of all clips
  Project recalculateDuration() {
    int maxEnd = 0;
    for (final track in tracks) {
      if (track.durationMs > maxEnd) {
        maxEnd = track.durationMs;
      }
    }
    return copyWith(
      durationMs: maxEnd,
      updatedAt: DateTime.now(),
    );
  }

  /// Appends a media asset to the project's asset library if not already present
  Project addAsset(MediaAsset asset) {
    if (assets.any((a) => a.id == asset.id || a.path == asset.path)) {
      return this;
    }
    return copyWith(
      assets: [...assets, asset],
      updatedAt: DateTime.now(),
    );
  }

  /// Adds a clip to a specific track and recalculates total duration
  Project addClipToTrack(String trackId, Clip clip) {
    final updatedTracks = tracks.map((track) {
      if (track.id == trackId) {
        return track.addClip(clip);
      }
      return track;
    }).toList();

    return copyWith(
      tracks: updatedTracks,
      updatedAt: DateTime.now(),
    ).recalculateDuration();
  }

  /// Removes a clip across all tracks
  Project removeClip(String clipId) {
    final updatedTracks = tracks.map((track) {
      return track.removeClip(clipId);
    }).toList();

    return copyWith(
      tracks: updatedTracks,
      updatedAt: DateTime.now(),
    ).recalculateDuration();
  }

  /// Updates an existing clip
  Project updateClip(Clip updatedClip) {
    final updatedTracks = tracks.map((track) {
      return track.updateClip(updatedClip);
    }).toList();

    return copyWith(
      tracks: updatedTracks,
      updatedAt: DateTime.now(),
    ).recalculateDuration();
  }

  /// Adds a new track to the project
  Project addTrack(Track track) {
    return copyWith(
      tracks: [...tracks, track],
      updatedAt: DateTime.now(),
    );
  }

  /// Removes a track by id
  Project removeTrack(String trackId) {
    return copyWith(
      tracks: tracks.where((t) => t.id != trackId).toList(),
      updatedAt: DateTime.now(),
    ).recalculateDuration();
  }

  Project copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? durationMs,
    int? fps,
    int? width,
    int? height,
    String? thumbnailPath,
    List<Track>? tracks,
    List<MediaAsset>? assets,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      durationMs: durationMs ?? this.durationMs,
      fps: fps ?? this.fps,
      width: width ?? this.width,
      height: height ?? this.height,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      tracks: tracks ?? this.tracks,
      assets: assets ?? this.assets,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'durationMs': durationMs,
        'fps': fps,
        'width': width,
        'height': height,
        'thumbnailPath': thumbnailPath,
        'tracks': tracks.map((t) => t.toJson()).toList(),
        'assets': assets.map((a) => a.toJson()).toList(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
        fps: (json['fps'] as num?)?.toInt() ?? 30,
        width: (json['width'] as num?)?.toInt() ?? 1920,
        height: (json['height'] as num?)?.toInt() ?? 1080,
        thumbnailPath: json['thumbnailPath'] as String?,
        tracks: (json['tracks'] as List<dynamic>?)
                ?.map((t) => Track.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        assets: (json['assets'] as List<dynamic>?)
                ?.map((a) => MediaAsset.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
      );

  @override
  List<Object?> get props => [id, title, createdAt, updatedAt, durationMs, fps, width, height, thumbnailPath, tracks, assets];
}
