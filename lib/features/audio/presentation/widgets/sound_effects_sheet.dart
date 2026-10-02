import 'package:flutter/material.dart' hide Clip;
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../../../models/project.dart';
import '../../../../models/track.dart';
import '../../../../models/media_asset.dart';
import '../../models/sound_effect_item.dart';
import 'waveform_painter.dart';

class SoundEffectsSheet extends StatefulWidget {
  final Project project;
  final int playheadPositionMs;
  final Function(Project updatedProject) onSaveProject;
  final VoidCallback? onDone;
  final bool isDocked;

  const SoundEffectsSheet({
    super.key,
    required this.project,
    required this.playheadPositionMs,
    required this.onSaveProject,
    this.onDone,
    this.isDocked = false,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    required int playheadPositionMs,
    required Function(Project) onSaveProject,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (context) => SoundEffectsSheet(
        project: project,
        playheadPositionMs: playheadPositionMs,
        onSaveProject: onSaveProject,
        onDone: onDone,
      ),
    );
  }

  @override
  State<SoundEffectsSheet> createState() => _SoundEffectsSheetState();
}

class _SoundEffectsSheetState extends State<SoundEffectsSheet> {
  String _selectedCategory = 'All';
  String? _previewingId;

  List<String> get _categories => ['All', 'Transitions', 'Impacts', 'Risers', 'Tactile & UI', 'Ambience'];

  List<SoundEffectItem> get _filteredItems {
    if (_selectedCategory == 'All') {
      return SoundEffectItem.library;
    }
    return SoundEffectItem.library.where((s) => s.category == _selectedCategory).toList();
  }

  void _previewSound(SoundEffectItem item) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_previewingId == item.id) {
        _previewingId = null;
      } else {
        _previewingId = item.id;
      }
    });

    // Auto-stop preview after duration
    if (_previewingId != null) {
      Future.delayed(Duration(milliseconds: item.durationMs), () {
        if (mounted && _previewingId == item.id) {
          setState(() => _previewingId = null);
        }
      });
    }
  }

  void _insertToTimeline(SoundEffectItem item) {
    HapticFeedback.mediumImpact();

    final startTime = widget.playheadPositionMs;
    final duration = item.durationMs;
    final sfxAssetId = 'asset_sfx_${DateTime.now().millisecondsSinceEpoch}';

    final sfxAsset = MediaAsset(
      id: sfxAssetId,
      path: item.assetPath ?? 'procedural://${item.id}',
      fileName: item.name,
      type: MediaType.audio,
      durationMs: duration,
    );

    // Locate or create audio track
    final tracks = List<Track>.from(widget.project.tracks);
    int audioTrackIndex = tracks.indexWhere((t) => t.type == TrackType.audio);
    String trackId;

    if (audioTrackIndex == -1) {
      trackId = 'track_audio_${DateTime.now().millisecondsSinceEpoch}';
      final newTrack = Track(
        id: trackId,
        name: 'Audio SFX',
        type: TrackType.audio,
        clips: const [],
      );
      tracks.add(newTrack);
      audioTrackIndex = tracks.length - 1;
    } else {
      trackId = tracks[audioTrackIndex].id;
    }

    final newClip = Clip(
      id: 'clip_sfx_${DateTime.now().millisecondsSinceEpoch}',
      assetId: sfxAssetId,
      trackId: trackId,
      startTimeMs: startTime,
      durationMs: duration,
      sourceInMs: 0,
      sourceOutMs: duration,
    );

    final existingTrack = tracks[audioTrackIndex];
    final updatedClips = List<Clip>.from(existingTrack.clips)..add(newClip);
    tracks[audioTrackIndex] = existingTrack.copyWith(clips: updatedClips);

    final updatedAssets = List<MediaAsset>.from(widget.project.assets)..add(sfxAsset);
    final updatedProject = widget.project.copyWith(tracks: tracks, assets: updatedAssets);
    widget.onSaveProject(updatedProject);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${item.name}" to audio track at ${(startTime / 1000).toStringAsFixed(1)}s'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.isDocked ? null : MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: widget.isDocked ? Colors.transparent : AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: widget.isDocked ? null : const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked) _buildHeader(),
          _buildCategoryFilterBar(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final isPlaying = _previewingId == item.id;
                return _buildSfxCard(item, isPlaying);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: AppColors.primaryLight, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sound Effects Studio',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'CapCut Flagship SFX Library',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.check, color: AppColors.primaryLight),
                onPressed: () {
                  widget.onDone?.call();
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterBar() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(
              cat,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surfaceElevated,
            onSelected: (selected) {
              if (selected) {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = cat);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildSfxCard(SoundEffectItem item, bool isPlaying) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlaying ? item.color : AppColors.border,
          width: isPlaying ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Play / Preview button
          InkWell(
            onTap: () => _previewSound(item),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPlaying ? item.color : item.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.stop : Icons.play_arrow,
                color: isPlaying ? Colors.black : item.color,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name, Category & Waveform
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(item.durationMs / 1000).toStringAsFixed(1)}s',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 18,
                  child: CustomPaint(
                    size: const Size(double.infinity, 18),
                    painter: WaveformPainter(
                      color: isPlaying ? item.color : AppColors.textMuted,
                      pcmPeaks: item.pcmPeaks,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 1-Tap Add to Timeline button
          IconButton.styleFrom(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            foregroundColor: AppColors.primaryLight,
          ) != null
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(40, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _insertToTimeline(item),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.white),
                      SizedBox(width: 2),
                      Text('Add', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
