import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../services/gallery_saver_service.dart';

class ExportSuccessDialog extends StatefulWidget {
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
  State<ExportSuccessDialog> createState() => _ExportSuccessDialogState();
}

class _ExportSuccessDialogState extends State<ExportSuccessDialog> {
  bool _isSavingToGallery = false;
  String? _galleryStatusMessage;

  @override
  Widget build(BuildContext context) {
    final file = File(widget.outputPath);
    final exists = file.existsSync();
    final actualSizeMb = exists ? (file.lengthSync() / (1024 * 1024)) : widget.fileSizeMb;
    final displaySize = double.parse(actualSizeMb.toStringAsFixed(2));

    final isGalleryPath = widget.outputPath.contains('Movies') ||
        widget.outputPath.contains('DCIM') ||
        widget.outputPath.contains('Edito');

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
              'Your video has been rendered and saved to your device gallery (Movies/Edito).',
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
                      Text('Gallery Status', style: AppTypography.labelSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                        ),
                        child: Text(
                          isGalleryPath ? '✓ Saved to Gallery' : '✓ Rendered',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Gallery Location', style: AppTypography.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    widget.outputPath,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_galleryStatusMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _galleryStatusMessage!,
                      style: const TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSavingToGallery
                        ? null
                        : () async {
                            setState(() => _isSavingToGallery = true);
                            final res = await GallerySaverService.saveVideoToGallery(
                              widget.outputPath,
                              title: 'Edito_Export',
                              album: 'Edito',
                            );
                            if (mounted) {
                              setState(() {
                                _isSavingToGallery = false;
                                _galleryStatusMessage = res.isSuccess
                                    ? '✓ Verified in MediaStore Movies/Edito'
                                    : 'Saved at: ${res.savedPath}';
                              });
                            }
                          },
                    icon: _isSavingToGallery
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                          )
                        : const Icon(Icons.download, size: 16),
                    label: const Text('Save to Gallery', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        if (File(widget.outputPath).existsSync()) {
                          await Share.shareXFiles(
                            [XFile(widget.outputPath)],
                            text: 'Check out my edited video created with Edito!',
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Video saved to ${widget.outputPath}')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sharing error: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share Video', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done', style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
