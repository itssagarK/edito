import 'package:equatable/equatable.dart';

enum AssetCategory {
  badge('Badges & Stickers'),
  frame('Layout Frames & Borders'),
  lowerThird('Lower Thirds & Titles'),
  background('Canvas Backgrounds');

  final String label;
  const AssetCategory(this.label);
}

class CreativeAsset extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final AssetCategory category;
  final String iconEmoji;
  final int primaryColor;
  final int secondaryColor;
  final Map<String, dynamic> metadata;

  const CreativeAsset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.iconEmoji,
    required this.primaryColor,
    this.secondaryColor = 0xFFFFFFFF,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        category,
        iconEmoji,
        primaryColor,
        secondaryColor,
        metadata,
      ];
}
