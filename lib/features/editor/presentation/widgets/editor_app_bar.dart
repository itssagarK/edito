import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final String? resolutionBadge;
  final VoidCallback? onResolutionTap;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onBack;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onExport;

  const EditorAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.resolutionBadge,
    this.onResolutionTap,
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
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.2)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back Button
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              onPressed: onBack,
              tooltip: 'Back to projects',
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(36, 36),
              ),
            ),
            const SizedBox(width: 4),

            // Project Title & Subtitle Column
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Undo Action
            IconButton(
              icon: Icon(
                Icons.undo,
                size: 19,
                color: canUndo ? AppColors.textPrimary : AppColors.textMuted.withOpacity(0.4),
              ),
              onPressed: canUndo ? onUndo : null,
              tooltip: 'Undo',
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
              ),
            ),

            // Redo Action
            IconButton(
              icon: Icon(
                Icons.redo,
                size: 19,
                color: canRedo ? AppColors.textPrimary : AppColors.textMuted.withOpacity(0.4),
              ),
              onPressed: canRedo ? onRedo : null,
              tooltip: 'Redo',
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
              ),
            ),

            const SizedBox(width: 6),

            // Quick Resolution & FPS Preset Badge
            if (resolutionBadge != null && resolutionBadge!.isNotEmpty)
              Tooltip(
                message: 'Tap to configure resolution & export preset',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onResolutionTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          resolutionBadge!,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 14,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(width: 8),

            // Primary Export CTA Button with Electric Gradient
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF8854D0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.file_upload_outlined, size: 15),
                label: const Text(
                  'Export',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
