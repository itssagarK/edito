import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/relight_config.dart';
import '../../services/relight_compiler_service.dart';

/// CapCut Pro AI Video Relight & Virtual Studio Lighting Studio Sheet
class RelightSheet extends StatefulWidget {
  final RelightConfig initialConfig;
  final ValueChanged<RelightConfig> onApply;
  final VoidCallback? onClose;
  final bool isDocked;

  const RelightSheet({
    super.key,
    required this.initialConfig,
    required this.onApply,
    this.onClose,
    this.isDocked = false,
  });

  @override
  State<RelightSheet> createState() => _RelightSheetState();
}

class _RelightSheetState extends State<RelightSheet> {
  late RelightConfig _config;
  bool _isComparing = false; // Hold to compare raw unlit footage

  static const List<int> _colorPalette = [
    0xFFFFE8D6, // Soft Warm White
    0xFFFFF5EB, // Studio Daylight
    0xFFFFB347, // Golden Amber
    0xFFFF9F43, // Tungsten Warmth
    0xFF00CEC9, // Electric Cyan
    0xFFFF007F, // Neon Magenta
    0xFF55EFC4, // Mint Emerald
    0xFFA29BFE, // Electric Lavender
  ];

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  void _updateConfig(RelightConfig updated) {
    setState(() {
      _config = updated;
    });
    widget.onApply(updated);
  }

  void _reset() {
    const fresh = RelightConfig();
    _updateConfig(fresh);
  }

  @override
  Widget build(BuildContext context) {
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            _buildHeader(),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Interactive 2D Light Position Pad
                    _buildInteractiveLightPad(),
                    const SizedBox(height: 12),

                    // Preset Mode Selector
                    _buildModeSelector(),
                    const SizedBox(height: 12),

                    // Light Color Swatches
                    _buildColorSwatches(),
                    const SizedBox(height: 12),

                    // Sliders
                    _buildSlider(
                      label: 'Light Intensity',
                      value: _config.intensity,
                      min: 0.0,
                      max: 1.0,
                      percent: true,
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          intensity: val,
                        ));
                      },
                    ),
                    _buildSlider(
                      label: 'Light Radius & Spread',
                      value: _config.radius,
                      min: 0.1,
                      max: 2.0,
                      formatVal: '${(_config.radius * 100).toInt()}%',
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          radius: val,
                        ));
                      },
                    ),
                    _buildSlider(
                      label: 'Falloff Softness',
                      value: _config.softness,
                      min: 0.1,
                      max: 1.0,
                      percent: true,
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          softness: val,
                        ));
                      },
                    ),

                    const SizedBox(height: 12),

                    // Hold to Compare & Status Bar
                    _buildCompareBar(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD166).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lightbulb_circle,
              color: Color(0xFFFFD166),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI Video Relight',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD166), Color(0xFFFF9F43)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PRO',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _config.isEnabled && _config.mode != RelightMode.none
                      ? '${_config.mode.label} active • Drag pad to position'
                      : 'Disabled — Tap a lighting preset to illuminate',
                  style: AppTypography.labelSmall.copyWith(
                    color: _config.isEnabled && _config.mode != RelightMode.none
                        ? const Color(0xFFFFD166)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Reset button
          if (_config.isEnabled && _config.mode != RelightMode.none)
            TextButton(
              onPressed: _reset,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Reset',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
              ),
            ),

          // Close button
          IconButton(
            onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.check, color: AppColors.textPrimary, size: 20),
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveLightPad() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padWidth = constraints.maxWidth;
        final padHeight = 110.0;

        // Position of glowing orb
        final orbX = ((_config.lightX + 1.0) / 2.0 * padWidth).clamp(12.0, padWidth - 12.0);
        final orbY = ((_config.lightY + 1.0) / 2.0 * padHeight).clamp(12.0, padHeight - 12.0);

        final lightColor = Color(_config.colorValue);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '2D VIRTUAL LIGHT POSITION',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'X: ${(_config.lightX * 100).toInt()}% • Y: ${(_config.lightY * 100).toInt()}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFFFFD166),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onPanUpdate: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localOffset = details.localPosition;
                final normX = ((localOffset.dx / padWidth) * 2.0 - 1.0).clamp(-1.0, 1.0);
                final normY = ((localOffset.dy / padHeight) * 2.0 - 1.0).clamp(-1.0, 1.0);

                _updateConfig(_config.copyWith(
                  isEnabled: true,
                  mode: _config.mode == RelightMode.none ? RelightMode.facialSpotlight : _config.mode,
                  lightX: normX,
                  lightY: normY,
                ));
              },
              child: Container(
                width: padWidth,
                height: padHeight,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _config.isEnabled ? const Color(0xFFFFD166).withOpacity(0.5) : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Grid Crosshairs
                    Center(
                      child: Container(
                        width: 1,
                        height: padHeight,
                        color: Colors.white10,
                      ),
                    ),
                    Center(
                      child: Container(
                        width: padWidth,
                        height: 1,
                        color: Colors.white10,
                      ),
                    ),

                    // Light Beam Ray
                    if (_config.isEnabled)
                      CustomPaint(
                        size: Size(padWidth, padHeight),
                        painter: _PadBeamPainter(
                          orbCenter: Offset(orbX, orbY),
                          color: lightColor,
                          radius: _config.radius * 30.0,
                        ),
                      ),

                    // Glowing Light Orb
                    Positioned(
                      left: orbX - 14,
                      top: orbY - 14,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: lightColor,
                          boxShadow: [
                            BoxShadow(
                              color: lightColor.withOpacity(0.8),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.wb_sunny, size: 14, color: Colors.black87),
                        ),
                      ),
                    ),

                    // Hint overlay
                    Positioned(
                      bottom: 6,
                      right: 10,
                      child: Text(
                        'Drag to position light source',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT LIGHTING PRESET',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: RelightMode.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mode = RelightMode.values[index];
              final isSelected = _config.isEnabled && _config.mode == mode;

              return InkWell(
                onTap: () {
                  if (mode == RelightMode.none) {
                    _updateConfig(const RelightConfig());
                  } else {
                    _updateConfig(RelightConfig.fromMode(mode, intensity: _config.intensity));
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 108,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFD166).withOpacity(0.12)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFFD166) : AppColors.border,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getModeIcon(mode),
                        size: 20,
                        color: isSelected ? const Color(0xFFFFD166) : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mode.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? const Color(0xFFFFD166) : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      Text(
                        isSelected ? 'Active' : 'Pro Light',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          color: isSelected ? const Color(0xFFFFD166) : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSwatches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LIGHT COLOR TEMPERATURE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _colorPalette.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final colorVal = _colorPalette[index];
              final isSelected = _config.colorValue == colorVal;

              return InkWell(
                onTap: () {
                  _updateConfig(_config.copyWith(
                    isEnabled: true,
                    colorValue: colorVal,
                  ));
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(colorVal),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white24,
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(colorVal).withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(Icons.check, size: 16, color: Colors.black87),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompareBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.flare, color: Color(0xFFFFD166), size: 16),
              const SizedBox(width: 8),
              Text(
                'Hold button to compare with unlit raw video',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          GestureDetector(
            onTapDown: (_) {
              setState(() => _isComparing = true);
              widget.onApply(const RelightConfig());
            },
            onTapUp: (_) {
              setState(() => _isComparing = false);
              widget.onApply(_config);
            },
            onTapCancel: () {
              setState(() => _isComparing = false);
              widget.onApply(_config);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isComparing ? Colors.white24 : Colors.white10,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    _isComparing ? Icons.visibility_off : Icons.visibility,
                    size: 14,
                    color: _isComparing ? const Color(0xFFFFD166) : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isComparing ? 'Raw' : 'Compare',
                    style: AppTypography.labelSmall.copyWith(
                      color: _isComparing ? const Color(0xFFFFD166) : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
    required ValueChanged<double> onChanged,
    bool percent = false,
    String? formatVal,
  }) {
    final displayValue = formatVal ?? (percent ? '${(value * 100).toInt()}%' : value.toStringAsFixed(2));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                displayValue,
                style: AppTypography.labelSmall.copyWith(
                  color: const Color(0xFFFFD166),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFFD166),
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(RelightMode mode) {
    switch (mode) {
      case RelightMode.none:
        return Icons.power_settings_new;
      case RelightMode.facialSpotlight:
        return Icons.face;
      case RelightMode.studioSoftbox:
        return Icons.video_camera_front;
      case RelightMode.rimBacklight:
        return Icons.flare;
      case RelightMode.ambientRingLight:
        return Icons.circle_outlined;
      case RelightMode.goldenSunbeam:
        return Icons.wb_sunny;
      case RelightMode.cyberNeonDual:
        return Icons.tungsten;
      case RelightMode.vintageWarmTungsten:
        return Icons.lightbulb;
      case RelightMode.custom:
        return Icons.tune;
    }
  }
}

class _PadBeamPainter extends CustomPainter {
  final Offset orbCenter;
  final Color color;
  final double radius;

  const _PadBeamPainter({
    required this.orbCenter,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (orbCenter.dx / size.width) * 2.0 - 1.0,
          (orbCenter.dy / size.height) * 2.0 - 1.0,
        ),
        radius: 0.6,
        colors: [
          color.withOpacity(0.35),
          color.withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _PadBeamPainter oldDelegate) {
    return oldDelegate.orbCenter != orbCenter || oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
