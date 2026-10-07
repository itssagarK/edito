import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/crt_scanline_config.dart';
import '../../services/crt_scanline_compiler_service.dart';

class CrtScanlineSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const CrtScanlineSheet({
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
      builder: (context) => CrtScanlineSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<CrtScanlineSheet> createState() => _CrtScanlineSheetState();
}

class _CrtScanlineSheetState extends State<CrtScanlineSheet> with SingleTickerProviderStateMixin {
  late CrtScanlineConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.crtScanline;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void disposeValidate() {
    _animController.dispose();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(CrtScanlineConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(crtScanline: updated);
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
                _buildLiveCrtMonitor(),
                const SizedBox(height: 16),
                _buildPresetsSection(),
                const SizedBox(height: 16),
                _buildPhosphorTintSelector(),
                const SizedBox(height: 16),
                _buildRasterControls(),
                const SizedBox(height: 16),
                _buildOpticsAndNoiseControls(),
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
                      color: const Color(0xFF00FF66).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tv, color: Color(0xFF00FF66), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Retro CRT Scanlines Studio', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00FF66),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text('100% OFFLINE • PHOSPHOR RASTER', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.5)),
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
                    activeColor: const Color(0xFF00FF66),
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

  Widget _buildLiveCrtMonitor() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _config.isEnabled ? const Color(0xFF00FF66).withOpacity(0.6) : AppColors.border,
          width: 2.0,
        ),
        boxShadow: _config.isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFF00FF66).withOpacity(0.15),
                  blurRadius: 16,
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
              painter: _CrtScreenPainter(
                config: _config,
                phase: _animController.value,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PVM 20M4U MONITOR',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: _config.phosphorTint.colorHex != null
                            ? Color(_config.phosphorTint.colorHex!)
                            : Colors.white,
                        shadows: [
                          if (_config.phosphorGlow > 0.1)
                            Shadow(
                              color: _config.phosphorTint.colorHex != null
                                  ? Color(_config.phosphorTint.colorHex!).withOpacity(_config.phosphorGlow)
                                  : Colors.white.withOpacity(_config.phosphorGlow),
                              blurRadius: 10,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SCANLINES: ${_config.scanlinePitch.toStringAsFixed(1)}px • ROLLING HUM: ${_config.rollingBarSpeed.toStringAsFixed(1)}x',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 9,
                        letterSpacing: 1.0,
                        color: Colors.white.withOpacity(0.6),
                      ),
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
      {'name': 'Arcade 1984', 'config': CrtScanlineConfig.arcade1984, 'icon': '🕹️'},
      {'name': 'Cyber Terminal', 'config': CrtScanlineConfig.cyberpunkTerminal, 'icon': '👾'},
      {'name': 'VHS Camcorder', 'config': CrtScanlineConfig.vhsCamcorder1995, 'icon': '📼'},
      {'name': 'PVM Broadcast', 'config': CrtScanlineConfig.pvmBroadcast, 'icon': '📺'},
      {'name': 'Security CCTV', 'config': CrtScanlineConfig.securityCctv, 'icon': '📹'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Retro CRT Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final presetConfig = p['config'] as CrtScanlineConfig;
              final isSelected = _config.phosphorTint == presetConfig.phosphorTint &&
                  (_config.scanlinePitch - presetConfig.scanlinePitch).abs() < 0.1;

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
                      color: isSelected ? const Color(0xFF00FF66).withOpacity(0.2) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00FF66) : AppColors.border,
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

  Widget _buildPhosphorTintSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cathode-Ray Phosphor Tint', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CrtPhosphorTint.values.map((tint) {
            final isSelected = _config.phosphorTint == tint;
            final hexColor = tint.colorHex;

            return InkWell(
              onTap: () {
                _applyConfig(_config.copyWith(phosphorTint: tint, isEnabled: true));
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? (hexColor != null ? Color(hexColor).withOpacity(0.2) : AppColors.accent.withOpacity(0.2)) : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? (hexColor != null ? Color(hexColor) : AppColors.accent) : AppColors.border,
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
                        color: hexColor != null ? Color(hexColor) : Colors.white70,
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

  Widget _buildRasterControls() {
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
              const Text('Scanline Spacing / Pitch', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${_config.scanlinePitch.toStringAsFixed(1)} px', style: AppTypography.timecode.copyWith(fontSize: 12, color: const Color(0xFF00FF66))),
            ],
          ),
          Slider(
            value: _config.scanlinePitch,
            min: 2.0,
            max: 12.0,
            divisions: 20,
            activeColor: const Color(0xFF00FF66),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(scanlinePitch: val, isEnabled: true));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Scanline Opacity / Darkness', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.scanlineOpacity * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: const Color(0xFF00FF66))),
            ],
          ),
          Slider(
            value: _config.scanlineOpacity,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: const Color(0xFF00FF66),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(scanlineOpacity: val, isEnabled: true));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rolling Hum Bar Speed', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${_config.rollingBarSpeed.toStringAsFixed(1)}x', style: AppTypography.timecode.copyWith(fontSize: 12, color: const Color(0xFF00FF66))),
            ],
          ),
          Slider(
            value: _config.rollingBarSpeed,
            min: 0.0,
            max: 3.0,
            divisions: 15,
            activeColor: const Color(0xFF00FF66),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(rollingBarSpeed: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOpticsAndNoiseControls() {
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
              const Text('CRT Barrel Curvature / Vignette', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.screenCurvature * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: const Color(0xFF00FF66))),
            ],
          ),
          Slider(
            value: _config.screenCurvature,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: const Color(0xFF00FF66),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(screenCurvature: val));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RGB Chromatic Shadow Offset', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${_config.rgbShadowOffset.toStringAsFixed(1)} px', style: AppTypography.timecode.copyWith(fontSize: 12, color: const Color(0xFF00FF66))),
            ],
          ),
          Slider(
            value: _config.rgbShadowOffset,
            min: 0.0,
            max: 10.0,
            divisions: 20,
            activeColor: const Color(0xFF00FF66),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(rgbShadowOffset: val));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Analog Cathode Noise Grain', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.analogNoise * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: const Color(0xFF00FF66))),
            ],
          ),
          Slider(
            value: _config.analogNoise,
            min: 0.0,
            max: 0.5,
            divisions: 20,
            activeColor: const Color(0xFF00FF66),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(analogNoise: val));
            },
          ),
          const Divider(height: 16, color: AppColors.border),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('60Hz Interlacing Field Flicker', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            subtitle: const Text('Simulates alternating cathode ray electron beam scanning', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            value: _config.interlacingFlicker,
            activeColor: const Color(0xFF00FF66),
            onChanged: (val) {
              _applyConfig(_config.copyWith(interlacingFlicker: val));
            },
          ),
        ],
      ),
    );
  }
}

class _CrtScreenPainter extends CustomPainter {
  final CrtScanlineConfig config;
  final double phase;

  _CrtScreenPainter({
    required this.config,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!config.isActive) return;

    // 1. Phosphor background glow wash
    if (config.phosphorTint.colorHex != null) {
      final tintPaint = Paint()
        ..color = Color(config.phosphorTint.colorHex!).withOpacity(config.phosphorGlow * 0.15)
        ..blendMode = BlendMode.screen;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tintPaint);
    }

    // 2. Horizontal cathode scanlines
    final scanlinePaint = Paint()
      ..color = Colors.black.withOpacity(config.scanlineOpacity.clamp(0.0, 0.95))
      ..strokeWidth = 1.0;

    final pitch = config.scanlinePitch.clamp(2.0, 20.0);
    for (double y = 0; y < size.height; y += pitch) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }

    // 3. Rolling hum bar
    if (config.rollingBarOpacity > 0.02 && config.rollingBarSpeed > 0.0) {
      final barY = (phase * size.height * config.rollingBarSpeed) % size.height;
      final humBarPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(config.rollingBarOpacity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, barY - 20, size.width, 40));

      canvas.drawRect(Rect.fromLTWH(0, barY - 20, size.width, 40), humBarPaint);
    }

    // 4. CRT Corner vignette / barrel falloff
    if (config.screenCurvature > 0.05) {
      final vignettePaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.9 - (config.screenCurvature * 0.3),
          colors: [
            Colors.transparent,
            Colors.black.withOpacity((config.screenCurvature * 0.85).clamp(0.0, 0.95)),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CrtScreenPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.phase != phase;
  }
}
