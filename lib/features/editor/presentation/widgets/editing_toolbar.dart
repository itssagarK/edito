import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/editor_provider.dart';


/// CapCut-Style Two-Tier Contextual Dock.
/// Switches smoothly between:
/// 1. Global Navigation Dock (when no clip is selected) - 9 core categories + More sheet
/// 2. Contextual Clip Action Dock (when a clip is selected) - 14 primary tools + More sheet
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
    // 14 Core CapCut editing tools
    final primaryClipTools = [
      const _ToolItem(EditorTool.split, 'Split', Icons.content_cut),
      const _ToolItem(EditorTool.speed, 'Speed', Icons.speed),
      const _ToolItem(EditorTool.audio, 'Volume', Icons.volume_up_outlined),
      const _ToolItem(EditorTool.keyframes, 'Animation', Icons.animation),
      const _ToolItem(EditorTool.chromaKey, 'Cutout', Icons.blur_linear),
      const _ToolItem(EditorTool.transform, 'Transform', Icons.crop_rotate),
      const _ToolItem(EditorTool.mask, 'Mask', Icons.masks),
      const _ToolItem(EditorTool.color, 'Filters', Icons.palette_outlined),
      const _ToolItem(EditorTool.curves, 'Adjust', Icons.show_chart),
      const _ToolItem(EditorTool.extractAudio, 'Extract Audio', Icons.music_note),
      const _ToolItem(EditorTool.reverseClip, 'Reverse', Icons.replay),
      const _ToolItem(EditorTool.freezeFrame, 'Freeze', Icons.ac_unit),
      const _ToolItem(EditorTool.duplicateClip, 'Duplicate', Icons.control_point_duplicate),
      const _ToolItem(EditorTool.deleteClip, 'Delete', Icons.delete_outline),
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

          // Scrollable Primary Clip Action Items
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: primaryClipTools.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                if (index == primaryClipTools.length) {
                  return _buildMoreClipToolsButton(context);
                }
                final item = primaryClipTools[index];
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
    // 9 Core CapCut global categories
    final globalTools = [
      const _ToolItem(EditorTool.select, 'Edit', Icons.movie_creation_outlined),
      const _ToolItem(EditorTool.audio, 'Audio', Icons.music_note_outlined),
      const _ToolItem(EditorTool.text, 'Text', Icons.title),
      const _ToolItem(EditorTool.imageOverlay, 'Overlay', Icons.picture_in_picture_alt_outlined),
      const _ToolItem(EditorTool.vfx, 'Effects', Icons.auto_awesome),
      const _ToolItem(EditorTool.color, 'Filters', Icons.palette_outlined),
      const _ToolItem(EditorTool.layout, 'Ratio', Icons.aspect_ratio),
      const _ToolItem(EditorTool.highlight, 'Canvas', Icons.photo_filter_outlined),
      const _ToolItem(EditorTool.curves, 'Adjust', Icons.tune),
    ];

    return KeyedSubtree(
      key: const ValueKey('global_category_dock'),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: globalTools.length + 2,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == globalTools.length) {
            return _buildMoreGlobalToolsButton(context);
          }
          if (index == globalTools.length + 1) {
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

  Widget _buildMoreGlobalToolsButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showGlobalMoreToolsSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apps_rounded, size: 20, color: AppColors.accent),
            const SizedBox(height: 4),
            Text(
              'More',
              style: AppTypography.labelSmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreClipToolsButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showClipMoreToolsSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.more_horiz, size: 20, color: AppColors.accent),
            const SizedBox(height: 4),
            Text(
              'More',
              style: AppTypography.labelSmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
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
            const Icon(Icons.add_circle_outline, size: 20, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              'Add Track',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. MORE TOOLS SHEETS ---
  void _showGlobalMoreToolsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Creative Suite',
                      style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                      style: IconButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(28, 28)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildSheetToolItem(sheetContext, EditorTool.audioRecord, 'Record Voice', Icons.mic),
                    _buildSheetToolItem(sheetContext, EditorTool.captions, 'Auto Captions', Icons.closed_caption),
                    _buildSheetToolItem(sheetContext, EditorTool.tts, 'Voiceover', Icons.record_voice_over),
                    _buildSheetToolItem(sheetContext, EditorTool.teleprompter, 'Prompter', Icons.subtitles_outlined),
                    _buildSheetToolItem(sheetContext, EditorTool.imageEditor, 'Cover Maker', Icons.photo_size_select_actual_outlined),
                    _buildSheetToolItem(sheetContext, EditorTool.enhance, '8K Boost', Icons.auto_awesome_motion),
                    _buildSheetToolItem(sheetContext, EditorTool.hdConverter, 'HD Ultra', Icons.high_quality),
                    _buildSheetToolItem(sheetContext, EditorTool.beats, 'Beats Sync', Icons.music_note),
                    _buildSheetToolItem(sheetContext, EditorTool.parallax3D, '3D Zoom', Icons.view_in_ar),
                    _buildSheetToolItem(sheetContext, EditorTool.splitScreen, 'Split Screen', Icons.grid_view_rounded),
                    _buildSheetToolItem(sheetContext, EditorTool.doodle, 'Doodle', Icons.draw),

                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClipMoreToolsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Advanced Clip Tools',
                      style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                      style: IconButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(28, 28)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSectionHeader('Smart & Pro Actions'),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _buildSheetToolItem(sheetContext, EditorTool.stabilization, 'Stabilize', Icons.screen_lock_rotation),
                    _buildSheetToolItem(sheetContext, EditorTool.parallax3D, '3D Zoom', Icons.view_in_ar),
                    _buildSheetToolItem(sheetContext, EditorTool.relight, 'Relight', Icons.lightbulb_circle),
                    _buildSheetToolItem(sheetContext, EditorTool.splitScreen, 'Split Screen', Icons.grid_view_rounded),
                    _buildSheetToolItem(sheetContext, EditorTool.mask, 'Mask', Icons.theater_comedy),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSectionHeader('Audio & Voice Suite'),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _buildSheetToolItem(sheetContext, EditorTool.audioRecord, 'Record Voice', Icons.mic),
                    _buildSheetToolItem(sheetContext, EditorTool.vocalIsolation, 'Isolate Voice', Icons.record_voice_over),
                    _buildSheetToolItem(sheetContext, EditorTool.voiceEffects, 'Voice Effect', Icons.mic_external_on),
                    _buildSheetToolItem(sheetContext, EditorTool.denoise, 'Denoise', Icons.noise_control_off),
                    _buildSheetToolItem(sheetContext, EditorTool.soundEffects, 'Sound FX', Icons.speaker),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSectionHeader('Visual Styling & FX'),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _buildSheetToolItem(sheetContext, EditorTool.blend, 'Blend Mode', Icons.layers),
                    _buildSheetToolItem(sheetContext, EditorTool.colorWheels, 'Color Wheels', Icons.donut_large),
                    _buildSheetToolItem(sheetContext, EditorTool.colorMatch, 'Color Match', Icons.auto_fix_high),
                    _buildSheetToolItem(sheetContext, EditorTool.filmGrain, 'Film Grain', Icons.grain),
                    _buildSheetToolItem(sheetContext, EditorTool.vignette, 'Vignette', Icons.blur_circular),
                    _buildSheetToolItem(sheetContext, EditorTool.edgeAura, 'Edge Aura', Icons.flare),
                    _buildSheetToolItem(sheetContext, EditorTool.mosaic, 'Mosaic', Icons.blur_on),
                    _buildSheetToolItem(sheetContext, EditorTool.smooth, 'Flow & Blur', Icons.waves),
                    _buildSheetToolItem(sheetContext, EditorTool.effects, 'Transitions', Icons.transform_outlined),
                    _buildSheetToolItem(sheetContext, EditorTool.borders, 'Border', Icons.border_outer),
                    _buildSheetToolItem(sheetContext, EditorTool.enhance, '8K Upscale', Icons.auto_awesome_motion),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildSheetToolItem(BuildContext sheetContext, EditorTool tool, String label, IconData icon) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.pop(sheetContext);
        onSelectTool(tool);
      },
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppColors.primaryLight),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetActionItem(BuildContext sheetContext, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.pop(sheetContext);
        onTap();
      },
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppColors.accent),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
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
