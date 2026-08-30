import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../providers/export_provider.dart';

class ExportProgressDialog extends ConsumerWidget {
  const ExportProgressDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ExportProgressDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportProvider);
    final progress = exportState.progress;

    return WillPopScope(
      onWillPop: () async => false, // Prevent accidental back tap while rendering
      child: Dialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rendering Video', style: AppTypography.titleLarge),
                  Text('${progress.percentage}%', style: AppTypography.timecode.copyWith(color: AppColors.accent, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.progress,
                  minHeight: 10,
                  backgroundColor: AppColors.surface,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),

              const SizedBox(height: 16),

              // Status message
              Text(
                progress.statusMessage,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Metadata grid: Frames & Time
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Frames', style: AppTypography.labelSmall),
                        const SizedBox(height: 2),
                        Text('${progress.currentFrame} / ${progress.totalFrames}', style: AppTypography.timecode.copyWith(fontSize: 11)),
                      ],
                    ),
                    const VerticalDivider(color: AppColors.border, width: 20),
                    Column(
                      children: [
                        Text('Elapsed', style: AppTypography.labelSmall),
                        const SizedBox(height: 2),
                        Text(TimecodeFormatter.formatMilliseconds(progress.elapsedTimeMs), style: AppTypography.timecode.copyWith(fontSize: 11)),
                      ],
                    ),
                    const VerticalDivider(color: AppColors.border, width: 20),
                    Column(
                      children: [
                        Text('ETA', style: AppTypography.labelSmall),
                        const SizedBox(height: 2),
                        Text(
                          progress.etaRemainingMs > 0
                              ? TimecodeFormatter.formatMilliseconds(progress.etaRemainingMs)
                              : '--:--',
                          style: AppTypography.timecode.copyWith(fontSize: 11, color: AppColors.accent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(exportProvider.notifier).cancelExport();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accentWarm),
                    foregroundColor: AppColors.accentWarm,
                  ),
                  child: const Text('Cancel Export'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
