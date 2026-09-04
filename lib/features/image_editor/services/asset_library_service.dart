import 'package:uuid/uuid.dart';
import '../../../models/clip.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import '../../overlays/models/text_overlay_config.dart';
import '../models/creative_asset.dart';
import '../models/image_overlay_config.dart';
import '../models/video_layout_config.dart';

class AssetLibraryService {
  /// Returns the catalog of built-in creative assets
  static List<CreativeAsset> getAllAssets() {
    return const [
      // Badges & Stickers
      CreativeAsset(
        id: 'asset_sub',
        title: 'Subscribe & Bell',
        subtitle: 'Call to action animation banner',
        category: AssetCategory.badge,
        iconEmoji: '🔔',
        primaryColor: 0xFFFF0000,
        secondaryColor: 0xFFFFFFFF,
        metadata: {'label': 'SUBSCRIBE', 'emoji': '🔔'},
      ),
      CreativeAsset(
        id: 'asset_like',
        title: 'Thumbs Up & Share',
        subtitle: 'Engagement booster badge',
        category: AssetCategory.badge,
        iconEmoji: '👍',
        primaryColor: 0xFF0088FF,
        secondaryColor: 0xFFFFFFFF,
        metadata: {'label': 'LIKE & SHARE', 'emoji': '👍'},
      ),
      CreativeAsset(
        id: 'asset_trending',
        title: '#1 On Trending',
        subtitle: 'Viral video badge',
        category: AssetCategory.badge,
        iconEmoji: '🔥',
        primaryColor: 0xFFFF5500,
        secondaryColor: 0xFFFFEA00,
        metadata: {'label': '#1 TRENDING', 'emoji': '🔥'},
      ),
      CreativeAsset(
        id: 'asset_4k',
        title: '4K UHD 60FPS',
        subtitle: 'Resolution & quality badge',
        category: AssetCategory.badge,
        iconEmoji: '⚡',
        primaryColor: 0xFF7928CA,
        secondaryColor: 0xFF00DFD8,
        metadata: {'label': '4K UHD 60FPS', 'emoji': '⚡'},
      ),
      CreativeAsset(
        id: 'asset_verified',
        title: 'Official Verified',
        subtitle: 'Credibility creator tick',
        category: AssetCategory.badge,
        iconEmoji: '✓',
        primaryColor: 0xFF00C853,
        secondaryColor: 0xFFFFFFFF,
        metadata: {'label': 'VERIFIED', 'emoji': '✓'},
      ),
      CreativeAsset(
        id: 'asset_live',
        title: 'Live Now',
        subtitle: 'Broadcast badge',
        category: AssetCategory.badge,
        iconEmoji: '🔴',
        primaryColor: 0xFFD50000,
        secondaryColor: 0xFFFFFFFF,
        metadata: {'label': 'LIVE', 'emoji': '🔴'},
      ),

      // Layout Frames & Borders
      CreativeAsset(
        id: 'frame_cinema',
        title: 'Cinematic Anamorphic',
        subtitle: '2.35:1 Widescreen letterbox crop',
        category: AssetCategory.frame,
        iconEmoji: '🎬',
        primaryColor: 0xFF000000,
        metadata: {'ratio': 'ratio21_9', 'padding': 0.0, 'radius': 0.0},
      ),
      CreativeAsset(
        id: 'frame_rounded',
        title: 'Modern Rounded Border',
        subtitle: 'Floating rounded frame with blur',
        category: AssetCategory.frame,
        iconEmoji: '📱',
        primaryColor: 0xFF6366F1,
        metadata: {'padding': 16.0, 'radius': 24.0, 'bg': 'blur'},
      ),
      CreativeAsset(
        id: 'frame_polaroid',
        title: 'Vintage Polaroid Frame',
        subtitle: 'Retro photo paper border',
        category: AssetCategory.frame,
        iconEmoji: '📷',
        primaryColor: 0xFFFAFAFA,
        metadata: {'padding': 24.0, 'radius': 4.0, 'bg': 'solidColor', 'color': 0xFFFFFFFF},
      ),

      // Lower Thirds & Titles
      CreativeAsset(
        id: 'lower_breaking',
        title: 'Breaking News Banner',
        subtitle: 'Bottom alert banner',
        category: AssetCategory.lowerThird,
        iconEmoji: '📢',
        primaryColor: 0xFFCC0000,
        metadata: {'text': '🔴 BREAKING NEWS: WATCH FULL UPDATE', 'y': 0.88},
      ),
      CreativeAsset(
        id: 'lower_social',
        title: 'Social Handle @User',
        subtitle: 'Channel branding card',
        category: AssetCategory.lowerThird,
        iconEmoji: '💬',
        primaryColor: 0xFF1D9BF0,
        metadata: {'text': '@YourChannel • Subscribe for more', 'y': 0.82},
      ),
      CreativeAsset(
        id: 'lower_chapter',
        title: 'Chapter Segment Card',
        subtitle: 'Topic introduction card',
        category: AssetCategory.lowerThird,
        iconEmoji: '🔖',
        primaryColor: 0xFFFFB703,
        metadata: {'text': 'CHAPTER 01: INTRODUCTION', 'y': 0.20},
      ),

      // Canvas Backgrounds
      CreativeAsset(
        id: 'bg_cosmic',
        title: 'Dark Cosmic Nebula',
        subtitle: 'Deep purple/blue gradient',
        category: AssetCategory.background,
        iconEmoji: '🌌',
        primaryColor: 0xFF180B38,
        metadata: {'color': 0xFF180B38},
      ),
      CreativeAsset(
        id: 'bg_cyber',
        title: 'Cyberpunk Grid',
        subtitle: 'Neon cyan/pink backdrop',
        category: AssetCategory.background,
        iconEmoji: '🌆',
        primaryColor: 0xFF0D0221,
        metadata: {'color': 0xFF0D0221},
      ),
      CreativeAsset(
        id: 'bg_minimal',
        title: 'Minimal Studio Grey',
        subtitle: 'Clean neutral charcoal',
        category: AssetCategory.background,
        iconEmoji: '🎨',
        primaryColor: 0xFF1E293B,
        metadata: {'color': 0xFF1E293B},
      ),
    ];
  }

  /// Filters assets by category
  static List<CreativeAsset> getAssetsByCategory(AssetCategory category) {
    return getAllAssets().where((a) => a.category == category).toList();
  }

  /// Applies a selected creative asset directly into the project structure
  static Project applyAssetToProject(Project project, CreativeAsset asset, {String? targetClipId}) {
    switch (asset.category) {
      case AssetCategory.badge:
        // Add as an ImageOverlay on the target clip or create overlay track
        return _applyBadgeOverlay(project, asset, targetClipId: targetClipId);

      case AssetCategory.lowerThird:
        // Add a styled lower third text overlay
        return _applyLowerThird(project, asset, targetClipId: targetClipId);

      case AssetCategory.frame:
      case AssetCategory.background:
        // Configure project layout
        return _applyLayoutConfig(project, asset);
    }
  }

  static Project _applyBadgeOverlay(Project project, CreativeAsset asset, {String? targetClipId}) {
    final label = asset.metadata['label'] as String? ?? asset.title;
    final emoji = asset.metadata['emoji'] as String? ?? asset.iconEmoji;

    final overlayConfig = ImageOverlayConfig(
      isEnabled: true,
      assetLabel: '$emoji $label',
      positionX: 0.85,
      positionY: 0.18,
      scale: 1.0,
      opacity: 1.0,
      borderColor: asset.primaryColor,
    );

    // If target clip provided, apply overlay to it
    if (targetClipId != null) {
      for (final track in project.tracks) {
        for (final clip in track.clips) {
          if (clip.id == targetClipId) {
            final updatedClip = clip.copyWith(imageOverlay: overlayConfig);
            return project.updateClip(updatedClip);
          }
        }
      }
    }

    // Otherwise apply to first video clip
    for (final track in project.tracks) {
      if (track.type == TrackType.video && track.clips.isNotEmpty) {
        final firstClip = track.clips.first;
        final updatedClip = firstClip.copyWith(imageOverlay: overlayConfig);
        return project.updateClip(updatedClip);
      }
    }

    return project;
  }

  static Project _applyLowerThird(Project project, CreativeAsset asset, {String? targetClipId}) {
    final text = asset.metadata['text'] as String? ?? asset.title;
    final posY = (asset.metadata['y'] as num?)?.toDouble() ?? 0.85;

    final textConfig = TextOverlayConfig(
      text: text,
      positionX: 0.5,
      positionY: posY,
      fontSize: 22,
      textColor: 0xFFFFFFFF,
      backgroundColor: asset.primaryColor.withOpacity(0.85).toInt(),
    );

    // Create a new overlay clip or apply to clip
    final duration = project.durationMs > 0 ? project.durationMs : 4000;
    final newClip = Clip(
      id: const Uuid().v4(),
      assetId: '',
      trackId: 'track_overlay_assets',
      startTimeMs: 0,
      durationMs: duration,
      sourceInMs: 0,
      sourceOutMs: duration,
      textOverlay: textConfig,
    );

    // Check if an overlay track exists
    Track? overlayTrack;
    for (final t in project.tracks) {
      if (t.type == TrackType.overlay || t.type == TrackType.text) {
        overlayTrack = t;
        break;
      }
    }

    if (overlayTrack != null) {
      final updatedTrack = overlayTrack.copyWith(clips: [...overlayTrack.clips, newClip]);
      return project.updateTrack(updatedTrack);
    } else {
      final newTrack = Track(
        id: const Uuid().v4(),
        name: 'Graphics & Titles',
        type: TrackType.overlay,
        order: project.tracks.length,
        clips: [newClip],
      );
      return project.copyWith(tracks: [...project.tracks, newTrack]);
    }
  }

  static Project _applyLayoutConfig(Project project, CreativeAsset asset) {
    VideoLayoutConfig currentLayout = project.layoutConfig;

    if (asset.category == AssetCategory.frame) {
      final ratioStr = asset.metadata['ratio'] as String?;
      final padding = (asset.metadata['padding'] as num?)?.toDouble() ?? 0.0;
      final radius = (asset.metadata['radius'] as num?)?.toDouble() ?? 0.0;
      final bg = asset.metadata['bg'] as String?;

      VideoLayoutRatio ratio = currentLayout.ratio;
      if (ratioStr != null) {
        ratio = VideoLayoutRatio.values.firstWhere((r) => r.name == ratioStr, orElse: () => ratio);
      }

      currentLayout = currentLayout.copyWith(
        ratio: ratio,
        framePadding: padding,
        cornerRadius: radius,
        backgroundMode: bg == 'blur' ? LayoutBackgroundMode.blur : currentLayout.backgroundMode,
      );
    } else if (asset.category == AssetCategory.background) {
      final color = asset.metadata['color'] as int? ?? asset.primaryColor;
      currentLayout = currentLayout.copyWith(
        backgroundMode: LayoutBackgroundMode.solidColor,
        backgroundColor: color,
      );
    }

    return project.copyWith(
      layoutConfig: currentLayout,
      width: currentLayout.ratio.defaultWidth,
      height: currentLayout.ratio.defaultHeight,
    );
  }
}

extension IntColorExtension on int {
  int withOpacity(double opacity) {
    final a = (opacity * 255).round().clamp(0, 255);
    return (this & 0x00FFFFFF) | (a << 24);
  }
}
