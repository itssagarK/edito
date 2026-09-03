import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/video_enhancement_config.dart';
import '../../services/ai_video_enhancer_service.dart';

class VideoEnhancementSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;

  const VideoEnhancementSheet({
    super.key,
    required this.clip,
    required this.onSave,
  });

  static Future<void> show(BuildContext context, {required Clip clip, required Function(Clip) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoEnhancementSheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<VideoEnhancementSheet> createState() => _VideoEnhancementSheetState();
}

class _VideoEnhancementSheetState extends State<VideoEnhancementSheet> {
  late VideoEnhancementConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.enhancement;
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(
      enhancement: _config,
    );
    widget.onSave(updated);
  }

  void _applyPreset(EnhanceModelPreset preset) {
    setState(() {
      switch (preset) {
        case EnhanceModelPreset.ultraCinema8k:
          _config = _config.copyWith(
            modelPreset: preset,
            is8kUpscaleEnabled: true,
            isAiSuperResolutionEnabled: true,
            sharpness: 1.4,
            deNoise: 0.25,
            isHdrToneMapping: true,
            clarity: 1.25,
            isColorPop: false,
          );
          break;
        case EnhanceModelPreset.crispPhoto:
          _config = _config.copyWith(
            modelPreset: preset,
            is8kUpscaleEnabled: true,
            isAiSuperResolutionEnabled: true,
            sharpness: 1.6,
            deNoise: 0.15,
            isHdrToneMapping: false,
            clarity: 1.35,
            isColorPop: true,
          );
          break;
        case EnhanceModelPreset.cleanDenoise:
          _config = _config.copyWith(
            modelPreset: preset,
            is8kUpscaleEnabled: false,
            isAiSuperResolutionEnabled: true,
            sharpness: 1.1,
            deNoise: 0.70,
            isHdrToneMapping: false,
            clarity: 1.05,
            isColorPop: false,
          );
          break;
        case EnhanceModelPreset.vibrantHdr:
          _config = _config.copyWith(
            modelPreset: preset,
            is8kUpscaleEnabled: false,
            isAiSuperResolutionEnabled: true,
            sharpness: 1.2,
            deNoise: 0.20,
            isHdrToneMapping: true,
            clarity: 1.30,
            isColorPop: true,
          );
          break;
        case EnhanceModelPreset.standard:
          _config = _config.copyWith(
            modelPreset: preset,
            is8kUpscaleEnabled: false,
            isAiSuperResolutionEnabled: false,
            sharpness: 1.0,
            deNoise: 0.0,
            isHdrToneMapping: false,
            clarity: 1.0,
            isColorPop: false,
          );
          break;
      }
    });
    _applyChange();
  }

  @override
  Widget build(BuildContext context) {
    final resolutionLabel = AIVideoEnhancerService.getResolutionLabel(_config);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.4),
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
                        const Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
                        const SizedBox(width: 8),
                        Text('8K AI Video & Photo Enhancer', style: AppTypography.titleLarge),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.accent, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // 1. 8K Ultra HD Upscaling Banner Card
                _buildCard(
                  title: '🚀 8K AI Ultra HD Upscaler',
                  subtitle: 'Neural super-resolution up to 7680x4320 resolution',
                  badge: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: _config.is8kUpscaleEnabled
                          ? const LinearGradient(colors: [Color(0xFFFF007F), Color(0xFF7928CA)])
                          : null,
                      color: _config.is8kUpscaleEnabled ? null : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _config.is8kUpscaleEnabled ? Colors.transparent : AppColors.border,
                      ),
                    ),
                    child: Text(
                      resolutionLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _config.is8kUpscaleEnabled ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable 8K AI Upscale (7680x4320)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Upscales standard video or photos to ultra-crisp 8K master output', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        value: _config.is8kUpscaleEnabled,
                        activeColor: const Color(0xFFFF007F),
                        onChanged: (val) {
                          setState(() {
                            _config = _config.copyWith(
                              is8kUpscaleEnabled: val,
                              isAiSuperResolutionEnabled: val ? true : _config.isAiSuperResolutionEnabled,
                            );
                          });
                          _applyChange();
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('AI Super-Resolution & Edge Reconstruction', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Synthesizes missing high-frequency micro-details & sharpens edges', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        value: _config.isAiSuperResolutionEnabled,
                        activeColor: AppColors.accent,
                        onChanged: (val) {
                          setState(() => _config = _config.copyWith(isAiSuperResolutionEnabled: val));
                          _applyChange();
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('HDR Dynamic Range & Tone Mapping', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Expands highlight details and deepens cinematic shadows', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        value: _config.isHdrToneMapping,
                        activeColor: AppColors.primaryLight,
                        onChanged: (val) {
                          setState(() => _config = _config.copyWith(isHdrToneMapping: val));
                          _applyChange();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2. AI Model Presets Card
                _buildCard(
                  title: '✨ AI Enhancement Presets',
                  subtitle: 'One-tap optimization for cinema, photos, and restoration',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: EnhanceModelPreset.values.map((preset) {
                          final isSelected = _config.modelPreset == preset;
                          return ChoiceChip(
                            label: Text(preset.label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            selected: isSelected,
                            selectedColor: AppColors.accent,
                            backgroundColor: AppColors.surface,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
                            onSelected: (selected) {
                              if (selected) {
                                _applyPreset(preset);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _config.modelPreset.description,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Detail & Sharpness Sliders Card
                _buildCard(
                  title: '🔍 Micro-Detail & Noise Controls',
                  subtitle: 'Fine-tune clarity, edge sharpness and grain suppression',
                  child: Column(
                    children: [
                      // Sharpness
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('AI Detail Sharpness', style: TextStyle(fontSize: 13)),
                          Text('${(_config.sharpness * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent)),
                        ],
                      ),
                      Slider(
                        value: _config.sharpness,
                        min: 0.0,
                        max: 2.5,
                        divisions: 25,
                        activeColor: AppColors.accent,
                        inactiveColor: AppColors.surfaceElevated,
                        onChanged: (val) {
                          setState(() => _config = _config.copyWith(sharpness: val));
                          _applyChange();
                        },
                      ),

                      // Denoise
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('AI Artifact & Noise Reduction', style: TextStyle(fontSize: 13)),
                          Text('${(_config.deNoise * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.primaryLight)),
                        ],
                      ),
                      Slider(
                        value: _config.deNoise,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        activeColor: AppColors.primaryLight,
                        inactiveColor: AppColors.surfaceElevated,
                        onChanged: (val) {
                          setState(() => _config = _config.copyWith(deNoise: val));
                          _applyChange();
                        },
                      ),

                      // Clarity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Local Contrast & Clarity', style: TextStyle(fontSize: 13)),
                          Text('${(_config.clarity * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12)),
                        ],
                      ),
                      Slider(
                        value: _config.clarity,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        activeColor: AppColors.audioTrack,
                        inactiveColor: AppColors.surfaceElevated,
                        onChanged: (val) {
                          setState(() => _config = _config.copyWith(clarity: val));
                          _applyChange();
                        },
                      ),

                      // Color Pop
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Vibrant Color & Chroma Boost', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Enriches natural saturation and photographic vividness', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        value: _config.isColorPop,
                        activeColor: AppColors.accentWarm,
                        onChanged: (val) {
                          setState(() => _config = _config.copyWith(isColorPop: val));
                          _applyChange();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    Widget? badge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.labelSmall),
                  ],
                ),
              ),
              if (badge != null) badge,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
