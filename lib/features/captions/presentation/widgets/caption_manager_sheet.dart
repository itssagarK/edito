import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../models/project.dart';
import '../models/caption_line.dart';
import '../services/auto_caption_service.dart';

class CaptionManagerSheet extends StatefulWidget {
  final Project project;
  final Function(Project updatedProject) onSave;
  final Function(int timestampMs)? onSeek;

  const CaptionManagerSheet({
    super.key,
    required this.project,
    required this.onSave,
    this.onSeek,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    required Function(Project) onSave,
    Function(int)? onSeek,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CaptionManagerSheet(
        project: project,
        onSave: onSave,
        onSeek: onSeek,
      ),
    );
  }

  @override
  State<CaptionManagerSheet> createState() => _CaptionManagerSheetState();
}

class _CaptionManagerSheetState extends State<CaptionManagerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _selfDescriptionController = TextEditingController();
  List<CaptionLine> _captions = [];
  CaptionPreset _activePreset = CaptionPreset.tiktokViral;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _captions = AutoCaptionService.extractCaptionsFromProject(widget.project);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _selfDescriptionController.dispose();
    super.dispose();
  }

  void _applyAndSave() {
    final updatedProject = AutoCaptionService.syncCaptionsToProject(widget.project, _captions);
    widget.onSave(updatedProject);
  }

  void _generateAuto() {
    setState(() {
      _captions = AutoCaptionService.generateAutoCaptions(
        widget.project,
        preset: _activePreset,
      );
    });
    _applyAndSave();
    if (_captions.isNotEmpty && widget.onSeek != null) {
      widget.onSeek!(_captions.first.startTimeMs);
    }
  }

  void _generateFromDescription() {
    final text = _selfDescriptionController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _captions = AutoCaptionService.generateFromSelfDescription(
        text,
        widget.project.durationMs,
        preset: _activePreset,
      );
    });
    _applyAndSave();
    if (_captions.isNotEmpty && widget.onSeek != null) {
      widget.onSeek!(_captions.first.startTimeMs);
    }
  }

  void _changePreset(CaptionPreset preset) {
    setState(() {
      _activePreset = preset;
      _captions = _captions.map((cap) {
        return cap.copyWith(style: preset.createStyle(cap.text));
      }).toList();
    });
    _applyAndSave();
  }

  void _addNewCaptionLine() {
    final lastEnd = _captions.isNotEmpty ? _captions.last.endTimeMs : 0;
    final newCap = CaptionLine(
      id: const Uuid().v4(),
      text: 'New Caption Line',
      startTimeMs: lastEnd,
      durationMs: 2500,
      style: _activePreset.createStyle('New Caption Line'),
    );
    setState(() {
      _captions.add(newCap);
    });
    _applyAndSave();
    widget.onSeek?.call(newCap.startTimeMs);
  }

  void _deleteCaptionLine(int index) {
    setState(() {
      _captions.removeAt(index);
    });
    _applyAndSave();
  }

  void _editCaptionText(int index, String newText) {
    setState(() {
      _captions[index] = _captions[index].copyWith(
        text: newText,
        style: _captions[index].style.copyWith(text: newText),
      );
    });
    _applyAndSave();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
                        const Icon(Icons.closed_caption, color: AppColors.primaryLight, size: 24),
                        const SizedBox(width: 8),
                        Text('Captions & Subtitles', style: AppTypography.titleLarge),
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

          // Tabs: Auto-Generate | Self-Description | Styles
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.auto_awesome, size: 16), text: 'Auto-Captions'),
                Tab(icon: Icon(Icons.edit_note, size: 16), text: 'Self-Description'),
                Tab(icon: Icon(Icons.style, size: 16), text: 'Caption Styles'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Top Tab Content
          SizedBox(
            height: 160,
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Auto-Caption Tab
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Automatically detect speech timing and populate animated captions across your entire timeline.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _generateAuto,
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('✨ Generate AI Auto-Captions'),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Self-Description Tab
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _selfDescriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Type or paste your video script, description, or custom dialogue here...',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _generateFromDescription,
                          icon: const Icon(Icons.subtitles, size: 16),
                          label: const Text('Convert Script to Timed Captions'),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Caption Styles Tab
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CaptionPreset.values.map((preset) {
                        final isSelected = _activePreset == preset;
                        return ChoiceChip(
                          label: Text(preset.label, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          selectedColor: AppColors.accent,
                          backgroundColor: AppColors.surfaceElevated,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) _changePreset(preset);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 16),

          // Caption Lines List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TIMED CAPTIONS (${_captions.length})',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                Row(
                  children: [
                    if (_captions.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _captions.clear());
                          _applyAndSave();
                        },
                        icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.redAccent),
                        label: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    TextButton.icon(
                      onPressed: _addNewCaptionLine,
                      icon: const Icon(Icons.add, size: 16, color: AppColors.accent),
                      label: const Text('Add Line', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List of Caption Lines
          Expanded(
            child: _captions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.subtitles_off, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text('No captions yet', style: AppTypography.bodyMedium),
                        const SizedBox(height: 4),
                        Text('Use Auto-Captions or type a Self-Description above', style: AppTypography.labelSmall),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _captions.length,
                    itemBuilder: (context, index) {
                      final cap = _captions[index];
                      final timeStr = '${TimecodeFormatter.formatMilliseconds(cap.startTimeMs)} - ${TimecodeFormatter.formatMilliseconds(cap.endTimeMs)}';

                      return Card(
                        color: AppColors.surfaceElevated,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              // Playhead jump button
                              IconButton(
                                icon: const Icon(Icons.play_circle_outline, color: AppColors.accent, size: 22),
                                onPressed: () => widget.onSeek?.call(cap.startTimeMs),
                                tooltip: 'Jump to this caption',
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timeStr,
                                      style: AppTypography.timecode.copyWith(fontSize: 10, color: AppColors.textMuted),
                                    ),
                                    const SizedBox(height: 2),
                                    InkWell(
                                      onTap: () async {
                                        final controller = TextEditingController(text: cap.text);
                                        final edited = await showDialog<String>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: AppColors.surfaceElevated,
                                            title: const Text('Edit Caption Line', style: TextStyle(fontSize: 16)),
                                            content: TextField(
                                              controller: controller,
                                              autofocus: true,
                                              decoration: const InputDecoration(border: OutlineInputBorder()),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, controller.text),
                                                child: const Text('Save'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (edited != null && edited.trim().isNotEmpty) {
                                          _editCaptionText(index, edited.trim());
                                        }
                                      },
                                      child: Text(
                                        cap.text,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                                onPressed: () => _deleteCaptionLine(index),
                                tooltip: 'Remove line',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
