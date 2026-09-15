import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../../color_grading/models/color_grading_config.dart';
import '../../models/speed_curve_preset.dart';
import '../../services/speed_ramping_service.dart';
import 'speed_curve_graph_widget.dart';

class SpeedRampingSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const SpeedRampingSheet({
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
    if (widget.clip.speedCurve.type != SpeedCurveType.constant) {
      _tabController.index = 1;
    }
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
    final effectiveSpeed = SpeedRampingService.calculateEffectiveAverageSpeed(_speedCurve, _constantSpeed);

    final newDuration = sourceSpan > 0 && effectiveSpeed > 0
        ? (sourceSpan / effectiveSpeed).round().clamp(100, 3600000)
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
                          Text('Speed & Curves Studio', style: AppTypography.titleLarge),
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
                Tab(text: 'Dynamic Curves & Graph'),
              ],
            ),
          ),

          // Toggles row: Pitch Correction & Smooth Slow-Mo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Preserve Pitch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Natural tone voice', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    value: _speedCurve.enablePitchCorrection,
                    activeColor: AppColors.accent,
                    onChanged: (enabled) {
                      setState(() => _speedCurve = _speedCurve.copyWith(enablePitchCorrection: enabled));
                      _applyChange();
                    },
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Smooth Slow-Mo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Optical flow blending', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    value: _speedCurve.isSmoothSlowMo,
                    activeColor: const Color(0xFF00E5FF),
                    onChanged: (enabled) {
                      setState(() => _speedCurve = _speedCurve.copyWith(isSmoothSlowMo: enabled));
                      _applyChange();
                    },
                  ),
                ),
              ],
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
            Text(
              '${_constantSpeed}x',
              style: AppTypography.timecode.copyWith(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
            final isSelected = _constantSpeed == s && _speedCurve.type == SpeedCurveType.constant;
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
    final curvePresets = SpeedCurveType.values.where((t) => t != SpeedCurveType.constant).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        children: [
          // Interactive Bezier Curve Canvas
          SizedBox(
            height: 170,
            child: SpeedCurveGraphWidget(
              config: _speedCurve,
              onPointsChanged: (newPoints) {
                setState(() {
                  _speedCurve = _speedCurve.copyWith(
                    type: SpeedCurveType.custom,
                    curvePoints: newPoints,
                  );
                });
                _applyChange();
              },
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal Carousel of Curve Presets
          SizedBox(
            height: 75,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: curvePresets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final presetType = curvePresets[index];
                final isSelected = _speedCurve.type == presetType;

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      _speedCurve = _speedCurve.copyWith(
                        type: presetType,
                        curvePoints: presetType.defaultCurvePoints,
                      );
                    });
                    _applyChange();
                  },
                  child: Container(
                    width: 110,
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
                        Icon(
                          presetType == SpeedCurveType.custom ? Icons.gesture : Icons.show_chart,
                          size: 18,
                          color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          presetType.label.split('(').first.trim(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
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
