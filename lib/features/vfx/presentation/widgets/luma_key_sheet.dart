import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/luma_key_config.dart';
import '../../services/luma_key_compiler_service.dart';

class LumaKeySheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const LumaKeySheet({
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
      builder: (context) => LumaKeySheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<LumaKeySheet> createState() => _LumaKeySheetState();
}

class _LumaKeySheetState extends State<LumaKeySheet> with SingleTickerProviderStateMixin {
  late LumaKeyConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.lumaKey;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(LumaKeyConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(lumaKey: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case LumaKeyMode.darkSilhouette:
        return const Color(0xFF00E5FF); // Electric cyan
      case LumaKeyMode.brightSpecular:
        return const Color(0xFFFFD600); // Solar yellow
      case LumaKeyMode.midtonesOnly:
        return const Color(0xFF76FF03); // Phosphor green
      case LumaKeyMode.highContrastLuma:
        return const Color(0xFFFF4081); // Graphic neon pink
      case LumaKeyMode.softThresholdGradient:
        return const Color(0xFFE040FB); // Feathered purple
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
          if (!widget.isDocked) _buildDragHandle(),
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonitorCard(),
                  const SizedBox(height: 16),
                  _buildEnableToggle(),
                  const SizedBox(height: 16),
                  _buildModeSelector(),
                  const SizedBox(height: 16),
                  _buildPresetSelector(),
                  const SizedBox(height: 20),
                  _buildParameterSliders(),
                  const SizedBox(height: 16),
                  _buildInvertSwitch(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.isDocked) {
      return content;
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: content,
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accentColor.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.content_cut_rounded,
              color: _accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Luma Key & Silhouette Studio',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Luminance transparency masking & silhouette extraction',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          if (_config.isActive)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
              tooltip: 'Reset Luma Key',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _applyConfig(const LumaKeyConfig()),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: widget.onDone ?? () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitorCard() {
    return Container(
      height: 125,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0C101A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isActive ? _accentColor.withOpacity(0.4) : Colors.white10,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _LumaKeyPainter(
                      config: _config,
                      accentColor: _accentColor,
                      phase: _animController.value,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 12,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  _config.isActive
                      ? '${_config.mode.displayName.toUpperCase()} • ${(_config.threshold * 100).round()}% THRESH'
                      : 'LUMA KEY BYPASS',
                  style: AppTypography.caption.copyWith(
                    color: _config.isActive ? _accentColor : Colors.white38,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 8,
              child: Text(
                'FEATHER: ${(_config.tolerance * 100).round()}% • INVERT: ${_config.invert ? "YES" : "NO"}',
                style: AppTypography.caption.copyWith(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161822),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(
            _config.isEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
            color: _config.isEnabled ? _accentColor : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Luma Key Transparency',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _config.isEnabled
                      ? 'Luminance alpha channel keying active'
                      : 'Bypassed - solid opaque frame preserved',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
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
          'LUMINANCE KEYING MODE',
          style: AppTypography.caption.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LumaKeyMode.values.map((mode) {
            final isSelected = _config.mode == mode;
            return ChoiceChip(
              label: Text(mode.displayName),
              selected: isSelected,
              selectedColor: _accentColor.withOpacity(0.2),
              backgroundColor: const Color(0xFF1E2130),
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? _accentColor : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? _accentColor : Colors.white12,
              ),
              onSelected: (selected) {
                if (selected) {
                  _applyConfig(_config.copyWith(mode: mode, isEnabled: true));
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          _config.mode.description,
          style: AppTypography.caption.copyWith(
            color: Colors.white54,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetSelector() {
    final presets = [
      {'name': 'Black Backdrop', 'config': LumaKeyConfig.blackBackdropKey, 'color': const Color(0xFF00E5FF)},
      {'name': 'White Sky', 'config': LumaKeyConfig.whiteSkyCutout, 'color': const Color(0xFFFFD600)},
      {'name': 'Hard Stencil', 'config': LumaKeyConfig.highContrastStencil, 'color': const Color(0xFFFF4081)},
      {'name': 'Shadow Ghost', 'config': LumaKeyConfig.shadowGhost, 'color': const Color(0xFFE040FB)},
      {'name': 'Midtones Band', 'config': LumaKeyConfig.midtonesBand, 'color': const Color(0xFF76FF03)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURATED PRESETS',
          style: AppTypography.caption.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final presetConfig = p['config'] as LumaKeyConfig;
              final name = p['name'] as String;
              final color = p['color'] as Color;
              final isMatched = _config.mode == presetConfig.mode &&
                  (_config.threshold - presetConfig.threshold).abs() < 0.05 &&
                  _config.isEnabled;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  backgroundColor: isMatched ? color.withOpacity(0.2) : const Color(0xFF1E2130),
                  side: BorderSide(
                    color: isMatched ? color : Colors.white12,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: AppTypography.bodySmall.copyWith(
                          color: isMatched ? color : Colors.white70,
                          fontWeight: isMatched ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  onPressed: () => _applyConfig(presetConfig),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildParameterSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LUMINANCE THRESHOLD & EDGE CONTROLS',
          style: AppTypography.caption.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        // Threshold
        _buildSlider(
          label: 'Luma Cutoff Threshold',
          valueText: '${(_config.threshold * 100).round()}%',
          value: _config.threshold,
          min: 0.01,
          max: 0.99,
          onChanged: (val) {
            _applyConfig(_config.copyWith(threshold: val, isEnabled: true));
          },
        ),

        // Tolerance / Feathering
        _buildSlider(
          label: 'Edge Softness & Tolerance',
          valueText: '${(_config.tolerance * 100).round()}%',
          value: _config.tolerance,
          min: 0.01,
          max: 0.50,
          onChanged: (val) {
            _applyConfig(_config.copyWith(tolerance: val, isEnabled: true));
          },
        ),

        // Opacity
        _buildSlider(
          label: 'Composite Layer Opacity',
          valueText: '${(_config.opacity * 100).round()}%',
          value: _config.opacity,
          min: 0.10,
          max: 1.0,
          onChanged: (val) {
            _applyConfig(_config.copyWith(opacity: val, isEnabled: true));
          },
        ),
      ],
    );
  }

  Widget _buildInvertSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161822),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.invert_colors,
                color: _config.invert ? _accentColor : Colors.white38,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Invert Keying Transparency',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Switch.adaptive(
            value: _config.invert,
            activeColor: _accentColor,
            onChanged: (val) {
              _applyConfig(_config.copyWith(invert: val, isEnabled: true));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              valueText,
              style: AppTypography.caption.copyWith(
                color: _accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _accentColor,
            thumbColor: _accentColor,
            inactiveTrackColor: Colors.white12,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

/// Skia Canvas painter rendering transparency checkerboard, luminance histogram,
/// threshold cutoff marker, and soft feathered silhouette ramp.
class _LumaKeyPainter extends CustomPainter {
  final LumaKeyConfig config;
  final Color accentColor;
  final double phase;

  _LumaKeyPainter({
    required this.config,
    required this.accentColor,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Draw transparency checkerboard pattern
    final checkSize = 10.0;
    final darkCheck = Paint()..color = const Color(0xFF141722);
    final lightCheck = Paint()..color = const Color(0xFF222636);

    for (double y = 0; y < size.height; y += checkSize) {
      for (double x = 0; x < size.width; x += checkSize) {
        final isEven = ((x / checkSize).floor() + (y / checkSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkSize, checkSize),
          isEven ? lightCheck : darkCheck,
        );
      }
    }

    if (!config.isActive) return;

    // 2. Draw simulated luminance content with alpha cutout
    final tX = config.threshold * size.width;
    final tolX = config.tolerance * size.width;

    final contentPaint = Paint()..color = Colors.white.withOpacity(config.opacity);

    if (config.mode == LumaKeyMode.darkSilhouette) {
      // Dark regions cut out, bright regions stay
      final path = Path();
      path.moveTo(tX, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(tX, size.height);
      path.close();
      canvas.drawPath(path, contentPaint);
    } else if (config.mode == LumaKeyMode.brightSpecular) {
      // Bright regions cut out, dark stays
      final path = Path();
      path.moveTo(0, 0);
      path.lineTo(tX, 0);
      path.lineTo(tX, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, contentPaint);
    } else {
      // General gradient ramp
      final rampGradient = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(config.opacity),
        ],
      );
      final rampPaint = Paint()
        ..shader = rampGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), rampPaint);
    }

    // 3. Draw threshold cutoff marker line
    final markerPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(tX, 0), Offset(tX, size.height), markerPaint);

    // 4. Draw tolerance / feathering band
    final featherPaint = Paint()
      ..color = accentColor.withOpacity(0.20);
    canvas.drawRect(
      Rect.fromLTWH((tX - tolX).clamp(0.0, size.width), 0, tolX * 2, size.height),
      featherPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LumaKeyPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.phase != phase;
  }
}
