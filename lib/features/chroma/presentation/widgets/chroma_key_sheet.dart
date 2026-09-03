import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../models/chroma_key_config.dart';

class ChromaKeySheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;

  const ChromaKeySheet({
    super.key,
    required this.clip,
    required this.onSave,
  });

  static Future<void> show(BuildContext context, {required Clip clip, required Function(Clip) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChromaKeySheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<ChromaKeySheet> createState() => _ChromaKeySheetState();
}

class _ChromaKeySheetState extends State<ChromaKeySheet> {
  late ChromaKeyConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.chromaKey;
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(chromaKey: _config);
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                        const Icon(Icons.blur_linear, color: AppColors.accent, size: 22),
                        const SizedBox(width: 8),
                        Text('Chroma Key & Green Screen', style: AppTypography.titleLarge),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.accent, size: 22),
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
                // Master Toggle Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _config.isEnabled ? AppColors.accent.withOpacity(0.5) : AppColors.border,
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Chroma Key Removal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: const Text('Isolates subject by making green or blue backgrounds transparent', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    value: _config.isEnabled,
                    activeColor: AppColors.accent,
                    onChanged: (val) {
                      setState(() => _config = _config.copyWith(isEnabled: val));
                      _applyChange();
                    },
                  ),
                ),
                const SizedBox(height: 16),

                if (_config.isEnabled) ...[
                  // Color Selection Presets
                  const Text('Key Color Selection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildColorButton(const Color(0xFF00FF00), 'Green Screen'),
                      const SizedBox(width: 10),
                      _buildColorButton(const Color(0xFF0055FF), 'Blue Screen'),
                      const SizedBox(width: 10),
                      _buildColorButton(const Color(0xFF00FFFF), 'Cyan Screen'),
                      const SizedBox(width: 10),
                      _buildColorButton(const Color(0xFFFF0055), 'Magenta'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sliders
                  _buildSlider(
                    title: 'Similarity Threshold',
                    subtitle: 'Expands color sensitivity range',
                    value: _config.similarity,
                    min: 0.05,
                    max: 0.50,
                    displayValue: '${(_config.similarity * 100).round()}%',
                    onChanged: (v) {
                      setState(() => _config = _config.copyWith(similarity: v));
                      _applyChange();
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildSlider(
                    title: 'Edge Smoothness & Feather',
                    subtitle: 'Blends borders to eliminate harsh green fringes',
                    value: _config.smoothness,
                    min: 0.01,
                    max: 0.35,
                    displayValue: '${(_config.smoothness * 100).round()}%',
                    onChanged: (v) {
                      setState(() => _config = _config.copyWith(smoothness: v));
                      _applyChange();
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildSlider(
                    title: 'Spill Suppression',
                    subtitle: 'Neutralizes green reflection bounce on subject',
                    value: _config.spill,
                    min: 0.0,
                    max: 0.40,
                    displayValue: '${(_config.spill * 100).round()}%',
                    onChanged: (v) {
                      setState(() => _config = _config.copyWith(spill: v));
                      _applyChange();
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color, String label) {
    final isSelected = _config.keyColorValue == color.value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _config = _config.copyWith(keyColorValue: color.value));
          _applyChange();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(isSelected ? 0.35 : 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(displayValue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent)),
            ],
          ),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
