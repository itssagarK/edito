import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/matrix_rain_config.dart';
import '../../services/matrix_rain_compiler_service.dart';

class MatrixRainSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const MatrixRainSheet({
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
      builder: (context) => MatrixRainSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<MatrixRainSheet> createState() => _MatrixRainSheetState();
}

class _MatrixRainSheetState extends State<MatrixRainSheet> with SingleTickerProviderStateMixin {
  late MatrixRainConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.matrixRain;
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

  void _applyConfig(MatrixRainConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(matrixRain: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case MatrixRainMode.classicPhosphorGreen:
        return const Color(0xFF00FF66); // Terminal phosphor green
      case MatrixRainMode.cyberpunkNeonPink:
        return const Color(0xFFFF007F); // Synthwave hot pink
      case MatrixRainMode.quantumCyanData:
        return const Color(0xFF00E5FF); // Quantum cyan
      case MatrixRainMode.goldenAsciiGold:
        return const Color(0xFFFFD600); // Mainframe gold
      case MatrixRainMode.ghostMonochrome:
        return const Color(0xFFECEFF1); // Silver terminal
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
              Icons.terminal_rounded,
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
                  'Matrix Digital Code Rain',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Cascading cyber code streams & terminal phosphor trails',
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
              tooltip: 'Reset Matrix Rain',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _applyConfig(const MatrixRainConfig()),
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
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF070B0E),
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
                    painter: _MatrixRainPainter(
                      config: _config,
                      accentColor: _accentColor,
                      animationProgress: _animController.value,
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
                      ? '${_config.mode.displayName.toUpperCase()} • ${(_config.density * 100).round()}% DENSITY'
                      : 'MATRIX RAIN BYPASS',
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
                'SPEED: ${_config.fallSpeed.toStringAsFixed(1)}x • GLOW: ${(_config.glyphGlow * 100).round()}%',
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
            _config.isEnabled ? Icons.terminal : Icons.terminal_outlined,
            color: _config.isEnabled ? _accentColor : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Digital Code Rain',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _config.isEnabled
                      ? 'Cascading cyber terminal code cascade active'
                      : 'Bypassed - clean source footage preserved',
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
          'STREAM COLOR SCHEME',
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
          children: MatrixRainMode.values.map((mode) {
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
      {'name': 'Matrix Classic', 'config': MatrixRainConfig.matrixClassic, 'color': const Color(0xFF00FF66)},
      {'name': 'Neon Cyber', 'config': MatrixRainConfig.neonCyber, 'color': const Color(0xFFFF007F)},
      {'name': 'Quantum Cyan', 'config': MatrixRainConfig.quantumStream, 'color': const Color(0xFF00E5FF)},
      {'name': 'Golden Hex', 'config': MatrixRainConfig.goldenHex, 'color': const Color(0xFFFFD600)},
      {'name': 'Ghost Silver', 'config': MatrixRainConfig.ghostCode, 'color': const Color(0xFFECEFF1)},
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
              final presetConfig = p['config'] as MatrixRainConfig;
              final name = p['name'] as String;
              final color = p['color'] as Color;
              final isMatched = _config.mode == presetConfig.mode &&
                  (_config.density - presetConfig.density).abs() < 0.05 &&
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
          'RAIN VELOCITY & DENSITY CONTROLS',
          style: AppTypography.caption.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        // Density
        _buildSlider(
          label: 'Stream Column Density',
          valueText: '${(_config.density * 100).round()}%',
          value: _config.density,
          min: 0.20,
          max: 1.0,
          onChanged: (val) {
            _applyConfig(_config.copyWith(density: val, isEnabled: true));
          },
        ),

        // Fall Speed
        _buildSlider(
          label: 'Cascade Falling Velocity',
          valueText: '${_config.fallSpeed.toStringAsFixed(1)}x',
          value: _config.fallSpeed,
          min: 0.50,
          max: 3.0,
          onChanged: (val) {
            _applyConfig(_config.copyWith(fallSpeed: val, isEnabled: true));
          },
        ),

        // Glyph Glow
        _buildSlider(
          label: 'Phosphor Glow & Bloom',
          valueText: '${(_config.glyphGlow * 100).round()}%',
          value: _config.glyphGlow,
          min: 0.20,
          max: 1.0,
          onChanged: (val) {
            _applyConfig(_config.copyWith(glyphGlow: val, isEnabled: true));
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

/// Skia Canvas painter rendering cascading columns of digital glyph rain
/// with white leading heads and fading phosphor tails.
class _MatrixRainPainter extends CustomPainter {
  final MatrixRainConfig config;
  final Color accentColor;
  final double animationProgress;

  _MatrixRainPainter({
    required this.config,
    required this.accentColor,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final bgPaint = Paint()..color = const Color(0xFF070B0E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (!config.isActive) return;

    final colWidth = 14.0;
    final totalCols = (size.width / colWidth).ceil();
    final activeCols = (totalCols * config.density).round().clamp(6, totalCols);

    final headPaint = Paint()..color = Colors.white.withOpacity(config.opacity);
    final trailPaint = Paint()..style = PaintingStyle.fill;

    for (int col = 0; col < totalCols; col += (totalCols / activeCols).ceil().clamp(1, 4)) {
      final x = col * colWidth;
      // Deterministic pseudo-random seed per column
      final colSeed = (col * 37) % 100 / 100.0;
      final speedMult = 0.7 + colSeed * 0.6;
      final streamProgress = (animationProgress * config.fallSpeed * speedMult + colSeed) % 1.0;
      final headY = streamProgress * (size.height + 60.0) - 20.0;

      // Draw bright white leading head glyph node
      if (headY >= 0 && headY <= size.height) {
        canvas.drawCircle(Offset(x + 5.0, headY), 2.5, headPaint);
      }

      // Draw fading phosphor tail segments
      final tailLength = 8;
      for (int t = 1; t <= tailLength; t++) {
        final nodeY = headY - (t * 8.0);
        if (nodeY >= 0 && nodeY <= size.height) {
          final alpha = ((1.0 - (t / tailLength)) * config.opacity * config.glyphGlow).clamp(0.05, 1.0);
          trailPaint.color = accentColor.withOpacity(alpha);
          canvas.drawRect(
            Rect.fromLTWH(x + 4.0, nodeY, 3.0, 5.0),
            trailPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixRainPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.animationProgress != animationProgress;
  }
}
