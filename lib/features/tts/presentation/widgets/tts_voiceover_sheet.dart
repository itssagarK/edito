import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../models/project.dart';
import '../../../captions/services/auto_caption_service.dart';
import '../../models/tts_voice_profile.dart';
import '../../services/tts_generation_service.dart';

class TTSVoiceoverSheet extends StatefulWidget {
  final Project project;
  final int currentPlayheadMs;
  final Function(Project updatedProject) onProjectChanged;
  final bool isDocked;
  final VoidCallback? onDone;

  const TTSVoiceoverSheet({
    super.key,
    required this.project,
    required this.currentPlayheadMs,
    required this.onProjectChanged,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    required int currentPlayheadMs,
    required Function(Project) onProjectChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.20),
      backgroundColor: Colors.transparent,
      builder: (context) => TTSVoiceoverSheet(
        project: project,
        currentPlayheadMs: currentPlayheadMs,
        onProjectChanged: onProjectChanged,
      ),
    );
  }

  @override
  State<TTSVoiceoverSheet> createState() => _TTSVoiceoverSheetState();
}

class _TTSVoiceoverSheetState extends State<TTSVoiceoverSheet> {
  late TextEditingController _textController;
  late TTSConfig _config;

  @override
  void initState() {
    super.initState();
    _config = const TTSConfig();
    _textController = TextEditingController(text: _config.scriptText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleGenerateVoiceover() {
    final script = _textController.text.trim();
    if (script.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a script text to generate voiceover'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    final updatedConfig = _config.copyWith(scriptText: script);
    var updatedProject = TTSGenerationService.insertVoiceoverClip(
      project: widget.project,
      config: updatedConfig,
      startTimeMs: widget.currentPlayheadMs,
    );

    // Optional: Synchronize captions
    if (updatedConfig.autoGenerateCaptions) {
      final durationMs = TTSGenerationService.estimateSpokenDurationMs(
        script: script,
        speechRate: updatedConfig.speechRate,
      );
      final captions = TTSGenerationService.generateSynchronizedCaptions(
        script: script,
        startTimeMs: widget.currentPlayheadMs,
        totalDurationMs: durationMs,
      );
      if (captions.isNotEmpty) {
        updatedProject = AutoCaptionService.syncCaptionsToTimeline(
          updatedProject,
          captions,
        );
      }
    }

    widget.onProjectChanged(updatedProject);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎙️ Voiceover generated and added to timeline! (${_config.voice.displayName})'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );

    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.65;
    final estimatedDurationMs = TTSGenerationService.estimateSpokenDurationMs(
      script: _textController.text,
      speechRate: _config.speechRate,
    );
    final wordCount = _textController.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Column(
              children: [
                if (!widget.isDocked)
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.record_voice_over, color: Color(0xFF00E5FF), size: 22),
                        const SizedBox(width: 8),
                        Text('AI Voiceover & Narration', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
                          ),
                          child: const Text(
                            'NEURAL TTS',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                      ),
                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                      onPressed: widget.onDone ?? () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Studio Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                // 1. Script Input Area
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Voiceover Script', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Text('$wordCount words  •  ', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              Text(
                                'Est. ${TimecodeFormatter.formatMilliseconds(estimatedDurationMs)}',
                                style: AppTypography.timecode.copyWith(fontSize: 10, color: const Color(0xFF00E5FF)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Type or paste narration script here...',
                          hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Voice Persona Cards
                const Text('Choose Voice Persona', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: TTSVoiceProfile.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final profile = TTSVoiceProfile.values[index];
                      final isSelected = _config.voice == profile;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _config = _config.copyWith(
                              voice: profile,
                              pitchShift: profile.defaultPitch,
                            );
                          });
                        },
                        child: Container(
                          width: 130,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.16) : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00E5FF) : AppColors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(profile.avatarEmoji, style: const TextStyle(fontSize: 22)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(profile.gender, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                                  ),
                                ],
                              ),
                              Text(
                                profile.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                profile.category.label,
                                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
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

                const SizedBox(height: 12),

                // 3. Speech Rate & Pitch Sliders
                Row(
                  children: [
                    // Speech Rate Slider Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Speed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                Text('${_config.speechRate.toStringAsFixed(2)}x', style: AppTypography.timecode.copyWith(fontSize: 11, color: const Color(0xFF00E5FF))),
                              ],
                            ),
                            Slider(
                              value: _config.speechRate,
                              min: 0.5,
                              max: 2.0,
                              activeColor: const Color(0xFF00E5FF),
                              inactiveColor: AppColors.border,
                              onChanged: (v) => setState(() => _config = _config.copyWith(speechRate: double.parse(v.toStringAsFixed(2)))),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Pitch Shift Slider Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Pitch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                Text(
                                  '${_config.pitchShift >= 0 ? "+" : ""}${_config.pitchShift.toStringAsFixed(1)} st',
                                  style: AppTypography.timecode.copyWith(fontSize: 11, color: AppColors.accent),
                                ),
                              ],
                            ),
                            Slider(
                              value: _config.pitchShift,
                              min: -6.0,
                              max: 6.0,
                              activeColor: AppColors.accent,
                              inactiveColor: AppColors.border,
                              onChanged: (v) => setState(() => _config = _config.copyWith(pitchShift: double.parse(v.toStringAsFixed(1)))),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 4. Auto-Generate Subtitles Checkbox Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-Generate Captions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Synchronize animated subtitles with synthesized speech', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    value: _config.autoGenerateCaptions,
                    activeColor: const Color(0xFF00E5FF),
                    onChanged: (v) => setState(() => _config = _config.copyWith(autoGenerateCaptions: v)),
                  ),
                ),

                const SizedBox(height: 14),

                // 5. Generate Voiceover Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_to_photos, size: 20),
                  label: Text(
                    'Insert Voiceover at ${TimecodeFormatter.formatMilliseconds(widget.currentPlayheadMs)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: _handleGenerateVoiceover,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
