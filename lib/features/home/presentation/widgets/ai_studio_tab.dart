import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/ai/device_tier_service.dart';
import '../../../editor/providers/editor_provider.dart';

class AiStudioTab extends StatefulWidget {
  final ValueChanged<EditorTool> onToolSelected;

  const AiStudioTab({super.key, required this.onToolSelected});

  @override
  State<AiStudioTab> createState() => _AiStudioTabState();
}

class _AiStudioTabState extends State<AiStudioTab> {
  DeviceHardwareInfo? _hardwareInfo;

  @override
  void initState() {
    super.initState();
    _loadHardwareInfo();
  }

  Future<void> _loadHardwareInfo() async {
    try {
      final info = await DeviceTierService.getHardwareInfo();
      if (mounted) {
        setState(() => _hardwareInfo = info);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // AI Header Title
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'On-Device AI Studio',
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF20BF6B).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF20BF6B), width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Color(0xFF20BF6B), size: 6),
                          SizedBox(width: 4),
                          Text(
                            '100% OFFLINE',
                            style: TextStyle(
                              color: Color(0xFF20BF6B),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Local neural models running privately on your device hardware with zero cloud latency.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),

        // Device AI Hardware Card
        if (_hardwareInfo != null)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.memory, color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _hardwareInfo!.tier.label,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_hardwareInfo!.cpuCores} Cores',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_hardwareInfo!.totalRamMb} MB RAM • Threads: ${_hardwareInfo!.inferenceThreads}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Section 1: Speech & Audio AI
        _buildSectionHeader('Speech & Audio AI Engines'),
        _buildGrid([
          _AiFeatureItem(
            title: 'Auto Captions',
            subtitle: 'Offline Whisper Speech-to-Text',
            model: 'Whisper Tiny',
            icon: Icons.closed_caption,
            color: const Color(0xFF00CEC9),
            tool: EditorTool.captions,
          ),
          _AiFeatureItem(
            title: 'Silence Jump-Cut',
            subtitle: 'Auto remove silent gaps & pauses',
            model: 'Silero VAD',
            icon: Icons.movie_filter_outlined,
            color: const Color(0xFFFF7675),
            tool: EditorTool.clipWorkflow,
          ),
          _AiFeatureItem(
            title: 'Vocal Isolation',
            subtitle: 'Split vocals & background tracks',
            model: 'Demucs',
            icon: Icons.mic_none,
            color: const Color(0xFF6C5CE7),
            tool: EditorTool.vocalIsolation,
          ),
          _AiFeatureItem(
            title: 'Neural De-Noise',
            subtitle: 'AI background noise removal',
            model: 'RNNoise BSD-3',
            icon: Icons.noise_control_off,
            color: const Color(0xFF20BF6B),
            tool: EditorTool.denoise,
          ),
          _AiFeatureItem(
            title: 'AI Voiceover',
            subtitle: 'Natural text-to-speech narration',
            model: 'Neural TTS',
            icon: Icons.record_voice_over,
            color: const Color(0xFFFDCB6E),
            tool: EditorTool.tts,
          ),
          _AiFeatureItem(
            title: 'Beat Sync',
            subtitle: 'Spectral flux rhythm snapping',
            model: 'Onset DSP',
            icon: Icons.music_note,
            color: const Color(0xFFFF9F43),
            tool: EditorTool.beats,
          ),
        ]),

        // Section 2: Vision & Motion AI
        _buildSectionHeader('Vision & Motion Intelligence'),
        _buildGrid([
          _AiFeatureItem(
            title: 'Smart Cutout',
            subtitle: 'One-tap background removal',
            model: 'MediaPipe',
            icon: Icons.blur_linear,
            color: const Color(0xFF00CEC9),
            tool: EditorTool.chromaKey,
          ),
          _AiFeatureItem(
            title: 'Motion Tracking',
            subtitle: 'Real optical flow subject tracking',
            model: 'Lucas-Kanade',
            icon: Icons.my_location,
            color: const Color(0xFF6C5CE7),
            tool: EditorTool.tracking,
          ),
          _AiFeatureItem(
            title: 'AI Relight',
            subtitle: '3D studio light & ambient sunbeams',
            model: 'Studio Relight',
            icon: Icons.lightbulb_circle,
            color: const Color(0xFFFFD700),
            tool: EditorTool.relight,
          ),
          _AiFeatureItem(
            title: 'Auto-Reframe',
            subtitle: 'Dynamic active speaker centering',
            model: 'Focal Reframe',
            icon: Icons.aspect_ratio,
            color: const Color(0xFF20BF6B),
            tool: EditorTool.layout,
          ),
          _AiFeatureItem(
            title: 'Magic Eraser',
            subtitle: 'Remove unwanted objects & spots',
            model: 'Inpainting AI',
            icon: Icons.auto_fix_high,
            color: const Color(0xFFFF5252),
            tool: EditorTool.objectRemoval,
          ),
          _AiFeatureItem(
            title: 'AI Face Retouch',
            subtitle: 'Skin smoothing & natural polish',
            model: 'Beauty AI',
            icon: Icons.face_retouching_natural,
            color: const Color(0xFFFF7675),
            tool: EditorTool.retouch,
          ),
        ]),

        // Section 3: Super-Resolution & Clarity
        _buildSectionHeader('Neural Super-Resolution & Clarity'),
        _buildGrid([
          _AiFeatureItem(
            title: '8K AI Detail Upscaler',
            subtitle: 'Tiled neural super-resolution',
            model: 'Real-ESRGAN',
            icon: Icons.auto_awesome_motion,
            color: const Color(0xFF8854D0),
            tool: EditorTool.enhance,
          ),
          _AiFeatureItem(
            title: 'HD Video Converter',
            subtitle: 'Bitrate boost & color fidelity',
            model: 'Pro Master',
            icon: Icons.high_quality,
            color: const Color(0xFF3867D6),
            tool: EditorTool.hdConverter,
          ),
        ]),

        const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      sliver: SliverToBoxAdapter(
        child: Text(
          title.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<_AiFeatureItem> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => widget.onToolSelected(item.tool),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.icon, color: item.color, size: 18),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.model,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: item.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}

class _AiFeatureItem {
  final String title;
  final String subtitle;
  final String model;
  final IconData icon;
  final Color color;
  final EditorTool tool;

  const _AiFeatureItem({
    required this.title,
    required this.subtitle,
    required this.model,
    required this.icon,
    required this.color,
    required this.tool,
  });
}
