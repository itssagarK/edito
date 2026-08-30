import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class TimelineContextBar extends StatelessWidget {
  final VoidCallback onSplit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onTrimHeadToPlayhead;
  final VoidCallback onTrimTailToPlayhead;
  final VoidCallback onDeselect;

  const TimelineContextBar({
    super.key,
    required this.onSplit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onTrimHeadToPlayhead,
    required this.onTrimTailToPlayhead,
    required this.onDeselect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Split at Playhead
          _buildActionButton(
            icon: Icons.content_cut,
            label: 'Split',
            onTap: onSplit,
            color: AppColors.primaryLight,
          ),
          const VerticalDivider(width: 12, indent: 8, endIndent: 8, color: AppColors.border),
          // Duplicate
          _buildActionButton(
            icon: Icons.copy,
            label: 'Duplicate',
            onTap: onDuplicate,
            color: AppColors.textPrimary,
          ),
          const VerticalDivider(width: 12, indent: 8, endIndent: 8, color: AppColors.border),
          // Trim Head
          _buildActionButton(
            icon: Icons.arrow_left_outlined,
            label: 'Trim Start',
            onTap: onTrimHeadToPlayhead,
            color: AppColors.textPrimary,
          ),
          const VerticalDivider(width: 12, indent: 8, endIndent: 8, color: AppColors.border),
          // Trim Tail
          _buildActionButton(
            icon: Icons.arrow_right_outlined,
            label: 'Trim End',
            onTap: onTrimTailToPlayhead,
            color: AppColors.textPrimary,
          ),
          const VerticalDivider(width: 12, indent: 8, endIndent: 8, color: AppColors.border),
          // Delete
          _buildActionButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            onTap: onDelete,
            color: AppColors.accentWarm,
          ),
          const SizedBox(width: 4),
          // Deselect
          InkWell(
            onTap: onDeselect,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
