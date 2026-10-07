import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/film_halation_config.dart';
import '../../services/film_halation_compiler_service.dart';

class FilmHalationSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const FilmHalationSheet({
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
      builder: (context) => FilmHalationSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<FilmHalationSheet> createState() => _FilmHalationSheetState();
}

class _FilmHalationSheetState extends State<FilmHalationSheet> with SingleTickerProviderStateMixin {
  late FilmHalationConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.filmHalation;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(FilmHalationConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(filmHalation: updated);
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
                _buildLiveSimulationCard(),
                const SizedBox(height: 16),
                _buildPresetsSection(),
                const SizedBox(height: 16),
                _buildHueSelector(),
                const SizedBox(height: 16),
                _buildControlsSliders(),
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
                      color: const Color(0xFFFF1E27).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.blur_on, color: Color(0xFFFF1E27), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('35mm Film Halation Studio', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF1E27),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text('100% OFFLINE • RED EMULSION BLEED', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.5)),
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
                    activeColor: const Color(0xFFFF1E27),
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

  Widget _buildLiveSimulationCard() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0607),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _config.isEnabled ? Color(_config.hue.colorHex).withOpacity(0.6) : AppColors.border,
          width: 2.0,
        ),
        boxShadow: _config.isEnabled
            ? [
                BoxShadow(
                  color: Color(_config.hue.colorHex).withOpacity(0.18),
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
              painter: _FilmHalationPainter(
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
                        Text(
                          'KODAK 35MM EMULSION SCATTER',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Text(
                            '${(_config.intensity * 100).toInt()}% BLEED • ${_config.spreadRadius.toInt()}px RADIUS',
                            style: AppTypography.timecode.copyWith(fontSize: 10, color: Color(_config.hue.colorHex)),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'EMULSION: ${_config.hue.label.toUpperCase()}',
                          style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.6), fontFamily: 'Courier'),
                        ),
                        Text(
                          'THRESHOLD: ${(_config.threshold * 100).toInt()}%',
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
      {'name': 'CineStill 800T', 'config': FilmHalationConfig.cineStill800T, 'icon': '🔴'},
      {'name': 'Vision3 500T', 'config': FilmHalationConfig.kodakVision3, 'icon': '🟠'},
      {'name': 'Kodachrome 64', 'config': FilmHalationConfig.kodachrome64, 'icon': '🟡'},
      {'name': 'Eterna Pastel', 'config': FilmHalationConfig.fujicolorEterna, 'icon': '🌸'},
      {'name': 'Subtle 16mm', 'config': FilmHalationConfig.subtle16mm, 'icon': '🎞️'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Film Stock Emulsion Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final presetConfig = p['config'] as FilmHalationConfig;
              final isSelected = _config.hue == presetConfig.hue &&
                  (_config.spreadRadius - presetConfig.spreadRadius).abs() < 0.1 &&
                  (_config.intensity - presetConfig.intensity).abs() < 0.1;

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
                      color: isSelected ? Color(presetConfig.hue.colorHex).withOpacity(0.2) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Color(presetConfig.hue.colorHex) : AppColors.border,
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

  Widget _buildHueSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Emulsion Backscatter Hue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HalationHue.values.map((hue) {
            final isSelected = _config.hue == hue;
            final hex = hue.colorHex;

            return InkWell(
              onTap: () {
                _applyConfig(_config.copyWith(hue: hue, isEnabled: true));
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Color(hex).withOpacity(0.2) : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? Color(hex) : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(hex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hue.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
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

  Widget _buildControlsSliders() {
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
              const Text('Diffusion Spread Radius', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${_config.spreadRadius.toInt()} px', style: AppTypography.timecode.copyWith(fontSize: 12, color: Color(_config.hue.colorHex))),
            ],
          ),
          Slider(
            value: _config.spreadRadius,
            min: 2.0,
            max: 30.0,
            divisions: 28,
            activeColor: Color(_config.hue.colorHex),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(spreadRadius: val, isEnabled: true));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Specular Highlight Threshold', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.threshold * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: Color(_config.hue.colorHex))),
            ],
          ),
          Slider(
            value: _config.threshold,
            min: 0.60,
            max: 0.98,
            divisions: 19,
            activeColor: Color(_config.hue.colorHex),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(threshold: val));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Halation Bleed Intensity', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.intensity * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: Color(_config.hue.colorHex))),
            ],
          ),
          Slider(
            value: _config.intensity,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: Color(_config.hue.colorHex),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(intensity: val, isEnabled: true));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Warmth Edge Scatter', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.warmthBleed * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: Color(_config.hue.colorHex))),
            ],
          ),
          Slider(
            value: _config.warmthBleed,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: Color(_config.hue.colorHex),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(warmthBleed: val));
            },
          ),
        ],
      ),
    );
  }
}

class _FilmHalationPainter extends CustomPainter {
  final FilmHalationConfig config;
  final double phase;

  _FilmHalationPainter({
    required this.config,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!config.isActive) return;

    final center = Offset(size.width / 2, size.height / 2);
    final hueColor = Color(config.hue.colorHex);

    // 1. Simulating high-contrast light bulb / specular filament
    final filamentRadius = 14.0;
    final filamentPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, filamentRadius, filamentPaint);

    // 2. Inner photochemical red-orange bloom halo
    final haloRadius = (filamentRadius + config.spreadRadius * 1.5).clamp(16.0, 70.0);
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9),
          hueColor.withOpacity((config.intensity * 0.85).clamp(0.1, 0.95)),
          Color(config.hue.colorHex).withOpacity((config.warmthBleed * 0.6).clamp(0.05, 0.6)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: haloRadius))
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(center, haloRadius, haloPaint);

    // 3. Silhouette edge bleed simulation
    final edgeRect = Rect.fromCenter(center: center.translate(35, 0), width: 18, height: 50);
    canvas.drawRect(
      edgeRect,
      Paint()..color = Colors.black.withOpacity(0.8),
    );

    // Red bleed halo fringing the dark silhouette edge
    final edgeBleedPaint = Paint()
      ..color = hueColor.withOpacity((config.intensity * 0.7).clamp(0.1, 0.85))
      ..strokeWidth = (config.spreadRadius * 0.35).clamp(2.0, 10.0)
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      ..blendMode = BlendMode.screen;

    canvas.drawRect(edgeRect, edgeBleedPaint);
  }

  @override
  bool shouldRepaint(covariant _FilmHalationPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.phase != phase;
  }
}
