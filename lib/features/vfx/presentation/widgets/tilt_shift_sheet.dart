import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/tilt_shift_config.dart';
import '../../services/tilt_shift_compiler_service.dart';

class TiltShiftSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const TiltShiftSheet({
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
      builder: (context) => TiltShiftSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<TiltShiftSheet> createState() => _TiltShiftSheetState();
}

class _TiltShiftSheetState extends State<TiltShiftSheet> with SingleTickerProviderStateMixin {
  late TiltShiftConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.tiltShift;
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

  void _applyConfig(TiltShiftConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(tiltShift: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case TiltShiftMode.linearBar:
        return const Color(0xFF00E5FF); // Cyan linear band
      case TiltShiftMode.radialCircle:
        return const Color(0xFFFF4081); // Pink radial spotlight
      case TiltShiftMode.miniatureModel:
        return const Color(0xFFFFD600); // Toy model vivid yellow
      case TiltShiftMode.cinematicMacro:
        return const Color(0xFF69F0AE); // Macro soft mint
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.isDocked) _buildHeader(),
              const SizedBox(height: 8),

              // Enable switch
              _buildEnableSwitch(),
              const SizedBox(height: 12),

              // Live interactive Skia Canvas focal viewfinder
              _buildFocusMonitor(),
              const SizedBox(height: 16),

              // Presets row
              _buildPresetsSection(),
              const SizedBox(height: 16),

              // Mode selector
              _buildModeSelector(),
              const SizedBox(height: 16),

              // Parameter sliders
              _buildSliders(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    return content;
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.camera_enhance_rounded, color: _accentColor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tilt-Shift Miniature Studio',
                style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                'Miniature toy diorama depth-of-field & selective focus planes',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (widget.onDone != null)
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.textPrimary,
            ),
            icon: const Icon(Icons.check, size: 20),
            onPressed: widget.onDone,
          ),
      ],
    );
  }

  Widget _buildEnableSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isEnabled ? _accentColor.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _config.isEnabled ? Icons.blur_linear_rounded : Icons.blur_off_rounded,
                color: _config.isEnabled ? _accentColor : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                _config.isEnabled ? 'Tilt-Shift Active' : 'Tilt-Shift Bypassed',
                style: AppTypography.bodyMedium.copyWith(
                  color: _config.isEnabled ? _accentColor : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: _accentColor,
            onChanged: (val) => _applyConfig(_config.copyWith(isEnabled: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusMonitor() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF10141D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accentColor.withOpacity(0.4), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 140),
                  painter: _TiltShiftPainter(
                    config: _config,
                    accentColor: _accentColor,
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
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
                    const SizedBox(width: 5),
                    Text(
                      'BAND: ${(_config.focusBandwidth * 100).round()}% | BLUR: ${_config.blurRadius.round()}px',
                      style: AppTypography.caption.copyWith(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 10,
              child: Text(
                _config.mode.displayName,
                style: AppTypography.caption.copyWith(
                  color: _accentColor.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsSection() {
    final presets = [
      {'name': 'Toy Town', 'config': TiltShiftConfig.toyTownMiniature, 'icon': Icons.toys_outlined},
      {'name': 'Diorama', 'config': TiltShiftConfig.dioramaHorizontal, 'icon': Icons.view_day_outlined},
      {'name': 'Radial', 'config': TiltShiftConfig.portraitRadialFocus, 'icon': Icons.center_focus_strong},
      {'name': 'Macro DoF', 'config': TiltShiftConfig.macroShallowDof, 'icon': Icons.lens},
      {'name': 'Architectural', 'config': TiltShiftConfig.architecturalTilt, 'icon': Icons.architecture},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DIORAMA PRESETS',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final presetConfig = p['config'] as TiltShiftConfig;
              final isSelected = _config.mode == presetConfig.mode &&
                  (_config.focusBandwidth - presetConfig.focusBandwidth).abs() < 0.05;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: Icon(
                    p['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.black : _accentColor,
                  ),
                  label: Text(p['name'] as String),
                  selected: isSelected,
                  selectedColor: _accentColor,
                  checkmarkColor: Colors.black,
                  backgroundColor: AppColors.surfaceVariant.withOpacity(0.5),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      _applyConfig(presetConfig.copyWith(isEnabled: true));
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FOCAL GEOMETRY',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TiltShiftMode.values.map((mode) {
            final isSelected = _config.mode == mode;
            return ChoiceChip(
              label: Text(mode.displayName),
              selected: isSelected,
              selectedColor: _accentColor,
              backgroundColor: AppColors.surfaceVariant.withOpacity(0.5),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (selected) {
                if (selected) {
                  _applyConfig(_config.copyWith(mode: mode, isEnabled: true));
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          _config.mode.description,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Focus Position
        _buildSliderTile(
          title: 'Focal Center Position',
          valueText: '${(_config.focusPosition * 100).round()}%',
          value: _config.focusPosition,
          min: 0.1,
          max: 0.9,
          onChanged: (val) => _applyConfig(_config.copyWith(focusPosition: val)),
        ),

        // Focus Bandwidth
        _buildSliderTile(
          title: 'Sharp In-Focus Width',
          valueText: '${(_config.focusBandwidth * 100).round()}%',
          value: _config.focusBandwidth,
          min: 0.05,
          max: 0.80,
          onChanged: (val) => _applyConfig(_config.copyWith(focusBandwidth: val)),
        ),

        // Defocus Blur Radius
        _buildSliderTile(
          title: 'Defocus Blur Radius',
          valueText: '${_config.blurRadius.round()} px',
          value: _config.blurRadius,
          min: 1.0,
          max: 30.0,
          onChanged: (val) => _applyConfig(_config.copyWith(blurRadius: val)),
        ),

        // Feather Smoothness
        _buildSliderTile(
          title: 'Transition Feather',
          valueText: '${(_config.feather * 100).round()}%',
          value: _config.feather,
          min: 0.05,
          max: 0.50,
          onChanged: (val) => _applyConfig(_config.copyWith(feather: val)),
        ),

        // Saturation Boost (Diorama Pop)
        _buildSliderTile(
          title: 'Toy Model Saturation Pop',
          valueText: '${_config.saturationBoost.toStringAsFixed(2)}x',
          value: _config.saturationBoost,
          min: 1.0,
          max: 2.2,
          onChanged: (val) => _applyConfig(_config.copyWith(saturationBoost: val)),
        ),

        // Tilt Angle (for linear modes)
        if (_config.mode != TiltShiftMode.radialCircle)
          _buildSliderTile(
            title: 'Focal Plane Tilt Angle',
            valueText: '${_config.angleDeg.round()}°',
            value: _config.angleDeg,
            min: -45.0,
            max: 45.0,
            onChanged: (val) => _applyConfig(_config.copyWith(angleDeg: val)),
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

/// Custom Skia painter displaying linear focal plane strip guides and progressive blur areas.
class _TiltShiftPainter extends CustomPainter {
  final TiltShiftConfig config;
  final Color accentColor;

  _TiltShiftPainter({
    required this.config,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Viewport background grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    for (double x = 0; x < width; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 0; y < height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    if (!config.isActive) return;

    if (config.mode == TiltShiftMode.radialCircle) {
      // Radial spotlight ellipse
      final center = Offset(width * 0.5, height * config.focusPosition);
      final radiusX = (width * 0.4) * (config.focusBandwidth * 2.0);
      final radiusY = (height * 0.4) * (config.focusBandwidth * 2.0);

      // Defocus blur outside
      final blurPaint = Paint()
        ..color = Colors.black.withOpacity(0.55)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), blurPaint);

      // Clear sharp center ellipse
      final sharpPaint = Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.dstOut;
      canvas.drawOval(Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2), sharpPaint);

      // Focus contour ring
      final ringPaint = Paint()
        ..color = accentColor.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawOval(Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2), ringPaint);
    } else {
      // Linear focal strip
      final centerY = height * config.focusPosition;
      final halfBand = (height * config.focusBandwidth) / 2.0;
      final topY = (centerY - halfBand).clamp(0.0, height);
      final bottomY = (centerY + halfBand).clamp(0.0, height);

      // Top blur wash
      final topBlurPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.65),
            Colors.black.withOpacity(0.15),
          ],
        ).createShader(Rect.fromLTWH(0, 0, width, topY));
      canvas.drawRect(Rect.fromLTWH(0, 0, width, topY), topBlurPaint);

      // Bottom blur wash
      final bottomBlurPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.65),
            Colors.black.withOpacity(0.15),
          ],
        ).createShader(Rect.fromLTWH(0, bottomY, width, height - bottomY));
      canvas.drawRect(Rect.fromLTWH(0, bottomY, width, height - bottomY), bottomBlurPaint);

      // In-focus sharp band indicator lines
      final linePaint = Paint()
        ..color = accentColor.withOpacity(0.85)
        ..strokeWidth = 1.6;

      canvas.drawLine(Offset(0, topY), Offset(width, topY), linePaint);
      canvas.drawLine(Offset(0, bottomY), Offset(width, bottomY), linePaint);

      // Center focal axis dashed line
      final centerPaint = Paint()
        ..color = accentColor.withOpacity(0.4)
        ..strokeWidth = 1.0;
      for (double x = 0; x < width; x += 12) {
        canvas.drawLine(Offset(x, centerY), Offset(x + 6, centerY), centerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TiltShiftPainter oldDelegate) {
    return oldDelegate.config != config;
  }
}
