import 'package:flutter/material.dart' hide Clip;
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/image_overlay_config.dart';

class ImageOverlaySheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;

  const ImageOverlaySheet({
    super.key,
    required this.clip,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Function(Clip) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageOverlaySheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<ImageOverlaySheet> createState() => _ImageOverlaySheetState();
}

class _ImageOverlaySheetState extends State<ImageOverlaySheet> {
  late ImageOverlayConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.imageOverlay;
    if (!_config.isEnabled) {
      _config = _config.copyWith(isEnabled: true);
    }
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(imageOverlay: _config);
    widget.onSave(updated);
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _config = _config.copyWith(
            isEnabled: true,
            imagePath: picked.path,
            assetLabel: 'Custom Photo',
          );
        });
        _applyChange();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Header
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
                        const Icon(Icons.picture_in_picture_alt_outlined, color: AppColors.accent, size: 22),
                        const SizedBox(width: 8),
                        Text('Overlay & Picture-in-Picture', style: AppTypography.titleLarge),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Enable Toggle & Status Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _config.isEnabled ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _config.isPiP ? Icons.picture_in_picture : Icons.layers,
                      color: _config.isEnabled ? AppColors.accent : AppColors.textMuted,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _config.assetLabel.isNotEmpty ? _config.assetLabel : 'Image / PiP Layer',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          _config.isEnabled ? 'Active on video clip' : 'Disabled',
                          style: TextStyle(
                            color: _config.isEnabled ? AppColors.accent : AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _config.isEnabled,
                  activeColor: AppColors.accent,
                  onChanged: (val) {
                    setState(() => _config = _config.copyWith(isEnabled: val));
                    _applyChange();
                  },
                ),
              ],
            ),
          ),

          // Pick Photo Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size.fromHeight(42),
              ),
              icon: const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.primary),
              label: const Text('Pick Image from Device Gallery', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: _pickImage,
            ),
          ),

          // Controls
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // PiP Window Framing Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Picture-in-Picture Frame', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Add rounded border and drop shadow framing', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  value: _config.isPiP,
                  activeColor: AppColors.accent,
                  onChanged: (val) {
                    setState(() => _config = _config.copyWith(isPiP: val));
                    _applyChange();
                  },
                ),
                const Divider(color: AppColors.border, height: 20),

                // Scale Multiplier
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Scale Multiplier', style: TextStyle(fontSize: 12)),
                    Text('${_config.scale.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _config.scale,
                  min: 0.2,
                  max: 2.5,
                  activeColor: AppColors.accent,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(scale: v));
                    _applyChange();
                  },
                ),

                // Position X
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Horizontal Position (X)', style: TextStyle(fontSize: 12)),
                    Text('${(_config.positionX * 100).round()}%', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _config.positionX,
                  min: 0.0,
                  max: 1.0,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(positionX: v));
                    _applyChange();
                  },
                ),

                // Position Y
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Vertical Position (Y)', style: TextStyle(fontSize: 12)),
                    Text('${(_config.positionY * 100).round()}%', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _config.positionY,
                  min: 0.0,
                  max: 1.0,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(positionY: v));
                    _applyChange();
                  },
                ),

                // Opacity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Layer Opacity', style: TextStyle(fontSize: 12)),
                    Text('${(_config.opacity * 100).round()}%', style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _config.opacity,
                  min: 0.0,
                  max: 1.0,
                  activeColor: Colors.white70,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(opacity: v));
                    _applyChange();
                  },
                ),

                // Rotation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rotation Angle', style: TextStyle(fontSize: 12)),
                    Text('${_config.rotation.round()}°', style: const TextStyle(fontSize: 12, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _config.rotation,
                  min: 0.0,
                  max: 360.0,
                  activeColor: Colors.orangeAccent,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(rotation: v));
                    _applyChange();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
