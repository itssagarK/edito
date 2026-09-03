import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/transition_type.dart';

class TransitionSelectorSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;

  const TransitionSelectorSheet({
    super.key,
    required this.clip,
    required this.onSave,
  });

  static Future<void> show(BuildContext context, {required Clip clip, required Function(Clip) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransitionSelectorSheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<TransitionSelectorSheet> createState() => _TransitionSelectorSheetState();
}

class _TransitionSelectorSheetState extends State<TransitionSelectorSheet> {
  late TransitionType _selectedType;
  late int _durationMs;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.clip.transitionIn.type;
    _durationMs = widget.clip.transitionIn.durationMs;
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(
      transitionIn: TransitionConfig(
        type: _selectedType,
        durationMs: _durationMs,
      ),
    );
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
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
                        const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 22),
                        const SizedBox(width: 8),
                        Text('Video Transitions', style: AppTypography.titleLarge),
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

          // Duration Slider
          if (_selectedType != TransitionType.none)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transition Duration', style: TextStyle(fontSize: 13)),
                      Text('${(_durationMs / 1000.0).toStringAsFixed(1)}s', style: AppTypography.timecode.copyWith(color: AppColors.accent, fontSize: 12)),
                    ],
                  ),
                  Slider(
                    value: _durationMs.toDouble(),
                    min: 200,
                    max: 2000,
                    divisions: 18,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceElevated,
                    onChanged: (val) {
                      setState(() => _durationMs = val.toInt());
                      _applyChange();
                    },
                  ),
                ],
              ),
            ),

          // Grid of Transitions
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: TransitionType.values.length,
              itemBuilder: (context, index) {
                final type = TransitionType.values[index];
                final isSelected = _selectedType == type;

                return InkWell(
                  onTap: () {
                    setState(() => _selectedType = type);
                    _applyChange();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.25) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type.icon,
                          size: 28,
                          color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
