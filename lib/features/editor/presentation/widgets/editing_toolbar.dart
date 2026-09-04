import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/editor_provider.dart';

class EditingToolbar extends StatelessWidget {
  final EditorTool activeTool;
  final bool hasSelectedClip;
  final Function(EditorTool) onSelectTool;
  final VoidCallback onAddTrack;

  const EditingToolbar({
    super.key,
    required this.activeTool,
    required this.hasSelectedClip,
    required this.onSelectTool,
    required this.onAddTrack,
  });

  @override
  Widget build(BuildContext context) {
    final tools = [
      _ToolItem(EditorTool.split, 'Split', Icons.content_cut),
      _ToolItem(EditorTool.trim, 'Trim', Icons.crop),
      _ToolItem(EditorTool.enhance, '8K Upscale', Icons.auto_awesome_motion),
      _ToolItem(EditorTool.smooth, 'Smoother', Icons.waves),
      _ToolItem(EditorTool.speed, 'Speed', Icons.speed),
      _ToolItem(EditorTool.audio, 'Voice & Audio', Icons.mic_none),
      _ToolItem(EditorTool.color, 'Color & Looks', Icons.palette_outlined),
      _ToolItem(EditorTool.text, 'Text / Titles', Icons.title),
      _ToolItem(EditorTool.captions, 'Captions', Icons.closed_caption),
      _ToolItem(EditorTool.layout, 'Layout', Icons.aspect_ratio),
      _ToolItem(EditorTool.assets, 'Assets', Icons.auto_awesome_mosaic),
      _ToolItem(EditorTool.imageOverlay, 'Overlay / PiP', Icons.picture_in_picture_alt_outlined),
      _ToolItem(EditorTool.imageEditor, 'Cover / Thumb', Icons.photo_size_select_actual_outlined),
      _ToolItem(EditorTool.chromaKey, 'Chroma Key', Icons.blur_linear),
      _ToolItem(EditorTool.effects, 'Transitions', Icons.auto_awesome),
    ];

    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: tools.length + 1,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == tools.length) {
              return _buildAddTrackButton();
            }
            final item = tools[index];
            final isSelected = activeTool == item.tool;

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
          },
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
