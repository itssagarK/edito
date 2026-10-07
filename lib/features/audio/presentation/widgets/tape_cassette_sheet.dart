import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/tape_cassette_config.dart';
import '../../services/tape_cassette_compiler_service.dart';

class TapeCassetteSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const TapeCassetteSheet({
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
      builder: (context) => TapeCassetteSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<TapeCassetteSheet> createState() => _TapeCassetteSheetState();
}

class _TapeCassetteSheetState extends State<TapeCassetteSheet> with SingleTickerProviderStateMixin {
  late TapeCassetteConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.tapeCassette;
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

  void _applyConfig(TapeCassetteConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(tapeCassette: updated);
    widget.onSave(updatedClip);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.isDocked ? null : MediaQuery.of(context).size.height * 0.68,
      decoration: BoxDecoration(
        color: widget.isDocked ? Colors.transparent : AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: widget.isDocked ? null : const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked) _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildLiveCassetteMonitor(),
                const SizedBox(height: 16),
                _buildPresetsSection(),
                const SizedBox(height: 16),
                _buildWowControls(),
                const SizedBox(height: 16),
                _buildFlutterAndWarmthControls(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9E00).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.album, color: Color(0xFFFF9E00), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vintage Tape Cassette Studio', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF9E00),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text('100% OFFLINE • WOW & FLUTTER DSP', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Switch(
                    value: _config.isEnabled,
                    activeColor: const Color(0xFFFF9E00),
                    onChanged: (val) {
                      _applyConfig(_config.copyWith(isEnabled: val));
                    },
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                    icon: const Icon(Icons.check, color: AppColors.accent, size: 20),
                    onPressed: widget.onDone ?? () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCassetteMonitor() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF140D05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _config.isEnabled ? const Color(0xFFFF9E00).withOpacity(0.6) : AppColors.border,
          width: 2.0,
        ),
        boxShadow: _config.isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFFFF9E00).withOpacity(0.18),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return CustomPaint(
              painter: _TapeCassettePainter(
                config: _config,
                phase: _animController.value,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(_config.era.iconEmoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              _config.era.label.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Color(0xFFFF9E00),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Text(
                            '${(_config.wowDepth * 100).toInt()}% WOW • ${(_config.flutterDepth * 100).toInt()}% FLUTTER',
                            style: AppTypography.timecode.copyWith(fontSize: 10, color: const Color(0xFFFF9E00)),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'WARMTH: ${(_config.tapeWarmth * 100).toInt()}%',
                          style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.6), fontFamily: 'Courier'),
                        ),
                        Text(
                          'HISS: ${(_config.hissLevel * 100).toInt()}%',
                          style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.6), fontFamily: 'Courier'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPresetsSection() {
    final presets = [
      {'name': 'Walkman 1985', 'config': TapeCassetteConfig.walkman1985, 'icon': '📼'},
      {'name': 'Dictaphone', 'config': TapeCassetteConfig.microcassette, 'icon': '🎙️'},
      {'name': 'VHS Hi-Fi', 'config': TapeCassetteConfig.vhsHiFi, 'icon': '📺'},
      {'name': 'Reel-to-Reel', 'config': TapeCassetteConfig.masterReel15ips, 'icon': '🎛️'},
      {'name': 'Thrift Cassette', 'config': TapeCassetteConfig.wornThriftTape, 'icon': '📻'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Analog Tape Era Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final presetConfig = p['config'] as TapeCassetteConfig;
              final isSelected = _config.era == presetConfig.era;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    _applyConfig(presetConfig.copyWith(isEnabled: true));
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF9E00).withOpacity(0.2) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF9E00) : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(p['icon'] as String, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          p['name'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
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

  Widget _buildWowControls() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wow Pitch Drift Depth', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.wowDepth * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: const Color(0xFFFF9E00))),
            ],
          ),
          Slider(
            value: _config.wowDepth,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: const Color(0xFFFF9E00),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(wowDepth: val, isEnabled: true));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wow LFO Speed Rate', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${_config.wowRateHz.toStringAsFixed(1)} Hz', style: AppTypography.timecode.copyWith(fontSize: 12, color: const Color(0xFFFF9E00))),
            ],
          ),
          Slider(
            value: _config.wowRateHz,
            min: 0.2,
            max: 2.0,
            divisions: 18,
            activeColor: const Color(0xFFFF9E00),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(wowRateHz: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFlutterAndWarmthControls() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Flutter Capstan Vibration', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.flutterDepth * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: const Color(0xFFFF9E00))),
            ],
          ),
          Slider(
            value: _config.flutterDepth,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: const Color(0xFFFF9E00),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(flutterDepth: val, isEnabled: true));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Magnetic Tape Warmth & Saturation', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.tapeWarmth * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: const Color(0xFFFF9E00))),
            ],
          ),
          Slider(
            value: _config.tapeWarmth,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: const Color(0xFFFF9E00),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(tapeWarmth: val));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Analog Tape Hiss Noise Floor', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.hissLevel * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: const Color(0xFFFF9E00))),
            ],
          ),
          Slider(
            value: _config.hissLevel,
            min: 0.0,
            max: 0.30,
            divisions: 15,
            activeColor: const Color(0xFFFF9E00),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(hissLevel: val));
            },
          ),
        ],
      ),
    );
  }
}

class _TapeCassettePainter extends CustomPainter {
  final TapeCassetteConfig config;
  final double phase;

  _TapeCassettePainter({
    required this.config,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Dual rotating tape cassette reels
    final reelRadius = 24.0;
    final leftCenter = Offset(center.dx - 55, center.dy);
    final rightCenter = Offset(center.dx + 55, center.dy);

    final reelPaint = Paint()
      ..color = const Color(0xFFFF9E00).withOpacity(config.isActive ? 0.35 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(leftCenter, reelRadius, reelPaint);
    canvas.drawCircle(rightCenter, reelRadius, reelPaint);

    // Reel spokes
    final spokeAngle = phase * 2 * math.pi;
    for (int i = 0; i < 6; i++) {
      final a = spokeAngle + (i * math.pi / 3);
      final dx = math.cos(a) * reelRadius;
      final dy = math.sin(a) * reelRadius;
      canvas.drawLine(leftCenter, Offset(leftCenter.dx + dx, leftCenter.dy + dy), reelPaint);
      canvas.drawLine(rightCenter, Offset(rightCenter.dx + dx, rightCenter.dy + dy), reelPaint);
    }

    // 2. Magnetic tape ribbon path
    final tapePaint = Paint()
      ..color = const Color(0xFFFF9E00).withOpacity(config.isActive ? 0.6 : 0.2)
      ..strokeWidth = 2.5;

    canvas.drawLine(
      Offset(leftCenter.dx, leftCenter.dy + reelRadius),
      Offset(rightCenter.dx, rightCenter.dy + reelRadius),
      tapePaint,
    );

    // 3. Central magnetic head & capstan
    final headRect = Rect.fromCenter(center: Offset(center.dx, center.dy + reelRadius), width: 22, height: 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, const Radius.circular(3)),
      Paint()..color = Colors.white.withOpacity(config.isActive ? 0.5 : 0.2),
    );
  }

  @override
  bool shouldRepaint(covariant _TapeCassettePainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.phase != phase;
  }
}
