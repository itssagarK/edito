import 'dart:math' as math;
import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/audio_fade_config.dart';

class AudioFadeSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const AudioFadeSheet({
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
      barrierColor: Colors.black.withOpacity(0.20),
      backgroundColor: Colors.transparent,
      builder: (context) => AudioFadeSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<AudioFadeSheet> createState() => _AudioFadeSheetState();
}

class _AudioFadeSheetState extends State<AudioFadeSheet> {
  late AudioFadeConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.audioFade;
  }

  void _apply(AudioFadeConfig newConfig) {
    setState(() => _config = newConfig);
    widget.onSave(widget.clip.copyWith(audioFade: newConfig));
  }

  @override
  Widget build(BuildContext context) {
    final maxAllowedFadeSec = ((widget.clip.durationMs / 2000.0).clamp(0.5, 5.0));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isDocked) ...[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
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
                        const Icon(Icons.volume_up, color: AppColors.accent, size: 22),
                        const SizedBox(width: 8),
                        Text('Audio Fade Studio', style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: widget.onDone ?? () => Navigator.pop(context),
                      style: IconButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(28, 28)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Visual Volume Envelope Curve Graph
              Container(
                height: 74,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: CustomPaint(
                  painter: _AudioFadeEnvelopePainter(
                    fadeInDurationMs: _config.fadeInDurationMs,
                    fadeOutDurationMs: _config.fadeOutDurationMs,
                    clipDurationMs: widget.clip.durationMs > 0 ? widget.clip.durationMs : 4000,
                    curve: _config.curve,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Fade In Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Fade In (Seconds)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                    '${(_config.fadeInDurationMs / 1000.0).toStringAsFixed(2)}s',
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              Slider(
                value: (_config.fadeInDurationMs / 1000.0).clamp(0.0, maxAllowedFadeSec),
                min: 0.0,
                max: maxAllowedFadeSec,
                divisions: (maxAllowedFadeSec * 20).round(),
                activeColor: AppColors.accent,
                onChanged: (v) {
                  _apply(_config.copyWith(fadeInDurationMs: (v * 1000).round()));
                },
              ),

              // Fade Out Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Fade Out (Seconds)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                    '${(_config.fadeOutDurationMs / 1000.0).toStringAsFixed(2)}s',
                    style: const TextStyle(color: Color(0xFFFF2A6D), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              Slider(
                value: (_config.fadeOutDurationMs / 1000.0).clamp(0.0, maxAllowedFadeSec),
                min: 0.0,
                max: maxAllowedFadeSec,
                divisions: (maxAllowedFadeSec * 20).round(),
                activeColor: const Color(0xFFFF2A6D),
                onChanged: (v) {
                  _apply(_config.copyWith(fadeOutDurationMs: (v * 1000).round()));
                },
              ),
              const SizedBox(height: 6),

              // Curve Shape Selector
              const Text('Fade Transition Curve', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AudioFadeCurve.values.map((c) {
                  final isSel = _config.curve == c;
                  return ChoiceChip(
                    label: Text(c.label),
                    selected: isSel,
                    onSelected: (_) => _apply(_config.copyWith(curve: c)),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Fast Presets
              const Text('Quick Fade Presets', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPresetButton('Anti-Pop (0.1s)', 100, 100),
                  const SizedBox(width: 8),
                  _buildPresetButton('Intro (1.0s)', 1000, 0),
                  const SizedBox(width: 8),
                  _buildPresetButton('Outro (2.0s)', 0, 2000),
                  const SizedBox(width: 8),
                  _buildPresetButton('Reset (0s)', 0, 0),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, int inMs, int outMs) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          _apply(_config.copyWith(fadeInDurationMs: inMs, fadeOutDurationMs: outMs));
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ),
    );
  }
}

class _AudioFadeEnvelopePainter extends CustomPainter {
  final int fadeInDurationMs;
  final int fadeOutDurationMs;
  final int clipDurationMs;
  final AudioFadeCurve curve;

  _AudioFadeEnvelopePainter({
    required this.fadeInDurationMs,
    required this.fadeOutDurationMs,
    required this.clipDurationMs,
    required this.curve,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)), bgPaint);

    final totalMs = clipDurationMs > 0 ? clipDurationMs : 4000;
    final inRatio = (fadeInDurationMs / totalMs).clamp(0.0, 0.5);
    final outRatio = (fadeOutDurationMs / totalMs).clamp(0.0, 0.5);

    final path = Path();
    final inW = size.width * inRatio;
    final outW = size.width * outRatio;
    final topY = 12.0;
    final bottomY = size.height - 12.0;

    // Start at bottom left
    path.moveTo(0, bottomY);

    // Fade-in curve
    if (inW > 0) {
      for (double x = 0; x <= inW; x += 2.0) {
        final p = (x / inW).clamp(0.0, 1.0);
        final factor = _evaluateCurve(p);
        final y = bottomY - factor * (bottomY - topY);
        path.lineTo(x, y);
      }
    } else {
      path.lineTo(0, topY);
    }

    // Sustain Plateau
    final sustainEndX = size.width - outW;
    path.lineTo(sustainEndX, topY);

    // Fade-out curve
    if (outW > 0) {
      for (double x = sustainEndX; x <= size.width; x += 2.0) {
        final p = ((x - sustainEndX) / outW).clamp(0.0, 1.0);
        final factor = 1.0 - _evaluateCurve(p);
        final y = bottomY - factor * (bottomY - topY);
        path.lineTo(x, y);
      }
    } else {
      path.lineTo(size.width, topY);
    }

    path.lineTo(size.width, bottomY);
    path.close();

    // Fill with gradient
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.accent, AppColors.primary, Color(0xFFFF2A6D)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Stroke outline
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, strokePaint);
  }

  double _evaluateCurve(double p) {
    switch (curve) {
      case AudioFadeCurve.linear:
        return p;
      case AudioFadeCurve.logarithmic:
        return math.sqrt(p);
      case AudioFadeCurve.exponential:
        return p * p;
      case AudioFadeCurve.sCurve:
        return (1.0 - math.cos(p * math.pi)) / 2.0;
    }
  }

  @override
  bool shouldRepaint(covariant _AudioFadeEnvelopePainter old) {
    return old.fadeInDurationMs != fadeInDurationMs ||
        old.fadeOutDurationMs != fadeOutDurationMs ||
        old.clipDurationMs != clipDurationMs ||
        old.curve != curve;
  }
}
