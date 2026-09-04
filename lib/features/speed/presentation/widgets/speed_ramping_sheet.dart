import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/speed_curve_preset.dart';

class SpeedRampingSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;

  const SpeedRampingSheet({
    super.key,
    required this.clip,
    required this.onSave,
  });

  static Future<void> show(BuildContext context, {required Clip clip, required Function(Clip) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SpeedRampingSheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<SpeedRampingSheet> createState() => _SpeedRampingSheetState();
}

class _SpeedRampingSheetState extends State<SpeedRampingSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late double _constantSpeed;
  late SpeedCurveConfig _speedCurve;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _constantSpeed = widget.clip.speed;
    _speedCurve = widget.clip.speedCurve;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyChange() {
    final sourceSpan = (widget.clip.sourceOutMs - widget.clip.sourceInMs).abs();
    final newDuration = sourceSpan > 0 && _constantSpeed > 0
        ? (sourceSpan / _constantSpeed).round().clamp(100, 3600000)
        : widget.clip.durationMs;

    final updated = widget.clip.copyWith(
      speed: _constantSpeed,
      speedCurve: _speedCurve,
      durationMs: newDuration,
    );
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
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
                        const Icon(Icons.speed, color: AppColors.primaryLight, size: 22),
                        const SizedBox(width: 8),
                        Text('Speed & Curves', style: AppTypography.titleLarge),
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

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Standard Multiplier'),
                Tab(text: 'Dynamic Curves'),
              ],
            ),
          ),

          // Pitch Correction Switch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Preserve Audio Pitch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Keeps natural tone without chipmunk / robot artifacts', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              value: _speedCurve.enablePitchCorrection,
              activeColor: AppColors.accent,
              onChanged: (enabled) {
                setState(() => _speedCurve = _speedCurve.copyWith(enablePitchCorrection: enabled));
                _applyChange();
              },
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConstantSpeedTab(),
                _buildSpeedCurvesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConstantSpeedTab() {
    final speeds = [0.2, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 4.0, 8.0];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Playback Rate', style: AppTypography.titleMedium),
            Text('${_constantSpeed}x', style: AppTypography.timecode.copyWith(color: AppColors.accent, fontSize: 14)),
          ],
        ),
        Slider(
          value: _constantSpeed,
          min: 0.1,
          max: 8.0,
          divisions: 79,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.surfaceElevated,
          onChanged: (val) {
            setState(() {
              _constantSpeed = (val * 10).round() / 10.0;
              _speedCurve = _speedCurve.copyWith(type: SpeedCurveType.constant, constantSpeed: _constantSpeed);
            });
            _applyChange();
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: speeds.map((s) {
            final isSelected = _constantSpeed == s;
            return ChoiceChip(
              label: Text('${s}x'),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _constantSpeed = s;
                    _speedCurve = _speedCurve.copyWith(type: SpeedCurveType.constant, constantSpeed: s);
                  });
                  _applyChange();
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpeedCurvesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: SpeedCurveType.values.where((t) => t != SpeedCurveType.constant).map((curveType) {
        final isSelected = _speedCurve.type == curveType;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            onTap: () {
              setState(() {
                _speedCurve = _speedCurve.copyWith(
                  type: curveType,
                  curvePoints: curveType.defaultCurvePoints,
                );
              });
              _applyChange();
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.show_chart, color: isSelected ? Colors.white : AppColors.primaryLight, size: 20),
            ),
            title: Text(curveType.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.accent, size: 20) : null,
          ),
        );
      }).toList(),
    );
  }
}
