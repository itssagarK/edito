import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onBack;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onExport;

  const EditorAppBar({
    super.key,
    required this.title,
    this.canUndo = false,
    this.canRedo = false,
    required this.onBack,
    required this.onUndo,
    required this.onRedo,
    required this.onExport,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: onBack,
              tooltip: 'Back to projects',
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: AppTypography.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.undo,
                size: 20,
                color: canUndo ? AppColors.textPrimary : AppColors.textMuted,
              ),
              onPressed: canUndo ? onUndo : null,
              tooltip: 'Undo',
            ),
            IconButton(
              icon: Icon(
                Icons.redo,
                size: 20,
                color: canRedo ? AppColors.textPrimary : AppColors.textMuted,
              ),
              onPressed: canRedo ? onRedo : null,
              tooltip: 'Redo',
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.file_upload_outlined, size: 16),
              label: const Text('Export', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
