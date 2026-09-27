import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/teleprompter_config.dart';
import '../../models/teleprompter_script.dart';

class TeleprompterSheet extends StatefulWidget {
  final TeleprompterConfig config;
  final Function(TeleprompterConfig updatedConfig) onSave;
  final VoidCallback onDone;
  final bool isDocked;

  const TeleprompterSheet({
    super.key,
    required this.config,
    required this.onSave,
    required this.onDone,
    this.isDocked = false,
  });

  @override
  State<TeleprompterSheet> createState() => _TeleprompterSheetState();
}

class _TeleprompterSheetState extends State<TeleprompterSheet> {
  late TeleprompterConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
  }

  void _update(TeleprompterConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onSave(_config);
  }

  void _showNewScriptDialog() {
    final titleController = TextEditingController(text: 'New Creator Script');
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('New Teleprompter Script', style: AppTypography.titleMedium),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Script Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Script Content',
                  hintText: 'Paste or type your script here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              if (contentController.text.trim().isNotEmpty) {
                final newScript = TeleprompterScript(
                  id: 'script_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text.trim().isEmpty
                      ? 'Untitled Script'
                      : titleController.text.trim(),
                  content: contentController.text.trim(),
                  createdAt: DateTime.now(),
                );
                final updatedScripts = List<TeleprompterScript>.from(_config.effectiveScripts)
                  ..add(newScript);
                _update(_config.copyWith(
                  scripts: updatedScripts,
                  activeScriptId: newScript.id,
                  isEnabled: true,
                ));
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add Script'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked
            ? null
            : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildEnableCard(),
                  const SizedBox(height: 16),
                  if (_config.isEnabled) ...[
                    _buildScriptManagerSection(),
                    const SizedBox(height: 16),
                    _buildSpeedSection(),
                    const SizedBox(height: 16),
                    _buildFontAndAlignmentSection(),
                    const SizedBox(height: 16),
                    _buildPrompterOptionsSection(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.record_voice_over, color: Color(0xFF00F0FF), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creator Teleprompter Studio',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Read script while recording with auto-scroll',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Reset',
            onPressed: () => _update(const TeleprompterConfig()),
            style: IconButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primaryLight),
            onPressed: widget.onDone,
            style: IconButton.styleFrom(backgroundColor: AppColors.primary.withOpacity(0.15)),
          ),
        ],
      ),
    );
  }

  Widget _buildEnableCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isEnabled ? const Color(0xFF00F0FF).withOpacity(0.5) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _config.isEnabled ? Icons.speaker_notes : Icons.speaker_notes_off,
                color: _config.isEnabled ? const Color(0xFF00F0FF) : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Floating Script Teleprompter',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _config.isEnabled ? 'Active in viewport' : 'Disabled (Tap to activate)',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _config.isEnabled,
            onChanged: (val) => _update(_config.copyWith(isEnabled: val)),
            activeColor: const Color(0xFF00F0FF),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptManagerSection() {
    final script = _config.activeScript;
    final scripts = _config.effectiveScripts;

    return Container(
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
              Text(
                'ACTIVE SCRIPT',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Script', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF00F0FF)),
                onPressed: _showNewScriptDialog,
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: scripts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final s = scripts[i];
                final isSelected = s.id == _config.activeScriptId;
                return ChoiceChip(
                  label: Text(s.title),
                  selected: isSelected,
                  selectedColor: const Color(0xFF00F0FF).withOpacity(0.25),
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF00F0FF) : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF00F0FF) : AppColors.border,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      _update(_config.copyWith(activeScriptId: s.id));
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Stats pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF00F0FF)),
                const SizedBox(width: 8),
                Text(
                  '${script.wordCount} words • ~${script.formattedEstimatedTime(_config.scrollSpeedWpm)} at ${_config.scrollSpeedWpm} WPM',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedSection() {
    return Container(
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
              Text('Scrolling Speed', style: AppTypography.bodySmall),
              Text(
                '${_config.scrollSpeedWpm} WPM',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00F0FF),
                ),
              ),
            ],
          ),
          Slider(
            value: _config.scrollSpeedWpm.toDouble().clamp(60.0, 300.0),
            min: 60.0,
            max: 300.0,
            divisions: 24,
            activeColor: const Color(0xFF00F0FF),
            inactiveColor: AppColors.border,
            onChanged: (v) => _update(_config.copyWith(scrollSpeedWpm: v.round())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: PrompterSpeedPreset.values.map((preset) {
              final isSelected = _config.scrollSpeedWpm == preset.wpm;
              return ActionChip(
                label: Text(
                  preset.label.split(' ').first,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF00F0FF) : AppColors.textSecondary,
                  ),
                ),
                backgroundColor: isSelected
                    ? const Color(0xFF00F0FF).withOpacity(0.18)
                    : AppColors.surface,
                side: BorderSide(
                  color: isSelected ? const Color(0xFF00F0FF) : AppColors.border,
                ),
                onPressed: () => _update(_config.copyWith(scrollSpeedWpm: preset.wpm)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFontAndAlignmentSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Font size slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Font Size', style: AppTypography.bodySmall),
              Text(
                '${_config.fontSize.toInt()} sp',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00F0FF),
                ),
              ),
            ],
          ),
          Slider(
            value: _config.fontSize.clamp(14.0, 42.0),
            min: 14.0,
            max: 42.0,
            divisions: 14,
            activeColor: const Color(0xFF00F0FF),
            inactiveColor: AppColors.border,
            onChanged: (v) => _update(_config.copyWith(fontSize: v)),
          ),
          const Divider(height: 16),
          // Text Alignment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Text Alignment', style: AppTypography.bodySmall),
              Row(
                children: [
                  _buildAlignButton(TextAlign.left, Icons.format_align_left),
                  _buildAlignButton(TextAlign.center, Icons.format_align_center),
                  _buildAlignButton(TextAlign.right, Icons.format_align_right),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlignButton(TextAlign align, IconData icon) {
    final isSelected = _config.textAlign == align;
    return IconButton(
      icon: Icon(icon, size: 18),
      color: isSelected ? const Color(0xFF00F0FF) : AppColors.textSecondary,
      style: IconButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF00F0FF).withOpacity(0.15) : null,
      ),
      onPressed: () => _update(_config.copyWith(textAlign: align)),
    );
  }

  Widget _buildPrompterOptionsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Reading Focus Line', style: AppTypography.bodyMedium),
            subtitle: Text(
              'Highlights center line for optimal eye contact with camera',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
            value: _config.isHighlightFocusLine,
            activeColor: const Color(0xFF00F0FF),
            onChanged: (val) => _update(_config.copyWith(isHighlightFocusLine: val)),
          ),
          const Divider(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Hardware Mirror Mode', style: AppTypography.bodyMedium),
            subtitle: Text(
              'Flips text horizontally for glass teleprompter beamsplitters',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
            value: _config.isMirrorMode,
            activeColor: const Color(0xFF00F0FF),
            onChanged: (val) => _update(_config.copyWith(isMirrorMode: val)),
          ),
          const Divider(height: 12),
          // Countdown selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Countdown Timer', style: AppTypography.bodyMedium),
              Row(
                children: [0, 3, 5, 10].map((s) {
                  final isSelected = _config.countdownSeconds == s;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(s == 0 ? 'Off' : '${s}s'),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00F0FF).withOpacity(0.25),
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: isSelected ? const Color(0xFF00F0FF) : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF00F0FF) : AppColors.border,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          _update(_config.copyWith(countdownSeconds: s));
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const Divider(height: 12),
          // Background Opacity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Backdrop Opacity', style: AppTypography.bodySmall),
              Text(
                '${(_config.backgroundOpacity * 100).toInt()}%',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00F0FF),
                ),
              ),
            ],
          ),
          Slider(
            value: _config.backgroundOpacity.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            activeColor: const Color(0xFF00F0FF),
            inactiveColor: AppColors.border,
            onChanged: (v) => _update(_config.copyWith(backgroundOpacity: v)),
          ),
        ],
      ),
    );
  }
}
