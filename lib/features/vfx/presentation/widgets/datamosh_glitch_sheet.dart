import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/datamosh_glitch_config.dart';
import '../../services/datamosh_glitch_compiler_service.dart';

class DatamoshGlitchSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const DatamoshGlitchSheet({
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
      builder: (context) => DatamoshGlitchSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<DatamoshGlitchSheet> createState() => _DatamoshGlitchSheetState();
}

class _DatamoshGlitchSheetState extends State<DatamoshGlitchSheet> with SingleTickerProviderStateMixin {
  late DatamoshGlitchConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.datamoshGlitch;
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

  void _applyConfig(DatamoshGlitchConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(datamoshGlitch: updated);
    widget.onSave(updatedClip);
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
            color: const Color(0xFF00E5FF).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.electric_bolt_rounded,
            color: Color(0xFF00E5FF),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Datamosh & Compression Glitch',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'I-frame dropout, macroblocks & RGB spectral tears',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: _config.isEnabled,
          activeColor: const Color(0xFF00E5FF),
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
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isActive
              ? const Color(0xFF00E5FF).withOpacity(0.5)
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
                  painter: _DatamoshPainter(
                    config: _config,
                    animationValue: _animController.value,
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.70),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _config.isActive ? const Color(0xFF00E5FF) : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _config.isActive
                          ? DatamoshGlitchCompilerService.getDatamoshBadge(_config)
                          : '⚡ DATAMOSH (BYPASS)',
                      style: AppTypography.caption.copyWith(
                        color: _config.isActive ? const Color(0xFF00E5FF) : Colors.white54,
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
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_config.blockSize.round()}px BLOCKS • ${_config.frequency.toStringAsFixed(1)}x BURSTS',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white70,
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
      {'name': 'Delta Mosh', 'preset': DatamoshGlitchConfig.classicDatamosh},
      {'name': 'RGB Glitch', 'preset': DatamoshGlitchConfig.cyberpunkGlitch},
      {'name': 'Macroblock', 'preset': DatamoshGlitchConfig.extremeCompression},
      {'name': 'VHS Tape Tear', 'preset': DatamoshGlitchConfig.vhsTapeTear},
      {'name': 'Data Decay', 'preset': DatamoshGlitchConfig.fatalDataDecay},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Corruption Presets',
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
              final preset = item['preset'] as DatamoshGlitchConfig;
              final isSelected = _config.isEnabled &&
                  _config.profile == preset.profile &&
                  _config.intensity == preset.intensity;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(item['name'] as String),
                  selected: isSelected,
                  selectedColor: const Color(0xFF00E5FF).withOpacity(0.25),
                  checkmarkColor: const Color(0xFF00E5FF),
                  labelStyle: AppTypography.caption.copyWith(
                    color: isSelected ? const Color(0xFF00E5FF) : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
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

  Widget _buildProfileSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Digital Glitch Engine',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DatamoshProfile.values.map((profile) {
            final isSelected = _config.profile == profile;
            return ChoiceChip(
              label: Text(profile.displayName),
              selected: isSelected,
              selectedColor: const Color(0xFF00E5FF).withOpacity(0.25),
              labelStyle: AppTypography.caption.copyWith(
                color: isSelected ? const Color(0xFF00E5FF) : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
                ),
              ),
              onSelected: (val) {
                if (val) {
                  _applyConfig(_config.copyWith(profile: profile, isEnabled: true));
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          _config.profile.description,
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
            title: 'Glitch Intensity',
            value: _config.intensity,
            min: 0.0,
            max: 1.0,
            displayValue: '${(_config.intensity * 100).round()}%',
            onChanged: (val) {
              _applyConfig(_config.copyWith(intensity: val, isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Burst Frequency',
            value: _config.frequency,
            min: 0.2,
            max: 3.0,
            displayValue: '${_config.frequency.toStringAsFixed(1)}x',
            onChanged: (val) {
              _applyConfig(_config.copyWith(frequency: val, isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Macroblock Size',
            value: _config.blockSize,
            min: 4.0,
            max: 32.0,
            displayValue: '${_config.blockSize.round()}px',
            onChanged: (val) {
              _applyConfig(_config.copyWith(blockSize: val.roundToDouble(), isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Preserve Chroma Channels',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Switch.adaptive(
                value: _config.preserveColor,
                activeColor: const Color(0xFF00E5FF),
                onChanged: (val) {
                  _applyConfig(_config.copyWith(preserveColor: val, isEnabled: true));
                },
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
              activeTrackColor: const Color(0xFF00E5FF),
              thumbColor: const Color(0xFF00E5FF),
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

/// Skia Canvas painter rendering datamosh tears, RGB displacement splits, and macroblock compression artifacts.
class _DatamoshPainter extends CustomPainter {
  final DatamoshGlitchConfig config;
  final double animationValue;

  _DatamoshPainter({
    required this.config,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base dark background
    final bgPaint = Paint()..color = const Color(0xFF0F1218);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subject silhouettes
    final hillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.70)
      ..lineTo(size.width * 0.4, size.height * 0.55)
      ..lineTo(size.width * 0.7, size.height * 0.75)
      ..lineTo(size.width, size.height * 0.65)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hillPath, Paint()..color = const Color(0xFF1E2430));

    if (!config.isActive) return;

    final progress = (animationValue * config.frequency) % 1.0;
    final rand = math.Random((progress * 100).toInt());

    // 2. Horizontal scanline tearing bands
    final numBands = (3 + (config.intensity * 6).round()).clamp(2, 10);
    final maxShift = config.intensity * 28.0;

    for (int i = 0; i < numBands; i++) {
      final bandY = rand.nextDouble() * size.height;
      final bandHeight = 6.0 + rand.nextDouble() * 18.0;
      final shiftX = (rand.nextDouble() - 0.5) * 2 * maxShift;

      // Chromatic RGB displacement
      // Red shift
      final redPaint = Paint()
        ..color = const Color(0xFFFF0055).withOpacity((config.intensity * 0.6).clamp(0.1, 0.8))
        ..blendMode = BlendMode.screen;
      canvas.drawRect(
        Rect.fromLTWH(shiftX + 4, bandY, size.width, bandHeight),
        redPaint,
      );

      // Cyan shift
      final cyanPaint = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity((config.intensity * 0.6).clamp(0.1, 0.8))
        ..blendMode = BlendMode.screen;
      canvas.drawRect(
        Rect.fromLTWH(-shiftX - 4, bandY, size.width, bandHeight),
        cyanPaint,
      );
    }

    // 3. Macroblock quantization blocks
    final block = config.blockSize.clamp(4.0, 32.0);
    final numBlocks = (config.intensity * 14).round();
    final blockPaint = Paint()..style = PaintingStyle.fill;

    for (int j = 0; j < numBlocks; j++) {
      final bx = (rand.nextDouble() * (size.width - block)).floorToDouble();
      final by = (rand.nextDouble() * (size.height - block)).floorToDouble();
      final colorPick = rand.nextInt(3);

      if (colorPick == 0) {
        blockPaint.color = const Color(0xFFFF2A6D).withOpacity(0.5);
      } else if (colorPick == 1) {
        blockPaint.color = const Color(0xFF05D9E8).withOpacity(0.5);
      } else {
        blockPaint.color = Colors.white.withOpacity(0.4);
      }

      canvas.drawRect(Rect.fromLTWH(bx, by, block, block), blockPaint);
    }

    // 4. Bottom VHS tracking sync static bar
    if (config.profile == DatamoshProfile.vhsTrackingLoss) {
      final vhsPaint = Paint()..color = Colors.white.withOpacity(0.35);
      for (double x = 0; x < size.width; x += 4) {
        if (rand.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x, size.height - 10, 3, 10), vhsPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DatamoshPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.animationValue != animationValue;
  }
}
