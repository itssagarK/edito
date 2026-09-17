import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/audio_effects_config.dart';

class AcousticSpaceVisualizer extends StatelessWidget {
  final AudioEffectsConfig config;

  const AcousticSpaceVisualizer({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final roomSize = config.reverbRoomSize.clamp(0.05, 1.0);
    final damping = config.reverbDamping.clamp(0.0, 1.0);
    final wetGain = config.reverbWetGain.clamp(0.0, 1.0);
    final isEnabled = config.isReverbEnabled && config.reverbPreset != RoomReverbPreset.none;

    // Estimate RT60 decay time in seconds based on Sabine room equation approximation
    final estimatedRt60 = isEnabled ? (0.3 + (roomSize * 3.2) * (1.1 - damping * 0.7)) : 0.0;

    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? AppColors.accent.withOpacity(0.5) : AppColors.border,
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          // Isometric 3D Room & Acoustic Wave Reflections
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _AcousticRoomPainter(
                  roomSize: roomSize,
                  damping: damping,
                  wetGain: wetGain,
                  isEnabled: isEnabled,
                ),
              ),
            ),
          ),

          // HUD Readout Badges
          Positioned(
            left: 10,
            top: 8,
            child: Row(
              children: [
                Icon(
                  Icons.surround_sound,
                  size: 14,
                  color: isEnabled ? AppColors.accent : AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  isEnabled ? config.reverbPreset.label.toUpperCase() : 'DRY ACOUSTIC SPACE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isEnabled ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 10,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Text(
                isEnabled ? 'RT60: ${estimatedRt60.toStringAsFixed(2)}s' : 'RT60: 0.00s',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
          ),

          Positioned(
            left: 10,
            bottom: 8,
            child: Text(
              isEnabled
                  ? 'Reflectivity: ${(wetGain * 100).toInt()}% • Damping: ${(damping * 100).toInt()}%'
                  : 'Acoustic reflections bypassed',
              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcousticRoomPainter extends CustomPainter {
  final double roomSize;
  final double damping;
  final double wetGain;
  final bool isEnabled;

  const _AcousticRoomPainter({
    required this.roomSize,
    required this.damping,
    required this.wetGain,
    required this.isEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 6;

    // Room scale dimensions
    final maxW = size.width * 0.70;
    final maxH = size.height * 0.65;
    final roomW = (maxW * (0.35 + roomSize * 0.65)) / 2;
    final roomH = (maxH * (0.35 + roomSize * 0.65)) / 2;
    final depth = (20.0 + roomSize * 25.0);

    final gridPaint = Paint()
      ..color = isEnabled ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final wallPaint = Paint()
      ..color = isEnabled ? AppColors.accent.withOpacity(0.04 + wetGain * 0.08) : Colors.transparent
      ..style = PaintingStyle.fill;

    // Back wall points
    final backL = Offset(cx - roomW + depth * 0.5, cy - roomH - depth * 0.5);
    final backR = Offset(cx + roomW - depth * 0.5, cy - roomH - depth * 0.5);
    final backBL = Offset(cx - roomW + depth * 0.5, cy + roomH - depth * 0.5);
    final backBR = Offset(cx + roomW - depth * 0.5, cy + roomH - depth * 0.5);

    // Front wall corners
    final frontL = Offset(cx - roomW, cy - roomH);
    final frontR = Offset(cx + roomW, cy - roomH);
    final frontBL = Offset(cx - roomW, cy + roomH);
    final frontBR = Offset(cx + roomW, cy + roomH);

    // Fill back wall
    final backWall = Path()
      ..moveTo(backL.dx, backL.dy)
      ..lineTo(backR.dx, backR.dy)
      ..lineTo(backBR.dx, backBR.dy)
      ..lineTo(backBL.dx, backBL.dy)
      ..close();
    canvas.drawPath(backWall, wallPaint);

    // Draw Isometric Room Box Edges
    canvas.drawLine(frontL, frontR, gridPaint);
    canvas.drawLine(frontR, frontBR, gridPaint);
    canvas.drawLine(frontBR, frontBL, gridPaint);
    canvas.drawLine(frontBL, frontL, gridPaint);

    canvas.drawLine(backL, backR, gridPaint);
    canvas.drawLine(backR, backBR, gridPaint);
    canvas.drawLine(backBR, backBL, gridPaint);
    canvas.drawLine(backBL, backL, gridPaint);

    canvas.drawLine(frontL, backL, gridPaint);
    canvas.drawLine(frontR, backR, gridPaint);
    canvas.drawLine(frontBL, backBL, gridPaint);
    canvas.drawLine(frontBR, backBR, gridPaint);

    if (!isEnabled) return;

    // Source Emitter (Microphone / Vocalist)
    final src = Offset(cx - roomW * 0.45, cy + roomH * 0.25);
    final srcPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(src, 3.5, srcPaint);

    // Reflection bouncing paths
    final rayPaint = Paint()
      ..color = Color.lerp(const Color(0xFF00E5FF), const Color(0xFFFFD700), wetGain)!
          .withOpacity((0.35 + wetGain * 0.55).clamp(0.2, 0.9))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // First order reflections
    final r1 = Offset(backR.dx * 0.95, backR.dy + 8);
    final r2 = Offset(frontR.dx, cy + 4);
    final r3 = Offset(cx + roomW * 0.2, frontBL.dy);
    final r4 = Offset(frontL.dx + 10, cy - 8);

    canvas.drawLine(src, r1, rayPaint);
    canvas.drawLine(r1, r2, rayPaint);
    canvas.drawLine(r2, r3, rayPaint);
    canvas.drawLine(r3, r4, rayPaint);

    // Second order acoustic diffusion wave
    final diffusePaint = Paint()
      ..color = const Color(0xFFE040FB).withOpacity((wetGain * (1.0 - damping * 0.5) * 0.4).clamp(0.05, 0.4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final rad = (i * 12.0) * (0.6 + roomSize * 0.8);
      canvas.drawCircle(r1, rad, diffusePaint);
      canvas.drawCircle(r2, rad * 0.75, diffusePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AcousticRoomPainter oldDelegate) {
    return oldDelegate.roomSize != roomSize ||
        oldDelegate.damping != damping ||
        oldDelegate.wetGain != wetGain ||
        oldDelegate.isEnabled != isEnabled;
  }
}
