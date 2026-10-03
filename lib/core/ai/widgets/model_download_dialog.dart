import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../ai_model_manager.dart';
import '../models/ai_model_descriptor.dart';
import '../on_device_inference_runner.dart';

class ModelDownloadDialog extends StatefulWidget {
  final AiModelDescriptor model;

  const ModelDownloadDialog({
    super.key,
    required this.model,
  });

  /// Shows the download dialog and resolves to true if the model is ready for offline use
  static Future<bool> show(BuildContext context, AiModelDescriptor model) async {
    final isInstalled = await AiModelManager.isModelInstalled(model);
    if (isInstalled) return true;

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ModelDownloadDialog(model: model),
    );

    return result ?? false;
  }

  @override
  State<ModelDownloadDialog> createState() => _ModelDownloadDialogState();
}

class _ModelDownloadDialogState extends State<ModelDownloadDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = 'Model download required for offline processing';
  String _speedText = '';
  String? _errorMessage;
  CancellationToken? _cancelToken;
  StreamSubscription<AiModelDownloadProgress>? _downloadSub;
  int _freeSpaceBytes = 0;

  @override
  void initState() {
    super.initState();
    _checkStorage();
  }

  Future<void> _checkStorage() async {
    final free = await AiModelManager.getAvailableStorageBytes();
    if (mounted) {
      setState(() {
        _freeSpaceBytes = free;
      });
    }
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _progress = 0.0;
      _statusMessage = 'Connecting to download server...';
      _cancelToken = CancellationToken();
    });

    _downloadSub = AiModelManager.downloadModel(
      widget.model,
      cancelToken: _cancelToken,
    ).listen(
      (p) {
        if (!mounted) return;
        setState(() {
          _progress = p.fraction;
          _statusMessage = p.statusMessage;
          _speedText = p.formattedSpeed;
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isDownloading = false;
          _errorMessage = err.toString();
          _statusMessage = 'Download failed';
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _isDownloading = false;
          _progress = 1.0;
        });
        Navigator.of(context).pop(true);
      },
      cancelOnError: true,
    );
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    _downloadSub?.cancel();
    setState(() {
      _isDownloading = false;
      _statusMessage = 'Download cancelled';
    });
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final freeSpaceMb = (_freeSpaceBytes / (1024 * 1024)).toStringAsFixed(0);
    final hasEnoughSpace = _freeSpaceBytes >= (widget.model.sizeBytes * 2);

    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Icon & Category
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.download_for_offline_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.model.name,
                        style: AppTypography.titleMedium.copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.model.license,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.model.category.label,
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'This AI model runs 100% on-device and offline. Download the model weights once to enable speech recognition with zero cloud dependency.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Storage Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download Size',
                        style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.model.formattedSize,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Available Space',
                        style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$freeSpaceMb MB free',
                        style: AppTypography.bodyMedium.copyWith(
                          color: hasEnoughSpace ? AppColors.accent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Progress or Error state
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: AppColors.surfaceBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_speedText.isNotEmpty)
                    Text(
                      '${(_progress * 100).toInt()}% • $_speedText',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ] else if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTypography.caption.copyWith(color: Colors.redAccent),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isDownloading ? _cancelDownload : () => Navigator.of(context).pop(false),
                  child: Text(
                    _isDownloading ? 'Cancel' : 'Not Now',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 10),
                if (!_isDownloading)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: hasEnoughSpace ? _startDownload : null,
                    child: Text('Download (${widget.model.formattedSize})'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
