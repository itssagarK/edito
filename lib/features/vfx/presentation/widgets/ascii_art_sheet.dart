import 'dart:math' as math;
import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/ascii_art_config.dart';
import '../../services/ascii_art_compiler_service.dart';

/// Interactive bottom sheet and docked panel for configuring ASCII terminal
/// character matrix texturization.
class AsciiArtSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const AsciiArtSheet({
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
      builder: (context) => AsciiArtSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<AsciiArtSheet> createState() => _AsciiArtSheetState();
}

class _AsciiArtSheetState extends State<AsciiArtSheet>
    with SingleTickerProviderStateMixin {
  late AsciiArtConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.asciiArt;
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

  void _applyConfig(AsciiArtConfig updated) {
    setState(() => _config = updated);
    final updatedClip = widget.clip.copyWith(asciiArt: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case AsciiArtMode.greenPhosphor:
        return const Color(0xFF00FF66);
      case AsciiArtMode.amberCathode:
        return const Color(0xFFFFB000);
      case AsciiArtMode.cyberpunkNeon:
        return const Color(0xFF00E5FF);
      case AsciiArtMode.matrixColor:
        return const Color(0xFFFF4081);
      case AsciiArtMode.monochromePaper:
        return const Color(0xFFECEFF1);
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isDocked) _buildDragHandle(),
              _buildHeader(),
              const SizedBox(height: 12),
              _buildCanvasMonitor(),
              const SizedBox(height: 16),
              _buildModeSelector(),
              const SizedBox(height: 16),
              _buildPresetsRow(),
              const SizedBox(height: 16),
              _buildSliders(),
            ],
          ),
        ),
      ),
    );

    return content;
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accentColor.withAlpha(38),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.terminal, color: _accentColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ASCII Terminal Matrix',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _config.isEnabled
                    ? 'Active: ${_config.mode.label} (${_config.cellSize}px cells)'
                    : 'Disabled • Tap toggle to activate',
                style: TextStyle(
                  color: _config.isEnabled ? _accentColor : Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _config.isEnabled,
          activeColor: _accentColor,
          onChanged: (val) => _applyConfig(_config.copyWith(isEnabled: val)),
        ),
        if (!widget.isDocked && widget.onDone != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(36, 36),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDone?.call();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCanvasMonitor() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF050805),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _config.isEnabled ? _accentColor.withAlpha(100) : Colors.white12,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return CustomPaint(
              painter: _AsciiArtPainter(
                config: _config,
                animationProgress: _animController.value,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TERMINAL CONSOLE MODE',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AsciiArtMode.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mode = AsciiArtMode.values[index];
              final isSelected = _config.mode == mode;
              return ChoiceChip(
                label: Text(mode.label),
                selected: isSelected,
                selectedColor: _accentColor,
                backgroundColor: const Color(0xFF20202E),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildPresetsRow() {
    final presets = [
      ('VT100 Green', AsciiArtConfig.classicGreenTerminal),
      ('Amber CRT', AsciiArtConfig.vintageAmberCathode),
      ('Cyberpunk', AsciiArtConfig.cyberpunkConsole),
      ('ANSI Color', AsciiArtConfig.colorAnsiMatrix),
      ('Paper Print', AsciiArtConfig.monochromePrintout),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRESETS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = presets[index];
              return ActionChip(
                backgroundColor: const Color(0xFF20202E),
                side: BorderSide(
                  color: _accentColor.withAlpha(50),
                ),
                label: Text(
                  preset.$1,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                onPressed: () => _applyConfig(preset.$2),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderTile(
          label: 'Grid Cell Size',
          value: _config.cellSize.toDouble(),
          min: 4,
          max: 20,
          divisions: 16,
          displayValue: '${_config.cellSize} px',
          onChanged: (val) =>
              _applyConfig(_config.copyWith(cellSize: val.round())),
        ),
        _buildSliderTile(
          label: 'Character Density',
          value: _config.characterDensity,
          min: 0.2,
          max: 1.0,
          displayValue: '${(_config.characterDensity * 100).toInt()}%',
          onChanged: (val) =>
              _applyConfig(_config.copyWith(characterDensity: val)),
        ),
        _buildSliderTile(
          label: 'Luminance Contrast',
          value: _config.contrast,
          min: 0.5,
          max: 2.5,
          displayValue: '${_config.contrast.toStringAsFixed(1)}x',
          onChanged: (val) => _applyConfig(_config.copyWith(contrast: val)),
        ),
        _buildSliderTile(
          label: 'Phosphor Glow',
          value: _config.glyphGlow,
          min: 0.0,
          max: 1.0,
          displayValue: '${(_config.glyphGlow * 100).toInt()}%',
          onChanged: (val) => _applyConfig(_config.copyWith(glyphGlow: val)),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Invert Character Ramp',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Switch(
              value: _config.isInverted,
              activeColor: _accentColor,
              onChanged: _config.isEnabled
                  ? (val) => _applyConfig(_config.copyWith(isInverted: val))
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
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
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              displayValue,
              style: TextStyle(
                color: _accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _accentColor,
            inactiveTrackColor: Colors.white12,
            thumbColor: _accentColor,
            overlayColor: _accentColor.withAlpha(38),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: _config.isEnabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}

/// Skia Canvas painter rendering a simulated real-time procedural ASCII glyph grid.
class _AsciiArtPainter extends CustomPainter {
  final AsciiArtConfig config;
  final double animationProgress;

  static const String _ramp = '@%#*+=-:. ';

  _AsciiArtPainter({
    required this.config,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgColor = (config.mode == AsciiArtMode.monochromePaper)
        ? const Color(0xFFE8E5D8)
        : const Color(0xFF040604);
    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);

    if (!config.isEnabled) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'ASCII MATRIX DISABLED',
          style: TextStyle(
            color: Colors.white24,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
      return;
    }

    final cell = config.cellSize.clamp(6, 18).toDouble();
    final cols = (size.width / cell).floor();
    final rows = (size.height / cell).floor();

    final t = animationProgress * 2 * math.pi;
    final focalX = (size.width / 2) + math.sin(t) * (size.width * 0.3);
    final focalY = (size.height / 2) + math.cos(t) * (size.height * 0.25);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final px = c * cell + cell / 2;
        final py = r * cell + cell / 2;

        final dist = math.sqrt(math.pow(px - focalX, 2) + math.pow(py - focalY, 2));
        final normDist = (dist / (size.width * 0.45)).clamp(0.0, 1.0);
        double luma = 1.0 - normDist;

        luma = math.pow(luma, config.contrast).toDouble().clamp(0.0, 1.0);

        if (config.isInverted) {
          luma = 1.0 - luma;
        }

        final charIndex = ((1.0 - luma) * (_ramp.length - 1)).clamp(0, _ramp.length - 1).round();
        final char = _ramp[charIndex];

        final glyphColor = _resolveColor(luma, px, py, size);

        final textPainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              color: glyphColor,
              fontSize: cell * 0.95,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(c * cell, r * cell),
        );
      }
    }

    final badgeText =
        '${config.mode.label.toUpperCase()} • ${config.cellSize}PX • CONTRAST ${config.contrast.toStringAsFixed(1)}X';
    final badgePainter = TextPainter(
      text: TextSpan(
        text: badgeText,
        style: TextStyle(
          color: (config.mode == AsciiArtMode.monochromePaper)
              ? Colors.black87
              : const Color(0xFF00FF66),
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeRect = Rect.fromLTWH(
      8,
      size.height - badgePainter.height - 12,
      badgePainter.width + 12,
      badgePainter.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
      Paint()
        ..color = (config.mode == AsciiArtMode.monochromePaper)
            ? Colors.white.withAlpha(200)
            : Colors.black.withAlpha(200),
    );
    badgePainter.paint(
      canvas,
      Offset(badgeRect.left + 6, badgeRect.top + 3),
    );
  }

  Color _resolveColor(double luma, double px, double py, Size size) {
    final alpha = (luma * 255).clamp(40, 255).toInt();
    switch (config.mode) {
      case AsciiArtMode.greenPhosphor:
        return Color.fromARGB(alpha, 0, 255, 102);

      case AsciiArtMode.amberCathode:
        return Color.fromARGB(alpha, 255, 176, 0);

      case AsciiArtMode.cyberpunkNeon:
        final ratio = (px / size.width).clamp(0.0, 1.0);
        final r = (255 * (1.0 - ratio)).toInt();
        final b = (255 * ratio).toInt();
        return Color.fromARGB(alpha, r, 220, b);

      case AsciiArtMode.matrixColor:
        final hue = ((px / size.width) * 360).clamp(0.0, 360.0);
        return HSVColor.fromAHSV(luma.clamp(0.2, 1.0), hue, 0.85, 1.0).toColor();

      case AsciiArtMode.monochromePaper:
        final darkVal = ((1.0 - luma) * 220).clamp(0, 220).toInt();
        return Color.fromARGB(255, darkVal, darkVal, darkVal);
    }
  }

  @override
  bool shouldRepaint(covariant _AsciiArtPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.animationProgress != animationProgress;
  }
}
