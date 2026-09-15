import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/chroma_key_config.dart';
import '../../services/chroma_key_compiler_service.dart';

class ChromaKeySheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const ChromaKeySheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(BuildContext context, {required Clip clip, required Function(Clip) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.15),
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

  void _applyPreset({
    required int colorValue,
    required double similarity,
    required double smoothness,
    required double spill,
    required double edgeChoke,
    required bool isLumaKey,
  }) {
    setState(() {
      _config = _config.copyWith(
        isEnabled: true,
        keyColorValue: colorValue,
        similarity: similarity,
        smoothness: smoothness,
        spill: spill,
        edgeChoke: edgeChoke,
        isLumaKey: isLumaKey,
      );
    });
    _applyChange();
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.65;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked)
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
                          Text('Chroma Key Studio', style: AppTypography.titleLarge),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: AppColors.accent, size: 22),
                        onPressed: () {
                          if (widget.onDone != null) {
                            widget.onDone!();
                          } else {
                            Navigator.pop(context);
                          }
                        },
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _config.isEnabled ? AppColors.accent.withOpacity(0.5) : AppColors.border,
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Enable Chroma Key Removal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      _config.isEnabled
                          ? ChromaKeyCompilerService.getChromaBadge(_config)
                          : 'Isolates subjects by keying green, blue, or luma backgrounds',
                      style: TextStyle(
                        fontSize: 11,
                        color: _config.isEnabled ? AppColors.accent : AppColors.textSecondary,
                        fontWeight: _config.isEnabled ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    value: _config.isEnabled,
                    activeColor: AppColors.accent,
                    onChanged: (val) {
                      setState(() => _config = _config.copyWith(isEnabled: val));
                      _applyChange();
                    },
                  ),
                ),
                const SizedBox(height: 14),

                if (_config.isEnabled) ...[
                  // 1. One-Tap Studio Presets
                  const Text('Studio Keying Presets', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildPresetCard(
                          title: 'Green Screen',
                          color: const Color(0xFF00FF00),
                          onTap: () => _applyPreset(
                            colorValue: 0xFF00FF00,
                            similarity: 0.15,
                            smoothness: 0.08,
                            spill: 0.15,
                            edgeChoke: 0.0,
                            isLumaKey: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPresetCard(
                          title: 'Blue Screen',
                          color: const Color(0xFF0055FF),
                          onTap: () => _applyPreset(
                            colorValue: 0xFF0055FF,
                            similarity: 0.18,
                            smoothness: 0.10,
                            spill: 0.15,
                            edgeChoke: 0.0,
                            isLumaKey: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPresetCard(
                          title: 'Cyber Cyan',
                          color: const Color(0xFF00FFFF),
                          onTap: () => _applyPreset(
                            colorValue: 0xFF00FFFF,
                            similarity: 0.20,
                            smoothness: 0.12,
                            spill: 0.10,
                            edgeChoke: 0.0,
                            isLumaKey: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPresetCard(
                          title: 'Magenta Stage',
                          color: const Color(0xFFFF0055),
                          onTap: () => _applyPreset(
                            colorValue: 0xFFFF0055,
                            similarity: 0.20,
                            smoothness: 0.10,
                            spill: 0.10,
                            edgeChoke: 0.0,
                            isLumaKey: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPresetCard(
                          title: 'Luma Black (Fire)',
                          color: Colors.black,
                          onTap: () => _applyPreset(
                            colorValue: 0xFF000000,
                            similarity: 0.25,
                            smoothness: 0.15,
                            spill: 0.0,
                            edgeChoke: 0.0,
                            isLumaKey: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPresetCard(
                          title: 'Luma White (Snow)',
                          color: Colors.white,
                          onTap: () => _applyPreset(
                            colorValue: 0xFFFFFFFF,
                            similarity: 0.25,
                            smoothness: 0.15,
                            spill: 0.0,
                            edgeChoke: 0.0,
                            isLumaKey: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Color Selection Palette
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Key Color Selection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      Text(
                        '#${_config.keyColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                        style: AppTypography.timecode.copyWith(color: AppColors.accent, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildColorButton(const Color(0xFF00FF00), 'Green'),
                      const SizedBox(width: 8),
                      _buildColorButton(const Color(0xFF0055FF), 'Blue'),
                      const SizedBox(width: 8),
                      _buildColorButton(const Color(0xFF00FFFF), 'Cyan'),
                      const SizedBox(width: 8),
                      _buildColorButton(const Color(0xFFFF0055), 'Pink'),
                      const SizedBox(width: 8),
                      _buildColorButton(Colors.black, 'Black'),
                      const SizedBox(width: 8),
                      _buildColorButton(Colors.white, 'White'),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 3. Sliders
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
                  const SizedBox(height: 12),

                  _buildSlider(
                    title: 'Edge Choke / Inset',
                    subtitle: 'Erodes outer borders to clip halo reflections',
                    value: _config.edgeChoke,
                    min: 0.0,
                    max: 0.20,
                    displayValue: '${(_config.edgeChoke * 100).round()}%',
                    onChanged: (v) {
                      setState(() => _config = _config.copyWith(edgeChoke: v));
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

  Widget _buildPresetCard({
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSelected = _config.keyColorValue == color.value;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 105,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color, String label) {
    final isSelected = _config.keyColorValue == color.value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _config = _config.copyWith(
              keyColorValue: color.value,
              isLumaKey: color == Colors.black || color == Colors.white,
            );
          });
          _applyChange();
        },
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.white : AppColors.border,
              width: isSelected ? 2.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? Center(
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  ),
                )
              : null,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(displayValue, style: AppTypography.timecode.copyWith(color: AppColors.accent, fontSize: 12)),
            ],
          ),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.border,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
