import 'package:equatable/equatable.dart';

class TeleprompterScript extends Equatable {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  const TeleprompterScript({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }

  int estimatedDurationSec([int wpm = 130]) {
    if (wordCount == 0) return 0;
    final speed = wpm > 0 ? wpm : 130;
    return ((wordCount / speed) * 60).round();
  }

  String formattedEstimatedTime([int wpm = 130]) {
    final sec = estimatedDurationSec(wpm);
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m > 0) {
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${s}s';
  }

  TeleprompterScript copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
  }) {
    return TeleprompterScript(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TeleprompterScript.fromJson(Map<String, dynamic> json) => TeleprompterScript(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Untitled Script',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  @override
  List<Object?> get props => [id, title, content, createdAt];

  static List<TeleprompterScript> get defaultSampleScripts => [
        TeleprompterScript(
          id: 'script_tiktok_hook',
          title: 'Viral Reel Hook & Story',
          content: 'Stop scrolling! If you are editing videos on your phone in 2026, '
              'you need to know this one secret that CapCut pro editors never share.\n\n'
              'Here is the breakdown:\n'
              'First, never cut on the beat alone—cut on the action before the drop.\n'
              'Second, boost your speech clarity with dynamic multiband compression '
              'and an alimiter brickwall ceiling.\n\n'
              'Hit follow for daily mobile video editing secrets!',
          createdAt: DateTime(2026, 1, 1),
        ),
        TeleprompterScript(
          id: 'script_product_demo',
          title: 'Product Review & Demo',
          content: 'Welcome back everyone. Today we are testing Edito Pro, '
              'the ultra-fast video creation suite for mobile.\n\n'
              'Notice the buttery smooth timeline, instant 8K Lanczos upscaling, '
              'and the brand new AI Smart Mosaic tool that blurs license plates '
              'and faces with a single tap.\n\n'
              'Drop a comment below with what feature you want us to add next!',
          createdAt: DateTime(2026, 1, 2),
        ),
      ];
}
