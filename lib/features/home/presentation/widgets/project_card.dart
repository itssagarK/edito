import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../models/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onRename;
  final VoidCallback? onDuplicate;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onDelete,
    this.onRename,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    final ratioLabel = project.width > project.height
        ? '16:9'
        : (project.width < project.height ? '9:16' : '1:1');

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail preview container with aspect ratio badge
              Stack(
                children: [
                  Container(
                    width: 104,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.surfaceElevated,
                          AppColors.surfaceHighlight.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.movie_creation_outlined,
                        color: AppColors.primaryLight.withOpacity(0.85),
                        size: 26,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ratioLabel,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Project details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 13, color: AppColors.primaryLight),
                        const SizedBox(width: 4),
                        Text(
                          TimecodeFormatter.formatMilliseconds(project.durationMs),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.videocam_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          '${project.tracks.fold(0, (sum, t) => sum + t.clips.length)} clips',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Edited ${dateFormat.format(project.updatedAt)}',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              // Actions menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                color: AppColors.surfaceElevated,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (value) {
                  switch (value) {
                    case 'open':
                      onTap();
                      break;
                    case 'rename':
                      onRename?.call();
                      break;
                    case 'duplicate':
                      onDuplicate?.call();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'open',
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_outlined, size: 16, color: AppColors.primaryLight),
                        SizedBox(width: 8),
                        Text('Open Project', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.drive_file_rename_outline, size: 16, color: AppColors.textPrimary),
                        SizedBox(width: 8),
                        Text('Rename', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_all_outlined, size: 16, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text('Duplicate', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(fontSize: 13, color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
