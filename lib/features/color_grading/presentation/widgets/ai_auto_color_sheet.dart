import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../../../models/project.dart';
import '../../models/color_grading_config.dart';
import '../../services/ai_color_enhancer_service.dart';
import 'color_scopes_widget.dart';

/// 100% Offline, On-Device AI Auto-Color & Tone Enhancement Sheet.
///
/// Features:
/// - 5 Algorithmic Computer Vision Looks (Smart Auto, Vivid Pop, Cinema Golden, Clean Crisp, Low-Light Boost)
/// - Continuous intensity blending (0% to 150%)
/// - Real-time RGB Scopes monitor
/// - Press & hold "Before / After" comparison
/// - 1-tap "Apply to All Clips"
class AiAutoColorSheet extends StatefulWidget {
  final Clip clip;
  final Project? project;
  final Function(Clip updatedClip, {bool applyToAll}) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const AiAutoColorSheet({
    super.key,
    required this.clip,
    this.project,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    Project? project,
    required Function(Clip updatedClip, {bool applyToAll}) onSave,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.2),
      backgroundColor: Colors.transparent,
      builder: (context) => AiAutoColorSheet(
        clip: clip,
        project: project,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<AiAutoColorSheet> createState() => _AiAutoColorSheetState();
}

class _AiAutoColorSheetState extends State<AiAutoColorSheet> {
  late ColorGradingConfig _originalConfig;
  late ColorGradingConfig _currentConfig;
  AiColorMode _selectedMode = AiColorMode.smartAuto;
  double _intensity = 1.0;
  bool _isHoldingBefore = false;
  bool _applyToAll = false;

  @override
  void initState() {
    super.initState();
    _originalConfig = widget.clip.colorGrading;
    _computeAndApply(mode: _selectedMode, intensity: _intensity);
  }

  void _computeAndApply({required AiColorMode mode, required double intensity}) {
    final enhanced = AiColorEnhancerService.computeEnhancement(
      baseConfig: _originalConfig,
      mode: mode,
      intensity: intensity,
    );

    setState(() {
      _selectedMode = mode;
      _intensity = intensity;
      _currentConfig = enhanced;
    });

    _emitChange(enhanced);
  }

  void _emitChange(ColorGradingConfig config) {
    final updated = widget.clip.copyWith(colorGrading: config);
    widget.onSave(updated, applyToAll: _applyToAll);
  }

  void _resetToOriginal() {
    setState(() {
      _intensity = 1.0;
      _currentConfig = _originalConfig;
    });
    _emitChange(_originalConfig);
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.65;
    final activeDisplayConfig = _isHoldingBefore ? _originalConfig : _currentConfig;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text('AI Auto-Color & Tone', style: AppTypography.titleLarge),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF20BF6B).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF20BF6B), width: 0.8),
                            ),
                            child: const Text(
                              'OFFLINE CV',
                              style: TextStyle(
                                color: Color(0xFF20BF6B),
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _resetToOriginal,
                            child: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: AppColors.accent, size: 22),
                            onPressed: () {
                              _emitChange(_currentConfig);
                              widget.onDone?.call();
                              Navigator.pop(context);
                            },
                            tooltip: 'Done',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.accent.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Real-time RGB Scopes Monitor
          ColorScopesWidget(config: activeDisplayConfig),

          // Scrollable Preset & Slider Controls
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                // Hold to Compare Banner & Metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isHoldingBefore ? '👀 VIEWING ORIGINAL (BEFORE)' : '✨ AI BALANCED (AFTER)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isHoldingBefore ? AppColors.accentWarm : AppColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    GestureDetector(
                      onTapDown: (_) {
                        setState(() => _isHoldingBefore = true);
                        _emitChange(_originalConfig);
                      },
                      onTapUp: (_) {
                        setState(() => _isHoldingBefore = false);
                        _emitChange(_currentConfig);
                      },
                      onTapCancel: () {
                        setState(() => _isHoldingBefore = false);
                        _emitChange(_currentConfig);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.compare, size: 14, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Text(
                              'Hold to Compare',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // AI Preset Modes Horizontal Chips
                Text('AI ENHANCEMENT PROFILES', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AiColorMode.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final mode = AiColorMode.values[index];
                      final isSelected = _selectedMode == mode;
                      return ChoiceChip(
                        label: Text(
                          mode.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceElevated,
                        side: BorderSide(
                          color: isSelected ? AppColors.accent : AppColors.border,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            _computeAndApply(mode: mode, intensity: _intensity);
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Active Mode Description Card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedMode.description,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Intensity Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Enhancement Intensity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(
                      '${(_intensity * 100).round()}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: AppColors.surfaceElevated,
                    thumbColor: Colors.white,
                    overlayColor: AppColors.accent.withOpacity(0.2),
                    trackHeight: 3.5,
                  ),
                  child: Slider(
                    value: _intensity,
                    min: 0.0,
                    max: 1.5,
                    divisions: 30,
                    onChanged: (val) {
                      _computeAndApply(mode: _selectedMode, intensity: val);
                    },
                  ),
                ),

                // Applied Values Breakdown (Transparency & Honesty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildMetricBadge('Exposure', '+${(_currentConfig.exposure * 100).round()}%'),
                      _buildMetricBadge('Contrast', '${(_currentConfig.contrast * 100).round()}%'),
                      _buildMetricBadge('Vibrance', '${(_currentConfig.saturation * 100).round()}%'),
                      _buildMetricBadge('Shadows', '${_currentConfig.shadows >= 0 ? "+" : ""}${(_currentConfig.shadows * 100).round()}%'),
                      _buildMetricBadge('Highlights', '${_currentConfig.highlights >= 0 ? "+" : ""}${(_currentConfig.highlights * 100).round()}%'),
                      _buildMetricBadge('Temp', '${_currentConfig.temperature >= 0 ? "+" : ""}${_currentConfig.temperature.toStringAsFixed(1)}K'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar: Apply to All Clips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _applyToAll,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        setState(() => _applyToAll = val ?? false);
                        _emitChange(_currentConfig);
                      },
                    ),
                    const Text('Apply to all clips in project', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {
                    _emitChange(_currentConfig);
                    widget.onDone?.call();
                    if (!widget.isDocked) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Apply Look', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}
