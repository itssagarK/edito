import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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
    final file = File(outputPath);
    final exists = file.existsSync();
    final actualSizeMb = exists ? (file.lengthSync() / (1024 * 1024)) : fileSizeMb;
    final displaySize = double.parse(actualSizeMb.toStringAsFixed(2));

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
              'Your video has been rendered and saved to your device gallery.',
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
                      Text('~$displaySize MB', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent)),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status', style: AppTypography.labelSmall),
                      Text(
                        exists ? 'Saved to Gallery' : 'Rendered',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: exists ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
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
                    onPressed: () async {
                      try {
                        if (File(outputPath).existsSync()) {
                          await Share.shareXFiles(
                            [XFile(outputPath)],
                            text: 'Check out my edited video created with Edito!',
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Video saved to $outputPath')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sharing error: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share Video'),
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
