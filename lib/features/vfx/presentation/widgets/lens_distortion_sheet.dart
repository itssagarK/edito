import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/lens_distortion_config.dart';
import '../../services/lens_distortion_compiler_service.dart';

class LensDistortionSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const LensDistortionSheet({
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
      builder: (context) => LensDistortionSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<LensDistortionSheet> createState() => _LensDistortionSheetState();
}

class _LensDistortionSheetState extends State<LensDistortionSheet> {
  late LensDistortionConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.lensDistortion;
  }

  void _applyConfig(LensDistortionConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(lensDistortion: updated);
    widget.onSave(updatedClip);
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildLiveMonitorCard(),
              const SizedBox(height: 16),
              _buildPresetsRow(),
              const SizedBox(height: 16),
              _buildProfileSelector(),
              const SizedBox(height: 16),
              _buildControls(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (widget.isDocked) return content;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, controller) => content,
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.panorama_fish_eye, color: Color(0xFF00E5FF), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lens Distortion & Fisheye',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  LensDistortionCompilerService.getHudBadge(_config),
                  style: AppTypography.labelSmall.copyWith(color: AppColors.accent),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Switch(
              value: _config.isEnabled,
              activeColor: const Color(0xFF00E5FF),
              onChanged: (val) => _applyConfig(_config.copyWith(isEnabled: val)),
            ),
            if (widget.onDone != null)
              IconButton(
                icon: const Icon(Icons.check, color: AppColors.textPrimary),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  padding: const EdgeInsets.all(8),
                ),
                onPressed: widget.onDone,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveMonitorCard() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isEnabled ? const Color(0xFF00E5FF).withOpacity(0.5) : AppColors.border,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: CustomPaint(
          painter: _LensDistortionPainter(config: _config),
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.camera,
                        color: _config.isEnabled ? const Color(0xFF00E5FF) : Colors.grey,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _config.profile.displayName.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 10,
                child: Text(
                  'OPTICAL CURVATURE MESH',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 9,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsRow() {
    final presets = [
      {'name': 'GoPro Fisheye', 'config': LensDistortionConfig.actionGoPro, 'icon': '🏄'},
      {'name': 'Skate Fisheye', 'config': LensDistortionConfig.skateVideoFisheye, 'icon': '🛹'},
      {'name': 'Cinema Barrel', 'config': LensDistortionConfig.cinemaAnamorphic, 'icon': '🎬'},
      {'name': 'Tele Pincushion', 'config': LensDistortionConfig.telephotoPincushion, 'icon': '🔭'},
      {'name': 'CCTV Spyglass', 'config': LensDistortionConfig.securityCCTV, 'icon': '📹'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OPTICAL PRESETS',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final presetConfig = p['config'] as LensDistortionConfig;
              final isSelected = _config.profile == presetConfig.profile &&
                  (_config.distortion - presetConfig.distortion).abs() < 0.05;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _applyConfig(presetConfig),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00E5FF) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00E5FF) : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(p['icon'] as String, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(
                          p['name'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LENS GEOMETRY PROFILE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LensDistortionProfile.values.map((prof) {
            final isSelected = _config.profile == prof;
            return ChoiceChip(
              label: Text(prof.displayName),
              selected: isSelected,
              selectedColor: const Color(0xFF00E5FF),
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (_) => _applyConfig(_config.copyWith(profile: prof, isEnabled: true)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSlider(
            title: 'Curvature (Barrel vs Pincushion)',
            value: _config.distortion,
            min: -1.0,
            max: 1.0,
            displayValue: '${_config.distortion > 0 ? '+' : ''}${(_config.distortion * 100).round()}%',
            onChanged: (val) => _applyConfig(_config.copyWith(distortion: val, isEnabled: true)),
          ),
          const Divider(height: 16, color: AppColors.border),
          _buildSlider(
            title: 'Chromatic Aberration (RGB Fringe)',
            value: _config.chromaticAberration,
            min: 0.0,
            max: 1.0,
            displayValue: '${(_config.chromaticAberration * 100).round()}%',
            onChanged: (val) => _applyConfig(_config.copyWith(chromaticAberration: val, isEnabled: true)),
          ),
          const Divider(height: 16, color: AppColors.border),
          _buildSlider(
            title: 'Vignette Edge Falloff',
            value: _config.vignetteFalloff,
            min: 0.0,
            max: 1.0,
            displayValue: '${(_config.vignetteFalloff * 100).round()}%',
            onChanged: (val) => _applyConfig(_config.copyWith(vignetteFalloff: val, isEnabled: true)),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(displayValue, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF00E5FF),
            inactiveTrackColor: AppColors.border,
            thumbColor: const Color(0xFF00E5FF),
            trackHeight: 3,
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

class _LensDistortionPainter extends CustomPainter {
  final LensDistortionConfig config;

  _LensDistortionPainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxRadius = math.sqrt(cx * cx + cy * cy);

    // 1. Distorted Optical Mesh Grid
    final gridCount = 9;
    final distCoeff = config.isEnabled ? config.distortion : 0.0;
    final chromaOffset = config.isEnabled ? (config.chromaticAberration * 3.5) : 0.0;

    void drawCurvedGrid(Color color, double chromaDelta) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // Vertical lines
      for (int i = 0; i <= gridCount; i++) {
        final normX = (i / gridCount) * 2 - 1; // -1 to 1
        final path = Path();

        for (int step = 0; step <= 24; step++) {
          final normY = (step / 24) * 2 - 1;
          final r = math.sqrt(normX * normX + normY * normY);
          final warp = 1.0 + (distCoeff * 0.35 * (r * r));
          final px = cx + (normX * warp * (cx * 0.85)) + chromaDelta;
          final py = cy + (normY * warp * (cy * 0.85));

          if (step == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        canvas.drawPath(path, paint);
      }

      // Horizontal lines
      for (int j = 0; j <= gridCount; j++) {
        final normY = (j / gridCount) * 2 - 1; // -1 to 1
        final path = Path();

        for (int step = 0; step <= 24; step++) {
          final normX = (step / 24) * 2 - 1;
          final r = math.sqrt(normX * normX + normY * normY);
          final warp = 1.0 + (distCoeff * 0.35 * (r * r));
          final px = cx + (normX * warp * (cx * 0.85)) + chromaDelta;
          final py = cy + (normY * warp * (cy * 0.85));

          if (step == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        canvas.drawPath(path, paint);
      }
    }

    if (chromaOffset > 0.3) {
      // Draw Red and Cyan fringe split
      drawCurvedGrid(Colors.redAccent.withOpacity(0.35), chromaOffset);
      drawCurvedGrid(Colors.cyanAccent.withOpacity(0.35), -chromaOffset);
    }
    drawCurvedGrid(Colors.white.withOpacity(0.65), 0.0);

    // 2. Optical Lens Vignette Falloff
    if (config.isEnabled && config.vignetteFalloff > 0.05) {
      final vigOpacity = (config.vignetteFalloff * 0.85).clamp(0.1, 0.9);
      final vigPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(vigOpacity * 0.4),
            Colors.black.withOpacity(vigOpacity),
          ],
          stops: const [0.45, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vigPaint);
    }

    // 3. Lens Optical Circular Outer Ring
    final ringPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(config.isEnabled ? 0.45 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(cx, cy), math.min(cx, cy) * 0.92, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _LensDistortionPainter oldDelegate) {
    return oldDelegate.config != config;
  }
}
