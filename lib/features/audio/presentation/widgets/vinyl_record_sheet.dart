import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/vinyl_record_config.dart';
import '../../services/vinyl_record_compiler_service.dart';

class VinylRecordSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const VinylRecordSheet({
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
      builder: (context) => VinylRecordSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<VinylRecordSheet> createState() => _VinylRecordSheetState();
}

class _VinylRecordSheetState extends State<VinylRecordSheet> with SingleTickerProviderStateMixin {
  late VinylRecordConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.vinylRecord;
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

  void _applyConfig(VinylRecordConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(vinylRecord: updated);
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
              _buildLiveTurntableMonitor(),
              const SizedBox(height: 16),
              _buildPresetsRow(),
              const SizedBox(height: 16),
              _buildRpmSelector(),
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
                color: const Color(0xFFFFB300).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.album, color: Color(0xFFFFB300), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vinyl Turntable Studio',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  VinylRecordCompilerService.getHudBadge(_config),
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
              activeColor: const Color(0xFFFFB300),
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

  Widget _buildLiveTurntableMonitor() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF14120E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isEnabled ? const Color(0xFFFFB300).withOpacity(0.5) : AppColors.border,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            final phase = _animController.value * 2 * math.pi * _config.rpm.rotationSpeed;
            return CustomPaint(
              painter: _VinylTurntablePainter(
                config: _config,
                phase: phase,
              ),
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
                            Icons.album,
                            color: _config.isEnabled ? const Color(0xFFFFB300) : Colors.grey,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _config.rpm.displayName.toUpperCase(),
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
                      'HI-FI DIRECT DRIVE',
                      style: TextStyle(
                        color: const Color(0xFFFFB300).withOpacity(0.6),
                        fontSize: 9,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
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
      {'name': 'Classic LP 33', 'config': VinylRecordConfig.classicLp33, 'icon': '💿'},
      {'name': 'Vintage 45', 'config': VinylRecordConfig.vintageSingle45, 'icon': '📻'},
      {'name': 'Antique 78', 'config': VinylRecordConfig.antiqueGramophone78, 'icon': '🎺'},
      {'name': 'Lo-Fi Warm', 'config': VinylRecordConfig.lofiWarmBeats, 'icon': '☕'},
      {'name': 'Dusty Attic', 'config': VinylRecordConfig.wornDustyVinyl, 'icon': '📦'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANALOG RECORD PRESETS',
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
              final presetConfig = p['config'] as VinylRecordConfig;
              final isSelected = _config.rpm == presetConfig.rpm &&
                  (_config.dustCrackle - presetConfig.dustCrackle).abs() < 0.05;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _applyConfig(presetConfig),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFB300) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFFB300) : AppColors.border,
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

  Widget _buildRpmSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TURNTABLE ROTATION SPEED (RPM)',
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
          children: VinylRpm.values.map((speed) {
            final isSelected = _config.rpm == speed;
            return ChoiceChip(
              label: Text(speed.displayName),
              selected: isSelected,
              selectedColor: const Color(0xFFFFB300),
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (_) => _applyConfig(_config.copyWith(rpm: speed, isEnabled: true)),
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
            title: 'Dust Crackle & Needle Pops',
            value: _config.dustCrackle,
            min: 0.0,
            max: 1.0,
            displayValue: '${(_config.dustCrackle * 100).round()}%',
            onChanged: (val) => _applyConfig(_config.copyWith(dustCrackle: val, isEnabled: true)),
          ),
          const Divider(height: 16, color: AppColors.border),
          _buildSlider(
            title: 'Continuous Surface Hiss',
            value: _config.surfaceNoise,
            min: 0.0,
            max: 1.0,
            displayValue: '${(_config.surfaceNoise * 100).round()}%',
            onChanged: (val) => _applyConfig(_config.copyWith(surfaceNoise: val, isEnabled: true)),
          ),
          const Divider(height: 16, color: AppColors.border),
          _buildSlider(
            title: 'Phono Cartridge Warmth (RIAA)',
            value: _config.needleWearTone,
            min: 0.0,
            max: 1.0,
            displayValue: '${(_config.needleWearTone * 100).round()}%',
            onChanged: (val) => _applyConfig(_config.copyWith(needleWearTone: val, isEnabled: true)),
          ),
          const Divider(height: 16, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Needle Drop Intro Cue', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    'Soft mechanical click as stylus hits outer groove',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                  ),
                ],
              ),
              Switch(
                value: _config.needleDropCue,
                activeColor: const Color(0xFFFFB300),
                onChanged: (val) => _applyConfig(_config.copyWith(needleDropCue: val)),
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
            Text(displayValue, style: const TextStyle(color: Color(0xFFFFB300), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFFB300),
            inactiveTrackColor: AppColors.border,
            thumbColor: const Color(0xFFFFB300),
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

class _VinylTurntablePainter extends CustomPainter {
  final VinylRecordConfig config;
  final double phase;

  _VinylTurntablePainter({
    required this.config,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.40;
    final cy = size.height / 2;
    final recordRadius = 55.0;

    // 1. Turntable platter slipmat
    final slipmatPaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), recordRadius + 4, slipmatPaint);

    // 2. Vinyl disc
    final discPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), recordRadius, discPaint);

    // 3. Concentric microgrooves
    final groovePaint = Paint()
      ..color = Colors.white.withOpacity(0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double r = 24.0; r < recordRadius - 2; r += 5.5) {
      canvas.drawCircle(Offset(cx, cy), r, groovePaint);
    }

    // 4. Rotating light reflections (specular sheen on grooves)
    final sheenPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.18),
          Colors.transparent,
          Colors.white.withOpacity(0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        transform: GradientRotation(phase),
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: recordRadius));

    canvas.drawCircle(Offset(cx, cy), recordRadius, sheenPaint);

    // 5. Center record label (warm gold / red)
    final labelPaint = Paint()
      ..color = const Color(0xFFD43828)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 18.0, labelPaint);

    final innerRingPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(cx, cy), 14.0, innerRingPaint);

    // Center spindle hole
    final spindlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 3.5, spindlePaint);

    // 6. Dust Fleck Particles
    if (config.isEnabled && config.dustCrackle > 0.1) {
      final dustPaint = Paint()
        ..color = const Color(0xFFFFE082).withOpacity(0.7)
        ..style = PaintingStyle.fill;

      final randSeed = (phase * 10).toInt();
      for (int i = 0; i < 7; i++) {
        final angle = (randSeed * 1.37 + i * 1.8) % (2 * math.pi);
        final dist = 22.0 + ((randSeed * 3.7 + i * 9.1) % (recordRadius - 24.0));
        final px = cx + math.cos(angle) * dist;
        final py = cy + math.sin(angle) * dist;
        canvas.drawCircle(Offset(px, py), 1.2, dustPaint);
      }
    }

    // 7. Tonearm tracking over the record
    final tonearmBase = Offset(size.width * 0.82, 22.0);
    final pivotPaint = Paint()
      ..color = const Color(0xFF8D8D8D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(tonearmBase, 9.0, pivotPaint);

    // Tonearm wand
    final stylusPos = Offset(cx + recordRadius * 0.45, cy + 12.0);
    final armPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path()
      ..moveTo(tonearmBase.dx, tonearmBase.dy)
      ..lineTo(tonearmBase.dx - 18, tonearmBase.dy + 42)
      ..lineTo(stylusPos.dx, stylusPos.dy);

    canvas.drawPath(path, armPaint);

    // Headshell Cartridge
    final cartridgePaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(center: stylusPos, width: 7.0, height: 11.0),
      cartridgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VinylTurntablePainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.phase != phase;
  }
}
