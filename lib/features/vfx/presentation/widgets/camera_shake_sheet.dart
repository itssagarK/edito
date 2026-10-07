import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/camera_shake_config.dart';
import '../../services/camera_shake_compiler_service.dart';

class CameraShakeSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const CameraShakeSheet({
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
      builder: (context) => CameraShakeSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<CameraShakeSheet> createState() => _CameraShakeSheetState();
}

class _CameraShakeSheetState extends State<CameraShakeSheet> with SingleTickerProviderStateMixin {
  late CameraShakeConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.cameraShake;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(CameraShakeConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(cameraShake: updated);
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
              _buildTypeSelector(),
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
                color: const Color(0xFFFF5722).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.vibration, color: Color(0xFFFF5722), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Camera Shake & Tremor',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  CameraShakeCompilerService.getHudBadge(_config),
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
              activeColor: const Color(0xFFFF5722),
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
          color: _config.isEnabled ? const Color(0xFFFF5722).withOpacity(0.5) : AppColors.border,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return CustomPaint(
              painter: _CameraShakePainter(
                config: _config,
                phase: _animController.value * 2 * math.pi,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.videocam,
                            color: _config.isEnabled ? const Color(0xFFFF5722) : Colors.grey,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _config.shakeType.displayName.toUpperCase(),
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
                      'OPTICAL GYRO SIM',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                        letterSpacing: 1.1,
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

  Widget _buildPresetsRow() {
    final presets = [
      {'name': 'Gentle Handheld', 'config': CameraShakeConfig.gentleHandheld, 'icon': '🎥'},
      {'name': 'Action Tremor', 'config': CameraShakeConfig.actionCamTremor, 'icon': '⚡'},
      {'name': 'Earthquake', 'config': CameraShakeConfig.earthquakeShock, 'icon': '🌋'},
      {'name': 'Offroad Car', 'config': CameraShakeConfig.carOffroad, 'icon': '🚙'},
      {'name': 'Impact Thud', 'config': CameraShakeConfig.impactThud, 'icon': '💥'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CINEMATIC PRESETS',
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
              final presetConfig = p['config'] as CameraShakeConfig;
              final isSelected = _config.shakeType == presetConfig.shakeType &&
                  (_config.intensity - presetConfig.intensity).abs() < 0.05;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _applyConfig(presetConfig),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF5722) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF5722) : AppColors.border,
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
                            color: isSelected ? Colors.white : AppColors.textPrimary,
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

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SHAKE PROFILE',
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
          children: CameraShakeType.values.map((type) {
            final isSelected = _config.shakeType == type;
            return ChoiceChip(
              label: Text(type.displayName),
              selected: isSelected,
              selectedColor: const Color(0xFFFF5722),
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (_) => _applyConfig(_config.copyWith(shakeType: type, isEnabled: true)),
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
            title: 'Intensity',
            value: _config.intensity,
            min: 0.05,
            max: 1.0,
            displayValue: '${(_config.intensity * 100).round()}%',
            onChanged: (val) => _applyConfig(_config.copyWith(intensity: val, isEnabled: true)),
          ),
          const Divider(height: 16, color: AppColors.border),
          _buildSlider(
            title: 'Frequency & Speed',
            value: _config.speed,
            min: 0.2,
            max: 3.0,
            displayValue: '${_config.speed.toStringAsFixed(1)}x',
            onChanged: (val) => _applyConfig(_config.copyWith(speed: val, isEnabled: true)),
          ),
          const Divider(height: 16, color: AppColors.border),
          _buildSlider(
            title: 'Rotation Jitter',
            value: _config.rotationShake,
            min: 0.0,
            max: 1.0,
            displayValue: '${(_config.rotationShake * 100).round()}%',
            onChanged: (val) => _applyConfig(_config.copyWith(rotationShake: val, isEnabled: true)),
          ),
          const Divider(height: 16, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Motion Blur Smoothing', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    'Subtle directional blur across rapid tremors',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                  ),
                ],
              ),
              Switch(
                value: _config.motionBlur,
                activeColor: const Color(0xFFFF5722),
                onChanged: (val) => _applyConfig(_config.copyWith(motionBlur: val)),
              ),
            ],
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
            Text(displayValue, style: const TextStyle(color: Color(0xFFFF5722), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFF5722),
            inactiveTrackColor: AppColors.border,
            thumbColor: const Color(0xFFFF5722),
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

class _CameraShakePainter extends CustomPainter {
  final CameraShakeConfig config;
  final double phase;

  _CameraShakePainter({
    required this.config,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Draw background horizon grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (!config.isEnabled) {
      // Draw stable reticle
      final centerPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(cx, cy), 18, centerPaint);
      canvas.drawLine(Offset(cx - 28, cy), Offset(cx + 28, cy), centerPaint);
      canvas.drawLine(Offset(cx, cy - 28), Offset(cx, cy + 28), centerPaint);
      return;
    }

    // Dynamic displacement simulation
    final amp = config.intensity * 26.0;
    final p = phase * config.speed;

    double dx = 0;
    double dy = 0;
    double rot = 0;

    switch (config.shakeType) {
      case CameraShakeType.handheld:
        dx = math.sin(p * 0.9) * amp + math.cos(p * 0.4) * (amp * 0.5);
        dy = math.cos(p * 1.1) * (amp * 0.8) + math.sin(p * 0.6) * (amp * 0.4);
        rot = math.sin(p * 0.7) * (config.rotationShake * 0.08);
        break;
      case CameraShakeType.earthquake:
        dx = (math.sin(p * 3.5) + math.sin(p * 7.2) * 0.5) * amp;
        dy = (math.cos(p * 3.8) + math.cos(p * 8.1) * 0.5) * amp;
        rot = (math.sin(p * 4.2)) * (config.rotationShake * 0.16);
        break;
      case CameraShakeType.carBumpy:
        dx = (math.sin(p * 2.1) + math.cos(p * 4.2) * 0.3) * (amp * 0.7);
        dy = (math.cos(p * 2.6) + math.sin(p * 5.4) * 0.5) * amp;
        rot = (math.sin(p * 2.8)) * (config.rotationShake * 0.10);
        break;
      case CameraShakeType.heartbeatPulse:
        final pulse = math.pow(math.sin(p * 1.2).clamp(0.0, 1.0), 3.0).toDouble();
        dx = math.sin(p * 0.5) * (amp * 0.3);
        dy = -pulse * amp * 1.2;
        rot = math.sin(p * 0.8) * (config.rotationShake * 0.05);
        break;
      case CameraShakeType.impactTremor:
        final decay = (math.sin(p * 4.5) * math.exp(-((phase % math.pi) * 0.8))).clamp(-1.0, 1.0);
        dx = decay * amp * 1.4;
        dy = decay * amp * 1.2;
        rot = decay * (config.rotationShake * 0.15);
        break;
    }

    canvas.save();
    canvas.translate(cx + dx, cy + dy);
    canvas.rotate(rot);

    // Viewfinder dynamic frame
    final frameRect = Rect.fromCenter(center: Offset.zero, width: size.width * 0.75, height: size.height * 0.75);
    final framePaint = Paint()
      ..color = const Color(0xFFFF5722).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(frameRect, framePaint);

    // Dynamic crosshair reticle
    final reticlePaint = Paint()
      ..color = const Color(0xFFFF5722)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset.zero, 16, reticlePaint);
    canvas.drawLine(const Offset(-24, 0), const Offset(-10, 0), reticlePaint);
    canvas.drawLine(const Offset(10, 0), const Offset(24, 0), reticlePaint);
    canvas.drawLine(const Offset(0, -24), const Offset(0, -10), reticlePaint);
    canvas.drawLine(const Offset(0, 10), const Offset(0, 24), reticlePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CameraShakePainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.phase != phase;
  }
}
