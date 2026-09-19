import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/transition_type.dart';
import '../../services/transition_compiler_service.dart';
import 'transition_shader_painter.dart';

class TransitionSelectorSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final ValueChanged<TransitionConfig>? onApplyToAll;

  const TransitionSelectorSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.onApplyToAll,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Function(Clip) onSave,
    ValueChanged<TransitionConfig>? onApplyToAll,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransitionSelectorSheet(
        clip: clip,
        onSave: onSave,
        onApplyToAll: onApplyToAll,
      ),
    );
  }

  @override
  State<TransitionSelectorSheet> createState() => _TransitionSelectorSheetState();
}

class _TransitionSelectorSheetState extends State<TransitionSelectorSheet>
    with SingleTickerProviderStateMixin {
  late TransitionType _selectedType;
  late int _durationMs;
  late TransitionEasing _selectedEasing;
  late bool _playSfx;

  late AnimationController _animController;
  bool _isPlaying = true;
  TransitionCategory _activeCategory = TransitionCategory.all;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.clip.transitionIn.type;
    _durationMs = widget.clip.transitionIn.durationMs;
    _selectedEasing = widget.clip.transitionIn.easing;
    _playSfx = widget.clip.transitionIn.playSfx;

    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _durationMs),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updateAnimationDuration() {
    _animController.duration = Duration(milliseconds: _durationMs);
    if (_isPlaying && !_animController.isAnimating) {
      _animController.repeat();
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animController.repeat();
      } else {
        _animController.stop();
      }
    });
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(
      transitionIn: TransitionConfig(
        type: _selectedType,
        durationMs: _durationMs,
        easing: _selectedEasing,
        playSfx: _playSfx,
      ),
    );
    widget.onSave(updated);
  }

  List<TransitionType> get _filteredTransitions {
    if (_activeCategory == TransitionCategory.all) {
      return TransitionType.values;
    }
    return TransitionType.values.where((t) {
      if (t == TransitionType.none) return true;
      return t.category == _activeCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
                    const SizedBox(width: 8),
                    Text('Cinematic Transitions', style: AppTypography.titleLarge),
                  ],
                ),
                Row(
                  children: [
                    if (widget.onApplyToAll != null && _selectedType != TransitionType.none)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        icon: const Icon(Icons.copy_all, size: 16),
                        label: const Text('Apply All', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          widget.onApplyToAll!(
                            TransitionConfig(
                              type: _selectedType,
                              durationMs: _durationMs,
                              easing: _selectedEasing,
                              playSfx: _playSfx,
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Applied ${_selectedType.label} to all clip boundaries'),
                              backgroundColor: AppColors.surfaceElevated,
                              duration: const Duration(milliseconds: 900),
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.accent, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        padding: const EdgeInsets.all(8),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Live Interactive Viewport Preview Canvas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 140,
                width: double.infinity,
                color: Colors.black,
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(double.infinity, 140),
                          painter: TransitionShaderPainter(
                            progress: _animController.value,
                            type: _selectedType,
                            easing: _selectedEasing,
                            labelA: 'SCENE 1',
                            labelB: 'SCENE 2',
                          ),
                        );
                      },
                    ),

                    // Controls overlay
                    Positioned(
                      bottom: 8,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _animController,
                              builder: (context, child) {
                                return SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2.5,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                    activeTrackColor: AppColors.accent,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: AppColors.accent,
                                  ),
                                  child: Slider(
                                    value: _animController.value,
                                    onChanged: (v) {
                                      if (_isPlaying) {
                                        _animController.stop();
                                        setState(() => _isPlaying = false);
                                      }
                                      _animController.value = v;
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              _selectedType == TransitionType.none ? 'OFF' : '${(_durationMs / 1000.0).toStringAsFixed(1)}s',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active badge
                    Positioned(
                      top: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _selectedType.label,
                          style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category Chips Row
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: TransitionCategory.values.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = TransitionCategory.values[index];
                final isSelected = _activeCategory == cat;
                return ChoiceChip(
                  label: Text(cat.label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textSecondary)),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceElevated,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onSelected: (_) {
                    setState(() => _activeCategory = cat);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // Duration & Easing controls (if enabled)
          if (_selectedType != TransitionType.none)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              child: Row(
                children: [
                  // Duration Slider
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Duration', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text('${(_durationMs / 1000.0).toStringAsFixed(1)}s', style: AppTypography.timecode.copyWith(color: AppColors.accent, fontSize: 12)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.surfaceElevated,
                          ),
                          child: Slider(
                            value: _durationMs.toDouble(),
                            min: 100,
                            max: 3000,
                            divisions: 29,
                            onChanged: (val) {
                              setState(() => _durationMs = val.toInt());
                              _updateAnimationDuration();
                              _applyChange();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Easing Dropdown Pill
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Easing', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<TransitionEasing>(
                              value: _selectedEasing,
                              isDense: true,
                              isExpanded: true,
                              dropdownColor: AppColors.surfaceElevated,
                              items: TransitionEasing.values.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(e.label, style: const TextStyle(fontSize: 11)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedEasing = val);
                                  _applyChange();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Grid of Transitions
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemCount: _filteredTransitions.length,
              itemBuilder: (context, index) {
                final type = _filteredTransitions[index];
                final isSelected = _selectedType == type;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                      if (!_isPlaying) {
                        _isPlaying = true;
                        _animController.repeat();
                      }
                    });
                    _applyChange();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.border,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type.icon,
                          size: 26,
                          color: isSelected ? AppColors.accent : AppColors.textPrimary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          type.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? AppColors.accent : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
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
