import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/pixel_sort_config.dart';
import '../../services/pixel_sort_compiler_service.dart';

class PixelSortSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const PixelSortSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Function(Clip) onSave,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => PixelSortSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<PixelSortSheet> createState() => _PixelSortSheetState();
}

class _PixelSortSheetState extends State<PixelSortSheet> with SingleTickerProviderStateMixin {
  late PixelSortConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.pixelSort;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(PixelSortConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(pixelSort: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case PixelSortMode.verticalDown:
        return const Color(0xFF00E5FF); // Cyber rain cyan
      case PixelSortMode.horizontalTear:
        return const Color(0xFFFF1744); // Horizontal tear crimson
      case PixelSortMode.diagonalSlant:
        return const Color(0xFFE040FB); // Diagonal neon magenta
      case PixelSortMode.radiantBurst:
        return const Color(0xFFFFD600); // Radiant solar yellow
      case PixelSortMode.thresholdBand:
        return const Color(0xFF76FF03); // Threshold phosphor green
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonitorVisualizer(),
                  const SizedBox(height: 16),
                  _buildEnableToggle(),
                  if (_config.isEnabled) ...[
                    const SizedBox(height: 16),
                    _buildModeSelector(),
                    const SizedBox(height: 16),
                    _buildPresetChips(),
                    const SizedBox(height: 16),
                    _buildControls(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.isDocked) return content;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: content,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.format_line_spacing, color: _accentColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pixel Sort Glitch Studio',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Threshold luminance sorting & digital data streaks',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (widget.onDone != null)
            IconButton(
              onPressed: widget.onDone,
              icon: const Icon(Icons.check, color: AppColors.primary),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                padding: const EdgeInsets.all(8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonitorVisualizer() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF090D14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isActive ? _accentColor.withOpacity(0.6) : AppColors.border,
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return CustomPaint(
              painter: _PixelSortPainter(
                config: _config,
                accentColor: _accentColor,
                time: _animController.value,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _accentColor.withOpacity(0.5), width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _config.isActive ? _accentColor : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _config.isActive
                                ? 'SORTING THRESHOLD: ${(_config.threshold * 100).round()}% • ${(math.sin(_animController.value * 2 * math.pi) * 10).abs().toStringAsFixed(1)}'
                                : 'PIXEL ALIGNMENT NORMAL',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'STREAK: ${(_config.streakLength * 100).round()}% • ${_config.mode.displayName.toUpperCase()}',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnableToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _config.isEnabled ? Icons.blur_linear : Icons.blur_off,
                color: _config.isEnabled ? _accentColor : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pixel Sort Glitch',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _config.isEnabled ? 'Luminance data streaks flowing' : 'Original un-sorted frame pixels',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: _accentColor,
            onChanged: (val) {
              _applyConfig(_config.copyWith(isEnabled: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SORTING PATTERN',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PixelSortMode.values.map((mode) {
            final isSelected = _config.mode == mode;
            return ChoiceChip(
              label: Text(mode.displayName),
              selected: isSelected,
              selectedColor: _accentColor.withOpacity(0.2),
              backgroundColor: AppColors.surfaceVariant,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? _accentColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? _accentColor : Colors.transparent,
                width: 1.2,
              ),
              onSelected: (selected) {
                if (selected) {
                  _applyConfig(_config.copyWith(mode: mode));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPresetChips() {
    final presets = [
      {'name': 'Cyber Rain', 'cfg': PixelSortConfig.cyberRainDown},
      {'name': 'Data Tear', 'cfg': PixelSortConfig.horizontalDataTear},
      {'name': 'Neon Warp', 'cfg': PixelSortConfig.neonStreakWarp},
      {'name': 'Radiant Burst', 'cfg': PixelSortConfig.radiantBurstSort},
      {'name': 'Grain Streak', 'cfg': PixelSortConfig.subtleGrainStreak},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURATED PRESETS',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final cfg = p['cfg'] as PixelSortConfig;
              final isMatch = _config.mode == cfg.mode &&
                  (_config.streakLength - cfg.streakLength).abs() < 0.05;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(p['name'] as String),
                  backgroundColor: isMatch ? _accentColor.withOpacity(0.25) : AppColors.surfaceVariant,
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: isMatch ? _accentColor : AppColors.textPrimary,
                    fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isMatch ? _accentColor : AppColors.border,
                    width: 1.0,
                  ),
                  onPressed: () {
                    _applyConfig(cfg.copyWith(isEnabled: true));
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderTile(
          title: 'Luminance Threshold',
          valueText: '${(_config.threshold * 100).round()}%',
          value: _config.threshold,
          min: 0.1,
          max: 0.95,
          onChanged: (v) => _applyConfig(_config.copyWith(threshold: v)),
        ),
        _buildSliderTile(
          title: 'Streak Length',
          valueText: '${(_config.streakLength * 100).round()}%',
          value: _config.streakLength,
          min: 0.1,
          max: 1.0,
          onChanged: (v) => _applyConfig(_config.copyWith(streakLength: v)),
        ),
        if (_config.mode == PixelSortMode.diagonalSlant)
          _buildSliderTile(
            title: 'Sorting Angle',
            valueText: '${_config.angleDeg.round()}°',
            value: _config.angleDeg,
            min: 0.0,
            max: 360.0,
            onChanged: (v) => _applyConfig(_config.copyWith(angleDeg: v)),
          ),
        _buildSliderTile(
          title: 'Boundary Randomness',
          valueText: '${(_config.randomness * 100).round()}%',
          value: _config.randomness,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => _applyConfig(_config.copyWith(randomness: v)),
        ),
        _buildSliderTile(
          title: 'Glitch Intensity',
          valueText: '${(_config.intensity * 100).round()}%',
          value: _config.intensity,
          min: 0.1,
          max: 1.0,
          onChanged: (v) => _applyConfig(_config.copyWith(intensity: v)),
        ),
      ],
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
            Text(
              valueText,
              style: AppTypography.bodySmall.copyWith(
                color: _accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _accentColor,
            inactiveTrackColor: AppColors.surfaceVariant,
            thumbColor: _accentColor,
            overlayColor: _accentColor.withOpacity(0.15),
            trackHeight: 3.5,
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
}

/// Custom Skia painter displaying animated luminance pixel sorting streaks.
class _PixelSortPainter extends CustomPainter {
  final PixelSortConfig config;
  final Color accentColor;
  final double time;

  _PixelSortPainter({
    required this.config,
    required this.accentColor,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Background pixel grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    for (double x = 0; x < width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 0; y < height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    if (!config.isActive) {
      // Draw static center pixels
      final dotPaint = Paint()..color = Colors.white24;
      for (double x = 36; x < width; x += 36) {
        for (double y = 36; y < height; y += 36) {
          canvas.drawRect(Rect.fromLTWH(x, y, 4, 4), dotPaint);
        }
      }
      return;
    }

    final rng = math.Random(42);
    final streakLen = config.streakLength * 55.0;

    // Draw sorted pixel streak trails
    final count = 28;
    for (int i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * width;
      final baseY = rng.nextDouble() * height;
      final lumWeight = rng.nextDouble();

      // Only sort if above threshold
      if (lumWeight < (1.0 - config.threshold)) continue;

      final pTime = (time + (i * 0.035)) % 1.0;
      final currentLen = streakLen * (0.6 + (0.4 * math.sin(pTime * math.pi)));

      final streakPaint = Paint()
        ..color = Color.lerp(accentColor, Colors.white, lumWeight)!.withOpacity(config.intensity * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (rng.nextDouble() * 2.0);

      switch (config.mode) {
        case PixelSortMode.verticalDown:
        case PixelSortMode.thresholdBand:
          final yOffset = (baseY + (pTime * height)) % height;
          canvas.drawLine(Offset(baseX, yOffset), Offset(baseX, yOffset + currentLen), streakPaint);
          break;

        case PixelSortMode.horizontalTear:
          final xOffset = (baseX + (pTime * width)) % width;
          canvas.drawLine(Offset(xOffset, baseY), Offset(xOffset + currentLen, baseY), streakPaint);
          break;

        case PixelSortMode.diagonalSlant:
          final xOffset = (baseX + (pTime * width * 0.7)) % width;
          final yOffset = (baseY + (pTime * height * 0.7)) % height;
          canvas.drawLine(Offset(xOffset, yOffset), Offset(xOffset + (currentLen * 0.7), yOffset + (currentLen * 0.7)), streakPaint);
          break;

        case PixelSortMode.radiantBurst:
          final cx = width * 0.5;
          final cy = height * 0.5;
          final angle = (i / count) * 2 * math.pi;
          final dist = 20.0 + (pTime * 50.0);
          final p1 = Offset(cx + math.cos(angle) * dist, cy + math.sin(angle) * dist);
          final p2 = Offset(cx + math.cos(angle) * (dist + currentLen), cy + math.sin(angle) * (dist + currentLen));
          canvas.drawLine(p1, p2, streakPaint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelSortPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.time != time;
  }
}
