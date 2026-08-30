import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ExportSuccessDialog extends StatelessWidget {
  final String outputPath;
  final double fileSizeMb;

  const ExportSuccessDialog({
    super.key,
    required this.outputPath,
    required this.fileSizeMb,
  });

  static void show(BuildContext context, {required String outputPath, required double fileSizeMb}) {
    showDialog(
      context: context,
      builder: (context) => ExportSuccessDialog(outputPath: outputPath, fileSizeMb: fileSizeMb),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.black, size: 36),
            ),

            const SizedBox(height: 18),
            Text('Export Successful!', style: AppTypography.displayMedium.copyWith(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              'Your video has been rendered and saved.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Video Details Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('File Size', style: AppTypography.labelSmall),
                      Text('~$fileSizeMb MB', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Format', style: AppTypography.labelSmall),
                      Text('MP4 (H.264 / AAC)', style: AppTypography.timecode.copyWith(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Output Location', style: AppTypography.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    outputPath,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Done'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Video saved to gallery & ready to share!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
