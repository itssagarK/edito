import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/bitcrusher_config.dart';
import '../../services/bitcrusher_compiler_service.dart';

class BitcrusherSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const BitcrusherSheet({
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
      builder: (context) => BitcrusherSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<BitcrusherSheet> createState() => _BitcrusherSheetState();
}

class _BitcrusherSheetState extends State<BitcrusherSheet> with SingleTickerProviderStateMixin {
  late BitcrusherConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.bitcrusher;
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

  void _applyConfig(BitcrusherConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(bitcrusher: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case BitcrusherMode.nesChiptune8Bit:
        return const Color(0xFFFF2A6D); // Cyberpunk neon red/pink
      case BitcrusherMode.gameBoyLofi:
        return const Color(0xFF8BAC0F); // Authentic Nintendo DMG LCD olive green
      case BitcrusherMode.arcade16Bit:
        return const Color(0xFF05D9E8); // Arcade neon cyan
      case BitcrusherMode.walkieTalkieRadio:
        return const Color(0xFFFFB000); // Amber radio phosphor
      case BitcrusherMode.extremeDecimator:
        return const Color(0xFFD100D1); // Magenta glitch
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildLiveMonitorCard(),
              const SizedBox(height: 16),
              _buildPresetsRow(),
              const SizedBox(height: 16),
              _buildModeSelector(),
              const SizedBox(height: 16),
              _buildControls(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (widget.isDocked) return content;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: content,
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.videogame_asset_rounded,
            color: _accentColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '8-Bit Lo-Fi Chiptune Crusher',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'Sample rate downsampling & DAC bit-depth quantization',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
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
        if (!widget.isDocked && widget.onDone != null)
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: widget.onDone ?? () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  Widget _buildLiveMonitorCard() {
    return Container(
      width: double.infinity,
      height: 145,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isActive
              ? _accentColor.withOpacity(0.5)
              : AppColors.surfaceVariant,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _BitcrusherPainter(
                    config: _config,
                    animationValue: _animController.value,
                    accentColor: _accentColor,
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _config.isActive ? _accentColor : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _config.isActive
                          ? BitcrusherCompilerService.getBitcrusherBadge(_config)
                          : '👾 8-BIT CRUSHER (BYPASS)',
                      style: AppTypography.caption.copyWith(
                        color: _config.isActive ? _accentColor : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'BRICKWALL CEILING: -0.05dB',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white60,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPresetsRow() {
    final presets = [
      {'name': 'NES 8-Bit', 'preset': BitcrusherConfig.retroNesConsole},
      {'name': 'Game Boy DMG', 'preset': BitcrusherConfig.dmgGameBoy},
      {'name': 'Arcade 16-Bit', 'preset': BitcrusherConfig.arcadeCabinet},
      {'name': 'Walkie Talkie', 'preset': BitcrusherConfig.tacticalRadio},
      {'name': 'Bit Decimator', 'preset': BitcrusherConfig.bitStarvedGlitch},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Retro Hardware Presets',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((item) {
              final preset = item['preset'] as BitcrusherConfig;
              final isSelected = _config.isEnabled &&
                  _config.mode == preset.mode &&
                  _config.bitDepth == preset.bitDepth;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(item['name'] as String),
                  selected: isSelected,
                  selectedColor: _accentColor.withOpacity(0.25),
                  checkmarkColor: _accentColor,
                  labelStyle: AppTypography.caption.copyWith(
                    color: isSelected ? _accentColor : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? _accentColor : Colors.transparent,
                    ),
                  ),
                  onSelected: (val) {
                    _applyConfig(preset);
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
          'Hardware Emulation Engine',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BitcrusherMode.values.map((mode) {
            final isSelected = _config.mode == mode;
            return ChoiceChip(
              label: Text(mode.displayName),
              selected: isSelected,
              selectedColor: _accentColor.withOpacity(0.25),
              labelStyle: AppTypography.caption.copyWith(
                color: isSelected ? _accentColor : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? _accentColor : Colors.transparent,
                ),
              ),
              onSelected: (val) {
                if (val) {
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
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSlider(
            title: 'Sample Rate',
            value: _config.sampleRateKhz,
            min: 3.0,
            max: 22.0,
            displayValue: '${_config.sampleRateKhz.toStringAsFixed(1)} kHz',
            onChanged: (val) {
              _applyConfig(_config.copyWith(sampleRateKhz: val, isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Quantization Depth',
            value: _config.bitDepth.toDouble(),
            min: 2.0,
            max: 12.0,
            displayValue: '${_config.bitDepth}-bit',
            onChanged: (val) {
              _applyConfig(_config.copyWith(bitDepth: val.round(), isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Drive / Overdrive',
            value: _config.drive,
            min: 0.0,
            max: 1.0,
            displayValue: '+${(_config.drive * 100).round()}%',
            onChanged: (val) {
              _applyConfig(_config.copyWith(drive: val, isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Wet / Dry Mix',
            value: _config.mix,
            min: 0.0,
            max: 1.0,
            displayValue: '${(_config.mix * 100).round()}%',
            onChanged: (val) {
              _applyConfig(_config.copyWith(mix: val, isEnabled: true));
            },
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
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
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
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            displayValue,
            textAlign: TextAlign.end,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Skia Canvas painter rendering retro 8-bit quantized audio waveforms and CRT arcade grid.
class _BitcrusherPainter extends CustomPainter {
  final BitcrusherConfig config;
  final double animationValue;
  final Color accentColor;

  _BitcrusherPainter({
    required this.config,
    required this.animationValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw retro CRT background
    final bgPaint = Paint()..color = const Color(0xFF0C0E14);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle arcade coordinate grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (!config.isActive) return;

    // 2. Center zero line
    final midY = size.height * 0.55;
    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), axisPaint);

    // 3. Quantized stepped staircase waveform
    // Quantization step count based on bit depth (2-12 bits -> 4 to 64 visual quantization steps)
    final quantLevels = math.pow(2, config.bitDepth.clamp(2, 6)).toDouble();
    // Sample step width based on sample rate (lower sample rate = larger block steps)
    final stepWidth = (24.0 - config.sampleRateKhz).clamp(4.0, 20.0);

    final wavePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = accentColor.withOpacity(0.20)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path()..moveTo(0, midY);

    bool first = true;
    for (double x = 0; x < size.width; x += stepWidth) {
      // Audio sine waveform combined with harmonics and drive
      final t = (x / size.width * 4 * math.pi) + (animationValue * 4 * math.pi);
      double rawAmp = math.sin(t) * 0.7 + math.sin(t * 2.3) * 0.25;
      if (config.drive > 0) {
        rawAmp = (rawAmp * (1.0 + config.drive * 1.5)).clamp(-1.0, 1.0);
      }

      // Quantize amplitude to discrete steps
      final quantizedAmp = (rawAmp * (quantLevels / 2)).round() / (quantLevels / 2);
      final y = midY - quantizedAmp * (size.height * 0.35);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
      path.lineTo(x + stepWidth, y);

      fillPath.lineTo(x, y);
      fillPath.lineTo(x + stepWidth, y);
    }

    fillPath.lineTo(size.width, midY);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, wavePaint);

    // 4. CRT scanline raster
    final scanlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BitcrusherPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.accentColor != accentColor;
  }
}
