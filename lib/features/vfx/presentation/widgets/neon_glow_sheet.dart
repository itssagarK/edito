import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/neon_glow_config.dart';
import '../../services/neon_glow_compiler_service.dart';

class NeonGlowSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const NeonGlowSheet({
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
      builder: (context) => NeonGlowSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<NeonGlowSheet> createState() => _NeonGlowSheetState();
}

class _NeonGlowSheetState extends State<NeonGlowSheet> with SingleTickerProviderStateMixin {
  late NeonGlowConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.neonGlow;
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

  void _applyConfig(NeonGlowConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(neonGlow: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case NeonGlowMode.cyberpunkNeon:
        return const Color(0xFF00E5FF); // Electric cyan
      case NeonGlowMode.hologramWireframe:
        return const Color(0xFF00B0FF); // Sci-fi light blue
      case NeonGlowMode.rainbowEdges:
        return const Color(0xFFFFD700); // Spectral gold
      case NeonGlowMode.matrixPhosphor:
        return const Color(0xFF00FF66); // Terminal phosphor green
      case NeonGlowMode.thermalContour:
        return const Color(0xFFFF3D00); // Thermal flame orange
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

              // Live interactive Skia Canvas neon wireframe monitor
              _buildNeonMonitor(),
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
        Icon(Icons.electric_bolt_rounded, color: _accentColor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cyberpunk Neon & Hologram Glow',
                style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                'Sobel edge detection, neon wireframes, & glowing silhouette contours',
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
                _config.isEnabled ? Icons.auto_awesome : Icons.layers_clear,
                color: _config.isEnabled ? _accentColor : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                _config.isEnabled ? 'Neon Contour Active' : 'Contour Bypassed',
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

  Widget _buildNeonMonitor() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
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
                  painter: _NeonGlowPainter(
                    config: _config,
                    animationValue: _animController.value,
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
                      'SENSITIVITY: ${(100 - _config.edgeThreshold * 100).round()}% | BLOOM: ${_config.glowRadius.round()}px',
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
      {'name': 'Tokyo Cyan', 'config': NeonGlowConfig.tokyoNeonCyan, 'icon': Icons.bolt},
      {'name': 'Hologram Blue', 'config': NeonGlowConfig.hologramMeshBlue, 'icon': Icons.view_in_ar},
      {'name': 'Synthwave', 'config': NeonGlowConfig.synthwaveMagenta, 'icon': Icons.flare},
      {'name': 'Matrix Green', 'config': NeonGlowConfig.matrixWireframe, 'icon': Icons.terminal},
      {'name': 'Rainbow Spectrum', 'config': NeonGlowConfig.rainbowSpectrum, 'icon': Icons.palette},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTOUR PRESETS',
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
              final presetConfig = p['config'] as NeonGlowConfig;
              final isSelected = _config.mode == presetConfig.mode &&
                  (_config.glowIntensity - presetConfig.glowIntensity).abs() < 0.1;
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
          'NEON / WIREFRAME ENGINE',
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
          children: NeonGlowMode.values.map((mode) {
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
        // Edge sensitivity
        _buildSliderTile(
          title: 'Edge Sensitivity',
          valueText: '${(100 - _config.edgeThreshold * 100).round()}%',
          value: _config.edgeThreshold,
          min: 0.05,
          max: 0.80,
          onChanged: (val) => _applyConfig(_config.copyWith(edgeThreshold: val)),
        ),

        // Glow Bloom Radius
        _buildSliderTile(
          title: 'Neon Bloom Radius',
          valueText: '${_config.glowRadius.round()} px',
          value: _config.glowRadius,
          min: 1.0,
          max: 20.0,
          onChanged: (val) => _applyConfig(_config.copyWith(glowRadius: val)),
        ),

        // Glow Luminance Intensity
        _buildSliderTile(
          title: 'Glow Luminance',
          valueText: '${(_config.glowIntensity * 100).round()}%',
          value: _config.glowIntensity,
          min: 0.2,
          max: 2.5,
          onChanged: (val) => _applyConfig(_config.copyWith(glowIntensity: val)),
        ),

        // Mix with source video
        _buildSliderTile(
          title: 'Source Video Blend',
          valueText: '${(_config.mixWithSource * 100).round()}%',
          value: _config.mixWithSource,
          min: 0.0,
          max: 1.0,
          onChanged: (val) => _applyConfig(_config.copyWith(mixWithSource: val)),
        ),

        // Scanlines switch
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Holographic Scanline Raster',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            'Overlays retro-futuristic CRT scanline mesh',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          value: _config.scanlines,
          activeColor: _accentColor,
          onChanged: (val) => _applyConfig(_config.copyWith(scanlines: val)),
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

/// Custom Skia painter displaying stylized glowing neon silhouette contours and holographic scanlines.
class _NeonGlowPainter extends CustomPainter {
  final NeonGlowConfig config;
  final double animationValue;
  final Color accentColor;

  _NeonGlowPainter({
    required this.config,
    required this.animationValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    if (!config.isActive) return;

    final pulse = 0.85 + 0.15 * math.sin(animationValue * 2 * math.pi);
    final intensity = config.glowIntensity * pulse;

    // 1. Draw stylized subject contour silhouette path
    final path = Path();
    final cx = width * 0.5;
    final cy = height * 0.5;

    // Head silhouette
    path.addOval(Rect.fromCircle(center: Offset(cx, cy - 20), radius: 24));
    // Shoulders silhouette
    path.moveTo(cx - 50, cy + 35);
    path.quadraticBezierTo(cx - 30, cy + 5, cx - 18, cy + 8);
    path.lineTo(cx + 18, cy + 8);
    path.quadraticBezierTo(cx + 30, cy + 5, cx + 50, cy + 35);

    // 2. Outer Bloom Diffusion Halo
    final haloPaint = Paint()
      ..color = accentColor.withOpacity((0.35 * intensity).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.glowRadius * 1.5
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius);
    canvas.drawPath(path, haloPaint);

    // 3. Inner Razor-Sharp Neon Core
    final corePaint = Paint()
      ..color = Colors.white.withOpacity((0.90 * intensity).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, corePaint);

    // Secondary colored neon edge stroke
    final edgePaint = Paint()
      ..color = accentColor.withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(path, edgePaint);

    // 4. Holographic scanlines
    if (config.scanlines) {
      final scanPaint = Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..strokeWidth = 1.0;
      for (double y = 0; y < height; y += 4.0) {
        canvas.drawLine(Offset(0, y), Offset(width, y), scanPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NeonGlowPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.config != config;
  }
}
