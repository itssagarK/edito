import 'package:equatable/equatable.dart';
import 'track.dart';
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
