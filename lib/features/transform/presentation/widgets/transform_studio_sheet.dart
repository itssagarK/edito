import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/video_transform_config.dart';

class TransformStudioSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final VoidCallback? onDone;
  final bool isDocked;

  const TransformStudioSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.onDone,
    this.isDocked = false,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Function(Clip) onSave,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransformStudioSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<TransformStudioSheet> createState() => _TransformStudioSheetState();
}

class _TransformStudioSheetState extends State<TransformStudioSheet> {
  late VideoTransformConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.transform;
  }

  void _update(VideoTransformConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onSave(widget.clip.copyWith(transform: newConfig));
  }

  void _rotate90() {
    final nextRotation = (_config.rotationDegrees + 90) % 360;
    _update(_config.copyWith(rotationDegrees: nextRotation));
  }

  void _toggleMirror() {
    _update(_config.copyWith(isFlippedHorizontal: !_config.isFlippedHorizontal));
  }

  void _toggleFlip() {
    _update(_config.copyWith(isFlippedVertical: !_config.isFlippedVertical));
  }

  void _reset() {
    _update(const VideoTransformConfig());
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (if not docked)
          if (!widget.isDocked) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.crop_rotate, color: AppColors.primaryLight, size: 22),
                    const SizedBox(width: 8),
                    Text('Transform & Basic Edit', style: AppTypography.titleMedium),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                  ),
                  onPressed: widget.onDone ?? () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: AppColors.border),
          ],

          // Quick Action Buttons Grid (Rotate, Mirror, Flip, Reset)
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.rotate_90_degrees_cw_outlined,
                  label: 'Rotate 90°',
                  badge: '${_config.rotationDegrees}°',
                  isActive: _config.rotationDegrees != 0,
                  onTap: _rotate90,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.flip,
                  label: 'Mirror',
                  badge: _config.isFlippedHorizontal ? 'ON' : 'OFF',
                  isActive: _config.isFlippedHorizontal,
                  onTap: _toggleMirror,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.swap_vert,
                  label: 'Flip V',
                  badge: _config.isFlippedVertical ? 'ON' : 'OFF',
                  isActive: _config.isFlippedVertical,
                  onTap: _toggleFlip,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.restart_alt,
                  label: 'Reset',
                  badge: null,
                  isActive: false,
                  onTap: _reset,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Scale & Zoom Slider
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.zoom_in, color: AppColors.accent, size: 18),
                        const SizedBox(width: 6),
                        Text('Scale & Zoom', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(
                      '${(_config.scale * 100).toInt()}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accent,
                    thumbColor: AppColors.accent,
                    overlayColor: AppColors.accent.withOpacity(0.2),
                    inactiveTrackColor: AppColors.border,
                  ),
                  child: Slider(
                    value: _config.scale.clamp(0.5, 3.0),
                    min: 0.5,
                    max: 3.0,
                    divisions: 50,
                    onChanged: (val) {
                      _update(_config.copyWith(scale: val));
                    },
                  ),
                ),
                const SizedBox(height: 4),
                // Quick Presets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildScaleChip('Fit (100%)', 1.0),
                    _buildScaleChip('Fill (115%)', 1.15),
                    _buildScaleChip('Zoom (130%)', 1.30),
                    _buildScaleChip('Dramatic (160%)', 1.60),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isDocked) {
      return content;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: content,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String? badge,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withOpacity(0.15) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.accent : AppColors.border,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.accent : AppColors.textPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (badge != null) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScaleChip(String label, double scaleVal) {
    final isSelected = (_config.scale - scaleVal).abs() < 0.02;
    return InkWell(
      onTap: () => _update(_config.copyWith(scale: scaleVal)),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? AppColors.accent : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
