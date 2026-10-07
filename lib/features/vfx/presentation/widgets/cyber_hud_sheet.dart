import 'dart:math' as math;
import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/cyber_hud_config.dart';
import '../../services/cyber_hud_compiler_service.dart';

/// Interactive bottom sheet and docked panel for configuring sci-fi
/// tactical HUD holograms and cyber reticles.
class CyberHudSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const CyberHudSheet({
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
      builder: (context) => CyberHudSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<CyberHudSheet> createState() => _CyberHudSheetState();
}

class _CyberHudSheetState extends State<CyberHudSheet>
    with SingleTickerProviderStateMixin {
  late CyberHudConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.cyberHud;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(CyberHudConfig updated) {
    setState(() => _config = updated);
    final updatedClip = widget.clip.copyWith(cyberHud: updated);
    widget.onSave(updatedClip);
  }

  Color get _hudColor => _config.color.color;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(20)),
        border: widget.isDocked
            ? const Border(top: BorderSide(color: AppColors.surfaceElevated, width: 1))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonitorCard(),
                    const SizedBox(height: 14),
                    _buildModeSelector(),
                    const SizedBox(height: 14),
                    _buildColorSelector(),
                    const SizedBox(height: 14),
                    _buildPresetRow(),
                    const SizedBox(height: 16),
                    _buildSliders(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isDocked) return content;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      builder: (_, controller) => content,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceElevated, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hudColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.gps_fixed, color: _hudColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cyber HUD Reticle',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _config.isActive
                      ? '${_config.mode.label} • ${_config.color.label}'
                      : 'Disabled',
                  style: AppTypography.labelSmall.copyWith(
                    color: _config.isActive ? _hudColor : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: _hudColor,
            onChanged: (val) {
              _applyConfig(_config.copyWith(isEnabled: val));
            },
          ),
          if (!widget.isDocked)
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.primary),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                shape: const CircleBorder(),
              ),
              onPressed: () {
                widget.onDone?.call();
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMonitorCard() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isActive ? _hudColor.withOpacity(0.4) : AppColors.surfaceElevated,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return CustomPaint(
            painter: _CyberHudPainter(
              config: _config,
              progress: _animController.value,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _hudColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      'STATUS: ${_config.isActive ? "ONLINE" : "STANDBY"} [SYS.V26]',
                      style: TextStyle(
                        color: _hudColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 10,
                  child: Text(
                    'SCALE: ${(_config.scale * 100).round()}% | ${(100 * _config.opacity).round()}% OPACITY',
                    style: TextStyle(
                      color: _hudColor.withOpacity(0.7),
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HUD INTERFACE SYSTEM',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CyberHudMode.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final mode = CyberHudMode.values[idx];
              final isSelected = _config.mode == mode;
              return ChoiceChip(
                label: Text(mode.label),
                selected: isSelected,
                selectedColor: _hudColor.withOpacity(0.25),
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: TextStyle(
                  color: isSelected ? _hudColor : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? _hudColor : Colors.transparent,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    _applyConfig(_config.copyWith(mode: mode, isEnabled: true));
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOLOGRAPHIC EMISSION COLOR',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: CyberHudColor.values.map((col) {
            final isSelected = _config.color == col;
            return GestureDetector(
              onTap: () => _applyConfig(_config.copyWith(color: col, isEnabled: true)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? col.color.withOpacity(0.2) : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? col.color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: col.color,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: col.color.withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      col.label.split(' ')[0],
                      style: TextStyle(
                        color: isSelected ? col.color : Colors.white70,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPresetRow() {
    final presets = [
      ('Hunter Lock', CyberHudConfig.presetHunterLock),
      ('Sonar Sweep', CyberHudConfig.presetSonarSweep),
      ('Avionics', CyberHudConfig.presetAvionicsHud),
      ('Cyber Combat', CyberHudConfig.presetCyberCombat),
      ('Orbital', CyberHudConfig.presetQuantumOrbital),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURATED PRESETS',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: presets.map((preset) {
            return ActionChip(
              label: Text(preset.$1),
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              onPressed: () {
                _applyConfig(preset.$2);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderTile(
          title: 'Hologram Opacity',
          value: _config.opacity,
          min: 0.1,
          max: 1.0,
          displayValue: '${(_config.opacity * 100).round()}%',
          onChanged: (v) => _applyConfig(_config.copyWith(opacity: v, isEnabled: true)),
        ),
        _buildSliderTile(
          title: 'HUD Reticle Scale',
          value: _config.scale,
          min: 0.5,
          max: 1.8,
          displayValue: '${_config.scale.toStringAsFixed(1)}x',
          onChanged: (v) => _applyConfig(_config.copyWith(scale: v, isEnabled: true)),
        ),
        _buildSliderTile(
          title: 'Sweep / Radar Speed',
          value: _config.sweepSpeed,
          min: 0.2,
          max: 3.0,
          displayValue: '${_config.sweepSpeed.toStringAsFixed(1)}x',
          onChanged: (v) => _applyConfig(_config.copyWith(sweepSpeed: v)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Holographic Scanlines', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                  Switch(
                    value: _config.scanlines,
                    activeColor: _hudColor,
                    onChanged: (val) => _applyConfig(_config.copyWith(scanlines: val)),
                  ),
                ],
              ),
              const Divider(color: AppColors.surfaceElevated, height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Telemetry Coordinates', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                  Switch(
                    value: _config.showTelemetry,
                    activeColor: _hudColor,
                    onChanged: (val) => _applyConfig(_config.copyWith(showTelemetry: val)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset Defaults'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              onPressed: () {
                _applyConfig(CyberHudConfig.defaultDisabled);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(color: Colors.white70),
            ),
            Text(
              displayValue,
              style: AppTypography.labelSmall.copyWith(
                color: _hudColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _hudColor,
            inactiveTrackColor: AppColors.surfaceElevated,
            thumbColor: _hudColor,
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
    );
  }
}

/// Skia custom painter visualizing dynamic sci-fi cyber HUD reticles,
/// rotating radar sweep, and telemetry elements.
class _CyberHudPainter extends CustomPainter {
  final CyberHudConfig config;
  final double progress;

  _CyberHudPainter({
    required this.config,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!config.isActive) return;

    final center = Offset(size.width / 2, size.height / 2);
    final hudColor = config.color.color;
    final op = config.opacity;
    final scale = config.scale;

    // 1. Scanlines
    if (config.scanlines) {
      final scanPaint = Paint()
        ..color = hudColor.withOpacity(0.08 * op)
        ..strokeWidth = 1.0;
      for (double y = 0; y < size.height; y += 4) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
      }
    }

    // 2. Corner L-Brackets
    final bracketPaint = Paint()
      ..color = hudColor.withOpacity(0.85 * op)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const bLen = 22.0;
    const bPad = 12.0;

    // Top-Left
    canvas.drawLine(const Offset(bPad, bPad), const Offset(bPad + bLen, bPad), bracketPaint);
    canvas.drawLine(const Offset(bPad, bPad), const Offset(bPad, bPad + bLen), bracketPaint);
    // Top-Right
    canvas.drawLine(Offset(size.width - bPad, bPad), Offset(size.width - bPad - bLen, bPad), bracketPaint);
    canvas.drawLine(Offset(size.width - bPad, bPad), Offset(size.width - bPad, bPad + bLen), bracketPaint);
    // Bottom-Left
    canvas.drawLine(Offset(bPad, size.height - bPad), Offset(bPad + bLen, size.height - bPad), bracketPaint);
    canvas.drawLine(Offset(bPad, size.height - bPad), Offset(bPad, size.height - bPad - bLen), bracketPaint);
    // Bottom-Right
    canvas.drawLine(Offset(size.width - bPad, size.height - bPad), Offset(size.width - bPad - bLen, size.height - bPad), bracketPaint);
    canvas.drawLine(Offset(size.width - bPad, size.height - bPad), Offset(size.width - bPad, size.height - bPad - bLen), bracketPaint);

    // 3. Central Reticle & Radar Rings
    final ringRadius = 55.0 * scale;
    final ringPaint = Paint()
      ..color = hudColor.withOpacity(0.4 * op)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, ringRadius, ringPaint);
    canvas.drawCircle(center, ringRadius * 0.6, ringPaint..color = hudColor.withOpacity(0.25 * op));
    canvas.drawCircle(center, ringRadius * 1.35, ringPaint..color = hudColor.withOpacity(0.2 * op));

    // Radar Rotating Sweep Arm
    final sweepAngle = (progress * 2 * math.pi * config.sweepSpeed) % (2 * math.pi);
    final sweepArm = Offset(
      center.dx + math.cos(sweepAngle) * ringRadius * 1.35,
      center.dy + math.sin(sweepAngle) * ringRadius * 1.35,
    );

    final armPaint = Paint()
      ..color = hudColor.withOpacity(0.9 * op)
      ..strokeWidth = 1.5;
    canvas.drawLine(center, sweepArm, armPaint);

    // Radar Sweep Sector Glow
    final sweepSectorPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: sweepAngle - 0.5,
        endAngle: sweepAngle,
        colors: [
          hudColor.withOpacity(0.0),
          hudColor.withOpacity(0.25 * op),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: ringRadius * 1.35))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, ringRadius * 1.35, sweepSectorPaint);

    // Center Mode-Specific Graphics
    final mainPaint = Paint()
      ..color = hudColor.withOpacity(op)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    switch (config.mode) {
      case CyberHudMode.tacticalTargeting:
        // Diamond target lock
        final dPath = Path();
        final dSize = 16.0 * scale;
        dPath.moveTo(center.dx, center.dy - dSize);
        dPath.lineTo(center.dx + dSize, center.dy);
        dPath.lineTo(center.dx, center.dy + dSize);
        dPath.lineTo(center.dx - dSize, center.dy);
        dPath.close();
        canvas.drawPath(dPath, mainPaint);
        // Crosshair ticks
        canvas.drawLine(center.translate(-dSize - 12, 0), center.translate(-dSize - 4, 0), mainPaint);
        canvas.drawLine(center.translate(dSize + 4, 0), center.translate(dSize + 12, 0), mainPaint);
        canvas.drawLine(center.translate(0, -dSize - 12), center.translate(0, -dSize - 4), mainPaint);
        canvas.drawLine(center.translate(0, dSize + 4), center.translate(0, dSize + 12), mainPaint);
        break;

      case CyberHudMode.radarSonarScan:
        // Crosshair compass lines
        canvas.drawLine(center.translate(-ringRadius * 1.35, 0), center.translate(ringRadius * 1.35, 0), ringPaint);
        canvas.drawLine(center.translate(0, -ringRadius * 1.35), center.translate(0, ringRadius * 1.35), ringPaint);
        // Blip dots
        final blipPaint = Paint()..color = hudColor.withOpacity(0.9 * op);
        canvas.drawCircle(center.translate(22 * scale, -18 * scale), 2.5, blipPaint);
        canvas.drawCircle(center.translate(-35 * scale, 28 * scale), 2.0, blipPaint);
        break;

      case CyberHudMode.sciFiTelemetry:
      case CyberHudMode.flightAvionics:
        // Artificial horizon pitch bars
        canvas.drawLine(center.translate(-40 * scale, -15 * scale), center.translate(-15 * scale, -15 * scale), mainPaint);
        canvas.drawLine(center.translate(15 * scale, -15 * scale), center.translate(40 * scale, -15 * scale), mainPaint);
        canvas.drawLine(center.translate(-30 * scale, 15 * scale), center.translate(-12 * scale, 15 * scale), mainPaint);
        canvas.drawLine(center.translate(12 * scale, 15 * scale), center.translate(30 * scale, 15 * scale), mainPaint);
        // Center reticle dot
        canvas.drawCircle(center, 3.0, Paint()..color = hudColor.withOpacity(op));
        break;

      case CyberHudMode.cyberpunkCombat:
        // Hexagonal combat shield outline
        final hexPath = Path();
        final hRadius = 32.0 * scale;
        for (int i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          final x = center.dx + hRadius * math.cos(a);
          final y = center.dy + hRadius * math.sin(a);
          if (i == 0) hexPath.moveTo(x, y);
          else hexPath.lineTo(x, y);
        }
        hexPath.close();
        canvas.drawPath(hexPath, mainPaint);
        break;
    }

    // 4. Telemetry Readouts
    if (config.showTelemetry) {
      final textStyle = TextStyle(
        color: hudColor.withOpacity(0.85 * op),
        fontSize: 9,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      );

      final spanLeft = TextSpan(
        text: 'ALT 12,400M\nVEL MACH 1.8\nLOCK [ACQ-4]',
        style: textStyle,
      );
      final tpLeft = TextPainter(text: spanLeft, textDirection: TextDirection.ltr)..layout();
      tpLeft.paint(canvas, const Offset(bPad + 6, bPad + 28));

      final spanRight = TextSpan(
        text: 'HDG 084° E\nAZM +14.2°\nSYS NOMINAL',
        style: textStyle,
      );
      final tpRight = TextPainter(text: spanRight, textDirection: TextDirection.ltr)..layout();
      tpRight.paint(canvas, Offset(size.width - bPad - tpRight.width - 6, bPad + 28));
    }
  }

  @override
  bool shouldRepaint(covariant _CyberHudPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.progress != progress;
  }
}
