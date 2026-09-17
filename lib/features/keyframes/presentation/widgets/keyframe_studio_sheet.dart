import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../../overlays/models/keyframe.dart';
import '../../services/keyframe_evaluator_service.dart';

class KeyframeStudioSheet extends StatefulWidget {
  final Clip clip;
  final int currentPlayheadMs;
  final Function(Clip updatedClip) onSave;
  final VoidCallback? onDone;
  final ValueChanged<int>? onSeek;

  const KeyframeStudioSheet({
    super.key,
    required this.clip,
    this.currentPlayheadMs = 0,
    required this.onSave,
    this.onDone,
    this.onSeek,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    int currentPlayheadMs = 0,
    required Function(Clip) onSave,
    VoidCallback? onDone,
    ValueChanged<int>? onSeek,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => KeyframeStudioSheet(
        clip: clip,
        currentPlayheadMs: currentPlayheadMs,
        onSave: onSave,
        onDone: onDone,
        onSeek: onSeek,
      ),
    );
  }

  @override
  State<KeyframeStudioSheet> createState() => _KeyframeStudioSheetState();
}

class _KeyframeStudioSheetState extends State<KeyframeStudioSheet> {
  late List<Keyframe> _keyframes;
  late int _currentOffsetMs;

  @override
  void initState() {
    super.initState();
    _keyframes = List<Keyframe>.from(widget.clip.keyframes);
    _currentOffsetMs = (widget.currentPlayheadMs - widget.clip.startTimeMs).clamp(0, widget.clip.durationMs);
  }

  void _saveKeyframes(List<Keyframe> newKeyframes) {
    setState(() => _keyframes = newKeyframes);
    final updated = widget.clip.copyWith(keyframes: _keyframes);
    widget.onSave(updated);
  }

  Keyframe? get _keyframeAtCurrentOffset {
    for (final k in _keyframes) {
      if ((k.timeOffsetMs - _currentOffsetMs).abs() <= 60) {
        return k;
      }
    }
    return null;
  }

  void _toggleKeyframeAtCurrentOffset() {
    final existing = _keyframeAtCurrentOffset;
    if (existing != null) {
      // Remove keyframe
      final updated = List<Keyframe>.from(_keyframes)
        ..removeWhere((k) => (k.timeOffsetMs - _currentOffsetMs).abs() <= 60);
      _saveKeyframes(updated);
    } else {
      // Add keyframe with currently interpolated or default values
      final currentValues = KeyframeEvaluatorService.evaluateTransformAt(_keyframes, _currentOffsetMs);
      final newK = Keyframe(
        timeOffsetMs: _currentOffsetMs,
        positionX: currentValues.positionX,
        positionY: currentValues.positionY,
        scale: currentValues.scale,
        rotation: currentValues.rotation,
        opacity: currentValues.opacity,
        easing: KeyframeEasing.easeInOut,
      );
      final updated = List<Keyframe>.from(_keyframes)..add(newK);
      updated.sort((a, b) => a.timeOffsetMs.compareTo(b.timeOffsetMs));
      _saveKeyframes(updated);
    }
  }

  void _updateActiveKeyframe({
    double? positionX,
    double? positionY,
    double? scale,
    double? rotation,
    double? opacity,
    KeyframeEasing? easing,
  }) {
    final active = _keyframeAtCurrentOffset;
    if (active == null) {
      // Automatically create a keyframe first
      _toggleKeyframeAtCurrentOffset();
      return;
    }

    final updatedKey = active.copyWith(
      positionX: positionX,
      positionY: positionY,
      scale: scale,
      rotation: rotation,
      opacity: opacity,
      easing: easing,
    );

    final updated = List<Keyframe>.from(_keyframes)
      ..removeWhere((k) => k.timeOffsetMs == active.timeOffsetMs)
      ..add(updatedKey);
    updated.sort((a, b) => a.timeOffsetMs.compareTo(b.timeOffsetMs));
    _saveKeyframes(updated);
  }

  void _jumpToPreviousKeyframe() {
    if (_keyframes.isEmpty) return;
    final sorted = List<Keyframe>.from(_keyframes)..sort((a, b) => a.timeOffsetMs.compareTo(b.timeOffsetMs));
    final prev = sorted.lastWhere(
      (k) => k.timeOffsetMs < (_currentOffsetMs - 50),
      orElse: () => sorted.first,
    );
    setState(() => _currentOffsetMs = prev.timeOffsetMs);
    widget.onSeek?.call(widget.clip.startTimeMs + _currentOffsetMs);
  }

  void _jumpToNextKeyframe() {
    if (_keyframes.isEmpty) return;
    final sorted = List<Keyframe>.from(_keyframes)..sort((a, b) => a.timeOffsetMs.compareTo(b.timeOffsetMs));
    final next = sorted.firstWhere(
      (k) => k.timeOffsetMs > (_currentOffsetMs + 50),
      orElse: () => sorted.last,
    );
    setState(() => _currentOffsetMs = next.timeOffsetMs);
    widget.onSeek?.call(widget.clip.startTimeMs + _currentOffsetMs);
  }

  void _applyPreset(KeyframePreset preset) {
    final generated = KeyframeEvaluatorService.generatePresetKeyframes(preset, widget.clip.durationMs);
    _saveKeyframes(generated);
  }

  void _clearAll() {
    _saveKeyframes([]);
  }

  @override
  Widget build(BuildContext context) {
    final activeKey = _keyframeAtCurrentOffset;
    final currentValues = KeyframeEvaluatorService.evaluateTransformAt(_keyframes, _currentOffsetMs);

    return Container(
      height: 520,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          // Header Bar
          _buildHeader(),

          // Timeline Keyframe Scrub & Diamond Navigator
          _buildKeyframeNavigator(),

          // Transform & Easing Controls
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Scale Slider
                _buildSlider(
                  label: 'Scale / Zoom',
                  value: activeKey?.scale ?? currentValues.scale,
                  min: 0.2,
                  max: 3.0,
                  displayValue: '${((activeKey?.scale ?? currentValues.scale) * 100).round()}%',
                  onChanged: (v) => _updateActiveKeyframe(scale: v),
                ),

                // Rotation Slider
                _buildSlider(
                  label: 'Rotation',
                  value: activeKey?.rotation ?? currentValues.rotation,
                  min: -180.0,
                  max: 180.0,
                  displayValue: '${(activeKey?.rotation ?? currentValues.rotation).round()}°',
                  onChanged: (v) => _updateActiveKeyframe(rotation: v),
                ),

                // Position X
                _buildSlider(
                  label: 'Position X',
                  value: activeKey?.positionX ?? currentValues.positionX,
                  min: -0.5,
                  max: 1.5,
                  displayValue: '${(((activeKey?.positionX ?? currentValues.positionX) - 0.5) * 200).round()}%',
                  onChanged: (v) => _updateActiveKeyframe(positionX: v),
                ),

                // Position Y
                _buildSlider(
                  label: 'Position Y',
                  value: activeKey?.positionY ?? currentValues.positionY,
                  min: -0.5,
                  max: 1.5,
                  displayValue: '${(((activeKey?.positionY ?? currentValues.positionY) - 0.5) * 200).round()}%',
                  onChanged: (v) => _updateActiveKeyframe(positionY: v),
                ),

                // Opacity
                _buildSlider(
                  label: 'Opacity',
                  value: activeKey?.opacity ?? currentValues.opacity,
                  min: 0.0,
                  max: 1.0,
                  displayValue: '${((activeKey?.opacity ?? currentValues.opacity) * 100).round()}%',
                  onChanged: (v) => _updateActiveKeyframe(opacity: v),
                ),

                const SizedBox(height: 6),

                // Easing Curve Selector (when sitting on a keyframe)
                Text('Motion Easing Curve', style: AppTypography.captionBold),
                const SizedBox(height: 6),
                _buildEasingChips(activeKey?.easing ?? KeyframeEasing.easeInOut),

                const SizedBox(height: 12),

                // Animation Presets
                Text('Animation Presets', style: AppTypography.captionBold),
                const SizedBox(height: 6),
                _buildPresetsCarousel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.animation, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Universal Keyframes', style: AppTypography.bodyBold),
                  Text(
                    '${_keyframes.length} KEYFRAME${_keyframes.length == 1 ? "" : "S"} ON CLIP',
                    style: AppTypography.micro.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Clear all
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
                tooltip: 'Clear All Keyframes',
                style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
                onPressed: _keyframes.isNotEmpty ? _clearAll : null,
              ),
              // Done
              IconButton(
                icon: const Icon(Icons.check_circle, color: AppColors.accent, size: 22),
                tooltip: 'Done',
                style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
                onPressed: () {
                  widget.onDone?.call();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyframeNavigator() {
    final bool hasKey = _keyframeAtCurrentOffset != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous keyframe
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 20),
                color: _keyframes.isNotEmpty ? Colors.white : AppColors.textTertiary,
                tooltip: 'Previous Keyframe',
                style: IconButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: _keyframes.isNotEmpty ? _jumpToPreviousKeyframe : null,
              ),

              // Add / Remove Keyframe Diamond Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasKey ? Colors.redAccent.withValues(alpha: 0.2) : AppColors.accent,
                  foregroundColor: hasKey ? Colors.redAccent : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: hasKey ? Colors.redAccent : AppColors.accent),
                  ),
                ),
                onPressed: _toggleKeyframeAtCurrentOffset,
                icon: Icon(hasKey ? Icons.remove_circle_outline : Icons.add_circle, size: 16),
                label: Text(
                  hasKey ? 'Remove Keyframe' : 'Add Keyframe (◆)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),

              // Next keyframe
              IconButton(
                icon: const Icon(Icons.skip_next, size: 20),
                color: _keyframes.isNotEmpty ? Colors.white : AppColors.textTertiary,
                tooltip: 'Next Keyframe',
                style: IconButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: _keyframes.isNotEmpty ? _jumpToNextKeyframe : null,
              ),
            ],
          ),

          // Scrub Slider inside Clip
          Row(
            children: [
              Text(
                '${(_currentOffsetMs / 1000.0).toStringAsFixed(2)}s',
                style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accent,
                    thumbColor: AppColors.accent,
                    inactiveTrackColor: AppColors.surface,
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: _currentOffsetMs.toDouble().clamp(0.0, widget.clip.durationMs.toDouble()),
                    min: 0.0,
                    max: widget.clip.durationMs.toDouble(),
                    onChanged: (v) {
                      setState(() => _currentOffsetMs = v.round());
                      widget.onSeek?.call(widget.clip.startTimeMs + _currentOffsetMs);
                    },
                  ),
                ),
              ),
              Text(
                '${(widget.clip.durationMs / 1000.0).toStringAsFixed(2)}s',
                style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.caption),
            Text(displayValue, style: AppTypography.captionBold.copyWith(color: AppColors.accent)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            thumbColor: AppColors.accent,
            inactiveTrackColor: AppColors.surface,
            trackHeight: 2.5,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildEasingChips(KeyframeEasing activeEasing) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: KeyframeEasing.values.map((easing) {
          final isSelected = activeEasing == easing;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(easing.label),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surface,
              onSelected: (selected) {
                if (selected) {
                  _updateActiveKeyframe(easing: easing);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPresetsCarousel() {
    final presets = [
      {'preset': KeyframePreset.slowZoomIn, 'title': 'Ken Burns Zoom In', 'icon': Icons.zoom_in},
      {'preset': KeyframePreset.slowZoomOut, 'title': 'Slow Zoom Out', 'icon': Icons.zoom_out},
      {'preset': KeyframePreset.slideInFromLeft, 'title': 'Slide In Left', 'icon': Icons.arrow_forward},
      {'preset': KeyframePreset.spinAndPop, 'title': 'Spin & Bounce Pop', 'icon': Icons.rotate_right},
      {'preset': KeyframePreset.cinematicFade, 'title': 'Cinematic Fade In/Out', 'icon': Icons.gradient},
      {'preset': KeyframePreset.dutchAngleRoll, 'title': 'Dutch Angle Roll', 'icon': Icons.screen_rotation},
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final item = presets[i];
          final preset = item['preset'] as KeyframePreset;
          return ActionChip(
            avatar: Icon(item['icon'] as IconData, size: 14, color: AppColors.accent),
            label: Text(item['title'] as String, style: const TextStyle(fontSize: 11)),
            backgroundColor: AppColors.surface,
            onPressed: () => _applyPreset(preset),
          );
        },
      ),
    );
  }
}
