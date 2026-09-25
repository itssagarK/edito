import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/vocal_isolation_config.dart';
import '../../services/vocal_isolation_compiler_service.dart';

/// CapCut Pro AI Vocal Isolation & Audio Stem Splitter Studio Sheet
class VocalIsolationSheet extends StatefulWidget {
  final VocalIsolationConfig initialConfig;
  final ValueChanged<VocalIsolationConfig> onApply;
  final VoidCallback? onClose;
  final bool isDocked;

  const VocalIsolationSheet({
    super.key,
    required this.initialConfig,
    required this.onApply,
    this.onClose,
    this.isDocked = false,
  });

  @override
  State<VocalIsolationSheet> createState() => _VocalIsolationSheetState();
}

class _VocalIsolationSheetState extends State<VocalIsolationSheet> {
  late VocalIsolationConfig _config;
  bool _isPeekingRaw = false;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  void _updateConfig(VocalIsolationConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onApply(_config);
  }

  void _selectMode(VocalIsolationMode mode) {
    final updated = VocalIsolationConfig.fromMode(mode).copyWith(
      engine: _config.engine,
      speechClarity: _config.speechClarity,
      noiseThreshold: _config.noiseThreshold,
    );
    _updateConfig(updated);
  }

  @override
  Widget build(BuildContext context) {
    final activeConfig = _isPeekingRaw ? const VocalIsolationConfig() : _config;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(20)),
        border: widget.isDocked
            ? const Border(top: BorderSide(color: AppColors.border, width: 1))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            _buildHeaderBar(),

            // Interactive Dual-Stem Spectrum Visualizer
            _buildDualStemVisualizer(activeConfig),

            // Scrollable Controls
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Mode Selection Cards
                  _buildSectionTitle('SEPARATION MODE', Icons.graphic_eq),
                  const SizedBox(height: 8),
                  _buildModeSelector(),

                  if (_config.isEnabled && _config.mode != VocalIsolationMode.none) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('DSP SEPARATION ENGINE', Icons.memory),
                    const SizedBox(height: 8),
                    _buildEngineChips(),

                    const SizedBox(height: 16),
                    _buildSectionTitle('STEM BALANCE & LEVEL CONTROLS', Icons.tune),
                    const SizedBox(height: 8),
                    _buildSlidersSection(),
                  ],

                  const SizedBox(height: 16),
                  _buildRawComparisonButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.record_voice_over, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Vocal Isolation',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _config.isEnabled
                      ? '${_config.mode.label} • ${_config.engine.label}'
                      : 'Disabled (Full Mix)',
                  style: AppTypography.labelSmall.copyWith(
                    color: _config.isEnabled ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_config.isEnabled)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 20),
              tooltip: 'Reset Isolation',
              onPressed: () => _updateConfig(const VocalIsolationConfig()),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
              tooltip: 'Close',
              onPressed: widget.onClose,
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDualStemVisualizer(VocalIsolationConfig config) {
    final isActive = config.isEnabled && config.mode != VocalIsolationMode.none;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.accent.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'VOCAL STEM',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accentGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ACCOMPANIMENT STEM',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: CustomPaint(
              size: const Size(double.infinity, 38),
              painter: _DualStemSpectrumPainter(
                isActive: isActive,
                mode: config.mode,
                vocalGain: config.vocalGain,
                instrumentalGain: config.instrumentalGain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: VocalIsolationMode.values.map((mode) {
        final isSelected = _config.mode == mode;
        return InkWell(
          onTap: () => _selectMode(mode),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getModeIcon(mode),
                  size: 18,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  mode.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getModeIcon(VocalIsolationMode mode) {
    switch (mode) {
      case VocalIsolationMode.none:
        return Icons.volume_up_outlined;
      case VocalIsolationMode.isolateVocals:
        return Icons.person;
      case VocalIsolationMode.removeVocals:
        return Icons.music_note;
      case VocalIsolationMode.voiceBoost:
        return Icons.record_voice_over;
      case VocalIsolationMode.musicBoost:
        return Icons.graphic_eq;
      case VocalIsolationMode.custom:
        return Icons.tune;
    }
  }

  Widget _buildEngineChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: IsolationEngine.values.map((engine) {
        final isSelected = _config.engine == engine;
        return ChoiceChip(
          label: Text(engine.label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              _updateConfig(_config.copyWith(engine: engine));
            }
          },
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surfaceElevated,
          labelStyle: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSlidersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSliderRow(
            label: 'Vocal Stem Gain',
            value: _config.vocalGain,
            min: -24.0,
            max: 12.0,
            formattedValue: '${_config.vocalGain >= 0 ? '+' : ''}${_config.vocalGain.toStringAsFixed(1)} dB',
            onChanged: (val) {
              _updateConfig(_config.copyWith(
                vocalGain: val,
                mode: VocalIsolationMode.custom,
              ));
            },
          ),
          const Divider(color: AppColors.border, height: 16),
          _buildSliderRow(
            label: 'Accompaniment Gain',
            value: _config.instrumentalGain,
            min: -24.0,
            max: 12.0,
            formattedValue: '${_config.instrumentalGain >= 0 ? '+' : ''}${_config.instrumentalGain.toStringAsFixed(1)} dB',
            onChanged: (val) {
              _updateConfig(_config.copyWith(
                instrumentalGain: val,
                mode: VocalIsolationMode.custom,
              ));
            },
          ),
          const Divider(color: AppColors.border, height: 16),
          _buildSliderRow(
            label: 'Speech Clarity Enhancer',
            value: _config.speechClarity,
            min: 0.0,
            max: 1.0,
            formattedValue: '${(_config.speechClarity * 100).round()}%',
            onChanged: (val) {
              _updateConfig(_config.copyWith(
                speechClarity: val,
                mode: VocalIsolationMode.custom,
              ));
            },
          ),
          const Divider(color: AppColors.border, height: 16),
          _buildSliderRow(
            label: 'Noise Gate Floor',
            value: _config.noiseThreshold,
            min: -60.0,
            max: -10.0,
            formattedValue: '${_config.noiseThreshold.toStringAsFixed(0)} dB',
            onChanged: (val) {
              _updateConfig(_config.copyWith(
                noiseThreshold: val,
                mode: VocalIsolationMode.custom,
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String formattedValue,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surfaceHighlight,
              thumbColor: AppColors.accent,
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
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
          width: 55,
          child: Text(
            formattedValue,
            textAlign: TextAlign.right,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRawComparisonButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPeekingRaw = true),
      onTapUp: (_) => setState(() => _isPeekingRaw = false),
      onTapCancel: () => setState(() => _isPeekingRaw = false),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _isPeekingRaw
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isPeekingRaw ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isPeekingRaw ? Icons.hearing : Icons.hearing_outlined,
              size: 18,
              color: _isPeekingRaw ? AppColors.primaryLight : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              _isPeekingRaw ? 'Listening to Raw Full Mix' : 'Hold to Listen to Raw Audio',
              style: AppTypography.labelSmall.copyWith(
                color: _isPeekingRaw ? AppColors.primaryLight : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter rendering simulated dual-stem frequency spectrum bars
class _DualStemSpectrumPainter extends CustomPainter {
  final bool isActive;
  final VocalIsolationMode mode;
  final double vocalGain;
  final double instrumentalGain;

  _DualStemSpectrumPainter({
    required this.isActive,
    required this.mode,
    required this.vocalGain,
    required this.instrumentalGain,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const numBars = 32;
    final barWidth = size.width / (numBars * 1.5);
    final spacing = barWidth * 0.5;

    final vocalPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    final musicPaint = Paint()
      ..color = AppColors.accentGold.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < numBars; i++) {
      final x = i * (barWidth + spacing);
      final freqNorm = i / numBars;

      // Vocal profile centers around 0.3 - 0.7 frequency range
      final vocalProfile = math.exp(-math.pow((freqNorm - 0.45) * 4.0, 2));
      final musicProfile = 0.4 + 0.3 * math.sin(freqNorm * math.pi * 3);

      double vHeight = size.height * vocalProfile * 0.9;
      double mHeight = size.height * musicProfile * 0.8;

      if (isActive) {
        if (mode == VocalIsolationMode.isolateVocals) {
          mHeight *= 0.15;
          vHeight *= 1.15;
        } else if (mode == VocalIsolationMode.removeVocals) {
          vHeight *= 0.10;
          mHeight *= 1.10;
        }
      }

      vHeight = vHeight.clamp(2.0, size.height);
      mHeight = mHeight.clamp(2.0, size.height);

      // Draw instrumental bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - mHeight, barWidth * 0.45, mHeight),
          const Radius.circular(2),
        ),
        musicPaint,
      );

      // Draw vocal bar adjacent
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + (barWidth * 0.5), size.height - vHeight, barWidth * 0.45, vHeight),
          const Radius.circular(2),
        ),
        vocalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DualStemSpectrumPainter oldDelegate) {
    return oldDelegate.isActive != isActive ||
        oldDelegate.mode != mode ||
        oldDelegate.vocalGain != vocalGain ||
        oldDelegate.instrumentalGain != instrumentalGain;
  }
}
