import 'dart:math' as math;
import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/multiband_compressor_config.dart';
import '../../services/multiband_compressor_compiler_service.dart';

/// Interactive bottom sheet and docked panel for configuring 3-band studio
/// audio master compression and dynamic control.
class MultibandCompressorSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const MultibandCompressorSheet({
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
      builder: (context) => MultibandCompressorSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<MultibandCompressorSheet> createState() => _MultibandCompressorSheetState();
}

class _MultibandCompressorSheetState extends State<MultibandCompressorSheet>
    with SingleTickerProviderStateMixin {
  late MultibandCompressorConfig _config;
  late AnimationController _animController;
  bool _isAuditionBypass = false;
  int _activeBandTab = 0; // 0: Low, 1: Mid, 2: High, 3: Master

  @override
  void initState() {
    super.initState();
    _config = widget.clip.multibandCompressor;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(MultibandCompressorConfig updated) {
    setState(() => _config = updated);
    final updatedClip = widget.clip.copyWith(multibandCompressor: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case MultibandCompressorMode.transparentMaster:
        return const Color(0xFF00E5FF);
      case MultibandCompressorMode.punchyClub808:
        return const Color(0xFFFF5252);
      case MultibandCompressorMode.vocalPresenceRadio:
        return const Color(0xFFFFD700);
      case MultibandCompressorMode.warmTapeSaturate:
        return const Color(0xFFFF9100);
      case MultibandCompressorMode.heavyGlueMix:
        return const Color(0xFFE040FB);
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
                    _buildPreviewMonitorCard(),
                    const SizedBox(height: 16),
                    _buildModeSelector(),
                    const SizedBox(height: 16),
                    _buildPresetsCarousel(),
                    const SizedBox(height: 16),
                    _buildBandTabBar(),
                    const SizedBox(height: 14),
                    _buildActiveBandControls(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceElevated, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.tune_outlined, color: _accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3-Band Master Compressor',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _config.isActive
                      ? '${_config.mode.label} • 3-Band Active'
                      : 'Disabled',
                  style: AppTypography.labelSmall.copyWith(
                    color: _config.isActive ? _accentColor : AppColors.textMuted,
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
          if (!widget.isDocked && widget.onDone != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.textPrimary),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                padding: const EdgeInsets.all(8),
              ),
              onPressed: widget.onDone,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewMonitorCard() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _config.isActive ? _accentColor.withOpacity(0.5) : AppColors.surfaceElevated,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _MultibandCompressorPainter(
                      config: _isAuditionBypass ? MultibandCompressorConfig.defaultDisabled : _config,
                      phase: _animController.value,
                      accentColor: _accentColor,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  const MultibandCompressorCompilerService().getCompressorBadge(_config),
                  style: AppTypography.labelSmall.copyWith(
                    color: _accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isAuditionBypass = true),
                onTapUp: (_) => setState(() => _isAuditionBypass = false),
                onTapCancel: () => setState(() => _isAuditionBypass = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isAuditionBypass ? _accentColor : AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'HOLD A/B',
                    style: AppTypography.labelSmall.copyWith(
                      color: _isAuditionBypass ? Colors.black : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MASTER PROFILE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: MultibandCompressorMode.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mode = MultibandCompressorMode.values[index];
              final isSelected = _config.mode == mode;
              return ChoiceChip(
                label: Text(mode.label),
                selected: isSelected,
                selectedColor: _accentColor.withOpacity(0.25),
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: AppTypography.labelMedium.copyWith(
                  color: isSelected ? _accentColor : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? _accentColor : Colors.transparent,
                    width: 1.2,
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

  Widget _buildPresetsCarousel() {
    final presets = [
      ('Transparent Master', MultibandCompressorConfig.presetTransparentMaster, Icons.tune),
      ('Punchy Club 808', MultibandCompressorConfig.presetPunchyClub808, Icons.speaker),
      ('Vocal Radio', MultibandCompressorConfig.presetVocalPresence, Icons.mic),
      ('Warm Tape Glue', MultibandCompressorConfig.presetWarmTapeSaturate, Icons.album),
      ('Heavy Master Glue', MultibandCompressorConfig.presetHeavyGlueMix, Icons.compress),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURATED PRESETS',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final (name, preset, icon) = presets[index];
              final isSelected = _config.mode == preset.mode &&
                  (_config.lowThresholdDb - preset.lowThresholdDb).abs() < 0.1;

              return InkWell(
                onTap: () => _applyConfig(preset),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 126,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? _accentColor.withOpacity(0.15) : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? _accentColor : Colors.white.withOpacity(0.06),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: isSelected ? _accentColor : AppColors.textSecondary, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? _accentColor : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBandTabBar() {
    final tabs = [
      ('LOW (<${_config.crossoverLowHz.round()}Hz)', 0),
      ('MID', 1),
      ('HIGH (>${_config.crossoverHighHz.round()}Hz)', 2),
      ('MASTER', 3),
    ];

    return Row(
      children: tabs.map((t) {
        final isSelected = _activeBandTab == t.$2;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeBandTab = t.$2),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected ? _accentColor.withOpacity(0.2) : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? _accentColor : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Text(
                  t.$1,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? _accentColor : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveBandControls() {
    switch (_activeBandTab) {
      case 0:
        // Low Band
        return Column(
          children: [
            _buildSliderRow(
              label: 'Low Threshold',
              value: _config.lowThresholdDb,
              min: -40.0,
              max: 0.0,
              displayValue: '${_config.lowThresholdDb.toStringAsFixed(1)} dB',
              onChanged: (val) => _applyConfig(_config.copyWith(lowThresholdDb: val, isEnabled: true)),
            ),
            _buildSliderRow(
              label: 'Low Ratio',
              value: _config.lowRatio,
              min: 1.0,
              max: 20.0,
              displayValue: '${_config.lowRatio.toStringAsFixed(1)}:1',
              onChanged: (val) => _applyConfig(_config.copyWith(lowRatio: val, isEnabled: true)),
            ),
            _buildSliderRow(
              label: 'Low Makeup Gain',
              value: _config.lowGainDb,
              min: -12.0,
              max: 12.0,
              displayValue: '${_config.lowGainDb >= 0 ? '+' : ''}${_config.lowGainDb.toStringAsFixed(1)} dB',
              onChanged: (val) => _applyConfig(_config.copyWith(lowGainDb: val, isEnabled: true)),
            ),
            _buildSliderRow(
              label: 'Low Crossover Frequency',
              value: _config.crossoverLowHz,
              min: 80.0,
              max: 400.0,
              displayValue: '${_config.crossoverLowHz.round()} Hz',
              onChanged: (val) => _applyConfig(_config.copyWith(crossoverLowHz: val, isEnabled: true)),
            ),
          ],
        );

      case 1:
        // Mid Band
        return Column(
          children: [
            _buildSliderRow(
              label: 'Mid Threshold',
              value: _config.midThresholdDb,
              min: -40.0,
              max: 0.0,
              displayValue: '${_config.midThresholdDb.toStringAsFixed(1)} dB',
              onChanged: (val) => _applyConfig(_config.copyWith(midThresholdDb: val, isEnabled: true)),
            ),
            _buildSliderRow(
              label: 'Mid Ratio',
              value: _config.midRatio,
              min: 1.0,
              max: 20.0,
              displayValue: '${_config.midRatio.toStringAsFixed(1)}:1',
              onChanged: (val) => _applyConfig(_config.copyWith(midRatio: val, isEnabled: true)),
            ),
            _buildSliderRow(
              label: 'Mid Makeup Gain',
              value: _config.midGainDb,
              min: -12.0,
              max: 12.0,
              displayValue: '${_config.midGainDb >= 0 ? '+' : ''}${_config.midGainDb.toStringAsFixed(1)} dB',
              onChanged: (val) => _applyConfig(_config.copyWith(midGainDb: val, isEnabled: true)),
            ),
          ],
        );

      case 2:
        // High Band
        return Column(
          children: [
            _buildSliderRow(
              label: 'High Threshold',
              value: _config.highThresholdDb,
              min: -40.0,
              max: 0.0,
              displayValue: '${_config.highThresholdDb.toStringAsFixed(1)} dB',
              onChanged: (val) => _applyConfig(_config.copyWith(highThresholdDb: val, isEnabled: true)),
            ),
            _buildSliderRow(
              label: 'High Ratio',
              value: _config.highRatio,
              min: 1.0,
              max: 20.0,
              displayValue: '${_config.highRatio.toStringAsFixed(1)}:1',
              onChanged: (val) => _applyConfig(_config.copyWith(highRatio: val, isEnabled: true)),
            ),
            _buildSliderRow(
              label: 'High Makeup Gain',
              value: _config.highGainDb,
              min: -12.0,
              max: 12.0,
              displayValue: '${_config.highGainDb >= 0 ? '+' : ''}${_config.highGainDb.toStringAsFixed(1)} dB',
              onChanged: (val) => _applyConfig(_config.copyWith(highGainDb: val, isEnabled: true)),
            ),
            _buildSliderRow(
              label: 'High Crossover Frequency',
              value: _config.crossoverHighHz,
              min: 2000.0,
              max: 8000.0,
              displayValue: '${_config.crossoverHighHz.round()} Hz',
              onChanged: (val) => _applyConfig(_config.copyWith(crossoverHighHz: val, isEnabled: true)),
            ),
          ],
        );

      case 3:
      default:
        // Master Dynamics
        return Column(
          children: [
            _buildSliderRow(
              label: 'Master Output Gain',
              value: _config.masterGainDb,
              min: -12.0,
              max: 12.0,
              displayValue: '${_config.masterGainDb >= 0 ? '+' : ''}${_config.masterGainDb.toStringAsFixed(1)} dB',
              onChanged: (val) => _applyConfig(_config.copyWith(masterGainDb: val, isEnabled: true)),
            ),
            _buildSliderRow(
              label: 'Attack Time',
              value: _config.attackMs,
              min: 1.0,
              max: 100.0,
              displayValue: '${_config.attackMs.toStringAsFixed(1)} ms',
              onChanged: (val) => _applyConfig(_config.copyWith(attackMs: val, isEnabled: true)),
            ),
            _buildSliderRow(
              label: 'Release Time',
              value: _config.releaseMs,
              min: 20.0,
              max: 1000.0,
              displayValue: '${_config.releaseMs.round()} ms',
              onChanged: (val) => _applyConfig(_config.copyWith(releaseMs: val, isEnabled: true)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'True-Peak Brickwall Limiter Active (Ceiling: -0.05 dBFS, 0.95)',
                      style: AppTypography.labelSmall.copyWith(color: Colors.greenAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildSliderRow({
    required String label,
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
            Text(label, style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
            Text(
              displayValue,
              style: AppTypography.labelMedium.copyWith(
                color: _accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _accentColor,
            inactiveTrackColor: AppColors.surfaceElevated,
            thumbColor: _accentColor,
            overlayColor: _accentColor.withOpacity(0.15),
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

/// Skia Canvas painter rendering 3-band spectrum analyzer, animated bouncing
/// RMS level meters, and dynamic gain reduction (GR) meters.
class _MultibandCompressorPainter extends CustomPainter {
  final MultibandCompressorConfig config;
  final double phase; // 0.0 to 1.0
  final Color accentColor;

  _MultibandCompressorPainter({
    required this.config,
    required this.phase,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Background grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (!config.isActive) return;

    final bandWidth = size.width / 3.0;

    // Draw 3 Bands: 0: Low, 1: Mid, 2: High
    final bands = [
      ('LOW', config.lowGainDb, config.lowThresholdDb, config.lowRatio, const Color(0xFF00E5FF)),
      ('MID', config.midGainDb, config.midThresholdDb, config.midRatio, const Color(0xFFFFD700)),
      ('HIGH', config.highGainDb, config.highThresholdDb, config.highRatio, const Color(0xFFFF4081)),
    ];

    for (int i = 0; i < 3; i++) {
      final (bandLabel, gain, thresh, ratio, bandColor) = bands[i];
      final x0 = i * bandWidth;

      // Divider line
      if (i > 0) {
        final divPaint = Paint()
          ..color = Colors.white.withOpacity(0.12)
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(x0, 0), Offset(x0, size.height), divPaint);
      }

      // Band Label
      final tp = TextPainter(
        text: TextSpan(
          text: bandLabel,
          style: TextStyle(
            color: bandColor.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x0 + 8, 8));

      // Animated RMS Input Level Bar (bounces with phase)
      final rmsFactor = math.sin((phase * 2 * math.pi * 2.0) + i * 1.5).abs();
      final rmsHeight = (0.2 + rmsFactor * 0.6) * (size.height - 40);

      final barRect = Rect.fromLTWH(
        x0 + 12,
        size.height - 12 - rmsHeight,
        bandWidth * 0.35,
        rmsHeight,
      );

      final rmsShader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF00E676),
          const Color(0xFFFFEA00),
          const Color(0xFFFF1744),
        ],
        stops: const [0.6, 0.85, 1.0],
      ).createShader(barRect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
        Paint()..shader = rmsShader,
      );

      // Gain Reduction (GR) Meter (dips down from top)
      final grFactor = math.max(0.0, (rmsFactor - (thresh.abs() / 40.0))) * (ratio / 5.0);
      final grHeight = (grFactor * 45.0).clamp(0.0, size.height - 50);

      final grRect = Rect.fromLTWH(
        x0 + bandWidth * 0.55,
        30,
        bandWidth * 0.28,
        grHeight,
      );

      final grPaint = Paint()
        ..color = const Color(0xFFFF5252).withOpacity(0.85)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(grRect, const Radius.circular(2)),
        grPaint,
      );

      // GR Tag
      final grText = TextPainter(
        text: TextSpan(
          text: grHeight > 2 ? '-${(grHeight / 3).toStringAsFixed(0)}dB' : '0dB',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      grText.paint(canvas, Offset(x0 + bandWidth * 0.55, 14));
    }
  }

  @override
  bool shouldRepaint(covariant _MultibandCompressorPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.phase != phase ||
        oldDelegate.accentColor != accentColor;
  }
}
