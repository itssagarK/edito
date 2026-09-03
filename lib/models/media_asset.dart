import 'package:equatable/equatable.dart';

enum MediaType { video, audio, image }

class MediaAsset extends Equatable {
  final String id;
  final String path;
  final String fileName;
  final MediaType type;
  final int durationMs;
  final int width;
  final int height;
  final double fps;
  final int fileSize;
  final String? thumbnailPath;
  final String? proxyPath;

  const MediaAsset({
    required this.id,
    required this.path,
    required this.fileName,
    required this.type,
    required this.durationMs,
    this.width = 0,
    this.height = 0,
    this.fps = 30.0,
    this.fileSize = 0,
    this.thumbnailPath,
    this.proxyPath,
  });

  bool get is4kOrHigher => width >= 3840 || height >= 2160;
  bool get hasProxy => proxyPath != null && proxyPath!.isNotEmpty;

  MediaAsset copyWith({
    String? id,
    String? path,
    String? fileName,
    MediaType? type,
    int? durationMs,
    int? width,
    int? height,
    double? fps,
    int? fileSize,
    String? thumbnailPath,
    String? proxyPath,
  }) {
    return MediaAsset(
      id: id ?? this.id,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      durationMs: durationMs ?? this.durationMs,
      width: width ?? this.width,
      height: height ?? this.height,
      fps: fps ?? this.fps,
      fileSize: fileSize ?? this.fileSize,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      proxyPath: proxyPath ?? this.proxyPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'fileName': fileName,
        'type': type.name,
        'durationMs': durationMs,
        'width': width,
        'height': height,
        'fps': fps,
        'fileSize': fileSize,
        'thumbnailPath': thumbnailPath,
        'proxyPath': proxyPath,
      };

  factory MediaAsset.fromJson(Map<String, dynamic> json) => MediaAsset(
        id: json['id'] as String,
        path: json['path'] as String,
        fileName: json['fileName'] as String,
        type: MediaType.values.firstWhere((e) => e.name == json['type']),
        durationMs: json['durationMs'] as int,
        width: (json['width'] as num?)?.toInt() ?? 0,
        height: (json['height'] as num?)?.toInt() ?? 0,
        fps: (json['fps'] as num?)?.toDouble() ?? 30.0,
        fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
        thumbnailPath: json['thumbnailPath'] as String?,
        proxyPath: json['proxyPath'] as String?,
      );

  @override
  List<Object?> get props => [id, path, fileName, type, durationMs, width, height, fps, fileSize, thumbnailPath, proxyPath];
}
