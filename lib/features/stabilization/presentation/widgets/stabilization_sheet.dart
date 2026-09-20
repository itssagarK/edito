import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/stabilization_config.dart';
import '../../services/stabilization_compiler_service.dart';

/// CapCut Pro AI Video Stabilization & Gyro Flow Studio Sheet
class StabilizationSheet extends StatefulWidget {
  final StabilizationConfig initialConfig;
  final ValueChanged<StabilizationConfig> onApply;
  final VoidCallback? onClose;
  final bool isDocked;

  const StabilizationSheet({
    super.key,
    required this.initialConfig,
    required this.onApply,
    this.onClose,
    this.isDocked = false,
  });

  @override
  State<StabilizationSheet> createState() => _StabilizationSheetState();
}

class _StabilizationSheetState extends State<StabilizationSheet> {
  late StabilizationConfig _config;
  bool _isPeekingRaw = false;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  void _updateConfig(StabilizationConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onApply(_config);
  }

  void _selectLevel(StabilizationLevel level) {
    final updated = StabilizationConfig.fromLevel(level).copyWith(
      algorithm: _config.algorithm,
      edgeMode: _config.edgeMode,
      rollingShutterCorrection: _config.rollingShutterCorrection,
    );
    _updateConfig(updated);
  }

  @override
  Widget build(BuildContext context) {
    final activeConfig = _isPeekingRaw ? const StabilizationConfig() : _config;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(20)),
        border: widget.isDocked
            ? const Border(top: BorderSide(color: AppColors.border, width: 1))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            _buildHeaderBar(),

            // Interactive Gyro Leveler HUD
            _buildGyroLevelerHUD(activeConfig),

            // Scrollable Settings Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Level Selector Cards
                  _buildSectionTitle('STABILIZATION LEVEL', Icons.auto_graph),
                  const SizedBox(height: 8),
                  _buildLevelSelector(),

                  if (_config.isEnabled && _config.level != StabilizationLevel.none) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('ENGINE ALGORITHM', Icons.memory),
                    const SizedBox(height: 8),
                    _buildAlgorithmChips(),

                    const SizedBox(height: 16),
                    _buildSectionTitle('EDGE PADDING & BOUNDARIES', Icons.crop_free),
                    const SizedBox(height: 8),
                    _buildEdgeModeChips(),

                    const SizedBox(height: 16),
                    _buildSectionTitle('DAMPENING CONTROLS', Icons.tune),
                    const SizedBox(height: 8),
                    _buildSlidersSection(),

                    const SizedBox(height: 12),
                    _buildRollingShutterSwitch(),
                  ],

                  const SizedBox(height: 16),
                  // Raw Comparison Button
                  _buildRawComparisonButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.screen_lock_rotation, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Video Stabilization',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _config.isEnabled
                      ? '${_config.level.label} • ${(_config.cropMargin * 100).round()}% Crop'
                      : 'Disabled',
                  style: AppTypography.labelSmall.copyWith(
                    color: _config.isEnabled ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_config.isEnabled)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 20),
              tooltip: 'Reset Stabilization',
              onPressed: () => _updateConfig(const StabilizationConfig()),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
              tooltip: 'Close',
              onPressed: widget.onClose,
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGyroLevelerHUD(StabilizationConfig config) {
    final isStabilized = config.isEnabled && config.level != StabilizationLevel.none;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isStabilized ? AppColors.accent.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Gyro Level Indicator Disc
          SizedBox(
            width: 48,
            height: 48,
            child: CustomPaint(
              painter: _GyroDiscPainter(
                isStabilized: isStabilized,
                rollDampening: config.rollDampening,
                smoothing: config.smoothingStrength,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'GYRO HORIZON LOCK',
                      style: AppTypography.labelSmall.copyWith(
                        color: isStabilized ? AppColors.accent : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isStabilized)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isStabilized
                      ? 'Camera shake dampened via ${config.algorithm.label}. Missing edge margins clamped with ${config.edgeMode.label}.'
                      : 'Camera shake dampening is inactive. Select a stabilization level below.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSelector() {
    return Row(
      children: StabilizationLevel.values.map((level) {
        final isSelected = _config.level == level;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => _selectLevel(level),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getLevelIcon(level),
                      size: 20,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      level.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getLevelIcon(StabilizationLevel level) {
    switch (level) {
      case StabilizationLevel.none:
        return Icons.videocam_off_outlined;
      case StabilizationLevel.minimalCrop:
        return Icons.stay_current_portrait;
      case StabilizationLevel.recommended:
        return Icons.center_focus_strong;
      case StabilizationLevel.mostStable:
        return Icons.videocam;
      case StabilizationLevel.custom:
        return Icons.tune;
    }
  }

  Widget _buildAlgorithmChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: StabilizationAlgorithm.values.map((algo) {
        final isSelected = _config.algorithm == algo;
        return ChoiceChip(
          label: Text(algo.label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              _updateConfig(_config.copyWith(algorithm: algo));
            }
          },
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surfaceElevated,
          labelStyle: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEdgeModeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: EdgePaddingMode.values.map((mode) {
        final isSelected = _config.edgeMode == mode;
        return ChoiceChip(
          label: Text(mode.label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              _updateConfig(_config.copyWith(edgeMode: mode));
            }
          },
          selectedColor: AppColors.accent.withOpacity(0.85),
          backgroundColor: AppColors.surfaceElevated,
          labelStyle: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSlidersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSliderRow(
            label: 'Smoothing Factor',
            value: _config.smoothingStrength,
            min: 0.0,
            max: 1.0,
            formattedValue: '${(_config.smoothingStrength * 100).round()}%',
            onChanged: (val) {
              _updateConfig(_config.copyWith(
                smoothingStrength: val,
                level: StabilizationLevel.custom,
              ));
            },
          ),
          const Divider(color: AppColors.border, height: 16),
          _buildSliderRow(
            label: 'Zoom Crop Margin',
            value: _config.cropMargin,
            min: 0.0,
            max: 0.25,
            formattedValue: '${(_config.cropMargin * 100).round()}%',
            onChanged: (val) {
              _updateConfig(_config.copyWith(
                cropMargin: val,
                level: StabilizationLevel.custom,
              ));
            },
          ),
          const Divider(color: AppColors.border, height: 16),
          _buildSliderRow(
            label: 'Pitch & Yaw Dampening',
            value: _config.pitchYawDampening,
            min: 0.0,
            max: 1.0,
            formattedValue: '${(_config.pitchYawDampening * 100).round()}%',
            onChanged: (val) {
              _updateConfig(_config.copyWith(
                pitchYawDampening: val,
                level: StabilizationLevel.custom,
              ));
            },
          ),
          const Divider(color: AppColors.border, height: 16),
          _buildSliderRow(
            label: 'Roll Horizon Dampening',
            value: _config.rollDampening,
            min: 0.0,
            max: 1.0,
            formattedValue: '${(_config.rollDampening * 100).round()}%',
            onChanged: (val) {
              _updateConfig(_config.copyWith(
                rollDampening: val,
                level: StabilizationLevel.custom,
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String formattedValue,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surfaceHighlight,
              thumbColor: AppColors.accent,
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            formattedValue,
            textAlign: TextAlign.right,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRollingShutterSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rolling Shutter Jello Correction',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Compensates for CMOS diagonal vibration shearing',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Switch(
            value: _config.rollingShutterCorrection,
            activeColor: AppColors.accent,
            onChanged: (val) {
              _updateConfig(_config.copyWith(rollingShutterCorrection: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRawComparisonButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPeekingRaw = true),
      onTapUp: (_) => setState(() => _isPeekingRaw = false),
      onTapCancel: () => setState(() => _isPeekingRaw = false),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _isPeekingRaw
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isPeekingRaw ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isPeekingRaw ? Icons.visibility : Icons.visibility_outlined,
              size: 18,
              color: _isPeekingRaw ? AppColors.primaryLight : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              _isPeekingRaw ? 'Showing Raw Shaky Video' : 'Hold to Compare Raw Video',
              style: AppTypography.labelSmall.copyWith(
                color: _isPeekingRaw ? AppColors.primaryLight : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter rendering a gyro horizon artificial horizon disc
class _GyroDiscPainter extends CustomPainter {
  final bool isStabilized;
  final double rollDampening;
  final double smoothing;

  _GyroDiscPainter({
    required this.isStabilized,
    required this.rollDampening,
    required this.smoothing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = const Color(0xFF1E1E28)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Border circle
    final borderPaint = Paint()
      ..color = isStabilized ? AppColors.accent.withOpacity(0.5) : const Color(0x33FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    // Artificial horizon line
    final horizonPaint = Paint()
      ..color = isStabilized ? AppColors.accent : const Color(0x88FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final tilt = isStabilized ? 0.0 : 0.15;
    final p1 = Offset(
      center.dx - (radius * 0.75 * math.cos(tilt)),
      center.dy - (radius * 0.75 * math.sin(tilt)),
    );
    final p2 = Offset(
      center.dx + (radius * 0.75 * math.cos(tilt)),
      center.dy + (radius * 0.75 * math.sin(tilt)),
    );
    canvas.drawLine(p1, p2, horizonPaint);

    // Center crosshair / bullseye
    final bullseyePaint = Paint()
      ..color = isStabilized ? AppColors.accent : Colors.white70
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, bullseyePaint);
  }

  @override
  bool shouldRepaint(covariant _GyroDiscPainter oldDelegate) {
    return oldDelegate.isStabilized != isStabilized ||
        oldDelegate.rollDampening != rollDampening ||
        oldDelegate.smoothing != smoothing;
  }
}
