import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/editor_provider.dart';

/// CapCut-Style Two-Tier Contextual Dock.
/// Switches smoothly between:
/// 1. Global Navigation Dock (when no clip is selected)
/// 2. Contextual Clip Action Dock with Back button (when a clip is selected)
class EditingToolbar extends StatelessWidget {
  final EditorTool activeTool;
  final bool hasSelectedClip;
  final Function(EditorTool) onSelectTool;
  final VoidCallback? onDeselectClip;
  final VoidCallback onAddTrack;

  const EditingToolbar({
    super.key,
    required this.activeTool,
    required this.hasSelectedClip,
    required this.onSelectTool,
    this.onDeselectClip,
    required this.onAddTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.25),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: hasSelectedClip
              ? _buildContextualClipDock(context)
              : _buildGlobalCategoryDock(context),
        ),
      ),
    );
  }

  // --- 1. CONTEXTUAL CLIP DOCK (CLIP SELECTED) ---
  Widget _buildContextualClipDock(BuildContext context) {
    final clipTools = [
      _ToolItem(EditorTool.split, 'Split', Icons.content_cut),
      _ToolItem(EditorTool.speed, 'Speed', Icons.speed),
      _ToolItem(EditorTool.keyframes, 'Animation', Icons.animation),
      _ToolItem(EditorTool.tracking, 'Tracking', Icons.my_location),
      _ToolItem(EditorTool.audio, 'Volume', Icons.volume_up_outlined),
      _ToolItem(EditorTool.chromaKey, 'Cutout', Icons.blur_linear),
      _ToolItem(EditorTool.retouch, 'Retouch', Icons.face_retouching_natural),
      _ToolItem(EditorTool.mask, 'Mask', Icons.masks),
      _ToolItem(EditorTool.blend, 'Blend', Icons.layers),
      _ToolItem(EditorTool.enhance, '8K Upscale', Icons.auto_awesome_motion),
      _ToolItem(EditorTool.smooth, 'Flow & Blur', Icons.waves),
      _ToolItem(EditorTool.color, 'Filters', Icons.palette_outlined),
      _ToolItem(EditorTool.effects, 'Transitions', Icons.transform_outlined),
      _ToolItem(EditorTool.characterZoom, 'Zoom', Icons.center_focus_strong),
      _ToolItem(EditorTool.parallax3D, '3D Zoom', Icons.view_in_ar),
      _ToolItem(EditorTool.stabilization, 'Stabilize', Icons.screen_lock_rotation),
      _ToolItem(EditorTool.vocalIsolation, 'Isolate Voice', Icons.record_voice_over),
      _ToolItem(EditorTool.colorMatch, 'Color Match', Icons.auto_fix_high),
      _ToolItem(EditorTool.relight, 'Relight', Icons.lightbulb_circle),
      _ToolItem(EditorTool.denoise, 'Denoise', Icons.noise_control_off),
      _ToolItem(EditorTool.borders, 'Border', Icons.border_outer),
      _ToolItem(EditorTool.clipWorkflow, 'Actions', Icons.movie_filter_outlined),
      _ToolItem(EditorTool.layout, 'Reframe', Icons.aspect_ratio),
    ];

    return KeyedSubtree(
      key: const ValueKey('contextual_clip_dock'),
      child: Row(
        children: [
          // CapCut-Style Back Button
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 4, top: 8, bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onDeselectClip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.accent),
                    const SizedBox(height: 4),
                    Text(
                      'Back',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.border),

          // Scrollable Clip Action Items
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: clipTools.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final item = clipTools[index];
                final isSelected = activeTool == item.tool;

                return _buildToolTile(item, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. GLOBAL CATEGORY DOCK (NO CLIP SELECTED) ---
  Widget _buildGlobalCategoryDock(BuildContext context) {
    final globalTools = [
      _ToolItem(EditorTool.select, 'Edit', Icons.movie_creation_outlined),
      _ToolItem(EditorTool.audio, 'Audio', Icons.mic_none),
      _ToolItem(EditorTool.text, 'Text', Icons.title),
      _ToolItem(EditorTool.captions, 'Captions', Icons.closed_caption),
      _ToolItem(EditorTool.tts, 'AI Voice', Icons.record_voice_over),
      _ToolItem(EditorTool.imageOverlay, 'Overlay', Icons.picture_in_picture_alt_outlined),
      _ToolItem(EditorTool.tracking, 'Tracking', Icons.my_location),
      _ToolItem(EditorTool.vfx, 'Effects', Icons.auto_awesome),
      _ToolItem(EditorTool.retouch, 'Retouch', Icons.face_retouching_natural),
      _ToolItem(EditorTool.parallax3D, '3D Zoom', Icons.view_in_ar),
      _ToolItem(EditorTool.color, 'Filters', Icons.palette_outlined),
      _ToolItem(EditorTool.layout, 'Ratio', Icons.aspect_ratio),
      _ToolItem(EditorTool.highlight, 'Canvas', Icons.photo_filter_outlined),
      _ToolItem(EditorTool.enhance, '8K Boost', Icons.auto_awesome_motion),
      _ToolItem(EditorTool.imageEditor, 'Cover', Icons.photo_size_select_actual_outlined),
      _ToolItem(EditorTool.hdConverter, 'HD Ultra', Icons.high_quality),
      _ToolItem(EditorTool.beats, 'Beats', Icons.music_note),
    ];

    return KeyedSubtree(
      key: const ValueKey('global_category_dock'),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: globalTools.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == globalTools.length) {
            return _buildAddTrackButton();
          }
          final item = globalTools[index];
          final isSelected = activeTool == item.tool;

          return _buildToolTile(item, isSelected);
        },
      ),
    );
  }

  Widget _buildToolTile(_ToolItem item, bool isSelected) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onSelectTool(item.tool),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTrackButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onAddTrack,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 20, color: AppColors.accent),
            const SizedBox(height: 4),
            Text(
              'Add Track',
              style: AppTypography.labelSmall.copyWith(color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolItem {
  final EditorTool tool;
  final String label;
  final IconData icon;

  const _ToolItem(this.tool, this.label, this.icon);
}
