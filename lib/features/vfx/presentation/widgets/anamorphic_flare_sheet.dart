import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/anamorphic_flare_config.dart';
import '../../services/anamorphic_flare_compiler_service.dart';

class AnamorphicFlareSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const AnamorphicFlareSheet({
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
      builder: (context) => AnamorphicFlareSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<AnamorphicFlareSheet> createState() => _AnamorphicFlareSheetState();
}

class _AnamorphicFlareSheetState extends State<AnamorphicFlareSheet> with SingleTickerProviderStateMixin {
  late AnamorphicFlareConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.anamorphicFlare;
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

  void _applyConfig(AnamorphicFlareConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(anamorphicFlare: updated);
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
                _buildTintSelector(),
                const SizedBox(height: 16),
                _buildSpikesSelector(),
                const SizedBox(height: 16),
                _buildOpticalSliders(),
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
                      color: const Color(0xFF00B4D8).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lens_blur, color: Color(0xFF00B4D8), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Anamorphic Flare Studio', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00B4D8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text('100% OFFLINE • OPTICAL STREAK', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.5)),
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
                    activeColor: const Color(0xFF00B4D8),
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
        color: const Color(0xFF050912),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _config.isEnabled ? Color(_config.tint.colorHex).withOpacity(0.6) : AppColors.border,
          width: 2.0,
        ),
        boxShadow: _config.isEnabled
            ? [
                BoxShadow(
                  color: Color(_config.tint.colorHex).withOpacity(0.18),
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
              painter: _AnamorphicFlarePainter(
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
                          'PANAVISION ANAMORPHIC SIMULATION',
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
                            '${(_config.intensity * 100).toInt()}% BLOOM • ${_config.streakLength.toStringAsFixed(1)}X STRETCH',
                            style: AppTypography.timecode.copyWith(fontSize: 10, color: Color(_config.tint.colorHex)),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TINT: ${_config.tint.label.toUpperCase()}',
                          style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.6), fontFamily: 'Courier'),
                        ),
                        Text(
                          _config.starburstSpikes > 0 ? '${_config.starburstSpikes}-POINT STAR' : 'HORIZONTAL STREAK ONLY',
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
      {'name': 'Hollywood Blue', 'config': AnamorphicFlareConfig.hollywoodBlue, 'icon': '🎬'},
      {'name': 'Golden Hour', 'config': AnamorphicFlareConfig.vintageGoldenHour, 'icon': '🌅'},
      {'name': 'Sci-Fi Laser', 'config': AnamorphicFlareConfig.sciFiLaser, 'icon': '⚡'},
      {'name': 'Subtle Cinema', 'config': AnamorphicFlareConfig.subtleCinema, 'icon': '✨'},
      {'name': 'Starburst Glint', 'config': AnamorphicFlareConfig.starburstGlint, 'icon': '🌟'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cinematic Flare Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final presetConfig = p['config'] as AnamorphicFlareConfig;
              final isSelected = _config.tint == presetConfig.tint &&
                  (_config.streakLength - presetConfig.streakLength).abs() < 0.1 &&
                  _config.starburstSpikes == presetConfig.starburstSpikes;

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
                      color: isSelected ? Color(presetConfig.tint.colorHex).withOpacity(0.2) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Color(presetConfig.tint.colorHex) : AppColors.border,
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

  Widget _buildTintSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Streak Reflection Tint', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FlareTint.values.map((tint) {
            final isSelected = _config.tint == tint;
            final hex = tint.colorHex;

            return InkWell(
              onTap: () {
                _applyConfig(_config.copyWith(tint: tint, isEnabled: true));
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
                      tint.label,
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

  Widget _buildSpikesSelector() {
    final spikeOptions = [
      {'spikes': 0, 'label': 'Streak Only'},
      {'spikes': 4, 'label': '4-Point Cross'},
      {'spikes': 6, 'label': '6-Point Star'},
      {'spikes': 8, 'label': '8-Point Star'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Specular Starburst Spikes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: spikeOptions.map((opt) {
              final spikes = opt['spikes'] as int;
              final isSelected = _config.starburstSpikes == spikes;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(opt['label'] as String),
                  selected: isSelected,
                  selectedColor: Color(_config.tint.colorHex),
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                  onSelected: (sel) {
                    if (sel) {
                      _applyConfig(_config.copyWith(starburstSpikes: spikes));
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

  Widget _buildOpticalSliders() {
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
              const Text('Horizontal Streak Stretch', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${_config.streakLength.toStringAsFixed(1)}x', style: AppTypography.timecode.copyWith(fontSize: 12, color: Color(_config.tint.colorHex))),
            ],
          ),
          Slider(
            value: _config.streakLength,
            min: 1.0,
            max: 10.0,
            divisions: 18,
            activeColor: Color(_config.tint.colorHex),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(streakLength: val, isEnabled: true));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Highlight Threshold', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.threshold * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: Color(_config.tint.colorHex))),
            ],
          ),
          Slider(
            value: _config.threshold,
            min: 0.60,
            max: 0.98,
            divisions: 19,
            activeColor: Color(_config.tint.colorHex),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(threshold: val));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Flare Bloom Intensity', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.intensity * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: Color(_config.tint.colorHex))),
            ],
          ),
          Slider(
            value: _config.intensity,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: Color(_config.tint.colorHex),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(intensity: val, isEnabled: true));
            },
          ),
        ],
      ),
    );
  }
}

class _AnamorphicFlarePainter extends CustomPainter {
  final AnamorphicFlareConfig config;
  final double phase;

  _AnamorphicFlarePainter({
    required this.config,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!config.isActive) return;

    final center = Offset(size.width / 2, size.height / 2);
    final tintColor = Color(config.tint.colorHex);

    // 1. Specular bright core
    final coreRadius = (4.0 * config.intensity).clamp(2.0, 10.0);
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(config.intensity.clamp(0.2, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawCircle(center, coreRadius, corePaint);

    // 2. Horizontal cylindrical anamorphic streak
    final streakHalfWidth = (size.width * 0.45 * (config.streakLength / 5.0)).clamp(20.0, size.width * 0.48);
    final streakHeight = (config.flareThickness * 1.5).clamp(1.0, 12.0);

    final streakRect = Rect.fromCenter(
      center: center,
      width: streakHalfWidth * 2,
      height: streakHeight,
    );

    final streakPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          tintColor.withOpacity((config.intensity * 0.8).clamp(0.1, 0.95)),
          Colors.white,
          tintColor.withOpacity((config.intensity * 0.8).clamp(0.1, 0.95)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(streakRect)
      ..blendMode = BlendMode.screen;

    canvas.drawRect(streakRect, streakPaint);

    // 3. Optional starburst spikes
    if (config.starburstSpikes > 0) {
      final spikeLength = (size.height * 0.35 * config.intensity).clamp(10.0, 60.0);
      final spikePaint = Paint()
        ..color = tintColor.withOpacity((config.intensity * 0.6).clamp(0.1, 0.8))
        ..strokeWidth = 1.2
        ..blendMode = BlendMode.screen;

      final count = config.starburstSpikes;
      final angleStep = math.pi / count;
      for (int i = 0; i < count; i++) {
        final angle = i * angleStep;
        final dx = math.cos(angle) * spikeLength;
        final dy = math.sin(angle) * spikeLength;
        canvas.drawLine(Offset(center.dx - dx, center.dy - dy), Offset(center.dx + dx, center.dy + dy), spikePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnamorphicFlarePainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.phase != phase;
  }
}
