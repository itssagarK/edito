import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../audio/models/audio_effects_config.dart';
import '../../../color_grading/models/color_grading_config.dart';
import '../../../color_grading/services/color_filter_compiler_service.dart';
import '../../../enhancement/models/video_enhancement_config.dart';
import '../../../overlays/models/text_overlay_config.dart';
import '../../../overlays/services/overlay_compiler_service.dart';
import '../../models/aspect_ratio_preset.dart';
import '../../models/compositor_frame.dart';
import '../../providers/preview_playback_provider.dart';

class RealtimePreviewViewport extends ConsumerWidget {
  final int currentPositionMs;
  final int totalDurationMs;
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onStepBackward;
  final VoidCallback onStepForward;

  const RealtimePreviewViewport({
    super.key,
    required this.currentPositionMs,
    required this.totalDurationMs,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onStepBackward,
    required this.onStepForward,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewState = ref.watch(previewPlaybackProvider);
    final currentFrame = previewState.currentFrame;
    final activeRatio = previewState.aspectRatio;

    return Column(
      children: [
        // Aspect Ratio & Guide Overlay Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Aspect ratio selector
              PopupMenuButton<AspectRatioPreset>(
                tooltip: 'Select Aspect Ratio',
                color: AppColors.surfaceElevated,
                initialValue: activeRatio,
                onSelected: (ratio) {
                  ref.read(previewPlaybackProvider.notifier).setAspectRatio(ratio);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(activeRatio.icon, size: 14, color: AppColors.primaryLight),
                      const SizedBox(width: 6),
                      Text(
                        activeRatio.label.split(' ').first,
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
                itemBuilder: (context) => AspectRatioPreset.values.map((preset) {
                  return PopupMenuItem(
                    value: preset,
                    child: Row(
                      children: [
                        Icon(preset.icon, size: 16, color: AppColors.textPrimary),
                        const SizedBox(width: 8),
                        Text(preset.label, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
              ),

              // Safe Zone & Center Grid Toggle
              IconButton(
                icon: Icon(
                  previewState.showSafeGuides ? Icons.grid_on : Icons.grid_off_outlined,
                  size: 18,
                  color: previewState.showSafeGuides ? AppColors.accent : AppColors.textMuted,
                ),
                onPressed: () {
                  ref.read(previewPlaybackProvider.notifier).toggleSafeGuides();
                },
                tooltip: 'Toggle Safe Area Guides',
              ),
            ],
          ),
        ),

        // Video Render Canvas with dynamic AspectRatio fitting
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: AspectRatio(
                  aspectRatio: activeRatio.ratio,
                  child: Container(
                    color: const Color(0xFF0D0D12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Visual Frame Content with Real-Time Color Matrix Filter
                        _buildVisualContent(currentFrame),

                        // Text & Graphic Overlays
                        if (currentFrame != null && currentFrame.activeOverlays.isNotEmpty)
                          ...currentFrame.activeOverlays.map((overlayClip) {
                            final offsetMs = currentPositionMs - overlayClip.startTimeMs;
                            final evaluatedText = OverlayCompilerService.evaluateOverlayAt(overlayClip, offsetMs);
                            return _buildTextOverlayWidget(evaluatedText);
                          }),

                        // Safe-Zone Grid Overlays (90% action safe, 80% title safe)
                        if (previewState.showSafeGuides)
                          const IgnorePointer(
                            child: CustomPaint(
                              painter: _SafeGuidesPainter(),
                            ),
                          ),

                        // Overlay Timecode Badge
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              TimecodeFormatter.formatSmpte(currentPositionMs),
                              style: AppTypography.timecode.copyWith(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Transport Playback Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TimecodeFormatter.formatMilliseconds(currentPositionMs),
                style: AppTypography.timecode,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_5, size: 22),
                    onPressed: onStepBackward,
                    tooltip: '-5s',
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: onTogglePlay,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.forward_5, size: 22),
                    onPressed: onStepForward,
                    tooltip: '+5s',
                  ),
                ],
              ),
              Text(
                TimecodeFormatter.formatMilliseconds(totalDurationMs),
                style: AppTypography.timecode.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualContent(CompositorFrame? frame) {
    if (frame == null || !frame.hasVisualContent) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              size: 42,
              color: AppColors.textMuted.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'No visual clip at ${TimecodeFormatter.formatMilliseconds(frame?.timestampMs ?? 0)}',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    final clip = frame.primaryVideoClip!;
    final asset = frame.primaryAsset;
    final colorMatrix = ColorFilterCompilerService.compileColorMatrix(clip.colorGrading);

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(colorMatrix),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E272E), Color(0xFF0F141C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_filled,
                size: 48,
                color: AppColors.primaryLight.withOpacity(0.8),
              ),
              const SizedBox(height: 8),
              Text(
                asset?.fileName ?? 'Clip ${clip.id.substring(0, 4)}',
                style: AppTypography.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Source frame: ${TimecodeFormatter.formatMilliseconds(frame.sourceFrameTimeMs)} (${clip.speed}x)',
                style: AppTypography.labelSmall.copyWith(color: AppColors.accent),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  if (clip.colorGrading.activeLut != LutPreset.none)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'LUT: ${clip.colorGrading.activeLut.label.split(' ').first}',
                        style: const TextStyle(fontSize: 9, color: AppColors.accent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (clip.enhancement.is8kUpscaleEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF007F), Color(0xFF7928CA)]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '8K UHD (7680x4320)',
                        style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                  else if (clip.enhancement.hasActiveEnhancements)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '✨ AI ENHANCED',
                        style: TextStyle(fontSize: 9, color: AppColors.accent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (clip.audioEffects.isLoudVoiceEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '🔥 LOUD VOICE',
                        style: TextStyle(fontSize: 9, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (clip.audioEffects.modulationPreset != VoiceModulationPreset.natural)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.audioTrack.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        clip.audioEffects.modulationPreset.label.toUpperCase(),
                        style: const TextStyle(fontSize: 9, color: AppColors.audioTrack, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (clip.smoother.hasActiveSmoothing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentWarm.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.accentWarm.withOpacity(0.6)),
                      ),
                      child: Text(
                        clip.smoother.isStabilizationEnabled
                            ? '🛡️ GIMBAL STABILIZED'
                            : '🌊 ${clip.smoother.targetFps}FPS SMOOTH',
                        style: const TextStyle(fontSize: 9, color: AppColors.accentWarm, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextOverlayWidget(TextOverlayConfig config) {
    if (config.text.trim().isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment(
        (config.positionX * 2.0) - 1.0,
        (config.positionY * 2.0) - 1.0,
      ),
      child: Transform.scale(
        scale: config.scale,
        child: Transform.rotate(
          angle: config.rotation * (3.14159 / 180.0),
          child: Opacity(
            opacity: config.opacity.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: config.backgroundColor != null ? Color(config.backgroundColor!) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Builder(
                builder: (context) {
                  TextStyle style;
                  try {
                    style = GoogleFonts.getFont(
                      config.fontFamily == 'Inter' ? 'Inter' : (config.fontFamily == 'JetBrainsMono' ? 'JetBrains Mono' : 'Roboto'),
                      fontSize: config.fontSize,
                      fontWeight: FontWeight.bold,
                      color: Color(config.textColor),
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    );
                  } catch (_) {
                    style = TextStyle(
                      fontSize: config.fontSize,
                      fontWeight: FontWeight.bold,
                      color: Color(config.textColor),
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    );
                  }
                  return Text(config.text, style: style);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SafeGuidesPainter extends CustomPainter {
  const _SafeGuidesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final actionSafePaint = Paint()
      ..color = AppColors.accent.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final titleSafePaint = Paint()
      ..color = AppColors.accentGold.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final crosshairPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // Action Safe (90% area -> 5% margin)
    final actionRect = Rect.fromLTWH(
      size.width * 0.05,
      size.height * 0.05,
      size.width * 0.90,
      size.height * 0.90,
    );
    canvas.drawRect(actionRect, actionSafePaint);

    // Title Safe (80% area -> 10% margin)
    final titleRect = Rect.fromLTWH(
      size.width * 0.10,
      size.height * 0.10,
      size.width * 0.80,
      size.height * 0.80,
    );
    canvas.drawRect(titleRect, titleSafePaint);

    // Center Crosshair
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    canvas.drawLine(Offset(centerX - 10, centerY), Offset(centerX + 10, centerY), crosshairPaint);
    canvas.drawLine(Offset(centerX, centerY - 10), Offset(centerX, centerY + 10), crosshairPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
