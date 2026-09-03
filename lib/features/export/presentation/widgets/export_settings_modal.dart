import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../models/project.dart';
import '../../models/export_preset.dart';
import '../../models/export_status.dart';
import '../../providers/export_provider.dart';
import 'export_progress_dialog.dart';
import 'export_success_dialog.dart';

class ExportSettingsModal extends ConsumerWidget {
  final Project project;

  const ExportSettingsModal({super.key, required this.project});

  static Future<void> show(BuildContext context, {required Project project}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportSettingsModal(project: project),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportProvider);
    final config = exportState.configuration;
    final estimatedSizeMb = config.estimateFileSizeMb(project.durationMs);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.file_upload_outlined, color: AppColors.primaryLight, size: 22),
                        const SizedBox(width: 8),
                        Text('Export Project', style: AppTypography.titleLarge),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Project Summary Badge
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.movie, color: AppColors.primaryLight, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(project.title, style: AppTypography.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(
                              'Duration: ${TimecodeFormatter.formatMilliseconds(project.durationMs)}  •  Est. Size: ~${estimatedSizeMb} MB',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 1. Resolution Selection
                _buildSectionHeader('Resolution'),
                Wrap(
                  spacing: 8,
                  children: ExportResolution.values.map((res) {
                    final isSelected = config.resolution == res;
                    return ChoiceChip(
                      label: Text(res.label),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) ref.read(exportProvider.notifier).setResolution(res);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // 2. Framerate Selection
                _buildSectionHeader('Framerate'),
                Wrap(
                  spacing: 8,
                  children: ExportFramerate.values.map((fps) {
                    final isSelected = config.framerate == fps;
                    return ChoiceChip(
                      label: Text(fps.label),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) ref.read(exportProvider.notifier).setFramerate(fps);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // 3. Codec Selection
                _buildSectionHeader('Video Codec'),
                Wrap(
                  spacing: 8,
                  children: ExportCodec.values.map((codec) {
                    final isSelected = config.codec == codec;
                    return ChoiceChip(
                      label: Text(codec.label),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) ref.read(exportProvider.notifier).setCodec(codec);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // 4. Quality Preset Selection
                _buildSectionHeader('Encoding Quality (CRF)'),
                Wrap(
                  spacing: 8,
                  children: ExportQuality.values.map((q) {
                    final isSelected = config.quality == q;
                    return ChoiceChip(
                      label: Text(q.label),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) ref.read(exportProvider.notifier).setQuality(q);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Start Render Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context); // Close settings sheet
                  ExportProgressDialog.show(context);

                  final outputPath = await ref.read(exportProvider.notifier).runExport();

                  if (context.mounted && outputPath != null) {
                    final progress = ref.read(exportProvider).progress;
                    if (progress.status == ExportStatus.completed) {
                      Navigator.pop(context); // Close progress dialog
                      ExportSuccessDialog.show(
                        context,
                        outputPath: outputPath,
                        fileSizeMb: estimatedSizeMb,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.movie_creation, size: 18),
                label: Text(
                  'Start Export (~$estimatedSizeMb MB)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTypography.titleMedium),
    );
  }
}
