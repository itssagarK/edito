import 'dart:math' as math;
import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/echo_motion_config.dart';
import '../../services/echo_motion_compiler_service.dart';

/// Interactive bottom sheet and docked panel for configuring motion blur
/// and temporal echo decay trails.
class EchoMotionSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const EchoMotionSheet({
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
      builder: (context) => EchoMotionSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<EchoMotionSheet> createState() => _EchoMotionSheetState();
}

class _EchoMotionSheetState extends State<EchoMotionSheet>
    with SingleTickerProviderStateMixin {
  late EchoMotionConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.echoMotion;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }


  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(EchoMotionConfig updated) {
    setState(() => _config = updated);
    final updatedClip = widget.clip.copyWith(echoMotion: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case EchoMotionMode.smoothMotionBlur:
        return const Color(0xFF00E5FF);
      case EchoMotionMode.longExposureGhost:
        return const Color(0xFF7C4DFF);
      case EchoMotionMode.phantomEcho:
        return const Color(0xFFFF4081);
      case EchoMotionMode.lightTrailSmear:
        return const Color(0xFFFFD700);
      case EchoMotionMode.dreamySlowShutter:
        return const Color(0xFF00E676);
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
          child: Icon(Icons.blur_on, color: _accentColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Motion Echo Trails',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _config.isEnabled
                    ? 'Active: ${_config.mode.label} (${_config.trailCount} taps)'
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
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF090910),
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
              painter: _EchoMotionPainter(
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
          'MOTION BLUR MODE',
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
            itemCount: EchoMotionMode.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mode = EchoMotionMode.values[index];
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
      ('Action Blur', EchoMotionConfig.naturalActionBlur),
      ('Light Trails', EchoMotionConfig.neonLightTrails),
      ('Spectral Ghost', EchoMotionConfig.spectralGhost),
      ('Phantom Echo', EchoMotionConfig.multiPhantomEcho),
      ('Slow Shutter', EchoMotionConfig.vintageSlowShutter),
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
          label: 'Decay Persistence',
          value: _config.decay,
          min: 0.1,
          max: 0.98,
          displayValue: '${(_config.decay * 100).toInt()}%',
          onChanged: (val) => _applyConfig(_config.copyWith(decay: val)),
        ),
        _buildSliderTile(
          label: 'Trail Frame Count',
          value: _config.trailCount.toDouble(),
          min: 2,
          max: 12,
          divisions: 10,
          displayValue: '${_config.trailCount} taps',
          onChanged: (val) =>
              _applyConfig(_config.copyWith(trailCount: val.round())),
        ),
        _buildSliderTile(
          label: 'Shutter Angle',
          value: _config.shutterAngle,
          min: 45.0,
          max: 360.0,
          displayValue: '${_config.shutterAngle.toInt()}°',
          onChanged: (val) => _applyConfig(_config.copyWith(shutterAngle: val)),
        ),
        _buildSliderTile(
          label: 'Smear Opacity',
          value: _config.opacity,
          min: 0.0,
          max: 1.0,
          displayValue: '${(_config.opacity * 100).toInt()}%',
          onChanged: (val) => _applyConfig(_config.copyWith(opacity: val)),
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

/// Skia Canvas painter rendering simulated dynamic motion trails and decaying ghost silhouettes.
class _EchoMotionPainter extends CustomPainter {
  final EchoMotionConfig config;
  final double animationProgress;

  _EchoMotionPainter({
    required this.config,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0B0B14);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(12)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (!config.isEnabled) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'MOTION ECHO TRAILS DISABLED',
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

    final trailCount = config.trailCount.clamp(2, 12);
    final decay = config.decay.clamp(0.1, 0.98);
    final primaryColor = switch (config.mode) {
      EchoMotionMode.smoothMotionBlur => const Color(0xFF00E5FF),
      EchoMotionMode.longExposureGhost => const Color(0xFF7C4DFF),
      EchoMotionMode.phantomEcho => const Color(0xFFFF4081),
      EchoMotionMode.lightTrailSmear => const Color(0xFFFFD700),
      EchoMotionMode.dreamySlowShutter => const Color(0xFF00E676),
    };

    for (int i = trailCount; i >= 0; i--) {
      final lagProgress = (animationProgress - (i * 0.04)) % 1.0;
      final t = lagProgress * 2 * math.pi;

      final cx = size.width / 2 + math.sin(t) * (size.width * 0.35);
      final cy = size.height / 2 +
          math.sin(t * 2) * (size.height * 0.28) * math.cos(t * 0.5);

      final alphaFactor = (i == 0)
          ? 1.0
          : (math.pow(decay, i) * config.opacity).clamp(0.05, 0.95);

      final radius = (i == 0) ? 14.0 : (14.0 + (i * 1.5));

      if (i > 0) {
        final ghostPaint = Paint()
          ..color = primaryColor.withAlpha((alphaFactor * 160).toInt())
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, (i * 2.5));
        canvas.drawCircle(Offset(cx, cy), radius, ghostPaint);

        final ghostCorePaint = Paint()
          ..color = primaryColor.withAlpha((alphaFactor * 220).toInt())
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), radius * 0.6, ghostCorePaint);
      } else {
        final leadGlowPaint = Paint()
          ..color = Colors.white.withAlpha(200)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(Offset(cx, cy), 14.0, leadGlowPaint);

        final leadPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), 10.0, leadPaint);

        final strokePaint = Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(Offset(cx, cy), 12.0, strokePaint);
      }
    }

    final badgeText =
        '${config.mode.label.toUpperCase()} • ${config.trailCount} TAPS • ${(config.decay * 100).toInt()}% DECAY';
    final badgePainter = TextPainter(
      text: TextSpan(
        text: badgeText,
        style: TextStyle(
          color: primaryColor,
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
      Paint()..color = Colors.black.withAlpha(180),
    );
    badgePainter.paint(
      canvas,
      Offset(badgeRect.left + 6, badgeRect.top + 3),
    );
  }

  @override
  bool shouldRepaint(covariant _EchoMotionPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.animationProgress != animationProgress;
  }
}
